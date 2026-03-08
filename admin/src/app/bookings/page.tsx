'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { type ColumnDef } from '@tanstack/react-table';
import { Eye } from 'lucide-react';
import { apiGet } from '@/lib/api-client';
import { formatCurrency, formatDate } from '@/lib/utils';
import { DataTable } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import type { Booking, PaginationMeta } from '@/types';

const columns: ColumnDef<Booking, unknown>[] = [
  {
    accessorKey: 'booking_number',
    header: 'Booking Number',
    cell: ({ row }) => (
      <Link
        href={`/bookings/${row.original.id}`}
        className="font-medium text-indigo-600 hover:text-indigo-700"
      >
        {row.original.booking_number}
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
    accessorKey: 'service',
    header: 'Service',
    enableSorting: false,
    cell: ({ row }) => row.original.service?.name || '-',
  },
  {
    accessorKey: 'vendor',
    header: 'Vendor',
    enableSorting: false,
    cell: ({ row }) => row.original.vendor?.business_name || '-',
  },
  {
    accessorKey: 'booking_date',
    header: 'Date/Time',
    cell: ({ row }) => (
      <div>
        <p className="text-sm">{formatDate(row.original.booking_date)}</p>
        <p className="text-xs text-gray-500">
          {row.original.start_time} - {row.original.end_time}
        </p>
      </div>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => <StatusBadge status={row.original.status} />,
  },
  {
    accessorKey: 'total_amount',
    header: 'Total',
    cell: ({ row }) => formatCurrency(row.original.total_amount),
  },
  {
    id: 'actions',
    header: 'Actions',
    enableSorting: false,
    cell: ({ row }) => (
      <Link href={`/bookings/${row.original.id}`}>
        <Button variant="ghost" size="sm">
          <Eye className="h-4 w-4" />
        </Button>
      </Link>
    ),
  },
];

export default function BookingsPage() {
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const { data, isLoading } = useQuery({
    queryKey: ['bookings', page],
    queryFn: () =>
      apiGet<Booking[]>(`/admin/bookings?page=${page}&per_page=${pageSize}`),
  });

  const bookings = data?.data || [];
  const meta = (data?.meta || { total_pages: 1 }) as PaginationMeta;

  return (
    <div className="space-y-4">
      <DataTable
        columns={columns}
        data={bookings}
        pageCount={meta.total_pages}
        page={page}
        onPageChange={setPage}
        pageSize={pageSize}
        isLoading={isLoading}
      />
    </div>
  );
}
