import React, { useState, useEffect, useCallback } from 'react';
import type { GoldAsset, GoldBrand, GoldPriceCache } from '../types';
import { useApp } from '../context/AppContext';
import { fetchGoldPrices, loadCachedGoldPrices, isCacheValid } from '../services/goldPriceService';
import { formatVND } from '../utils/formatters';

function resolveGoldPrice(asset: GoldAsset, cache: GoldPriceCache | null): number | null {
  if (!cache) return null;
  if (asset.brand === 'world') {
    return cache.world?.spotPerLuong ?? null;
  }
  const source = asset.brand === 'SJC' ? cache.sjc : cache.btmc;
  if (!source) return null;
  const product = source.products.find((p) => p.name === asset.productName);
  return product?.buyPrice ?? null;
}

function getProductsForBrand(brand: GoldBrand, cache: GoldPriceCache | null): string[] {
  if (!cache) return [];
  if (brand === 'world') return ['Spot (XAUUSD)'];
  const source = brand === 'SJC' ? cache.sjc : cache.btmc;
  return source?.products.map((p) => p.name) ?? [];
}

const BRAND_LABELS: Record<GoldBrand, string> = { SJC: 'SJC', BTMC: 'BTMC', world: 'Thế giới' };
const BRAND_COLORS: Record<GoldBrand, string> = {
  SJC: 'bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400',
  BTMC: 'bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400',
  world: 'bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400',
};

interface AssetFormState {
  brand: GoldBrand;
  productName: string;
  quantity: string;
  note: string;
}

const defaultForm: AssetFormState = { brand: 'SJC', productName: '', quantity: '', note: '' };

