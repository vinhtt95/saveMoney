import { Router } from 'express';
import { pool } from '../db.js';

export const router = Router();

router.get('/accounts', async (_req, res) => {
  const [accounts] = await pool.query('SELECT id, name FROM accounts ORDER BY name');
  const [balances] = await pool.query('SELECT account_id, balance FROM account_balances') as any;
  const balanceMap: Record<string, number> = {};
  for (const row of balances) {
    balanceMap[row.account_id] = parseFloat(row.balance);
  }
  res.json({ accounts, balances: balanceMap });
});

router.post('/accounts', async (req, res) => {
  const { id, name } = req.body;
  await pool.query('INSERT INTO accounts (id, name) VALUES (?, ?)', [id, name]);
  res.json({ id, name });
});

router.post('/accounts/bulk', async (req, res) => {
  const accounts: Array<{ id: string; name: string }> = req.body;
  if (!accounts.length) return res.json({ inserted: 0 });
  const values = accounts.map((a) => [a.id, a.name]);
  const [result] = await pool.query(
    'INSERT IGNORE INTO accounts (id, name) VALUES ?',
    [values]
  ) as any;
  res.json({ inserted: result.affectedRows });
});

router.put('/accounts/:id', async (req, res) => {
  const { name } = req.body;
  await pool.query('UPDATE accounts SET name = ? WHERE id = ?', [name, req.params.id]);
  res.json({ ok: true });
});

router.delete('/accounts/:id', async (req, res) => {
  await pool.query('DELETE FROM accounts WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
});

router.put('/accounts/:id/balance', async (req, res) => {
  const { balance } = req.body;
  await pool.query(
    'INSERT INTO account_balances (account_id, balance) VALUES (?, ?) ON DUPLICATE KEY UPDATE balance = ?',
    [req.params.id, balance, balance]
  );
  res.json({ ok: true });
});

// Bulk set all balances at once
router.put('/accounts/balances/bulk', async (req, res) => {
  const balances: Record<string, number> = req.body;
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    await conn.query('DELETE FROM account_balances');
    const entries = Object.entries(balances);
    if (entries.length) {
      const values = entries.map(([id, bal]) => [id, bal]);
      await conn.query('INSERT INTO account_balances (account_id, balance) VALUES ?', [values]);
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
