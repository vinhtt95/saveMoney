import React, { useState, useEffect, useCallback } from 'react';
import type { GoldPriceCache, GoldSourceData, GoldProductPrice } from '../types';
import { fetchGoldPrices, loadCachedGoldPrices, isCacheValid } from '../services/goldPriceService';
import { formatVND } from '../utils/formatters';

function formatUSD(value: number): string {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 2 }).format(value);
}

function formatTime(iso: string): string {
  try {
    return new Date(iso).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  } catch {
    return iso;
  }
}

function TableSkeleton() {
  return (
    <div className="space-y-2 animate-pulse">
      {[1, 2, 3, 4].map((i) => (
        <div key={i} className="grid grid-cols-3 gap-2">
          <div className="h-4 bg-slate-200 dark:bg-slate-700 rounded col-span-1" />
          <div className="h-4 bg-slate-200 dark:bg-slate-700 rounded" />
          <div className="h-4 bg-slate-200 dark:bg-slate-700 rounded" />
        </div>
      ))}
    </div>
  );
}

function GoldTable({ data, loading, error }: { data: GoldSourceData | null; loading: boolean; error?: boolean }) {
  if (loading) return <TableSkeleton />;
  if (error || (!data && !loading)) {
    return (
      <div className="flex items-center gap-2 py-4 text-sm text-rose-500 dark:text-rose-400">
        <span className="material-symbols-outlined text-base">error</span>
        Không tải được dữ liệu
      </div>
    );
  }
  if (!data || data.products.length === 0) {
    return <p className="text-sm text-slate-400 py-4">Không có dữ liệu</p>;
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead>
          <tr className="text-xs font-semibold text-slate-400 dark:text-slate-500 uppercase tracking-wide border-b border-slate-100 dark:border-slate-700">
            <th className="text-left pb-2 pr-4">Sản phẩm</th>
            <th className="text-right pb-2 pr-4 text-emerald-600 dark:text-emerald-400">Mua vào</th>
            <th className="text-right pb-2 text-rose-500 dark:text-rose-400">Bán ra</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-50 dark:divide-slate-800">
          {data.products.map((p: GoldProductPrice, i: number) => (
            <tr key={i} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors">
              <td className="py-2 pr-4 text-slate-700 dark:text-slate-300 font-medium">{p.name}</td>
              <td className="py-2 pr-4 text-right text-emerald-600 dark:text-emerald-400 tabular-nums">
                {p.buyPrice > 0 ? formatVND(p.buyPrice) : '—'}
              </td>
              <td className="py-2 text-right text-rose-500 dark:text-rose-400 tabular-nums">
                {p.sellPrice > 0 ? formatVND(p.sellPrice) : '—'}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function Gold() {
  const [cache, setCache] = useState<GoldPriceCache | null>(null);
  const [loading, setLoading] = useState(false);
  const [fetchErrors, setFetchErrors] = useState<{ sjc?: boolean; btmc?: boolean; world?: boolean }>({});

  const load = useCallback(async (force = false) => {
    const existing = loadCachedGoldPrices();
    if (!force && existing && isCacheValid(existing)) {
      setCache(existing);
      return;
    }
    setLoading(true);
    try {
      const result = await fetchGoldPrices();
      setCache(result);
      setFetchErrors({
        world: !result.world,
        sjc: !result.sjc || result.sjc.products.length === 0,
        btmc: !result.btmc || result.btmc.products.length === 0,
      });
    } catch {
      // preserve existing cache on full failure
      if (existing) setCache(existing);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const lastUpdated = cache?.cachedAt ? formatTime(cache.cachedAt) : null;

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 dark:text-slate-100">Giá Vàng</h1>
          {lastUpdated && (
            <p className="text-xs text-slate-400 mt-0.5">Cập nhật lúc {lastUpdated}</p>
          )}
        </div>
        <button
          onClick={() => load(true)}
          disabled={loading}
          className="flex items-center gap-1.5 px-4 py-2 text-sm font-medium rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700 disabled:opacity-50 transition-colors"
        >
          <span className={`material-symbols-outlined text-base ${loading ? 'animate-spin' : ''}`}>
            {loading ? 'autorenew' : 'refresh'}
          </span>
          {loading ? 'Đang tải...' : 'Làm mới'}
        </button>
      </div>

      {/* World Gold Card */}
      <div className="rounded-2xl border border-amber-200 dark:border-amber-800/50 bg-gradient-to-br from-amber-50 to-yellow-50 dark:from-amber-950/30 dark:to-yellow-950/30 p-5">
        <div className="flex items-center gap-2 mb-4">
          <span className="material-symbols-outlined text-amber-500">public</span>
          <a href="https://vn.tradingview.com/symbols/XAUUSD/" target="_blank" rel="noopener noreferrer" className="font-semibold text-slate-700 dark:text-slate-200 hover:text-amber-600 dark:hover:text-amber-400 hover:underline transition-colors">Giá Vàng Thế Giới (XAUUSD)</a>
        </div>

        {loading && !cache?.world ? (
          <div className="animate-pulse space-y-2">
            <div className="h-8 w-48 bg-amber-200/60 dark:bg-amber-800/30 rounded" />
            <div className="h-5 w-64 bg-amber-200/40 dark:bg-amber-800/20 rounded" />
          </div>
        ) : fetchErrors.world || !cache?.world ? (
          <div className="flex items-center gap-2 text-sm text-rose-500">
            <span className="material-symbols-outlined text-base">error</span>
            Không tải được giá thế giới
          </div>
        ) : (
          <div className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              {/* Spot */}
              <div className="rounded-xl bg-white/60 dark:bg-slate-800/40 p-3 space-y-1">
                <p className="text-[11px] font-semibold uppercase tracking-wide text-amber-600 dark:text-amber-400">Spot (XAUUSD=X)</p>
                <p className="text-xl font-bold text-amber-600 dark:text-amber-400 tabular-nums">
                  {cache.world.spot > 0 ? formatUSD(cache.world.spot) : '—'}
                </p>
                <p className="text-xs text-slate-500 dark:text-slate-400">/ troy oz</p>
                <p className="text-sm font-semibold text-slate-700 dark:text-slate-200 tabular-nums">
                  {cache.world.spotPerLuong > 0 ? formatVND(cache.world.spotPerLuong) : '—'}
                </p>
                <p className="text-xs text-slate-400">/ lượng</p>
              </div>
              {/* Futures */}
              <div className="rounded-xl bg-white/60 dark:bg-slate-800/40 p-3 space-y-1">
                <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Futures (GC=F)</p>
                <p className="text-xl font-bold text-slate-600 dark:text-slate-300 tabular-nums">
                  {cache.world.futures > 0 ? formatUSD(cache.world.futures) : '—'}
                </p>
                <p className="text-xs text-slate-500 dark:text-slate-400">/ troy oz</p>
                <p className="text-sm font-semibold text-slate-700 dark:text-slate-200 tabular-nums">
                  {cache.world.futuresPerLuong > 0 ? formatVND(cache.world.futuresPerLuong) : '—'}
                </p>
                <p className="text-xs text-slate-400">/ lượng</p>
              </div>
              {/* FX rate */}
              <div className="rounded-xl bg-white/60 dark:bg-slate-800/40 p-3 space-y-1">
                <p className="text-[11px] font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">Tỷ giá</p>
                <p className="text-xl font-bold text-slate-600 dark:text-slate-300 tabular-nums">
                  {formatVND(cache.world.usdvnd)}
                </p>
                <p className="text-xs text-slate-400">/ 1 USD</p>
              </div>
            </div>
          </div>
        )}
        <p className="text-[10px] text-slate-400 mt-3">
          Công thức: giá × (37.5g ÷ 31.1035g) × tỷ giá — chưa thuế phí. Spot = giá giao ngay, Futures = hợp đồng tương lai.
        </p>
      </div>

      {/* SJC + BTMC comparison */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* SJC */}
        <div className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-5">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <span className="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 font-bold text-sm">S</span>
              <div>
                <a href="https://sjc.com.vn/gia-vang-online" target="_blank" rel="noopener noreferrer" className="font-semibold text-slate-800 dark:text-slate-100 hover:text-red-600 dark:hover:text-red-400 hover:underline transition-colors">SJC</a>
                {cache?.sjc?.fetchedAt && (
                  <p className="text-[10px] text-slate-400">{formatTime(cache.sjc.fetchedAt)}</p>
                )}
              </div>
            </div>
            {fetchErrors.sjc && (
              <span className="text-xs px-2 py-0.5 rounded-full bg-rose-100 dark:bg-rose-900/30 text-rose-600 dark:text-rose-400">Lỗi</span>
            )}
          </div>
          <GoldTable data={cache?.sjc ?? null} loading={loading && !cache?.sjc} error={fetchErrors.sjc} />
        </div>

        {/* BTMC */}
        <div className="rounded-2xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 p-5">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <span className="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 font-bold text-sm">B</span>
              <div>
                <a href="https://btmc.vn/gia-vang-theo-ngay.html" target="_blank" rel="noopener noreferrer" className="font-semibold text-slate-800 dark:text-slate-100 hover:text-blue-600 dark:hover:text-blue-400 hover:underline transition-colors">Bảo Tín Minh Châu</a>
                {cache?.btmc?.fetchedAt && (
                  <p className="text-[10px] text-slate-400">{formatTime(cache.btmc.fetchedAt)}</p>
                )}
              </div>
            </div>
            {fetchErrors.btmc && (
              <span className="text-xs px-2 py-0.5 rounded-full bg-rose-100 dark:bg-rose-900/30 text-rose-600 dark:text-rose-400">Lỗi</span>
            )}
          </div>
          <GoldTable data={cache?.btmc ?? null} loading={loading && !cache?.btmc} error={fetchErrors.btmc} />
        </div>
      </div>

      {/* Note */}
      <p className="text-xs text-slate-400 text-center">
        Dữ liệu được lấy từ sjc.com.vn và btmc.vn. Cache 5 phút. SJC và BTMC có thể dùng tên gọi khác nhau cho cùng loại vàng.
      </p>
    </div>
  );
}
