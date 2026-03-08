'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { type ColumnDef } from '@tanstack/react-table';
import { Eye } from 'lucide-react';
import { apiGet } from '@/lib/api-client';
import { formatCurrency, formatDate } from '@/lib/utils';
import { cn } from '@/lib/utils';
import { DataTable } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import type { Order, OrderStatus, PaginationMeta } from '@/types';

const statusTabs: Array<{ label: string; value: OrderStatus | '' }> = [
  { label: 'All', value: '' },
  { label: 'Pending', value: 'pending' },
  { label: 'Confirmed', value: 'confirmed' },
  { label: 'Preparing', value: 'preparing' },
  { label: 'Delivered', value: 'delivered' },
  { label: 'Cancelled', value: 'cancelled' },
];

const columns: ColumnDef<Order, unknown>[] = [
  {
    accessorKey: 'order_number',
    header: 'Order Number',
    cell: ({ row }) => (
      <Link
        href={`/orders/${row.original.id}`}
        className="font-medium text-indigo-600 hover:text-indigo-700"
      >
        {row.original.order_number}
      </Link>
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
    id: 'items_count',
    header: 'Items',
    cell: ({ row }) => row.original.items?.length || 0,
  },
  {
    accessorKey: 'total_amount',
    header: 'Total',
    cell: ({ row }) => formatCurrency(row.original.total_amount),
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
  {
    id: 'actions',
    header: 'Actions',
    enableSorting: false,
    cell: ({ row }) => (
      <Link href={`/orders/${row.original.id}`}>
        <Button variant="ghost" size="sm">
          <Eye className="h-4 w-4" />
          View
        </Button>
      </Link>
    ),
  },
];

export default function OrdersPage() {
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState<OrderStatus | ''>('');
  const pageSize = 10;

  const { data, isLoading } = useQuery({
    queryKey: ['orders', page, statusFilter],
    queryFn: () =>
      apiGet<Order[]>(
        `/admin/orders?page=${page}&per_page=${pageSize}${statusFilter ? `&status=${statusFilter}` : ''}`
      ),
  });

  const orders = data?.data || [];
  const meta = (data?.meta || { total_pages: 1 }) as PaginationMeta;

  return (
    <div className="space-y-4">
      {/* Status tabs */}
      <div className="flex border-b border-gray-200">
        {statusTabs.map((tab) => (
          <button
            key={tab.value}
            className={cn(
              'border-b-2 px-4 py-2 text-sm font-medium',
              statusFilter === tab.value
                ? 'border-indigo-600 text-indigo-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            )}
            onClick={() => {
              setStatusFilter(tab.value);
              setPage(1);
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <DataTable
        columns={columns}
        data={orders}
        pageCount={meta.total_pages}
        page={page}
        onPageChange={setPage}
        pageSize={pageSize}
        isLoading={isLoading}
      />
    </div>
  );
}
