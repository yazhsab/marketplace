'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { type ColumnDef } from '@tanstack/react-table';
import { Star, Trash2 } from 'lucide-react';
import { apiGet, apiDelete } from '@/lib/api-client';
import { formatDate, truncateText } from '@/lib/utils';
import { DataTable } from '@/components/ui/data-table';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import type { Review, PaginationMeta } from '@/types';

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-0.5">
      {Array.from({ length: 5 }).map((_, i) => (
        <Star
          key={i}
          className={`h-4 w-4 ${
            i < rating
              ? 'fill-yellow-400 text-yellow-400'
              : 'fill-gray-200 text-gray-200'
          }`}
        />
      ))}
    </div>
  );
}

export default function ReviewsPage() {
  const [page, setPage] = useState(1);
  const pageSize = 10;
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['reviews', page],
    queryFn: () =>
      apiGet<Review[]>(`/admin/reviews?page=${page}&per_page=${pageSize}`),
  });

  const deleteMutation = useMutation({
    mutationFn: (reviewId: string) => apiDelete(`/admin/reviews/${reviewId}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['reviews'] });
    },
  });

  const columns: ColumnDef<Review, unknown>[] = [
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
      id: 'type',
      header: 'Type',
      cell: ({ row }) => (
        <Badge variant={row.original.product_id ? 'indigo' : 'info'}>
          {row.original.product_id ? 'Product' : 'Service'}
        </Badge>
      ),
    },
    {
      accessorKey: 'rating',
      header: 'Rating',
      cell: ({ row }) => <StarRating rating={row.original.rating} />,
    },
    {
      accessorKey: 'comment',
      header: 'Comment',
      enableSorting: false,
      cell: ({ row }) => (
        <span className="text-sm text-gray-600">
          {row.original.comment ? truncateText(row.original.comment, 60) : '-'}
        </span>
      ),
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
        <Button
          variant="ghost"
          size="sm"
          className="text-red-500 hover:text-red-700"
          onClick={() => {
            if (window.confirm('Are you sure you want to delete this review?')) {
              deleteMutation.mutate(row.original.id);
            }
          }}
          disabled={deleteMutation.isPending}
        >
          <Trash2 className="h-4 w-4" />
        </Button>
      ),
    },
  ];

  const reviews = data?.data || [];
  const meta = (data?.meta || { total_pages: 1 }) as PaginationMeta;

  return (
    <div className="space-y-4">
      <DataTable
        columns={columns}
        data={reviews}
        pageCount={meta.total_pages}
        page={page}
        onPageChange={setPage}
        pageSize={pageSize}
        isLoading={isLoading}
      />
    </div>
  );
}
