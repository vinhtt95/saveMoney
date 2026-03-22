import React, { useState, useRef, useEffect } from 'react';
import { Account, Category } from '../types';
import { useApp } from '../context/AppContext';
import { parseCSV, exportCSV } from '../utils/csvParser';
import { exportDatabase, readBackupFile } from '../utils/backup';
import { categoryName, accountName } from '../utils/lookup';
import { formatVND, formatDate } from '../utils/formatters';

type Tab = 'data' | 'lists' | 'display' | 'about';

interface ParsedPreviewRow {
  date: Date;
  type: string;
  categoryId: string;
  accountId: string;
  amount: number;
}

export function Settings() {
  const { state, dispatch } = useApp();
  const [activeTab, setActiveTab] = useState<Tab>('data');
  const [preview, setPreview] = useState<ParsedPreviewRow[]>([]);
  const [pendingTxs, setPendingTxs] = useState<ReturnType<typeof parseCSV>['transactions']>([]);
  const [pendingNewCategories, setPendingNewCategories] = useState<Category[]>([]);
  const [pendingNewAccounts, setPendingNewAccounts] = useState<Account[]>([]);
  const [importMsg, setImportMsg] = useState('');
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [newCategory, setNewCategory] = useState('');
  const [newAccount, setNewAccount] = useState('');
  const [defaultCategoryExpenseId, setDefaultCategoryExpenseId] = useState(state.defaultCategoryExpenseId);
  const [defaultCategoryIncomeId, setDefaultCategoryIncomeId] = useState(state.defaultCategoryIncomeId);
  const [defaultAccountId, setDefaultAccountId] = useState(state.defaultAccountId);

  useEffect(() => { setDefaultCategoryExpenseId(state.defaultCategoryExpenseId); }, [state.defaultCategoryExpenseId]);
  useEffect(() => { setDefaultCategoryIncomeId(state.defaultCategoryIncomeId); }, [state.defaultCategoryIncomeId]);
  useEffect(() => { setDefaultAccountId(state.defaultAccountId); }, [state.defaultAccountId]);

  // All categories merged (working set for preview parsing)
  const allCategoriesRef = React.useRef(state.categories);
  allCategoriesRef.current = state.categories;
  const allAccountsRef = React.useRef(state.accounts);
  allAccountsRef.current = state.accounts;

  function handleFile(file: File) {
    if (!file.name.endsWith('.csv')) {
      setImportMsg('Please select a CSV file.');
      return;
    }
    const reader = new FileReader();
    reader.onload = (e) => {
      const text = e.target?.result as string;
      const result = parseCSV(text, allCategoriesRef.current, allAccountsRef.current);
      setPendingTxs(result.transactions);
      setPendingNewCategories(result.newCategories);
      setPendingNewAccounts(result.newAccounts);
      setPreview(result.transactions.slice(-5));
      setImportMsg(`Parsed ${result.transactions.length} transactions. Review preview below, then click Import.`);
    };
    reader.readAsText(file);
  }

  function handleDrop(e: React.DragEvent) {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files[0];
    if (file) handleFile(file);
  }

  function handleFileInput(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (file) handleFile(file);
  }

  function handleImport() {
    if (pendingTxs.length === 0) return;
    dispatch({ type: 'IMPORT', transactions: pendingTxs, newCategories: pendingNewCategories, newAccounts: pendingNewAccounts });
    setImportMsg(`Successfully imported ${pendingTxs.length} transactions!`);
    setPendingTxs([]);
    setPendingNewCategories([]);
    setPendingNewAccounts([]);
    setPreview([]);
  }

  function handleExportCSV() {
    const csv = exportCSV(state.transactions, state.categories, state.accounts);
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `savemoney-export-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  function handleClear() {
    if (confirm('This will permanently delete all transaction data. Are you sure?')) {
      dispatch({ type: 'CLEAR' });
      setImportMsg('');
      setPendingTxs([]);
      setPreview([]);
    }
  }

  const [pendingBackup, setPendingBackup] = useState<Awaited<ReturnType<typeof readBackupFile>> | null>(null);
  const [backupMsg, setBackupMsg] = useState('');
  const [isBackupDragging, setIsBackupDragging] = useState(false);
  const backupInputRef = useRef<HTMLInputElement>(null);

  async function handleBackupFile(file: File) {
    try {
      const backup = await readBackupFile(file);
      setPendingBackup(backup);
      setBackupMsg(`Đọc thành công: ${backup.transactions.length} giao dịch, ${backup.budgets.length} ngân sách, ${backup.categories.length} danh mục, ${backup.accounts.length} tài khoản.`);
    } catch (err) {
      setBackupMsg((err as Error).message);
    }
  }

  function handleRestoreBackup() {
    if (!pendingBackup) return;
    if (!confirm('Thao tác này sẽ GHI ĐÈ toàn bộ dữ liệu hiện tại (giao dịch, danh mục, tài khoản, ngân sách). Tiếp tục?')) return;
    const { budgets, ...rest } = pendingBackup;
    dispatch({ type: 'RESTORE_BACKUP', backup: rest });
    localStorage.setItem('savemoney_budgets', JSON.stringify(budgets));
    setPendingBackup(null);
    setBackupMsg(`Khôi phục thành công! ${rest.transactions.length} giao dịch, ${budgets.length} ngân sách đã được nạp.`);
  }

  const [newCategoryType, setNewCategoryType] = useState<'Expense' | 'Income'>('Expense');

  function addCategory() {
    const val = newCategory.trim();
    if (!val) return;
    const category: Category = { id: crypto.randomUUID(), name: val, type: newCategoryType };
    dispatch({ type: 'ADD_CATEGORY', category });
    setNewCategory('');
  }

  function removeCategory(id: string) {
    dispatch({ type: 'DELETE_CATEGORY', id });
  }

  function addAccount() {
    const val = newAccount.trim();
    if (!val || state.accounts.some((a) => a.name === val)) return;
    const account: Account = { id: crypto.randomUUID(), name: val };
    dispatch({ type: 'SET_ACCOUNTS', accounts: [...state.accounts, account].sort((a, b) => a.name.localeCompare(b.name)) });
    setNewAccount('');
  }

  function removeAccount(id: string) {
    dispatch({ type: 'SET_ACCOUNTS', accounts: state.accounts.filter((a) => a.id !== id) });
  }

  const expenseCategories = state.categories.filter((c) => c.type === 'Expense');
  const incomeCategories = state.categories.filter((c) => c.type === 'Income');

  // For preview: build lookup maps including pending new categories/accounts
  const previewCatMap = new Map([...state.categories, ...pendingNewCategories].map((c) => [c.id, c.name]));
  const previewAccMap = new Map([...state.accounts, ...pendingNewAccounts].map((a) => [a.id, a.name]));

  const tabs: { id: Tab; label: string }[] = [
    { id: 'data', label: 'Data Management' },
    { id: 'lists', label: 'Danh mục & Tài khoản' },
    { id: 'display', label: 'Display & Theme' },
    { id: 'about', label: 'About App' },
  ];

  return (
    <div className="space-y-8">
      <div className="flex border-b border-slate-200 dark:border-slate-800 gap-8">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex flex-col items-center justify-center border-b-2 pb-3 pt-2 text-sm font-medium tracking-tight transition-colors ${
              activeTab === tab.id
                ? 'border-primary text-primary font-bold'
                : 'border-transparent text-slate-500 hover:text-slate-700'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {activeTab === 'data' && (
        <div className="max-w-5xl space-y-8">
          <section className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden">
            <div className="p-6 border-b border-slate-100 dark:border-slate-800">
              <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">Import Transactions</h3>
              <p className="text-sm text-slate-500">Upload your Savey export CSV file to populate your dashboard.</p>
            </div>
            <div className="p-6">
              <div
                className={`flex flex-col items-center gap-4 rounded-xl border-2 border-dashed px-6 py-10 transition-colors ${
                  isDragging
                    ? 'border-primary bg-primary/5'
                    : 'border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50'
                }`}
                onDragOver={(e) => { e.preventDefault(); setIsDragging(true); }}
                onDragLeave={() => setIsDragging(false)}
                onDrop={handleDrop}
              >
                <div className="size-12 bg-primary/10 text-primary rounded-full flex items-center justify-center">
                  <span className="material-symbols-outlined">upload_file</span>
                </div>
                <div className="text-center">
                  <p className="text-sm font-bold text-slate-900 dark:text-slate-100">
                    {isDragging ? 'Drop your file here' : 'Click to upload or drag and drop'}
                  </p>
                  <p className="text-xs text-slate-500 mt-1">CSV from Savey app (max. 10MB)</p>
                </div>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept=".csv"
                  className="hidden"
                  onChange={handleFileInput}
                />
                <button
                  onClick={() => fileInputRef.current?.click()}
                  className="mt-2 flex items-center justify-center rounded-lg h-10 px-6 bg-primary text-white text-sm font-bold transition-opacity hover:opacity-90"
                >
                  Select File
                </button>
              </div>

              {importMsg && (
                <p className={`mt-4 text-sm font-medium ${importMsg.includes('Successfully') ? 'text-emerald-600' : 'text-slate-600 dark:text-slate-400'}`}>
                  {importMsg}
                </p>
              )}

              {preview.length > 0 && (
                <div className="mt-6">
                  <div className="flex items-center justify-between mb-4">
                    <h4 className="text-xs font-bold uppercase tracking-wider text-slate-400">Preview (Last 5 Rows)</h4>
                    <button
                      onClick={handleImport}
                      className="px-4 py-2 bg-primary text-white rounded-lg text-sm font-bold hover:opacity-90 transition-opacity flex items-center gap-2"
                    >
                      <span className="material-symbols-outlined text-sm">check_circle</span>
                      Import {pendingTxs.length} transactions
                    </button>
                  </div>
                  <div className="overflow-x-auto border border-slate-200 dark:border-slate-800 rounded-lg">
                    <table className="w-full text-left border-collapse">
                      <thead>
                        <tr className="bg-slate-50 dark:bg-slate-800/50 text-slate-500 text-xs font-bold uppercase tracking-wider">
                          <th className="px-4 py-3 border-b border-slate-200 dark:border-slate-800">Date</th>
                          <th className="px-4 py-3 border-b border-slate-200 dark:border-slate-800">Type</th>
                          <th className="px-4 py-3 border-b border-slate-200 dark:border-slate-800">Category</th>
                          <th className="px-4 py-3 border-b border-slate-200 dark:border-slate-800">Account</th>
                          <th className="px-4 py-3 border-b border-slate-200 dark:border-slate-800 text-right">Amount</th>
                        </tr>
                      </thead>
                      <tbody className="text-sm divide-y divide-slate-100 dark:divide-slate-800">
                        {preview.map((row, i) => (
                          <tr key={i}>
                            <td className="px-4 py-3 whitespace-nowrap">{formatDate(row.date)}</td>
                            <td className="px-4 py-3">
                              <span className={`px-2 py-0.5 rounded text-xs font-medium ${
                                row.type === 'Expense' ? 'bg-rose-100 text-rose-700' :
                                row.type === 'Income' ? 'bg-emerald-100 text-emerald-700' :
                                'bg-slate-100 text-slate-600'
                              }`}>{row.type}</span>
                            </td>
                            <td className="px-4 py-3">{previewCatMap.get(row.categoryId) ?? row.categoryId}</td>
                            <td className="px-4 py-3 text-slate-500">{previewAccMap.get(row.accountId) ?? row.accountId}</td>
                            <td className={`px-4 py-3 text-right font-medium ${row.amount < 0 ? 'text-rose-600' : 'text-emerald-600'}`}>
                              {row.amount < 0 ? '-' : '+'}{formatVND(Math.abs(row.amount))}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}

              {state.transactions.length > 0 && preview.length === 0 && (
                <p className="mt-4 text-sm text-slate-500">
                  <span className="font-semibold text-slate-700 dark:text-slate-300">{state.transactions.length}</span> transactions currently loaded.
                </p>
              )}
            </div>
          </section>

          <section className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6 flex flex-col md:flex-row md:items-center justify-between gap-6">
            <div className="flex-1">
              <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">Export Data</h3>
              <p className="text-sm text-slate-500">Download your data for backup or external analysis.</p>
              <p className="text-xs text-slate-400 mt-2">{state.transactions.length} transactions available</p>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={handleExportCSV}
                disabled={state.transactions.length === 0}
                className="flex items-center gap-2 px-6 py-2 border border-slate-200 dark:border-slate-700 rounded-lg text-sm font-bold hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
              >
                <span className="material-symbols-outlined text-lg">download</span>
                CSV
              </button>
            </div>
          </section>

          <section className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden">
            <div className="p-6 border-b border-slate-100 dark:border-slate-800">
              <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">Sao lưu & Khôi phục</h3>
              <p className="text-sm text-slate-500">Export toàn bộ database (giao dịch, danh mục, tài khoản, ngân sách) ra file JSON để backup hoặc chuyển thiết bị.</p>
            </div>
            <div className="p-6 space-y-6">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                  <p className="text-sm font-bold text-slate-900 dark:text-slate-100">Export Database</p>
                  <p className="text-xs text-slate-500 mt-0.5">
                    {state.transactions.length} giao dịch · {state.categories.length} danh mục · {state.accounts.length} tài khoản
                  </p>
                </div>
                <button
                  onClick={() => exportDatabase(state)}
                  className="flex items-center gap-2 px-5 py-2 bg-primary text-white rounded-lg text-sm font-bold hover:opacity-90 transition-opacity"
                >
                  <span className="material-symbols-outlined text-lg">backup</span>
                  Export .json
                </button>
              </div>

              <div className="border-t border-slate-100 dark:border-slate-800 pt-6">
                <p className="text-sm font-bold text-slate-900 dark:text-slate-100 mb-3">Khôi phục từ backup</p>
                <div
                  className={`flex flex-col items-center gap-3 rounded-xl border-2 border-dashed px-6 py-8 transition-colors cursor-pointer ${
                    isBackupDragging
                      ? 'border-primary bg-primary/5'
                      : 'border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/50'
                  }`}
                  onDragOver={(e) => { e.preventDefault(); setIsBackupDragging(true); }}
                  onDragLeave={() => setIsBackupDragging(false)}
                  onDrop={(e) => { e.preventDefault(); setIsBackupDragging(false); const f = e.dataTransfer.files[0]; if (f) handleBackupFile(f); }}
                  onClick={() => backupInputRef.current?.click()}
                >
                  <span className="material-symbols-outlined text-3xl text-slate-400">settings_backup_restore</span>
                  <p className="text-sm text-slate-500 text-center">
                    {isBackupDragging ? 'Thả file .json vào đây' : 'Click hoặc kéo thả file .json backup vào đây'}
                  </p>
                  <input
                    ref={backupInputRef}
                    type="file"
                    accept=".json"
                    className="hidden"
                    onChange={(e) => { const f = e.target.files?.[0]; if (f) handleBackupFile(f); e.target.value = ''; }}
                  />
                </div>

                {backupMsg && (
                  <p className={`mt-3 text-sm font-medium ${backupMsg.includes('thành công') ? 'text-emerald-600' : 'text-slate-600 dark:text-slate-400'}`}>
                    {backupMsg}
                  </p>
                )}

                {pendingBackup && (
                  <div className="mt-4 flex items-center gap-3">
                    <button
                      onClick={handleRestoreBackup}
                      className="flex items-center gap-2 px-5 py-2 bg-primary text-white rounded-lg text-sm font-bold hover:opacity-90 transition-opacity"
                    >
                      <span className="material-symbols-outlined text-sm">restore</span>
                      Khôi phục
                    </button>
                    <button
                      onClick={() => { setPendingBackup(null); setBackupMsg(''); }}
                      className="px-4 py-2 text-sm font-medium text-slate-500 hover:text-slate-700 transition-colors"
                    >
                      Hủy
                    </button>
                  </div>
                )}
              </div>
            </div>
          </section>

          <section className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 divide-y divide-slate-100 dark:divide-slate-800">
            <div className="p-6">
              <h3 className="text-base font-bold text-slate-900 dark:text-slate-100 mb-4">Dangerous Actions</h3>
              <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                <div>
                  <p className="text-sm font-bold text-slate-900 dark:text-slate-100">Clear All Transaction Data</p>
                  <p className="text-xs text-slate-500">This will permanently delete all your uploaded transactions. This cannot be undone.</p>
                </div>
                <button
                  onClick={handleClear}
                  className="px-4 py-2 bg-rose-50 text-rose-600 border border-rose-100 rounded-lg text-sm font-bold hover:bg-rose-100 transition-colors"
                >
                  Clear Database
                </button>
              </div>
            </div>
          </section>
        </div>
      )}

      {activeTab === 'lists' && (
        <div className="max-w-5xl space-y-8">
          {/* Defaults */}
          <section className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden">
            <div className="p-6 border-b border-slate-100 dark:border-slate-800">
              <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">Mặc định khi thêm giao dịch</h3>
              <p className="text-sm text-slate-500">Danh mục và tài khoản sẽ được điền sẵn khi mở form thêm giao dịch mới.</p>
            </div>
            <div className="p-6 grid grid-cols-1 md:grid-cols-3 gap-6">
              <div>
                <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Danh mục mặc định — Chi tiêu</label>
                <select
                  value={defaultCategoryExpenseId}
                  onChange={(e) => {
                    setDefaultCategoryExpenseId(e.target.value);
                    dispatch({ type: 'SET_DEFAULTS', defaultCategoryExpenseId: e.target.value, defaultCategoryIncomeId, defaultAccountId });
                  }}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
                >
                  <option value="">— Không có mặc định —</option>
                  {expenseCategories.map((cat) => (
                    <option key={cat.id} value={cat.id}>{cat.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Danh mục mặc định — Thu nhập</label>
                <select
                  value={defaultCategoryIncomeId}
                  onChange={(e) => {
                    setDefaultCategoryIncomeId(e.target.value);
                    dispatch({ type: 'SET_DEFAULTS', defaultCategoryExpenseId, defaultCategoryIncomeId: e.target.value, defaultAccountId });
                  }}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
                >
                  <option value="">— Không có mặc định —</option>
                  {incomeCategories.map((cat) => (
                    <option key={cat.id} value={cat.id}>{cat.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs font-bold uppercase text-slate-400 mb-2">Tài khoản mặc định</label>
                <select
                  value={defaultAccountId}
                  onChange={(e) => {
                    setDefaultAccountId(e.target.value);
                    dispatch({ type: 'SET_DEFAULTS', defaultCategoryExpenseId, defaultCategoryIncomeId, defaultAccountId: e.target.value });
                  }}
                  className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
                >
                  <option value="">— Không có mặc định —</option>
                  {state.accounts.map((acc) => (
                    <option key={acc.id} value={acc.id}>{acc.name}</option>
                  ))}
                </select>
              </div>
            </div>
          </section>

          {/* Categories */}
          <section className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden">
            <div className="p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
              <div>
                <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">Danh mục</h3>
                <p className="text-sm text-slate-500">Quản lý danh sách danh mục dùng trong form nhập giao dịch.</p>
              </div>
              <span className="text-sm font-semibold text-primary">{state.categories.length} danh mục</span>
            </div>
            <div className="p-6 space-y-4">
              <div className="flex gap-2">
                <select
                  value={newCategoryType}
                  onChange={(e) => setNewCategoryType(e.target.value as 'Expense' | 'Income')}
                  className="px-3 py-2 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
                >
                  <option value="Expense">Chi tiêu</option>
                  <option value="Income">Thu nhập</option>
                </select>
                <input
                  type="text"
                  value={newCategory}
                  onChange={(e) => setNewCategory(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && addCategory()}
                  placeholder="Nhập tên danh mục mới..."
                  className="flex-1 px-3 py-2 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
                />
                <button
                  onClick={addCategory}
                  disabled={!newCategory.trim()}
                  className="flex items-center gap-1.5 px-4 py-2 bg-primary text-white rounded-lg text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-40 disabled:cursor-not-allowed"
                >
                  <span className="material-symbols-outlined text-sm">add</span>
                  Thêm
                </button>
              </div>
              {state.categories.length === 0 ? (
                <p className="text-sm text-slate-400 text-center py-4">Chưa có danh mục nào. Import CSV hoặc thêm thủ công.</p>
              ) : (
                <div className="space-y-3">
                  {expenseCategories.length > 0 && (
                    <div>
                      <p className="text-xs font-bold uppercase text-rose-500 mb-1.5">Chi tiêu</p>
                      <div className="flex flex-wrap gap-2">
                        {expenseCategories.map((cat) => (
                          <span key={cat.id} className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-rose-50 dark:bg-rose-900/20 rounded-full text-sm font-medium text-slate-700 dark:text-slate-300">
                            {cat.name}
                            <button onClick={() => removeCategory(cat.id)} className="size-4 flex items-center justify-center rounded-full hover:bg-rose-100 hover:text-rose-600 transition-colors text-slate-400">
                              <span className="material-symbols-outlined text-xs">close</span>
                            </button>
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                  {incomeCategories.length > 0 && (
                    <div>
                      <p className="text-xs font-bold uppercase text-emerald-500 mb-1.5">Thu nhập</p>
                      <div className="flex flex-wrap gap-2">
                        {incomeCategories.map((cat) => (
                          <span key={cat.id} className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-emerald-50 dark:bg-emerald-900/20 rounded-full text-sm font-medium text-slate-700 dark:text-slate-300">
                            {cat.name}
                            <button onClick={() => removeCategory(cat.id)} className="size-4 flex items-center justify-center rounded-full hover:bg-emerald-100 hover:text-emerald-600 transition-colors text-slate-400">
                              <span className="material-symbols-outlined text-xs">close</span>
                            </button>
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          </section>

          {/* Accounts */}
          <section className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden">
            <div className="p-6 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
              <div>
                <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">Tài khoản</h3>
                <p className="text-sm text-slate-500">Quản lý danh sách tài khoản dùng trong form nhập giao dịch.</p>
              </div>
              <span className="text-sm font-semibold text-primary">{state.accounts.length} tài khoản</span>
            </div>
            <div className="p-6 space-y-4">
              <div className="flex gap-2">
                <input
                  type="text"
                  value={newAccount}
                  onChange={(e) => setNewAccount(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && addAccount()}
                  placeholder="Nhập tên tài khoản mới..."
                  className="flex-1 px-3 py-2 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition"
                />
                <button
                  onClick={addAccount}
                  disabled={!newAccount.trim() || state.accounts.some((a) => a.name === newAccount.trim())}
                  className="flex items-center gap-1.5 px-4 py-2 bg-primary text-white rounded-lg text-sm font-semibold hover:opacity-90 transition-opacity disabled:opacity-40 disabled:cursor-not-allowed"
                >
                  <span className="material-symbols-outlined text-sm">add</span>
                  Thêm
                </button>
              </div>
              {state.accounts.length === 0 ? (
                <p className="text-sm text-slate-400 text-center py-4">Chưa có tài khoản nào. Import CSV hoặc thêm thủ công.</p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {state.accounts.map((acc) => (
                    <span
                      key={acc.id}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-slate-100 dark:bg-slate-800 rounded-full text-sm font-medium text-slate-700 dark:text-slate-300"
                    >
                      {acc.name}
                      <button
                        onClick={() => removeAccount(acc.id)}
                        className="size-4 flex items-center justify-center rounded-full hover:bg-rose-100 hover:text-rose-600 transition-colors text-slate-400"
                      >
                        <span className="material-symbols-outlined text-xs">close</span>
                      </button>
                    </span>
                  ))}
                </div>
              )}
            </div>
          </section>
        </div>
      )}

      {activeTab === 'display' && (
        <div className="max-w-5xl">
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6">
            <h3 className="text-base font-bold text-slate-900 dark:text-slate-100 mb-2">Display & Theme</h3>
            <p className="text-sm text-slate-500">Theme settings coming soon.</p>
          </div>
        </div>
      )}

      {activeTab === 'about' && (
        <div className="max-w-5xl">
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-6 space-y-3">
            <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">About saveMoney</h3>
            <p className="text-sm text-slate-500">Personal finance dashboard for Savey app exports.</p>
            <p className="text-xs text-slate-400">Import your CSV from the Savey iPhone app to get started.</p>
          </div>
        </div>
      )}
    </div>
  );
}
