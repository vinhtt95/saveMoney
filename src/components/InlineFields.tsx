import React from 'react';
import { Account, Category, TransactionType } from '../types';
import { Combobox } from './Combobox';
import { toYYYYMMDD } from '../utils/formatters';

export const TRANSACTION_TYPES: TransactionType[] = ['Expense', 'Income', 'Transfer', 'Account'];

export interface Draft {
  date: string;
  type: TransactionType;
  categoryId: string;
  accountId: string;
  transferToId: string;
  amountStr: string;
}

export function emptyDraft(
  defaultCategoryExpenseId = '',
  defaultCategoryIncomeId = '',
  defaultAccountId = ''
): Draft {
  return {
    date: toYYYYMMDD(new Date()),
    type: 'Expense',
    categoryId: defaultCategoryExpenseId,
    accountId: defaultAccountId,
    transferToId: '',
    amountStr: '',
  };
}

export const fieldCls =
  'w-full px-2 py-1.5 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition';

export function InlineFields({
  draft,
  onChange,
  expenseCategories,
  incomeCategories,
  allAccounts,
  defaultCategoryExpenseId = '',
  defaultCategoryIncomeId = '',
  onNewCategory,
  onNewAccount,
}: {
  draft: Draft;
  onChange: (patch: Partial<Draft>) => void;
  expenseCategories: Category[];
  incomeCategories: Category[];
  allAccounts: Account[];
  defaultCategoryExpenseId?: string;
  defaultCategoryIncomeId?: string;
  onNewCategory?: (name: string, type: 'Expense' | 'Income') => string;
  onNewAccount?: (name: string) => string;
}) {
  const expenseOpts = expenseCategories.map((c) => ({ value: c.id, label: c.name }));
  const incomeOpts = incomeCategories.map((c) => ({ value: c.id, label: c.name }));
  const accountOpts = allAccounts.map((a) => ({ value: a.id, label: a.name }));

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

  const categoryOpts = draft.type === 'Expense' ? expenseOpts : draft.type === 'Income' ? incomeOpts : [];

  return (
    <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
      {/* Type */}
      <div className="col-span-2 md:col-span-3">
        <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Loại</p>
        <div className="flex gap-1.5 flex-wrap">
          {TRANSACTION_TYPES.map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => {
                const newCategoryId = t === 'Expense' ? defaultCategoryExpenseId : t === 'Income' ? defaultCategoryIncomeId : '';
                onChange({ type: t, transferToId: '', categoryId: newCategoryId });
              }}
              className={`px-3 py-1 rounded-lg text-xs font-semibold border transition-colors ${
                draft.type === t
                  ? 'bg-primary text-white border-primary'
                  : 'bg-white dark:bg-slate-800 border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300 hover:bg-slate-50'
              }`}
            >
              {t}
            </button>
          ))}
        </div>
      </div>

      {/* Date */}
      <div>
        <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Ngày</p>
        <input
          type="date"
          value={draft.date}
          onChange={(e) => onChange({ date: e.target.value })}
          className={fieldCls}
        />
      </div>

      {/* Category */}
      <div>
        <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Danh mục</p>
        <Combobox
          value={draft.categoryId}
          onChange={handleCategoryChange}
          options={categoryOpts}
          placeholder="Coffee, Transport..."
          allowCustom
        />
      </div>

      {/* Account */}
      <div>
        <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Tài khoản</p>
        <Combobox
          value={draft.accountId}
          onChange={handleAccountChange}
          options={accountOpts}
          placeholder="Tiền mặt..."
          allowCustom
        />
      </div>

      {/* Transfer To (only Transfer type) */}
      {draft.type === 'Transfer' && (
        <div>
          <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Chuyển đến</p>
          <Combobox
            value={draft.transferToId}
            onChange={handleTransferToChange}
            options={accountOpts}
            placeholder="Tài khoản đích..."
            allowCustom
          />
        </div>
      )}

      {/* Amount */}
      <div>
        <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">
          Số tiền (VND){draft.type === 'Expense' && <span className="ml-1 text-rose-400 normal-case font-normal">— tự ghi âm</span>}
        </p>
        <input
          type="number"
          min="1"
          step="any"
          value={draft.amountStr}
          onChange={(e) => onChange({ amountStr: e.target.value })}
          placeholder="50000"
          className={fieldCls}
        />
      </div>
    </div>
  );
}
