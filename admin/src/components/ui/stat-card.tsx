import { type ReactNode } from 'react';
import { cn } from '@/lib/utils';
import { Card } from './card';

interface StatCardProps {
  icon: ReactNode;
  label: string;
  value: string | number;
  change?: string;
  changeType?: 'positive' | 'negative' | 'neutral';
}

export function StatCard({ icon, label, value, change, changeType = 'neutral' }: StatCardProps) {
  return (
    <Card className="p-6">
      <div className="flex items-start justify-between">
        <div className="space-y-2">
          <p className="text-sm font-medium text-gray-500">{label}</p>
          <p className="text-2xl font-bold text-gray-900">{value}</p>
          {change && (
            <p
              className={cn(
                'text-xs font-medium',
                changeType === 'positive' && 'text-green-600',
                changeType === 'negative' && 'text-red-600',
                changeType === 'neutral' && 'text-gray-500'
              )}
            >
              {change}
            </p>
          )}
        </div>
        <div className="rounded-lg bg-indigo-50 p-3 text-indigo-600">{icon}</div>
      </div>
    </Card>
  );
}
