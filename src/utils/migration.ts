import { Account, Category, DatabaseBackup, DatabaseBackupV1 } from '../types';

const MIGRATION_GUARD_KEY = 'savemoney_v2_migrated';

// v1 storage keys (read-only after migration)
const STORAGE_KEY = 'savemoney_transactions';
const EXPENSE_CATEGORIES_KEY = 'savemoney_expense_categories';
const INCOME_CATEGORIES_KEY = 'savemoney_income_categories';
const CATEGORIES_LEGACY_KEY = 'savemoney_categories';
const ACCOUNTS_KEY = 'savemoney_accounts';
const ACCOUNT_BALANCES_KEY = 'savemoney_account_balances';
const DEFAULTS_KEY = 'savemoney_defaults';
const BUDGETS_KEY = 'savemoney_budgets';

// v2 storage keys
export const CATEGORIES_V2_KEY = 'savemoney_categories_v2';
export const ACCOUNTS_V2_KEY = 'savemoney_accounts_v2';

function loadJSON<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    if (raw) return JSON.parse(raw) as T;
  } catch { /* ignore */ }
  return fallback;
}

function makeCategory(name: string, type: 'Expense' | 'Income'): Category {
  return { id: crypto.randomUUID(), name, type };
}

function makeAccount(name: string): Account {
  return { id: crypto.randomUUID(), name };
}

/**
 * Migrates localStorage data from v1 (name-based) to v2 (ID-based).
 * Non-destructive: old keys are not deleted.
 * Idempotent: guarded by MIGRATION_GUARD_KEY.
 */
export function migrateStorageV1ToV2(): void {
  if (localStorage.getItem(MIGRATION_GUARD_KEY)) return;

  // Read old data
  const rawTxs = loadJSON<Array<Record<string, unknown>>>(STORAGE_KEY, []);

  // Load expense categories
  let expenseNames: string[] = loadJSON<string[]>(EXPENSE_CATEGORIES_KEY, []);
  let incomeNames: string[] = loadJSON<string[]>(INCOME_CATEGORIES_KEY, []);

  // If no split keys, try legacy flat key
  if (expenseNames.length === 0 && incomeNames.length === 0) {
    const legacy = loadJSON<string[]>(CATEGORIES_LEGACY_KEY, []);
    // Use transaction types to split
    const expenseSet = new Set<string>();
    const incomeSet = new Set<string>();
    rawTxs.forEach((t) => {
      if (t.category && typeof t.category === 'string') {
        if (t.type === 'Expense') expenseSet.add(t.category);
        else if (t.type === 'Income') incomeSet.add(t.category);
      }
    });
    legacy.forEach((name) => {
      if (incomeSet.has(name) && !expenseSet.has(name)) incomeNames.push(name);
      else expenseNames.push(name);
    });
  }

  const accountNames: string[] = loadJSON<string[]>(ACCOUNTS_KEY, []);
  const oldBalances: Record<string, number> = loadJSON<Record<string, number>>(ACCOUNT_BALANCES_KEY, {});
  const oldDefaults: Record<string, string> = loadJSON<Record<string, string>>(DEFAULTS_KEY, {});
  const oldBudgets: Array<Record<string, unknown>> = loadJSON<Array<Record<string, unknown>>>(BUDGETS_KEY, []);

  // Build category objects (collect all unique names first, including orphans from transactions)
  const expenseCatMap = new Map<string, Category>();
  const incomeCatMap = new Map<string, Category>();

  expenseNames.forEach((name) => {
    if (name) expenseCatMap.set(name, makeCategory(name, 'Expense'));
  });
  incomeNames.forEach((name) => {
    if (name) incomeCatMap.set(name, makeCategory(name, 'Income'));
  });

  // Handle orphaned categories from transactions
  rawTxs.forEach((t) => {
    const name = t.category as string;
    const type = t.type as string;
    if (!name) return;
    if (type === 'Expense' && !expenseCatMap.has(name)) {
      expenseCatMap.set(name, makeCategory(name, 'Expense'));
    } else if (type === 'Income' && !incomeCatMap.has(name)) {
      incomeCatMap.set(name, makeCategory(name, 'Income'));
    } else if (type !== 'Expense' && type !== 'Income') {
      // Account/Transfer transactions — put in expense bucket if not already present
      if (!expenseCatMap.has(name) && !incomeCatMap.has(name) && name && name !== '') {
        expenseCatMap.set(name, makeCategory(name, 'Expense'));
      }
    }
  });

  const allCategories: Category[] = [...expenseCatMap.values(), ...incomeCatMap.values()];

  // catNameToId: for a given name, find the first matching category id
  const catNameToId = new Map<string, string>();
  allCategories.forEach((c) => catNameToId.set(c.name, c.id));

  // Build account objects
  const accountMap = new Map<string, Account>();
  accountNames.forEach((name) => {
    if (name) accountMap.set(name, makeAccount(name));
  });

  // Handle orphaned accounts from transactions
  rawTxs.forEach((t) => {
    const acc = t.account as string;
    const transferTo = t.transferTo as string;
    if (acc && !accountMap.has(acc)) accountMap.set(acc, makeAccount(acc));
    if (transferTo && !accountMap.has(transferTo)) accountMap.set(transferTo, makeAccount(transferTo));
  });

  const allAccounts: Account[] = [...accountMap.values()];
  const accNameToId = new Map<string, string>();
  allAccounts.forEach((a) => accNameToId.set(a.name, a.id));

  // Migrate transactions
  const migratedTxs = rawTxs.map((t) => ({
    ...t,
    categoryId: catNameToId.get(t.category as string) ?? '',
    accountId: accNameToId.get(t.account as string) ?? '',
    transferToId: accNameToId.get(t.transferTo as string) ?? '',
    // Remove old string fields
    category: undefined,
    account: undefined,
    transferTo: undefined,
  }));

  // Migrate account balances (keyed by name → keyed by id)
  const migratedBalances: Record<string, number> = {};
  Object.entries(oldBalances).forEach(([name, balance]) => {
    const id = accNameToId.get(name);
    if (id) migratedBalances[id] = balance;
  });

  // Migrate defaults
  const migratedDefaults = {
    defaultCategoryExpenseId: catNameToId.get(oldDefaults.defaultCategoryExpense ?? '') ?? '',
    defaultCategoryIncomeId: catNameToId.get(oldDefaults.defaultCategoryIncome ?? '') ?? '',
    defaultAccountId: accNameToId.get(oldDefaults.defaultAccount ?? '') ?? '',
  };

  // Migrate budgets
  const migratedBudgets = oldBudgets.map((b) => ({
    ...b,
    categoryIds: (b.categories as string[] ?? []).map((name) => catNameToId.get(name) ?? '').filter(Boolean),
    categories: undefined,
  }));

  // Write v2 data
  try {
    localStorage.setItem(CATEGORIES_V2_KEY, JSON.stringify(allCategories));
    localStorage.setItem(ACCOUNTS_V2_KEY, JSON.stringify(allAccounts));
    localStorage.setItem(STORAGE_KEY, JSON.stringify(migratedTxs));
    localStorage.setItem(ACCOUNT_BALANCES_KEY, JSON.stringify(migratedBalances));
    localStorage.setItem(DEFAULTS_KEY, JSON.stringify(migratedDefaults));
    localStorage.setItem(BUDGETS_KEY, JSON.stringify(migratedBudgets));
    localStorage.setItem(MIGRATION_GUARD_KEY, '1');
  } catch (e) {
    console.error('Migration v1→v2 failed:', e);
  }
}

