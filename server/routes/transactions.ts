import { Router } from 'express';
import { pool } from '../db.js';

export const router = Router();

router.get('/transactions', async (_req, res) => {
  const [rows] = await pool.query(
    'SELECT id, date, type, category_id as categoryId, account_id as accountId, transfer_to_id as transferToId, amount FROM transactions ORDER BY date DESC'
  ) as any;
  const transactions = rows.map((r: any) => ({
    ...r,
    amount: parseFloat(r.amount),
  }));
  res.json(transactions);
});

router.post('/transactions', async (req, res) => {
  const { id, date, type, categoryId, accountId, transferToId, amount } = req.body;
  const dateStr = typeof date === 'string' ? date.slice(0, 10) : new Date(date).toISOString().slice(0, 10);
  await pool.query(
    'INSERT INTO transactions (id, date, type, category_id, account_id, transfer_to_id, amount) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [id, dateStr, type, categoryId || null, accountId, transferToId || null, amount]
  );
  res.json({ ok: true });
});

router.post('/transactions/bulk', async (req, res) => {
  const transactions: any[] = req.body;
  if (!transactions.length) return res.json({ inserted: 0 });
  const values = transactions.map((t) => {
    const dateStr = typeof t.date === 'string' ? t.date.slice(0, 10) : new Date(t.date).toISOString().slice(0, 10);
    return [t.id, dateStr, t.type, t.categoryId || null, t.accountId, t.transferToId || null, t.amount];
  });
  const [result] = await pool.query(
    'INSERT IGNORE INTO transactions (id, date, type, category_id, account_id, transfer_to_id, amount) VALUES ?',
    [values]
  ) as any;
  res.json({ inserted: result.affectedRows });
});

router.put('/transactions/:id', async (req, res) => {
  const { date, type, categoryId, accountId, transferToId, amount } = req.body;
  const dateStr = typeof date === 'string' ? date.slice(0, 10) : new Date(date).toISOString().slice(0, 10);
  await pool.query(
    'UPDATE transactions SET date=?, type=?, category_id=?, account_id=?, transfer_to_id=?, amount=? WHERE id=?',
    [dateStr, type, categoryId || null, accountId, transferToId || null, amount, req.params.id]
  );
  res.json({ ok: true });
});

router.delete('/transactions/all', async (_req, res) => {
  await pool.query('DELETE FROM transactions');
  res.json({ ok: true });
});

router.delete('/transactions/:id', async (req, res) => {
  await pool.query('DELETE FROM transactions WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
});
