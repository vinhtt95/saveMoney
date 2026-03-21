import { useLocation } from 'react-router-dom';

export function Header() {
  const location = useLocation();
  
  const getTitle = () => {
    switch (location.pathname) {
      case '/': return 'Overview';
      case '/transactions': return 'Transactions';
      case '/analytics': return 'Analytics';
      case '/budget': return 'Budget';
      case '/settings': return 'Settings';
      default: return 'ExpensePro';
    }
  };

  return (
    <header className="h-16 border-b border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 flex items-center justify-between px-8 shrink-0 sticky top-0 z-50">
      <div className="flex items-center gap-4">
        <h2 className="text-lg font-bold text-slate-900 dark:text-white md:hidden">{getTitle()}</h2>
        {location.pathname === '/transactions' && (
          <div className="hidden md:flex items-center gap-2 bg-slate-100 dark:bg-slate-800 px-3 py-1.5 rounded-lg border border-slate-200 dark:border-slate-700">
            <span className="material-symbols-outlined text-sm">calendar_today</span>
            <span className="text-sm font-semibold italic">Oct 2023 - Dec 2023</span>
            <span className="material-symbols-outlined text-sm">expand_more</span>
          </div>
        )}
      </div>
      <div className="flex items-center gap-4">
        <button className="p-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-full">
          <span className="material-symbols-outlined">notifications</span>
        </button>
        <div className="size-8 rounded-full bg-primary/10 border border-primary/20 flex items-center justify-center overflow-hidden">
          <img alt="User Profile" className="size-full object-cover" src="https://lh3.googleusercontent.com/aida-public/AB6AXuAtAhXP-2QU0EHm7TR3Np-KF3pWxw7-4nTcKLc5Ss1fOyTmRMzFTMB1ebSfVYV_b_WJD30VWoUt4TjdpFcqDHM6hcDtEWkAZ2FcllxKlzqY42m-e_1xx35Dn5wj8Vwi1qj6N_dbgaYd_ll8Ln9xqNlHw6icjchxuvoPeUlsBvmtE1lvYMe1hWq5QpFEPxml1fJWGv3Idl8T52s9ukLuDacspemiJHrEd9GXkZzQJtiOA6B9_Cs_bb5bi228NZvB3kzwz4SKh2IydKw" />
        </div>
      </div>
    </header>
  );
}
