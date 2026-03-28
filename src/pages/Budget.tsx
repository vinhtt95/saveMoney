import React, { useState, useMemo } from 'react';
import {
  PieChart, Pie, Cell, Tooltip, ResponsiveContainer,
  BarChart, Bar, XAxis, YAxis, LineChart, Line, Legend,
} from 'recharts';
import { useApp } from '../context/AppContext';
import type { Budget as BudgetType, Transaction, Category, Account } from '../types';
import { categoryName as resolveCategoryName, accountName as resolveAccountName } from '../utils/lookup';
import { Draft } from '../components/InlineFields';
import { InlineEditForm } from '../components/InlineEditForm';
import { formatVND, formatVNDShort, formatDate, toYYYYMM, toYYYYMMDD } from '../utils/formatters';
import { getCategoryMonthMatrix, getCategoryMonthlyTrend, getCategoryDailyTrend, getCategoryWeeklyTrend, getAvailablePeriods } from '../utils/analytics';

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
function getIcon(name: string) {
  return CATEGORY_ICONS[name] || { icon: 'receipt_long', color: 'text-slate-600', bg: 'bg-slate-100 dark:bg-slate-800' };
}

function draftFromTx(tx: Transaction): Draft {
  return {
    date: `${tx.date.getFullYear()}-${String(tx.date.getMonth() + 1).padStart(2, '0')}-${String(tx.date.getDate()).padStart(2, '0')}`,
    type: tx.type,
    categoryId: tx.categoryId,
    accountId: tx.accountId,
    transferToId: tx.transferToId,
    amountStr: String(Math.abs(tx.amount)),
    note: tx.note || '',
  };
}

function draftToTx(draft: Draft, id: string): Transaction | null {
  const amt = parseFloat(draft.amountStr);
  const needsCategory = draft.type !== 'Transfer';
  if (!draft.date || (needsCategory && !draft.categoryId) || !draft.accountId || !draft.amountStr || isNaN(amt) || amt <= 0) {
    return null;
  }
  if (draft.type === 'Transfer' && !draft.transferToId) return null;
  return {
    id,
    date: new Date(draft.date),
    type: draft.type,
    categoryId: draft.categoryId,
    accountId: draft.accountId,
    transferToId: draft.transferToId,
    amount: draft.type === 'Expense' ? -Math.abs(amt) : Math.abs(amt),
    note: draft.note || undefined,
  };
}

const PIE_COLORS = ['#144bb8', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#f97316', '#ec4899'];


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
  categoryIds: string[];
}

const emptyForm: FormState = {
  name: '',
  limit: '',
  dateStart: '',
  dateEnd: '',
  categoryIds: [],
};

