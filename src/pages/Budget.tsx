import { useState, useMemo, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import {
  getExpenses,
  getTotalSpending,
  getTotalIncome,
  getCategoryBreakdown,
  filterByPeriod,
  getAvailablePeriods,
} from '../utils/analytics';
import { formatVND, formatVNDShort, formatMonth, toYYYYMM } from '../utils/formatters';

const BUDGET_STORAGE_KEY = 'savemoney_budgets';

type BudgetMap = { [category: string]: number }; // category -> monthly limit (VND)

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
  Shopping: { icon: 'shopping_bag', color: 'text-violet-600', bg: 'bg-violet-100 dark:bg-violet-900/30' },
  Health: { icon: 'favorite', color: 'text-rose-600', bg: 'bg-rose-100 dark:bg-rose-900/30' },
  Food: { icon: 'restaurant', color: 'text-orange-600', bg: 'bg-orange-100 dark:bg-orange-900/30' },
};

function getCategoryIcon(category: string) {
  return CATEGORY_ICONS[category] || { icon: 'category', color: 'text-slate-600', bg: 'bg-slate-100 dark:bg-slate-800' };
}

function loadBudgets(): BudgetMap {
  try {
    const raw = localStorage.getItem(BUDGET_STORAGE_KEY);
    return raw ? JSON.parse(raw) : {};
  } catch {
    return {};
  }
}

function saveBudgets(budgets: BudgetMap) {
  localStorage.setItem(BUDGET_STORAGE_KEY, JSON.stringify(budgets));
}

