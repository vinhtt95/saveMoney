import { AppState, Budget, DatabaseBackup, DatabaseBackupV1 } from '../types';
import { migrateBackupV1 } from './migration';

export function exportDatabase(state: AppState): void {
  const budgets = state.budgets;

  const backup: DatabaseBackup = {
    version: 2,
    exportedAt: new Date().toISOString(),
    transactions: state.transactions.map((t) => ({ ...t, date: t.date.toISOString() })),
    categories: state.categories,
    accounts: state.accounts,
    accountBalances: state.accountBalances,
    defaults: {
      defaultCategoryExpenseId: state.defaultCategoryExpenseId,
      defaultCategoryIncomeId: state.defaultCategoryIncomeId,
      defaultAccountId: state.defaultAccountId,
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
        const parsed = JSON.parse(e.target?.result as string) as DatabaseBackup | DatabaseBackupV1;
        if (typeof parsed.version !== 'number' || !Array.isArray(parsed.transactions)) {
          reject(new Error('Invalid backup file format.'));
          return;
        }
        if (parsed.version === 1) {
          resolve(migrateBackupV1(parsed as DatabaseBackupV1));
        } else {
          resolve(parsed as DatabaseBackup);
        }
      } catch {
        reject(new Error('Failed to parse backup file.'));
      }
    };
    reader.onerror = () => reject(new Error('Failed to read file.'));
    reader.readAsText(file);
  });
}
