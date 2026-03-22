import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  ResponsiveContainer,
  CartesianGrid,
} from 'recharts';
import type { GoldBrand } from '../types';
import { formatVNDShort } from '../utils/formatters';
import type { HistoryDataPoint, WorldRefPoint } from '../services/goldHistoryService';

export interface ChartSeries {
  productId: string;
  label: string;
  brand: GoldBrand;
  data: HistoryDataPoint[];
}

interface GoldPriceChartProps {
  series: ChartSeries[];
  worldSeries: WorldRefPoint[];
}

const BRAND_COLORS: Record<string, string[]> = {
  SJC: ['#ef4444', '#dc2626', '#b91c1c', '#f87171', '#fca5a5'],
  BTMC: ['#3b82f6', '#2563eb', '#1d4ed8', '#60a5fa', '#93c5fd'],
  world: ['#f59e0b', '#d97706'],
};

function getBrandColor(brand: GoldBrand, idx: number): string {
  const palette = BRAND_COLORS[brand] ?? ['#6b7280'];
  return palette[idx % palette.length];
}

// Merge all series onto a unified date axis
function buildChartData(
  series: ChartSeries[],
  worldSeries: WorldRefPoint[]
): Record<string, number | string>[] {
  const dateSet = new Set<string>();

  series.forEach(s => s.data.forEach(d => dateSet.add(d.date)));
  worldSeries.forEach(w => dateSet.add(w.date));

  const dates = Array.from(dateSet).sort();

  return dates.map(date => {
    const row: Record<string, number | string> = { date };
    series.forEach(s => {
      const point = s.data.find(d => d.date === date);
      if (point) row[`${s.productId}_buy`] = point.buyPrice;
    });
    const wp = worldSeries.find(w => w.date === date);
    if (wp) row['world_spot_ref'] = wp.spotPerLuong;
    return row;
  });
}

function formatDateLabel(date: string): string {
  // 'YYYY-MM-DD' → 'DD/MM'
  const parts = date.split('-');
  if (parts.length !== 3) return date;
  return `${parts[2]}/${parts[1]}`;
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: Array<{ name: string; value: number; color: string }>;
  label?: string;
}

function CustomTooltip({ active, payload, label }: CustomTooltipProps) {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-gray-900 border border-gray-700 rounded-lg p-3 text-sm shadow-xl">
      <p className="text-gray-400 mb-2 font-medium">{label}</p>
      {payload.map((entry) => (
        <div key={entry.name} className="flex items-center gap-2 mb-1">
          <span className="w-2 h-2 rounded-full flex-shrink-0" style={{ backgroundColor: entry.color }} />
          <span className="text-gray-300 truncate max-w-[160px]">{entry.name}:</span>
          <span className="text-white font-medium ml-auto pl-2">{formatVNDShort(entry.value)}</span>
        </div>
      ))}
    </div>
  );
}

export default function GoldPriceChart({ series, worldSeries }: GoldPriceChartProps) {
  if (series.length === 0 && worldSeries.length === 0) {
    return (
      <div className="flex items-center justify-center h-48 text-gray-500 text-sm">
        Chọn loại vàng để xem biểu đồ
      </div>
    );
  }

  const chartData = buildChartData(series, worldSeries);

  if (chartData.length === 0) {
    return (
      <div className="flex items-center justify-center h-48 text-gray-500 text-sm">
        Chưa có dữ liệu lịch sử cho giai đoạn này
      </div>
    );
  }

  // Group series by brand for color indexing
  const brandCount: Record<string, number> = {};

  return (
    <ResponsiveContainer width="100%" height={320}>
      <LineChart data={chartData} margin={{ top: 8, right: 16, left: 8, bottom: 8 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
        <XAxis
          dataKey="date"
          tickFormatter={formatDateLabel}
          tick={{ fill: '#9ca3af', fontSize: 11 }}
          tickLine={false}
          axisLine={{ stroke: '#374151' }}
          interval="preserveStartEnd"
        />
        <YAxis
          tickFormatter={(v: number) => formatVNDShort(v)}
          tick={{ fill: '#9ca3af', fontSize: 11 }}
          tickLine={false}
          axisLine={false}
          width={72}
        />
        <Tooltip content={<CustomTooltip />} />
        <Legend
          wrapperStyle={{ fontSize: 12, color: '#d1d5db', paddingTop: 8 }}
          formatter={(value) => <span style={{ color: '#d1d5db' }}>{value}</span>}
        />

        {series.map(s => {
          brandCount[s.brand] = (brandCount[s.brand] ?? 0);
          const colorIdx = brandCount[s.brand]++;
          const color = getBrandColor(s.brand, colorIdx);
          return (
            <Line
              key={s.productId}
              type="monotone"
              dataKey={`${s.productId}_buy`}
              name={s.label}
              stroke={color}
              strokeWidth={2}
              dot={false}
              connectNulls
            />
          );
        })}

        {worldSeries.length > 0 && (
          <Line
            type="monotone"
            dataKey="world_spot_ref"
            name="Vàng TG (Spot)"
            stroke="#f59e0b"
            strokeWidth={1.5}
            strokeDasharray="5 3"
            dot={false}
            connectNulls
          />
        )}
      </LineChart>
    </ResponsiveContainer>
  );
}
