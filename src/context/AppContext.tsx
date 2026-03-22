import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { Account, AppState, Category, DatabaseBackup, FilterState, Transaction } from '../types';
import { getAvailablePeriods } from '../utils/analytics';
import { toYYYYMM } from '../utils/formatters';
import { migrateStorageV1ToV2, CATEGORIES_V2_KEY, ACCOUNTS_V2_KEY } from '../utils/migration';

const STORAGE_KEY = 'savemoney_transactions';
const ACCOUNT_BALANCES_KEY = 'savemoney_account_balances';
const DEFAULTS_KEY = 'savemoney_defaults';

type Action =
  | { type: 'IMPORT'; transactions: Transaction[]; newCategories?: Category[]; newAccounts?: Account[] }
  | { type: 'CLEAR' }
  | { type: 'SET_FILTER'; filter: Partial<FilterState> }
  | { type: 'SET_PERIOD'; period: string }
  | { type: 'DELETE_TRANSACTION'; id: string }
  | { type: 'ADD_TRANSACTION'; transaction: Transaction }
  | { type: 'EDIT_TRANSACTION'; transaction: Transaction }
  | { type: 'SET_CATEGORIES'; categories: Category[] }
  | { type: 'ADD_CATEGORY'; category: Category }
  | { type: 'RENAME_CATEGORY'; id: string; newName: string }
  | { type: 'DELETE_CATEGORY'; id: string }
  | { type: 'SET_ACCOUNTS'; accounts: Account[] }
  | { type: 'SET_ACCOUNT_BALANCES'; accountBalances: Record<string, number> }
  | { type: 'RENAME_ACCOUNT'; id: string; newName: string }
  | { type: 'SET_DEFAULTS'; defaultCategoryExpenseId: string; defaultCategoryIncomeId: string; defaultAccountId: string }
  | { type: 'RESTORE_BACKUP'; backup: Omit<DatabaseBackup, 'budgets'> };

const defaultFilters: FilterState = {
  search: '',
  categoryIds: [],
  accountIds: [],
  types: [],
  dateStart: null,
  dateEnd: null,
};

const initialState: AppState = {
  transactions: [],
  filters: defaultFilters,
  selectedPeriod: toYYYYMM(new Date()),
  categories: [],
  accounts: [],
  accountBalances: {},
  defaultCategoryExpenseId: '',
  defaultCategoryIncomeId: '',
  defaultAccountId: '',
};

function serializeTransactions(txs: Transaction[]): string {
  return JSON.stringify(txs.map((t) => ({ ...t, date: t.date.toISOString() })));
}

function deserializeTransactions(raw: string): Transaction[] {
  try {
    const arr = JSON.parse(raw);
    return arr.map((t: Record<string, unknown>) => ({ ...t, date: new Date(t.date as string) }));
  } catch {
    return [];
  }
}

function loadJSON<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    if (raw) return JSON.parse(raw) as T;
  } catch { /* ignore */ }
  return fallback;
}

function loadFromStorage(): Pick<
  AppState,
  'transactions' | 'categories' | 'accounts' | 'accountBalances' |
  'defaultCategoryExpenseId' | 'defaultCategoryIncomeId' | 'defaultAccountId'
> {
  try {
    // Run v1→v2 migration if needed (idempotent)
    migrateStorageV1ToV2();

    const raw = localStorage.getItem(STORAGE_KEY);
    const transactions = raw ? deserializeTransactions(raw) : [];

    const categories = loadJSON<Category[]>(CATEGORIES_V2_KEY, []);
    const accounts = loadJSON<Account[]>(ACCOUNTS_V2_KEY, []);
    const accountBalances = loadJSON<Record<string, number>>(ACCOUNT_BALANCES_KEY, {});
    const defaults = loadJSON<Record<string, string>>(DEFAULTS_KEY, {});

    return {
      transactions,
      categories,
      accounts,
      accountBalances,
      defaultCategoryExpenseId: defaults.defaultCategoryExpenseId ?? '',
      defaultCategoryIncomeId: defaults.defaultCategoryIncomeId ?? '',
      defaultAccountId: defaults.defaultAccountId ?? '',
    };
  } catch {
    return {
      transactions: [],
      categories: [],
      accounts: [],
      accountBalances: {},
      defaultCategoryExpenseId: '',
      defaultCategoryIncomeId: '',
      defaultAccountId: '',
    };
  }
}

function mergeCategories(existing: Category[], incoming: Category[]): Category[] {
  const map = new Map(existing.map((c) => [c.id, c]));
  incoming.forEach((c) => { if (!map.has(c.id)) map.set(c.id, c); });
  return [...map.values()].sort((a, b) => a.name.localeCompare(b.name));
}

function mergeAccounts(existing: Account[], incoming: Account[]): Account[] {
  const map = new Map(existing.map((a) => [a.id, a]));
  incoming.forEach((a) => { if (!map.has(a.id)) map.set(a.id, a); });
  return [...map.values()].sort((a, b) => a.name.localeCompare(b.name));
}

