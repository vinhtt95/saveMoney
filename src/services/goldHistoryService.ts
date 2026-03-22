import type {
  GoldPriceCache,
  GoldProduct,
  GoldProductRegistry,
  GoldPriceHistory,
  GoldPricePoint,
  GoldPriceSnapshot,
} from '../types';

const REGISTRY_KEY = 'savemoney_gold_products';
const HISTORY_KEY = 'savemoney_gold_history';
const MAX_SNAPSHOTS = 365;

// --- Default Registry ---
// IDs are assigned by position (sortOrder) within each source's product array.
// Even if product names drift slightly over time, the position stays stable.

const DEFAULT_SJC_NAMES = [
  'Vàng miếng SJC 1L, 10L, 1KG',
  'Vàng miếng SJC 5c',
  'Vàng miếng SJC 2c, 1c, 5p',
  'Vàng nhẫn SJC 99.99 1c, 2c',
  'Vàng nhẫn SJC 99.99 5c',
  'Vàng trang sức SJC 99.99',
  'Vàng trang sức SJC 68',
  'Vàng trang sức SJC 61.8',
  'Vàng trang sức SJC 58.3',
  'Vàng trang sức SJC 41.7',
  'Vàng trang sức SJC 37.5',
  'Vàng trang sức SJC 33.3',
];

const DEFAULT_BTMC_NAMES = [
  'Vàng SJC 1L',
  'Vàng SJC 1C-2C-5C',
  'Nữ trang vàng 99.99',
  'Nữ trang vàng 99%',
  'Nữ trang vàng 68%',
  'Nữ trang vàng 58.3%',
  'Nữ trang vàng 41.7%',
  'Vàng BTMC SJC',
  'Vàng BTMC 9999',
];

export function buildDefaultRegistry(): GoldProductRegistry {
  const products: GoldProduct[] = [];

  DEFAULT_SJC_NAMES.forEach((name, i) => {
    products.push({ id: `sjc_${String(i + 1).padStart(3, '0')}`, brand: 'SJC', name, sortOrder: i });
  });

  DEFAULT_BTMC_NAMES.forEach((name, i) => {
    products.push({ id: `btmc_${String(i + 1).padStart(3, '0')}`, brand: 'BTMC', name, sortOrder: i });
  });

  products.push({ id: 'world_spot', brand: 'world', name: 'Vàng thế giới (Spot)', sortOrder: 0 });
  products.push({ id: 'world_futures', brand: 'world', name: 'Vàng thế giới (Futures)', sortOrder: 1 });

  return { products, version: 1, updatedAt: new Date().toISOString() };
}

export function loadRegistry(): GoldProductRegistry {
  try {
    const raw = localStorage.getItem(REGISTRY_KEY);
    if (raw) return JSON.parse(raw) as GoldProductRegistry;
  } catch { /* ignore */ }
  const registry = buildDefaultRegistry();
  saveRegistry(registry);
  return registry;
}

function saveRegistry(registry: GoldProductRegistry): void {
  try {
    localStorage.setItem(REGISTRY_KEY, JSON.stringify(registry));
  } catch { /* ignore */ }
}

// Update display names in the registry based on fresh fetch data (by sortOrder position).
// This keeps names current while IDs remain stable.
export function updateRegistryNames(registry: GoldProductRegistry, cache: GoldPriceCache): void {
  let changed = false;

  if (cache.sjc?.products) {
    cache.sjc.products.forEach((p, i) => {
      const entry = registry.products.find(r => r.brand === 'SJC' && r.sortOrder === i);
      if (entry && entry.name !== p.name) {
        entry.name = p.name;
        changed = true;
      }
    });
  }

  if (cache.btmc?.products) {
    cache.btmc.products.forEach((p, i) => {
      const entry = registry.products.find(r => r.brand === 'BTMC' && r.sortOrder === i);
      if (entry && entry.name !== p.name) {
        entry.name = p.name;
        changed = true;
      }
    });
  }

  if (changed) {
    registry.updatedAt = new Date().toISOString();
    saveRegistry(registry);
  }
}

// --- History ---

export function loadGoldHistory(): GoldPriceHistory {
  try {
    const raw = localStorage.getItem(HISTORY_KEY);
    if (raw) return JSON.parse(raw) as GoldPriceHistory;
  } catch { /* ignore */ }
  return { snapshots: [], version: 1 };
}

