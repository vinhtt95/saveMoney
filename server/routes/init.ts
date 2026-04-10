import { Router } from 'express';
import { pool } from '../db.js';

export const router = Router();

router.get('/init', async (_req, res) => {
  // Ensure note column exists (for existing databases)
  try {
    await pool.query('ALTER TABLE transactions ADD COLUMN note TEXT NULL');
  } catch (err: any) {
    if (err.code !== 'ER_DUP_FIELDNAME') throw err;
  }

  const [
    [categories],
    [accounts],
    [balanceRows],
    [transactions],
    [budgets],
    [budgetCats],
    [goldAssets],
    [settingRows],
  ] = await Promise.all([
    pool.query('SELECT id, name, type, icon, color FROM categories ORDER BY type, name'),
    pool.query('SELECT id, name FROM accounts ORDER BY name'),
    pool.query('SELECT account_id, balance FROM account_balances'),
    pool.query('SELECT id, date, type, category_id as categoryId, account_id as accountId, transfer_to_id as transferToId, amount, note FROM transactions ORDER BY date DESC'),
    pool.query('SELECT id, name, limit_amount as limitAmount, date_start as dateStart, date_end as dateEnd FROM budgets'),
    pool.query('SELECT budget_id, category_id FROM budget_categories'),
    pool.query('SELECT id, brand, product_id as productId, product_name as productName, quantity, note, created_at as createdAt FROM gold_assets'),
    pool.query('SELECT `key`, value FROM user_settings'),
  ]) as any;

  const balanceMap: Record<string, number> = {};
  for (const row of balanceRows) {
    balanceMap[row.account_id] = parseFloat(row.balance);
  }

  const catMap: Record<string, string[]> = {};
  for (const link of budgetCats) {
    if (!catMap[link.budget_id]) catMap[link.budget_id] = [];
    catMap[link.budget_id].push(link.category_id);
  }

  const settings: Record<string, string> = {};
  for (const row of settingRows) {
    settings[row.key] = row.value;
  }

  const sellPriceMapById: Record<string, number> = {};
  const buyPriceMapById: Record<string, number> = {};
  
  const sellPriceMapByName: Record<string, number> = {};
  const buyPriceMapByName: Record<string, number> = {};

  const rawCache = settings['goldPriceCache'];
  if (rawCache) {
    try {
      const cache = JSON.parse(rawCache);
      
      // 1. Quét format cũ
      for (const item of (cache.items ?? [])) {
        if (item.id) {
          if (item.sell_price) sellPriceMapById[item.id] = item.sell_price;
          if (item.buy_price) buyPriceMapById[item.id] = item.buy_price;
        }
      }

      // 2. Quét format mới (SJC, BTMC)
      const sources = [cache.sjc, cache.btmc];
      for (const source of sources) {
        if (source?.products) {
          for (const p of source.products) {
            // Ánh xạ theo ID
            if (p.id) {
              if (p.sellPrice) sellPriceMapById[p.id] = p.sellPrice;
              if (p.buyPrice) buyPriceMapById[p.id] = p.buyPrice;
            }
            // Ánh xạ dự phòng theo Name
            if (p.name) {
              if (p.sellPrice) sellPriceMapByName[p.name] = p.sellPrice;
              if (p.buyPrice) buyPriceMapByName[p.name] = p.buyPrice;
            }
          }
        }
      }

      // 3. Quét giá Vàng Thế giới
      if (cache.world?.spotPerLuong) {
        sellPriceMapById['world_spot'] = cache.world.spotPerLuong;
        buyPriceMapById['world_spot'] = cache.world.spotPerLuong;
      }
    } catch (e) {
      console.error("Lỗi parse gold cache:", e);
    }
  }

  res.json({
    categories,
    accounts,
    accountBalances: balanceMap,
    transactions: transactions.map((t: any) => ({
      ...t,
      amount: parseFloat(t.amount),
      note: t.note || undefined,
    })),
    budgets: budgets.map((b: any) => ({
      ...b,
      limit: parseFloat(b.limitAmount),
      categoryIds: catMap[b.id] || [],
      limitAmount: undefined,
    })),
    goldAssets: goldAssets.map((a: any) => ({
      ...a,
      quantity: parseFloat(a.quantity),
      // Tìm theo ID trước, nếu không có thì tìm theo Name, nếu vẫn không có thì gán null
      currentSellPrice: sellPriceMapById[a.productId] ?? sellPriceMapByName[a.productName] ?? null,
      currentBuyPrice: buyPriceMapById[a.productId] ?? buyPriceMapByName[a.productName] ?? null,
    })),
    settings,
  });
});
