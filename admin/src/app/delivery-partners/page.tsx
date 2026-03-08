'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { type ColumnDef } from '@tanstack/react-table';
import { Eye, Star, CheckCircle, XCircle } from 'lucide-react';
import { apiGet, apiPut } from '@/lib/api-client';
import { DataTable } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Badge } from '@/components/ui/badge';
import { Select } from '@/components/ui/select';
import { Button } from '@/components/ui/button';
import type { DeliveryPartner, PaginationMeta } from '@/types';

function ActionsCell({ partner }: { partner: DeliveryPartner }) {
  const queryClient = useQueryClient();

  const updateStatus = useMutation({
    mutationFn: (status: string) =>
      apiPut(`/admin/delivery-partners/${partner.id}/status`, { status }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['delivery-partners'] });
    },
  });

  return (
    <div className="flex items-center gap-1">
      <Link href={`/delivery-partners/${partner.id}`}>
        <Button variant="ghost" size="sm">
          <Eye className="h-4 w-4" />
        </Button>
      </Link>
      {partner.status === 'pending' && (
        <>
          <Button
            variant="ghost"
            size="sm"
            className="text-green-600 hover:text-green-700"
            onClick={() => updateStatus.mutate('approved')}
            disabled={updateStatus.isPending}
          >
            <CheckCircle className="h-4 w-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="text-red-600 hover:text-red-700"
            onClick={() => updateStatus.mutate('rejected')}
            disabled={updateStatus.isPending}
          >
            <XCircle className="h-4 w-4" />
          </Button>
        </>
      )}
    </div>
  );
}

const columns: ColumnDef<DeliveryPartner, unknown>[] = [
  {
    accessorKey: 'user',
    header: 'Partner',
    cell: ({ row }) => (
      <Link
        href={`/delivery-partners/${row.original.id}`}
        className="font-medium text-indigo-600 hover:text-indigo-700"
      >
        {row.original.user?.first_name} {row.original.user?.last_name}
      </Link>
    ),
  },
  {
    accessorKey: 'vehicle_type',
    header: 'Vehicle',
    cell: ({ row }) => (
      <Badge variant="indigo">
        {row.original.vehicle_type.charAt(0).toUpperCase() + row.original.vehicle_type.slice(1)}
      </Badge>
    ),
  },
  {
    accessorKey: 'vehicle_number',
    header: 'Vehicle No.',
    cell: ({ row }) => row.original.vehicle_number || '-',
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => <StatusBadge status={row.original.status} />,
  },
  {
    accessorKey: 'is_available',
    header: 'Available',
    cell: ({ row }) => (
      <span className={`inline-flex items-center gap-1 text-sm ${row.original.is_available ? 'text-green-600' : 'text-gray-400'}`}>
        <span className={`h-2 w-2 rounded-full ${row.original.is_available ? 'bg-green-500' : 'bg-gray-300'}`} />
        {row.original.is_available ? 'Yes' : 'No'}
      </span>
    ),
  },
  {
    accessorKey: 'total_deliveries',
    header: 'Deliveries',
  },
  {
    accessorKey: 'avg_rating',
    header: 'Rating',
    cell: ({ row }) => (
      <div className="flex items-center gap-1">
        <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
        <span>{row.original.avg_rating.toFixed(1)}</span>
      </div>
    ),
  },
  {
    id: 'actions',
    header: 'Actions',
    cell: ({ row }) => <ActionsCell partner={row.original} />,
  },
];

export default function DeliveryPartnersPage() {
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const pageSize = 10;

  const { data, isLoading } = useQuery({
    queryKey: ['delivery-partners', page, statusFilter],
    queryFn: () =>
      apiGet<DeliveryPartner[]>(
        `/admin/delivery-partners?page=${page}&per_page=${pageSize}${statusFilter ? `&status=${statusFilter}` : ''}`
      ),
  });

  const partners = data?.data || [];
  const meta = (data?.meta || { total_pages: 1 }) as PaginationMeta;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Delivery Partners</h1>
        <Select
          value={statusFilter}
          onChange={(e) => {
            setStatusFilter(e.target.value);
            setPage(1);
          }}
          className="w-40"
        >
          <option value="">All Status</option>
          <option value="pending">Pending</option>
          <option value="approved">Approved</option>
          <option value="rejected">Rejected</option>
          <option value="suspended">Suspended</option>
        </Select>
      </div>

      <DataTable
        columns={columns}
        data={partners}
        pageCount={meta.total_pages}
        page={page}
        onPageChange={setPage}
        pageSize={pageSize}
        isLoading={isLoading}
      />
    </div>
  );
}
