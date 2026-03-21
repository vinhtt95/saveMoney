import { useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useApp } from '../context/AppContext';
import { formatVND, formatDate } from '../utils/formatters';
import { Transaction } from '../types';

const fieldCls =
  'px-2 py-1.5 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg text-sm outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition';

function typeBadge(type: Transaction['type']) {
  switch (type) {
    case 'Expense':
      return (
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-rose-100 dark:bg-rose-900/30 text-rose-600">
          Chi tiêu
        </span>
      );
    case 'Income':
      return (
        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600">
          Thu nhập
        </span>
      );
    default:
      return null;
  }
}

export function Categories() {
  const { state, dispatch } = useApp();

  const [activeTab, setActiveTab] = useState<'Expense' | 'Income'>('Expense');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [isAdding, setIsAdding] = useState(false);
  const [newCategoryName, setNewCategoryName] = useState('');
  const [addError, setAddError] = useState('');
  const [editingCategory, setEditingCategory] = useState<string | null>(null);
  const [editingName, setEditingName] = useState('');

  const categories = activeTab === 'Expense' ? state.expenseCategories : state.incomeCategories;

  const categoryData = useMemo(() => {
    return categories.map((cat) => {
      const txCount = state.transactions.filter(
        (t) => t.category === cat && t.type === activeTab
      ).length;
      const total = state.transactions
        .filter((t) => t.category === cat && t.type === activeTab)
        .reduce((sum, t) => sum + Math.abs(t.amount), 0);
      return { name: cat, txCount, total };
    });
  }, [categories, state.transactions, activeTab]);

  const selectedTxs = useMemo(() => {
    if (!selectedCategory) return [];
    return state.transactions
      .filter((t) => t.category === selectedCategory && t.type === activeTab)
      .sort((a, b) => b.date.getTime() - a.date.getTime())
      .slice(0, 50);
  }, [selectedCategory, state.transactions, activeTab]);

  const selectedTxTotal = useMemo(() => {
    if (!selectedCategory) return 0;
    return state.transactions.filter((t) => t.category === selectedCategory && t.type === activeTab).length;
  }, [selectedCategory, state.transactions, activeTab]);

  function handleTabChange(tab: 'Expense' | 'Income') {
    setActiveTab(tab);
    setSelectedCategory(null);
    setIsAdding(false);
    setEditingCategory(null);
    setAddError('');
  }

  function handleAdd() {
    const name = newCategoryName.trim();
    if (!name) {
      setAddError('Tên danh mục không được trống');
      return;
    }
    if (categories.includes(name)) {
      setAddError('Danh mục đã tồn tại');
      return;
    }
    dispatch({ type: 'ADD_CATEGORY', name, categoryType: activeTab });
    setIsAdding(false);
    setNewCategoryName('');
    setAddError('');
  }

  function handleRename(oldName: string) {
    const newName = editingName.trim();
    if (!newName || newName === oldName) {
      setEditingCategory(null);
      return;
    }
    if (categories.includes(newName)) {
      setEditingCategory(null);
      return;
    }
    dispatch({ type: 'RENAME_CATEGORY', oldName, newName, categoryType: activeTab });
    if (selectedCategory === oldName) setSelectedCategory(newName);
    setEditingCategory(null);
  }

  function handleDelete(name: string) {
    const txCount = state.transactions.filter(
      (t) => t.category === name && t.type === activeTab
    ).length;
    if (txCount > 0) {
      const confirmed = window.confirm(
        `Danh mục "${name}" có ${txCount} giao dịch. Xóa sẽ không xóa giao dịch, chỉ xóa khỏi danh sách. Tiếp tục?`
      );
      if (!confirmed) return;
    }
    dispatch({ type: 'DELETE_CATEGORY', name, categoryType: activeTab });
    if (selectedCategory === name) setSelectedCategory(null);
  }

  function startEdit(name: string) {
    setEditingCategory(name);
    setEditingName(name);
  }

  const isExpenseTab = activeTab === 'Expense';

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Danh mục</h1>
          <p className="text-sm text-slate-500 mt-0.5">Quản lý danh mục chi tiêu và thu nhập</p>
        </div>
        <button
          onClick={() => { setIsAdding(true); setNewCategoryName(''); setAddError(''); setEditingCategory(null); }}
          className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-xl text-sm font-semibold hover:opacity-90 transition-opacity shadow-sm"
        >
          <span className="material-symbols-outlined text-sm">add</span>
          Thêm danh mục
        </button>
      </div>

      {/* Tabs */}
      <div className="flex border-b border-slate-200 dark:border-slate-800 gap-1">
        <button
          onClick={() => handleTabChange('Expense')}
          className={`flex items-center gap-2 px-5 py-2.5 text-sm font-semibold border-b-2 transition-colors ${
            isExpenseTab
              ? 'border-rose-500 text-rose-600'
              : 'border-transparent text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'
          }`}
        >
          <span className="material-symbols-outlined text-base">trending_down</span>
          Chi tiêu
          <span className={`ml-1 px-2 py-0.5 rounded-full text-xs font-bold ${isExpenseTab ? 'bg-rose-100 dark:bg-rose-900/30 text-rose-600' : 'bg-slate-100 dark:bg-slate-800 text-slate-500'}`}>
            {state.expenseCategories.length}
          </span>
        </button>
        <button
          onClick={() => handleTabChange('Income')}
          className={`flex items-center gap-2 px-5 py-2.5 text-sm font-semibold border-b-2 transition-colors ${
            !isExpenseTab
              ? 'border-emerald-500 text-emerald-600'
              : 'border-transparent text-slate-500 hover:text-slate-700 dark:hover:text-slate-300'
          }`}
        >
          <span className="material-symbols-outlined text-base">trending_up</span>
          Thu nhập
          <span className={`ml-1 px-2 py-0.5 rounded-full text-xs font-bold ${!isExpenseTab ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600' : 'bg-slate-100 dark:bg-slate-800 text-slate-500'}`}>
            {state.incomeCategories.length}
          </span>
        </button>
      </div>

      {/* Add inline form */}
      {isAdding && (
        <div className={`rounded-xl border p-5 ${isExpenseTab ? 'bg-rose-50 dark:bg-rose-900/10 border-rose-200 dark:border-rose-800' : 'bg-emerald-50 dark:bg-emerald-900/10 border-emerald-200 dark:border-emerald-800'}`}>
          <p className={`text-xs font-bold uppercase tracking-widest mb-3 ${isExpenseTab ? 'text-rose-600' : 'text-emerald-600'}`}>
            Danh mục {isExpenseTab ? 'chi tiêu' : 'thu nhập'} mới
          </p>
          <div className="flex gap-3 items-start">
            <input
              autoFocus
              className={`flex-1 ${fieldCls}`}
              placeholder={isExpenseTab ? 'Vd: Ăn uống, Đi lại, Giải trí...' : 'Vd: Lương, Thưởng, Đầu tư...'}
              value={newCategoryName}
              onChange={(e) => setNewCategoryName(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') handleAdd();
                if (e.key === 'Escape') { setIsAdding(false); setAddError(''); }
              }}
            />
            <button
              onClick={handleAdd}
              className="flex items-center gap-1.5 px-4 py-1.5 bg-primary text-white rounded-lg text-sm font-semibold hover:opacity-90 transition-opacity"
            >
              <span className="material-symbols-outlined text-sm">check</span> Lưu
            </button>
            <button
              onClick={() => { setIsAdding(false); setAddError(''); }}
              className="flex items-center gap-1.5 px-3 py-1.5 border border-slate-200 dark:border-slate-700 rounded-lg text-sm font-medium text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
            >
              <span className="material-symbols-outlined text-sm">close</span>
            </button>
          </div>
          {addError && <p className="text-xs text-rose-500 mt-2">{addError}</p>}
        </div>
      )}

      {/* Two-column layout */}
      <div className="grid grid-cols-[2fr_3fr] gap-5 items-start">
        {/* Left: Category list */}
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
          <div className="px-5 py-3 border-b border-slate-100 dark:border-slate-800">
            <p className="text-xs font-bold uppercase tracking-widest text-slate-400">
              {categoryData.length} danh mục
            </p>
          </div>
          {categoryData.length === 0 ? (
            <div className="px-5 py-12 text-center text-slate-400">
              <span className="material-symbols-outlined text-4xl mb-2 block">category</span>
              <p className="text-sm font-medium">Chưa có danh mục nào</p>
              <p className="text-xs mt-1">Thêm danh mục bằng nút bên trên</p>
            </div>
          ) : (
            <div className="divide-y divide-slate-50 dark:divide-slate-800/50">
              {categoryData.map((cat) => {
                const isSelected = selectedCategory === cat.name;
                const isEditing = editingCategory === cat.name;
                return (
                  <div
                    key={cat.name}
                    onClick={() => !isEditing && setSelectedCategory(isSelected ? null : cat.name)}
                    className={`group flex items-center gap-3 px-4 py-3 cursor-pointer transition-colors ${
                      isSelected
                        ? isExpenseTab
                          ? 'bg-rose-50 dark:bg-rose-900/20 border-l-2 border-rose-500'
                          : 'bg-emerald-50 dark:bg-emerald-900/20 border-l-2 border-emerald-500'
                        : 'hover:bg-slate-50 dark:hover:bg-slate-800/50 border-l-2 border-transparent'
                    }`}
                  >
                    {/* Icon */}
                    <div className={`size-8 rounded-lg flex items-center justify-center shrink-0 ${
                      isExpenseTab ? 'bg-rose-100 dark:bg-rose-900/30' : 'bg-emerald-100 dark:bg-emerald-900/30'
                    }`}>
                      <span className={`material-symbols-outlined text-sm ${isExpenseTab ? 'text-rose-500' : 'text-emerald-500'}`}>
                        {isExpenseTab ? 'shopping_bag' : 'payments'}
                      </span>
                    </div>

                    {/* Name / edit input */}
                    <div className="flex-1 min-w-0" onClick={(e) => isEditing && e.stopPropagation()}>
                      {isEditing ? (
                        <input
                          autoFocus
                          className={`${fieldCls} w-full`}
                          value={editingName}
                          onChange={(e) => setEditingName(e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter') handleRename(cat.name);
                            if (e.key === 'Escape') setEditingCategory(null);
                          }}
                          onBlur={() => handleRename(cat.name)}
                          onClick={(e) => e.stopPropagation()}
                        />
                      ) : (
                        <>
                          <p className="text-sm font-semibold text-slate-800 dark:text-slate-100 truncate">{cat.name}</p>
                          <p className="text-xs text-slate-400">{cat.txCount} giao dịch</p>
                        </>
                      )}
                    </div>

                    {/* Actions */}
                    {!isEditing && (
                      <div className="flex items-center gap-0.5 shrink-0 opacity-0 group-hover:opacity-100 transition-opacity"
                        onClick={(e) => e.stopPropagation()}
                      >
                        <button
                          title="Đổi tên"
                          onClick={(e) => { e.stopPropagation(); startEdit(cat.name); }}
                          className="p-1 text-slate-400 hover:text-primary hover:bg-primary/10 rounded-lg transition-colors"
                        >
                          <span className="material-symbols-outlined text-sm">edit</span>
                        </button>
                        <button
                          title="Xóa"
                          onClick={(e) => { e.stopPropagation(); handleDelete(cat.name); }}
                          className="p-1 text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-900/20 rounded-lg transition-colors"
                        >
                          <span className="material-symbols-outlined text-sm">delete</span>
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Right: Transaction list for selected category */}
        <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
          {!selectedCategory ? (
            <div className="px-5 py-16 text-center text-slate-400">
              <span className="material-symbols-outlined text-5xl mb-3 block">touch_app</span>
              <p className="text-base font-medium">Chọn một danh mục</p>
              <p className="text-sm mt-1">để xem các giao dịch thuộc danh mục đó</p>
            </div>
          ) : (
            <>
              <div className="px-5 py-3.5 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between">
                <div>
                  <p className="text-sm font-bold text-slate-800 dark:text-slate-100">{selectedCategory}</p>
                  <p className="text-xs text-slate-400">{selectedTxTotal} giao dịch</p>
                </div>
                {typeBadge(activeTab)}
              </div>
              {selectedTxs.length === 0 ? (
                <div className="px-5 py-12 text-center text-slate-400">
                  <span className="material-symbols-outlined text-4xl mb-2 block">receipt_long</span>
                  <p className="text-sm">Chưa có giao dịch nào trong danh mục này</p>
                </div>
              ) : (
                <>
                  <div className="divide-y divide-slate-50 dark:divide-slate-800/50">
                    {selectedTxs.map((tx) => (
                      <div key={tx.id} className="flex items-center gap-3 px-5 py-3 hover:bg-slate-50/50 dark:hover:bg-slate-800/30 transition-colors">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className="text-xs text-slate-400 tabular-nums">{formatDate(tx.date)}</span>
                            <span className="text-sm text-slate-600 dark:text-slate-300 truncate">{tx.account}</span>
                          </div>
                        </div>
                        <span className={`text-sm font-bold tabular-nums shrink-0 ${activeTab === 'Expense' ? 'text-rose-600' : 'text-emerald-600'}`}>
                          {activeTab === 'Expense' ? '-' : '+'}{formatVND(Math.abs(tx.amount))}
                        </span>
                      </div>
                    ))}
                  </div>
                  {selectedTxTotal > 50 && (
                    <div className="px-5 py-3 border-t border-slate-100 dark:border-slate-800 text-center">
                      <Link
                        to="/transactions"
                        className="text-xs text-primary hover:underline font-medium"
                      >
                        Xem tất cả {selectedTxTotal} giao dịch →
                      </Link>
                    </div>
                  )}
                </>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
