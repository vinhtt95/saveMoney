export type TransactionType = 'Expense' | 'Income' | 'Account' | 'Transfer';

export interface Category {
  id: string;
  name: string;
  type: 'Expense' | 'Income';
}

export interface Account {
  id: string;
  name: string;
}

export interface Transaction {
  id: string;
  date: Date;
  type: TransactionType;
  categoryId: string;
  accountId: string;
  transferToId: string;
  amount: number; // signed VND value (negative = expense)
}

export interface FilterState {
  search: string;
  categoryIds: string[];
  accountIds: string[];
  types: string[];
  dateStart: string | null; // 'YYYY-MM-DD'
  dateEnd: string | null;
}

export interface Budget {
  id: string;
  name: string;
  limit: number;       // VND
  dateStart: string;   // 'YYYY-MM-DD'
  dateEnd: string;     // 'YYYY-MM-DD'
  categoryIds: string[];
}

// Legacy v1 backup shape (for migration)
export interface DatabaseBackupV1 {
  version: 1;
  exportedAt: string;
  transactions: Array<{ id: string; date: string; type: TransactionType; category: string; account: string; transferTo: string; amount: number }>;
  expenseCategories: string[];
  incomeCategories: string[];
  accounts: string[];
  accountBalances: Record<string, number>;
  defaults: {
    defaultCategoryExpense: string;
    defaultCategoryIncome: string;
    defaultAccount: string;
  };
  budgets: Array<{ id: string; name: string; limit: number; dateStart: string; dateEnd: string; categories: string[] }>;
}

export interface DatabaseBackup {
  version: 2;
  exportedAt: string;
  transactions: Array<Omit<Transaction, 'date'> & { date: string }>;
  categories: Category[];
  accounts: Account[];
  accountBalances: Record<string, number>;
  defaults: {
    defaultCategoryExpenseId: string;
    defaultCategoryIncomeId: string;
    defaultAccountId: string;
  };
  budgets: Budget[];
}

export interface AppState {
  transactions: Transaction[];
  filters: FilterState;
  selectedPeriod: string; // 'all' | 'YYYY-MM'
  categories: Category[];
  accounts: Account[];
  accountBalances: Record<string, number>;
  defaultCategoryExpenseId: string;
  defaultCategoryIncomeId: string;
  defaultAccountId: string;
}
