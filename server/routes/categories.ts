import { Router } from 'express';
import { pool } from '../db.js';

export const router = Router();

router.get('/categories', async (_req, res) => {
  const [rows] = await pool.query('SELECT id, name, type FROM categories ORDER BY type, name');
  res.json(rows);
});

router.post('/categories', async (req, res) => {
  const { id, name, type } = req.body;
  await pool.query('INSERT INTO categories (id, name, type) VALUES (?, ?, ?)', [id, name, type]);
  res.json({ id, name, type });
});

router.post('/categories/bulk', async (req, res) => {
  const categories: Array<{ id: string; name: string; type: string }> = req.body;
  if (!categories.length) return res.json({ inserted: 0 });
  const values = categories.map((c) => [c.id, c.name, c.type]);
  const [result] = await pool.query(
    'INSERT IGNORE INTO categories (id, name, type) VALUES ?',
    [values]
  ) as any;
  res.json({ inserted: result.affectedRows });
});

router.put('/categories/:id', async (req, res) => {
  const { name } = req.body;
  await pool.query('UPDATE categories SET name = ? WHERE id = ?', [name, req.params.id]);
  res.json({ ok: true });
});

router.delete('/categories/:id', async (req, res) => {
  await pool.query('DELETE FROM categories WHERE id = ?', [req.params.id]);
  res.json({ ok: true });
});
