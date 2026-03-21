import React, { useState, useMemo, useEffect } from 'react';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from 'recharts';
import { useApp } from '../context/AppContext';
import type { Budget as BudgetType } from '../types';
import { formatVND, formatVNDShort, formatDate, toYYYYMMDD } from '../utils/formatters';

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
function getIcon(cat: string) {
  return CATEGORY_ICONS[cat] || { icon: 'receipt_long', color: 'text-slate-600', bg: 'bg-slate-100 dark:bg-slate-800' };
}

const PIE_COLORS = ['#144bb8', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#f97316', '#ec4899'];

const BUDGET_STORAGE_KEY = 'savemoney_budgets';

function loadBudgets(): BudgetType[] {
  try {
    const raw = localStorage.getItem(BUDGET_STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    // Guard against old format (BudgetMap = plain object)
    if (!Array.isArray(parsed)) return [];
    return parsed;
  } catch {
    return [];
  }
}

function saveBudgets(budgets: BudgetType[]) {
  localStorage.setItem(BUDGET_STORAGE_KEY, JSON.stringify(budgets));
}

function getBudgetStatus(pct: number): { label: string; barColor: string; badgeClass: string } {
  if (pct >= 100) return { label: 'Over budget', barColor: 'bg-rose-500', badgeClass: 'bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400' };
  if (pct >= 85) return { label: 'Critical', barColor: 'bg-amber-500', badgeClass: 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400' };
  if (pct >= 65) return { label: 'On track', barColor: 'bg-primary', badgeClass: 'bg-primary/10 text-primary dark:bg-primary/20' };
  return { label: 'Good', barColor: 'bg-emerald-500', badgeClass: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400' };
}

function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
}

interface FormState {
  name: string;
  limit: string;
  dateStart: string;
  dateEnd: string;
  categories: string[];
}

const emptyForm: FormState = {
  name: '',
  limit: '',
  dateStart: '',
  dateEnd: '',
  categories: [],
};

export function Budget() {
  const { state } = useApp();
  const { transactions, expenseCategories } = state;

  const [budgets, setBudgets] = useState<BudgetType[]>(loadBudgets);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [formMode, setFormMode] = useState<'none' | 'create' | 'edit'>('none');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);

  useEffect(() => {
    saveBudgets(budgets);
  }, [budgets]);

  function openCreate() {
    setForm(emptyForm);
    setEditingId(null);
    setFormMode('create');
  }

  function openEdit(budget: BudgetType) {
    setForm({
      name: budget.name,
      limit: String(budget.limit),
      dateStart: budget.dateStart,
      dateEnd: budget.dateEnd,
      categories: [...budget.categories],
    });
    setEditingId(budget.id);
    setFormMode('edit');
  }

  function cancelForm() {
    setFormMode('none');
    setEditingId(null);
    setForm(emptyForm);
  }

  function saveForm() {
    const limit = parseFloat(form.limit.replace(/,/g, ''));
    if (!form.name.trim() || isNaN(limit) || limit <= 0 || !form.dateStart || !form.dateEnd) return;

    if (formMode === 'create') {
      const newBudget: BudgetType = {
        id: generateId(),
        name: form.name.trim(),
        limit,
        dateStart: form.dateStart,
        dateEnd: form.dateEnd,
        categories: form.categories,
      };
      setBudgets((prev) => [...prev, newBudget]);
    } else if (formMode === 'edit' && editingId) {
      setBudgets((prev) =>
        prev.map((b) =>
          b.id === editingId
            ? { ...b, name: form.name.trim(), limit, dateStart: form.dateStart, dateEnd: form.dateEnd, categories: form.categories }
            : b
        )
      );
    }
    cancelForm();
  }

  function deleteBudget(id: string) {
    setBudgets((prev) => prev.filter((b) => b.id !== id));
    if (expandedId === id) setExpandedId(null);
    setDeleteConfirmId(null);
  }

  function toggleCategory(cat: string) {
    setForm((prev) => ({
      ...prev,
      categories: prev.categories.includes(cat)
        ? prev.categories.filter((c) => c !== cat)
        : [...prev.categories, cat],
    }));
  }

  const budgetsWithStats = useMemo(() => {
    return budgets.map((budget) => {
      const matchingTxs = transactions
        .filter(
          (t) =>
            t.type === 'Expense' &&
            budget.categories.includes(t.category) &&
            toYYYYMMDD(t.date) >= budget.dateStart &&
            toYYYYMMDD(t.date) <= budget.dateEnd
        )
        .sort((a, b) => b.date.getTime() - a.date.getTime());

      const spent = matchingTxs.reduce((sum, t) => sum + Math.abs(t.amount), 0);
      const pct = budget.limit > 0 ? (spent / budget.limit) * 100 : 0;

      // Category breakdown for pie chart
      const catMap = new Map<string, number>();
      matchingTxs.forEach((t) => {
        catMap.set(t.category, (catMap.get(t.category) ?? 0) + Math.abs(t.amount));
      });
      const pieData = [...catMap.entries()]
        .sort((a, b) => b[1] - a[1])
        .map(([name, value]) => ({ name, value }));

      // Group by day for the transaction table
      const groupMap = new Map<string, { dateKey: string; date: Date; txs: typeof matchingTxs; dayTotal: number }>();
      const groups: typeof groupMap extends Map<string, infer V> ? V[] : never[] = [];
      for (const tx of matchingTxs) {
        const key = toYYYYMMDD(tx.date);
        if (!groupMap.has(key)) {
          const g = { dateKey: key, date: tx.date, txs: [], dayTotal: 0 };
          groupMap.set(key, g);
          groups.push(g);
        }
        const g = groupMap.get(key)!;
        g.txs.push(tx);
        g.dayTotal += Math.abs(tx.amount);
      }

      return { budget, matchingTxs, spent, pct, pieData, groups };
    });
  }, [budgets, transactions]);

  const isFormValid =
    form.name.trim().length > 0 &&
    parseFloat(form.limit.replace(/,/g, '')) > 0 &&
    form.dateStart.length > 0 &&
    form.dateEnd.length > 0;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Budgets</h2>
          <p className="text-slate-500 dark:text-slate-400 text-sm mt-0.5">Thiết lập hạn mức chi tiêu theo khoảng thời gian và danh mục.</p>
        </div>
        {formMode === 'none' && (
          <button
            onClick={openCreate}
            className="flex items-center gap-2 px-4 py-2 bg-primary text-white text-sm font-bold rounded-lg hover:opacity-90 transition-opacity"
          >
            <span className="material-symbols-outlined text-base">add</span>
            Thêm Budget
          </button>
        )}
      </div>

      {/* Create / Edit Form */}
      {formMode !== 'none' && (
        <div className="bg-white dark:bg-slate-900 rounded-xl shadow-sm border-t-4 border-primary overflow-hidden">
          <div className="p-5 space-y-5">
            {/* Name */}
            <div>
              <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Tên Budget <span className="text-rose-400">*</span></p>
              <input
                autoFocus
                className="w-full px-3 py-1.5 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition"
                placeholder="Ví dụ: Ăn uống tháng 3"
                value={form.name}
                onChange={(e) => setForm((p) => ({ ...p, name: e.target.value }))}
              />
            </div>

            {/* Hero Limit */}
            <div className="bg-slate-50 dark:bg-slate-800/50 rounded-2xl p-5 flex flex-col items-center gap-1">
              <p className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider">Hạn mức</p>
              <input
                type="text"
                inputMode="decimal"
                value={form.limit}
                onChange={(e) => {
                  const v = e.target.value.replace(/[^0-9]/g, '');
                  setForm((p) => ({ ...p, limit: v }));
                }}
                placeholder="0"
                className="w-full text-center text-5xl font-bold bg-transparent border-none outline-none placeholder:text-slate-200 dark:placeholder:text-slate-700 text-primary transition-colors"
              />
              <span className="text-xs font-medium text-slate-400">₫ VND</span>
              {form.limit && !isNaN(parseFloat(form.limit)) && parseFloat(form.limit) > 0 && (
                <span className="text-xs text-slate-400">{formatVND(parseFloat(form.limit))}</span>
              )}
            </div>

            {/* Date range */}
            <div className="grid grid-cols-2 gap-3">
              <div>
                <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Từ ngày <span className="text-rose-400">*</span></p>
                <input
                  type="date"
                  value={form.dateStart}
                  onChange={(e) => setForm((p) => ({ ...p, dateStart: e.target.value }))}
                  className="w-full px-3 py-1.5 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition"
                />
              </div>
              <div>
                <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Đến ngày <span className="text-rose-400">*</span></p>
                <input
                  type="date"
                  value={form.dateEnd}
                  onChange={(e) => setForm((p) => ({ ...p, dateEnd: e.target.value }))}
                  className="w-full px-3 py-1.5 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition"
                />
              </div>
            </div>

            {/* Categories */}
            <div>
              <p className="text-[10px] uppercase font-bold text-slate-400 mb-2">
                Danh mục áp dụng {form.categories.length > 0 && <span className="normal-case font-normal text-slate-400">— {form.categories.length} đã chọn</span>}
              </p>
              {expenseCategories.length === 0 ? (
                <p className="text-sm text-slate-400">Chưa có danh mục chi tiêu nào.</p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {expenseCategories.map((cat) => {
                    const selected = form.categories.includes(cat);
                    return (
                      <button
                        key={cat}
                        type="button"
                        onClick={() => toggleCategory(cat)}
                        className={`px-3 py-1.5 text-xs font-semibold rounded-full border transition-colors ${
                          selected
                            ? 'bg-primary text-white border-primary'
                            : 'bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-400 border-slate-200 dark:border-slate-700 hover:border-primary/50'
                        }`}
                      >
                        {cat}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Actions */}
            <div className="flex gap-2 justify-end">
              <button
                onClick={saveForm}
                disabled={!isFormValid}
                className="flex items-center gap-1.5 px-5 py-2 bg-primary text-white text-sm font-bold rounded-lg hover:opacity-90 transition-opacity disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <span className="material-symbols-outlined text-sm">check</span>
                {formMode === 'create' ? 'Tạo Budget' : 'Lưu thay đổi'}
              </button>
              <button
                onClick={cancelForm}
                className="flex items-center gap-1.5 px-4 py-2 border border-slate-200 dark:border-slate-700 rounded-lg text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
              >
                <span className="material-symbols-outlined text-sm">close</span>
                Hủy
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Budget List */}
      {budgets.length === 0 && formMode === 'none' && (
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-16 text-center">
          <div className="size-16 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center mx-auto mb-4">
            <span className="material-symbols-outlined text-3xl text-slate-400">savings</span>
          </div>
          <h3 className="font-bold text-slate-900 dark:text-white text-lg mb-1">Chưa có budget nào</h3>
          <p className="text-slate-500 text-sm mb-6">Tạo budget để theo dõi chi tiêu theo hạn mức và thời gian.</p>
          <button
            onClick={openCreate}
            className="px-6 py-2 bg-primary text-white text-sm font-bold rounded-lg hover:opacity-90 transition-opacity"
          >
            Tạo Budget đầu tiên
          </button>
        </div>
      )}

      {budgetsWithStats.length > 0 && (
        <div className="space-y-4">
          {budgetsWithStats.map(({ budget, matchingTxs, spent, pct, pieData, groups }) => {
            const status = getBudgetStatus(pct);
            const isExpanded = expandedId === budget.id;
            const remaining = budget.limit - spent;

            return (
              <div key={budget.id} className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
                {/* Card overview */}
                <div className="p-5">
                  {/* Top row: name + actions */}
                  <div className="flex items-start justify-between gap-4 mb-4">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-bold text-slate-900 dark:text-white truncate">{budget.name}</h3>
                        <span className={`shrink-0 px-2 py-0.5 rounded-full text-xs font-bold ${status.badgeClass}`}>{status.label}</span>
                      </div>
                      <p className="text-xs text-slate-400 mb-2">
                        {formatDate(new Date(budget.dateStart + 'T00:00:00'))} → {formatDate(new Date(budget.dateEnd + 'T00:00:00'))}
                      </p>
                      {/* Category chips merged with pie legend */}
                      {budget.categories.length > 0 && (
                        <div className="flex flex-wrap gap-1.5">
                          {[...budget.categories]
                            .sort((a, b) => {
                              const aVal = pieData.find((d) => d.name === a)?.value ?? -1;
                              const bVal = pieData.find((d) => d.name === b)?.value ?? -1;
                              return bVal - aVal;
                            })
                            .map((cat) => {
                            const pieIdx = pieData.findIndex((d) => d.name === cat);
                            const color = pieIdx >= 0 ? PIE_COLORS[pieIdx % PIE_COLORS.length] : null;
                            const catPct = pieIdx >= 0 && spent > 0 ? ((pieData[pieIdx].value / spent) * 100).toFixed(0) : null;
                            return (
                              <span
                                key={cat}
                                className="flex items-center gap-1 px-2 py-0.5 text-xs rounded-full border"
                                style={color ? { borderColor: color + '60', backgroundColor: color + '15', color } : undefined}
                              >
                                {color && <span className="size-1.5 rounded-full shrink-0" style={{ backgroundColor: color }} />}
                                {!color && <span className="size-1.5 rounded-full shrink-0 bg-slate-300 dark:bg-slate-600" />}
                                <span className={color ? '' : 'text-slate-500 dark:text-slate-400'}>{cat}</span>
                                {catPct && <span className="font-bold opacity-80">{catPct}%</span>}
                              </span>
                            );
                          })}
                        </div>
                      )}
                    </div>
                    <div className="flex items-center gap-1 shrink-0">
                      <button onClick={() => openEdit(budget)} className="p-1.5 text-slate-400 hover:text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors">
                        <span className="material-symbols-outlined text-base">edit</span>
                      </button>
                      {deleteConfirmId === budget.id ? (
                        <div className="flex items-center gap-1">
                          <button onClick={() => deleteBudget(budget.id)} className="px-2 py-1 text-xs font-bold bg-rose-500 text-white rounded-lg">Xóa</button>
                          <button onClick={() => setDeleteConfirmId(null)} className="px-2 py-1 text-xs font-medium border border-slate-200 dark:border-slate-700 rounded-lg">Hủy</button>
                        </div>
                      ) : (
                        <button onClick={() => setDeleteConfirmId(budget.id)} className="p-1.5 text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-900/20 rounded-lg transition-colors">
                          <span className="material-symbols-outlined text-base">delete</span>
                        </button>
                      )}
                    </div>
                  </div>

                  {/* Progress + Pie side by side */}
                  <div className="flex items-center gap-4">
                    {/* Left: progress */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-end justify-between mb-1.5">
                        <div>
                          <span className="text-lg font-bold text-slate-900 dark:text-white">{formatVNDShort(spent)}</span>
                          <span className="text-sm text-slate-400 ml-1.5">/ {formatVNDShort(budget.limit)}</span>
                        </div>
                        <span className={`text-sm font-bold ${pct >= 100 ? 'text-rose-600' : pct >= 85 ? 'text-amber-600' : 'text-emerald-600'}`}>
                          {pct.toFixed(0)}%
                        </span>
                      </div>
                      {/* Stacked bar by category */}
                      <div className="w-full bg-slate-100 dark:bg-slate-800 h-2.5 rounded-full overflow-hidden flex">
                        {pieData.length > 0
                          ? pieData.map((d, i) => (
                              <div
                                key={d.name}
                                className="h-full transition-all"
                                style={{
                                  width: `${Math.min((d.value / budget.limit) * 100, 100)}%`,
                                  backgroundColor: PIE_COLORS[i % PIE_COLORS.length],
                                }}
                                title={`${d.name}: ${formatVNDShort(d.value)}`}
                              />
                            ))
                          : <div className={`h-full rounded-full ${status.barColor}`} style={{ width: `${Math.min(pct, 100)}%` }} />
                        }
                      </div>
                      <div className="flex justify-between mt-1.5 text-xs text-slate-400">
                        <span>{matchingTxs.length} giao dịch</span>
                        <span className={remaining < 0 ? 'text-rose-600 dark:text-rose-400 font-medium' : ''}>
                          {remaining >= 0 ? `Còn lại ${formatVNDShort(remaining)}` : `Vượt ${formatVNDShort(Math.abs(remaining))}`}
                        </span>
                      </div>

                      {/* Expand toggle */}
                      {matchingTxs.length > 0 && (
                        <button
                          onClick={() => setExpandedId(isExpanded ? null : budget.id)}
                          className="mt-3 flex items-center gap-1 text-xs font-semibold text-primary hover:opacity-75 transition-opacity"
                        >
                          <span className="material-symbols-outlined text-sm">{isExpanded ? 'expand_less' : 'expand_more'}</span>
                          {isExpanded ? 'Ẩn giao dịch' : `Xem ${matchingTxs.length} giao dịch`}
                        </button>
                      )}
                    </div>

                    {/* Right: pie chart (no legend, merged into chips above) */}
                    {pieData.length > 0 && (
                      <div className="shrink-0">
                        <ResponsiveContainer width={120} height={120}>
                          <PieChart>
                            <Pie data={pieData} dataKey="value" cx="50%" cy="50%" innerRadius={28} outerRadius={52} paddingAngle={2} strokeWidth={0}>
                              {pieData.map((_, i) => (
                                <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                              ))}
                            </Pie>
                            <Tooltip
                              formatter={(value: number) => formatVNDShort(value)}
                              contentStyle={{ fontSize: 11, borderRadius: 8, border: '1px solid #e2e8f0' }}
                            />
                          </PieChart>
                        </ResponsiveContainer>
                      </div>
                    )}
                  </div>
                </div>

                {/* Expanded Transactions — grouped by day, table style */}
                {isExpanded && (
                  <div className="border-t border-slate-200 dark:border-slate-800">
                    <table className="w-full text-left">
                      <thead className="bg-slate-50 dark:bg-slate-800/50">
                        <tr>
                          <th className="px-6 py-2.5 text-xs font-bold uppercase tracking-wider text-slate-400">Danh mục</th>
                          <th className="px-6 py-2.5 text-xs font-bold uppercase tracking-wider text-slate-400">Tài khoản</th>
                          <th className="px-6 py-2.5 text-xs font-bold uppercase tracking-wider text-slate-400 text-right">Số tiền</th>
                        </tr>
                      </thead>
                      <tbody>
                        {groups.map((group) => (
                          <React.Fragment key={group.dateKey}>
                            {/* Day header */}
                            <tr className="bg-slate-50 dark:bg-slate-800/70 border-t-2 border-slate-200 dark:border-slate-700">
                              <td className="px-6 py-2.5">
                                <span className="text-sm font-bold text-slate-700 dark:text-slate-200">{formatDate(group.date)}</span>
                              </td>
                              <td className="px-6 py-2.5 text-sm text-slate-400">{group.txs.length} giao dịch</td>
                              <td className="px-6 py-2.5 text-right text-sm font-bold text-rose-600">-{formatVND(group.dayTotal)}</td>
                            </tr>
                            {/* Transactions */}
                            {group.txs.map((tx) => {
                              const icon = getIcon(tx.category);
                              return (
                                <tr key={tx.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/50 transition-colors border-t border-slate-100 dark:border-slate-800/60">
                                  <td className="px-6 py-3">
                                    <div className="flex items-center gap-2 pl-4">
                                      <div className={`size-7 rounded ${icon.bg} ${icon.color} flex items-center justify-center shrink-0`}>
                                        <span className="material-symbols-outlined text-base">{icon.icon}</span>
                                      </div>
                                      <span className="text-sm font-medium text-slate-800 dark:text-slate-200">{tx.category}</span>
                                    </div>
                                  </td>
                                  <td className="px-6 py-3 text-sm text-slate-500 dark:text-slate-400">{tx.account}</td>
                                  <td className="px-6 py-3 text-right text-sm font-bold text-rose-600 dark:text-rose-400">
                                    -{formatVND(tx.amount)}
                                  </td>
                                </tr>
                              );
                            })}
                          </React.Fragment>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
