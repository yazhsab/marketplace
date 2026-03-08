'use client';

import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { Send, CheckCircle } from 'lucide-react';
import { apiPost } from '@/lib/api-client';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { InputField } from '@/components/ui/input';
import { Select } from '@/components/ui/select';
import type { NotificationType } from '@/types';

interface NotificationPayload {
  title: string;
  body: string;
  type: NotificationType;
  target: 'all_users' | 'all_vendors' | 'all_delivery_partners' | 'specific_user';
  user_id?: string;
}

export default function NotificationsPage() {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [type, setType] = useState<NotificationType>('promotion');
  const [target, setTarget] = useState<'all_users' | 'all_vendors' | 'all_delivery_partners' | 'specific_user'>('all_users');
  const [userId, setUserId] = useState('');
  const [sent, setSent] = useState(false);

  const sendMutation = useMutation({
    mutationFn: (payload: NotificationPayload) =>
      apiPost('/admin/notifications/send', payload),
    onSuccess: () => {
      setSent(true);
      setTitle('');
      setBody('');
      setUserId('');
      setTimeout(() => setSent(false), 3000);
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const payload: NotificationPayload = {
      title,
      body,
      type,
      target,
    };
    if (target === 'specific_user' && userId) {
      payload.user_id = userId;
    }
    sendMutation.mutate(payload);
  };

  return (
    <div className="mx-auto max-w-2xl">
      <Card>
        <CardHeader>
          <CardTitle>Send Notification</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <InputField
              label="Title"
              placeholder="Notification title"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
            />

            <div className="space-y-1.5">
              <label className="block text-sm font-medium text-gray-700">
                Body
              </label>
              <textarea
                className="flex min-h-[100px] w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-900 placeholder:text-gray-400 focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/20"
                placeholder="Notification body..."
                value={body}
                onChange={(e) => setBody(e.target.value)}
                required
              />
            </div>

            <Select
              label="Type"
              value={type}
              onChange={(e) => setType(e.target.value as NotificationType)}
            >
              <option value="promotion">Promotion</option>
              <option value="system">System</option>
              <option value="order_update">Order Update</option>
              <option value="booking_update">Booking Update</option>
              <option value="vendor_update">Vendor Update</option>
            </Select>

            <Select
              label="Target"
              value={target}
              onChange={(e) =>
                setTarget(e.target.value as 'all_users' | 'all_vendors' | 'all_delivery_partners' | 'specific_user')
              }
            >
              <option value="all_users">All Users</option>
              <option value="all_vendors">All Vendors</option>
              <option value="all_delivery_partners">All Delivery Partners</option>
              <option value="specific_user">Specific User</option>
            </Select>

            {target === 'specific_user' && (
              <InputField
                label="User ID"
                placeholder="Enter user ID"
                value={userId}
                onChange={(e) => setUserId(e.target.value)}
                required
              />
            )}

            {sent && (
              <div className="flex items-center gap-2 rounded-lg bg-green-50 p-3 text-sm text-green-700">
                <CheckCircle className="h-4 w-4" />
                Notification sent successfully!
              </div>
            )}

            {sendMutation.isError && (
              <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">
                Failed to send notification. Please try again.
              </div>
            )}

            <Button
              type="submit"
              disabled={sendMutation.isPending}
              className="w-full"
            >
              <Send className="h-4 w-4" />
              {sendMutation.isPending ? 'Sending...' : 'Send Notification'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
