import React, { useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import { getAccountNetTotals } from '../utils/analytics';
import { categoryName as resolveCategoryName, accountName as resolveAccountName } from '../utils/lookup';
import { formatVND, formatDate } from '../utils/formatters';
import { Account, Transaction } from '../types';

const fieldCls =
  'px-2 py-1.5 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition';

const ACCOUNT_COLORS = [
  { bg: 'bg-blue-100 dark:bg-blue-900/30', text: 'text-blue-600' },
  { bg: 'bg-violet-100 dark:bg-violet-900/30', text: 'text-violet-600' },
  { bg: 'bg-emerald-100 dark:bg-emerald-900/30', text: 'text-emerald-600' },
  { bg: 'bg-amber-100 dark:bg-amber-900/30', text: 'text-amber-600' },
  { bg: 'bg-rose-100 dark:bg-rose-900/30', text: 'text-rose-600' },
  { bg: 'bg-cyan-100 dark:bg-cyan-900/30', text: 'text-cyan-600' },
  { bg: 'bg-indigo-100 dark:bg-indigo-900/30', text: 'text-indigo-600' },
  { bg: 'bg-pink-100 dark:bg-pink-900/30', text: 'text-pink-600' },
];

function getAccountColor(index: number) {
  return ACCOUNT_COLORS[index % ACCOUNT_COLORS.length];
}

function typeBadge(type: Transaction['type']) {
  switch (type) {
    case 'Expense':
      return <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-rose-100 dark:bg-rose-900/30 text-rose-600">Chi tiêu</span>;
    case 'Income':
      return <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600">Thu nhập</span>;
    case 'Transfer':
      return <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-blue-100 dark:bg-blue-900/30 text-blue-600">Chuyển khoản</span>;
    case 'Account':
      return <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300">Số dư</span>;
  }
}

interface AccountTxListProps {
  account: Account;
  transactions: Transaction[];
  allCategories: ReturnType<typeof useApp>['state']['categories'];
  allAccounts: ReturnType<typeof useApp>['state']['accounts'];
}

function AccountTxList({ account, transactions, allCategories, allAccounts }: AccountTxListProps) {
  const accountTxs = useMemo(() => {
    return transactions
      .filter((t) => t.accountId === account.id || t.transferToId === account.id)
      .sort((a, b) => b.date.getTime() - a.date.getTime())
      .slice(0, 50);
  }, [transactions, account.id]);

  const total = transactions.filter((t) => t.accountId === account.id || t.transferToId === account.id).length;

  if (accountTxs.length === 0) {
    return (
      <div className="px-5 py-8 text-center text-slate-400 text-sm">
        Chưa có giao dịch nào trên tài khoản này.
      </div>
    );
  }

  const groups: { dateKey: string; date: Date; txs: Transaction[] }[] = [];
  const map = new Map<string, (typeof groups)[0]>();
  for (const tx of accountTxs) {
    const key = tx.date.toISOString().slice(0, 10);
    if (!map.has(key)) {
      const group = { dateKey: key, date: tx.date, txs: [] as Transaction[] };
      map.set(key, group);
      groups.push(group);
    }
    map.get(key)!.txs.push(tx);
  }

  return (
    <div className="border-t border-slate-100 dark:border-slate-800">
      {groups.map((group) => (
        <React.Fragment key={group.dateKey}>
          <div className="px-5 py-2 bg-slate-50 dark:bg-slate-800/70 border-t border-slate-100 dark:border-slate-700">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
              {formatDate(group.date)}
            </span>
          </div>
          {group.txs.map((tx) => {
            const isIncoming =
              tx.type === 'Income' ||
              tx.type === 'Account' ||
              (tx.type === 'Transfer' && tx.transferToId === account.id);
            const amountColor = isIncoming ? 'text-emerald-600' : 'text-rose-600';
            const amountSign = isIncoming ? '+' : '-';
            const catName = resolveCategoryName(allCategories, tx.categoryId);
            const fromAccName = resolveAccountName(allAccounts, tx.accountId);
            const toAccName = tx.transferToId ? resolveAccountName(allAccounts, tx.transferToId) : '';
            return (
              <div
                key={tx.id}
                className="flex items-center gap-3 px-5 py-3 border-t border-slate-50 dark:border-slate-800/50 hover:bg-slate-50/50 dark:hover:bg-slate-800/30 transition-colors"
              >
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    {typeBadge(tx.type)}
                    <span className="text-sm text-slate-700 dark:text-slate-200 font-medium truncate">
                      {tx.type === 'Transfer' ? '' : catName}
                    </span>
                    {tx.type === 'Transfer' && (
                      <span className="text-xs text-slate-400">
                        {tx.accountId === account.id ? `→ ${toAccName}` : `← ${fromAccName}`}
                      </span>
                    )}
                  </div>
                  {tx.accountId !== account.id && tx.type !== 'Transfer' && (
                    <p className="text-xs text-slate-400 mt-0.5">{fromAccName}</p>
                  )}
                </div>
                <span className={`text-sm font-bold tabular-nums ${amountColor}`}>
                  {amountSign}{formatVND(Math.abs(tx.amount))}
                </span>
              </div>
            );
          })}
        </React.Fragment>
      ))}
      {total > 50 && (
        <div className="px-5 py-3 border-t border-slate-100 dark:border-slate-800 text-center">
          <Link to={`/transactions`} className="text-xs text-primary hover:underline font-medium">
            Xem tất cả {total} giao dịch →
          </Link>
        </div>
      )}
    </div>
  );
}

export function Accounts() {
  const { state, dispatch } = useApp();

  // expandedAccount holds account ID
  const [expandedAccountId, setExpandedAccountId] = useState<string | null>(null);
  // editingName/Balance hold account ID
  const [editingNameId, setEditingNameId] = useState<string | null>(null);
  const [editingBalanceId, setEditingBalanceId] = useState<string | null>(null);
  const [nameInput, setNameInput] = useState('');
  const [balanceInput, setBalanceInput] = useState('');
  const [isAdding, setIsAdding] = useState(false);
  const [newAccountName, setNewAccountName] = useState('');
  const [addError, setAddError] = useState('');

  const netTotals = useMemo(() => getAccountNetTotals(state.transactions), [state.transactions]);

  const accountData = useMemo(() => {
    return state.accounts
      .map((acc, idx) => {
        const initial = state.accountBalances[acc.id] ?? 0;
        const net = netTotals[acc.id] ?? 0;
        const balance = initial + net;
        const txCount = state.transactions.filter(
          (t) => t.accountId === acc.id || t.transferToId === acc.id
        ).length;
        return { id: acc.id, name: acc.name, balance, txCount, initial, colorIdx: idx };
      })
      .sort((a, b) => b.balance - a.balance);
  }, [state.accounts, state.accountBalances, netTotals, state.transactions]);

  const totalBalance = useMemo(
    () => accountData.reduce((sum, a) => sum + a.balance, 0),
    [accountData]
  );

  function handleAddAccount() {
    const name = newAccountName.trim();
    if (!name) {
      setAddError('Tên tài khoản không được trống');
      return;
    }
    if (state.accounts.some((a) => a.name === name)) {
      setAddError('Tài khoản đã tồn tại');
      return;
    }
    const account: Account = { id: crypto.randomUUID(), name };
    dispatch({ type: 'SET_ACCOUNTS', accounts: [...state.accounts, account].sort((a, b) => a.name.localeCompare(b.name)) });
    setIsAdding(false);
    setNewAccountName('');
    setAddError('');
  }

  function handleRename(accId: string) {
    const newName = nameInput.trim();
    const acc = state.accounts.find((a) => a.id === accId);
    if (!newName || !acc || newName === acc.name) {
      setEditingNameId(null);
      return;
    }
    if (state.accounts.some((a) => a.name === newName && a.id !== accId)) {
      setEditingNameId(null);
      return;
    }
    dispatch({ type: 'RENAME_ACCOUNT', id: accId, newName });
    setEditingNameId(null);
  }

  function handleDelete(accId: string) {
    const acc = state.accounts.find((a) => a.id === accId);
    if (!acc) return;
    const txCount = state.transactions.filter(
      (t) => t.accountId === accId || t.transferToId === accId
    ).length;
    if (txCount > 0) {
      const confirmed = window.confirm(
        `Tài khoản "${acc.name}" có ${txCount} giao dịch. Xóa tài khoản sẽ không xóa giao dịch, chỉ xóa khỏi danh sách tài khoản. Tiếp tục?`
      );
      if (!confirmed) return;
    }
    const newBalances = { ...state.accountBalances };
    delete newBalances[accId];
    dispatch({ type: 'SET_ACCOUNTS', accounts: state.accounts.filter((a) => a.id !== accId) });
    dispatch({ type: 'SET_ACCOUNT_BALANCES', accountBalances: newBalances });
    if (expandedAccountId === accId) setExpandedAccountId(null);
  }

  function handleSaveBalance(accId: string) {
    const val = parseFloat(balanceInput);
    const newBalances = { ...state.accountBalances, [accId]: isNaN(val) ? 0 : val };
    dispatch({ type: 'SET_ACCOUNT_BALANCES', accountBalances: newBalances });
    setEditingBalanceId(null);
  }

  function startEditName(accId: string, currentName: string) {
    setEditingNameId(accId);
    setNameInput(currentName);
    setEditingBalanceId(null);
  }

  function startEditBalance(accId: string, initial: number) {
    setEditingBalanceId(accId);
    setBalanceInput(initial === 0 ? '' : String(initial));
    setEditingNameId(null);
  }

  const balanceColor = (b: number) =>
    b > 0 ? 'text-emerald-600' : b < 0 ? 'text-rose-600' : 'text-slate-400';

  return (
    <div className="p-6 max-w-3xl mx-auto space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Tài khoản</h1>
          <p className="text-sm text-slate-500 mt-0.5">Quản lý tài khoản và số dư</p>
        </div>
        <button
          onClick={() => { setIsAdding(true); setNewAccountName(''); setAddError(''); }}
          className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-xl text-sm font-semibold hover:opacity-90 transition-opacity shadow-sm"
        >
          <span className="material-symbols-outlined text-sm">add</span>
          Thêm tài khoản
        </button>
      </div>

      <div className="grid grid-cols-2 gap-4">
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5 shadow-sm">
          <p className="text-xs font-bold uppercase tracking-widest text-slate-400 mb-1">Tổng số dư</p>
          <p className={`text-2xl font-bold ${balanceColor(totalBalance)}`}>{formatVND(totalBalance)}</p>
        </div>
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5 shadow-sm">
          <p className="text-xs font-bold uppercase tracking-widest text-slate-400 mb-1">Số tài khoản</p>
          <p className="text-2xl font-bold text-slate-900 dark:text-white">{state.accounts.length}</p>
        </div>
      </div>

      {isAdding && (
        <div className="bg-primary/5 dark:bg-primary/10 rounded-xl border border-primary/30 p-5">
          <p className="text-xs font-bold uppercase tracking-widest text-primary mb-3">Tài khoản mới</p>
          <div className="flex gap-3 items-start">
            <input
              autoFocus
              className={`flex-1 ${fieldCls}`}
              placeholder="Tên tài khoản (vd: Tiền mặt, MB Bank...)"
              value={newAccountName}
              onChange={(e) => setNewAccountName(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') handleAddAccount();
                if (e.key === 'Escape') { setIsAdding(false); setAddError(''); }
              }}
            />
            <button onClick={handleAddAccount} className="flex items-center gap-1.5 px-4 py-1.5 bg-primary text-white rounded-lg text-sm font-semibold hover:opacity-90 transition-opacity">
              <span className="material-symbols-outlined text-sm">check</span> Lưu
            </button>
            <button onClick={() => { setIsAdding(false); setAddError(''); }} className="flex items-center gap-1.5 px-3 py-1.5 border border-slate-200 dark:border-slate-700 rounded-lg text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">
              <span className="material-symbols-outlined text-sm">close</span>
            </button>
          </div>
          {addError && <p className="text-xs text-rose-500 mt-2">{addError}</p>}
        </div>
      )}

      {accountData.length === 0 ? (
        <div className="text-center py-16 text-slate-400 bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800">
          <span className="material-symbols-outlined text-5xl mb-3 block">account_balance</span>
          <p className="text-lg font-medium">Chưa có tài khoản nào</p>
          <p className="text-sm mt-1">Thêm tài khoản đầu tiên bằng nút bên trên</p>
        </div>
      ) : (
        <div className="space-y-3">
          {accountData.map((acc) => {
            const color = getAccountColor(acc.colorIdx);
            const isExpanded = expandedAccountId === acc.id;
            const isEditingThisName = editingNameId === acc.id;
            const isEditingThisBalance = editingBalanceId === acc.id;
            const accObj = state.accounts.find((a) => a.id === acc.id)!;

            return (
              <div key={acc.id} className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
                <div className="flex items-center gap-4 p-5">
                  <div
                    className={`size-10 ${color.bg} rounded-lg flex items-center justify-center shrink-0 cursor-pointer`}
                    onClick={() => setExpandedAccountId(isExpanded ? null : acc.id)}
                  >
                    <span className={`material-symbols-outlined ${color.text}`}>account_balance</span>
                  </div>

                  <div
                    className="flex-1 min-w-0 cursor-pointer"
                    onClick={() => !isEditingThisName && !isEditingThisBalance && setExpandedAccountId(isExpanded ? null : acc.id)}
                  >
                    {isEditingThisName ? (
                      <input
                        autoFocus
                        className={`${fieldCls} w-full max-w-xs`}
                        value={nameInput}
                        onChange={(e) => setNameInput(e.target.value)}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') handleRename(acc.id);
                          if (e.key === 'Escape') setEditingNameId(null);
                        }}
                        onBlur={() => handleRename(acc.id)}
                        onClick={(e) => e.stopPropagation()}
                      />
                    ) : (
                      <p className="font-semibold text-slate-800 dark:text-slate-100 truncate">{acc.name}</p>
                    )}
                    <p className="text-xs text-slate-400 mt-0.5">{acc.txCount} giao dịch</p>
                  </div>

                  <div className="text-right shrink-0 mr-2">
                    {isEditingThisBalance ? (
                      <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
                        <div>
                          <input
                            autoFocus
                            type="number"
                            className={`${fieldCls} w-36 text-right`}
                            placeholder="Số dư ban đầu"
                            value={balanceInput}
                            onChange={(e) => setBalanceInput(e.target.value)}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter') handleSaveBalance(acc.id);
                              if (e.key === 'Escape') setEditingBalanceId(null);
                            }}
                            onBlur={() => handleSaveBalance(acc.id)}
                          />
                          <p className="text-xs text-slate-400 mt-0.5 text-right">Số dư ban đầu</p>
                        </div>
                        <button onClick={() => handleSaveBalance(acc.id)} className="p-1 text-emerald-600 hover:bg-emerald-50 dark:hover:bg-emerald-900/30 rounded-lg transition-colors">
                          <span className="material-symbols-outlined text-sm">check</span>
                        </button>
                        <button onClick={() => setEditingBalanceId(null)} className="p-1 text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors">
                          <span className="material-symbols-outlined text-sm">close</span>
                        </button>
                      </div>
                    ) : (
                      <>
                        <p className={`text-lg font-bold tabular-nums ${balanceColor(acc.balance)}`}>
                          {formatVND(acc.balance)}
                        </p>
                        {acc.initial !== 0 && (
                          <p className="text-xs text-slate-400">Ban đầu: {formatVND(acc.initial)}</p>
                        )}
                      </>
                    )}
                  </div>

                  {!isEditingThisName && !isEditingThisBalance && (
                    <div className="flex items-center gap-1 shrink-0">
                      <button title="Đổi tên" onClick={(e) => { e.stopPropagation(); startEditName(acc.id, acc.name); }} className="p-1.5 text-slate-400 hover:text-primary hover:bg-primary/10 rounded-lg transition-colors">
                        <span className="material-symbols-outlined text-sm">edit</span>
                      </button>
                      <button title="Chỉnh số dư ban đầu" onClick={(e) => { e.stopPropagation(); startEditBalance(acc.id, acc.initial); }} className="p-1.5 text-slate-400 hover:text-amber-500 hover:bg-amber-50 dark:hover:bg-amber-900/20 rounded-lg transition-colors">
                        <span className="material-symbols-outlined text-sm">account_balance_wallet</span>
                      </button>
                      <button title="Xóa tài khoản" onClick={(e) => { e.stopPropagation(); handleDelete(acc.id); }} className="p-1.5 text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-900/20 rounded-lg transition-colors">
                        <span className="material-symbols-outlined text-sm">delete</span>
                      </button>
                      <button title={isExpanded ? 'Thu gọn' : 'Xem giao dịch'} onClick={() => setExpandedAccountId(isExpanded ? null : acc.id)} className="p-1.5 text-slate-400 hover:text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors">
                        <span className="material-symbols-outlined text-sm">{isExpanded ? 'expand_less' : 'expand_more'}</span>
                      </button>
                    </div>
                  )}
                </div>

                {isExpanded && (
                  <AccountTxList
                    account={accObj}
                    transactions={state.transactions}
                    allCategories={state.categories}
                    allAccounts={state.accounts}
                  />
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
