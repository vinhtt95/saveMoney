import { AppState, Budget, DatabaseBackup } from '../types';

const BUDGETS_KEY = 'savemoney_budgets';

export function exportDatabase(state: AppState): void {
  const budgets: Budget[] = (() => {
    try {
      const raw = localStorage.getItem(BUDGETS_KEY);
      return raw ? (JSON.parse(raw) as Budget[]) : [];
    } catch {
      return [];
    }
  })();

  const backup: DatabaseBackup = {
    version: 1,
    exportedAt: new Date().toISOString(),
    transactions: state.transactions.map((t) => ({ ...t, date: t.date.toISOString() })),
    expenseCategories: state.expenseCategories,
    incomeCategories: state.incomeCategories,
    accounts: state.accounts,
    accountBalances: state.accountBalances,
    defaults: {
      defaultCategoryExpense: state.defaultCategoryExpense,
      defaultCategoryIncome: state.defaultCategoryIncome,
      defaultAccount: state.defaultAccount,
    },
    budgets,
  };

  const blob = new Blob([JSON.stringify(backup, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `savemoney-backup-${new Date().toISOString().slice(0, 10)}.json`;
  a.click();
  URL.revokeObjectURL(url);
}

export function readBackupFile(file: File): Promise<DatabaseBackup> {
  return new Promise((resolve, reject) => {
    if (!file.name.endsWith('.json')) {
      reject(new Error('Please select a .json backup file.'));
      return;
    }
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const parsed = JSON.parse(e.target?.result as string) as DatabaseBackup;
        if (typeof parsed.version !== 'number' || !Array.isArray(parsed.transactions)) {
          reject(new Error('Invalid backup file format.'));
          return;
        }
        resolve(parsed);
      } catch {
        reject(new Error('Failed to parse backup file.'));
      }
    };
    reader.onerror = () => reject(new Error('Failed to read file.'));
    reader.readAsText(file);
  });
}
