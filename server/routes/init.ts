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
    pool.query('SELECT id, name, type FROM categories ORDER BY type, name'),
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

  const priceMap: Record<string, number> = {};
  const rawCache = settings['goldPriceCache'];
  if (rawCache) {
    try {
      const cache = JSON.parse(rawCache);
      for (const item of (cache.items ?? [])) {
        if (item.id && item.sell_price) priceMap[item.id] = item.sell_price;
      }
    } catch {}
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
      currentSellPrice: priceMap[a.productId] ?? null,
    })),
    settings,
  });
});
