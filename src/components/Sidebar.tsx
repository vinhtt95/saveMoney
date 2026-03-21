import { NavLink } from 'react-router-dom';
import { clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

const navItems = [
  { name: 'Dashboard', icon: 'dashboard', path: '/' },
  { name: 'Transactions', icon: 'receipt_long', path: '/transactions' },
  { name: 'Analytics', icon: 'insights', path: '/analytics' },
  { name: 'Budget', icon: 'account_balance_wallet', path: '/budget' },
  { name: 'Settings', icon: 'settings', path: '/settings' },
];

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
      <div className="p-4 mt-auto">
        <div className="p-4 rounded-xl bg-primary/5 dark:bg-primary/20 border border-primary/10">
          <div className="flex items-center gap-2 mb-1">
            <span className="material-symbols-outlined text-primary text-sm">verified</span>
            <p className="text-xs font-bold text-primary dark:text-slate-200 uppercase tracking-wider">Pro Plan</p>
          </div>
          <p className="text-[10px] text-slate-500 dark:text-slate-400 mb-3">Unlock advanced AI spending insights.</p>
          <button className="w-full py-2 bg-primary text-white text-xs font-bold rounded-lg">Upgrade Now</button>
        </div>
      </div>
    </aside>
  );
}
