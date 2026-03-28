/**
 * One-shot migration: import a savemoney-backup-*.json into MySQL.
 *
 * Usage:
 *   npm run migrate -- --file savemoney-backup-2026-03-22.json
 *
 * Steps:
 *   1. Export backup from the app: Settings → Export .json
 *   2. Run this script with --file pointing to the backup file
 */

import * as fs from 'fs';
import { pool } from './db.js';

interface BackupTransaction {
  id: string;
  date: string;
  type: string;
  categoryId: string;
  accountId: string;
  transferToId: string;
  amount: number;
  note?: string;
}

interface Backup {
  version: number;
  transactions: BackupTransaction[];
  categories: Array<{ id: string; name: string; type: string }>;
  accounts: Array<{ id: string; name: string }>;
  accountBalances: Record<string, number>;
  defaults: {
    defaultCategoryExpenseId: string;
    defaultCategoryIncomeId: string;
    defaultAccountId: string;
  };
  budgets: Array<{ id: string; name: string; limit: number; dateStart: string; dateEnd: string; categoryIds: string[] }>;
  goldAssets?: Array<{ id: string; brand: string; productId?: string; productName: string; quantity: number; note?: string; createdAt: string }>;
}

async function migrate() {
  const fileArgIndex = process.argv.indexOf('--file');
  if (fileArgIndex === -1 || !process.argv[fileArgIndex + 1]) {
    console.error('Usage: npm run migrate -- --file <backup-file.json>');
    process.exit(1);
  }
  const filePath = process.argv[fileArgIndex + 1];

  if (!fs.existsSync(filePath)) {
    console.error(`File not found: ${filePath}`);
    process.exit(1);
  }

  const raw = fs.readFileSync(filePath, 'utf8');
  const backup: Backup = JSON.parse(raw);

  console.log(`Migrating backup v${backup.version}...`);
  console.log(`  Categories: ${backup.categories.length}`);
  console.log(`  Accounts: ${backup.accounts.length}`);
  console.log(`  Transactions: ${backup.transactions.length}`);
  console.log(`  Budgets: ${backup.budgets?.length ?? 0}`);
  console.log(`  Gold assets: ${backup.goldAssets?.length ?? 0}`);

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // Categories
    if (backup.categories.length) {
      const vals = backup.categories.map((c) => [c.id, c.name, c.type]);
      await conn.query('INSERT IGNORE INTO categories (id, name, type) VALUES ?', [vals]);
    }

    // Accounts
    if (backup.accounts.length) {
      const vals = backup.accounts.map((a) => [a.id, a.name]);
      await conn.query('INSERT IGNORE INTO accounts (id, name) VALUES ?', [vals]);
    }

    // Account balances
    const balEntries = Object.entries(backup.accountBalances ?? {});
    if (balEntries.length) {
      const vals = balEntries.map(([id, bal]) => [id, bal]);
      await conn.query(
        'INSERT INTO account_balances (account_id, balance) VALUES ? ON DUPLICATE KEY UPDATE balance = VALUES(balance)',
        [vals]
      );
    }

    // Transactions
    if (backup.transactions.length) {
      const vals = backup.transactions.map((t) => [
        t.id,
        t.date.slice(0, 10),
        t.type,
        t.categoryId || null,
        t.accountId,
        t.transferToId || null,
        t.amount,
        t.note || null,
      ]);
      await conn.query(
        'INSERT IGNORE INTO transactions (id, date, type, category_id, account_id, transfer_to_id, amount, note) VALUES ?',
        [vals]
      );
    }

    // Budgets + budget_categories
    for (const b of backup.budgets ?? []) {
      await conn.query(
        'INSERT IGNORE INTO budgets (id, name, limit_amount, date_start, date_end) VALUES (?, ?, ?, ?, ?)',
        [b.id, b.name, b.limit, b.dateStart, b.dateEnd]
      );
      const catIds: string[] = (b as any).categoryIds ?? (b as any).categories ?? [];
      if (catIds.length) {
        const catVals = catIds.map((cId) => [b.id, cId]);
        await conn.query('INSERT IGNORE INTO budget_categories (budget_id, category_id) VALUES ?', [catVals]);
      }
    }

    // Gold assets
    for (const a of backup.goldAssets ?? []) {
      await conn.query(
        'INSERT IGNORE INTO gold_assets (id, brand, product_id, product_name, quantity, note, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [a.id, a.brand, a.productId || null, a.productName, a.quantity, a.note || null, a.createdAt]
      );
    }

    // Settings
    const d = backup.defaults;
    if (d) {
      const settings = [
        ['defaultCategoryExpenseId', d.defaultCategoryExpenseId ?? ''],
        ['defaultCategoryIncomeId', d.defaultCategoryIncomeId ?? ''],
        ['defaultAccountId', d.defaultAccountId ?? ''],
      ];
      for (const [k, v] of settings) {
        await conn.query(
          'INSERT INTO user_settings (`key`, value) VALUES (?, ?) ON DUPLICATE KEY UPDATE value = ?',
          [k, v, v]
        );
      }
    }

    // Add note column to transactions if it doesn't exist (for existing databases)
    try {
      await conn.query('ALTER TABLE transactions ADD COLUMN note TEXT NULL');
      console.log('Added note column to transactions table');
    } catch (err: any) {
      if (err.code === 'ER_DUP_FIELDNAME') {
        console.log('note column already exists in transactions table');
      } else {
        throw err;
      }
    }

    await conn.commit();
    console.log('Migration complete!');
  } catch (err) {
    await conn.rollback();
    console.error('Migration failed:', err);
    process.exit(1);
  } finally {
    conn.release();
    await pool.end();
  }
}

migrate();
