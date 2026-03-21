import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { AppState, FilterState, Transaction } from '../types';
import { getAvailablePeriods } from '../utils/analytics';
import { toYYYYMM } from '../utils/formatters';

const STORAGE_KEY = 'savemoney_transactions';
const CATEGORIES_KEY = 'savemoney_categories';
const ACCOUNTS_KEY = 'savemoney_accounts';

type Action =
  | { type: 'IMPORT'; transactions: Transaction[] }
  | { type: 'CLEAR' }
  | { type: 'SET_FILTER'; filter: Partial<FilterState> }
  | { type: 'SET_PERIOD'; period: string }
  | { type: 'DELETE_TRANSACTION'; id: string }
  | { type: 'ADD_TRANSACTION'; transaction: Transaction }
  | { type: 'EDIT_TRANSACTION'; transaction: Transaction }
  | { type: 'SET_CATEGORIES'; categories: string[] }
  | { type: 'SET_ACCOUNTS'; accounts: string[] };

const defaultFilters: FilterState = {
  search: '',
  categories: [],
  accounts: [],
  types: [],
  dateStart: null,
  dateEnd: null,
};

const initialState: AppState = {
  transactions: [],
  filters: defaultFilters,
  selectedPeriod: 'all',
  categories: [],
  accounts: [],
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

function loadStringList(key: string): string[] {
  try {
    const raw = localStorage.getItem(key);
    if (raw) return JSON.parse(raw) as string[];
  } catch {
    // ignore
  }
  return [];
}

function loadFromStorage(): Pick<AppState, 'transactions' | 'categories' | 'accounts'> {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return {
      transactions: raw ? deserializeTransactions(raw) : [],
      categories: loadStringList(CATEGORIES_KEY),
      accounts: loadStringList(ACCOUNTS_KEY),
    };
  } catch {
    return { transactions: [], categories: [], accounts: [] };
  }
}

function mergeUnique(existing: string[], incoming: string[]): string[] {
  const set = new Set(existing);
  incoming.forEach((v) => { if (v) set.add(v); });
  return [...set].sort();
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
      // Auto-detect categories and accounts from imported transactions
      const newCategories = mergeUnique(
        state.categories,
        action.transactions.map((t) => t.category).filter(Boolean)
      );
      const newAccounts = mergeUnique(
        state.accounts,
        action.transactions.flatMap((t) => [t.account, t.transferTo]).filter(Boolean)
      );
      return {
        ...state,
        transactions: merged,
        selectedPeriod: latestPeriod,
        categories: newCategories,
        accounts: newAccounts,
      };
    }
    case 'CLEAR':
      return { ...initialState };
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
    case 'SET_ACCOUNTS':
      return { ...state, accounts: action.accounts };
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
    } catch {
      // ignore quota errors
    }
  }, [state.transactions]);

  useEffect(() => {
    try {
      localStorage.setItem(CATEGORIES_KEY, JSON.stringify(state.categories));
    } catch { /* ignore */ }
  }, [state.categories]);

  useEffect(() => {
    try {
      localStorage.setItem(ACCOUNTS_KEY, JSON.stringify(state.accounts));
    } catch { /* ignore */ }
  }, [state.accounts]);

  return <AppContext.Provider value={{ state, dispatch }}>{children}</AppContext.Provider>;
}

export function useApp(): AppContextValue {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used within AppProvider');
  return ctx;
}
