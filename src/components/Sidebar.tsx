import { useMemo } from 'react';
import { NavLink } from 'react-router-dom';
import { twMerge } from 'tailwind-merge';
import { useApp } from '../context/AppContext';
import { getAccountNetTotals } from '../utils/analytics';
import { toYYYYMMDD, formatVNDShort } from '../utils/formatters';
import type { Budget } from '../types';

function formatNum(amount: number): string {
  return Math.abs(Math.round(amount)).toLocaleString('vi-VN');
}

function loadBudgets(): Budget[] {
  try {
    const raw = localStorage.getItem('savemoney_budgets');
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

const navItems = [
  { name: 'Dashboard', icon: 'dashboard', path: '/' },
  { name: 'Transactions', icon: 'receipt_long', path: '/transactions' },
  { name: 'Analytics', icon: 'insights', path: '/analytics' },
  { name: 'Budgets', icon: 'savings', path: '/budget' },
  { name: 'Tài sản', icon: 'diamond', path: '/wealth' },
  { name: 'Vàng', icon: 'currency_exchange', path: '/gold' },
  { name: 'Accounts', icon: 'account_balance', path: '/accounts' },
  { name: 'Categories', icon: 'category', path: '/categories' },
  { name: 'Settings', icon: 'settings', path: '/settings' },
];

function SidebarAccountCards() {
  const { state } = useApp();
  const netTotals = useMemo(() => getAccountNetTotals(state.transactions), [state.transactions]);

  const accountCards = useMemo(() => {
    return state.accounts.map((acc) => {
      const initial = state.accountBalances[acc.id] ?? 0;
      const net = netTotals[acc.id] ?? 0;
      const balance = initial + net;
      let spending = 0;
      let income = 0;
      state.transactions.forEach((t) => {
        if (t.accountId === acc.id) {
          if (t.type === 'Expense') spending += Math.abs(t.amount);
          else if (t.type === 'Income') income += t.amount;
        }
      });
      return { account: acc, balance, spending, income };
    }).filter((a) => a.balance !== 0 || a.spending !== 0 || a.income !== 0);
  }, [state.accounts, state.accountBalances, netTotals, state.transactions]);

  if (accountCards.length === 0) return null;

  return (
    <div className="px-4 pb-4">
      <p className="px-3 text-[10px] font-bold uppercase tracking-widest text-slate-400 mb-2">Accounts</p>
      <div className="space-y-2">
        {accountCards.map((acc) => (
          <div key={acc.account.id} className="bg-slate-50 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden">
            <div className={`px-3 py-3 ${acc.balance >= 0 ? 'bg-emerald-50 dark:bg-emerald-900/20' : 'bg-rose-50 dark:bg-rose-900/20'}`}>
              <div className="flex items-center gap-1.5 mb-1">
                <span className="material-symbols-outlined text-slate-400 text-base">account_balance_wallet</span>
                <span className="text-sm font-semibold text-slate-500 dark:text-slate-400 truncate flex-1">{acc.account.name}</span>
                <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-slate-200 dark:bg-slate-700 text-slate-500 dark:text-slate-400 shrink-0">VND</span>
              </div>
              <p className={`text-lg font-bold text-right ${acc.balance >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600 dark:text-rose-400'}`}>
                {acc.balance >= 0 ? '+' : ''}{formatNum(acc.balance)}
              </p>
            </div>
            <div className="px-3 py-2 flex justify-between text-xs text-slate-400">
              <span className="flex items-center gap-1">
                <span className="size-1.5 rounded-full bg-rose-400 inline-block"></span>
                {acc.spending > 0 ? `-${formatNum(acc.spending)}` : '—'}
              </span>
              <span className="flex items-center gap-1">
                <span className="size-1.5 rounded-full bg-emerald-400 inline-block"></span>
                {acc.income > 0 ? `+${formatNum(acc.income)}` : '—'}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function SidebarBudgetCards() {
  const { state } = useApp();
  const budgets = useMemo(() => loadBudgets(), []);

  const budgetStats = useMemo(() => {
    return budgets.map((budget) => {
      const spent = state.transactions
        .filter(
          (t) =>
            t.type === 'Expense' &&
            budget.categoryIds.includes(t.categoryId) &&
            toYYYYMMDD(t.date) >= budget.dateStart &&
            toYYYYMMDD(t.date) <= budget.dateEnd
        )
        .reduce((sum, t) => sum + Math.abs(t.amount), 0);
      const pct = budget.limit > 0 ? Math.min((spent / budget.limit) * 100, 100) : 0;
      return { budget, spent, pct };
    });
  }, [budgets, state.transactions]);

  if (budgetStats.length === 0) return null;

  return (
    <div className="px-4 pb-4">
      <p className="px-3 text-[10px] font-bold uppercase tracking-widest text-slate-400 mb-2">Budgets</p>
      <div className="space-y-2">
        {budgetStats.map(({ budget, spent, pct }) => {
          const isOver = pct >= 100;
          const isCritical = pct >= 85;
          const barColor = isOver ? 'bg-rose-500' : isCritical ? 'bg-amber-500' : 'bg-emerald-500';
          const textColor = isOver ? 'text-rose-600 dark:text-rose-400' : isCritical ? 'text-amber-600 dark:text-amber-400' : 'text-emerald-600 dark:text-emerald-400';

          return (
            <NavLink
              key={budget.id}
              to="/budget"
              className="block bg-slate-50 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden hover:border-primary/40 transition-colors"
            >
              <div className="px-3 py-2.5">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs font-semibold text-slate-600 dark:text-slate-300 truncate flex-1">{budget.name}</span>
                </div>
                <div className="w-full bg-slate-200 dark:bg-slate-700 h-1.5 rounded-full overflow-hidden mb-1.5">
                  <div className={`h-full rounded-full transition-all ${barColor}`} style={{ width: `${pct}%` }} />
                </div>
                <div className="flex items-center justify-between text-[10px]">
                  <span className="text-slate-400">Còn lại</span>
                  <span className={`text-lg font-bold ${textColor}`}>
                    {(budget.limit - spent).toLocaleString('vi-VN')}
                  </span>
                </div>
              </div>
            </NavLink>
          );
        })}
      </div>
    </div>
  );
}

export function Sidebar() {
  return (
    <aside className="w-64 border-r border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 hidden md:flex flex-col shrink-0">
      <div className="p-6 flex items-center gap-3">
        <div className="size-8 bg-primary rounded-lg flex items-center justify-center text-white">
          <span className="material-symbols-outlined">account_balance_wallet</span>
        </div>
        <h1 className="font-bold text-xl tracking-tight text-primary dark:text-slate-100">ExpensePro</h1>
      </div>
      <nav className="flex-1 px-4 space-y-1">
        <p className="px-3 text-[10px] font-bold uppercase tracking-widest text-slate-400 mb-2 mt-4">Menu</p>
        {navItems.map((item) => (
          <NavLink
            key={item.name}
            to={item.path}
            className={({ isActive }) =>
              twMerge(
                'flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors',
                isActive
                  ? 'bg-primary text-white shadow-md'
                  : 'text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800'
              )
            }
          >
            <span className="material-symbols-outlined text-xl">{item.icon}</span>
            <span className="text-sm font-medium">{item.name}</span>
          </NavLink>
        ))}
      </nav>
      <SidebarBudgetCards />
      <SidebarAccountCards />
    </aside>
  );
}
