'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { type ColumnDef } from '@tanstack/react-table';
import { Eye } from 'lucide-react';
import { apiGet } from '@/lib/api-client';
import { formatDate } from '@/lib/utils';
import { DataTable } from '@/components/ui/data-table';
import { StatusBadge } from '@/components/ui/status-badge';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Select } from '@/components/ui/select';
import type { User, UserRole, PaginationMeta } from '@/types';

const roleVariantMap: Record<string, 'default' | 'success' | 'warning' | 'danger' | 'info' | 'indigo'> = {
  admin: 'danger',
  vendor: 'indigo',
  customer: 'default',
  delivery_partner: 'info',
};

const columns: ColumnDef<User, unknown>[] = [
  {
    accessorKey: 'first_name',
    header: 'Name',
    cell: ({ row }) => (
      <Link
        href={`/users/${row.original.id}`}
        className="font-medium text-indigo-600 hover:text-indigo-700"
      >
        {row.original.first_name} {row.original.last_name}
      </Link>
    ),
  },
  {
    accessorKey: 'email',
    header: 'Email',
  },
  {
    accessorKey: 'phone',
    header: 'Phone',
  },
  {
    accessorKey: 'role',
    header: 'Role',
    cell: ({ row }) => (
      <Badge variant={roleVariantMap[row.original.role] || 'default'}>
        {row.original.role.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())}
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
    header: 'Joined',
    cell: ({ row }) => formatDate(row.original.created_at),
  },
  {
    id: 'actions',
    header: 'Actions',
    enableSorting: false,
    cell: ({ row }) => (
      <Link href={`/users/${row.original.id}`}>
        <Button variant="ghost" size="sm">
          <Eye className="h-4 w-4" />
        </Button>
      </Link>
    ),
  },
];

export default function UsersPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<UserRole | ''>('');
  const pageSize = 10;

  const { data, isLoading } = useQuery({
    queryKey: ['users', page, search, roleFilter],
    queryFn: () =>
      apiGet<User[]>(
        `/admin/users?page=${page}&per_page=${pageSize}${search ? `&search=${search}` : ''}${roleFilter ? `&role=${roleFilter}` : ''}`
      ),
  });

  const users = data?.data || [];
  const meta = (data?.meta || { total_pages: 1 }) as PaginationMeta;

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <Input
          placeholder="Search users..."
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(1);
          }}
          className="w-64"
        />
        <Select
          value={roleFilter}
          onChange={(e) => {
            setRoleFilter(e.target.value as UserRole | '');
            setPage(1);
          }}
          className="w-44"
        >
          <option value="">All Roles</option>
          <option value="customer">Customer</option>
          <option value="vendor">Vendor</option>
          <option value="admin">Admin</option>
          <option value="delivery_partner">Delivery Partner</option>
        </Select>
      </div>

      <DataTable
        columns={columns}
        data={users}
        pageCount={meta.total_pages}
        page={page}
        onPageChange={setPage}
        pageSize={pageSize}
        isLoading={isLoading}
      />
    </div>
  );
}