export function Budget() {
  const { state, actions } = useApp();
  const { transactions, categories, accounts, budgets } = state;
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [analyticsOpenId, setAnalyticsOpenId] = useState<string | null>(null);
  const [selectedCatPerBudget, setSelectedCatPerBudget] = useState<Record<string, string>>({});
  const [trendGranularityPerBudget, setTrendGranularityPerBudget] = useState<Record<string, 'day' | 'week' | 'month'>>({});
  const [formMode, setFormMode] = useState<'none' | 'create' | 'edit'>('none');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<FormState>(emptyForm);
  const [deleteConfirmId, setDeleteConfirmId] = useState<string | null>(null);
  const [expandedTxRow, setExpandedTxRow] = useState<string | null>(null);
  const [txDraft, setTxDraft] = useState<Draft | null>(null);
  const [txEditError, setTxEditError] = useState('');

  const expenseCategories = useMemo(() => categories.filter((c) => c.type === 'Expense'), [categories]);
  const incomeCategories = useMemo(() => categories.filter((c) => c.type === 'Income'), [categories]);

  function handleNewCategory(name: string, type: 'Expense' | 'Income'): string {
    const id = crypto.randomUUID();
    const cat: Category = { id, name, type };
    actions.addCategory(cat);
    return id;
  }

  function handleNewAccount(name: string): string {
    const id = crypto.randomUUID();
    const acc: Account = { id, name };
    actions.addAccount(acc);
    return id;
  }

  async function confirmTxEdit() {
    if (!expandedTxRow || !txDraft) return;
    const tx = draftToTx(txDraft, expandedTxRow);
    if (!tx) { setTxEditError('Vui lòng điền đầy đủ thông tin hợp lệ.'); return; }
    await actions.editTransaction(tx);
    setExpandedTxRow(null);
    setTxDraft(null);
    setTxEditError('');
  }

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
      categoryIds: [...budget.categoryIds],
    });
    setEditingId(budget.id);
    setFormMode('edit');
  }

  function cancelForm() {
    setFormMode('none');
    setEditingId(null);
    setForm(emptyForm);
  }

  async function saveForm() {
    const limit = parseFloat(form.limit.replace(/,/g, ''));
    if (!form.name.trim() || isNaN(limit) || limit <= 0 || !form.dateStart || !form.dateEnd) return;

    if (formMode === 'create') {
      const newBudget: BudgetType = {
        id: generateId(),
        name: form.name.trim(),
        limit,
        dateStart: form.dateStart,
        dateEnd: form.dateEnd,
        categoryIds: form.categoryIds,
      };
      await actions.addBudget(newBudget);
    } else if (formMode === 'edit' && editingId) {
      const updated: BudgetType = {
        id: editingId,
        name: form.name.trim(),
        limit,
        dateStart: form.dateStart,
        dateEnd: form.dateEnd,
        categoryIds: form.categoryIds,
      };
      await actions.editBudget(updated);
    }
    cancelForm();
  }

  async function deleteBudget(id: string) {
    await actions.deleteBudget(id);
    if (expandedId === id) setExpandedId(null);
    setDeleteConfirmId(null);
  }

  function toggleCategory(catId: string) {
    setForm((prev) => ({
      ...prev,
      categoryIds: prev.categoryIds.includes(catId)
        ? prev.categoryIds.filter((c) => c !== catId)
        : [...prev.categoryIds, catId],
    }));
  }

  const budgetsWithStats = useMemo(() => {
    return budgets.map((budget) => {
      const matchingTxs = transactions
        .filter(
          (t) =>
            t.type === 'Expense' &&
            budget.categoryIds.includes(t.categoryId) &&
            toYYYYMMDD(t.date) >= budget.dateStart &&
            toYYYYMMDD(t.date) <= budget.dateEnd
        )
        .sort((a, b) => b.date.getTime() - a.date.getTime());

      const spent = matchingTxs.reduce((sum, t) => sum + Math.abs(t.amount), 0);
      const pct = budget.limit > 0 ? (spent / budget.limit) * 100 : 0;

      // Category breakdown for pie chart — use name for display
      const catMap = new Map<string, { id: string; name: string; value: number }>();
      matchingTxs.forEach((t) => {
        const name = resolveCategoryName(categories, t.categoryId);
        if (!catMap.has(t.categoryId)) catMap.set(t.categoryId, { id: t.categoryId, name, value: 0 });
        catMap.get(t.categoryId)!.value += Math.abs(t.amount);
      });
      const pieData = [...catMap.values()]
        .sort((a, b) => b.value - a.value)
        .map(({ id, name, value }) => ({ id, name, value }));

      // Group by day
      const groupMap = new Map<string, { dateKey: string; date: Date; txs: typeof matchingTxs; dayTotal: number }>();
      const groups: { dateKey: string; date: Date; txs: typeof matchingTxs; dayTotal: number }[] = [];
      for (const tx of matchingTxs) {
        const key = toYYYYMMDD(tx.date);
        if (!groupMap.has(key)) {
          const g = { dateKey: key, date: tx.date, txs: [] as typeof matchingTxs, dayTotal: 0 };
          groupMap.set(key, g);
          groups.push(g);
        }
        const g = groupMap.get(key)!;
        g.txs.push(tx);
        g.dayTotal += Math.abs(tx.amount);
      }

      // Analytics: month matrix (keys are categoryIds)
      const fromPeriod = toYYYYMM(new Date(budget.dateStart + 'T00:00:00'));
      const toPeriod = toYYYYMM(new Date(budget.dateEnd + 'T00:00:00'));
      const matrixData = matchingTxs.length > 0 ? getCategoryMonthMatrix(matchingTxs, fromPeriod, toPeriod) : [];
      const matrixPeriods = getAvailablePeriods(matchingTxs).filter((p) => p >= fromPeriod && p <= toPeriod).slice().reverse();
      const matrixCatIds = matrixData.length > 0
        ? (() => {
            const ids = Object.keys(matrixData[0]).filter((k) => k !== 'month');
            const totals: Record<string, number> = {};
            ids.forEach((id) => { totals[id] = matrixData.reduce((s, row) => s + ((row[id] as number) || 0), 0); });
            return ids.sort((a, b) => totals[b] - totals[a]);
          })()
        : [];
      const isMultiMonth = fromPeriod !== toPeriod;

      return { budget, matchingTxs, spent, pct, pieData, groups, matrixData, matrixPeriods, matrixCatIds, isMultiMonth, fromPeriod, toPeriod };
    });
  }, [budgets, transactions, categories]);

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
                Danh mục áp dụng {form.categoryIds.length > 0 && <span className="normal-case font-normal text-slate-400">— {form.categoryIds.length} đã chọn</span>}
              </p>
              {expenseCategories.length === 0 ? (
                <p className="text-sm text-slate-400">Chưa có danh mục chi tiêu nào.</p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {expenseCategories.map((cat) => {
                    const selected = form.categoryIds.includes(cat.id);
                    return (
                      <button
                        key={cat.id}
                        type="button"
                        onClick={() => toggleCategory(cat.id)}
                        className={`px-3 py-1.5 text-xs font-semibold rounded-full border transition-colors ${
                          selected
                            ? 'bg-primary text-white border-primary'
                            : 'bg-white dark:bg-slate-800 text-slate-600 dark:text-slate-400 border-slate-200 dark:border-slate-700 hover:border-primary/50'
                        }`}
                      >
                        {cat.name}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>

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
          {budgetsWithStats.map(({ budget, matchingTxs, spent, pct, pieData, groups, matrixData, matrixPeriods, matrixCatIds, isMultiMonth }) => {
            const status = getBudgetStatus(pct);
            const isExpanded = expandedId === budget.id;
            const isAnalyticsOpen = analyticsOpenId === budget.id;
            const remaining = budget.limit - spent;
            const selectedCatId = selectedCatPerBudget[budget.id] || matrixCatIds[0] || '';
            const selectedCatDisplayName = selectedCatId ? resolveCategoryName(categories, selectedCatId) : '';
            const granularity = trendGranularityPerBudget[budget.id] || 'week';
            const trendData: { label: string; amount: number }[] = selectedCatId
              ? granularity === 'day'
                ? getCategoryDailyTrend(matchingTxs, selectedCatId, budget.dateStart, budget.dateEnd).map((d) => ({ label: d.day, amount: d.amount }))
                : granularity === 'week'
                  ? getCategoryWeeklyTrend(matchingTxs, selectedCatId, budget.dateStart, budget.dateEnd).map((d) => ({ label: d.week, amount: d.amount }))
                  : matrixPeriods.length > 0 ? getCategoryMonthlyTrend(matchingTxs, selectedCatId, matrixPeriods).map((d) => ({ label: d.month, amount: d.amount })) : []
              : [];

            return (
              <div key={budget.id} className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
                {/* Card overview */}
                <div className="p-5">
                  <div className="flex items-start justify-between gap-4 mb-4">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <h3 className="font-bold text-slate-900 dark:text-white truncate">{budget.name}</h3>
                        <span className={`shrink-0 px-2 py-0.5 rounded-full text-xs font-bold ${status.badgeClass}`}>{status.label}</span>
                      </div>
                      <p className="text-xs text-slate-400 mb-2">
                        {formatDate(new Date(budget.dateStart + 'T00:00:00'))} → {formatDate(new Date(budget.dateEnd + 'T00:00:00'))}
                      </p>
                      {budget.categoryIds.length > 0 && (
                        <div className="flex flex-wrap gap-1.5">
                          {[...budget.categoryIds]
                            .sort((a, b) => {
                              const aVal = pieData.find((d) => d.id === a)?.value ?? -1;
                              const bVal = pieData.find((d) => d.id === b)?.value ?? -1;
                              return bVal - aVal;
                            })
                            .map((catId) => {
                              const name = resolveCategoryName(categories, catId);
                              const pieIdx = pieData.findIndex((d) => d.id === catId);
                              const color = pieIdx >= 0 ? PIE_COLORS[pieIdx % PIE_COLORS.length] : null;
                              const catPct = pieIdx >= 0 && spent > 0 ? ((pieData[pieIdx].value / spent) * 100).toFixed(0) : null;
                              return (
                                <span
                                  key={catId}
                                  className="flex items-center gap-1 px-2 py-0.5 text-xs rounded-full border"
                                  style={color ? { borderColor: color + '60', backgroundColor: color + '15', color } : undefined}
                                >
                                  {color && <span className="size-1.5 rounded-full shrink-0" style={{ backgroundColor: color }} />}
                                  {!color && <span className="size-1.5 rounded-full shrink-0 bg-slate-300 dark:bg-slate-600" />}
                                  <span className={color ? '' : 'text-slate-500 dark:text-slate-400'}>{name}</span>
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

                  <div className="flex items-center gap-4">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-end justify-between mb-1.5">
                        <div>
                          <span className="text-lg font-bold text-slate-900 dark:text-white">{formatVND(spent)}</span>
                          <span className="text-sm text-slate-400 ml-1.5">/ {formatVND(budget.limit)}</span>
                        </div>
                        <span className={`text-sm font-bold ${pct >= 100 ? 'text-rose-600' : pct >= 85 ? 'text-amber-600' : 'text-emerald-600'}`}>
                          {pct.toFixed(0)}%
                        </span>
                      </div>
                      <div className="w-full bg-slate-100 dark:bg-slate-800 h-2.5 rounded-full overflow-hidden flex">
                        {pieData.length > 0
                          ? pieData.map((d, i) => (
                              <div
                                key={d.id}
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
                          {remaining >= 0 ? `Còn lại ${formatVND(remaining)}` : `Vượt ${formatVND(Math.abs(remaining))}`}
                        </span>
                      </div>

                      {matchingTxs.length > 0 && (
                        <div className="mt-3 flex items-center gap-3">
                          <button
                            onClick={() => setExpandedId(isExpanded ? null : budget.id)}
                            className="flex items-center gap-1 text-xs font-semibold text-primary hover:opacity-75 transition-opacity"
                          >
                            <span className="material-symbols-outlined text-sm">{isExpanded ? 'expand_less' : 'expand_more'}</span>
                            {isExpanded ? 'Ẩn giao dịch' : `Xem ${matchingTxs.length} giao dịch`}
                          </button>
                          <button
                            onClick={() => setAnalyticsOpenId(isAnalyticsOpen ? null : budget.id)}
                            className="flex items-center gap-1 text-xs font-semibold text-slate-500 dark:text-slate-400 hover:text-primary hover:opacity-90 transition-colors"
                          >
                            <span className="material-symbols-outlined text-sm">{isAnalyticsOpen ? 'expand_less' : 'bar_chart'}</span>
                            {isAnalyticsOpen ? 'Ẩn analytics' : 'Xem analytics'}
                          </button>
                        </div>
                      )}
                    </div>

                    {pieData.length > 0 && (
                      <div className="shrink-0">
                        <ResponsiveContainer width={120} height={120}>
                          <PieChart>
                            <Pie data={pieData} dataKey="value" nameKey="name" cx="50%" cy="50%" innerRadius={28} outerRadius={52} paddingAngle={2} strokeWidth={0}>
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

                {/* Analytics Panel */}
                {isAnalyticsOpen && matrixData.length > 0 && (
                  <div className="border-t border-slate-200 dark:border-slate-800 p-5 space-y-6">
                    <h4 className="text-sm font-bold text-slate-700 dark:text-slate-200 flex items-center gap-2">
                      <span className="material-symbols-outlined text-base text-primary">bar_chart</span>
                      Analytics
                    </h4>

                    {isMultiMonth && matrixCatIds.length > 0 && (
                      <div>
                        <p className="text-xs font-semibold text-slate-500 dark:text-slate-400 mb-3">Chi tiêu theo tháng và danh mục</p>
                        <div className="h-56">
                          <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={matrixData} margin={{ top: 0, right: 0, left: 0, bottom: 0 }}>
                              <XAxis dataKey="month" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} />
                              <YAxis tickFormatter={(v) => formatVNDShort(v)} tick={{ fontSize: 10 }} tickLine={false} axisLine={false} width={72} />
                              <Tooltip
                                formatter={(value: number, catId: string) => [formatVND(value), resolveCategoryName(categories, catId)]}
                                labelFormatter={(label) => `Tháng ${label}`}
                              />
                              <Legend formatter={(catId: string) => resolveCategoryName(categories, catId)} />
                              {matrixCatIds.map((catId, i) => (
                                <Bar key={catId} dataKey={catId} stackId="a" fill={PIE_COLORS[i % PIE_COLORS.length]} radius={i === matrixCatIds.length - 1 ? [4, 4, 0, 0] : [0, 0, 0, 0]} />
                              ))}
                            </BarChart>
                          </ResponsiveContainer>
                        </div>
                      </div>
                    )}

                    <div>
                      <div className="flex items-center justify-between mb-3">
                        <div className="flex items-center gap-2">
                          <p className="text-xs font-semibold text-slate-500 dark:text-slate-400">Chi tiêu theo danh mục</p>
                          {selectedCatId && (
                            <div className="flex items-center gap-1.5 px-2.5 py-1 bg-primary/10 rounded-lg">
                              <div className="size-2 rounded-full bg-primary" />
                              <span className="text-xs font-bold text-primary">{selectedCatDisplayName}</span>
                            </div>
                          )}
                        </div>
                        <div className="flex items-center gap-1">
                          {(['day', 'week', 'month'] as const).map((g) => (
                            <button
                              key={g}
                              onClick={() => setTrendGranularityPerBudget((prev) => ({ ...prev, [budget.id]: g }))}
                              className={`px-2.5 py-1 text-xs font-bold rounded-lg transition-colors ${granularity === g ? 'bg-primary text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700'}`}
                            >
                              {g === 'day' ? 'Ngày' : g === 'week' ? 'Tuần' : 'Tháng'}
                            </button>
                          ))}
                        </div>
                      </div>
                      {trendData.length > 0 ? (
                        <div className="h-44">
                          <ResponsiveContainer width="100%" height="100%">
                            <LineChart data={trendData} margin={{ top: 4, right: 8, left: 0, bottom: 0 }}>
                              <XAxis dataKey="label" tick={{ fontSize: 11 }} tickLine={false} axisLine={false} interval="preserveStartEnd" />
                              <YAxis tickFormatter={(v) => formatVNDShort(v)} tick={{ fontSize: 10 }} tickLine={false} axisLine={false} width={72} />
                              <Tooltip formatter={(value: number) => [formatVND(value), selectedCatDisplayName]} />
                              <Line type="monotone" dataKey="amount" stroke="#144bb8" strokeWidth={2} dot={{ r: 3, fill: '#144bb8' }} activeDot={{ r: 5 }} />
                            </LineChart>
                          </ResponsiveContainer>
                        </div>
                      ) : (
                        <div className="h-44 flex items-center justify-center text-slate-400 text-xs">Không có dữ liệu.</div>
                      )}
                    </div>

                    {/* Category × Month table */}
                    <div>
                      <p className="text-xs font-semibold text-slate-500 dark:text-slate-400 mb-2">
                        Bảng chi tiết · <span className="font-normal">Click vào dòng để xem biểu đồ · Đỏ = tăng, xanh = giảm</span>
                      </p>
                      <div className="overflow-x-auto rounded-lg border border-slate-100 dark:border-slate-800">
                        <table className="w-full text-left text-sm">
                          <thead className="bg-slate-50 dark:bg-slate-800/50 text-slate-500 text-xs font-bold uppercase tracking-wider">
                            <tr>
                              <th className="px-4 py-2.5 sticky left-0 bg-slate-50 dark:bg-slate-800/50 min-w-[130px]">Danh mục</th>
                              {matrixData.map((row) => (
                                <th key={row.month as string} className="px-4 py-2.5 text-right whitespace-nowrap">{row.month as string}</th>
                              ))}
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                            {matrixCatIds.map((catId, ci) => {
                              const isSel = selectedCatId === catId;
                              const catDisplayName = resolveCategoryName(categories, catId);
                              const values = matrixData.map((row) => (row[catId] as number) || 0);
                              return (
                                <tr
                                  key={catId}
                                  onClick={() => setSelectedCatPerBudget((prev) => ({ ...prev, [budget.id]: catId }))}
                                  className={`cursor-pointer transition-colors ${isSel ? 'bg-primary/5 dark:bg-primary/10' : 'hover:bg-slate-50 dark:hover:bg-slate-800/50'}`}
                                >
                                  <td className={`px-4 py-2.5 sticky left-0 font-medium ${isSel ? 'bg-primary/5 dark:bg-primary/10' : 'bg-white dark:bg-slate-900'}`}>
                                    <div className="flex items-center gap-2">
                                      <div className="size-2.5 rounded-full shrink-0" style={{ backgroundColor: PIE_COLORS[ci % PIE_COLORS.length] }} />
                                      <span className={`truncate max-w-[100px] ${isSel ? 'text-primary font-bold' : ''}`}>{catDisplayName}</span>
                                      {isSel && <span className="material-symbols-outlined text-xs text-primary">show_chart</span>}
                                    </div>
                                  </td>
                                  {values.map((val, vi) => {
                                    const prev = vi > 0 ? values[vi - 1] : null;
                                    const isUp = prev !== null && prev > 0 && val > prev;
                                    const isDown = prev !== null && prev > 0 && val < prev;
                                    return (
                                      <td
                                        key={vi}
                                        className={`px-4 py-2.5 text-right font-medium whitespace-nowrap ${
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
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      </div>
                    </div>
                  </div>
                )}

                {/* Expanded Transactions */}
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
                            <tr className="bg-slate-50 dark:bg-slate-800/70 border-t-2 border-slate-200 dark:border-slate-700">
                              <td className="px-6 py-2.5">
                                <span className="text-sm font-bold text-slate-700 dark:text-slate-200">{formatDate(group.date)}</span>
                              </td>
                              <td className="px-6 py-2.5 text-sm text-slate-400">{group.txs.length} giao dịch</td>
                              <td className="px-6 py-2.5 text-right text-sm font-bold text-rose-600">-{formatVND(group.dayTotal)}</td>
                            </tr>
                            {group.txs.map((tx) => {
                              const txCatName = resolveCategoryName(categories, tx.categoryId);
                              const txAccName = resolveAccountName(accounts, tx.accountId);
                              const icon = getIcon(txCatName);
                              const isTxExpanded = expandedTxRow === tx.id;
                              const typeColor = txDraft?.type === 'Income' ? 'emerald' : txDraft?.type === 'Transfer' ? 'sky' : 'rose';
                              return (
                                <React.Fragment key={tx.id}>
                                  <tr
                                    className={`cursor-pointer transition-colors border-t border-slate-100 dark:border-slate-800/60 ${isTxExpanded ? 'bg-slate-50 dark:bg-slate-800/40' : 'hover:bg-slate-50/50 dark:hover:bg-slate-800/50'}`}
                                    onClick={() => {
                                      if (isTxExpanded) {
                                        setExpandedTxRow(null);
                                        setTxDraft(null);
                                        setTxEditError('');
                                      } else {
                                        setExpandedTxRow(tx.id);
                                        setTxDraft(draftFromTx(tx));
                                        setTxEditError('');
                                      }
                                    }}
                                  >
                                    <td className="px-6 py-3">
                                      <div className="flex items-center gap-2 pl-4">
                                        <div className={`size-7 rounded ${icon.bg} ${icon.color} flex items-center justify-center shrink-0`}>
                                          <span className="material-symbols-outlined text-base">{icon.icon}</span>
                                        </div>
                                        <div className="flex flex-col">
                                          <span className="text-sm font-medium text-slate-800 dark:text-slate-200">{txCatName}</span>
                                          {tx.note && <span className="text-[10px] text-slate-400 italic truncate max-w-[120px]">{tx.note}</span>}
                                        </div>
                                      </div>
                                    </td>
                                    <td className="px-6 py-3 text-sm text-slate-500 dark:text-slate-400">{txAccName}</td>
                                    <td className="px-6 py-3 text-right text-sm font-medium text-rose-400 dark:text-rose-300/60">
                                      -{formatVND(Math.abs(tx.amount))}
                                    </td>
                                  </tr>
                                  {isTxExpanded && txDraft && (
                                    <tr>
                                      <td colSpan={3} className={`px-6 py-5 border-t border-primary/10 bg-${typeColor}-50 dark:bg-${typeColor}-900/20`}>
                                        <InlineEditForm
                                          draft={txDraft}
                                          onChange={(patch) => setTxDraft((d) => d ? { ...d, ...patch } : d)}
                                          expenseCategories={expenseCategories}
                                          incomeCategories={incomeCategories}
                                          allAccounts={accounts}
                                          error={txEditError}
                                          onSave={confirmTxEdit}
                                          onCancel={() => { setExpandedTxRow(null); setTxDraft(null); setTxEditError(''); }}
                                          onDelete={async () => {
                                            if (confirm('Xóa giao dịch này?')) {
                                              await actions.deleteTransaction(tx.id);
                                              setExpandedTxRow(null);
                                              setTxDraft(null);
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
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
