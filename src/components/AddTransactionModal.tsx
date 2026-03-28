import { useState, useEffect } from 'react';
import { Account, Category, TransactionType, Transaction } from '../types';
import { Combobox } from './Combobox';
import { MiniCalendar, CalendarAccentColor } from './MiniCalendar';
import { formatVND, toYYYYMMDD } from '../utils/formatters';

interface Draft {
  date: string;
  type: TransactionType;
  categoryId: string;
  accountId: string;
  transferToId: string;
  amountStr: string;
  note: string;
}

type Mode = 'Expense' | 'Transfer' | 'Income';

const MODE_STYLES: Record<Mode, { active: string; accent: string; label: string }> = {
  Expense: {
    active: 'bg-rose-500 text-white shadow-sm',
    accent: 'border-t-4 border-rose-500',
    label: 'Chi tiêu',
  },
  Transfer: {
    active: 'bg-blue-500 text-white shadow-sm',
    accent: 'border-t-4 border-blue-500',
    label: 'Chuyển khoản',
  },
  Income: {
    active: 'bg-emerald-500 text-white shadow-sm',
    accent: 'border-t-4 border-emerald-500',
    label: 'Thu nhập',
  },
};

const AMOUNT_COLOR: Record<Mode, string> = {
  Expense: 'text-rose-500',
  Transfer: 'text-blue-500',
  Income: 'text-emerald-500',
};

const MODE_ACCENT: Record<Mode, CalendarAccentColor> = {
  Expense: 'rose',
  Transfer: 'blue',
  Income: 'emerald',
};

function emptyDraft(
  mode: Mode,
  defaultCategoryExpenseId: string,
  defaultCategoryIncomeId: string,
  defaultAccountId: string
): Draft {
  return {
    date: toYYYYMMDD(new Date()),
    type: mode,
    categoryId: mode === 'Expense' ? defaultCategoryExpenseId : mode === 'Income' ? defaultCategoryIncomeId : '',
    accountId: defaultAccountId,
    transferToId: '',
    amountStr: '',
    note: '',
  };
}

function draftToTx(draft: Draft, id: string): Transaction | null {
  const amt = parseFloat(draft.amountStr);
  if (!draft.date || !draft.accountId || !draft.amountStr || isNaN(amt) || amt <= 0) return null;
  if (draft.type !== 'Transfer' && !draft.categoryId) return null;
  if (draft.type === 'Transfer' && !draft.transferToId) return null;
  return {
    id,
    date: new Date(draft.date),
    type: draft.type,
    categoryId: draft.type === 'Transfer' ? '' : draft.categoryId,
    accountId: draft.accountId,
    transferToId: draft.transferToId,
    amount: draft.type === 'Expense' ? -Math.abs(amt) : Math.abs(amt),
    note: draft.note || undefined,
  };
}

interface Props {
  open: boolean;
  onClose: () => void;
  onConfirm: (tx: Transaction) => void;
  expenseCategories: Category[];
  incomeCategories: Category[];
  allAccounts: Account[];
  defaultCategoryExpenseId?: string;
  defaultCategoryIncomeId?: string;
  defaultAccountId?: string;
  onNewCategory?: (name: string, type: 'Expense' | 'Income') => string;
  onNewAccount?: (name: string) => string;
}

