import { Account, Category, Transaction, TransactionType } from '../types';
import { getCategoryIdByName, getAccountIdByName } from './lookup';
import { toYYYYMMDD } from './formatters';

export interface ParseCSVResult {
  transactions: Transaction[];
  newCategories: Category[];
  newAccounts: Account[];
}

export function parseCSV(
  text: string,
  existingCategories: Category[],
  existingAccounts: Account[]
): ParseCSVResult {
  const lines = text.trim().split('\n');
  if (lines.length < 2) return { transactions: [], newCategories: [], newAccounts: [] };

  const dataLines = lines.slice(1);
  const transactions: Transaction[] = [];
  const newCategories: Category[] = [];
  const newAccounts: Account[] = [];

  // Working copies — extended as new items are found
  const categories = [...existingCategories];
  const accounts = [...existingAccounts];

  function resolveCategory(name: string, type: 'Expense' | 'Income'): string {
    const trimmed = name.trim() || 'Other';
    let id = getCategoryIdByName(categories, trimmed);
    if (!id) {
      const cat: Category = { id: crypto.randomUUID(), name: trimmed, type };
      categories.push(cat);
      newCategories.push(cat);
      id = cat.id;
    }
    return id;
  }

  function resolveAccount(name: string): string {
    const trimmed = name.trim();
    if (!trimmed) return '';
    let id = getAccountIdByName(accounts, trimmed);
    if (!id) {
      const acc: Account = { id: crypto.randomUUID(), name: trimmed };
      accounts.push(acc);
      newAccounts.push(acc);
      id = acc.id;
    }
    return id;
  }

  dataLines.forEach((line, index) => {
    const cols = line.split(',').map((c) => c.trim());
    if (cols.length < 6) return;

    const [dateStr, typeStr, categoryName, accountName, transferToName, amountStr] = cols;

    // Parse date-only strings (YYYY-MM-DD) as local midnight to avoid UTC day-shift
    const normalized = /^\d{4}-\d{2}-\d{2}$/.test(dateStr.trim())
      ? dateStr.trim() + 'T00:00:00'
      : dateStr.trim();
    const date = new Date(normalized);
    if (isNaN(date.getTime())) return;

    const type = typeStr as TransactionType;
    const amount = parseFloat(amountStr.replace(/\s/g, ''));
    if (isNaN(amount)) return;

    const catType: 'Expense' | 'Income' = type === 'Income' ? 'Income' : 'Expense';
    const categoryId = resolveCategory(categoryName, catType);
    const accountId = resolveAccount(accountName);
    const transferToId = resolveAccount(transferToName);

    transactions.push({
      id: `tx-${index}-${date.getTime()}`,
      date,
      type,
      categoryId,
      accountId,
      transferToId,
      amount,
    });
  });

  return { transactions, newCategories, newAccounts };
}

export function exportCSV(
  transactions: Transaction[],
  categories: Category[],
  accounts: Account[]
): string {
  const catMap = new Map(categories.map((c) => [c.id, c.name]));
  const accMap = new Map(accounts.map((a) => [a.id, a.name]));

  const header = 'Date, Transaction Type, Category, Account, Transfer To, Amount';
  const rows = transactions.map((tx) => {
    const dateStr = toYYYYMMDD(tx.date);
    const amountStr = tx.amount >= 0 ? `+${tx.amount}` : `${tx.amount}`;
    const category = catMap.get(tx.categoryId) ?? tx.categoryId;
    const account = accMap.get(tx.accountId) ?? tx.accountId;
    const transferTo = tx.transferToId ? (accMap.get(tx.transferToId) ?? tx.transferToId) : '';
    return [dateStr, tx.type, category, account, transferTo, amountStr].join(', ');
  });
  return [header, ...rows].join('\n');
}
