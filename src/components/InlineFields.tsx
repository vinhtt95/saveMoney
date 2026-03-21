import React from 'react';
import { TransactionType } from '../types';
import { Combobox } from './Combobox';

export const TRANSACTION_TYPES: TransactionType[] = ['Expense', 'Income', 'Transfer', 'Account'];

export interface Draft {
  date: string;
  type: TransactionType;
  category: string;
  account: string;
  transferTo: string;
  amountStr: string;
}

export function emptyDraft(defaultCategoryExpense = '', defaultCategoryIncome = '', defaultAccount = ''): Draft {
  return {
    date: new Date().toISOString().slice(0, 10),
    type: 'Expense',
    category: defaultCategoryExpense,
    account: defaultAccount,
    transferTo: '',
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
  defaultCategoryExpense = '',
  defaultCategoryIncome = '',
}: {
  draft: Draft;
  onChange: (patch: Partial<Draft>) => void;
  expenseCategories: string[];
  incomeCategories: string[];
  allAccounts: string[];
  defaultCategoryExpense?: string;
  defaultCategoryIncome?: string;
}) {
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
                const newCategory = t === 'Expense' ? defaultCategoryExpense : t === 'Income' ? defaultCategoryIncome : '';
                onChange({ type: t, transferTo: '', category: newCategory });
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
          value={draft.category}
          onChange={(v) => onChange({ category: v })}
          options={draft.type === 'Expense' ? expenseCategories : draft.type === 'Income' ? incomeCategories : []}
          placeholder="Coffee, Transport..."
          allowCustom
        />
      </div>

      {/* Account */}
      <div>
        <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Tài khoản</p>
        <Combobox
          value={draft.account}
          onChange={(v) => onChange({ account: v })}
          options={allAccounts}
          placeholder="Tiền mặt..."
          allowCustom
        />
      </div>

      {/* Transfer To (only Transfer type) */}
      {draft.type === 'Transfer' && (
        <div>
          <p className="text-[10px] uppercase font-bold text-slate-400 mb-1">Chuyển đến</p>
          <Combobox
            value={draft.transferTo}
            onChange={(v) => onChange({ transferTo: v })}
            options={allAccounts}
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
