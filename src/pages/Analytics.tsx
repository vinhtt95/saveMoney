import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell,
  LineChart, Line, Legend,
} from 'recharts';
import { useApp } from '../context/AppContext';
import {
  getExpenses,
  filterByPeriod,
  getDayOfWeekBreakdown,
  getCalendarHeatmap,
  getTopSpendingDays,
  getMonthlyComparison,
  getAccountBreakdown,
  getCategoryBreakdown,
  getAvailablePeriods,
  getCategoryMonthMatrix,
  getCategoryMonthlyTrend,
} from '../utils/analytics';
import { formatVND, formatVNDShort, formatMonth, toYYYYMM } from '../utils/formatters';

type AnalyticsTab = 'overview' | 'categories' | 'comparison' | 'matrix';

const CATEGORY_COLORS = ['#144bb8', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4'];

const HEATMAP_LEVELS = [
  'bg-primary/5',
  'bg-primary/20',
  'bg-primary/40',
  'bg-primary/70',
  'bg-primary',
];

function formatDayLabel(dateStr: string): string {
  const d = new Date(dateStr);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

export function Analytics() {
  const { state } = useApp();
  const { transactions, selectedPeriod } = state;
  const [activeTab, setActiveTab] = useState<AnalyticsTab>('overview');

  const allTxs = transactions;
  const period = selectedPeriod === 'all'
    ? (getAvailablePeriods(allTxs)[0] || toYYYYMM(new Date()))
    : selectedPeriod;

  const periodTxs = useMemo(() => filterByPeriod(allTxs, period), [allTxs, period]);
  const expenses = useMemo(() => getExpenses(periodTxs), [periodTxs]);

  const dayOfWeek = useMemo(() => getDayOfWeekBreakdown(getExpenses(allTxs)), [allTxs]);
  const heatmap = useMemo(() => getCalendarHeatmap(allTxs, period), [allTxs, period]);
  const topDays = useMemo(() => getTopSpendingDays(getExpenses(allTxs), 5), [allTxs]);
  const monthComparison = useMemo(() => getMonthlyComparison(allTxs, period), [allTxs, period]);
  const accountBreakdown = useMemo(() => getAccountBreakdown(expenses), [expenses]);
  const categoryBreakdown = useMemo(() => getCategoryBreakdown(expenses), [expenses]);
  const totalExpenses = useMemo(() => categoryBreakdown.reduce((s, c) => s + c.total, 0), [categoryBreakdown]);

  // Multi-period category trend (last 6 months, top 3 categories)
  const periods = useMemo(() => getAvailablePeriods(allTxs).slice(0, 6).reverse(), [allTxs]);
  const topCats = useMemo(() => getCategoryBreakdown(getExpenses(allTxs)).slice(0, 3).map((c) => c.category), [allTxs]);
  const categoryTrendData = useMemo(() => {
    return periods.map((p) => {
      const txs = filterByPeriod(allTxs, p);
      const bd = getCategoryBreakdown(getExpenses(txs));
      const row: Record<string, string | number> = { month: p.slice(5) }; // MM label
      topCats.forEach((cat) => {
        row[cat] = bd.find((c) => c.category === cat)?.total || 0;
      });
      return row;
    });
  }, [periods, allTxs, topCats]);

  if (allTxs.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-4">
        <div className="size-16 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center">
          <span className="material-symbols-outlined text-3xl text-slate-400">bar_chart</span>
        </div>
        <h2 className="text-xl font-bold text-slate-900 dark:text-white">No data to analyze</h2>
        <p className="text-slate-500 text-sm">Import your Savey CSV to see analytics.</p>
        <Link to="/settings" className="px-6 py-2 bg-primary text-white rounded-lg text-sm font-bold hover:opacity-90 transition-opacity">
          Import Data
        </Link>
      </div>
    );
  }

  // First day of month weekday offset for heatmap
  const [y, m] = period.split('-').map(Number);
  const firstDayOfWeek = new Date(y, m - 1, 1).getDay(); // 0=Sun

  // Get heatmap start offset (Mon=0 layout), convert Sun=0 to Mon-first
  const startOffset = firstDayOfWeek === 0 ? 6 : firstDayOfWeek - 1;

  const maxDow = Math.max(...dayOfWeek.map((d) => d.amount), 1);

  // Matrix tab state
  const allPeriods = useMemo(() => getAvailablePeriods(allTxs), [allTxs]);
  const defaultFrom = allPeriods[Math.min(allPeriods.length - 1, 5)]; // up to 6 months back
  const defaultTo = allPeriods[0];
  const [matrixFrom, setMatrixFrom] = useState(defaultFrom || '');
  const [matrixTo, setMatrixTo] = useState(defaultTo || '');

  // Category trend line chart — synced with matrix date range
  const allCategories = useMemo(() => getCategoryBreakdown(getExpenses(allTxs)).map((c) => c.category), [allTxs]);
  const [trendCategory, setTrendCategory] = useState(() => allCategories[0] || '');
  const trendPeriods = useMemo(
    () => allPeriods.filter((p) => p >= matrixFrom && p <= matrixTo).slice().reverse(),
    [allPeriods, matrixFrom, matrixTo]
  );
  const trendData = useMemo(
    () => trendCategory ? getCategoryMonthlyTrend(allTxs, trendCategory, trendPeriods) : [],
    [allTxs, trendCategory, trendPeriods]
  );
  const [showTopN, setShowTopN] = useState(5);

  const matrixData = useMemo(() => {
    if (!matrixFrom || !matrixTo || matrixFrom > matrixTo) return [];
    return getCategoryMonthMatrix(allTxs, matrixFrom, matrixTo);
  }, [allTxs, matrixFrom, matrixTo]);

  const matrixCats = useMemo(() => {
    if (matrixData.length === 0) return [];
    const cats = Object.keys(matrixData[0]).filter((k) => k !== 'month');
    // Sort by total descending
    const totals: Record<string, number> = {};
    cats.forEach((cat) => {
      totals[cat] = matrixData.reduce((s, row) => s + ((row[cat] as number) || 0), 0);
    });
    return cats.sort((a, b) => totals[b] - totals[a]).slice(0, showTopN);
  }, [matrixData, showTopN]);

  const tabs: { id: AnalyticsTab; label: string; icon: string }[] = [
    { id: 'overview', label: 'Overview', icon: 'insights' },
    { id: 'categories', label: 'Categories', icon: 'category' },
    { id: 'comparison', label: 'Comparison', icon: 'compare_arrows' },
    { id: 'matrix', label: 'Theo danh mục', icon: 'grid_on' },
  ];

  return (
    <div className="flex flex-col gap-8">
      <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Analytics</h1>
          <p className="text-slate-500 dark:text-slate-400 mt-1">
            Deep dive into your financial habits and trends — {formatMonth(period)}.
          </p>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="flex border-b border-slate-200 dark:border-slate-800 gap-1">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex items-center gap-2 px-4 py-3 text-sm font-medium border-b-2 transition-colors ${
              activeTab === tab.id
                ? 'border-primary text-primary'
                : 'border-transparent text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'
            }`}
          >
            <span className="material-symbols-outlined text-base">{tab.icon}</span>
            {tab.label}
          </button>
        ))}
      </div>

      {activeTab === 'categories' && (
        <div className="flex flex-col gap-6">
          {/* Category spending trends chart */}
          {categoryTrendData.length > 1 && topCats.length > 0 && (
            <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
              <h3 className="font-bold text-slate-800 dark:text-slate-100 mb-6">Spending Trends — Top Categories</h3>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={categoryTrendData}>
                    <XAxis dataKey="month" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                    <YAxis tickFormatter={(v) => formatVNDShort(v)} tick={{ fontSize: 10 }} tickLine={false} axisLine={false} width={72} />
                    <Tooltip formatter={(value: number, name: string) => [formatVND(value), name]} />
                    <Legend />
                    {topCats.map((cat, i) => (
                      <Line
                        key={cat}
                        type="monotone"
                        dataKey={cat}
                        stroke={CATEGORY_COLORS[i]}
                        strokeWidth={2}
                        dot={{ r: 3 }}
                        activeDot={{ r: 5 }}
                      />
                    ))}
                  </LineChart>
                </ResponsiveContainer>
              </div>
            </div>
          )}

          {/* Category breakdown table */}
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
            <div className="p-6 border-b border-slate-100 dark:border-slate-800">
              <h3 className="font-bold text-slate-800 dark:text-slate-100">Category Breakdown — {formatMonth(period)}</h3>
            </div>
            {categoryBreakdown.length > 0 ? (
              <div className="overflow-x-auto">
                <table className="w-full text-left">
                  <thead className="bg-slate-50 dark:bg-slate-800/50 text-slate-500 text-xs font-bold uppercase tracking-wider">
                    <tr>
                      <th className="px-6 py-3">Category</th>
                      <th className="px-6 py-3 text-right">Total</th>
                      <th className="px-6 py-3 text-right">Count</th>
                      <th className="px-6 py-3 text-right">Avg/tx</th>
                      <th className="px-6 py-3 text-right">% of Total</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                    {categoryBreakdown.map((cat, i) => (
                      <tr key={cat.category} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
                        <td className="px-6 py-4">
                          <div className="flex items-center gap-2">
                            <div className="size-2.5 rounded-full" style={{ backgroundColor: CATEGORY_COLORS[i % CATEGORY_COLORS.length] }}></div>
                            <span className="text-sm font-medium">{cat.category}</span>
                          </div>
                        </td>
                        <td className="px-6 py-4 text-right text-sm font-bold text-rose-600">{formatVNDShort(cat.total)}</td>
                        <td className="px-6 py-4 text-right text-sm text-slate-500">{cat.count}</td>
                        <td className="px-6 py-4 text-right text-sm text-slate-500">{formatVNDShort(cat.total / cat.count)}</td>
                        <td className="px-6 py-4 text-right">
                          <div className="flex items-center justify-end gap-2">
                            <div className="w-16 bg-slate-100 dark:bg-slate-800 h-1.5 rounded-full overflow-hidden">
                              <div className="h-full rounded-full" style={{ width: `${cat.percent}%`, backgroundColor: CATEGORY_COLORS[i % CATEGORY_COLORS.length] }}></div>
                            </div>
                            <span className="text-sm font-medium text-slate-700 dark:text-slate-300 w-10 text-right">{cat.percent.toFixed(1)}%</span>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot className="bg-slate-50 dark:bg-slate-800/50">
                    <tr>
                      <td className="px-6 py-3 text-xs font-bold uppercase text-slate-500">Total</td>
                      <td className="px-6 py-3 text-right text-sm font-bold text-slate-900 dark:text-white">{formatVNDShort(totalExpenses)}</td>
                      <td className="px-6 py-3 text-right text-sm font-bold text-slate-900 dark:text-white">{categoryBreakdown.reduce((s, c) => s + c.count, 0)}</td>
                      <td className="px-6 py-3"></td>
                      <td className="px-6 py-3"></td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            ) : (
              <div className="p-12 text-center text-slate-400 text-sm">No expense data for this period.</div>
            )}
          </div>
        </div>
      )}

      {activeTab === 'comparison' && (
        <div className="flex flex-col gap-6">
          {monthComparison.length > 0 ? (
            <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
              <div className="flex flex-col md:flex-row justify-between md:items-center gap-4 mb-10">
                <div>
                  <h3 className="font-bold text-lg text-slate-800 dark:text-slate-100">Month-over-Month Comparison</h3>
                  <p className="text-sm text-slate-500">Top spending categories: {formatMonth(period)} vs previous month.</p>
                </div>
                <div className="flex gap-4">
                  <div className="flex items-center gap-2">
                    <div className="size-3 rounded-sm bg-primary"></div>
                    <span className="text-xs font-medium text-slate-600 dark:text-slate-400">This Month</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="size-3 rounded-sm bg-slate-200 dark:bg-slate-700"></div>
                    <span className="text-xs font-medium text-slate-600 dark:text-slate-400">Last Month</span>
                  </div>
                </div>
              </div>
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart
                    data={monthComparison.map((c) => ({
                      name: c.category,
                      current: Math.round(c.current),
                      previous: Math.round(c.previous),
                    }))}
                    margin={{ top: 0, right: 0, left: 0, bottom: 0 }}
                  >
                    <XAxis dataKey="name" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                    <YAxis tickFormatter={(v) => formatVNDShort(v)} tick={{ fontSize: 10 }} tickLine={false} axisLine={false} width={80} />
                    <Tooltip
                      formatter={(value: number, name: string) => [formatVND(value), name === 'current' ? 'This Month' : 'Last Month']}
                    />
                    <Bar dataKey="previous" fill="#e2e8f0" radius={[4, 4, 0, 0]} />
                    <Bar dataKey="current" radius={[4, 4, 0, 0]}>
                      {monthComparison.map((c, i) => (
                        <Cell key={i} fill={c.trend === 'up' ? '#f43f5e' : c.trend === 'down' ? '#10b981' : '#144bb8'} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 mt-6">
                {monthComparison.map((c) => (
                  <div key={c.category} className="text-center p-3 rounded-lg bg-slate-50 dark:bg-slate-800/50">
                    <p className="text-xs font-bold text-slate-600 dark:text-slate-400 truncate">{c.category}</p>
                    <p className={`text-sm font-black mt-1 ${c.trend === 'up' ? 'text-rose-600' : c.trend === 'down' ? 'text-emerald-600' : 'text-slate-600'}`}>
                      {c.trend === 'up' ? '+' : ''}{c.changePercent.toFixed(0)}%
                    </p>
                    <p className="text-[10px] text-slate-400 mt-0.5">{formatVNDShort(c.current)}</p>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-12 text-center">
              <p className="text-slate-400 text-sm">Not enough data for comparison. Import at least 2 months of data.</p>
            </div>
          )}
        </div>
      )}

      {activeTab === 'overview' && (<>
      {/* Row 1: Day of Week + Monthly Heatmap */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Day of Week */}
        <div className="lg:col-span-1 bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-bold text-slate-800 dark:text-slate-100">By Day of Week</h3>
            <span className="text-xs text-slate-400">all time</span>
          </div>
          <div className="space-y-4">
            {dayOfWeek.map((item) => {
              const isBusiest = item.amount === Math.max(...dayOfWeek.map((d) => d.amount));
              return (
                <div key={item.day} className="space-y-1">
                  <div className={`flex justify-between text-xs font-medium mb-1 ${isBusiest ? 'text-primary font-bold' : ''}`}>
                    <span>{item.day}</span>
                    <span>{formatVNDShort(item.amount)}</span>
                  </div>
                  <div className="w-full bg-slate-100 dark:bg-slate-800 h-2.5 rounded-full overflow-hidden">
                    <div
                      className={`${isBusiest ? 'bg-primary' : 'bg-primary/60'} h-full rounded-full`}
                      style={{ width: `${(item.amount / maxDow) * 100}%` }}
                    ></div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Heatmap */}
        <div className="lg:col-span-2 bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-bold text-slate-800 dark:text-slate-100">Monthly Density — {formatMonth(period)}</h3>
            <div className="flex gap-2 items-center text-[10px] text-slate-400 font-bold uppercase tracking-tighter">
              <span>Less</span>
              <div className="flex gap-1">
                {HEATMAP_LEVELS.map((cls, i) => (
                  <div key={i} className={`size-3 rounded-sm ${cls}`}></div>
                ))}
              </div>
              <span>More</span>
            </div>
          </div>
          <div className="grid grid-cols-7 gap-1.5">
            {['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((d) => (
              <div key={d} className="text-center text-[10px] font-bold text-slate-400">{d}</div>
            ))}
            {/* Empty offset cells */}
            {Array.from({ length: startOffset }).map((_, i) => (
              <div key={`empty-${i}`} className="aspect-square" />
            ))}
            {heatmap.map((cell) => (
              <div
                key={cell.date}
                className={`aspect-square ${HEATMAP_LEVELS[cell.level]} rounded-md hover:ring-2 ring-primary transition-all cursor-pointer`}
                title={`${formatDayLabel(cell.date)}: ${cell.amount > 0 ? formatVND(cell.amount) : 'No spending'}`}
              >
                <span className="sr-only">{cell.day}</span>
              </div>
            ))}
          </div>
          {expenses.length > 0 && (
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-6 italic">
              {(() => {
                const busiest = dayOfWeek.reduce((a, b) => (a.amount > b.amount ? a : b));
                return `Spending peaks on ${busiest.day} (${formatVNDShort(busiest.amount)} total).`;
              })()}
            </p>
          )}
        </div>
      </div>

      {/* Row 2: Account Breakdown + Top Spending Days */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex justify-between items-center mb-6">
            <h3 className="font-bold text-slate-800 dark:text-slate-100">Spending by Account</h3>
            <div className="flex gap-3">
              {accountBreakdown.slice(0, 3).map((a, i) => (
                <div key={a.account} className="flex items-center gap-1.5">
                  <div className={`size-2 rounded-full ${i === 0 ? 'bg-primary' : i === 1 ? 'bg-primary/40' : 'bg-slate-300'}`}></div>
                  <span className="text-[10px] font-bold text-slate-500">{a.account.toUpperCase()}</span>
                </div>
              ))}
            </div>
          </div>
          {accountBreakdown.length > 0 ? (
            <div className="space-y-4">
              {accountBreakdown.map((acc, i) => (
                <div key={acc.account} className="space-y-1.5">
                  <div className="flex justify-between text-sm">
                    <span className="font-medium text-slate-700 dark:text-slate-300">{acc.account}</span>
                    <span className="text-slate-900 dark:text-white font-bold">
                      {formatVNDShort(acc.total)} <span className="text-slate-400 font-normal text-xs">({acc.percent.toFixed(0)}%)</span>
                    </span>
                  </div>
                  <div className="w-full bg-slate-100 dark:bg-slate-800 h-3 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full ${i === 0 ? 'bg-primary' : i === 1 ? 'bg-primary/40' : 'bg-slate-300'}`}
                      style={{ width: `${acc.percent}%` }}
                    ></div>
                  </div>
                  <p className="text-xs text-slate-400">{acc.count} transactions</p>
                </div>
              ))}
            </div>
          ) : (
            <div className="h-32 flex items-center justify-center text-slate-400 text-sm">No expense data for this period</div>
          )}
        </div>

        <div className="lg:col-span-1 bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <h3 className="font-bold text-slate-800 dark:text-slate-100 mb-6">Top Spending Days</h3>
          <div className="space-y-4">
            {topDays.length > 0 ? topDays.map((item, i) => (
              <div key={i} className="flex items-center justify-between p-3 rounded-lg bg-slate-50 dark:bg-slate-800/50 border border-slate-100 dark:border-slate-800">
                <div>
                  <p className="text-sm font-bold">{formatDayLabel(item.date)}</p>
                  <p className="text-[10px] text-slate-500 truncate max-w-[120px]">{item.categories}</p>
                </div>
                <span className="text-sm font-black text-primary dark:text-slate-100 whitespace-nowrap ml-2">
                  {formatVNDShort(item.total)}
                </span>
              </div>
            )) : (
              <p className="text-sm text-slate-400">No data available.</p>
            )}
          </div>
        </div>
      </div>

      </>)}

      {activeTab === 'matrix' && (
        <div className="flex flex-col gap-6">
          {/* Shared controls */}
          <div className="flex flex-wrap items-center gap-4">
            <div className="flex items-center gap-2">
              <label className="text-sm font-medium text-slate-600 dark:text-slate-400">Từ</label>
              <select
                value={matrixFrom}
                onChange={(e) => setMatrixFrom(e.target.value)}
                className="text-sm border border-slate-200 dark:border-slate-700 rounded-lg px-3 py-1.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200"
              >
                {allPeriods.slice().reverse().map((p) => (
                  <option key={p} value={p}>{p}</option>
                ))}
              </select>
            </div>
            <div className="flex items-center gap-2">
              <label className="text-sm font-medium text-slate-600 dark:text-slate-400">Đến</label>
              <select
                value={matrixTo}
                onChange={(e) => setMatrixTo(e.target.value)}
                className="text-sm border border-slate-200 dark:border-slate-700 rounded-lg px-3 py-1.5 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-200"
              >
                {allPeriods.slice().reverse().map((p) => (
                  <option key={p} value={p}>{p}</option>
                ))}
              </select>
            </div>
            <div className="flex items-center gap-2 ml-auto">
              <label className="text-sm font-medium text-slate-600 dark:text-slate-400">Top</label>
              {[3, 5, 8, 10].map((n) => (
                <button
                  key={n}
                  onClick={() => setShowTopN(n)}
                  className={`px-2.5 py-1 text-xs font-bold rounded-lg transition-colors ${showTopN === n ? 'bg-primary text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700'}`}
                >
                  {n}
                </button>
              ))}
              <span className="text-sm text-slate-400">danh mục</span>
            </div>
          </div>

          {matrixData.length === 0 || matrixCats.length === 0 ? (
            <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-12 text-center text-slate-400 text-sm">
              Không có dữ liệu trong khoảng thời gian này.
            </div>
          ) : (
            <>
              {/* Stacked bar chart */}
              <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
                <h3 className="font-bold text-slate-800 dark:text-slate-100 mb-6">Chi tiêu theo tháng và danh mục</h3>
                <div className="h-72">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={matrixData} margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
                      <XAxis dataKey="month" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                      <YAxis tickFormatter={(v) => formatVNDShort(v)} tick={{ fontSize: 10 }} tickLine={false} axisLine={false} width={72} />
                      <Tooltip
                        formatter={(value: number, name: string) => [formatVND(value), name]}
                        labelFormatter={(label) => `Tháng ${label}`}
                      />
                      <Legend />
                      {matrixCats.map((cat, i) => (
                        <Bar key={cat} dataKey={cat} stackId="a" fill={CATEGORY_COLORS[i % CATEGORY_COLORS.length]} radius={i === matrixCats.length - 1 ? [4, 4, 0, 0] : [0, 0, 0, 0]} />
                      ))}
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>

              {/* Category trend line chart */}
              <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <h3 className="font-bold text-slate-800 dark:text-slate-100">Chi tiêu theo danh mục</h3>
                    <p className="text-xs text-slate-500 mt-1">Click vào dòng trong bảng để xem xu hướng của danh mục đó</p>
                  </div>
                  {trendCategory && (
                    <div className="flex items-center gap-2 px-3 py-1.5 bg-primary/10 rounded-lg">
                      <div className="size-2.5 rounded-full bg-primary"></div>
                      <span className="text-sm font-bold text-primary">{trendCategory}</span>
                    </div>
                  )}
                </div>
                {trendData.length > 0 ? (
                  <div className="h-56">
                    <ResponsiveContainer width="100%" height="100%">
                      <LineChart data={trendData} margin={{ top: 4, right: 8, left: 0, bottom: 0 }}>
                        <XAxis dataKey="month" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                        <YAxis tickFormatter={(v) => formatVNDShort(v)} tick={{ fontSize: 10 }} tickLine={false} axisLine={false} width={72} />
                        <Tooltip formatter={(value: number) => [formatVND(value), trendCategory]} labelFormatter={(label) => `Tháng ${label}`} />
                        <Line type="monotone" dataKey="amount" stroke="#144bb8" strokeWidth={2} dot={{ r: 4, fill: '#144bb8' }} activeDot={{ r: 6 }} />
                      </LineChart>
                    </ResponsiveContainer>
                  </div>
                ) : (
                  <div className="h-56 flex items-center justify-center text-slate-400 text-sm">
                    Không có dữ liệu trong khoảng thời gian này.
                  </div>
                )}
              </div>

              {/* Trend table */}
              <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
                <div className="p-6 border-b border-slate-100 dark:border-slate-800">
                  <h3 className="font-bold text-slate-800 dark:text-slate-100">Bảng chi tiết</h3>
                  <p className="text-xs text-slate-500 mt-1">Click vào dòng để xem biểu đồ đường · Màu đỏ = tăng, xanh = giảm so với tháng trước</p>
                </div>
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm">
                    <thead className="bg-slate-50 dark:bg-slate-800/50 text-slate-500 text-xs font-bold uppercase tracking-wider">
                      <tr>
                        <th className="px-4 py-3 sticky left-0 bg-slate-50 dark:bg-slate-800/50 min-w-[140px]">Danh mục</th>
                        {matrixData.map((row) => (
                          <th key={row.month as string} className="px-4 py-3 text-right whitespace-nowrap">{row.month as string}</th>
                        ))}
                        <th className="px-4 py-3 text-right whitespace-nowrap">Thay đổi</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                      {matrixCats.map((cat, ci) => {
                        const isSelected = trendCategory === cat;
                        const values = matrixData.map((row) => (row[cat] as number) || 0);
                        const first = values.find((v) => v > 0) || 0;
                        const last = values[values.length - 1];
                        const overallChange = first > 0 ? ((last - first) / first) * 100 : null;
                        return (
                          <tr
                            key={cat}
                            onClick={() => setTrendCategory(cat)}
                            className={`cursor-pointer transition-colors ${isSelected ? 'bg-primary/5 dark:bg-primary/10' : 'hover:bg-slate-50 dark:hover:bg-slate-800/50'}`}
                          >
                            <td className={`px-4 py-3 sticky left-0 font-medium ${isSelected ? 'bg-primary/5 dark:bg-primary/10' : 'bg-white dark:bg-slate-900'}`}>
                              <div className="flex items-center gap-2">
                                <div className="size-2.5 rounded-full shrink-0" style={{ backgroundColor: CATEGORY_COLORS[ci % CATEGORY_COLORS.length] }}></div>
                                <span className={`truncate max-w-[110px] ${isSelected ? 'text-primary font-bold' : ''}`}>{cat}</span>
                                {isSelected && <span className="material-symbols-outlined text-xs text-primary">show_chart</span>}
                              </div>
                            </td>
                            {values.map((val, vi) => {
                              const prev = vi > 0 ? values[vi - 1] : null;
                              const isUp = prev !== null && prev > 0 && val > prev;
                              const isDown = prev !== null && prev > 0 && val < prev;
                              return (
                                <td
                                  key={vi}
                                  className={`px-4 py-3 text-right font-medium whitespace-nowrap ${
                                    val === 0 ? 'text-slate-300 dark:text-slate-700' :
                                    isUp ? 'text-rose-600 bg-rose-50 dark:bg-rose-900/10' :
                                    isDown ? 'text-emerald-600 bg-emerald-50 dark:bg-emerald-900/10' :
                                    'text-slate-700 dark:text-slate-300'
                                  }`}
                                >
                                  {val === 0 ? '—' : formatVNDShort(val)}
                                </td>
                              );
                            })}
                            <td className="px-4 py-3 text-right font-bold whitespace-nowrap">
                              {overallChange === null ? (
                                <span className="text-slate-400">—</span>
                              ) : (
                                <span className={overallChange > 0 ? 'text-rose-600' : overallChange < 0 ? 'text-emerald-600' : 'text-slate-500'}>
                                  {overallChange > 0 ? '+' : ''}{overallChange.toFixed(0)}%
                                </span>
                              )}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
}
