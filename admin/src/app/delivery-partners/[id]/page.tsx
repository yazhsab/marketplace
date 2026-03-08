'use client';

import { use } from 'react';
import Link from 'next/link';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ArrowLeft, Star, MapPin, Bike, CreditCard, Wallet, TrendingUp } from 'lucide-react';
import { apiGet, apiPut } from '@/lib/api-client';
import { StatusBadge } from '@/components/ui/status-badge';
import { Button } from '@/components/ui/button';
import { InputField } from '@/components/ui/input';
import type { DeliveryPartner, DeliveryAssignment, Wallet as WalletType, WalletTransaction, PaginationMeta } from '@/types';

export default function DeliveryPartnerDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const queryClient = useQueryClient();

  const { data: partnerData, isLoading } = useQuery({
    queryKey: ['delivery-partner', id],
    queryFn: () => apiGet<DeliveryPartner>(`/admin/delivery-partners/${id}`),
  });

  const { data: assignmentsData } = useQuery({
    queryKey: ['partner-assignments', id],
    queryFn: () =>
      apiGet<DeliveryAssignment[]>(
        `/admin/delivery-assignments?delivery_partner_id=${id}&per_page=10`
      ),
  });

  const { data: walletData } = useQuery({
    queryKey: ['partner-wallet', id],
    queryFn: () => apiGet<WalletType>(`/admin/delivery-partners/${id}/wallet`),
  });

  const { data: transactionsData } = useQuery({
    queryKey: ['partner-transactions', id],
    queryFn: () =>
      apiGet<WalletTransaction[]>(
        `/admin/delivery-partners/${id}/wallet/transactions?per_page=10`
      ),
  });

  const updateCommission = useMutation({
    mutationFn: (commission_pct: number) =>
      apiPut(`/admin/delivery-partners/${id}/commission`, { commission_pct }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['delivery-partner', id] });
    },
  });

  const updateStatus = useMutation({
    mutationFn: (status: string) =>
      apiPut(`/admin/delivery-partners/${id}/status`, { status }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['delivery-partner', id] });
      queryClient.invalidateQueries({ queryKey: ['delivery-partners'] });
    },
  });

  if (isLoading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-indigo-600" />
      </div>
    );
  }

  const partner = partnerData?.data;
  if (!partner) {
    return <div className="text-center text-gray-500">Partner not found</div>;
  }

  const assignments = assignmentsData?.data || [];
  const wallet = walletData?.data;
  const transactions = transactionsData?.data || [];

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/delivery-partners">
          <Button variant="ghost" size="sm">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Button>
        </Link>
        <h1 className="text-2xl font-bold">
          {partner.user?.first_name} {partner.user?.last_name}
        </h1>
        <StatusBadge status={partner.status} />
      </div>

      {/* Status Actions */}
      {partner.status !== 'approved' && (
        <div className="flex gap-2 rounded-lg border border-yellow-200 bg-yellow-50 p-4">
          <span className="text-sm text-yellow-800">
            This partner is currently <strong>{partner.status}</strong>.
          </span>
          <div className="flex gap-2 ml-auto">
            {partner.status === 'pending' && (
              <>
                <Button
                  size="sm"
                  onClick={() => updateStatus.mutate('approved')}
                  disabled={updateStatus.isPending}
                  className="bg-green-600 hover:bg-green-700"
                >
                  Approve
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => updateStatus.mutate('rejected')}
                  disabled={updateStatus.isPending}
                  className="text-red-600 border-red-200 hover:bg-red-50"
                >
                  Reject
                </Button>
              </>
            )}
            {partner.status === 'suspended' && (
              <Button
                size="sm"
                onClick={() => updateStatus.mutate('approved')}
                disabled={updateStatus.isPending}
              >
                Reactivate
              </Button>
            )}
            {partner.status === 'rejected' && (
              <Button
                size="sm"
                onClick={() => updateStatus.mutate('approved')}
                disabled={updateStatus.isPending}
              >
                Approve
              </Button>
            )}
          </div>
        </div>
      )}

      <div className="grid gap-6 md:grid-cols-2">
        {/* Vehicle Info */}
        <div className="rounded-lg border border-gray-200 bg-white p-6">
          <h2 className="mb-4 flex items-center gap-2 text-lg font-semibold">
            <Bike className="h-5 w-5 text-gray-400" />
            Vehicle Information
          </h2>
          <dl className="space-y-3">
            <div className="flex justify-between">
              <dt className="text-sm text-gray-500">Type</dt>
              <dd className="text-sm font-medium capitalize">{partner.vehicle_type}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-sm text-gray-500">Number</dt>
              <dd className="text-sm font-medium">{partner.vehicle_number || '-'}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-sm text-gray-500">License</dt>
              <dd className="text-sm font-medium">{partner.license_number || '-'}</dd>
            </div>
          </dl>
        </div>

        {/* Performance */}
        <div className="rounded-lg border border-gray-200 bg-white p-6">
          <h2 className="mb-4 flex items-center gap-2 text-lg font-semibold">
            <Star className="h-5 w-5 text-gray-400" />
            Performance
          </h2>
          <dl className="space-y-3">
            <div className="flex justify-between">
              <dt className="text-sm text-gray-500">Rating</dt>
              <dd className="flex items-center gap-1 text-sm font-medium">
                <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                {partner.avg_rating.toFixed(1)}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-sm text-gray-500">Total Deliveries</dt>
              <dd className="text-sm font-medium">{partner.total_deliveries}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-sm text-gray-500">Commission Rate</dt>
              <dd className="text-sm font-medium">{partner.commission_pct}%</dd>
            </div>
          </dl>
        </div>

        {/* Status Info */}
        <div className="rounded-lg border border-gray-200 bg-white p-6">
          <h2 className="mb-4 flex items-center gap-2 text-lg font-semibold">
            <MapPin className="h-5 w-5 text-gray-400" />
            Current Status
          </h2>
          <dl className="space-y-3">
            <div className="flex justify-between">
              <dt className="text-sm text-gray-500">On Shift</dt>
              <dd className={`text-sm font-medium ${partner.is_on_shift ? 'text-green-600' : 'text-gray-400'}`}>
                {partner.is_on_shift ? 'Yes' : 'No'}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-sm text-gray-500">Available</dt>
              <dd className={`text-sm font-medium ${partner.is_available ? 'text-green-600' : 'text-gray-400'}`}>
                {partner.is_available ? 'Yes' : 'No'}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-sm text-gray-500">Zone Preference</dt>
              <dd className="text-sm font-medium">{partner.zone_preference || 'None'}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-sm text-gray-500">Active Order</dt>
              <dd className="text-sm font-medium">{partner.current_order_id || 'None'}</dd>
            </div>
          </dl>
        </div>

        {/* Earnings */}
        <div className="rounded-lg border border-gray-200 bg-white p-6">
          <h2 className="mb-4 flex items-center gap-2 text-lg font-semibold">
            <CreditCard className="h-5 w-5 text-gray-400" />
            Earnings
          </h2>
          <dl className="space-y-3">
            <div className="flex justify-between">
              <dt className="text-sm text-gray-500">Total Earned</dt>
              <dd className="text-sm font-medium text-green-600">
                &#8377;{partner.total_earnings.toFixed(2)}
              </dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-sm text-gray-500">Member Since</dt>
              <dd className="text-sm font-medium">
                {new Date(partner.created_at).toLocaleDateString()}
              </dd>
            </div>
          </dl>
        </div>
      </div>

      {/* Wallet & Transactions */}
      <div className="grid gap-6 md:grid-cols-2">
        {/* Wallet Balance */}
        <div className="rounded-lg border border-gray-200 bg-white p-6">
          <h2 className="mb-4 flex items-center gap-2 text-lg font-semibold">
            <Wallet className="h-5 w-5 text-gray-400" />
            Wallet
          </h2>
          {wallet ? (
            <dl className="space-y-3">
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500">Balance</dt>
                <dd className="text-lg font-bold text-green-600">
                  &#8377;{wallet.balance.toFixed(2)}
                </dd>
              </div>
              <div className="flex justify-between">
                <dt className="text-sm text-gray-500">Status</dt>
                <dd className={`text-sm font-medium ${wallet.is_active ? 'text-green-600' : 'text-red-500'}`}>
                  {wallet.is_active ? 'Active' : 'Inactive'}
                </dd>
              </div>
            </dl>
          ) : (
            <p className="text-sm text-gray-500">No wallet found</p>
          )}
        </div>

        {/* Commission Management */}
        <div className="rounded-lg border border-gray-200 bg-white p-6">
          <h2 className="mb-4 flex items-center gap-2 text-lg font-semibold">
            <TrendingUp className="h-5 w-5 text-gray-400" />
            Commission
          </h2>
          <div className="space-y-3">
            <div className="flex justify-between">
              <span className="text-sm text-gray-500">Current Rate</span>
              <span className="text-sm font-medium">{partner.commission_pct}%</span>
            </div>
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const formData = new FormData(e.currentTarget);
                const rate = parseFloat(formData.get('rate') as string);
                if (!isNaN(rate) && rate >= 0 && rate <= 100) {
                  updateCommission.mutate(rate);
                }
              }}
              className="flex items-end gap-2"
            >
              <div className="flex-1">
                <InputField
                  name="rate"
                  type="number"
                  min="0"
                  max="100"
                  step="0.5"
                  placeholder={partner.commission_pct.toString()}
                  label="New Rate (%)"
                />
              </div>
              <Button
                type="submit"
                size="sm"
                disabled={updateCommission.isPending}
              >
                Update
              </Button>
            </form>
          </div>
        </div>
      </div>

      {/* Recent Transactions */}
      {transactions.length > 0 && (
        <div className="rounded-lg border border-gray-200 bg-white p-6">
          <h2 className="mb-4 text-lg font-semibold">Recent Transactions</h2>
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b text-gray-500">
                  <th className="pb-3 pr-4 font-medium">Type</th>
                  <th className="pb-3 pr-4 font-medium">Amount</th>
                  <th className="pb-3 pr-4 font-medium">Balance After</th>
                  <th className="pb-3 pr-4 font-medium">Description</th>
                  <th className="pb-3 pr-4 font-medium">Status</th>
                  <th className="pb-3 font-medium">Date</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {transactions.map((t) => (
                  <tr key={t.id}>
                    <td className="py-3 pr-4 capitalize">
                      {t.type.replace(/_/g, ' ')}
                    </td>
                    <td className={`py-3 pr-4 font-medium ${t.type === 'credit' ? 'text-green-600' : 'text-red-600'}`}>
                      {t.type === 'credit' ? '+' : '-'}&#8377;{t.amount.toFixed(2)}
                    </td>
                    <td className="py-3 pr-4">&#8377;{t.balance_after.toFixed(2)}</td>
                    <td className="py-3 pr-4 text-gray-600">
                      {t.description || '-'}
                    </td>
                    <td className="py-3 pr-4">
                      <StatusBadge status={t.status} />
                    </td>
                    <td className="py-3">
                      {new Date(t.created_at).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Recent Assignments */}
      <div className="rounded-lg border border-gray-200 bg-white p-6">
        <h2 className="mb-4 text-lg font-semibold">Recent Assignments</h2>
        {assignments.length === 0 ? (
          <p className="text-sm text-gray-500">No assignments yet</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b text-gray-500">
                  <th className="pb-3 pr-4 font-medium">Order</th>
                  <th className="pb-3 pr-4 font-medium">Status</th>
                  <th className="pb-3 pr-4 font-medium">Distance</th>
                  <th className="pb-3 pr-4 font-medium">Earnings</th>
                  <th className="pb-3 font-medium">Date</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {assignments.map((a) => (
                  <tr key={a.id}>
                    <td className="py-3 pr-4">
                      <Link
                        href={`/orders/${a.order_id}`}
                        className="text-indigo-600 hover:text-indigo-700"
                      >
                        {a.order_id.substring(0, 8)}...
                      </Link>
                    </td>
                    <td className="py-3 pr-4">
                      <StatusBadge status={a.status} />
                    </td>
                    <td className="py-3 pr-4">
                      {a.distance_km ? `${a.distance_km.toFixed(1)} km` : '-'}
                    </td>
                    <td className="py-3 pr-4">
                      {a.earnings ? `\u20B9${a.earnings.toFixed(2)}` : '-'}
                    </td>
                    <td className="py-3">
                      {new Date(a.created_at).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Suspend / Unsuspend */}
      {partner.status === 'approved' && (
        <div className="flex justify-end">
          <Button
            variant="outline"
            className="text-red-600 border-red-200 hover:bg-red-50"
            onClick={() => updateStatus.mutate('suspended')}
            disabled={updateStatus.isPending}
          >
            Suspend Partner
          </Button>
        </div>
      )}
    </div>
  );
}
