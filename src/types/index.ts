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

export interface AppState {
  transactions: Transaction[];
  filters: FilterState;
  selectedPeriod: string; // 'all' | 'YYYY-MM'
  categories: string[];
  accounts: string[];
}
