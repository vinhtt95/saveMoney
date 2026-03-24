import React, { createContext, useContext, useEffect, useMemo, useReducer } from 'react';
import * as api from '../services/api';
import { Account, AppInitData, AppState, Budget, Category, DatabaseBackup, FilterState, GoldAsset, Transaction } from '../types';
import { getAvailablePeriods } from '../utils/analytics';
import { toYYYYMM } from '../utils/formatters';

type Action =
  | { type: 'HYDRATE'; data: AppInitData }
  | { type: 'IMPORT'; transactions: Transaction[]; newCategories?: Category[]; newAccounts?: Account[] }
  | { type: 'CLEAR' }
  | { type: 'ADD_GOLD_ASSET'; asset: GoldAsset }
  | { type: 'EDIT_GOLD_ASSET'; asset: GoldAsset }
  | { type: 'DELETE_GOLD_ASSET'; id: string }
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
  | { type: 'ADD_BUDGET'; budget: Budget }
  | { type: 'EDIT_BUDGET'; budget: Budget }
  | { type: 'DELETE_BUDGET'; id: string }
  | { type: 'SET_BUDGETS'; budgets: Budget[] }
  | { type: 'RESTORE_BACKUP'; backup: DatabaseBackup };

const defaultFilters: FilterState = {
  search: '',
  categoryIds: [],
  accountIds: [],
  types: [],
  dateStart: null,
  dateEnd: null,
};

const initialState: AppState = {
  isLoading: true,
  transactions: [],
  filters: defaultFilters,
  selectedPeriod: toYYYYMM(new Date()),
  categories: [],
  accounts: [],
  accountBalances: {},
  defaultCategoryExpenseId: '',
  defaultCategoryIncomeId: '',
  defaultAccountId: '',
  goldAssets: [],
  budgets: [],
};

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
    case 'HYDRATE': {
      const { data } = action;
      const transactions = data.transactions.map((t) => ({ ...t, date: new Date(t.date + 'T00:00:00') }));
      const periods = getAvailablePeriods(transactions);
      const latestPeriod = periods[0] || toYYYYMM(new Date());
      return {
        ...state,
        isLoading: false,
        transactions,
        categories: data.categories,
        accounts: data.accounts,
        accountBalances: data.accountBalances,
        goldAssets: data.goldAssets,
        budgets: data.budgets,
        defaultCategoryExpenseId: data.settings.defaultCategoryExpenseId ?? '',
        defaultCategoryIncomeId: data.settings.defaultCategoryIncomeId ?? '',
        defaultAccountId: data.settings.defaultAccountId ?? '',
        selectedPeriod: latestPeriod,
      };
    }
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
      return { ...initialState, isLoading: false, accountBalances: {} };
    case 'SET_FILTER':
      return { ...state, filters: { ...state.filters, ...action.filter } };
    case 'SET_PERIOD':
      return { ...state, selectedPeriod: action.period };
    case 'DELETE_TRANSACTION':
      return { ...state, transactions: state.transactions.filter((t) => t.id !== action.id) };
    case 'ADD_TRANSACTION':
      return { ...state, transactions: [action.transaction, ...state.transactions] };
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
    case 'RENAME_CATEGORY':
      return {
        ...state,
        categories: state.categories.map((c) =>
          c.id === action.id ? { ...c, name: action.newName } : c
        ).sort((a, b) => a.name.localeCompare(b.name)),
      };
    case 'DELETE_CATEGORY':
      return { ...state, categories: state.categories.filter((c) => c.id !== action.id) };
    case 'SET_ACCOUNTS':
      return { ...state, accounts: action.accounts };
    case 'SET_ACCOUNT_BALANCES':
      return { ...state, accountBalances: action.accountBalances };
    case 'RENAME_ACCOUNT':
      return {
        ...state,
        accounts: state.accounts.map((a) =>
          a.id === action.id ? { ...a, name: action.newName } : a
        ).sort((a, b) => a.name.localeCompare(b.name)),
      };
    case 'SET_DEFAULTS':
      return {
        ...state,
        defaultCategoryExpenseId: action.defaultCategoryExpenseId,
        defaultCategoryIncomeId: action.defaultCategoryIncomeId,
        defaultAccountId: action.defaultAccountId,
      };
    case 'ADD_GOLD_ASSET':
      return { ...state, goldAssets: [...state.goldAssets, action.asset] };
    case 'EDIT_GOLD_ASSET':
      return { ...state, goldAssets: state.goldAssets.map((a) => a.id === action.asset.id ? action.asset : a) };
    case 'DELETE_GOLD_ASSET':
      return { ...state, goldAssets: state.goldAssets.filter((a) => a.id !== action.id) };
    case 'ADD_BUDGET':
      return { ...state, budgets: [...state.budgets, action.budget] };
    case 'EDIT_BUDGET':
      return { ...state, budgets: state.budgets.map((b) => b.id === action.budget.id ? action.budget : b) };
    case 'DELETE_BUDGET':
      return { ...state, budgets: state.budgets.filter((b) => b.id !== action.id) };
    case 'SET_BUDGETS':
      return { ...state, budgets: action.budgets };
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
        budgets: backup.budgets,
        selectedPeriod: latestPeriod,
        filters: defaultFilters,
      };
    }
    default:
      return state;
  }
}

