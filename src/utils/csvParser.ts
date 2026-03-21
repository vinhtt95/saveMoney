import { Transaction, TransactionType } from '../types';

export function parseCSV(text: string): Transaction[] {
  const lines = text.trim().split('\n');
  if (lines.length < 2) return [];

  // Skip header row
  const dataLines = lines.slice(1);
  const transactions: Transaction[] = [];

  dataLines.forEach((line, index) => {
    const cols = line.split(',').map((c) => c.trim());
    if (cols.length < 6) return;

    const [dateStr, typeStr, category, account, transferTo, amountStr] = cols;

    const date = new Date(dateStr);
    if (isNaN(date.getTime())) return;

    const type = typeStr as TransactionType;
    const amount = parseFloat(amountStr.replace(/\s/g, ''));
    if (isNaN(amount)) return;

    transactions.push({
      id: `tx-${index}-${date.getTime()}`,
      date,
      type,
      category: category || 'Other',
      account: account || '',
      transferTo: transferTo || '',
      amount,
    });
  });

  return transactions;
}

export function exportCSV(transactions: Transaction[]): string {
  const header = 'Date, Transaction Type, Category, Account, Transfer To, Amount';
  const rows = transactions.map((tx) => {
    const dateStr = tx.date.toISOString();
    const amountStr = tx.amount >= 0 ? `+${tx.amount}` : `${tx.amount}`;
    return [dateStr, tx.type, tx.category, tx.account, tx.transferTo, amountStr].join(', ');
  });
  return [header, ...rows].join('\n');
}
