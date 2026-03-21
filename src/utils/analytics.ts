import { Transaction } from '../types';
import { toYYYYMM, toYYYYMMDD } from './formatters';

/** Only expense transactions (negative amounts, type=Expense) */
export function getExpenses(txs: Transaction[]): Transaction[] {
  return txs.filter((t) => t.type === 'Expense');
}

/** Expense + Income only (exclude Account/Transfer balance updates) */
export function getRelevant(txs: Transaction[]): Transaction[] {
  return txs.filter((t) => t.type === 'Expense' || t.type === 'Income');
}

/** Filter transactions to a period ('all' | 'YYYY-MM') */
export function filterByPeriod(txs: Transaction[], period: string): Transaction[] {
  if (period === 'all') return txs;
  return txs.filter((t) => toYYYYMM(t.date) === period);
}

/** Total spending (sum of absolute expense amounts) for a set of transactions */
export function getTotalSpending(txs: Transaction[]): number {
  return getExpenses(txs).reduce((sum, t) => sum + Math.abs(t.amount), 0);
}

/** Total income */
export function getTotalIncome(txs: Transaction[]): number {
  return txs
    .filter((t) => t.type === 'Income')
    .reduce((sum, t) => sum + Math.abs(t.amount), 0);
}

/** Average daily spending over the date range of the transactions */
export function getAvgDaily(txs: Transaction[]): number {
  const expenses = getExpenses(txs);
  if (expenses.length === 0) return 0;
  const dates = new Set(expenses.map((t) => toYYYYMMDD(t.date)));
  const days = dates.size || 1;
  return getTotalSpending(expenses) / days;
}

/** Category breakdown sorted by total descending */
export function getCategoryBreakdown(
  txs: Transaction[]
): { category: string; total: number; count: number; percent: number }[] {
  const expenses = getExpenses(txs);
  const total = getTotalSpending(expenses);
  const map: Record<string, { total: number; count: number }> = {};

  expenses.forEach((t) => {
    const abs = Math.abs(t.amount);
    if (!map[t.category]) map[t.category] = { total: 0, count: 0 };
    map[t.category].total += abs;
    map[t.category].count += 1;
  });

  return Object.entries(map)
    .map(([category, { total: catTotal, count }]) => ({
      category,
      total: catTotal,
      count,
      percent: total > 0 ? (catTotal / total) * 100 : 0,
    }))
    .sort((a, b) => b.total - a.total);
}

/** Daily spending trend — returns one entry per day with label and total amount */
export function getDailyTrend(
  txs: Transaction[]
): { date: string; amount: number }[] {
  const expenses = getExpenses(txs);
  const map: Record<string, number> = {};
  expenses.forEach((t) => {
    const key = toYYYYMMDD(t.date);
    map[key] = (map[key] || 0) + Math.abs(t.amount);
  });

  return Object.entries(map)
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([date, amount]) => ({ date, amount }));
}

const DAY_NAMES = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/** Spending by day of week */
export function getDayOfWeekBreakdown(
  txs: Transaction[]
): { day: string; amount: number; percent: number }[] {
  const expenses = getExpenses(txs);
  const totals = new Array(7).fill(0);
  expenses.forEach((t) => {
    totals[t.date.getDay()] += Math.abs(t.amount);
  });
  const max = Math.max(...totals, 1);
  // Reorder to Mon-Sun
  const order = [1, 2, 3, 4, 5, 6, 0];
  return order.map((dayIndex) => ({
    day: DAY_NAMES[dayIndex],
    amount: totals[dayIndex],
    percent: (totals[dayIndex] / max) * 100,
  }));
}

/** Calendar heatmap for a given YYYY-MM */
export function getCalendarHeatmap(
  txs: Transaction[],
  period: string // 'YYYY-MM'
): { day: number; date: string; amount: number; level: number }[] {
  const expenses = getExpenses(txs);
  const [yearStr, monthStr] = period.split('-');
  const year = parseInt(yearStr);
  const month = parseInt(monthStr);
  const daysInMonth = new Date(year, month, 0).getDate();
  const map: Record<string, number> = {};
  expenses
    .filter((t) => toYYYYMM(t.date) === period)
    .forEach((t) => {
      const key = toYYYYMMDD(t.date);
      map[key] = (map[key] || 0) + Math.abs(t.amount);
    });

  const amounts = Object.values(map);
  const max = amounts.length > 0 ? Math.max(...amounts) : 1;

  return Array.from({ length: daysInMonth }, (_, i) => {
    const day = i + 1;
    const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const amount = map[dateStr] || 0;
    const level = amount === 0 ? 0 : Math.ceil((amount / max) * 4);
    return { day, date: dateStr, amount, level };
  });
}