interface AppActions {
  addTransaction: (t: Transaction) => Promise<void>;
  editTransaction: (t: Transaction) => Promise<void>;
  deleteTransaction: (id: string) => Promise<void>;
  importData: (transactions: Transaction[], categories: Category[], accounts: Account[]) => Promise<void>;
  clearAll: () => Promise<void>;
  addCategory: (c: Category) => Promise<void>;
  renameCategory: (id: string, newName: string) => Promise<void>;
  deleteCategory: (id: string) => Promise<void>;
  addAccount: (a: Account) => Promise<void>;
  renameAccount: (id: string, newName: string) => Promise<void>;
  deleteAccount: (id: string) => Promise<void>;
  setAccountBalance: (accountId: string, balance: number) => Promise<void>;
  setDefaults: (expId: string, incId: string, accId: string) => Promise<void>;
  addGoldAsset: (a: GoldAsset) => Promise<void>;
  editGoldAsset: (a: GoldAsset) => Promise<void>;
  deleteGoldAsset: (id: string) => Promise<void>;
  addBudget: (b: Budget) => Promise<void>;
  editBudget: (b: Budget) => Promise<void>;
  deleteBudget: (id: string) => Promise<void>;
  restoreBackup: (backup: DatabaseBackup) => Promise<void>;
}

interface AppContextValue {
  state: AppState;
  dispatch: React.Dispatch<Action>;
  actions: AppActions;
}

const AppContext = createContext<AppContextValue | null>(null);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(reducer, initialState);

  // Load all data from MySQL on mount
  useEffect(() => {
    api.fetchInit().then((data) => {
      dispatch({ type: 'HYDRATE', data });
    }).catch((err) => {
      console.error('Failed to load data from server:', err);
      dispatch({ type: 'HYDRATE', data: { categories: [], accounts: [], accountBalances: {}, transactions: [], budgets: [], goldAssets: [], settings: {} } });
    });
  }, []);

  const actions = useMemo<AppActions>(() => ({
    async addTransaction(t) {
      await api.addTransaction(t);
      dispatch({ type: 'ADD_TRANSACTION', transaction: t });
    },
    async editTransaction(t) {
      await api.editTransaction(t);
      dispatch({ type: 'EDIT_TRANSACTION', transaction: t });
    },
    async deleteTransaction(id) {
      await api.deleteTransaction(id);
      dispatch({ type: 'DELETE_TRANSACTION', id });
    },
    async importData(transactions, categories, accounts) {
      await api.bulkAddTransactions(transactions, categories, accounts);
      dispatch({ type: 'IMPORT', transactions, newCategories: categories, newAccounts: accounts });
    },
    async clearAll() {
      await api.clearAllTransactions();
      dispatch({ type: 'CLEAR' });
    },
    async addCategory(c) {
      await api.addCategory(c);
      dispatch({ type: 'ADD_CATEGORY', category: c });
    },
    async renameCategory(id, newName) {
      await api.renameCategory(id, newName);
      dispatch({ type: 'RENAME_CATEGORY', id, newName });
    },
    async deleteCategory(id) {
      await api.deleteCategory(id);
      dispatch({ type: 'DELETE_CATEGORY', id });
    },
    async addAccount(a) {
      await api.addAccount(a);
      // Accounts are typically added through CSV import (bulkAddTransactions) or internal flows.
      // After adding, refetch to get the updated list.
      const data = await api.fetchInit();
      dispatch({ type: 'HYDRATE', data });
    },
    async renameAccount(id, newName) {
      await api.renameAccount(id, newName);
      dispatch({ type: 'RENAME_ACCOUNT', id, newName });
    },
    async deleteAccount(id) {
      await api.deleteAccount(id);
      dispatch({ type: 'SET_ACCOUNTS', accounts: [] }); // will re-fetch below
      const data = await api.fetchInit();
      dispatch({ type: 'HYDRATE', data });
    },
    async setAccountBalance(accountId, balance) {
      await api.setAccountBalance(accountId, balance);
      // Will be reflected in state via direct account balance update
    },
    async setDefaults(expId, incId, accId) {
      await api.saveSettings({ defaultCategoryExpenseId: expId, defaultCategoryIncomeId: incId, defaultAccountId: accId });
      dispatch({ type: 'SET_DEFAULTS', defaultCategoryExpenseId: expId, defaultCategoryIncomeId: incId, defaultAccountId: accId });
    },
    async addGoldAsset(a) {
      await api.addGoldAsset(a);
      dispatch({ type: 'ADD_GOLD_ASSET', asset: a });
    },
    async editGoldAsset(a) {
      await api.editGoldAsset(a);
      dispatch({ type: 'EDIT_GOLD_ASSET', asset: a });
    },
    async deleteGoldAsset(id) {
      await api.deleteGoldAsset(id);
      dispatch({ type: 'DELETE_GOLD_ASSET', id });
    },
    async addBudget(b) {
      await api.addBudget(b);
      dispatch({ type: 'ADD_BUDGET', budget: b });
    },
    async editBudget(b) {
      await api.editBudget(b);
      dispatch({ type: 'EDIT_BUDGET', budget: b });
    },
    async deleteBudget(id) {
      await api.deleteBudget(id);
      dispatch({ type: 'DELETE_BUDGET', id });
    },
    async restoreBackup(backup) {
      await api.restoreBackup(backup);
      dispatch({ type: 'RESTORE_BACKUP', backup });
    },
  }), []);

  if (state.isLoading) {
    return (
      <div className="flex h-screen items-center justify-center bg-slate-950">
        <p className="text-slate-400 text-sm">Loading...</p>
      </div>
    );
  }

  return <AppContext.Provider value={{ state, dispatch, actions }}>{children}</AppContext.Provider>;
}

export function useApp(): AppContextValue {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used within AppProvider');
  return ctx;
}
