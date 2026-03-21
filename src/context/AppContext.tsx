import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { AppState, FilterState, Transaction } from '../types';
import { getAvailablePeriods } from '../utils/analytics';
import { toYYYYMM } from '../utils/formatters';

const STORAGE_KEY = 'savemoney_transactions';
const CATEGORIES_KEY = 'savemoney_categories';
const ACCOUNTS_KEY = 'savemoney_accounts';
const ACCOUNT_BALANCES_KEY = 'savemoney_account_balances';
const DEFAULTS_KEY = 'savemoney_defaults';

type Action =
  | { type: 'IMPORT'; transactions: Transaction[] }
  | { type: 'CLEAR' }
  | { type: 'SET_FILTER'; filter: Partial<FilterState> }
  | { type: 'SET_PERIOD'; period: string }
  | { type: 'DELETE_TRANSACTION'; id: string }
  | { type: 'ADD_TRANSACTION'; transaction: Transaction }
  | { type: 'EDIT_TRANSACTION'; transaction: Transaction }
  | { type: 'SET_CATEGORIES'; categories: string[] }
  | { type: 'SET_ACCOUNTS'; accounts: string[] }
  | { type: 'SET_ACCOUNT_BALANCES'; accountBalances: Record<string, number> }
  | { type: 'RENAME_ACCOUNT'; oldName: string; newName: string }
  | { type: 'SET_DEFAULTS'; defaultCategoryExpense: string; defaultCategoryIncome: string; defaultAccount: string };

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
  selectedPeriod: toYYYYMM(new Date()),
  categories: [],
  accounts: [],
  accountBalances: {},
  defaultCategoryExpense: '',
  defaultCategoryIncome: '',
  defaultAccount: '',
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

function loadDefaults(): { defaultCategoryExpense: string; defaultCategoryIncome: string; defaultAccount: string } {
  try {
    const raw = localStorage.getItem(DEFAULTS_KEY);
    if (raw) {
      const parsed = JSON.parse(raw) as Record<string, string>;
      return {
        // migrate from old key name "defaultCategory"
        defaultCategoryExpense: parsed.defaultCategoryExpense ?? parsed.defaultCategory ?? '',
        defaultCategoryIncome: parsed.defaultCategoryIncome ?? '',
        defaultAccount: parsed.defaultAccount ?? '',
      };
    }
  } catch { /* ignore */ }
  return { defaultCategoryExpense: '', defaultCategoryIncome: '', defaultAccount: '' };
}

function loadAccountBalances(): Record<string, number> {
  try {
    const raw = localStorage.getItem(ACCOUNT_BALANCES_KEY);
    if (raw) return JSON.parse(raw) as Record<string, number>;
  } catch { /* ignore */ }
  return {};
}

function loadFromStorage(): Pick<AppState, 'transactions' | 'categories' | 'accounts' | 'accountBalances' | 'defaultCategoryExpense' | 'defaultCategoryIncome' | 'defaultAccount'> {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    const defaults = loadDefaults();
    return {
      transactions: raw ? deserializeTransactions(raw) : [],
      categories: loadStringList(CATEGORIES_KEY),
      accounts: loadStringList(ACCOUNTS_KEY),
      accountBalances: loadAccountBalances(),
      ...defaults,
    };
  } catch {
    return { transactions: [], categories: [], accounts: [], accountBalances: {}, defaultCategoryExpense: '', defaultCategoryIncome: '', defaultAccount: '' };
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
    case 'SET_ACCOUNTS':
      return { ...state, accounts: action.accounts };
    case 'SET_ACCOUNT_BALANCES':
      return { ...state, accountBalances: action.accountBalances };
    case 'SET_DEFAULTS':
      return { ...state, defaultCategoryExpense: action.defaultCategoryExpense, defaultCategoryIncome: action.defaultCategoryIncome, defaultAccount: action.defaultAccount };
    case 'RENAME_ACCOUNT': {
      const { oldName, newName } = action;
      const newAccounts = state.accounts.map((a) => (a === oldName ? newName : a));
      const newBalances = { ...state.accountBalances };
      if (oldName in newBalances) {
        newBalances[newName] = newBalances[oldName];
        delete newBalances[oldName];
      }
      const newTransactions = state.transactions.map((t) => ({
        ...t,
        account: t.account === oldName ? newName : t.account,
        transferTo: t.transferTo === oldName ? newName : t.transferTo,
      }));
      return { ...state, accounts: newAccounts, accountBalances: newBalances, transactions: newTransactions };
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

  useEffect(() => {
    try {
      localStorage.setItem(ACCOUNT_BALANCES_KEY, JSON.stringify(state.accountBalances));
    } catch { /* ignore */ }
  }, [state.accountBalances]);

  useEffect(() => {
    try {
      localStorage.setItem(DEFAULTS_KEY, JSON.stringify({ defaultCategoryExpense: state.defaultCategoryExpense, defaultCategoryIncome: state.defaultCategoryIncome, defaultAccount: state.defaultAccount }));
    } catch { /* ignore */ }
  }, [state.defaultCategoryExpense, state.defaultCategoryIncome, state.defaultAccount]);

  return <AppContext.Provider value={{ state, dispatch }}>{children}</AppContext.Provider>;
}

export function useApp(): AppContextValue {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used within AppProvider');
  return ctx;
}
