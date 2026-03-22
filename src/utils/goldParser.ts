import type { GoldProductPrice } from '../types';

// Parse SJC JSON API response from /GoldPrice/Services/PriceService.ashx?method=getCurrentGoldPrice
// Format: { success: true, data: [{ TypeName, BranchName, BuyValue, SellValue }] }
// Show only HCM branch, deduplicate by TypeName
export function parseSJCJson(data: unknown): GoldProductPrice[] {
  if (!data || typeof data !== 'object') return [];
  const obj = data as Record<string, unknown>;
  if (!Array.isArray(obj.data)) return [];

  const seen = new Set<string>();
  const results: GoldProductPrice[] = [];

  // First pass: HCM branch
  for (const item of obj.data as Record<string, unknown>[]) {
    const branch = String(item.BranchName ?? '');
    const name = String(item.TypeName ?? '').trim();
    if (!name || branch !== 'Hồ Chí Minh') continue;
    if (seen.has(name)) continue;
    seen.add(name);
    const buyPrice = Number(item.BuyValue) || 0;
    const sellPrice = Number(item.SellValue) || 0;
    if (buyPrice > 0 || sellPrice > 0) {
      results.push({ name, buyPrice, sellPrice });
    }
  }

  // Fallback: any branch if HCM returned nothing
  if (results.length === 0) {
    seen.clear();
    for (const item of obj.data as Record<string, unknown>[]) {
      const name = String(item.TypeName ?? '').trim();
      if (!name || seen.has(name)) continue;
      seen.add(name);
      const buyPrice = Number(item.BuyValue) || 0;
      const sellPrice = Number(item.SellValue) || 0;
      if (buyPrice > 0 || sellPrice > 0) {
        results.push({ name, buyPrice, sellPrice });
      }
    }
  }

  return results;
}

// Parse BTMC HTML table
// Table structure has rowspan on first column (logo cell), causing variable cell count per row:
//   6-cell row: [logo/empty, name, purity, buy, sell, detail]
//   5-cell row: [name, purity, buy, sell, detail]  ← due to rowspan
// Prices are in units of 10,000 VND (e.g. "16860" = 168,600,000 VND/lượng)
export function parseBTMCHtml(html: string): GoldProductPrice[] {
  const doc = new DOMParser().parseFromString(html, 'text/html');
  const rows = doc.querySelectorAll('table tr');
  const results: GoldProductPrice[] = [];

  for (const row of rows) {
    const cells = Array.from(row.querySelectorAll('td'));
    if (cells.length < 4) continue;

    let name = '';
    let buyRaw = '';
    let sellRaw = '';

    if (cells.length >= 6) {
      // 6-cell row: [logo, name, purity, buy, sell, detail]
      name = cells[1].textContent?.trim() ?? '';
      buyRaw = cells[3].textContent?.trim() ?? '';
      sellRaw = cells[4].textContent?.trim() ?? '';
    } else if (cells.length === 5) {
      // 5-cell row (rowspan removed logo): [name, purity, buy, sell, detail]
      name = cells[0].textContent?.trim() ?? '';
      buyRaw = cells[2].textContent?.trim() ?? '';
      sellRaw = cells[3].textContent?.trim() ?? '';
    } else if (cells.length === 4) {
      // 4-cell row: [name, buy, sell, detail]
      name = cells[0].textContent?.trim() ?? '';
      buyRaw = cells[1].textContent?.trim() ?? '';
      sellRaw = cells[2].textContent?.trim() ?? '';
    }

    if (!name || name.length < 3) continue;
    // Skip header-like cells
    if (name.toLowerCase().includes('thương phẩm') || name.toLowerCase().includes('brand')) continue;

    const buyNum = parseInt(buyRaw.replace(/[^\d]/g, ''), 10) || 0;
    const sellNum = parseInt(sellRaw.replace(/[^\d]/g, ''), 10) || 0;

    // BTMC prices are in units of 10,000 VND
    const buyPrice = buyNum * 10000;
    const sellPrice = typeof sellRaw === 'string' && sellRaw.toLowerCase().includes('liên hệ')
      ? 0
      : sellNum * 10000;

    if (buyPrice > 0 || sellPrice > 0) {
      results.push({ name, buyPrice, sellPrice });
    }
  }

  return results;
}
