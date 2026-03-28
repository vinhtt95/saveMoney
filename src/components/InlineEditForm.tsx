import { useState } from 'react';
import { Account, Category } from '../types';
import { Combobox } from './Combobox';
import { MiniCalendar, CalendarAccentColor } from './MiniCalendar';
import { Draft } from './InlineFields';
import { formatVND } from '../utils/formatters';

type Mode = 'Expense' | 'Transfer' | 'Income';

const MODE_STYLES: Record<Mode, { active: string; accent: string; label: string; amountColor: string }> = {
  Expense: {
    active: 'bg-rose-500 text-white shadow-sm',
    accent: 'border-t-4 border-rose-500',
    label: 'Chi tiêu',
    amountColor: 'text-rose-500',
  },
  Transfer: {
    active: 'bg-blue-500 text-white shadow-sm',
    accent: 'border-t-4 border-blue-500',
    label: 'Chuyển khoản',
    amountColor: 'text-blue-500',
  },
  Income: {
    active: 'bg-emerald-500 text-white shadow-sm',
    accent: 'border-t-4 border-emerald-500',
    label: 'Thu nhập',
    amountColor: 'text-emerald-500',
  },
};

const MODE_ACCENT: Record<Mode, CalendarAccentColor> = {
  Expense: 'rose',
  Transfer: 'blue',
  Income: 'emerald',
};

const fieldCls =
  'w-full px-2 py-1.5 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition';

interface Props {
  draft: Draft;
  onChange: (patch: Partial<Draft>) => void;
  expenseCategories: Category[];
  incomeCategories: Category[];
  allAccounts: Account[];
  error?: string;
  onSave: () => void;
  onCancel: () => void;
  onDelete: () => void;
  onNewCategory?: (name: string, type: 'Expense' | 'Income') => string;
  onNewAccount?: (name: string) => string;
}

