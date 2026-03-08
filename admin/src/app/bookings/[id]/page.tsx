'use client';

import { useParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { Calendar, Clock, MapPin, Phone, User } from 'lucide-react';
import { apiGet } from '@/lib/api-client';
import { formatCurrency, formatDate, formatDateTime } from '@/lib/utils';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { StatusBadge } from '@/components/ui/status-badge';
import { Badge } from '@/components/ui/badge';
import { PageLoading } from '@/components/ui/loading';
import type { Booking } from '@/types';

export default function BookingDetailPage() {
  const params = useParams();
  const bookingId = params.id as string;

  const { data, isLoading } = useQuery({
    queryKey: ['booking', bookingId],
    queryFn: () => apiGet<Booking>(`/admin/bookings/${bookingId}`),
  });

  if (isLoading) return <PageLoading />;

  const booking = data?.data;

  if (!booking) {
    return (
      <div className="flex h-[60vh] items-center justify-center">
        <p className="text-gray-500">Booking not found</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Booking Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-gray-900">{booking.booking_number}</h2>
          <p className="text-sm text-gray-500">
            Created on {formatDateTime(booking.created_at)}
          </p>
        </div>
        <StatusBadge status={booking.status} className="text-sm px-3 py-1" />
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Booking Details */}
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Booking Details</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            {/* Service info */}
            <div className="rounded-lg bg-gray-50 p-4">
              <h4 className="font-medium text-gray-900">
                {booking.service?.name || 'Service'}
              </h4>
              {booking.service?.description && (
                <p className="mt-1 text-sm text-gray-600">
                  {booking.service.description}
                </p>
              )}
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="flex items-center gap-2 text-sm">
                <Calendar className="h-4 w-4 text-gray-400" />
                <span className="text-gray-500">Date:</span>
                <span className="font-medium">{formatDate(booking.booking_date)}</span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <Clock className="h-4 w-4 text-gray-400" />
                <span className="text-gray-500">Time:</span>
                <span className="font-medium">
                  {booking.start_time} - {booking.end_time}
                </span>
              </div>
              <div className="flex items-center gap-2 text-sm">
                <Clock className="h-4 w-4 text-gray-400" />
                <span className="text-gray-500">Duration:</span>
                <span className="font-medium">{booking.duration_minutes} min</span>
              </div>
            </div>

            {booking.notes && (
              <div>
                <p className="text-sm font-medium text-gray-500">Notes</p>
                <p className="mt-1 text-sm text-gray-700">{booking.notes}</p>
              </div>
            )}

            {booking.cancellation_reason && (
              <div className="rounded-lg bg-red-50 p-3">
                <p className="text-sm font-medium text-red-700">Cancellation Reason</p>
                <p className="mt-1 text-sm text-red-600">{booking.cancellation_reason}</p>
              </div>
            )}

            {/* Price Breakdown */}
            <div className="border-t pt-4">
              <div className="space-y-1">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Subtotal</span>
                  <span>{formatCurrency(booking.subtotal)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-gray-500">Tax</span>
                  <span>{formatCurrency(booking.tax_amount)}</span>
                </div>
                {booking.discount_amount > 0 && (
                  <div className="flex justify-between text-sm text-green-600">
                    <span>Discount</span>
                    <span>-{formatCurrency(booking.discount_amount)}</span>
                  </div>
                )}
                <div className="flex justify-between border-t pt-1 text-sm font-bold">
                  <span>Total</span>
                  <span>{formatCurrency(booking.total_amount)}</span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Side Info */}
        <div className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Customer</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              {booking.customer ? (
                <>
                  <p className="flex items-center gap-2 font-medium text-gray-900">
                    <User className="h-4 w-4 text-gray-400" />
                    {booking.customer.first_name} {booking.customer.last_name}
                  </p>
                  <p className="flex items-center gap-2 text-sm text-gray-500">
                    <Phone className="h-3.5 w-3.5" />
                    {booking.customer.phone}
                  </p>
                  <p className="text-sm text-gray-500">{booking.customer.email}</p>
                </>
              ) : (
                <p className="text-sm text-gray-500">Customer info unavailable</p>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="text-base">Vendor</CardTitle>
            </CardHeader>
            <CardContent>
              {booking.vendor ? (
                <>
                  <p className="font-medium text-gray-900">
                    {booking.vendor.business_name}
                  </p>
                  <p className="mt-1 flex items-center gap-1.5 text-sm text-gray-500">
                    <MapPin className="h-3.5 w-3.5" />
                    {booking.vendor.city}
                  </p>
                </>
              ) : (
                <p className="text-sm text-gray-500">Vendor info unavailable</p>
              )}
            </CardContent>
          </Card>

          {booking.payment && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">Payment</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-500">Method</span>
                  <Badge variant="indigo">
                    {booking.payment.method.toUpperCase()}
                  </Badge>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-500">Status</span>
                  <StatusBadge status={booking.payment.status} />
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-500">Amount</span>
                  <span className="font-medium">
                    {formatCurrency(booking.payment.amount)}
                  </span>
                </div>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
