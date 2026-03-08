'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { type ColumnDef } from '@tanstack/react-table';
import { Star, Clock } from 'lucide-react';
import { apiGet } from '@/lib/api-client';
import { formatCurrency } from '@/lib/utils';
import { DataTable } from '@/components/ui/data-table';
import { Input } from '@/components/ui/input';
import type { Service, PaginationMeta } from '@/types';

const columns: ColumnDef<Service, unknown>[] = [
  {
    accessorKey: 'name',
    header: 'Name',
    cell: ({ row }) => (
      <span className="font-medium text-gray-900">{row.original.name}</span>
    ),
  },
  {
    accessorKey: 'vendor.business_name',
    header: 'Vendor',
    enableSorting: false,
    cell: ({ row }) => row.original.vendor?.business_name || '-',
  },
  {
    accessorKey: 'category.name',
    header: 'Category',
    enableSorting: false,
    cell: ({ row }) => row.original.category?.name || '-',
  },
  {
    accessorKey: 'price',
    header: 'Price',
    cell: ({ row }) => formatCurrency(row.original.price),
  },
  {
    accessorKey: 'duration_minutes',
    header: 'Duration',
    cell: ({ row }) => (
      <div className="flex items-center gap-1 text-gray-600">
        <Clock className="h-3.5 w-3.5" />
        <span>{row.original.duration_minutes} min</span>
      </div>
    ),
  },
  {
    accessorKey: 'rating',
    header: 'Rating',
    cell: ({ row }) => (
      <div className="flex items-center gap-1">
        <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
        <span>{row.original.rating.toFixed(1)}</span>
      </div>
    ),
  },
];

export default function ServicesPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const pageSize = 10;

  const { data, isLoading } = useQuery({
    queryKey: ['services', page, search],
    queryFn: () =>
      apiGet<Service[]>(
        `/admin/services?page=${page}&per_page=${pageSize}${search ? `&search=${search}` : ''}`
      ),
  });

  const services = data?.data || [];
  const meta = (data?.meta || { total_pages: 1 }) as PaginationMeta;

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <Input
          placeholder="Search services..."
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
          className="w-64"
        />
      </div>

      <DataTable
        columns={columns}
        data={services}
        pageCount={meta.total_pages}
        page={page}
        onPageChange={setPage}
        pageSize={pageSize}
        isLoading={isLoading}
      />
    </div>
  );
}