/** Account/payment method breakdown */
export function getAccountBreakdown(
  txs: Transaction[]
): { account: string; total: number; count: number; percent: number }[] {
  const expenses = getExpenses(txs);
  const map: Record<string, { total: number; count: number }> = {};
  expenses.forEach((t) => {
    if (!map[t.account]) map[t.account] = { total: 0, count: 0 };
    map[t.account].total += Math.abs(t.amount);
    map[t.account].count += 1;
  });
  const total = getTotalSpending(expenses);
  return Object.entries(map)
    .map(([account, { total: accTotal, count }]) => ({
      account,
      total: accTotal,
      count,
      percent: total > 0 ? (accTotal / total) * 100 : 0,
    }))
    .sort((a, b) => b.total - a.total);
}

/** Top N spending days (by total spending on that date) */
export function getTopSpendingDays(
  txs: Transaction[],
  n = 5
): { date: string; total: number; categories: string }[] {
  const expenses = getExpenses(txs);
  const map: Record<string, { total: number; cats: Set<string> }> = {};
  expenses.forEach((t) => {
    const key = toYYYYMMDD(t.date);
    if (!map[key]) map[key] = { total: 0, cats: new Set() };
    map[key].total += Math.abs(t.amount);
    map[key].cats.add(t.category);
  });
  return Object.entries(map)
    .sort(([, a], [, b]) => b.total - a.total)
    .slice(0, n)
    .map(([date, { total, cats }]) => ({
      date,
      total,
      categories: Array.from(cats).join(', '),
    }));
}

/** Month-over-month comparison per category (top categories) */
export function getMonthlyComparison(
  txs: Transaction[],
  currentPeriod: string
): {
  category: string;
  current: number;
  previous: number;
  changePercent: number;
  trend: 'up' | 'down' | 'flat';
}[] {
  const [year, month] = currentPeriod.split('-').map(Number);
  const prevDate = new Date(year, month - 2, 1);
  const prevPeriod = toYYYYMM(prevDate);

  const current = getCategoryBreakdown(filterByPeriod(getExpenses(txs), currentPeriod));
  const previous = getCategoryBreakdown(filterByPeriod(getExpenses(txs), prevPeriod));

  const prevMap: Record<string, number> = {};
  previous.forEach((c) => (prevMap[c.category] = c.total));

  return current.slice(0, 6).map((c) => {
    const prev = prevMap[c.category] || 0;
    const changePercent = prev > 0 ? ((c.total - prev) / prev) * 100 : 100;
    const trend: 'up' | 'down' | 'flat' =
      changePercent > 2 ? 'up' : changePercent < -2 ? 'down' : 'flat';
    return { category: c.category, current: c.total, previous: prev, changePercent, trend };
  });
}

/** Category × month spending matrix for a date range */
export function getCategoryMonthMatrix(
  txs: Transaction[],
  fromPeriod: string,
  toPeriod: string
): { month: string; [category: string]: number | string }[] {
  // Build sorted list of all YYYY-MM in range
  const allPeriods = getAvailablePeriods(txs).filter(
    (p) => p >= fromPeriod && p <= toPeriod
  ).reverse(); // chronological order

  // Collect all categories in range
  const rangeTxs = txs.filter((t) => {
    const p = toYYYYMM(t.date);
    return p >= fromPeriod && p <= toPeriod;
  });
  const allCats = getCategoryBreakdown(getExpenses(rangeTxs)).map((c) => c.category);

  return allPeriods.map((p) => {
    const periodTxs = filterByPeriod(txs, p);
    const bd = getCategoryBreakdown(getExpenses(periodTxs));
    const bdMap: Record<string, number> = {};
    bd.forEach((c) => (bdMap[c.category] = c.total));

    const row: { month: string; [key: string]: number | string } = { month: p };
    allCats.forEach((cat) => {
      row[cat] = bdMap[cat] || 0;
    });
    return row;
  });
}

/** Get sorted list of available periods (YYYY-MM) from transactions */
export function getAvailablePeriods(txs: Transaction[]): string[] {
  const set = new Set(txs.map((t) => toYYYYMM(t.date)));
  return Array.from(set).sort().reverse();
}

/** Account spending by week within a period */
export function getAccountByWeek(
  txs: Transaction[],
  period: string
): { week: string; [account: string]: number | string }[] {
  const expenses = filterByPeriod(getExpenses(txs), period);
  const weeks: { week: string; [account: string]: number | string }[] = [
    { week: 'Week 1' },
    { week: 'Week 2' },
    { week: 'Week 3' },
    { week: 'Week 4' },
  ];

  expenses.forEach((t) => {
    const day = t.date.getDate();
    const weekIdx = Math.min(Math.floor((day - 1) / 7), 3);
    const acc = t.account;
    if (weeks[weekIdx][acc] === undefined) weeks[weekIdx][acc] = 0;
    (weeks[weekIdx][acc] as number) += Math.abs(t.amount);
  });

  // Fill missing accounts with 0
  const accounts = [...new Set(expenses.map((t) => t.account))];
  weeks.forEach((w) => {
    accounts.forEach((acc) => {
      if (w[acc] === undefined) w[acc] = 0;
    });
  });

  return weeks;
}