/**
 * Converts a v1 backup to v2 format (pure function, no side effects).
 */
export function migrateBackupV1(backup: DatabaseBackupV1): DatabaseBackup {
  const expenseCatMap = new Map<string, Category>();
  const incomeCatMap = new Map<string, Category>();

  backup.expenseCategories.forEach((name) => {
    if (name) expenseCatMap.set(name, makeCategory(name, 'Expense'));
  });
  backup.incomeCategories.forEach((name) => {
    if (name) incomeCatMap.set(name, makeCategory(name, 'Income'));
  });

  // Orphaned categories from transactions
  backup.transactions.forEach((t) => {
    const name = t.category;
    if (!name) return;
    if (t.type === 'Expense' && !expenseCatMap.has(name)) expenseCatMap.set(name, makeCategory(name, 'Expense'));
    else if (t.type === 'Income' && !incomeCatMap.has(name)) incomeCatMap.set(name, makeCategory(name, 'Income'));
    else if (!expenseCatMap.has(name) && !incomeCatMap.has(name)) expenseCatMap.set(name, makeCategory(name, 'Expense'));
  });

  const allCategories: Category[] = [...expenseCatMap.values(), ...incomeCatMap.values()];
  const catNameToId = new Map<string, string>();
  allCategories.forEach((c) => catNameToId.set(c.name, c.id));

  const accountMap = new Map<string, Account>();
  backup.accounts.forEach((name) => {
    if (name) accountMap.set(name, makeAccount(name));
  });
  backup.transactions.forEach((t) => {
    if (t.account && !accountMap.has(t.account)) accountMap.set(t.account, makeAccount(t.account));
    if (t.transferTo && !accountMap.has(t.transferTo)) accountMap.set(t.transferTo, makeAccount(t.transferTo));
  });

  const allAccounts: Account[] = [...accountMap.values()];
  const accNameToId = new Map<string, string>();
  allAccounts.forEach((a) => accNameToId.set(a.name, a.id));

  const transactions = backup.transactions.map((t) => ({
    id: t.id,
    date: t.date,
    type: t.type,
    categoryId: catNameToId.get(t.category) ?? '',
    accountId: accNameToId.get(t.account) ?? '',
    transferToId: accNameToId.get(t.transferTo) ?? '',
    amount: t.amount,
  }));

  const accountBalances: Record<string, number> = {};
  Object.entries(backup.accountBalances).forEach(([name, bal]) => {
    const id = accNameToId.get(name);
    if (id) accountBalances[id] = bal;
  });

  const budgets = backup.budgets.map((b) => ({
    id: b.id,
    name: b.name,
    limit: b.limit,
    dateStart: b.dateStart,
    dateEnd: b.dateEnd,
    categoryIds: b.categories.map((name) => catNameToId.get(name) ?? '').filter(Boolean),
  }));

  return {
    version: 2,
    exportedAt: backup.exportedAt,
    transactions,
    categories: allCategories,
    accounts: allAccounts,
    accountBalances,
    defaults: {
      defaultCategoryExpenseId: catNameToId.get(backup.defaults.defaultCategoryExpense) ?? '',
      defaultCategoryIncomeId: catNameToId.get(backup.defaults.defaultCategoryIncome) ?? '',
      defaultAccountId: accNameToId.get(backup.defaults.defaultAccount) ?? '',
    },
    budgets,
  };
}
