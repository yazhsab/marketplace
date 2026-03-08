'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { type ColumnDef } from '@tanstack/react-table';
import { Check } from 'lucide-react';
import { apiGet, apiPost } from '@/lib/api-client';
import { formatCurrency, formatDate } from '@/lib/utils';
import { DataTable } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Select } from '@/components/ui/select';
import type { WalletTransaction, PaginationMeta } from '@/types';

export default function PayoutsPage() {
  const [page, setPage] = useState(1);
  const [sourceFilter, setSourceFilter] = useState<'all' | 'vendor' | 'delivery'>('all');
  const pageSize = 10;
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['payouts', page, sourceFilter],
    queryFn: () =>
      apiGet<WalletTransaction[]>(
        `/admin/payouts?page=${page}&per_page=${pageSize}&type=payout${sourceFilter !== 'all' ? `&source=${sourceFilter}` : ''}`
      ),
  });

  const approveMutation = useMutation({
    mutationFn: (transactionId: string) =>
      apiPost(`/admin/payouts/${transactionId}/approve`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['payouts'] });
    },
  });

  const columns: ColumnDef<WalletTransaction, unknown>[] = [
    {
      accessorKey: 'id',
      header: 'Transaction ID',
      cell: ({ row }) => (
        <span className="font-mono text-xs text-gray-600">
          {row.original.id.slice(0, 12)}...
        </span>
      ),
    },
    {
      id: 'source',
      header: 'Source',
      cell: ({ row }) => {
        const wallet = row.original.wallet;
        if (wallet?.delivery_partner_id) {
          return <Badge variant="info">Delivery Partner</Badge>;
        }
        return <Badge variant="indigo">Vendor</Badge>;
      },
    },
    {
      accessorKey: 'type',
      header: 'Type',
      cell: ({ row }) => (
        <span className="capitalize text-gray-700">
          {row.original.type.replace(/_/g, ' ')}
        </span>
      ),
    },
    {
      accessorKey: 'amount',
      header: 'Amount',
      cell: ({ row }) => (
        <span className="font-medium">{formatCurrency(row.original.amount)}</span>
      ),
    },
    {
      accessorKey: 'balance_after',
      header: 'Balance After',
      cell: ({ row }) => formatCurrency(row.original.balance_after),
    },
    {
      accessorKey: 'description',
      header: 'Description',
      cell: ({ row }) => (
        <span className="text-sm text-gray-600">
          {row.original.description || '-'}
        </span>
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
    {
      id: 'actions',
      header: 'Actions',
      enableSorting: false,
      cell: ({ row }) =>
        row.original.status === 'pending' ? (
          <Button
            variant="success"
            size="sm"
            onClick={() => approveMutation.mutate(row.original.id)}
            disabled={approveMutation.isPending}
          >
            <Check className="h-4 w-4" />
            Approve
          </Button>
        ) : null,
    },
  ];

  const payouts = data?.data || [];
  const meta = (data?.meta || { total_pages: 1 }) as PaginationMeta;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Payouts</h1>
        <Select
          value={sourceFilter}
          onChange={(e) => {
            setSourceFilter(e.target.value as 'all' | 'vendor' | 'delivery');
            setPage(1);
          }}
          className="w-48"
        >
          <option value="all">All Sources</option>
          <option value="vendor">Vendor Payouts</option>
          <option value="delivery">Delivery Partner Payouts</option>
        </Select>
      </div>

      <DataTable
        columns={columns}
        data={payouts}
        pageCount={meta.total_pages}
        page={page}
        onPageChange={setPage}
        pageSize={pageSize}
        isLoading={isLoading}
      />
    </div>
  );
}
