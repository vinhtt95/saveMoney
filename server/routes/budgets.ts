import { Router } from 'express';
import { pool } from '../db.js';

export const router = Router();

async function getBudgetsWithCategories() {
  const [budgets] = await pool.query(
    'SELECT id, name, limit_amount as limitAmount, date_start as dateStart, date_end as dateEnd FROM budgets'
  ) as any;
  const [links] = await pool.query('SELECT budget_id, category_id FROM budget_categories') as any;

  const catMap: Record<string, string[]> = {};
  for (const link of links) {
    if (!catMap[link.budget_id]) catMap[link.budget_id] = [];
    catMap[link.budget_id].push(link.category_id);
  }

  return budgets.map((b: any) => ({
    ...b,
    limitAmount: parseFloat(b.limitAmount),
    categoryIds: catMap[b.id] || [],
  }));
}

router.get('/budgets', async (_req, res) => {
  res.json(await getBudgetsWithCategories());
});

router.post('/budgets', async (req, res) => {
  const { id, name, limit, dateStart, dateEnd, categoryIds } = req.body;
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    await conn.query(
      'INSERT INTO budgets (id, name, limit_amount, date_start, date_end) VALUES (?, ?, ?, ?, ?)',
      [id, name, limit, dateStart, dateEnd]
    );
    if (categoryIds?.length) {
      const values = categoryIds.map((cId: string) => [id, cId]);
      await conn.query('INSERT IGNORE INTO budget_categories (budget_id, category_id) VALUES ?', [values]);
    }
    await conn.commit();
    res.json({ ok: true });
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
});

router.put('/budgets/:id', async (req, res) => {
  const { name, limit, dateStart, dateEnd, categoryIds } = req.body;
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    await conn.query(
      'UPDATE budgets SET name=?, limit_amount=?, date_start=?, date_end=? WHERE id=?',
      [name, limit, dateStart, dateEnd, req.params.id]
    );
    await conn.query('DELETE FROM budget_categories WHERE budget_id = ?', [req.params.id]);
    if (categoryIds?.length) {
      const values = categoryIds.map((cId: string) => [req.params.id, cId]);
      await conn.query('INSERT INTO budget_categories (budget_id, category_id) VALUES ?', [values]);
    }
    await conn.commit();
    res.json({ ok: true });
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
});

router.delete('/budgets/:id', async (req, res) => {
  await pool.query('DELETE FROM budgets WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
});
