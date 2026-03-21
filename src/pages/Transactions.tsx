import React, { useState, useMemo, useRef, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import { getExpenses, getTotalSpending, getTotalIncome, getAvgDaily, filterByPeriod, getAvailablePeriods } from '../utils/analytics';
import { formatVND, formatVNDShort, formatDate } from '../utils/formatters';

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
};

function getIcon(category: string) {
  return CATEGORY_ICONS[category] || { icon: 'receipt_long', color: 'text-slate-600', bg: 'bg-slate-100 dark:bg-slate-800' };
}

export function Transactions() {
  const { state, dispatch } = useApp();
  const [expandedRow, setExpandedRow] = useState<string | null>(null);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [showCategoryMenu, setShowCategoryMenu] = useState(false);
  const [showAccountMenu, setShowAccountMenu] = useState(false);
  const [showPeriodMenu, setShowPeriodMenu] = useState(false);
  const categoryMenuRef = useRef<HTMLDivElement>(null);
  const accountMenuRef = useRef<HTMLDivElement>(null);
  const periodMenuRef = useRef<HTMLDivElement>(null);

  const { filters, selectedPeriod, transactions } = state;

  const availablePeriods = useMemo(() => getAvailablePeriods(transactions), [transactions]);

  const periodTxs = useMemo(
    () => filterByPeriod(transactions, selectedPeriod),
    [transactions, selectedPeriod]
  );

  // Unique categories and accounts from period
  const allCategories = useMemo(
    () => [...new Set(periodTxs.filter((t) => t.type === 'Expense' || t.type === 'Income').map((t) => t.category))].sort(),
    [periodTxs]
  );
  const allAccounts = useMemo(
    () => [...new Set(periodTxs.map((t) => t.account))].sort(),
    [periodTxs]
  );

  // Filtered transactions
  const filtered = useMemo(() => {
    let txs = periodTxs.filter((t) => t.type === 'Expense' || t.type === 'Income');
    if (filters.search) {
      const q = filters.search.toLowerCase();
      txs = txs.filter(
        (t) => t.category.toLowerCase().includes(q) || t.account.toLowerCase().includes(q)
      );
    }
    if (filters.categories.length > 0) {
      txs = txs.filter((t) => filters.categories.includes(t.category));
    }
    if (filters.accounts.length > 0) {
      txs = txs.filter((t) => filters.accounts.includes(t.account));
    }
    return txs.sort((a, b) => b.date.getTime() - a.date.getTime());
  }, [periodTxs, filters]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const paginated = filtered.slice((page - 1) * pageSize, page * pageSize);

  // Group paginated transactions by date
  const groupedByDay = useMemo(() => {
    const groups: { dateKey: string; date: Date; txs: typeof paginated; dayIncome: number; dayExpense: number }[] = [];
    const map = new Map<string, typeof groups[0]>();
    for (const tx of paginated) {
      const key = tx.date.toISOString().slice(0, 10);
      if (!map.has(key)) {
        const group = { dateKey: key, date: tx.date, txs: [], dayIncome: 0, dayExpense: 0 };
        map.set(key, group);
        groups.push(group);
      }
      const g = map.get(key)!;
      g.txs.push(tx);
      if (tx.type === 'Income') g.dayIncome += tx.amount;
      if (tx.type === 'Expense') g.dayExpense += Math.abs(tx.amount);
    }
    return groups;
  }, [paginated]);

  // Reset page when filters or pageSize change
  useMemo(() => setPage(1), [filters, selectedPeriod, pageSize]);

  const expenses = useMemo(() => getExpenses(filtered), [filtered]);
  const totalSpending = useMemo(() => getTotalSpending(expenses), [expenses]);
  const totalIncome = useMemo(() => getTotalIncome(filtered), [filtered]);
  const avgDaily = useMemo(() => getAvgDaily(filtered), [filtered]);
  const netFlow = totalIncome - totalSpending;

  // Close dropdowns on outside click
  useEffect(() => {
    function handler(e: MouseEvent) {
      if (categoryMenuRef.current && !categoryMenuRef.current.contains(e.target as Node)) {
        setShowCategoryMenu(false);
      }
      if (accountMenuRef.current && !accountMenuRef.current.contains(e.target as Node)) {
        setShowAccountMenu(false);
      }
      if (periodMenuRef.current && !periodMenuRef.current.contains(e.target as Node)) {
        setShowPeriodMenu(false);
      }
    }
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  function toggleCategory(cat: string) {
    const cats = filters.categories.includes(cat)
      ? filters.categories.filter((c) => c !== cat)
      : [...filters.categories, cat];
    dispatch({ type: 'SET_FILTER', filter: { categories: cats } });
  }

  function toggleAccount(acc: string) {
    const accs = filters.accounts.includes(acc)
      ? filters.accounts.filter((a) => a !== acc)
      : [...filters.accounts, acc];
    dispatch({ type: 'SET_FILTER', filter: { accounts: accs } });
  }

  if (transactions.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-24 gap-4">
        <div className="size-16 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center">
          <span className="material-symbols-outlined text-3xl text-slate-400">receipt_long</span>
        </div>
        <h2 className="text-xl font-bold text-slate-900 dark:text-white">No transactions</h2>
        <p className="text-slate-500 text-sm">Import your Savey CSV to see transactions.</p>
        <Link to="/settings" className="px-6 py-2 bg-primary text-white rounded-lg text-sm font-bold hover:opacity-90 transition-opacity">
          Import Data
        </Link>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Transactions History</h2>
        <p className="text-slate-500 dark:text-slate-400 text-sm">Review and manage your financial records across all accounts.</p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white dark:bg-slate-900 p-5 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-center gap-4">
          <div className="size-10 bg-emerald-100 dark:bg-emerald-900/30 rounded-lg flex items-center justify-center shrink-0">
            <span className="material-symbols-outlined text-emerald-600 text-xl">arrow_downward</span>
          </div>
          <div>
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Total Income</p>
            <span className="text-xl font-bold text-emerald-600">{formatVNDShort(totalIncome)}</span>
          </div>
        </div>
        <div className="bg-white dark:bg-slate-900 p-5 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-center gap-4">
          <div className="size-10 bg-rose-100 dark:bg-rose-900/30 rounded-lg flex items-center justify-center shrink-0">
            <span className="material-symbols-outlined text-rose-600 text-xl">arrow_upward</span>
          </div>
          <div>
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Total Expenses</p>
            <span className="text-xl font-bold text-rose-600">{formatVNDShort(totalSpending)}</span>
          </div>
        </div>
        <div className="bg-white dark:bg-slate-900 p-5 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex items-center gap-4">
          <div className={`size-10 rounded-lg flex items-center justify-center shrink-0 ${netFlow >= 0 ? 'bg-primary/10' : 'bg-rose-100 dark:bg-rose-900/30'}`}>
            <span className={`material-symbols-outlined text-xl ${netFlow >= 0 ? 'text-primary' : 'text-rose-600'}`}>account_balance</span>
          </div>
          <div>
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Net Flow</p>
            <span className={`text-xl font-bold ${netFlow >= 0 ? 'text-primary' : 'text-rose-600'}`}>{netFlow >= 0 ? '+' : ''}{formatVNDShort(netFlow)}</span>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 items-center bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800">
        <div className="flex-1 min-w-[240px] relative">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">search</span>
          <input
            className="w-full pl-10 pr-4 py-2 bg-slate-50 dark:bg-slate-800 border-none rounded-lg text-sm focus:ring-2 focus:ring-primary/20 outline-none"
            placeholder="Search by category or account..."
            value={filters.search}
            onChange={(e) => dispatch({ type: 'SET_FILTER', filter: { search: e.target.value } })}
          />
        </div>

        {/* Period filter */}
        <div className="relative" ref={periodMenuRef}>
          <button
            onClick={() => setShowPeriodMenu((v) => !v)}
            className={`flex items-center gap-2 px-4 py-2 bg-slate-50 dark:bg-slate-800 border rounded-lg text-sm font-medium hover:bg-slate-100 transition-colors ${
              selectedPeriod !== 'all' ? 'border-primary text-primary' : 'border-slate-200 dark:border-slate-700'
            }`}
          >
            <span className="material-symbols-outlined text-sm">calendar_month</span>
            {selectedPeriod === 'all' ? 'All time' : selectedPeriod}
            <span className="material-symbols-outlined text-sm">expand_more</span>
          </button>
          {showPeriodMenu && (
            <div className="absolute top-full mt-1 left-0 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl shadow-lg z-10 min-w-[160px] overflow-hidden max-h-64 overflow-y-auto">
              <button
                onClick={() => { dispatch({ type: 'SET_PERIOD', period: 'all' }); setShowPeriodMenu(false); }}
                className={`w-full text-left px-4 py-2 text-sm hover:bg-slate-50 dark:hover:bg-slate-800 ${selectedPeriod === 'all' ? 'font-semibold text-primary' : ''}`}
              >
                All time
              </button>
              {availablePeriods.map((p) => (
                <button
                  key={p}
                  onClick={() => { dispatch({ type: 'SET_PERIOD', period: p }); setShowPeriodMenu(false); }}
                  className={`w-full text-left px-4 py-2 text-sm hover:bg-slate-50 dark:hover:bg-slate-800 ${selectedPeriod === p ? 'font-semibold text-primary' : ''}`}
                >
                  {p}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Category filter */}
        <div className="relative" ref={categoryMenuRef}>
          <button
            onClick={() => setShowCategoryMenu((v) => !v)}
            className={`flex items-center gap-2 px-4 py-2 bg-slate-50 dark:bg-slate-800 border rounded-lg text-sm font-medium hover:bg-slate-100 transition-colors ${
              filters.categories.length > 0 ? 'border-primary text-primary' : 'border-slate-200 dark:border-slate-700'
            }`}
          >
            <span className="material-symbols-outlined text-sm">category</span>
            Category {filters.categories.length > 0 && `(${filters.categories.length})`}
            <span className="material-symbols-outlined text-sm">expand_more</span>
          </button>
          {showCategoryMenu && (
            <div className="absolute top-full mt-1 left-0 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl shadow-lg z-10 min-w-[180px] overflow-hidden">
              {allCategories.map((cat) => (
                <label key={cat} className="flex items-center gap-2 px-4 py-2 hover:bg-slate-50 dark:hover:bg-slate-800 cursor-pointer text-sm">
                  <input
                    type="checkbox"
                    checked={filters.categories.includes(cat)}
                    onChange={() => toggleCategory(cat)}
                    className="rounded"
                  />
                  {cat}
                </label>
              ))}
              {filters.categories.length > 0 && (
                <button
                  onClick={() => dispatch({ type: 'SET_FILTER', filter: { categories: [] } })}
                  className="w-full text-left px-4 py-2 text-xs text-rose-500 hover:bg-rose-50 border-t border-slate-100 dark:border-slate-800"
                >
                  Clear filter
                </button>
              )}
            </div>
          )}
        </div>

        {/* Account filter */}
        <div className="relative" ref={accountMenuRef}>
          <button
            onClick={() => setShowAccountMenu((v) => !v)}
            className={`flex items-center gap-2 px-4 py-2 bg-slate-50 dark:bg-slate-800 border rounded-lg text-sm font-medium hover:bg-slate-100 transition-colors ${
              filters.accounts.length > 0 ? 'border-primary text-primary' : 'border-slate-200 dark:border-slate-700'
            }`}
          >
            <span className="material-symbols-outlined text-sm">payments</span>
            Account {filters.accounts.length > 0 && `(${filters.accounts.length})`}
            <span className="material-symbols-outlined text-sm">expand_more</span>
          </button>
          {showAccountMenu && (
            <div className="absolute top-full mt-1 left-0 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl shadow-lg z-10 min-w-[180px] overflow-hidden">
              {allAccounts.map((acc) => (
                <label key={acc} className="flex items-center gap-2 px-4 py-2 hover:bg-slate-50 dark:hover:bg-slate-800 cursor-pointer text-sm">
                  <input
                    type="checkbox"
                    checked={filters.accounts.includes(acc)}
                    onChange={() => toggleAccount(acc)}
                    className="rounded"
                  />
                  {acc}
                </label>
              ))}
              {filters.accounts.length > 0 && (
                <button
                  onClick={() => dispatch({ type: 'SET_FILTER', filter: { accounts: [] } })}
                  className="w-full text-left px-4 py-2 text-xs text-rose-500 hover:bg-rose-50 border-t border-slate-100 dark:border-slate-800"
                >
                  Clear filter
                </button>
              )}
            </div>
          )}
        </div>

        {(filters.search || filters.categories.length > 0 || filters.accounts.length > 0) && (
          <button
            onClick={() => dispatch({ type: 'SET_FILTER', filter: { search: '', categories: [], accounts: [] } })}
            className="px-3 py-2 text-xs text-rose-500 border border-rose-200 rounded-lg hover:bg-rose-50 transition-colors"
          >
            Clear all filters
          </button>
        )}
      </div>

      {/* Quick filter chips */}
      {allCategories.length > 0 && (
        <div className="flex flex-wrap gap-2">
          {allCategories.slice(0, 8).map((cat) => {
            const icon = getIcon(cat);
            const active = filters.categories.includes(cat);
            return (
              <button
                key={cat}
                onClick={() => toggleCategory(cat)}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold transition-colors ${
                  active
                    ? 'bg-primary text-white shadow-sm'
                    : 'bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'
                }`}
              >
                <span className={`material-symbols-outlined text-xs ${active ? 'text-white' : icon.color}`}>{icon.icon}</span>
                {cat}
              </button>
            );
          })}
        </div>
      )}

      {/* Table */}
      <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-800/50">
              <th className="px-6 py-4 text-xs font-bold uppercase text-slate-500 tracking-wider">Date</th>
              <th className="px-6 py-4 text-xs font-bold uppercase text-slate-500 tracking-wider">Category</th>
              <th className="px-6 py-4 text-xs font-bold uppercase text-slate-500 tracking-wider">Account</th>
              <th className="px-6 py-4 text-xs font-bold uppercase text-slate-500 tracking-wider text-right">Amount</th>
              <th className="px-6 py-4 w-10"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
            {paginated.length === 0 ? (
              <tr>
                <td colSpan={5} className="px-6 py-12 text-center text-slate-400 text-sm">No transactions match your filters.</td>
              </tr>
            ) : (
              groupedByDay.map((group) => (
                <React.Fragment key={group.dateKey}>
                  {/* Day header row */}
                  <tr className="bg-slate-50 dark:bg-slate-800/70 border-t-2 border-slate-200 dark:border-slate-700">
                    <td className="px-6 py-2">
                      <span className="text-xs font-bold text-slate-600 dark:text-slate-300 uppercase tracking-wider">
                        {formatDate(group.date)}
                      </span>
                    </td>
                    <td colSpan={2} className="px-6 py-2 text-xs text-slate-400">
                      {group.txs.length} transaction{group.txs.length !== 1 ? 's' : ''}
                    </td>
                    <td className="px-6 py-2 text-right">
                      <div className="flex items-center justify-end gap-3 text-xs font-semibold">
                        {group.dayIncome > 0 && (
                          <span className="text-emerald-600">+{formatVNDShort(group.dayIncome)}</span>
                        )}
                        {group.dayExpense > 0 && (
                          <span className="text-rose-600">-{formatVNDShort(group.dayExpense)}</span>
                        )}
                      </div>
                    </td>
                    <td />
                  </tr>
                  {group.txs.map((tx) => {
                const icon = getIcon(tx.category);
                const isExpense = tx.type === 'Expense';
                const isExpanded = expandedRow === tx.id;
                return (
                  <React.Fragment key={tx.id}>
                    <tr
                      className={`hover:bg-slate-50/50 dark:hover:bg-slate-800/50 transition-colors cursor-pointer ${isExpanded ? 'bg-primary/5 dark:bg-primary/10 border-l-4 border-primary' : ''}`}
                      onClick={() => setExpandedRow(isExpanded ? null : tx.id)}
                    >
                      <td className="px-6 py-4 text-sm whitespace-nowrap font-medium text-slate-400 dark:text-slate-500 pl-10">—</td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2">
                          <div className={`size-6 rounded ${icon.bg} flex items-center justify-center`}>
                            <span className={`material-symbols-outlined ${icon.color} text-sm`}>{icon.icon}</span>
                          </div>
                          <span className="text-sm font-medium">{tx.category}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-500 dark:text-slate-400">{tx.account}</td>
                      <td className={`px-6 py-4 text-sm font-bold text-right ${isExpense ? 'text-rose-600' : 'text-emerald-600'}`}>
                        {isExpense ? '-' : '+'}{formatVND(tx.amount)}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`material-symbols-outlined ${isExpanded ? 'text-primary' : 'text-slate-300'}`}>
                          {isExpanded ? 'expand_less' : 'chevron_right'}
                        </span>
                      </td>
                    </tr>
                    {isExpanded && (
                      <tr className="bg-primary/5 dark:bg-primary/10">
                        <td colSpan={5} className="px-12 py-6 border-t border-primary/10">
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                            <div className="space-y-2">
                              <p className="text-[10px] uppercase font-bold text-slate-400 mb-3">Details</p>
                              <ul className="text-sm space-y-2">
                                <li className="flex justify-between border-b border-slate-200/50 dark:border-slate-700/50 pb-1">
                                  <span className="text-slate-500">Transaction ID</span>
                                  <span className="font-mono text-xs">{tx.id}</span>
                                </li>
                                <li className="flex justify-between border-b border-slate-200/50 dark:border-slate-700/50 pb-1">
                                  <span className="text-slate-500">Date</span>
                                  <span className="font-medium">{formatDate(tx.date)}</span>
                                </li>
                                <li className="flex justify-between border-b border-slate-200/50 dark:border-slate-700/50 pb-1">
                                  <span className="text-slate-500">Type</span>
                                  <span className={`font-medium ${isExpense ? 'text-rose-600' : 'text-emerald-600'}`}>{tx.type}</span>
                                </li>
                                <li className="flex justify-between border-b border-slate-200/50 dark:border-slate-700/50 pb-1">
                                  <span className="text-slate-500">Category</span>
                                  <span>{tx.category}</span>
                                </li>
                                <li className="flex justify-between border-b border-slate-200/50 dark:border-slate-700/50 pb-1">
                                  <span className="text-slate-500">Account</span>
                                  <span>{tx.account}</span>
                                </li>
                                {tx.transferTo && (
                                  <li className="flex justify-between border-b border-slate-200/50 dark:border-slate-700/50 pb-1">
                                    <span className="text-slate-500">Transfer To</span>
                                    <span>{tx.transferTo}</span>
                                  </li>
                                )}
                                <li className="flex justify-between pb-1">
                                  <span className="text-slate-500">Amount</span>
                                  <span className={`font-bold ${isExpense ? 'text-rose-600' : 'text-emerald-600'}`}>
                                    {isExpense ? '-' : '+'}{formatVND(tx.amount)}
                                  </span>
                                </li>
                              </ul>
                            </div>
                            <div className="space-y-2">
                              <p className="text-[10px] uppercase font-bold text-slate-400 mb-3">Actions</p>
                              <div className="flex flex-col gap-2">
                                <button
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    if (confirm('Delete this transaction?')) {
                                      dispatch({ type: 'DELETE_TRANSACTION', id: tx.id });
                                      setExpandedRow(null);
                                    }
                                  }}
                                  className="flex items-center gap-2 text-sm font-medium px-4 py-2 text-red-600 bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-900/30 rounded-lg hover:bg-red-100 transition-colors"
                                >
                                  <span className="material-symbols-outlined text-sm">delete</span> Delete Transaction
                                </button>
                              </div>
                            </div>
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                );
              })}
                </React.Fragment>
              ))
            )}
          </tbody>
        </table>

        <div className="px-6 py-4 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between bg-slate-50 dark:bg-slate-900/50">
          <div className="flex items-center gap-3">
            <p className="text-sm text-slate-500">
              Showing <span className="font-medium">{Math.min((page - 1) * pageSize + 1, filtered.length)}</span>–
              <span className="font-medium">{Math.min(page * pageSize, filtered.length)}</span> of{' '}
              <span className="font-medium">{filtered.length}</span>
            </p>
            <select
              value={pageSize}
              onChange={(e) => setPageSize(Number(e.target.value))}
              className="text-sm border border-slate-200 dark:border-slate-700 rounded-lg px-2 py-1 bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-300"
            >
              {[10, 25, 50, 100].map((n) => (
                <option key={n} value={n}>{n} / page</option>
              ))}
            </select>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-sm text-slate-600 dark:text-slate-400 font-medium">Page {page} of {totalPages}</span>
            <div className="flex items-center gap-1">
              <button
                disabled={page === 1}
                onClick={() => setPage((p) => p - 1)}
                className="p-2 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-400 disabled:opacity-40 disabled:cursor-not-allowed hover:bg-white dark:hover:bg-slate-800"
              >
                <span className="material-symbols-outlined text-sm">chevron_left</span>
              </button>
              <button
                disabled={page === totalPages}
                onClick={() => setPage((p) => p + 1)}
                className="p-2 border border-slate-200 dark:border-slate-700 rounded-lg text-slate-600 dark:text-slate-300 disabled:opacity-40 disabled:cursor-not-allowed hover:bg-white dark:hover:bg-slate-800"
              >
                <span className="material-symbols-outlined text-sm">chevron_right</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
