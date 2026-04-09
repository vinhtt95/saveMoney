import { Router } from 'express';
import { pool } from '../db.js';
import { randomUUID } from 'crypto';

export const router = Router();

router.get('/transactions', async (_req, res) => {
  const [rows] = await pool.query(
    'SELECT id, date, type, category_id as categoryId, account_id as accountId, transfer_to_id as transferToId, amount, note FROM transactions ORDER BY date DESC'
  ) as any;
  const transactions = rows.map((r: any) => ({
    ...r,
    amount: parseFloat(r.amount),
  }));
  res.json(transactions);
});

router.post('/transactions', async (req, res) => {
  const { date, type, categoryId, accountId, transferToId, amount, note } = req.body;
  if (!accountId) {
    res.status(400).json({ error: 'account_id is required', code: 'MISSING_ACCOUNT_ID' });
    return;
  }
  const id = randomUUID();
  const dateStr = typeof date === 'string' ? date.slice(0, 10) : new Date(date).toISOString().slice(0, 10);
  await pool.query(
    'INSERT INTO transactions (id, date, type, category_id, account_id, transfer_to_id, amount, note) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [id, dateStr, type, categoryId || null, accountId, transferToId || null, amount, note || null]
  );
  res.json({ id, date: dateStr, type, categoryId: categoryId || null, accountId, transferToId: transferToId || null, amount, note: note || null });
});

router.post('/transactions/bulk', async (req, res) => {
  const transactions: any[] = req.body;
  if (!transactions.length) return res.json({ inserted: 0 });
  const invalid = transactions.filter((t) => !t.accountId);
  if (invalid.length > 0) {
    res.status(400).json({ error: 'Some transactions are missing account_id', code: 'MISSING_ACCOUNT_ID', invalidIds: invalid.map((t) => t.id) });
    return;
  }
  const values = transactions.map((t) => {
    const dateStr = typeof t.date === 'string' ? t.date.slice(0, 10) : new Date(t.date).toISOString().slice(0, 10);
    return [t.id, dateStr, t.type, t.categoryId || null, t.accountId, t.transferToId || null, t.amount, t.note || null];
  });
  const [result] = await pool.query(
    'INSERT IGNORE INTO transactions (id, date, type, category_id, account_id, transfer_to_id, amount, note) VALUES ?',
    [values]
  ) as any;
  res.json({ inserted: result.affectedRows });
});

router.put('/transactions/:id', async (req, res) => {
  const { date, type, categoryId, accountId, transferToId, amount, note } = req.body;
  const id = req.params.id;
  const dateStr = typeof date === 'string' ? date.slice(0, 10) : new Date(date).toISOString().slice(0, 10);
  await pool.query(
    'UPDATE transactions SET date=?, type=?, category_id=?, account_id=?, transfer_to_id=?, amount=?, note=? WHERE id=?',
    [dateStr, type, categoryId || null, accountId || null, transferToId || null, amount, note || null, id]
  );
  res.json({ id, date: dateStr, type, categoryId: categoryId || null, accountId: accountId || null, transferToId: transferToId || null, amount, note: note || null });
});

router.delete('/transactions/all', async (_req, res) => {
  await pool.query('DELETE FROM transactions');
  await pool.query('DELETE FROM account_balances');
  await pool.query('DELETE FROM categories');
  await pool.query('DELETE FROM accounts');
  res.json({ ok: true });
});

router.delete('/transactions/:id', async (req, res) => {
  await pool.query('DELETE FROM transactions WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
});
