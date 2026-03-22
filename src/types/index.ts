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

// --- Gold Price Types ---

export interface GoldProductPrice {
  name: string;          // Vietnamese product name
  buyPrice: number;      // VND per lượng
  sellPrice: number;     // VND per lượng
}

export interface GoldSourceData {
  source: 'SJC' | 'BTMC';
  products: GoldProductPrice[];
  fetchedAt: string;     // ISO timestamp
}

export interface WorldGoldData {
  spot: number;              // XAUUSD spot price, USD per troy oz
  futures: number;           // GC=F futures price, USD per troy oz
  usdvnd: number;            // VND per 1 USD
  spotPerLuong: number;      // spot * (37.5/31.1035) * usdvnd
  futuresPerLuong: number;   // futures * (37.5/31.1035) * usdvnd
  fetchedAt: string;
}

export interface GoldPriceCache {
  world: WorldGoldData | null;
  sjc: GoldSourceData | null;
  btmc: GoldSourceData | null;
  cachedAt: string;
}

// --- Wealth / Asset Types ---

export type GoldBrand = 'SJC' | 'BTMC' | 'world';

export interface GoldAsset {
  id: string;
  brand: GoldBrand;
  productId?: string;  // stable ID referencing GoldProduct.id
  productName: string; // product name from price list, or 'Spot' for world
  quantity: number;    // in lượng
  note?: string;
  createdAt: string;   // ISO timestamp
}

// --- Gold Product Registry ---

export interface GoldProduct {
  id: string;        // e.g. 'sjc_001', 'btmc_003', 'world_spot', 'world_futures'
  brand: GoldBrand;
  name: string;      // display name (may update over time; ID stays stable)
  sortOrder: number; // position in source array — stable identity anchor
}

export interface GoldProductRegistry {
  products: GoldProduct[];
  version: number;
  updatedAt: string;
}

// --- Gold Price History ---

export interface GoldPricePoint {
  productId: string;
  buyPrice: number;   // VND per lượng
  sellPrice: number;  // VND per lượng
}

export interface GoldPriceSnapshot {
  date: string;        // 'YYYY-MM-DD'
  recordedAt: string;  // full ISO timestamp
  prices: GoldPricePoint[];
  world: {
    spot: number;
    futures: number;
    usdvnd: number;
    spotPerLuong: number;
    futuresPerLuong: number;
  } | null;
}

export interface GoldPriceHistory {
  snapshots: GoldPriceSnapshot[];
  version: 1;
}

export interface AppState {
  isLoading: boolean;
  transactions: Transaction[];
  filters: FilterState;
  selectedPeriod: string; // 'all' | 'YYYY-MM'
  categories: Category[];
  accounts: Account[];
  accountBalances: Record<string, number>;
  defaultCategoryExpenseId: string;
  defaultCategoryIncomeId: string;
  defaultAccountId: string;
  goldAssets: GoldAsset[];
  budgets: Budget[];
}

export interface AppInitData {
  categories: Category[];
  accounts: Account[];
  accountBalances: Record<string, number>;
  transactions: Array<Omit<Transaction, 'date'> & { date: string }>;
  budgets: Budget[];
  goldAssets: GoldAsset[];
  settings: Record<string, string>;
}
