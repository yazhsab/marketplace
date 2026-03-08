'use client';

import { useParams } from 'next/navigation';
import Link from 'next/link';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  User,
  Mail,
  Phone,
  Shield,
  CheckCircle,
  XCircle,
  Calendar,
  ShoppingCart,
  Calendar as CalendarIcon,
  Ban,
  Check,
  AlertTriangle,
} from 'lucide-react';
import { apiGet, apiPut } from '@/lib/api-client';
import { formatDate, formatCurrency } from '@/lib/utils';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/status-badge';
import { Badge } from '@/components/ui/badge';
import { StatCard } from '@/components/ui/stat-card';
import { Button } from '@/components/ui/button';
import { PageLoading } from '@/components/ui/loading';
import type { User as UserType, Order, Booking } from '@/types';

interface UserActivity {
  total_orders: number;
  total_bookings: number;
  total_spent: number;
  last_order_at?: string;
  last_login_at?: string;
}

const roleVariantMap: Record<string, 'default' | 'success' | 'warning' | 'danger' | 'info' | 'indigo'> = {
  admin: 'danger',
  vendor: 'indigo',
  customer: 'default',
  delivery_partner: 'info',
};

export default function UserDetailPage() {
  const params = useParams();
  const userId = params.id as string;
  const queryClient = useQueryClient();

  const { data: userData, isLoading } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => apiGet<UserType>(`/admin/users/${userId}`),
  });

  const { data: activityData } = useQuery({
    queryKey: ['user-activity', userId],
    queryFn: () => apiGet<UserActivity>(`/admin/users/${userId}/activity`),
  });

  const { data: recentOrdersData } = useQuery({
    queryKey: ['user-orders', userId],
    queryFn: () => apiGet<Order[]>(`/admin/orders?customer_id=${userId}&per_page=5`),
  });

  const { data: recentBookingsData } = useQuery({
    queryKey: ['user-bookings', userId],
    queryFn: () => apiGet<Booking[]>(`/admin/bookings?customer_id=${userId}&per_page=5`),
  });

  const statusMutation = useMutation({
    mutationFn: (status: string) =>
      apiPut(`/admin/users/${userId}/status`, { status }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
  });

  if (isLoading) return <PageLoading />;

  const user = userData?.data;
  const activity = activityData?.data;
  const recentOrders = recentOrdersData?.data || [];
  const recentBookings = recentBookingsData?.data || [];

  if (!user) {
    return (
      <div className="flex h-[60vh] items-center justify-center">
        <p className="text-gray-500">User not found</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Profile Card */}
      <Card>
        <CardContent className="p-6">
          <div className="flex items-start gap-6">
            <div className="flex h-20 w-20 items-center justify-center rounded-full bg-indigo-100">
              {user.avatar_url ? (
                <img
                  src={user.avatar_url}
                  alt={`${user.first_name} ${user.last_name}`}
                  className="h-full w-full rounded-full object-cover"
                />
              ) : (
                <User className="h-10 w-10 text-indigo-600" />
              )}
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-3">
                <h2 className="text-xl font-bold text-gray-900">
                  {user.first_name} {user.last_name}
                </h2>
                <Badge variant={roleVariantMap[user.role] || 'default'}>
                  {user.role.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())}
                </Badge>
                <StatusBadge status={user.status} />
              </div>
              <div className="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-2">
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Mail className="h-4 w-4 text-gray-400" />
                  <span>{user.email}</span>
                  {user.email_verified ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : (
                    <XCircle className="h-4 w-4 text-red-400" />
                  )}
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Phone className="h-4 w-4 text-gray-400" />
                  <span>{user.phone}</span>
                  {user.phone_verified ? (
                    <CheckCircle className="h-4 w-4 text-green-500" />
                  ) : (
                    <XCircle className="h-4 w-4 text-red-400" />
                  )}
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Shield className="h-4 w-4 text-gray-400" />
                  <span>
                    ID: {user.id.slice(0, 8)}...
                  </span>
                </div>
                <div className="flex items-center gap-2 text-sm text-gray-600">
                  <Calendar className="h-4 w-4 text-gray-400" />
                  <span>Joined {formatDate(user.created_at)}</span>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Status Management */}
      {user.role !== 'admin' && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Account Actions</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex flex-wrap items-center gap-3">
              {user.status === 'active' && (
                <>
                  <Button
                    variant="warning"
                    size="sm"
                    onClick={() => {
                      if (window.confirm(`Suspend ${user.first_name} ${user.last_name}?`)) {
                        statusMutation.mutate('suspended');
                      }
                    }}
                    disabled={statusMutation.isPending}
                  >
                    <AlertTriangle className="h-4 w-4 mr-1" />
                    Suspend
                  </Button>
                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => {
                      if (window.confirm(`Ban ${user.first_name} ${user.last_name}? This is a severe action.`)) {
                        statusMutation.mutate('banned');
                      }
                    }}
                    disabled={statusMutation.isPending}
                  >
                    <Ban className="h-4 w-4 mr-1" />
                    Ban
                  </Button>
                </>
              )}
              {user.status === 'suspended' && (
                <>
                  <Button
                    variant="success"
                    size="sm"
                    onClick={() => statusMutation.mutate('active')}
                    disabled={statusMutation.isPending}
                  >
                    <Check className="h-4 w-4 mr-1" />
                    Reactivate
                  </Button>
                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => {
                      if (window.confirm(`Ban ${user.first_name} ${user.last_name}?`)) {
                        statusMutation.mutate('banned');
                      }
                    }}
                    disabled={statusMutation.isPending}
                  >
                    <Ban className="h-4 w-4 mr-1" />
                    Ban
                  </Button>
                </>
              )}
              {user.status === 'banned' && (
                <Button
                  variant="success"
                  size="sm"
                  onClick={() => {
                    if (window.confirm(`Unban and reactivate ${user.first_name} ${user.last_name}?`)) {
                      statusMutation.mutate('active');
                    }
                  }}
                  disabled={statusMutation.isPending}
                >
                  <Check className="h-4 w-4 mr-1" />
                  Unban & Reactivate
                </Button>
              )}
              {user.status === 'inactive' && (
                <Button
                  variant="success"
                  size="sm"
                  onClick={() => statusMutation.mutate('active')}
                  disabled={statusMutation.isPending}
                >
                  <Check className="h-4 w-4 mr-1" />
                  Activate
                </Button>
              )}
              {statusMutation.isError && (
                <span className="text-sm text-red-600">Failed to update status</span>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Activity Summary */}
      {activity && (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <StatCard
            icon={<ShoppingCart className="h-6 w-6" />}
            label="Total Orders"
            value={activity.total_orders}
          />
          <StatCard
            icon={<CalendarIcon className="h-6 w-6" />}
            label="Total Bookings"
            value={activity.total_bookings}
          />
          <StatCard
            icon={<span className="text-lg font-bold">&#8377;</span>}
            label="Total Spent"
            value={formatCurrency(activity.total_spent)}
          />
        </div>
      )}

      {activity && (
        <Card>
          <CardHeader>
            <CardTitle>Activity</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
              {activity.last_order_at && (
                <div>
                  <p className="text-sm font-medium text-gray-500">Last Order</p>
                  <p className="text-sm text-gray-700">{formatDate(activity.last_order_at)}</p>
                </div>
              )}
              {activity.last_login_at && (
                <div>
                  <p className="text-sm font-medium text-gray-500">Last Login</p>
                  <p className="text-sm text-gray-700">{formatDate(activity.last_login_at)}</p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Recent Orders */}
      {recentOrders.length > 0 && (
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>Recent Orders</CardTitle>
            <Link
              href={`/orders?customer_id=${userId}`}
              className="text-sm text-indigo-600 hover:text-indigo-700"
            >
              View all
            </Link>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b text-gray-500">
                    <th className="pb-2 pr-4 font-medium">Order</th>
                    <th className="pb-2 pr-4 font-medium">Total</th>
                    <th className="pb-2 pr-4 font-medium">Status</th>
                    <th className="pb-2 font-medium">Date</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {recentOrders.map((order) => (
                    <tr key={order.id}>
                      <td className="py-2 pr-4">
                        <Link
                          href={`/orders/${order.id}`}
                          className="text-indigo-600 hover:text-indigo-700"
                        >
                          {order.order_number}
                        </Link>
                      </td>
                      <td className="py-2 pr-4">{formatCurrency(order.total_amount)}</td>
                      <td className="py-2 pr-4"><StatusBadge status={order.status} /></td>
                      <td className="py-2">{formatDate(order.created_at)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Recent Bookings */}
      {recentBookings.length > 0 && (
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <CardTitle>Recent Bookings</CardTitle>
            <Link
              href={`/bookings?customer_id=${userId}`}
              className="text-sm text-indigo-600 hover:text-indigo-700"
            >
              View all
            </Link>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead>
                  <tr className="border-b text-gray-500">
                    <th className="pb-2 pr-4 font-medium">Booking</th>
                    <th className="pb-2 pr-4 font-medium">Service</th>
                    <th className="pb-2 pr-4 font-medium">Status</th>
                    <th className="pb-2 font-medium">Date</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {recentBookings.map((booking) => (
                    <tr key={booking.id}>
                      <td className="py-2 pr-4">
                        <Link
                          href={`/bookings/${booking.id}`}
                          className="text-indigo-600 hover:text-indigo-700"
                        >
                          {booking.booking_number}
                        </Link>
                      </td>
                      <td className="py-2 pr-4">{booking.service?.name || '-'}</td>
                      <td className="py-2 pr-4"><StatusBadge status={booking.status} /></td>
                      <td className="py-2">{formatDate(booking.booking_date)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
