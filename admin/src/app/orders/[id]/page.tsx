'use client';

import { useParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { MapPin, Phone, CreditCard, Check, Bike } from 'lucide-react';
import { apiGet } from '@/lib/api-client';
import { formatCurrency, formatDate, formatDateTime } from '@/lib/utils';
import { cn } from '@/lib/utils';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/status-badge';
import { Badge } from '@/components/ui/badge';
import { PageLoading } from '@/components/ui/loading';
import type { Order, OrderStatus, DeliveryAssignment } from '@/types';

const statusTimeline: OrderStatus[] = [
  'pending',
  'confirmed',
  'preparing',
  'ready',
  'assigned',
  'out_for_delivery',
  'delivered',
];

export default function OrderDetailPage() {
  const params = useParams();
  const orderId = params.id as string;

  const { data, isLoading } = useQuery({
    queryKey: ['order', orderId],
    queryFn: () => apiGet<Order>(`/admin/orders/${orderId}`),
  });

  const { data: assignmentData } = useQuery({
    queryKey: ['order-assignment', orderId],
    queryFn: () => apiGet<DeliveryAssignment[]>(`/admin/delivery-assignments?order_id=${orderId}`),
  });

  if (isLoading) return <PageLoading />;

  const order = data?.data;

  if (!order) {
    return (
      <div className="flex h-[60vh] items-center justify-center">
        <p className="text-gray-500">Order not found</p>
      </div>
    );
  }

  const isCancelled = order.status === 'cancelled' || order.status === 'refunded';
  const currentStepIndex = statusTimeline.indexOf(order.status);

  return (
    <div className="space-y-6">
      {/* Order Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-gray-900">{order.order_number}</h2>
          <p className="text-sm text-gray-500">
            Placed on {formatDateTime(order.created_at)}
          </p>
        </div>
        <StatusBadge status={order.status} className="text-sm px-3 py-1" />
      </div>

      {/* Status Timeline */}
      {!isCancelled && (
        <Card>
          <CardHeader>
            <CardTitle>Order Progress</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center justify-between">
              {statusTimeline.map((status, index) => {
                const isCompleted = index <= currentStepIndex;
                const isCurrent = index === currentStepIndex;
                return (
                  <div key={status} className="flex flex-1 items-center">
                    <div className="flex flex-col items-center">
                      <div
                        className={cn(
                          'flex h-8 w-8 items-center justify-center rounded-full border-2',
                          isCompleted
                            ? 'border-green-500 bg-green-500 text-white'
                            : 'border-gray-300 bg-white text-gray-400',
                          isCurrent && 'ring-4 ring-green-100'
                        )}
                      >
                        {isCompleted ? (
                          <Check className="h-4 w-4" />
                        ) : (
                          <span className="text-xs">{index + 1}</span>
                        )}
                      </div>
                      <span
                        className={cn(
                          'mt-1.5 text-xs',
                          isCompleted ? 'font-medium text-green-700' : 'text-gray-400'
                        )}
                      >
                        {status.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())}
                      </span>
                    </div>
                    {index < statusTimeline.length - 1 && (
                      <div
                        className={cn(
                          'mx-2 h-0.5 flex-1',
                          index < currentStepIndex ? 'bg-green-500' : 'bg-gray-200'
                        )}
                      />
                    )}
                  </div>
                );
              })}
            </div>
          </CardContent>
        </Card>
      )}

      {isCancelled && (
        <Card className="border-red-200 bg-red-50">
          <CardContent className="p-4">
            <p className="font-medium text-red-700">
              Order {order.status === 'refunded' ? 'Refunded' : 'Cancelled'}
            </p>
            {order.cancellation_reason && (
              <p className="mt-1 text-sm text-red-600">
                Reason: {order.cancellation_reason}
              </p>
            )}
            {order.cancelled_at && (
              <p className="mt-1 text-xs text-red-500">
                {formatDateTime(order.cancelled_at)}
              </p>
            )}
          </CardContent>
        </Card>
      )}

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Order Items */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Order Items</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead>
                  <tr>
                    <th className="px-3 py-2 text-left text-xs font-medium uppercase text-gray-500">
                      Product
                    </th>
                    <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                      Price
                    </th>
                    <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                      Qty
                    </th>
                    <th className="px-3 py-2 text-right text-xs font-medium uppercase text-gray-500">
                      Total
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {order.items?.map((item) => (
                    <tr key={item.id}>
                      <td className="px-3 py-3">
                        <div className="flex items-center gap-3">
                          {item.product_image && (
                            <img
                              src={item.product_image}
                              alt={item.product_name}
                              className="h-10 w-10 rounded-lg object-cover"
                            />
                          )}
                          <div>
                            <p className="font-medium text-gray-900">{item.product_name}</p>
                            {item.notes && (
                              <p className="text-xs text-gray-500">{item.notes}</p>
                            )}
                          </div>
                        </div>
                      </td>
                      <td className="px-3 py-3 text-right text-sm text-gray-700">
                        {formatCurrency(item.unit_price)}
                      </td>
                      <td className="px-3 py-3 text-right text-sm text-gray-700">
                        {item.quantity}
                      </td>
                      <td className="px-3 py-3 text-right text-sm font-medium text-gray-900">
                        {formatCurrency(item.total_price)}
                      </td>
                    </tr>
                  ))}
                </tbody>
                <tfoot className="border-t-2 border-gray-200">
                  <tr>
                    <td colSpan={3} className="px-3 py-2 text-right text-sm text-gray-500">
                      Subtotal
                    </td>
                    <td className="px-3 py-2 text-right text-sm text-gray-700">
                      {formatCurrency(order.subtotal)}
                    </td>
                  </tr>
                  <tr>
                    <td colSpan={3} className="px-3 py-2 text-right text-sm text-gray-500">
                      Delivery Fee
                    </td>
                    <td className="px-3 py-2 text-right text-sm text-gray-700">
                      {formatCurrency(order.delivery_fee)}
                    </td>
                  </tr>
                  <tr>
                    <td colSpan={3} className="px-3 py-2 text-right text-sm text-gray-500">
                      Tax
                    </td>
                    <td className="px-3 py-2 text-right text-sm text-gray-700">
                      {formatCurrency(order.tax_amount)}
                    </td>
                  </tr>
                  {order.discount_amount > 0 && (
                    <tr>
                      <td colSpan={3} className="px-3 py-2 text-right text-sm text-green-600">
                        Discount
                      </td>
                      <td className="px-3 py-2 text-right text-sm text-green-600">
                        -{formatCurrency(order.discount_amount)}
                      </td>
                    </tr>
                  )}
                  <tr>
                    <td colSpan={3} className="px-3 py-2 text-right text-sm font-bold text-gray-900">
                      Total
                    </td>
                    <td className="px-3 py-2 text-right text-sm font-bold text-gray-900">
                      {formatCurrency(order.total_amount)}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
          </CardContent>
        </Card>

        {/* Side Info */}
        <div className="space-y-4">
          {/* Customer Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Customer</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              {order.customer ? (
                <>
                  <p className="font-medium text-gray-900">
                    {order.customer.first_name} {order.customer.last_name}
                  </p>
                  <p className="flex items-center gap-1.5 text-sm text-gray-500">
                    <Phone className="h-3.5 w-3.5" />
                    {order.customer.phone}
                  </p>
                  <p className="text-sm text-gray-500">{order.customer.email}</p>
                </>
              ) : (
                <p className="text-sm text-gray-500">Customer info unavailable</p>
              )}
            </CardContent>
          </Card>

          {/* Vendor Info */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Vendor</CardTitle>
            </CardHeader>
            <CardContent>
              {order.vendor ? (
                <p className="font-medium text-gray-900">
                  {order.vendor.business_name}
                </p>
              ) : (
                <p className="text-sm text-gray-500">Vendor info unavailable</p>
              )}
            </CardContent>
          </Card>

          {/* Delivery Partner */}
          {assignmentData?.data && assignmentData.data.length > 0 && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Delivery Partner</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                {(() => {
                  const assignment = assignmentData.data[0];
                  return (
                    <>
                      {assignment.delivery_partner?.user && (
                        <Link
                          href={`/delivery-partners/${assignment.delivery_partner_id}`}
                          className="font-medium text-indigo-600 hover:text-indigo-700"
                        >
                          {assignment.delivery_partner.user.first_name}{' '}
                          {assignment.delivery_partner.user.last_name}
                        </Link>
                      )}
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-500">Status</span>
                        <StatusBadge status={assignment.status} />
                      </div>
                      {assignment.distance_km && (
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-gray-500">Distance</span>
                          <span className="text-sm text-gray-700">
                            {assignment.distance_km.toFixed(1)} km
                          </span>
                        </div>
                      )}
                      {assignment.earnings && (
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-gray-500">Earnings</span>
                          <span className="text-sm text-gray-700">
                            {formatCurrency(assignment.earnings)}
                          </span>
                        </div>
                      )}
                      {assignment.delivered_at && (
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-gray-500">Delivered</span>
                          <span className="text-sm text-gray-700">
                            {formatDate(assignment.delivered_at)}
                          </span>
                        </div>
                      )}
                    </>
                  );
                })()}
              </CardContent>
            </Card>
          )}

          {/* Delivery Address */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Delivery Address</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex items-start gap-2 text-sm text-gray-600">
                <MapPin className="mt-0.5 h-4 w-4 shrink-0 text-gray-400" />
                <div>
                  <p>{order.delivery_address_line1}</p>
                  {order.delivery_address_line2 && <p>{order.delivery_address_line2}</p>}
                  <p>
                    {order.delivery_city}, {order.delivery_state} - {order.delivery_pincode}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Payment Info */}
          {order.payment && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Payment</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-500">Method</span>
                  <Badge variant="indigo">
                    {order.payment.method.toUpperCase()}
                  </Badge>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-500">Status</span>
                  <StatusBadge status={order.payment.status} />
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-500">Amount</span>
                  <span className="font-medium text-gray-900">
                    {formatCurrency(order.payment.amount)}
                  </span>
                </div>
                {order.payment.paid_at && (
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-500">Paid</span>
                    <span className="text-sm text-gray-700">
                      {formatDate(order.payment.paid_at)}
                    </span>
                  </div>
                )}
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
