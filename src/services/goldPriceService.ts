import type { GoldPriceCache, GoldSourceData, WorldGoldData } from '../types';
import { parseSJCJson, parseBTMCHtml } from '../utils/goldParser';
import { maybeRecordTodaySnapshot } from './goldHistoryService';

const TROY_OZ_PER_LUONG = 37.5 / 31.1035; // ≈ 1.2057
const CACHE_KEY = 'savemoney_gold_cache';
const CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes
const FALLBACK_USDVND = 25400;

export function loadCachedGoldPrices(): GoldPriceCache | null {
  try {
    const raw = localStorage.getItem(CACHE_KEY);
    if (!raw) return null;
    return JSON.parse(raw) as GoldPriceCache;
  } catch {
    return null;
  }
}

export function saveCachedGoldPrices(cache: GoldPriceCache): void {
  try {
    localStorage.setItem(CACHE_KEY, JSON.stringify(cache));
  } catch {
    // ignore storage errors
  }
}

export function isCacheValid(cache: GoldPriceCache): boolean {
  return Date.now() - new Date(cache.cachedAt).getTime() < CACHE_TTL_MS;
}

async function fetchXAUUSD(): Promise<{ spot: number; futures: number; usdvnd: number }> {
  const [spotResult, futuresResult, fxResult] = await Promise.allSettled([
    // Spot: fxratesapi.com (CORS-friendly, no key needed)
    fetch('https://api.fxratesapi.com/latest?base=XAU&currencies=USD'),
    // Futures: Yahoo Finance GC=F via Vite proxy
    fetch('/api/gold-futures/v8/finance/chart/GC=F?interval=1d&range=1d'),
    fetch('/api/fx/v6/latest/USD'),
  ]);

  // fxratesapi: { base: "XAU", rates: { USD: 4497.44 } }
  let spot = 0;
  if (spotResult.status === 'fulfilled' && spotResult.value.ok) {
    try {
      const data = await spotResult.value.json();
      spot = Number(data?.rates?.USD) || 0;
    } catch { /* ignore */ }
  }

  let futures = 0;
  if (futuresResult.status === 'fulfilled' && futuresResult.value.ok) {
    try {
      const data = await futuresResult.value.json();
      futures = data?.chart?.result?.[0]?.meta?.regularMarketPrice ?? 0;
    } catch { /* ignore */ }
  }

  let usdvnd = FALLBACK_USDVND;
  if (fxResult.status === 'fulfilled' && fxResult.value.ok) {
    try {
      const data = await fxResult.value.json();
      if (data?.rates?.VND) usdvnd = data.rates.VND;
    } catch {
      // use fallback
    }
  }

  return { spot, futures, usdvnd };
}

async function fetchSJC(): Promise<GoldSourceData> {
  const res = await fetch('/api/sjc/GoldPrice/Services/PriceService.ashx?method=getCurrentGoldPrice');
  if (!res.ok) throw new Error(`SJC HTTP ${res.status}`);
  const json = await res.json();
  const products = parseSJCJson(json);
  return { source: 'SJC', products, fetchedAt: new Date().toISOString() };
}

async function fetchBTMC(): Promise<GoldSourceData> {
  const res = await fetch('/api/btmc/gia-vang-theo-ngay.html');
  if (!res.ok) throw new Error(`BTMC HTTP ${res.status}`);
  const html = await res.text();
  const products = parseBTMCHtml(html);
  return { source: 'BTMC', products, fetchedAt: new Date().toISOString() };
}

export async function fetchGoldPrices(): Promise<GoldPriceCache> {
  const existing = loadCachedGoldPrices();

  const [worldResult, sjcResult, btmcResult] = await Promise.allSettled([
    fetchXAUUSD(),
    fetchSJC(),
    fetchBTMC(),
  ]);

  let world: WorldGoldData | null = existing?.world ?? null;
  if (worldResult.status === 'fulfilled') {
    const { spot, futures, usdvnd } = worldResult.value;
    if (spot > 0 || futures > 0) {
      world = {
        spot,
        futures,
        usdvnd,
        spotPerLuong: Math.round(spot * TROY_OZ_PER_LUONG * usdvnd),
        futuresPerLuong: Math.round(futures * TROY_OZ_PER_LUONG * usdvnd),
        fetchedAt: new Date().toISOString(),
      };
    }
  }

  const sjc: GoldSourceData | null =
    sjcResult.status === 'fulfilled' ? sjcResult.value : (existing?.sjc ?? null);

  const btmc: GoldSourceData | null =
    btmcResult.status === 'fulfilled' ? btmcResult.value : (existing?.btmc ?? null);

  const cache: GoldPriceCache = { world, sjc, btmc, cachedAt: new Date().toISOString() };
  saveCachedGoldPrices(cache);
  maybeRecordTodaySnapshot(cache);
  return cache;
}
