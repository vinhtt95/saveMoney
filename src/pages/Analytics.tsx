import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer,
  LineChart, Line, Legend,
} from 'recharts';
import { useApp } from '../context/AppContext';
import {
  getExpenses,
  getAvailablePeriods,
  getCategoryBreakdown,
  getCategoryMonthMatrix,
  getCategoryMonthlyTrend,
} from '../utils/analytics';
import { formatVND, formatVNDShort, toYYYYMM } from '../utils/formatters';
import { categoryName } from '../utils/lookup';

const CATEGORY_COLORS = ['#144bb8', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4'];

export function Analytics() {
  const { state } = useApp();
  const { transactions, categories } = state;

  const allTxs = transactions;

  // Matrix tab state
  const allPeriods = useMemo(() => getAvailablePeriods(allTxs), [allTxs]);
  const defaultFrom = allPeriods[Math.min(allPeriods.length - 1, 5)];
  const defaultTo = allPeriods[0];
  const [matrixFrom, setMatrixFrom] = useState(defaultFrom || '');
  const [matrixTo, setMatrixTo] = useState(defaultTo || '');
  const [showTopN, setShowTopN] = useState(5);

  const allCategoryIds = useMemo(() => getCategoryBreakdown(getExpenses(allTxs)).map((c) => c.categoryId), [allTxs]);
  const [trendCategory, setTrendCategory] = useState(() => allCategoryIds[0] || '');

  const trendPeriods = useMemo(
    () => allPeriods.filter((p) => p >= matrixFrom && p <= matrixTo).slice().reverse(),
    [allPeriods, matrixFrom, matrixTo]
  );
  const trendData = useMemo(
    () => trendCategory ? getCategoryMonthlyTrend(allTxs, trendCategory, trendPeriods) : [],
    [allTxs, trendCategory, trendPeriods]
  );

  const matrixData = useMemo(() => {
    if (!matrixFrom || !matrixTo || matrixFrom > matrixTo) return [];
    return getCategoryMonthMatrix(allTxs, matrixFrom, matrixTo);
  }, [allTxs, matrixFrom, matrixTo]);

  const matrixCats = useMemo(() => {
    if (matrixData.length === 0) return [];
    const cats = Object.keys(matrixData[0]).filter((k) => k !== 'month');
    const totals: Record<string, number> = {};
    cats.forEach((cat) => {
      totals[cat] = matrixData.reduce((s, row) => s + ((row[cat] as number) || 0), 0);
    });
    return cats.sort((a, b) => totals[b] - totals[a]).slice(0, showTopN);
  }, [matrixData, showTopN]);

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

  return (
    <div className="flex flex-col gap-8">
      <div>
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Analytics</h1>
        <p className="text-slate-500 dark:text-slate-400 mt-1">Chi tiêu theo danh mục</p>
      </div>

      <div className="flex flex-col gap-6">
        {/* Controls */}
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
                    {matrixCats.map((catId, i) => (
                      <Bar key={catId} dataKey={catId} name={categoryName(categories, catId)} stackId="a" fill={CATEGORY_COLORS[i % CATEGORY_COLORS.length]} radius={i === matrixCats.length - 1 ? [4, 4, 0, 0] : [0, 0, 0, 0]} />
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
                    <span className="text-sm font-bold text-primary">{categoryName(categories, trendCategory)}</span>
                  </div>
                )}
              </div>
              {trendData.length > 0 ? (
                <div className="h-56">
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={trendData} margin={{ top: 4, right: 8, left: 0, bottom: 0 }}>
                      <XAxis dataKey="month" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                      <YAxis tickFormatter={(v) => formatVNDShort(v)} tick={{ fontSize: 10 }} tickLine={false} axisLine={false} width={72} />
                      <Tooltip formatter={(value: number) => [formatVND(value), categoryName(categories, trendCategory)]} labelFormatter={(label) => `Tháng ${label}`} />
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
                    {matrixCats.map((catId, ci) => {
                      const isSelected = trendCategory === catId;
                      const values = matrixData.map((row) => (row[catId] as number) || 0);
                      const first = values.find((v) => v > 0) || 0;
                      const last = values[values.length - 1];
                      const overallChange = first > 0 ? ((last - first) / first) * 100 : null;
                      return (
                        <tr
                          key={catId}
                          onClick={() => setTrendCategory(catId)}
                          className={`cursor-pointer transition-colors ${isSelected ? 'bg-primary/5 dark:bg-primary/10' : 'hover:bg-slate-50 dark:hover:bg-slate-800/50'}`}
                        >
                          <td className={`px-4 py-3 sticky left-0 font-medium ${isSelected ? 'bg-primary/5 dark:bg-primary/10' : 'bg-white dark:bg-slate-900'}`}>
                            <div className="flex items-center gap-2">
                              <div className="size-2.5 rounded-full shrink-0" style={{ backgroundColor: CATEGORY_COLORS[ci % CATEGORY_COLORS.length] }}></div>
                              <span className={`truncate max-w-[110px] ${isSelected ? 'text-primary font-bold' : ''}`}>{categoryName(categories, catId)}</span>
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
    </div>
  );
}
