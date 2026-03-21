import React, { useState, useRef } from 'react';
import { useApp } from '../context/AppContext';
import { parseCSV, exportCSV } from '../utils/csvParser';
import { formatVND, formatDate } from '../utils/formatters';

type Tab = 'data' | 'display' | 'about';

export function Settings() {
  const { state, dispatch } = useApp();
  const [activeTab, setActiveTab] = useState<Tab>('data');
  const [preview, setPreview] = useState<ReturnType<typeof parseCSV>>([]);
  const [pendingTxs, setPendingTxs] = useState<ReturnType<typeof parseCSV>>([]);
  const [importMsg, setImportMsg] = useState('');
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  function handleFile(file: File) {
    if (!file.name.endsWith('.csv')) {
      setImportMsg('Please select a CSV file.');
      return;
    }
    const reader = new FileReader();
    reader.onload = (e) => {
      const text = e.target?.result as string;
      const parsed = parseCSV(text);
      setPendingTxs(parsed);
      setPreview(parsed.slice(-5));
      setImportMsg(`Parsed ${parsed.length} transactions. Review preview below, then click Import.`);
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
    dispatch({ type: 'IMPORT', transactions: pendingTxs });
    setImportMsg(`Successfully imported ${pendingTxs.length} transactions!`);
    setPendingTxs([]);
    setPreview([]);
  }

  function handleExportCSV() {
    const csv = exportCSV(state.transactions);
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

  const tabs: { id: Tab; label: string }[] = [
    { id: 'data', label: 'Data Management' },
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
                            <td className="px-4 py-3">{row.category}</td>
                            <td className="px-4 py-3 text-slate-500">{row.account}</td>
                            <td className={`px-4 py-3 text-right font-medium ${row.amount < 0 ? 'text-rose-600' : 'text-emerald-600'}`}>
                              {row.amount < 0 ? '-' : '+'}{formatVND(row.amount)}
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
