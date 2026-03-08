'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { type ColumnDef } from '@tanstack/react-table';
import { Plus, Eye } from 'lucide-react';
import { apiGet, apiPost } from '@/lib/api-client';
import { DataTable } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Select } from '@/components/ui/select';
import { Button } from '@/components/ui/button';
import { InputField } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import type { DeliveryAssignment, PaginationMeta } from '@/types';

const columns: ColumnDef<DeliveryAssignment, unknown>[] = [
  {
    accessorKey: 'order_id',
    header: 'Order ID',
    cell: ({ row }) => (
      <Link
        href={`/orders/${row.original.order_id}`}
        className="font-mono text-sm text-indigo-600 hover:text-indigo-700"
      >
        {row.original.order_id.substring(0, 8)}...
      </Link>
    ),
  },
  {
    accessorKey: 'delivery_partner_id',
    header: 'Partner ID',
    cell: ({ row }) => (
      <Link
        href={`/delivery-partners/${row.original.delivery_partner_id}`}
        className="font-mono text-sm text-indigo-600 hover:text-indigo-700"
      >
        {row.original.delivery_partner_id.substring(0, 8)}...
      </Link>
    ),
  },
  {
    accessorKey: 'status',
    header: 'Status',
    cell: ({ row }) => <StatusBadge status={row.original.status} />,
  },
  {
    accessorKey: 'distance_km',
    header: 'Distance',
    cell: ({ row }) =>
      row.original.distance_km
        ? `${row.original.distance_km.toFixed(1)} km`
        : '-',
  },
  {
    accessorKey: 'earnings',
    header: 'Earnings',
    cell: ({ row }) =>
      row.original.earnings
        ? `\u20B9${row.original.earnings.toFixed(2)}`
        : '-',
  },
  {
    accessorKey: 'assigned_at',
    header: 'Assigned',
    cell: ({ row }) =>
      row.original.assigned_at
        ? new Date(row.original.assigned_at).toLocaleString()
        : '-',
  },
  {
    accessorKey: 'delivered_at',
    header: 'Delivered',
    cell: ({ row }) =>
      row.original.delivered_at
        ? new Date(row.original.delivered_at).toLocaleString()
        : '-',
  },
  {
    id: 'actions',
    header: 'Actions',
    cell: ({ row }) => (
      <Link href={`/orders/${row.original.order_id}`}>
        <Button variant="ghost" size="sm">
          <Eye className="h-4 w-4" />
        </Button>
      </Link>
    ),
  },
];

export default function DeliveryAssignmentsPage() {
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('');
  const [showAssignForm, setShowAssignForm] = useState(false);
  const [assignOrderId, setAssignOrderId] = useState('');
  const [assignPartnerId, setAssignPartnerId] = useState('');
  const pageSize = 10;
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['delivery-assignments', page, statusFilter],
    queryFn: () =>
      apiGet<DeliveryAssignment[]>(
        `/admin/delivery-assignments?page=${page}&per_page=${pageSize}${statusFilter ? `&status=${statusFilter}` : ''}`
      ),
  });

  const assignMutation = useMutation({
    mutationFn: (payload: { order_id: string; delivery_partner_id: string }) =>
      apiPost('/admin/delivery-assignments/assign', payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['delivery-assignments'] });
      setShowAssignForm(false);
      setAssignOrderId('');
      setAssignPartnerId('');
    },
  });

  const assignments = data?.data || [];
  const meta = (data?.meta || { total_pages: 1 }) as PaginationMeta;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Delivery Assignments</h1>
        <div className="flex items-center gap-3">
          <Select
            value={statusFilter}
            onChange={(e) => {
              setStatusFilter(e.target.value);
              setPage(1);
            }}
            className="w-40"
          >
            <option value="">All Status</option>
            <option value="assigned">Assigned</option>
            <option value="accepted">Accepted</option>
            <option value="picked_up">Picked Up</option>
            <option value="delivered">Delivered</option>
            <option value="rejected">Rejected</option>
            <option value="cancelled">Cancelled</option>
          </Select>
          <Button onClick={() => setShowAssignForm(!showAssignForm)}>
            <Plus className="h-4 w-4 mr-1" />
            Manual Assign
          </Button>
        </div>
      </div>

      {/* Manual Assign Form */}
      {showAssignForm && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Manual Assignment</CardTitle>
          </CardHeader>
          <CardContent>
            <form
              onSubmit={(e) => {
                e.preventDefault();
                if (assignOrderId && assignPartnerId) {
                  assignMutation.mutate({
                    order_id: assignOrderId,
                    delivery_partner_id: assignPartnerId,
                  });
                }
              }}
              className="flex items-end gap-3"
            >
              <div className="flex-1">
                <InputField
                  label="Order ID"
                  placeholder="Enter order UUID"
                  value={assignOrderId}
                  onChange={(e) => setAssignOrderId(e.target.value)}
                  required
                />
              </div>
              <div className="flex-1">
                <InputField
                  label="Delivery Partner ID"
                  placeholder="Enter partner UUID"
                  value={assignPartnerId}
                  onChange={(e) => setAssignPartnerId(e.target.value)}
                  required
                />
              </div>
              <div className="flex gap-2">
                <Button type="submit" disabled={assignMutation.isPending}>
                  {assignMutation.isPending ? 'Assigning...' : 'Assign'}
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => {
                    setShowAssignForm(false);
                    setAssignOrderId('');
                    setAssignPartnerId('');
                  }}
                >
                  Cancel
                </Button>
              </div>
            </form>
            {assignMutation.isError && (
              <p className="mt-2 text-sm text-red-600">
                Failed to create assignment. Please check the IDs and try again.
              </p>
            )}
          </CardContent>
        </Card>
      )}

      <DataTable
        columns={columns}
        data={assignments}
        pageCount={meta.total_pages}
        page={page}
        onPageChange={setPage}
        pageSize={pageSize}
        isLoading={isLoading}
      />
    </div>
  );
}