export function AddTransactionForm({
  open,
  onClose,
  onConfirm,
  expenseCategories,
  incomeCategories,
  allAccounts,
  defaultCategoryExpenseId = '',
  defaultCategoryIncomeId = '',
  defaultAccountId = '',
  onNewCategory,
  onNewAccount,
}: Props) {
  const [mode, setMode] = useState<Mode>('Expense');
  const [draft, setDraft] = useState<Draft>(() =>
    emptyDraft('Expense', defaultCategoryExpenseId, defaultCategoryIncomeId, defaultAccountId)
  );
  const [error, setError] = useState('');
  const [amountFocused, setAmountFocused] = useState(false);

  const expenseOpts = expenseCategories.map((c) => ({ value: c.id, label: c.name }));
  const incomeOpts = incomeCategories.map((c) => ({ value: c.id, label: c.name }));
  const accountOpts = allAccounts.map((a) => ({ value: a.id, label: a.name }));

  useEffect(() => {
    if (open) {
      setMode('Expense');
      setDraft(emptyDraft('Expense', defaultCategoryExpenseId, defaultCategoryIncomeId, defaultAccountId));
      setError('');
    }
  }, [open]);

  function switchMode(m: Mode) {
    setMode(m);
    setError('');
    setDraft((d) => ({
      ...d,
      type: m,
      categoryId: m === 'Expense' ? defaultCategoryExpenseId : m === 'Income' ? defaultCategoryIncomeId : '',
      transferToId: '',
    }));
  }

  function patch(p: Partial<Draft>) {
    setDraft((d) => ({ ...d, ...p }));
    setError('');
  }

  function handleCategoryChange(v: string) {
    const allCats = [...expenseCategories, ...incomeCategories];
    if (allCats.some((c) => c.id === v)) {
      patch({ categoryId: v });
    } else if (onNewCategory) {
      const type = mode === 'Income' ? 'Income' : 'Expense';
      const id = onNewCategory(v, type);
      patch({ categoryId: id });
    }
  }

  function handleAccountChange(v: string) {
    if (allAccounts.some((a) => a.id === v)) {
      patch({ accountId: v });
    } else if (onNewAccount) {
      const id = onNewAccount(v);
      patch({ accountId: id });
    }
  }

  function handleTransferToChange(v: string) {
    if (allAccounts.some((a) => a.id === v)) {
      patch({ transferToId: v });
    } else if (onNewAccount) {
      const id = onNewAccount(v);
      patch({ transferToId: id });
    }
  }

  function handleConfirm() {
    const tx = draftToTx(draft, crypto.randomUUID());
    if (!tx) {
      setError('Vui lòng điền đầy đủ thông tin bắt buộc.');
      return;
    }
    onConfirm(tx);
  }

  if (!open) return null;

  const styles = MODE_STYLES[mode];
  const displayAmount = !amountFocused && draft.amountStr
    ? Number(draft.amountStr).toLocaleString('vi-VN')
    : draft.amountStr;
  const categoryOpts = mode === 'Expense' ? expenseOpts : mode === 'Income' ? incomeOpts : [];

  return (
    <div className={`bg-white dark:bg-slate-900 rounded-xl shadow-sm ${styles.accent}`}>
      <div className="p-5 flex flex-col gap-4">
        {/* Mode Switcher - Full Width */}
        <div className="flex bg-slate-100 dark:bg-slate-800 rounded-xl p-1 gap-1">
          {(['Expense', 'Transfer', 'Income'] as Mode[]).map((m) => (
            <button
              key={m}
              type="button"
              onClick={() => switchMode(m)}
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
            {/* Hero Amount */}
            <div className="bg-slate-50 dark:bg-slate-800/50 rounded-2xl p-5 flex flex-col items-center gap-1">
              <p className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider">Số tiền</p>
              <input
                type="text"
                inputMode="decimal"
                value={amountFocused ? draft.amountStr : displayAmount}
                onChange={(e) => {
                  const v = e.target.value.replace(/[^0-9.]/g, '');
                  patch({ amountStr: v });
                }}
                onFocus={() => setAmountFocused(true)}
                onBlur={() => setAmountFocused(false)}
                placeholder="0"
                autoFocus
                className={`w-full text-center text-5xl font-bold bg-transparent border-none outline-none placeholder:text-slate-200 dark:placeholder:text-slate-700 ${AMOUNT_COLOR[mode]} transition-colors`}
              />
              <span className="text-xs font-medium text-slate-400">₫ VND</span>
              {draft.amountStr && !isNaN(parseFloat(draft.amountStr)) && (
                <span className="text-xs text-slate-400">{formatVND(parseFloat(draft.amountStr))}</span>
              )}
            </div>

            {/* Secondary Fields (no date) */}
            <div className="space-y-3">
              {mode === 'Transfer' ? (
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
                    <Combobox value={draft.categoryId} onChange={handleCategoryChange} options={categoryOpts} placeholder="Coffee, Transport..." allowCustom />
                  </div>
                  <div>
                    <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Tài khoản</p>
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
              onChange={(date) => patch({ date })}
              accentColor={MODE_ACCENT[mode]}
            />
          </div>
        </div>

        {/* Note textarea */}
        <div className="w-full">
          <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Ghi chú</p>
          <textarea
            value={draft.note}
            onChange={(e) => patch({ note: e.target.value })}
            placeholder="Thêm ghi chú cho giao dịch này..."
            rows={2}
            className="w-full px-3 py-2 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition resize-none"
          />
        </div>

        {error && (
          <p className="text-xs text-rose-500 flex items-center gap-1">
            <span className="material-symbols-outlined text-sm">error</span>
            {error}
          </p>
        )}

        <div className="flex gap-2 justify-end">
          <button
            type="button"
            onClick={handleConfirm}
            className={`flex items-center gap-1.5 px-5 py-2 rounded-lg text-sm font-bold text-white transition-opacity hover:opacity-90 ${
              mode === 'Expense' ? 'bg-rose-500' : mode === 'Income' ? 'bg-emerald-500' : 'bg-blue-500'
            }`}
          >
            <span className="material-symbols-outlined text-sm">check</span> Lưu giao dịch
          </button>
          <button
            type="button"
            onClick={onClose}
            className="flex items-center gap-1.5 px-4 py-2 border border-slate-200 dark:border-slate-700 rounded-lg text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
          >
            <span className="material-symbols-outlined text-sm">close</span> Hủy
          </button>
        </div>
      </div>
    </div>
  );
}