function AssetModal({
  open,
  editing,
  cache,
  onSave,
  onClose,
}: {
  open: boolean;
  editing: GoldAsset | null;
  cache: GoldPriceCache | null;
  onSave: (data: Omit<GoldAsset, 'id' | 'createdAt'>) => void;
  onClose: () => void;
}) {
  const [form, setForm] = useState<AssetFormState>(defaultForm);

  useEffect(() => {
    if (open) {
      setForm(editing
        ? { brand: editing.brand, productName: editing.productName, quantity: String(editing.quantity), note: editing.note ?? '' }
        : defaultForm
      );
    }
  }, [open, editing]);

  const products = getProductsForBrand(form.brand, cache);

  useEffect(() => {
    if (!editing && products.length > 0) {
      setForm((f) => ({ ...f, productName: products[0] }));
    }
  }, [form.brand, products.length]); // eslint-disable-line react-hooks/exhaustive-deps

  if (!open) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const qty = parseFloat(form.quantity);
    if (!form.productName || isNaN(qty) || qty <= 0) return;
    onSave({ brand: form.brand, productName: form.productName, quantity: qty, note: form.note || undefined });
  };

  const handleBrandChange = (brand: GoldBrand) => {
    const prods = getProductsForBrand(brand, cache);
    setForm((f) => ({ ...f, brand, productName: prods[0] ?? '' }));
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />
      <div className="relative w-full max-w-md rounded-2xl bg-white dark:bg-slate-900 shadow-2xl border border-slate-200 dark:border-slate-700 p-6 space-y-5">
        <h2 className="text-lg font-bold text-slate-800 dark:text-slate-100">
          {editing ? 'Sửa tài sản' : 'Thêm tài sản vàng'}
        </h2>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Brand */}
          <div>
            <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-1.5">
              Thương hiệu
            </label>
            <div className="flex gap-2">
              {(['SJC', 'BTMC', 'world'] as GoldBrand[]).map((b) => (
                <button
                  key={b}
                  type="button"
                  onClick={() => handleBrandChange(b)}
                  className={`flex-1 py-2 rounded-lg text-sm font-medium border transition-colors ${
                    form.brand === b
                      ? 'border-amber-400 bg-amber-50 dark:bg-amber-900/20 text-amber-700 dark:text-amber-300'
                      : 'border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800'
                  }`}
                >
                  {BRAND_LABELS[b]}
                </button>
              ))}
            </div>
          </div>

          {/* Product */}
          <div>
            <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-1.5">
              Loại vàng
            </label>
            {products.length > 0 ? (
              <select
                value={form.productName}
                onChange={(e) => setForm((f) => ({ ...f, productName: e.target.value }))}
                className="w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-3 py-2 text-sm text-slate-800 dark:text-slate-200 focus:outline-none focus:ring-2 focus:ring-amber-400"
              >
                {products.map((p) => (
                  <option key={p} value={p}>{p}</option>
                ))}
              </select>
            ) : (
              <div className="rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-3 py-2 text-sm text-slate-400">
                {cache ? 'Không có dữ liệu giá' : 'Đang tải giá...'}
              </div>
            )}
          </div>

          {/* Quantity */}
          <div>
            <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-1.5">
              Số lượng (lượng)
            </label>
            <input
              type="number"
              min="0.01"
              step="0.01"
              value={form.quantity}
              onChange={(e) => setForm((f) => ({ ...f, quantity: e.target.value }))}
              placeholder="VD: 1.5"
              className="w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-3 py-2 text-sm text-slate-800 dark:text-slate-200 focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
          </div>

          {/* Note */}
          <div>
            <label className="block text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wide mb-1.5">
              Ghi chú (tuỳ chọn)
            </label>
            <input
              type="text"
              value={form.note}
              onChange={(e) => setForm((f) => ({ ...f, note: e.target.value }))}
              placeholder="VD: Mua ngày 10/3"
              className="w-full rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 px-3 py-2 text-sm text-slate-800 dark:text-slate-200 focus:outline-none focus:ring-2 focus:ring-amber-400"
            />
          </div>

          <div className="flex gap-3 pt-1">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 text-sm font-medium text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
            >
              Huỷ
            </button>
            <button
              type="submit"
              className="flex-1 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-600 text-white text-sm font-semibold transition-colors"
            >
              {editing ? 'Lưu' : 'Thêm'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

export function Wealth() {
  const { state, dispatch } = useApp();
  const { goldAssets } = state;
  const [cache, setCache] = useState<GoldPriceCache | null>(null);
  const [loadingPrices, setLoadingPrices] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<GoldAsset | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<string | null>(null);

  const loadPrices = useCallback(async (force = false) => {
    const existing = loadCachedGoldPrices();
    if (!force && existing && isCacheValid(existing)) {
      setCache(existing);
      return;
    }
    setLoadingPrices(true);
    try {
      const result = await fetchGoldPrices();
      setCache(result);
    } catch {
      if (existing) setCache(existing);
    } finally {
      setLoadingPrices(false);
    }
  }, []);

  useEffect(() => { loadPrices(); }, [loadPrices]);

  const handleSave = (data: Omit<GoldAsset, 'id' | 'createdAt'>) => {
    if (editing) {
      dispatch({ type: 'EDIT_GOLD_ASSET', asset: { ...editing, ...data } });
    } else {
      dispatch({
        type: 'ADD_GOLD_ASSET',
        asset: { ...data, id: crypto.randomUUID(), createdAt: new Date().toISOString() },
      });
    }
    setModalOpen(false);
    setEditing(null);
  };

  const handleEdit = (asset: GoldAsset) => {
    setEditing(asset);
    setModalOpen(true);
  };

  const handleDelete = (id: string) => {
    dispatch({ type: 'DELETE_GOLD_ASSET', id });
    setDeleteConfirm(null);
  };

  const totalGold = goldAssets.reduce((sum, asset) => {
    const price = resolveGoldPrice(asset, cache);
    return price ? sum + price * asset.quantity : sum;
  }, 0);

  return (
    <div className="p-6 max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 dark:text-slate-100">Tài sản</h1>
          <p className="text-sm text-slate-400 mt-0.5">Quản lý tài sản vàng của bạn</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => loadPrices(true)}
            disabled={loadingPrices}
            className="flex items-center gap-1.5 px-3 py-2 text-sm font-medium rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700 disabled:opacity-50 transition-colors"
          >
            <span className={`material-symbols-outlined text-base ${loadingPrices ? 'animate-spin' : ''}`}>
              {loadingPrices ? 'autorenew' : 'refresh'}
            </span>
          </button>
          <button
            onClick={() => { setEditing(null); setModalOpen(true); }}
            className="flex items-center gap-1.5 px-4 py-2 text-sm font-semibold rounded-lg bg-amber-500 hover:bg-amber-600 text-white transition-colors"
          >
            <span className="material-symbols-outlined text-base">add</span>
            Thêm tài sản
          </button>
        </div>
      </div>

      {/* Summary card */}
      {goldAssets.length > 0 && (
        <div className="rounded-2xl border border-amber-200 dark:border-amber-800/50 bg-gradient-to-br from-amber-50 to-yellow-50 dark:from-amber-950/30 dark:to-yellow-950/30 p-5">
          <p className="text-xs font-semibold text-amber-600 dark:text-amber-400 uppercase tracking-wide mb-1">Tổng giá trị vàng</p>
          <p className="text-3xl font-bold text-amber-700 dark:text-amber-300 tabular-nums">
            {totalGold > 0 ? formatVND(totalGold) : '—'}
          </p>
          <p className="text-xs text-slate-400 mt-1">{goldAssets.length} tài sản · giá mua vào hiện tại</p>
        </div>
      )}

      {/* Gold assets list */}
      <div className="space-y-3">
        <h2 className="text-sm font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wide">
          Vàng
          <span className="ml-2 text-xs font-normal normal-case text-slate-400">({goldAssets.length})</span>
        </h2>

        {goldAssets.length === 0 ? (
          <div className="rounded-2xl border-2 border-dashed border-slate-200 dark:border-slate-700 p-12 text-center">
            <span className="material-symbols-outlined text-4xl text-slate-300 dark:text-slate-600">diamond</span>
            <p className="mt-3 text-sm text-slate-400">Chưa có tài sản nào</p>
            <button
              onClick={() => { setEditing(null); setModalOpen(true); }}
              className="mt-4 px-4 py-2 text-sm font-medium rounded-lg bg-amber-500 hover:bg-amber-600 text-white transition-colors"
            >
              Thêm tài sản đầu tiên
            </button>
          </div>
        ) : (
          <div className="space-y-2">
            {goldAssets.map((asset) => {
              const price = resolveGoldPrice(asset, cache);
              const total = price ? price * asset.quantity : null;
              return (
                <div
                  key={asset.id}
                  className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-4 flex items-center gap-4"
                >
                  {/* Brand badge */}
                  <span className={`inline-flex items-center justify-center w-10 h-10 rounded-lg text-sm font-bold shrink-0 ${BRAND_COLORS[asset.brand]}`}>
                    {asset.brand === 'world' ? '🌐' : asset.brand[0]}
                  </span>

                  {/* Info */}
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-semibold text-slate-800 dark:text-slate-100 truncate">{asset.productName}</p>
                    <p className="text-xs text-slate-400">
                      {asset.quantity} lượng
                      {price ? ` · ${formatVND(price)}/lượng` : (loadingPrices ? ' · Đang tải giá...' : ' · Chưa có giá')}
                    </p>
                    {asset.note && <p className="text-xs text-slate-400 italic mt-0.5">{asset.note}</p>}
                  </div>

                  {/* Total value */}
                  <div className="text-right shrink-0">
                    <p className="text-sm font-bold text-amber-600 dark:text-amber-400 tabular-nums">
                      {total ? formatVND(total) : '—'}
                    </p>
                    <span className={`text-[10px] font-semibold px-1.5 py-0.5 rounded-full ${BRAND_COLORS[asset.brand]}`}>
                      {BRAND_LABELS[asset.brand]}
                    </span>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center gap-1 shrink-0">
                    <button
                      onClick={() => handleEdit(asset)}
                      className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                    >
                      <span className="material-symbols-outlined text-base">edit</span>
                    </button>
                    {deleteConfirm === asset.id ? (
                      <div className="flex items-center gap-1">
                        <button
                          onClick={() => handleDelete(asset.id)}
                          className="px-2 py-1 text-xs rounded-lg bg-rose-100 dark:bg-rose-900/30 text-rose-600 dark:text-rose-400 font-medium hover:bg-rose-200 dark:hover:bg-rose-900/50 transition-colors"
                        >
                          Xoá
                        </button>
                        <button
                          onClick={() => setDeleteConfirm(null)}
                          className="px-2 py-1 text-xs rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-500 font-medium hover:bg-slate-200 dark:hover:bg-slate-700 transition-colors"
                        >
                          Huỷ
                        </button>
                      </div>
                    ) : (
                      <button
                        onClick={() => setDeleteConfirm(asset.id)}
                        className="p-1.5 rounded-lg text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-900/20 transition-colors"
                      >
                        <span className="material-symbols-outlined text-base">delete</span>
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      <AssetModal
        open={modalOpen}
        editing={editing}
        cache={cache}
        onSave={handleSave}
        onClose={() => { setModalOpen(false); setEditing(null); }}
      />
    </div>
  );
}