export function InlineEditForm({
  draft,
  onChange,
  expenseCategories,
  incomeCategories,
  allAccounts,
  error,
  onSave,
  onCancel,
  onDelete,
  onNewCategory,
  onNewAccount,
}: Props) {
  const [amountFocused, setAmountFocused] = useState(false);
  const mode = (draft.type === 'Account' ? 'Expense' : draft.type) as Mode;
  const styles = MODE_STYLES[mode];
  const displayAmount =
    !amountFocused && draft.amountStr
      ? Number(draft.amountStr).toLocaleString('vi-VN')
      : draft.amountStr;

  const expenseOpts = expenseCategories.map((c) => ({ value: c.id, label: c.name }));
  const incomeOpts = incomeCategories.map((c) => ({ value: c.id, label: c.name }));
  const accountOpts = allAccounts.map((a) => ({ value: a.id, label: a.name }));
  const categoryOpts = draft.type === 'Expense' ? expenseOpts : incomeOpts;

  function handleCategoryChange(v: string) {
    const allCats = [...expenseCategories, ...incomeCategories];
    if (allCats.some((c) => c.id === v)) {
      onChange({ categoryId: v });
    } else if (onNewCategory) {
      const type = draft.type === 'Income' ? 'Income' : 'Expense';
      const id = onNewCategory(v, type);
      onChange({ categoryId: id });
    }
  }

  function handleAccountChange(v: string) {
    if (allAccounts.some((a) => a.id === v)) {
      onChange({ accountId: v });
    } else if (onNewAccount) {
      const id = onNewAccount(v);
      onChange({ accountId: id });
    }
  }

  function handleTransferToChange(v: string) {
    if (allAccounts.some((a) => a.id === v)) {
      onChange({ transferToId: v });
    } else if (onNewAccount) {
      const id = onNewAccount(v);
      onChange({ transferToId: id });
    }
  }

  return (
    <div className={`bg-white dark:bg-slate-900 rounded-xl shadow-sm ${styles.accent}`}>
      <div className="p-5 flex flex-col gap-4">
        {/* Mode switcher - Full Width */}
        <div className="flex bg-slate-100 dark:bg-slate-800 rounded-xl p-1 gap-1">
          {(['Expense', 'Transfer', 'Income'] as Mode[]).map((m) => (
            <button
              key={m}
              type="button"
              onClick={(e) => {
                e.stopPropagation();
                const newCategoryId =
                  m === 'Expense'
                    ? (expenseCategories[0]?.id ?? '')
                    : m === 'Income'
                    ? (incomeCategories[0]?.id ?? '')
                    : '';
                onChange({ type: m, categoryId: newCategoryId, transferToId: '' });
              }}
              className={`flex-1 py-2 rounded-lg text-sm font-semibold transition-all ${
                mode === m
                  ? styles.active
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-700 dark:hover:text-slate-200'
              }`}
            >
              {MODE_STYLES[m].label}
            </button>
          ))}
        </div>

        {/* 2-Column Split */}
        <div className="flex gap-4 items-start flex-col sm:flex-row">
          {/* LEFT: 3/5 - Amount + Secondary Fields */}
          <div style={{ flex: 3 }} className="flex flex-col gap-4 min-w-0 w-full sm:w-auto">
            {/* Hero amount input */}
            <div className="bg-slate-50 dark:bg-slate-800/50 rounded-2xl p-5 flex flex-col items-center gap-1">
              <p className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider">Số tiền</p>
              <input
                type="text"
                inputMode="decimal"
                value={amountFocused ? draft.amountStr : displayAmount}
                onChange={(e) => {
                  const v = e.target.value.replace(/[^0-9.]/g, '');
                  onChange({ amountStr: v });
                }}
                onFocus={() => setAmountFocused(true)}
                onBlur={() => setAmountFocused(false)}
                onClick={(e) => e.stopPropagation()}
                placeholder="0"
                className={`w-full text-center text-5xl font-bold bg-transparent border-none outline-none placeholder:text-slate-200 dark:placeholder:text-slate-700 ${styles.amountColor} transition-colors`}
              />
              <span className="text-xs font-medium text-slate-400">₫ VND</span>
              {draft.amountStr && !isNaN(parseFloat(draft.amountStr)) && (
                <span className="text-xs text-slate-400">{formatVND(parseFloat(draft.amountStr))}</span>
              )}
            </div>

            {/* Secondary fields (no date) */}
            <div className="space-y-3">
              {draft.type === 'Transfer' ? (
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Từ tài khoản <span className="text-rose-400">*</span></p>
                    <Combobox value={draft.accountId} onChange={handleAccountChange} options={accountOpts} placeholder="Tài khoản nguồn..." allowCustom />
                  </div>
                  <div>
                    <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Đến tài khoản <span className="text-rose-400">*</span></p>
                    <Combobox value={draft.transferToId} onChange={handleTransferToChange} options={accountOpts} placeholder="Tài khoản đích..." allowCustom />
                  </div>
                </div>
              ) : (
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Danh mục <span className="text-rose-400">*</span></p>
                    <Combobox
                      value={draft.categoryId}
                      onChange={handleCategoryChange}
                      options={categoryOpts}
                      placeholder="Coffee, Transport..."
                      allowCustom
                    />
                  </div>
                  <div>
                    <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Tài khoản <span className="text-rose-400">*</span></p>
                    <Combobox value={draft.accountId} onChange={handleAccountChange} options={accountOpts} placeholder="Tiền mặt..." allowCustom />
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* RIGHT: ~27% - Calendar */}
          <div style={{ flex: 0.715 }} className="min-w-0 w-full sm:w-auto">
            <MiniCalendar
              value={draft.date}
              onChange={(date) => onChange({ date })}
              accentColor={MODE_ACCENT[mode]}
            />
          </div>
        </div>

        {error && <p className="text-xs text-rose-500">{error}</p>}

        {/* Actions */}
        <div className="flex gap-2">
          <button
            onClick={(e) => { e.stopPropagation(); onSave(); }}
            className="flex-1 flex items-center justify-center gap-1.5 py-2.5 bg-primary text-white rounded-xl text-sm font-semibold hover:opacity-90 transition-opacity"
          >
            <span className="material-symbols-outlined text-sm">check</span> Lưu thay đổi
          </button>
          <button
            onClick={(e) => { e.stopPropagation(); onCancel(); }}
            className="flex items-center justify-center gap-1.5 px-4 py-2.5 border border-slate-200 dark:border-slate-700 rounded-xl text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
          >
            <span className="material-symbols-outlined text-sm">close</span> Hủy
          </button>
          <button
            onClick={(e) => { e.stopPropagation(); onDelete(); }}
            className="flex items-center justify-center gap-1.5 px-4 py-2.5 text-red-600 bg-red-50 dark:bg-red-900/10 border border-red-100 dark:border-red-900/30 rounded-xl text-sm font-medium hover:bg-red-100 transition-colors"
          >
            <span className="material-symbols-outlined text-sm">delete</span>
          </button>
        </div>
      </div>
    </div>
  );
}
