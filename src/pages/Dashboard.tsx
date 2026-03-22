import React, { useState, useMemo, useEffect } from 'react';
import { AreaChart, Area, ResponsiveContainer, Tooltip, XAxis, YAxis, LineChart, Line } from 'recharts';
import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import { AddTransactionForm } from '../components/AddTransactionModal';
import { Draft, emptyDraft } from '../components/InlineFields';
import { InlineEditForm } from '../components/InlineEditForm';
import { Transaction, Budget as BudgetType } from '../types';
import {
  getExpenses,
  getTotalSpending,
  getTotalIncome,
  getAvgDaily,
  getCategoryBreakdown,
  getDailyTrend,
  filterByPeriod,
  getAvailablePeriods,
  getCategoryMonthMatrix,
  getCategoryDailyTrend,
  getCategoryWeeklyTrend,
  getCategoryMonthlyTrend,
} from '../utils/analytics';
import { formatVND, formatVNDShort, formatDate, formatMonth, toYYYYMM, toYYYYMMDD } from '../utils/formatters';
import { categoryName, accountName } from '../utils/lookup';
import { Category, Account } from '../types';

const BUDGET_CAT_COLORS = ['#144bb8', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#f97316', '#ec4899'];

function loadBudgets(): BudgetType[] {
  try {
    const raw = localStorage.getItem('savemoney_budgets');
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch { return []; }
}

function getBudgetStatus(pct: number): { label: string; badgeClass: string } {
  if (pct >= 100) return { label: 'Over budget', badgeClass: 'bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400' };
  if (pct >= 85) return { label: 'Critical', badgeClass: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400' };
  if (pct >= 65) return { label: 'On track', badgeClass: 'bg-primary/10 text-primary' };
  return { label: 'Good', badgeClass: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' };
}

const CATEGORY_ICONS: Record<string, { icon: string; color: string; bg: string }> = {
  Transport: { icon: 'directions_car', color: 'text-blue-600', bg: 'bg-blue-100 dark:bg-blue-900/30' },
  Coffee: { icon: 'local_cafe', color: 'text-amber-600', bg: 'bg-amber-100 dark:bg-amber-900/30' },
  Restaurant: { icon: 'restaurant', color: 'text-orange-600', bg: 'bg-orange-100 dark:bg-orange-900/30' },
  Gifts: { icon: 'card_giftcard', color: 'text-pink-600', bg: 'bg-pink-100 dark:bg-pink-900/30' },
  Rent: { icon: 'home', color: 'text-indigo-600', bg: 'bg-indigo-100 dark:bg-indigo-900/30' },
  Entertainment: { icon: 'theaters', color: 'text-purple-600', bg: 'bg-purple-100 dark:bg-purple-900/30' },
  Gas: { icon: 'local_gas_station', color: 'text-red-600', bg: 'bg-red-100 dark:bg-red-900/30' },
  Education: { icon: 'school', color: 'text-cyan-600', bg: 'bg-cyan-100 dark:bg-cyan-900/30' },
  Other: { icon: 'receipt_long', color: 'text-slate-600', bg: 'bg-slate-100 dark:bg-slate-800' },
  Allowance: { icon: 'payments', color: 'text-emerald-600', bg: 'bg-emerald-100 dark:bg-emerald-900/30' },
  Investment: { icon: 'trending_up', color: 'text-teal-600', bg: 'bg-teal-100 dark:bg-teal-900/30' },
  Income: { icon: 'payments', color: 'text-emerald-600', bg: 'bg-emerald-100 dark:bg-emerald-900/30' },
  'Balance update': { icon: 'account_balance', color: 'text-slate-600', bg: 'bg-slate-100 dark:bg-slate-800' },
};

function getCategoryIcon(category: string) {
  return CATEGORY_ICONS[category] || { icon: 'receipt_long', color: 'text-slate-600', bg: 'bg-slate-100 dark:bg-slate-800' };
}

function calcChange(current: number, previous: number): { pct: string; up: boolean; flat: boolean } {
  if (previous === 0) return { pct: 'N/A', up: true, flat: true };
  const pct = ((current - previous) / previous) * 100;
  return { pct: `${pct >= 0 ? '+' : ''}${pct.toFixed(0)}%`, up: pct >= 0, flat: Math.abs(pct) < 1 };
}

export function Dashboard() {
  const { state, dispatch } = useApp();
  const [showPeriodMenu, setShowPeriodMenu] = useState(false);
  const [showAddForm, setShowAddForm] = useState(false);
  const [expandedRow, setExpandedRow] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [draft, setDraft] = useState<Draft>(() => emptyDraft(state.defaultCategoryExpenseId, state.defaultCategoryIncomeId, state.defaultAccountId));
  const [editError, setEditError] = useState('');

  const allTxs = state.transactions;
  const period = state.selectedPeriod;
  const periods = useMemo(() => getAvailablePeriods(allTxs), [allTxs]);

  // Current period transactions
  const periodTxs = useMemo(() => filterByPeriod(allTxs, period), [allTxs, period]);

  // Previous period for comparison
  const prevPeriod = useMemo(() => {
    if (period === 'all') return 'all';
    const idx = periods.indexOf(period);
    return idx < periods.length - 1 ? periods[idx + 1] : null;
  }, [period, periods]);

  const prevTxs = useMemo(
    () => (prevPeriod ? filterByPeriod(allTxs, prevPeriod) : []),
    [allTxs, prevPeriod]
  );

  const totalSpending = useMemo(() => getTotalSpending(getExpenses(periodTxs)), [periodTxs]);
  const prevTotalSpending = useMemo(() => getTotalSpending(getExpenses(prevTxs)), [prevTxs]);
  const totalIncome = useMemo(() => getTotalIncome(periodTxs), [periodTxs]);
  const avgDaily = useMemo(() => getAvgDaily(periodTxs), [periodTxs]);
  const prevAvgDaily = useMemo(() => getAvgDaily(prevTxs), [prevTxs]);
  const txCount = useMemo(() => getExpenses(periodTxs).length, [periodTxs]);
  const prevTxCount = useMemo(() => getExpenses(prevTxs).length, [prevTxs]);
  const largestTx = useMemo(() => {
    const expenses = getExpenses(periodTxs);
    if (expenses.length === 0) return null;
    return expenses.reduce((max, t) => Math.abs(t.amount) > Math.abs(max.amount) ? t : max);
  }, [periodTxs]);
  const netFlow = totalIncome - totalSpending;

  const spendingChange = calcChange(totalSpending, prevTotalSpending);
  const avgChange = calcChange(avgDaily, prevAvgDaily);

  const dailyTrend = useMemo(() => {
    const data = getDailyTrend(periodTxs);
    return data.map((d) => ({ name: d.date.slice(5), value: d.amount }));
  }, [periodTxs]);

  const topCategories = useMemo(() => getCategoryBreakdown(getExpenses(periodTxs)).slice(0, 4), [periodTxs]);
  const maxCatTotal = topCategories[0]?.total || 1;

  // Recent transactions (expenses + income, last 10) grouped by date
  const groupedRecentTxs = useMemo(() => {
    const txs = [...periodTxs]
      .filter((t) => t.type === 'Expense' || t.type === 'Income')
      .sort((a, b) => b.date.getTime() - a.date.getTime())
      .slice(0, 10);
    const groups: { dateKey: string; date: Date; txs: typeof txs; dayIncome: number; dayExpense: number }[] = [];
    const map = new Map<string, typeof groups[0]>();
    for (const tx of txs) {
      const d = tx.date;
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
      if (!map.has(key)) {
        const group = { dateKey: key, date: tx.date, txs: [] as typeof txs, dayIncome: 0, dayExpense: 0 };
        map.set(key, group);
        groups.push(group);
      }
      const g = map.get(key)!;
      g.txs.push(tx);
      if (tx.type === 'Income') g.dayIncome += tx.amount;
      if (tx.type === 'Expense') g.dayExpense += Math.abs(tx.amount);
    }
    return groups;
  }, [periodTxs]);

  const { categories, accounts } = state;
  const expenseCategories = useMemo(() => categories.filter((c) => c.type === 'Expense'), [categories]);
  const incomeCategories = useMemo(() => categories.filter((c) => c.type === 'Income'), [categories]);

  function handleAddConfirm(tx: Transaction) {
    dispatch({ type: 'ADD_TRANSACTION', transaction: tx });
    setShowAddForm(false);
  }

  function draftFromTx(tx: Transaction): Draft {
    return {
      date: `${tx.date.getFullYear()}-${String(tx.date.getMonth() + 1).padStart(2, '0')}-${String(tx.date.getDate()).padStart(2, '0')}`,
      type: tx.type,
      categoryId: tx.categoryId,
      accountId: tx.accountId,
      transferToId: tx.transferToId,
      amountStr: String(Math.abs(tx.amount)),
    };
  }

  function draftToTx(d: Draft, id: string): Transaction | null {
    const amt = parseFloat(d.amountStr);
    const needsCategory = d.type !== 'Transfer';
    if (!d.date || (needsCategory && !d.categoryId) || !d.accountId || !d.amountStr || isNaN(amt) || amt <= 0) return null;
    if (d.type === 'Transfer' && !d.transferToId) return null;
    return {
      id,
      date: new Date(d.date),
      type: d.type,
      categoryId: d.categoryId,
      accountId: d.accountId,
      transferToId: d.transferToId,
      amount: d.type === 'Expense' ? -Math.abs(amt) : Math.abs(amt),
    };
  }

  function handleNewCategory(name: string, type: 'Expense' | 'Income'): string {
    const id = crypto.randomUUID();
    const cat: Category = { id, name, type };
    dispatch({ type: 'ADD_CATEGORY', category: cat });
    return id;
  }

  function handleNewAccount(name: string): string {
    const id = crypto.randomUUID();
    const acc: Account = { id, name };
    dispatch({ type: 'SET_ACCOUNTS', accounts: [...accounts, acc] });
    return id;
  }

  function startEdit(tx: Transaction) {
    setDraft(draftFromTx(tx));
    setEditError('');
    setEditingId(tx.id);
  }

  function cancelEdit() {
    setEditingId(null);
    setEditError('');
  }

  function confirmEdit(originalId: string) {
    const tx = draftToTx(draft, originalId);
    if (!tx) { setEditError('Vui lòng điền đầy đủ thông tin hợp lệ.'); return; }
    dispatch({ type: 'EDIT_TRANSACTION', transaction: tx });
    setEditingId(null);
    setEditError('');
  }

  // Budget section state
  const [budgets] = useState<BudgetType[]>(loadBudgets);
  const [selectedBudgetId, setSelectedBudgetId] = useState<string>(() => budgets[0]?.id || '');
  const [budgetTrendCat, setBudgetTrendCat] = useState<string>('');
  const [budgetGranularity, setBudgetGranularity] = useState<'day' | 'week' | 'month'>('week');

  const selectedBudget = useMemo(
    () => budgets.find((b) => b.id === selectedBudgetId) ?? budgets[0] ?? null,
    [budgets, selectedBudgetId]
  );

  const budgetMatchingTxs = useMemo(() => {
    if (!selectedBudget) return [];
    return allTxs.filter(
      (t) =>
        t.type === 'Expense' &&
        selectedBudget.categoryIds.includes(t.categoryId) &&
        toYYYYMMDD(t.date) >= selectedBudget.dateStart &&
        toYYYYMMDD(t.date) <= selectedBudget.dateEnd
    );
  }, [allTxs, selectedBudget]);

  const budgetSpent = useMemo(() => budgetMatchingTxs.reduce((s, t) => s + Math.abs(t.amount), 0), [budgetMatchingTxs]);
  const budgetPct = selectedBudget && selectedBudget.limit > 0 ? (budgetSpent / selectedBudget.limit) * 100 : 0;

  const budgetMatrixData = useMemo(() => {
    if (!selectedBudget || budgetMatchingTxs.length === 0) return [];
    const from = toYYYYMM(new Date(selectedBudget.dateStart + 'T00:00:00'));
    const to = toYYYYMM(new Date(selectedBudget.dateEnd + 'T00:00:00'));
    return getCategoryMonthMatrix(budgetMatchingTxs, from, to);
  }, [budgetMatchingTxs, selectedBudget]);

  const budgetMatrixCats = useMemo(() => {
    if (budgetMatrixData.length === 0) return [];
    const cats = Object.keys(budgetMatrixData[0]).filter((k) => k !== 'month');
    const totals: Record<string, number> = {};
    cats.forEach((cat) => { totals[cat] = budgetMatrixData.reduce((s, row) => s + ((row[cat] as number) || 0), 0); });
    return cats.sort((a, b) => totals[b] - totals[a]);
  }, [budgetMatrixData]);

  const budgetMatrixPeriods = useMemo(() => {
    if (!selectedBudget) return [];
    const from = toYYYYMM(new Date(selectedBudget.dateStart + 'T00:00:00'));
    const to = toYYYYMM(new Date(selectedBudget.dateEnd + 'T00:00:00'));
    return getAvailablePeriods(budgetMatchingTxs).filter((p) => p >= from && p <= to).slice().reverse();
  }, [budgetMatchingTxs, selectedBudget]);

  const budgetTrendData = useMemo((): { label: string; amount: number }[] => {
    if (!selectedBudget || !budgetTrendCat) return [];
    if (budgetGranularity === 'day') {
      return getCategoryDailyTrend(budgetMatchingTxs, budgetTrendCat, selectedBudget.dateStart, selectedBudget.dateEnd)
        .map((d) => ({ label: d.day, amount: d.amount }));
    } else if (budgetGranularity === 'week') {
      return getCategoryWeeklyTrend(budgetMatchingTxs, budgetTrendCat, selectedBudget.dateStart, selectedBudget.dateEnd)
        .map((d) => ({ label: d.week, amount: d.amount }));
    } else {
      return budgetMatrixPeriods.length > 0
        ? getCategoryMonthlyTrend(budgetMatchingTxs, budgetTrendCat, budgetMatrixPeriods).map((d) => ({ label: d.month, amount: d.amount }))
        : [];
    }
  }, [budgetMatchingTxs, budgetTrendCat, budgetGranularity, selectedBudget, budgetMatrixPeriods]);

  // Auto-select first category when budget changes
  useEffect(() => {
    setBudgetTrendCat(budgetMatrixCats[0] || '');
  }, [selectedBudget?.id, budgetMatrixCats]);

  const hasData = allTxs.length > 0;

  if (!hasData) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-4">
        <div className="size-16 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center">
          <span className="material-symbols-outlined text-3xl text-slate-400">account_balance_wallet</span>
        </div>
        <h2 className="text-xl font-bold text-slate-900 dark:text-white">No data yet</h2>
        <p className="text-slate-500 text-sm text-center max-w-sm">
          Import your Savey CSV file to start analyzing your finances.
        </p>
        <Link
          to="/settings"
          className="px-6 py-2 bg-primary text-white rounded-lg text-sm font-bold hover:opacity-90 transition-opacity"
        >
          Go to Settings → Import
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Overview</h2>
        <div className="relative">
          <button
            onClick={() => setShowPeriodMenu((v) => !v)}
            className="flex items-center gap-2 px-4 py-2 bg-slate-100 dark:bg-slate-800 rounded-lg text-sm font-semibold text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-slate-700"
          >
            <span>{formatMonth(period)}</span>
            <span className="material-symbols-outlined text-lg">expand_more</span>
          </button>
          {showPeriodMenu && (
            <div className="absolute right-0 mt-1 w-48 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl shadow-lg z-10 overflow-hidden">
              <button
                onClick={() => { dispatch({ type: 'SET_PERIOD', period: 'all' }); setShowPeriodMenu(false); }}
                className={`w-full text-left px-4 py-2 text-sm hover:bg-slate-50 dark:hover:bg-slate-800 ${period === 'all' ? 'font-bold text-primary' : ''}`}
              >
                All Time
              </button>
              {periods.map((p) => (
                <button
                  key={p}
                  onClick={() => { dispatch({ type: 'SET_PERIOD', period: p }); setShowPeriodMenu(false); }}
                  className={`w-full text-left px-4 py-2 text-sm hover:bg-slate-50 dark:hover:bg-slate-800 ${period === p ? 'font-bold text-primary' : ''}`}
                >
                  {formatMonth(p)}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6">
        <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex justify-between items-start mb-3">
            <div className="size-10 bg-rose-100 dark:bg-rose-900/30 rounded-lg flex items-center justify-center">
              <span className="material-symbols-outlined text-rose-600 text-xl">payments</span>
            </div>
            {!spendingChange.flat && (
              <span className={`flex items-center gap-0.5 px-2 py-0.5 rounded-full text-xs font-bold ${spendingChange.up ? 'text-rose-600 bg-rose-50 dark:bg-rose-900/30' : 'text-emerald-600 bg-emerald-50 dark:bg-emerald-900/30'}`}>
                <span className="material-symbols-outlined text-xs">{spendingChange.up ? 'arrow_upward' : 'arrow_downward'}</span>
                {spendingChange.pct}
              </span>
            )}
          </div>
          <h3 className="text-2xl font-bold text-slate-900 dark:text-white mt-3">{formatVND(totalSpending)}</h3>
          <p className="text-slate-500 text-sm font-medium mt-0.5">Total Spending</p>
          <p className="text-slate-400 text-xs mt-1">{prevPeriod ? `vs. ${formatMonth(prevPeriod)}` : 'all time'}</p>
        </div>

        <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex justify-between items-start mb-3">
            <div className="size-10 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center">
              <span className="material-symbols-outlined text-emerald-600 text-xl">trending_up</span>
            </div>
          </div>
          <h3 className="text-2xl font-bold text-emerald-600 mt-3">{formatVND(totalIncome)}</h3>
          <p className="text-slate-500 text-sm font-medium mt-0.5">Total Income</p>
          <p className={`text-xs mt-1 font-medium ${netFlow >= 0 ? 'text-emerald-500' : 'text-rose-500'}`}>
            Net: {netFlow >= 0 ? '+' : ''}{formatVND(netFlow)}
          </p>
        </div>

        <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex justify-between items-start mb-3">
            <div className="size-10 bg-primary/10 rounded-lg flex items-center justify-center">
              <span className="material-symbols-outlined text-primary text-xl">analytics</span>
            </div>
            {!avgChange.flat && (
              <span className={`flex items-center gap-0.5 px-2 py-0.5 rounded-full text-xs font-bold ${avgChange.up ? 'text-rose-600 bg-rose-50 dark:bg-rose-900/30' : 'text-emerald-600 bg-emerald-50 dark:bg-emerald-900/30'}`}>
                <span className="material-symbols-outlined text-xs">{avgChange.up ? 'arrow_upward' : 'arrow_downward'}</span>
                {avgChange.pct}
              </span>
            )}
          </div>
          <h3 className="text-2xl font-bold text-slate-900 dark:text-white mt-3">{formatVNDShort(avgDaily)}</h3>
          <p className="text-slate-500 text-sm font-medium mt-0.5">Avg Daily Spending</p>
          <p className="text-slate-400 text-xs mt-1">per day with expenses</p>
        </div>

        <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex justify-between items-start mb-3">
            <div className="size-10 bg-amber-100 dark:bg-amber-900/30 rounded-lg flex items-center justify-center">
              <span className="material-symbols-outlined text-amber-600 text-xl">receipt_long</span>
            </div>
            {prevTxCount > 0 && (
              <span className={`px-2 py-0.5 rounded-full text-xs font-bold ${txCount >= prevTxCount ? 'text-emerald-600 bg-emerald-50 dark:bg-emerald-900/30' : 'text-slate-500 bg-slate-100 dark:bg-slate-800'}`}>
                {txCount >= prevTxCount ? '+' : ''}{txCount - prevTxCount}
              </span>
            )}
          </div>
          <h3 className="text-2xl font-bold text-slate-900 dark:text-white mt-3">{txCount}</h3>
          <p className="text-slate-500 text-sm font-medium mt-0.5">Transactions</p>
          {largestTx && <p className="text-slate-400 text-xs mt-1">Largest: {formatVNDShort(Math.abs(largestTx.amount))}</p>}
        </div>
      </div>

      {/* Budget Section */}
      {budgets.length > 0 && selectedBudget && (
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
          {/* Header: title + budget selector */}
          <div className="p-5 border-b border-slate-100 dark:border-slate-800">
            <div className="flex items-center gap-3 flex-wrap">
              <h3 className="font-bold text-slate-900 dark:text-white shrink-0">Budget</h3>
              <div className="flex items-center gap-1.5 flex-wrap">
                {budgets.map((b) => (
                  <button
                    key={b.id}
                    onClick={() => setSelectedBudgetId(b.id)}
                    className={`px-3 py-1 rounded-full text-xs font-bold transition-colors ${
                      selectedBudget.id === b.id
                        ? 'bg-primary text-white'
                        : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700'
                    }`}
                  >
                    {b.name}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div className="p-5 space-y-6">
            {/* Budget progress overview */}
            <div className="flex items-center gap-4">
              <div className="flex-1 min-w-0">
                <div className="flex items-end justify-between mb-1.5">
                  <div>
                    <span className="text-lg font-bold text-slate-900 dark:text-white">{formatVND(budgetSpent)}</span>
                    <span className="text-sm text-slate-400 ml-1.5">/ {formatVND(selectedBudget.limit)}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className={`px-2 py-0.5 rounded-full text-xs font-bold ${getBudgetStatus(budgetPct).badgeClass}`}>
                      {getBudgetStatus(budgetPct).label}
                    </span>
                    <span className={`text-sm font-bold ${budgetPct >= 100 ? 'text-rose-600' : budgetPct >= 85 ? 'text-amber-600' : 'text-emerald-600'}`}>
                      {budgetPct.toFixed(0)}%
                    </span>
                  </div>
                </div>
                <div className="w-full bg-slate-100 dark:bg-slate-800 h-2 rounded-full overflow-hidden flex">
                  {budgetMatrixCats.length > 0 ? (
                    (() => {
                      const catMap = new Map<string, number>();
                      budgetMatchingTxs.forEach((t) => catMap.set(t.categoryId, (catMap.get(t.categoryId) ?? 0) + Math.abs(t.amount)));
                      return [...catMap.entries()].sort((a, b) => b[1] - a[1]).map(([cat, val], i) => (
                        <div
                          key={cat}
                          className="h-full"
                          style={{ width: `${Math.min((val / selectedBudget.limit) * 100, 100)}%`, backgroundColor: BUDGET_CAT_COLORS[i % BUDGET_CAT_COLORS.length] }}
                        />
                      ));
                    })()
                  ) : (
                    <div className="h-full rounded-full bg-primary" style={{ width: `${Math.min(budgetPct, 100)}%` }} />
                  )}
                </div>
                <div className="flex justify-between mt-1.5 text-xs text-slate-400">
                  <span>{budgetMatchingTxs.length} giao dịch · {formatDate(new Date(selectedBudget.dateStart + 'T00:00:00'))} → {formatDate(new Date(selectedBudget.dateEnd + 'T00:00:00'))}</span>
                  <span className={(selectedBudget.limit - budgetSpent) < 0 ? 'text-rose-600 font-medium' : ''}>
                    {(selectedBudget.limit - budgetSpent) >= 0 ? `Còn lại ${formatVND(selectedBudget.limit - budgetSpent)}` : `Vượt ${formatVND(Math.abs(selectedBudget.limit - budgetSpent))}`}
                  </span>
                </div>
              </div>
            </div>

            {budgetMatrixData.length === 0 ? (
              <div className="py-8 text-center text-slate-400 text-sm">Không có giao dịch trong budget này.</div>
            ) : (
              <div className="grid grid-cols-4 gap-5 items-stretch">
                {/* Line chart — 3/4 */}
                <div className="col-span-3 flex flex-col">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <p className="text-xs font-semibold text-slate-500 dark:text-slate-400">Chi tiêu theo danh mục</p>
                      {budgetTrendCat && (
                        <div className="flex items-center gap-1.5 px-2.5 py-1 bg-primary/10 rounded-lg">
                          <div className="size-2 rounded-full bg-primary" />
                          <span className="text-xs font-bold text-primary">{categoryName(categories, budgetTrendCat)}</span>
                        </div>
                      )}
                    </div>
                    <div className="flex items-center gap-1">
                      {(['day', 'week', 'month'] as const).map((g) => (
                        <button
                          key={g}
                          onClick={() => setBudgetGranularity(g)}
                          className={`px-2.5 py-1 text-xs font-bold rounded-lg transition-colors ${budgetGranularity === g ? 'bg-primary text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700'}`}
                        >
                          {g === 'day' ? 'Ngày' : g === 'week' ? 'Tuần' : 'Tháng'}
                        </button>
                      ))}
                    </div>
                  </div>
                  {budgetTrendData.length > 0 ? (
                    <div className="flex-1 min-h-0">
                      <ResponsiveContainer width="100%" height="100%">
                        <LineChart data={budgetTrendData} margin={{ top: 4, right: 8, left: 0, bottom: 0 }}>
                          <XAxis dataKey="label" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} interval="preserveStartEnd" />
                          <YAxis tickFormatter={(v) => formatVNDShort(v)} tick={{ fontSize: 10 }} tickLine={false} axisLine={false} width={72} />
                          <Tooltip formatter={(value: number) => [formatVND(value), categoryName(categories, budgetTrendCat)]} />
                          <Line type="monotone" dataKey="amount" stroke="#144bb8" strokeWidth={2} dot={{ r: 3, fill: '#144bb8' }} activeDot={{ r: 5 }} />
                        </LineChart>
                      </ResponsiveContainer>
                    </div>
                  ) : (
                    <div className="flex-1 flex items-center justify-center text-slate-400 text-sm">Không có dữ liệu.</div>
                  )}
                </div>

                {/* Category table — 1/4 */}
                <div className="col-span-1">
                  <p className="text-xs font-semibold text-slate-500 dark:text-slate-400 mb-2">
                    Danh mục · <span className="font-normal">Click để xem biểu đồ</span>
                  </p>
                  <div className="rounded-lg border border-slate-100 dark:border-slate-800 overflow-hidden">
                    <table className="w-full text-left text-sm">
                      <thead className="bg-slate-50 dark:bg-slate-800/50 text-slate-500 text-xs font-bold uppercase tracking-wider">
                        <tr>
                          <th className="px-3 py-2.5">Danh mục</th>
                          <th className="px-3 py-2.5 text-right">Tổng</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                        {budgetMatrixCats.map((catId, ci) => {
                          const isSel = budgetTrendCat === catId;
                          const total = budgetMatrixData.reduce((s, row) => s + ((row[catId] as number) || 0), 0);
                          return (
                            <tr
                              key={catId}
                              onClick={() => setBudgetTrendCat(catId)}
                              className={`cursor-pointer transition-colors ${isSel ? 'bg-primary/5 dark:bg-primary/10' : 'hover:bg-slate-50 dark:hover:bg-slate-800/50'}`}
                            >
                              <td className="px-3 py-2.5 font-medium">
                                <div className="flex items-center gap-1.5">
                                  <div className="size-2 rounded-full shrink-0" style={{ backgroundColor: BUDGET_CAT_COLORS[ci % BUDGET_CAT_COLORS.length] }} />
                                  <span className={`truncate text-xs ${isSel ? 'text-primary font-bold' : 'text-slate-700 dark:text-slate-300'}`}>{categoryName(categories, catId)}</span>
                                </div>
                              </td>
                              <td className={`px-3 py-2.5 text-right text-xs font-bold whitespace-nowrap ${isSel ? 'text-primary' : 'text-slate-700 dark:text-slate-300'}`}>
                                {formatVNDShort(total)}
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <h3 className="font-bold text-slate-900 dark:text-white">Spending Trend</h3>
            <span className="text-xs text-slate-400">{formatMonth(period)}</span>
          </div>
          <div className="h-64 w-full">
            {dailyTrend.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={dailyTrend}>
                  <defs>
                    <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#144bb8" stopOpacity={0.2} />
                      <stop offset="95%" stopColor="#144bb8" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <XAxis dataKey="name" tick={{ fontSize: 10 }} tickLine={false} axisLine={false} />
                  <Tooltip
                    formatter={(value: number) => [formatVND(value), 'Spending']}
                    contentStyle={{ fontSize: 12 }}
                  />
                  <Area
                    type="monotone"
                    dataKey="value"
                    stroke="#144bb8"
                    strokeWidth={3}
                    fillOpacity={1}
                    fill="url(#colorValue)"
                  />
                </AreaChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-full flex items-center justify-center text-slate-400 text-sm">No data for this period</div>
            )}
          </div>
        </div>

        <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <h3 className="font-bold text-slate-900 dark:text-white">Top Categories</h3>
          </div>
          {topCategories.length > 0 ? (
            <div className="space-y-4">
              {topCategories.map((cat) => {
                const name = categoryName(categories, cat.categoryId);
                const icon = getCategoryIcon(name);
                return (
                <div key={cat.categoryId} className="space-y-2">
                  <div className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2">
                      <div className={`size-7 rounded-lg ${icon.bg} ${icon.color} flex items-center justify-center`}>
                        <span className="material-symbols-outlined text-base">{icon.icon}</span>
                      </div>
                      <span className="font-medium text-slate-700 dark:text-slate-300">{name}</span>
                    </div>
                    <div className="text-right">
                      <span className="text-slate-900 dark:text-white font-bold">{formatVNDShort(cat.total)}</span>
                      <span className="text-slate-400 text-xs ml-1">({cat.percent.toFixed(0)}%)</span>
                    </div>
                  </div>
                  <div className="w-full bg-slate-100 dark:bg-slate-800 h-2 rounded-full overflow-hidden">
                    <div
                      className="bg-primary h-full rounded-full transition-all"
                      style={{ width: `${(cat.total / maxCatTotal) * 100}%` }}
                    ></div>
                  </div>
                </div>
                );
              })}
            </div>
          ) : (
            <div className="h-40 flex items-center justify-center text-slate-400 text-sm">No expenses for this period</div>
          )}
        </div>
      </div>

      {/* Recent Transactions */}
      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
        <div className="p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
          <h3 className="font-bold text-slate-900 dark:text-white">Recent Transactions</h3>
          <div className="flex items-center gap-3">
            <button
              onClick={() => setShowAddForm((v) => !v)}
              className="flex items-center gap-1.5 px-3 py-1.5 bg-primary text-white rounded-lg text-sm font-semibold hover:opacity-90 transition-opacity"
            >
              <span className="material-symbols-outlined text-sm">add</span>
              Thêm
            </button>
            <Link to="/transactions" className="text-sm font-semibold text-primary dark:text-slate-300 hover:underline">
              View All
            </Link>
          </div>
        </div>
        {showAddForm && (
          <div className="p-4 border-b border-slate-100 dark:border-slate-800">
            <AddTransactionForm
              open={showAddForm}
              onClose={() => setShowAddForm(false)}
              onConfirm={handleAddConfirm}
              expenseCategories={expenseCategories}
              incomeCategories={incomeCategories}
              allAccounts={accounts}
              defaultCategoryExpenseId={state.defaultCategoryExpenseId}
              defaultCategoryIncomeId={state.defaultCategoryIncomeId}
              defaultAccountId={state.defaultAccountId}
              onNewCategory={handleNewCategory}
              onNewAccount={handleNewAccount}
            />
          </div>
        )}
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-slate-50 dark:bg-slate-800/50 text-slate-500 text-xs font-bold uppercase tracking-wider">
              <tr>
                <th className="px-6 py-3">Category</th>
                <th className="px-6 py-3">Account</th>
                <th className="px-6 py-3 text-right">Amount</th>
              </tr>
            </thead>
            <tbody>
              {groupedRecentTxs.map((group) => (
                <React.Fragment key={group.dateKey}>
                  <tr className="bg-slate-50 dark:bg-slate-800/70 border-t-2 border-slate-200 dark:border-slate-700">
                    <td className="px-6 py-3">
                      <span className="text-sm font-bold text-slate-700 dark:text-slate-200">
                        {formatDate(group.date)}
                      </span>
                    </td>
                    <td className="px-6 py-3 text-sm font-medium text-slate-500 dark:text-slate-400">
                      {group.txs.length} giao dịch
                    </td>
                    <td className="px-6 py-3 text-right">
                      <div className="flex items-center justify-end gap-4 text-sm font-bold">
                        {group.dayIncome > 0 && <span className="text-emerald-600">+{formatVND(group.dayIncome)}</span>}
                        {group.dayExpense > 0 && <span className="text-rose-600">-{formatVND(group.dayExpense)}</span>}
                      </div>
                    </td>
                  </tr>
                  {group.txs.map((tx) => {
                    const txCatName = categoryName(categories, tx.categoryId);
                    const txAccName = accountName(accounts, tx.accountId);
                    const icon = getCategoryIcon(txCatName);
                    const isExpense = tx.type === 'Expense';
                    const isExpanded = expandedRow === tx.id;
                    return (
                      <React.Fragment key={tx.id}>
                        <tr
                          className={`hover:bg-slate-50/50 dark:hover:bg-slate-800/50 transition-colors border-t border-slate-100 dark:border-slate-800 cursor-pointer ${isExpanded ? (tx.type === 'Expense' ? 'bg-rose-50 dark:bg-rose-900/20' : tx.type === 'Income' ? 'bg-emerald-50 dark:bg-emerald-900/20' : 'bg-blue-50 dark:bg-blue-900/20') : ''}`}
                          onClick={() => {
                            if (isExpanded) {
                              setExpandedRow(null);
                              cancelEdit();
                            } else {
                              setExpandedRow(tx.id);
                              startEdit(tx);
                            }
                          }}
                        >
                          <td className="px-6 py-3">
                            <div className="flex items-center gap-2 pl-4">
                              <div className={`size-7 rounded ${icon.bg} ${icon.color} flex items-center justify-center`}>
                                <span className="material-symbols-outlined text-base">{icon.icon}</span>
                              </div>
                              <span className="text-sm font-medium">{txCatName}</span>
                            </div>
                          </td>
                          <td className="px-6 py-3 text-sm text-slate-500 dark:text-slate-400">{txAccName}</td>
                          <td className={`px-6 py-3 text-right text-sm font-bold ${isExpense ? 'text-rose-600' : 'text-emerald-600'}`}>
                            {isExpense ? '-' : '+'}{formatVND(tx.amount)}
                          </td>
                        </tr>

                        {isExpanded && (
                          <tr className={tx.type === 'Expense' ? 'bg-rose-50 dark:bg-rose-900/20' : tx.type === 'Income' ? 'bg-emerald-50 dark:bg-emerald-900/20' : 'bg-blue-50 dark:bg-blue-900/20'}>
                            <td colSpan={3} className="px-6 py-5 border-t border-primary/10">
                              <InlineEditForm
                                draft={draft}
                                onChange={(patch) => setDraft((d) => ({ ...d, ...patch }))}
                                expenseCategories={expenseCategories}
                                incomeCategories={incomeCategories}
                                allAccounts={accounts}
                                error={editError}
                                onSave={() => confirmEdit(tx.id)}
                                onCancel={() => { setExpandedRow(null); cancelEdit(); }}
                                onDelete={() => {
                                  if (confirm('Xóa giao dịch này?')) {
                                    dispatch({ type: 'DELETE_TRANSACTION', id: tx.id });
                                    setExpandedRow(null);
                                  }
                                }}
                                onNewCategory={handleNewCategory}
                                onNewAccount={handleNewAccount}
                              />
                            </td>
                          </tr>
                        )}
                      </React.Fragment>
                    );
                  })}
                </React.Fragment>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
