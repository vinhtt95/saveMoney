import { Account, Category, DatabaseBackup, DatabaseBackupV1 } from '../types';

function makeCategory(name: string, type: 'Expense' | 'Income'): Category {
  return { id: crypto.randomUUID(), name, type };
}

function makeAccount(name: string): Account {
  return { id: crypto.randomUUID(), name };
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
