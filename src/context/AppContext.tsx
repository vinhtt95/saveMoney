import React, { createContext, useContext, useReducer, useEffect } from 'react';
import { AppState, FilterState, Transaction } from '../types';
import { getAvailablePeriods } from '../utils/analytics';
import { toYYYYMM } from '../utils/formatters';

const STORAGE_KEY = 'savemoney_transactions';

type Action =
  | { type: 'IMPORT'; transactions: Transaction[] }
  | { type: 'CLEAR' }
  | { type: 'SET_FILTER'; filter: Partial<FilterState> }
  | { type: 'SET_PERIOD'; period: string }
  | { type: 'DELETE_TRANSACTION'; id: string };

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

function loadFromStorage(): Transaction[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return deserializeTransactions(raw);
  } catch {
    // ignore
  }
  return [];
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
      return { ...state, transactions: merged, selectedPeriod: latestPeriod };
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
  const [state, dispatch] = useReducer(reducer, {
    ...initialState,
    transactions: loadFromStorage(),
  });

  // Persist transactions on change
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEY, serializeTransactions(state.transactions));
    } catch {
      // ignore quota errors
    }
  }, [state.transactions]);

  return <AppContext.Provider value={{ state, dispatch }}>{children}</AppContext.Provider>;
}

export function useApp(): AppContextValue {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used within AppProvider');
  return ctx;
}
