import { Router } from 'express';
import { pool } from '../db.js';

export const router = Router();

const SETTINGS_KEY = 'goldPriceCache';

// GET /api/gold-prices — return latest cached gold prices saved by the web app
router.get('/gold-prices', async (_req, res) => {
  const [rows] = await pool.query(
    'SELECT value FROM user_settings WHERE `key` = ?',
    [SETTINGS_KEY]
  ) as any;
  if (!rows.length || !rows[0].value) {
    return res.status(404).json({ error: 'No gold price data available' });
  }
  try {
    res.json(JSON.parse(rows[0].value));
  } catch {
    res.status(500).json({ error: 'Corrupt gold price cache' });
  }
});

// POST /api/gold-prices — web app saves latest fetched prices here
router.post('/gold-prices', async (req, res) => {
  const blob = JSON.stringify(req.body);
  await pool.query(
    'INSERT INTO user_settings (`key`, value) VALUES (?, ?) ON DUPLICATE KEY UPDATE value = ?',
    [SETTINGS_KEY, blob, blob]
  );
  res.json({ ok: true });
});