export function saveGoldHistory(history: GoldPriceHistory): void {
  try {
    localStorage.setItem(HISTORY_KEY, JSON.stringify(history));
  } catch { /* ignore quota errors */ }
}

function getTodayDateKey(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function hasSnapshotForToday(history: GoldPriceHistory): boolean {
  const today = getTodayDateKey();
  return history.snapshots.some(s => s.date === today);
}

export function recordSnapshot(cache: GoldPriceCache, registry: GoldProductRegistry): void {
  const history = loadGoldHistory();
  const today = getTodayDateKey();

  // Build price points from registry
  const prices: GoldPricePoint[] = [];

  registry.products.forEach(product => {
    if (product.brand === 'SJC' && cache.sjc?.products) {
      const p = cache.sjc.products[product.sortOrder];
      if (p) prices.push({ productId: product.id, buyPrice: p.buyPrice, sellPrice: p.sellPrice });
    } else if (product.brand === 'BTMC' && cache.btmc?.products) {
      const p = cache.btmc.products[product.sortOrder];
      if (p) prices.push({ productId: product.id, buyPrice: p.buyPrice, sellPrice: p.sellPrice });
    } else if (product.brand === 'world' && cache.world) {
      if (product.id === 'world_spot') {
        prices.push({ productId: 'world_spot', buyPrice: cache.world.spotPerLuong, sellPrice: cache.world.spotPerLuong });
      } else if (product.id === 'world_futures') {
        prices.push({ productId: 'world_futures', buyPrice: cache.world.futuresPerLuong, sellPrice: cache.world.futuresPerLuong });
      }
    }
  });

  const snapshot: GoldPriceSnapshot = {
    date: today,
    recordedAt: new Date().toISOString(),
    prices,
    world: cache.world
      ? {
          spot: cache.world.spot,
          futures: cache.world.futures,
          usdvnd: cache.world.usdvnd,
          spotPerLuong: cache.world.spotPerLuong,
          futuresPerLuong: cache.world.futuresPerLuong,
        }
      : null,
  };

  // Replace if today's snapshot already exists, otherwise append
  const idx = history.snapshots.findIndex(s => s.date === today);
  if (idx >= 0) {
    history.snapshots[idx] = snapshot;
  } else {
    history.snapshots.push(snapshot);
  }

  // Cap at MAX_SNAPSHOTS, keep the most recent
  if (history.snapshots.length > MAX_SNAPSHOTS) {
    history.snapshots = history.snapshots.slice(-MAX_SNAPSHOTS);
  }

  saveGoldHistory(history);
}

export function maybeRecordTodaySnapshot(cache: GoldPriceCache): void {
  const history = loadGoldHistory();
  if (!hasSnapshotForToday(history)) {
    const registry = loadRegistry();
    updateRegistryNames(registry, cache);
    recordSnapshot(cache, registry);
  }
}

// --- Query helpers ---

export interface HistoryDataPoint {
  date: string;
  buyPrice: number;
  sellPrice: number;
}

export interface WorldRefPoint {
  date: string;
  spotPerLuong: number;
  futuresPerLuong: number;
}

function getDateCutoff(days: number | null): string | null {
  if (days === null) return null;
  const d = new Date();
  d.setDate(d.getDate() - days);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function getHistoryForProduct(
  productId: string,
  history: GoldPriceHistory,
  days: number | null
): HistoryDataPoint[] {
  const cutoff = getDateCutoff(days);
  return history.snapshots
    .filter(s => cutoff === null || s.date >= cutoff)
    .map(s => {
      const point = s.prices.find(p => p.productId === productId);
      return point
        ? { date: s.date, buyPrice: point.buyPrice, sellPrice: point.sellPrice }
        : null;
    })
    .filter((x): x is HistoryDataPoint => x !== null);
}

export function getWorldHistoryForPeriod(
  history: GoldPriceHistory,
  days: number | null
): WorldRefPoint[] {
  const cutoff = getDateCutoff(days);
  return history.snapshots
    .filter(s => (cutoff === null || s.date >= cutoff) && s.world !== null)
    .map(s => ({
      date: s.date,
      spotPerLuong: s.world!.spotPerLuong,
      futuresPerLuong: s.world!.futuresPerLuong,
    }));
}
