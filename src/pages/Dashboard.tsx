import { useState, useMemo } from 'react';
import { AreaChart, Area, ResponsiveContainer, Tooltip, XAxis } from 'recharts';
import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import { AddTransactionForm } from '../components/AddTransactionModal';
import {
  getExpenses,
  getTotalSpending,
  getTotalIncome,
  getAvgDaily,
  getCategoryBreakdown,
  getDailyTrend,
  filterByPeriod,
  getAvailablePeriods,
} from '../utils/analytics';
import { formatVND, formatVNDShort, formatDate, formatMonth, toYYYYMM } from '../utils/formatters';

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

  // Recent transactions (expenses + income, last 10)
  const recentTxs = useMemo(() => {
    return [...periodTxs]
      .filter((t) => t.type === 'Expense' || t.type === 'Income')
      .sort((a, b) => b.date.getTime() - a.date.getTime())
      .slice(0, 10);
  }, [periodTxs]);

  const allCategories = useMemo(
    () => [...state.expenseCategories, ...state.incomeCategories].sort(),
    [state.expenseCategories, state.incomeCategories]
  );
  const allAccounts = state.accounts;

  function handleAddConfirm(tx: import('../types').Transaction) {
    dispatch({ type: 'ADD_TRANSACTION', transaction: tx });
    setShowAddForm(false);
  }

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
          <h3 className="text-2xl font-bold text-slate-900 dark:text-white mt-3">{formatVNDShort(totalSpending)}</h3>
          <p className="text-slate-500 text-sm font-medium mt-0.5">Total Spending</p>
          <p className="text-slate-400 text-xs mt-1">{prevPeriod ? `vs. ${formatMonth(prevPeriod)}` : 'all time'}</p>
        </div>

        <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex justify-between items-start mb-3">
            <div className="size-10 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center">
              <span className="material-symbols-outlined text-emerald-600 text-xl">trending_up</span>
            </div>
          </div>
          <h3 className="text-2xl font-bold text-emerald-600 mt-3">{formatVNDShort(totalIncome)}</h3>
          <p className="text-slate-500 text-sm font-medium mt-0.5">Total Income</p>
          <p className={`text-xs mt-1 font-medium ${netFlow >= 0 ? 'text-emerald-500' : 'text-rose-500'}`}>
            Net: {netFlow >= 0 ? '+' : ''}{formatVNDShort(netFlow)}
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
                const icon = getCategoryIcon(cat.category);
                return (
                <div key={cat.category} className="space-y-2">
                  <div className="flex items-center justify-between text-sm">
                    <div className="flex items-center gap-2">
                      <div className={`size-7 rounded-lg ${icon.bg} ${icon.color} flex items-center justify-center`}>
                        <span className="material-symbols-outlined text-base">{icon.icon}</span>
                      </div>
                      <span className="font-medium text-slate-700 dark:text-slate-300">{cat.category}</span>
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
              expenseCategories={state.expenseCategories}
              incomeCategories={state.incomeCategories}
              allAccounts={allAccounts}
              defaultCategoryExpense={state.defaultCategoryExpense}
              defaultCategoryIncome={state.defaultCategoryIncome}
              defaultAccount={state.defaultAccount}
            />
          </div>
        )}
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-slate-50 dark:bg-slate-800/50 text-slate-500 text-xs font-bold uppercase tracking-wider">
              <tr>
                <th className="px-6 py-3">Category</th>
                <th className="px-6 py-3">Account</th>
                <th className="px-6 py-3">Date</th>
                <th className="px-6 py-3 text-right">Amount</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
              {recentTxs.map((tx) => {
                const icon = getCategoryIcon(tx.category);
                const isExpense = tx.type === 'Expense';
                return (
                  <tr key={tx.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className={`size-8 rounded ${icon.bg} ${icon.color} flex items-center justify-center`}>
                          <span className="material-symbols-outlined text-lg">{icon.icon}</span>
                        </div>
                        <span className="text-sm font-medium">{tx.category}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400">{tx.account}</td>
                    <td className="px-6 py-4 text-sm text-slate-500">{formatDate(tx.date)}</td>
                    <td className={`px-6 py-4 text-right text-sm font-bold ${isExpense ? 'text-rose-600' : 'text-emerald-600'}`}>
                      {isExpense ? '-' : '+'}{formatVND(tx.amount)}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
