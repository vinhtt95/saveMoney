import { Router } from 'express';
import { pool } from '../db.js';

export const router = Router();

router.get('/settings', async (_req, res) => {
  const [rows] = await pool.query('SELECT `key`, value FROM user_settings') as any;
  const result: Record<string, string> = {};
  for (const row of rows) {
    result[row.key] = row.value;
  }
  res.json(result);
});

router.put('/settings', async (req, res) => {
  const settings: Record<string, string> = req.body;
  const entries = Object.entries(settings);
  if (!entries.length) return res.json({ ok: true });
  for (const [key, value] of entries) {
    await pool.query(
      'INSERT INTO user_settings (`key`, value) VALUES (?, ?) ON DUPLICATE KEY UPDATE value = ?',
      [key, value, value]
    );
  }
  res.json({ ok: true });
});