function getBudgetStatus(pct: number): { label: string; barColor: string; badgeClass: string } {
  if (pct >= 100) return { label: 'Over budget', barColor: 'bg-rose-500', badgeClass: 'bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400' };
  if (pct >= 85) return { label: 'Critical', barColor: 'bg-amber-500', badgeClass: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400' };
  if (pct >= 65) return { label: 'On track', barColor: 'bg-primary', badgeClass: 'bg-primary/10 text-primary dark:bg-primary/20' };
  return { label: 'Good', barColor: 'bg-emerald-500', badgeClass: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' };
}

export function Budget() {
  const { state } = useApp();
  const [budgets, setBudgets] = useState<BudgetMap>(loadBudgets);
  const [editingCategory, setEditingCategory] = useState<string | null>(null);
  const [editValue, setEditValue] = useState('');

  useEffect(() => {
    saveBudgets(budgets);
  }, [budgets]);

  const { transactions, selectedPeriod } = state;
  const periods = useMemo(() => getAvailablePeriods(transactions), [transactions]);
  const period = selectedPeriod === 'all' ? (periods[0] || toYYYYMM(new Date())) : selectedPeriod;

  const periodTxs = useMemo(() => filterByPeriod(transactions, period), [transactions, period]);
  const expenses = useMemo(() => getExpenses(periodTxs), [periodTxs]);
  const totalSpending = useMemo(() => getTotalSpending(expenses), [expenses]);
  const totalIncome = useMemo(() => getTotalIncome(periodTxs), [periodTxs]);
  const categoryBreakdown = useMemo(() => getCategoryBreakdown(expenses), [expenses]);

  // Overall budget (sum of all set limits)
  const totalBudget = (Object.values(budgets) as number[]).reduce((a: number, b: number) => a + b, 0);
  const overallPct = totalBudget > 0 ? Math.min((totalSpending / totalBudget) * 100, 100) : 0;

  // Month-end forecast: project spending to end of month
  const today = new Date();
  const [y, m] = period.split('-').map(Number);
  const daysInMonth = new Date(y, m, 0).getDate();
  const dayOfMonth = (period === toYYYYMM(today)) ? today.getDate() : daysInMonth;
  const forecastedSpending = dayOfMonth > 0 ? (totalSpending / dayOfMonth) * daysInMonth : totalSpending;

  const categoriesWithBudget = categoryBreakdown.map((cat) => ({
    ...cat,
    limit: budgets[cat.category] || 0,
    pct: budgets[cat.category] ? Math.min((cat.total / budgets[cat.category]) * 100, 110) : 0,
  }));

  const budgetedCategories = categoriesWithBudget.filter((c) => c.limit > 0);
  const unbudgetedCategories = categoriesWithBudget.filter((c) => c.limit === 0);

  function startEdit(cat: string, current: number) {
    setEditingCategory(cat);
    setEditValue(current > 0 ? String(current) : '');
  }

  function saveEdit() {
    if (!editingCategory) return;
    const val = parseFloat(editValue.replace(/,/g, ''));
    if (!isNaN(val) && val > 0) {
      setBudgets((prev) => ({ ...prev, [editingCategory]: val }));
    } else if (editValue === '' || val === 0) {
      setBudgets((prev) => {
        const next = { ...prev };
        delete next[editingCategory];
        return next;
      });
    }
    setEditingCategory(null);
  }

  if (transactions.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-4">
        <div className="size-16 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center">
          <span className="material-symbols-outlined text-3xl text-slate-400">account_balance_wallet</span>
        </div>
        <h2 className="text-xl font-bold text-slate-900 dark:text-white">No data yet</h2>
        <p className="text-slate-500 text-sm">Import your CSV to start tracking budgets.</p>
        <Link to="/settings" className="px-6 py-2 bg-primary text-white rounded-lg text-sm font-bold hover:opacity-90 transition-opacity">
          Import Data
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Budget Tracking</h2>
          <p className="text-slate-500 dark:text-slate-400 text-sm mt-0.5">{formatMonth(period)} — Set limits per category and track your spending.</p>
        </div>
      </div>

      {/* Overview cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {/* Spending utilization */}
        <div className="sm:col-span-2 bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-xs font-bold uppercase tracking-wider text-slate-400">Overall Spending</p>
              <p className="text-2xl font-bold text-slate-900 dark:text-white mt-1">
                {formatVNDShort(totalSpending)}
                {totalBudget > 0 && <span className="text-base font-normal text-slate-400 ml-2">/ {formatVNDShort(totalBudget)}</span>}
              </p>
            </div>
            {totalBudget > 0 && (
              <span className={`text-2xl font-black ${overallPct >= 100 ? 'text-rose-600' : overallPct >= 85 ? 'text-amber-600' : 'text-emerald-600'}`}>
                {overallPct.toFixed(0)}%
              </span>
            )}
          </div>
          {totalBudget > 0 ? (
            <>
              <div className="w-full bg-slate-100 dark:bg-slate-800 h-3 rounded-full overflow-hidden">
                <div
                  className={`h-full rounded-full transition-all ${overallPct >= 100 ? 'bg-rose-500' : overallPct >= 85 ? 'bg-amber-500' : 'bg-primary'}`}
                  style={{ width: `${Math.min(overallPct, 100)}%` }}
                ></div>
              </div>
              <p className="text-xs text-slate-400 mt-2">
                {formatVNDShort(Math.max(totalBudget - totalSpending, 0))} remaining
              </p>
            </>
          ) : (
            <p className="text-sm text-slate-400 mt-2">Set category budgets below to track utilization.</p>
          )}
        </div>

        {/* Month-end forecast */}
        <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <p className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-1">Month-End Forecast</p>
          <div className="flex items-center gap-2 mt-3">
            <span className={`material-symbols-outlined ${forecastedSpending > totalBudget && totalBudget > 0 ? 'text-rose-500' : 'text-emerald-500'}`}>
              {forecastedSpending > totalSpending ? 'trending_up' : 'trending_flat'}
            </span>
            <span className="text-2xl font-bold text-slate-900 dark:text-white">{formatVNDShort(forecastedSpending)}</span>
          </div>
          <p className="text-xs text-slate-400 mt-2">Projected based on {dayOfMonth} days of spending</p>
          {totalBudget > 0 && forecastedSpending > totalBudget && (
            <div className="mt-3 p-2 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800/50">
              <p className="text-xs text-rose-600 dark:text-rose-400 font-medium">
                On track to exceed budget by {formatVNDShort(forecastedSpending - totalBudget)}
              </p>
            </div>
          )}
          {totalBudget > 0 && forecastedSpending <= totalBudget && (
            <div className="mt-3 p-2 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800/50">
              <p className="text-xs text-emerald-600 dark:text-emerald-400 font-medium">
                On track to save {formatVNDShort(totalBudget - forecastedSpending)}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Income summary */}
      {totalIncome > 0 && (
        <div className="bg-primary/5 dark:bg-primary/10 border border-primary/20 rounded-xl p-4 flex items-center gap-4">
          <span className="material-symbols-outlined text-primary text-2xl">savings</span>
          <div>
            <p className="text-sm font-bold text-primary">Income this period: {formatVNDShort(totalIncome)}</p>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
              Savings rate: {totalIncome > 0 ? ((( totalIncome - totalSpending) / totalIncome) * 100).toFixed(0) : 0}% — Net: {formatVNDShort(totalIncome - totalSpending)}
            </p>
          </div>
        </div>
      )}

      {/* Budgeted categories */}
      {budgetedCategories.length > 0 && (
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
          <div className="p-6 border-b border-slate-100 dark:border-slate-800">
            <h3 className="font-bold text-slate-900 dark:text-white">Budget Categories</h3>
          </div>
          <div className="divide-y divide-slate-100 dark:divide-slate-800">
            {budgetedCategories.map((cat) => {
              const icon = getCategoryIcon(cat.category);
              const status = getBudgetStatus(cat.pct);
              return (
                <div key={cat.category} className="p-5">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-3">
                      <div className={`size-9 rounded-lg ${icon.bg} ${icon.color} flex items-center justify-center`}>
                        <span className="material-symbols-outlined text-lg">{icon.icon}</span>
                      </div>
                      <div>
                        <p className="font-semibold text-slate-800 dark:text-slate-200 text-sm">{cat.category}</p>
                        <p className="text-xs text-slate-400">{cat.count} transactions</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <div className="text-right">
                        <p className="text-sm font-bold text-slate-900 dark:text-white">{formatVNDShort(cat.total)}</p>
                        <p className="text-xs text-slate-400">of {formatVNDShort(cat.limit)}</p>
                      </div>
                      <span className={`px-2 py-1 rounded-full text-xs font-bold ${status.badgeClass}`}>{status.label}</span>
                      <button
                        onClick={() => startEdit(cat.category, cat.limit)}
                        className="p-1.5 text-slate-400 hover:text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
                      >
                        <span className="material-symbols-outlined text-sm">edit</span>
                      </button>
                    </div>
                  </div>
                  {editingCategory === cat.category ? (
                    <div className="flex items-center gap-2 mt-2">
                      <input
                        autoFocus
                        className="flex-1 px-3 py-1.5 text-sm border border-primary rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/20 bg-white dark:bg-slate-800"
                        placeholder="Budget limit (VND)"
                        value={editValue}
                        onChange={(e) => setEditValue(e.target.value)}
                        onKeyDown={(e) => { if (e.key === 'Enter') saveEdit(); if (e.key === 'Escape') setEditingCategory(null); }}
                      />
                      <button onClick={saveEdit} className="px-3 py-1.5 bg-primary text-white text-xs font-bold rounded-lg">Save</button>
                      <button onClick={() => setEditingCategory(null)} className="px-3 py-1.5 border border-slate-200 dark:border-slate-700 text-xs font-medium rounded-lg">Cancel</button>
                    </div>
                  ) : (
                    <>
                      <div className="w-full bg-slate-100 dark:bg-slate-800 h-2.5 rounded-full overflow-hidden">
                        <div
                          className={`h-full rounded-full transition-all ${status.barColor}`}
                          style={{ width: `${Math.min(cat.pct, 100)}%` }}
                        ></div>
                      </div>
                      <div className="flex justify-between mt-1.5">
                        <span className="text-xs text-slate-400">{cat.pct.toFixed(0)}% used</span>
                        <span className={`text-xs font-medium ${cat.total > cat.limit ? 'text-rose-600' : 'text-slate-500'}`}>
                          {cat.total > cat.limit ? `Over by ${formatVNDShort(cat.total - cat.limit)}` : `${formatVNDShort(cat.limit - cat.total)} left`}
                        </span>
                      </div>
                      {cat.pct >= 85 && cat.pct < 100 && (
                        <div className="mt-2 flex items-center gap-2 p-2 rounded-lg bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800/50">
                          <span className="material-symbols-outlined text-amber-600 text-sm">warning</span>
                          <p className="text-xs text-amber-700 dark:text-amber-400">Approaching budget limit ({cat.pct.toFixed(0)}% used)</p>
                        </div>
                      )}
                      {cat.pct >= 100 && (
                        <div className="mt-2 flex items-center gap-2 p-2 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800/50">
                          <span className="material-symbols-outlined text-rose-600 text-sm">error</span>
                          <p className="text-xs text-rose-700 dark:text-rose-400">Over budget by {formatVNDShort(cat.total - cat.limit)}</p>
                        </div>
                      )}
                    </>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Unbudgeted categories - set limits */}
      {unbudgetedCategories.length > 0 && (
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
          <div className="p-6 border-b border-slate-100 dark:border-slate-800">
            <h3 className="font-bold text-slate-900 dark:text-white">Set Budgets for Categories</h3>
            <p className="text-sm text-slate-500 mt-0.5">Click "Set Budget" to add a monthly limit.</p>
          </div>
          <div className="divide-y divide-slate-100 dark:divide-slate-800">
            {unbudgetedCategories.map((cat) => {
              const icon = getCategoryIcon(cat.category);
              return (
                <div key={cat.category} className="p-5 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className={`size-9 rounded-lg ${icon.bg} ${icon.color} flex items-center justify-center`}>
                      <span className="material-symbols-outlined text-lg">{icon.icon}</span>
                    </div>
                    <div>
                      <p className="font-semibold text-slate-800 dark:text-slate-200 text-sm">{cat.category}</p>
                      <p className="text-xs text-slate-400">{formatVNDShort(cat.total)} spent · {cat.count} transactions</p>
                    </div>
                  </div>
                  {editingCategory === cat.category ? (
                    <div className="flex items-center gap-2">
                      <input
                        autoFocus
                        className="w-40 px-3 py-1.5 text-sm border border-primary rounded-lg focus:outline-none focus:ring-2 focus:ring-primary/20 bg-white dark:bg-slate-800"
                        placeholder="Limit (VND)"
                        value={editValue}
                        onChange={(e) => setEditValue(e.target.value)}
                        onKeyDown={(e) => { if (e.key === 'Enter') saveEdit(); if (e.key === 'Escape') setEditingCategory(null); }}
                      />
                      <button onClick={saveEdit} className="px-3 py-1.5 bg-primary text-white text-xs font-bold rounded-lg">Save</button>
                      <button onClick={() => setEditingCategory(null)} className="p-1.5 text-slate-400 hover:text-slate-600 rounded-lg">
                        <span className="material-symbols-outlined text-sm">close</span>
                      </button>
                    </div>
                  ) : (
                    <button
                      onClick={() => startEdit(cat.category, 0)}
                      className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-primary border border-primary/30 rounded-lg hover:bg-primary/5 transition-colors"
                    >
                      <span className="material-symbols-outlined text-sm">add</span>
                      Set Budget
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      )}

      {categoryBreakdown.length === 0 && (
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-12 text-center">
          <span className="material-symbols-outlined text-4xl text-slate-300 dark:text-slate-600">category</span>
          <p className="text-slate-400 text-sm mt-3">No expense data for {formatMonth(period)}.</p>
        </div>
      )}
    </div>
  );
}
