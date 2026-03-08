'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { type ColumnDef } from '@tanstack/react-table';
import { apiGet } from '@/lib/api-client';
import { formatCurrency, formatDate, truncateText } from '@/lib/utils';
import { DataTable } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import type { Payment, PaginationMeta } from '@/types';

const methodVariantMap: Record<string, 'default' | 'success' | 'warning' | 'danger' | 'info' | 'indigo'> = {
  razorpay: 'indigo',
  wallet: 'info',
  cod: 'warning',
  upi: 'success',
  card: 'default',
  net_banking: 'default',
};

const columns: ColumnDef<Payment, unknown>[] = [
  {
    accessorKey: 'id',
    header: 'Payment ID',
    cell: ({ row }) => (
      <span className="font-mono text-xs text-gray-600">
        {truncateText(row.original.id, 12)}
      </span>
    ),
  },
  {
    id: 'type',
    header: 'Type',
    cell: ({ row }) => (
      <Badge variant={row.original.order_id ? 'indigo' : 'info'}>
        {row.original.order_id ? 'Order' : 'Booking'}
      </Badge>
    ),
  },
  {
    accessorKey: 'customer',
    header: 'Customer',
    enableSorting: false,
    cell: ({ row }) =>
      row.original.customer
        ? `${row.original.customer.first_name} ${row.original.customer.last_name}`
        : '-',
  },
  {
    accessorKey: 'vendor',
    header: 'Vendor',
    enableSorting: false,
    cell: ({ row }) => row.original.vendor?.business_name || '-',
  },
  {
    accessorKey: 'amount',
    header: 'Amount',
    cell: ({ row }) => (
      <span className="font-medium">{formatCurrency(row.original.amount)}</span>
    ),
  },
  {
    accessorKey: 'method',
    header: 'Method',
    cell: ({ row }) => (
      <Badge variant={methodVariantMap[row.original.method] || 'default'}>
        {row.original.method.toUpperCase()}
      </Badge>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => <StatusBadge status={row.original.status} />,
  },
  {
    accessorKey: 'created_at',
    header: 'Date',
    cell: ({ row }) => formatDate(row.original.created_at),
  },
];

export default function PaymentsPage() {
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const { data, isLoading } = useQuery({
    queryKey: ['payments', page],
    queryFn: () =>
      apiGet<Payment[]>(`/admin/payments?page=${page}&per_page=${pageSize}`),
  });

  const payments = data?.data || [];
  const meta = (data?.meta || { total_pages: 1 }) as PaginationMeta;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-end">
        <Link href="/payments/payouts">
          <Button variant="outline">Payout Requests</Button>
        </Link>
      </div>

      <DataTable
        columns={columns}
        data={payments}
        pageCount={meta.total_pages}
        page={page}
        onPageChange={setPage}
        pageSize={pageSize}
        isLoading={isLoading}
      />
    </div>
  );
}
