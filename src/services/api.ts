import type { Account, AppInitData, Budget, Category, DatabaseBackup, GoldAsset, Transaction } from '../types/index.js';
import { toYYYYMMDD } from '../utils/formatters.js';

const BASE = '/api';

async function request<T>(method: string, path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: body ? { 'Content-Type': 'application/json' } : {},
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`API ${method} ${path} failed (${res.status}): ${text}`);
  }
  return res.json();
}

export async function fetchInit(): Promise<AppInitData> {
  return request('GET', '/init');
}

// --- Transactions ---
export async function addTransaction(t: Transaction): Promise<void> {
  await request('POST', '/transactions', {
    ...t,
    date: t.date instanceof Date ? toYYYYMMDD(t.date) : t.date,
  });
}

export async function editTransaction(t: Transaction): Promise<void> {
  await request('PUT', `/transactions/${t.id}`, {
    ...t,
    date: t.date instanceof Date ? toYYYYMMDD(t.date) : t.date,
  });
}

export async function deleteTransaction(id: string): Promise<void> {
  await request('DELETE', `/transactions/${id}`);
}

export async function bulkAddTransactions(
  transactions: Transaction[],
  categories: Category[],
  accounts: Account[]
): Promise<void> {
  if (categories.length) await request('POST', '/categories/bulk', categories);
  if (accounts.length) await request('POST', '/accounts/bulk', accounts);
  if (transactions.length) {
    const payload = transactions.map((t) => ({
      ...t,
      date: t.date instanceof Date ? toYYYYMMDD(t.date) : t.date,
    }));
    await request('POST', '/transactions/bulk', payload);
  }
}

export async function clearAllTransactions(): Promise<void> {
  await request('DELETE', '/transactions/all');
}

// --- Categories ---
export async function addCategory(c: Category): Promise<void> {
  await request('POST', '/categories', c);
}

export async function renameCategory(id: string, name: string): Promise<void> {
  await request('PUT', `/categories/${id}`, { name });
}

export async function deleteCategory(id: string): Promise<void> {
  await request('DELETE', `/categories/${id}`);
}

// --- Accounts ---
export async function addAccount(a: Account): Promise<void> {
  await request('POST', '/accounts', a);
}

export async function renameAccount(id: string, name: string): Promise<void> {
  await request('PUT', `/accounts/${id}`, { name });
}

export async function deleteAccount(id: string): Promise<void> {
  await request('DELETE', `/accounts/${id}`);
}

export async function setAccountBalance(accountId: string, balance: number): Promise<void> {
  await request('PUT', `/accounts/${accountId}/balance`, { balance });
}

export async function bulkSetAccountBalances(balances: Record<string, number>): Promise<void> {
  await request('PUT', '/accounts/balances/bulk', balances);
}

// --- Budgets ---
export async function addBudget(b: Budget): Promise<void> {
  await request('POST', '/budgets', b);
}

export async function editBudget(b: Budget): Promise<void> {
  await request('PUT', `/budgets/${b.id}`, b);
}

export async function deleteBudget(id: string): Promise<void> {
  await request('DELETE', `/budgets/${id}`);
}

// --- Gold Assets ---
export async function addGoldAsset(a: GoldAsset): Promise<void> {
  await request('POST', '/gold-assets', a);
}

export async function editGoldAsset(a: GoldAsset): Promise<void> {
  await request('PUT', `/gold-assets/${a.id}`, a);
}

export async function deleteGoldAsset(id: string): Promise<void> {
  await request('DELETE', `/gold-assets/${id}`);
}

// --- Settings ---
export async function saveSettings(settings: Record<string, string>): Promise<void> {
  await request('PUT', '/settings', settings);
}

// --- Full restore from backup ---
export async function restoreBackup(backup: DatabaseBackup): Promise<void> {
  // Clear transactions first, then re-insert everything in correct FK order
  await clearAllTransactions();
  await request('DELETE', '/transactions/all');

  // Wipe and re-insert categories
  for (const c of backup.categories) {
    await request('POST', '/categories', c).catch(() => {
      // May already exist if partial restore — update instead
      return request('PUT', `/categories/${c.id}`, { name: c.name });
    });
  }

  // Wipe and re-insert accounts
  for (const a of backup.accounts) {
    await request('POST', '/accounts', a).catch(() => {
      return request('PUT', `/accounts/${a.id}`, { name: a.name });
    });
  }

  // Bulk insert transactions
  if (backup.transactions.length) {
    await request('POST', '/transactions/bulk', backup.transactions);
  }

  // Bulk set balances
  if (Object.keys(backup.accountBalances).length) {
    await request('PUT', '/accounts/balances/bulk', backup.accountBalances);
  }

  // Settings
  await saveSettings({
    defaultCategoryExpenseId: backup.defaults.defaultCategoryExpenseId,
    defaultCategoryIncomeId: backup.defaults.defaultCategoryIncomeId,
    defaultAccountId: backup.defaults.defaultAccountId,
  });

  // Budgets - delete all and re-insert
  const existingBudgets = await request<Budget[]>('GET', '/budgets');
  for (const b of existingBudgets) {
    await request('DELETE', `/budgets/${b.id}`);
  }
  for (const b of backup.budgets) {
    await request('POST', '/budgets', b);
  }
}
