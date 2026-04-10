import { Router } from 'express';
import { pool } from '../db.js';

export const router = Router();

/**
 * Lấy danh sách tất cả danh mục
 * Đảm bảo SELECT đủ icon và color để iOS không bị lỗi Decoding
 */
router.get('/categories', async (_req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, name, type, icon, color FROM categories ORDER BY type, name'
    );
    res.json(rows);
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ error: 'Database error' });
  }
});

/**
 * Thêm danh mục mới
 * Nhận id từ client gửi lên để tránh lỗi ER_BAD_NULL_ERROR
 */
router.post('/categories', async (req, res) => {
  const { id, name, type, icon, color } = req.body;

  // Kiểm tra các trường bắt buộc
  if (!id || !name || !type) {
    return res.status(400).json({ error: 'Missing required fields: id, name, or type' });
  }

  try {
    // Thực hiện INSERT đủ 5 tham số
    await pool.query(
      'INSERT INTO categories (id, name, type, icon, color) VALUES (?, ?, ?, ?, ?)',
      [
        id, 
        name, 
        type, 
        icon || 'tag.fill', // Giá trị mặc định nếu client không gửi
        color || 'accent'    // Giá trị mặc định nếu client không gửi
      ]
    );

    // Trả về đúng object vừa tạo để iOS decode thành công
    res.json({ 
      id, 
      name, 
      type, 
      icon: icon || 'tag.fill', 
      color: color || 'accent' 
    });
  } catch (error: any) {
    console.error('Error creating category:', error);
    res.status(500).json({ error: error.message || 'Database error' });
  }
});

/**
 * Cập nhật danh mục hiện có
 */
router.put('/categories/:id', async (req, res) => {
  const { name, icon, color } = req.body;
  const { id } = req.params;

  try {
    // 1. Thực hiện cập nhật
    await pool.query(
      'UPDATE categories SET name = ?, icon = ?, color = ? WHERE id = ?',
      [name, icon, color, id]
    );

    // 2. Lấy lại thông tin loại (type) vì client cần object Category hoàn chỉnh
    const [rows]: any = await pool.query('SELECT type FROM categories WHERE id = ?', [id]);
    if (rows.length === 0) return res.status(404).json({ error: 'Not found' });

    // 3. TRẢ VỀ ĐỦ 5 TRƯỜNG: Đây là phần quan trọng nhất để fix lỗi Decoding
    res.json({ 
      id, 
      name, 
      type: rows[0].type, 
      icon: icon || 'tag.fill', 
      color: color || 'accent' 
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Database error' });
  }
});

/**
 * Xóa danh mục
 */
router.delete('/categories/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM categories WHERE id = ?', [req.params.id]);
    res.json({ ok: true });
  } catch (error) {
    console.error('Error deleting category:', error);
    res.status(500).json({ error: 'Database error' });
  }
});