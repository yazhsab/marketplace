'use client';

import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Cell,
} from 'recharts';

interface OrderChartProps {
  data: Array<{ status: string; count: number }>;
}

const STATUS_COLORS: Record<string, string> = {
  pending: '#F59E0B',
  confirmed: '#10B981',
  preparing: '#3B82F6',
  ready: '#6366F1',
  out_for_delivery: '#8B5CF6',
  delivered: '#059669',
  cancelled: '#EF4444',
  refunded: '#F97316',
};

export function OrderChart({ data }: OrderChartProps) {
  return (
    <div className="h-80 w-full">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart data={data} margin={{ top: 5, right: 20, left: 10, bottom: 5 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" vertical={false} />
          <XAxis
            dataKey="status"
            tick={{ fontSize: 12, fill: '#6B7280' }}
            tickLine={false}
            axisLine={{ stroke: '#E5E7EB' }}
            tickFormatter={(value: string) =>
              value.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
            }
          />
          <YAxis
            tick={{ fontSize: 12, fill: '#6B7280' }}
            tickLine={false}
            axisLine={{ stroke: '#E5E7EB' }}
            allowDecimals={false}
          />
          <Tooltip
            labelFormatter={(label) =>
              String(label).replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
            }
            contentStyle={{
              backgroundColor: '#fff',
              border: '1px solid #E5E7EB',
              borderRadius: '8px',
              boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
            }}
          />
          <Bar dataKey="count" radius={[4, 4, 0, 0]} barSize={40}>
            {data.map((entry, index) => (
              <Cell
                key={`cell-${index}`}
                fill={STATUS_COLORS[entry.status] || '#6B7280'}
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
