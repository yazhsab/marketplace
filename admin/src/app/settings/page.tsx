'use client';

import { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Save, CheckCircle } from 'lucide-react';
import { apiGet, apiPut } from '@/lib/api-client';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { InputField } from '@/components/ui/input';
import { PageLoading } from '@/components/ui/loading';

interface PlatformSettings {
  platform_name: string;
  default_commission_rate: number;
  default_delivery_commission_rate: number;
  default_delivery_fee: number;
  delivery_radius_km: number;
  gst_rate: number;
  support_email: string;
  maintenance_mode: boolean;
}

export default function SettingsPage() {
  const queryClient = useQueryClient();
  const [saved, setSaved] = useState(false);
  const [formData, setFormData] = useState<PlatformSettings>({
    platform_name: '',
    default_commission_rate: 10,
    default_delivery_commission_rate: 15,
    default_delivery_fee: 30,
    delivery_radius_km: 10,
    gst_rate: 18,
    support_email: '',
    maintenance_mode: false,
  });

  const { data, isLoading } = useQuery({
    queryKey: ['settings'],
    queryFn: () => apiGet<PlatformSettings>('/admin/settings'),
  });

  useEffect(() => {
    if (data?.data) {
      setFormData(data.data);
    }
  }, [data]);

  const saveMutation = useMutation({
    mutationFn: (settings: PlatformSettings) =>
      apiPut('/admin/settings', settings),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['settings'] });
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    saveMutation.mutate(formData);
  };

  const updateField = <K extends keyof PlatformSettings>(
    key: K,
    value: PlatformSettings[K]
  ) => {
    setFormData((prev) => ({ ...prev, [key]: value }));
  };

  if (isLoading) return <PageLoading />;

  return (
    <div className="mx-auto max-w-2xl">
      <Card>
        <CardHeader>
          <CardTitle>Platform Settings</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-5">
            <InputField
              label="Platform Name"
              value={formData.platform_name}
              onChange={(e) => updateField('platform_name', e.target.value)}
              placeholder="Your Platform Name"
            />

            <InputField
              label="Default Vendor Commission Rate (%)"
              type="number"
              min="0"
              max="100"
              step="0.5"
              value={formData.default_commission_rate.toString()}
              onChange={(e) =>
                updateField('default_commission_rate', parseFloat(e.target.value) || 0)
              }
              helperText="Commission charged to vendors on each order"
            />

            <InputField
              label="Default Delivery Partner Commission (%)"
              type="number"
              min="0"
              max="100"
              step="0.5"
              value={formData.default_delivery_commission_rate.toString()}
              onChange={(e) =>
                updateField('default_delivery_commission_rate', parseFloat(e.target.value) || 0)
              }
              helperText="Commission percentage for delivery partner earnings"
            />

            <InputField
              label="Default Delivery Fee (INR)"
              type="number"
              min="0"
              step="1"
              value={formData.default_delivery_fee.toString()}
              onChange={(e) =>
                updateField('default_delivery_fee', parseFloat(e.target.value) || 0)
              }
              helperText="Default delivery fee charged to customers"
            />

            <InputField
              label="Delivery Radius (km)"
              type="number"
              min="1"
              max="50"
              step="1"
              value={formData.delivery_radius_km.toString()}
              onChange={(e) =>
                updateField('delivery_radius_km', parseFloat(e.target.value) || 10)
              }
              helperText="Maximum radius for auto-assigning delivery partners"
            />

            <InputField
              label="GST Rate (%)"
              type="number"
              min="0"
              max="100"
              step="0.5"
              value={formData.gst_rate.toString()}
              onChange={(e) =>
                updateField('gst_rate', parseFloat(e.target.value) || 0)
              }
            />

            <InputField
              label="Support Email"
              type="email"
              value={formData.support_email}
              onChange={(e) => updateField('support_email', e.target.value)}
              placeholder="support@example.com"
            />

            {/* Maintenance Mode Toggle */}
            <div className="flex items-center justify-between rounded-lg border border-gray-200 p-4">
              <div>
                <p className="text-sm font-medium text-gray-900">
                  Maintenance Mode
                </p>
                <p className="text-xs text-gray-500">
                  When enabled, the platform will show a maintenance page to all
                  users
                </p>
              </div>
              <button
                type="button"
                onClick={() =>
                  updateField('maintenance_mode', !formData.maintenance_mode)
                }
                className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 ${
                  formData.maintenance_mode ? 'bg-red-500' : 'bg-gray-200'
                }`}
                role="switch"
                aria-checked={formData.maintenance_mode}
              >
                <span
                  className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                    formData.maintenance_mode ? 'translate-x-5' : 'translate-x-0'
                  }`}
                />
              </button>
            </div>

            {saved && (
              <div className="flex items-center gap-2 rounded-lg bg-green-50 p-3 text-sm text-green-700">
                <CheckCircle className="h-4 w-4" />
                Settings saved successfully!
              </div>
            )}

            {saveMutation.isError && (
              <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700">
                Failed to save settings. Please try again.
              </div>
            )}

            <Button
              type="submit"
              disabled={saveMutation.isPending}
              className="w-full"
            >
              <Save className="h-4 w-4" />
              {saveMutation.isPending ? 'Saving...' : 'Save Settings'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