function reducer(state: AppState, action: Action): AppState {
  switch (action.type) {
    case 'IMPORT': {
      const merged = [...state.transactions];
      const existingIds = new Set(state.transactions.map((t) => t.id));
      action.transactions.forEach((t) => {
        if (!existingIds.has(t.id)) merged.push(t);
      });
      const periods = getAvailablePeriods(merged);
      const latestPeriod = periods[0] || toYYYYMM(new Date());

      const newCategories = action.newCategories
        ? mergeCategories(state.categories, action.newCategories)
        : state.categories;
      const newAccounts = action.newAccounts
        ? mergeAccounts(state.accounts, action.newAccounts)
        : state.accounts;

      return {
        ...state,
        transactions: merged,
        selectedPeriod: latestPeriod,
        categories: newCategories,
        accounts: newAccounts,
      };
    }
    case 'CLEAR':
      return { ...initialState, accountBalances: {} };
    case 'SET_FILTER':
      return { ...state, filters: { ...state.filters, ...action.filter } };
    case 'SET_PERIOD':
      return { ...state, selectedPeriod: action.period };
    case 'DELETE_TRANSACTION':
      return {
        ...state,
        transactions: state.transactions.filter((t) => t.id !== action.id),
      };
    case 'ADD_TRANSACTION':
      return {
        ...state,
        transactions: [action.transaction, ...state.transactions],
      };
    case 'EDIT_TRANSACTION':
      return {
        ...state,
        transactions: state.transactions.map((t) =>
          t.id === action.transaction.id ? action.transaction : t
        ),
      };
    case 'SET_CATEGORIES':
      return { ...state, categories: action.categories };
    case 'ADD_CATEGORY': {
      if (state.categories.some((c) => c.id === action.category.id)) return state;
      return {
        ...state,
        categories: [...state.categories, action.category].sort((a, b) => a.name.localeCompare(b.name)),
      };
    }
    case 'RENAME_CATEGORY': {
      // No transaction updates needed — transactions reference by ID
      return {
        ...state,
        categories: state.categories.map((c) =>
          c.id === action.id ? { ...c, name: action.newName } : c
        ).sort((a, b) => a.name.localeCompare(b.name)),
      };
    }
    case 'DELETE_CATEGORY':
      return { ...state, categories: state.categories.filter((c) => c.id !== action.id) };
    case 'SET_ACCOUNTS':
      return { ...state, accounts: action.accounts };
    case 'SET_ACCOUNT_BALANCES':
      return { ...state, accountBalances: action.accountBalances };
    case 'RENAME_ACCOUNT': {
      // No transaction updates needed — transactions reference by ID
      return {
        ...state,
        accounts: state.accounts.map((a) =>
          a.id === action.id ? { ...a, name: action.newName } : a
        ).sort((a, b) => a.name.localeCompare(b.name)),
      };
    }
    case 'SET_DEFAULTS':
      return {
        ...state,
        defaultCategoryExpenseId: action.defaultCategoryExpenseId,
        defaultCategoryIncomeId: action.defaultCategoryIncomeId,
        defaultAccountId: action.defaultAccountId,
      };
    case 'RESTORE_BACKUP': {
      const { backup } = action;
      const transactions = backup.transactions.map((t) => ({ ...t, date: new Date(t.date) }));
      const periods = getAvailablePeriods(transactions);
      const latestPeriod = periods[0] || toYYYYMM(new Date());
      return {
        ...state,
        transactions,
        categories: backup.categories,
        accounts: backup.accounts,
        accountBalances: backup.accountBalances,
        defaultCategoryExpenseId: backup.defaults.defaultCategoryExpenseId,
        defaultCategoryIncomeId: backup.defaults.defaultCategoryIncomeId,
        defaultAccountId: backup.defaults.defaultAccountId,
        selectedPeriod: latestPeriod,
        filters: defaultFilters,
      };
    }
    default:
      return state;
  }
}

interface AppContextValue {
  state: AppState;
  dispatch: React.Dispatch<Action>;
}

const AppContext = createContext<AppContextValue | null>(null);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const stored = loadFromStorage();
  const [state, dispatch] = useReducer(reducer, {
    ...initialState,
    ...stored,
  });

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, serializeTransactions(state.transactions));
    } catch { /* ignore quota errors */ }
  }, [state.transactions]);

  useEffect(() => {
    try {
      localStorage.setItem(CATEGORIES_V2_KEY, JSON.stringify(state.categories));
    } catch { /* ignore */ }
  }, [state.categories]);

  useEffect(() => {
    try {
      localStorage.setItem(ACCOUNTS_V2_KEY, JSON.stringify(state.accounts));
    } catch { /* ignore */ }
  }, [state.accounts]);

  useEffect(() => {
    try {
      localStorage.setItem(ACCOUNT_BALANCES_KEY, JSON.stringify(state.accountBalances));
    } catch { /* ignore */ }
  }, [state.accountBalances]);

  useEffect(() => {
    try {
      localStorage.setItem(DEFAULTS_KEY, JSON.stringify({
        defaultCategoryExpenseId: state.defaultCategoryExpenseId,
        defaultCategoryIncomeId: state.defaultCategoryIncomeId,
        defaultAccountId: state.defaultAccountId,
      }));
    } catch { /* ignore */ }
  }, [state.defaultCategoryExpenseId, state.defaultCategoryIncomeId, state.defaultAccountId]);

  return <AppContext.Provider value={{ state, dispatch }}>{children}</AppContext.Provider>;
}

export function useApp(): AppContextValue {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used within AppProvider');
  return ctx;
}
