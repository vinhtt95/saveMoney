import { Router } from 'express';
import { pool } from '../db.js';

export const router = Router();

router.get('/gold-assets', async (_req, res) => {
  const [rows] = await pool.query(
    'SELECT id, brand, product_id as productId, product_name as productName, quantity, note, created_at as createdAt FROM gold_assets'
  ) as any;
  const assets = rows.map((r: any) => ({
    ...r,
    quantity: parseFloat(r.quantity),
  }));
  res.json(assets);
});

router.post('/gold-assets', async (req, res) => {
  const { id, brand, productId, productName, quantity, note, createdAt } = req.body;
  await pool.query(
    'INSERT INTO gold_assets (id, brand, product_id, product_name, quantity, note, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
    [id, brand, productId || null, productName, quantity, note || null, createdAt]
  );
  res.json({ ok: true });
});

router.put('/gold-assets/:id', async (req, res) => {
  const { brand, productId, productName, quantity, note } = req.body;
  await pool.query(
    'UPDATE gold_assets SET brand=?, product_id=?, product_name=?, quantity=?, note=? WHERE id=?',
    [brand, productId || null, productName, quantity, note || null, req.params.id]
  );
  res.json({ ok: true });
});

router.delete('/gold-assets/:id', async (req, res) => {
  await pool.query('DELETE FROM gold_assets WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
});
