import { Badge, type BadgeProps } from './badge';

type BadgeVariant = 'default' | 'success' | 'warning' | 'danger' | 'info' | 'indigo';

const statusVariantMap: Record<string, BadgeVariant> = {
  // Warning
  pending: 'warning',
  created: 'warning',
  draft: 'warning',

  // Success
  active: 'success',
  approved: 'success',
  confirmed: 'success',
  captured: 'success',
  completed: 'success',
  delivered: 'success',
  paid: 'success',

  // Danger
  rejected: 'danger',
  cancelled: 'danger',
  failed: 'danger',
  refunded: 'danger',
  suspended: 'danger',
  banned: 'danger',
  inactive: 'danger',
  out_of_stock: 'danger',
  no_show: 'danger',

  // Info
  preparing: 'info',
  ready: 'info',
  out_for_delivery: 'info',
  in_progress: 'info',
  authorized: 'info',
};

interface StatusBadgeProps extends Omit<BadgeProps, 'variant'> {
  status: string;
}

export function StatusBadge({ status, ...props }: StatusBadgeProps) {
  const variant = statusVariantMap[status] || 'default';
  const displayLabel = status.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());

  return (
    <Badge variant={variant} {...props}>
      {displayLabel}
    </Badge>
  );
}
