export function formatVND(amount: number): string {
  const abs = Math.abs(Math.round(amount));
  return abs.toLocaleString('vi-VN') + ' VND';
}

export function formatVNDShort(amount: number): string {
  const abs = Math.abs(amount);
  if (abs >= 1_000_000_000) return (abs / 1_000_000_000).toFixed(1) + 'B VND';
  if (abs >= 1_000_000) return (abs / 1_000_000).toFixed(1) + 'M VND';
  if (abs >= 1_000) return (abs / 1_000).toFixed(0) + 'K VND';
  return abs.toLocaleString('vi-VN') + ' VND';
}

export function formatDate(date: Date): string {
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

export function formatDateShort(date: Date): string {
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

export function formatMonth(yyyyMM: string): string {
  if (yyyyMM === 'all') return 'All Time';
  const [year, month] = yyyyMM.split('-');
  const date = new Date(parseInt(year), parseInt(month) - 1, 1);
  return date.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
}

export function toYYYYMM(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  return `${y}-${m}`;
}

export function toYYYYMMDD(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}
