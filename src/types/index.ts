export type TransactionType = 'Expense' | 'Income' | 'Account' | 'Transfer';

export interface Transaction {
  id: string;
  date: Date;
  type: TransactionType;
  category: string;
  account: string;
  transferTo: string;
  amount: number; // signed VND value (negative = expense)
}

export interface FilterState {
  search: string;
  categories: string[];
  accounts: string[];
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
  categories: string[];
}

export interface DatabaseBackup {
  version: number;
  exportedAt: string;
  transactions: Array<Omit<Transaction, 'date'> & { date: string }>;
  expenseCategories: string[];
  incomeCategories: string[];
  accounts: string[];
  accountBalances: Record<string, number>;
  defaults: {
    defaultCategoryExpense: string;
    defaultCategoryIncome: string;
    defaultAccount: string;
  };
  budgets: Budget[];
}

export interface AppState {
  transactions: Transaction[];
  filters: FilterState;
  selectedPeriod: string; // 'all' | 'YYYY-MM'
  expenseCategories: string[];
  incomeCategories: string[];
  accounts: string[];
  accountBalances: Record<string, number>;
  defaultCategoryExpense: string;
  defaultCategoryIncome: string;
  defaultAccount: string;
}
