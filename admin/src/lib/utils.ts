import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';
import { format, parseISO } from 'date-fns';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(amount);
}

export function formatDate(dateString: string, formatStr: string = 'dd MMM yyyy'): string {
  try {
    const date = typeof dateString === 'string' ? parseISO(dateString) : dateString;
    return format(date, formatStr);
  } catch {
    return dateString;
  }
}

export function formatDateTime(dateString: string): string {
  return formatDate(dateString, 'dd MMM yyyy, hh:mm a');
}

export function getStatusColor(status: string): string {
  const statusMap: Record<string, string> = {
    // Success states
    active: 'bg-green-100 text-green-800',
    approved: 'bg-green-100 text-green-800',
    confirmed: 'bg-green-100 text-green-800',
    completed: 'bg-green-100 text-green-800',
    delivered: 'bg-green-100 text-green-800',
    captured: 'bg-green-100 text-green-800',
    paid: 'bg-green-100 text-green-800',

    // Warning states
    pending: 'bg-yellow-100 text-yellow-800',
    created: 'bg-yellow-100 text-yellow-800',
    draft: 'bg-yellow-100 text-yellow-800',

    // Info / In-progress states
    preparing: 'bg-blue-100 text-blue-800',
    ready: 'bg-blue-100 text-blue-800',
    out_for_delivery: 'bg-blue-100 text-blue-800',
    in_progress: 'bg-blue-100 text-blue-800',
    authorized: 'bg-blue-100 text-blue-800',

    // Danger states
    rejected: 'bg-red-100 text-red-800',
    cancelled: 'bg-red-100 text-red-800',
    failed: 'bg-red-100 text-red-800',
    refunded: 'bg-red-100 text-red-800',
    suspended: 'bg-red-100 text-red-800',
    banned: 'bg-red-100 text-red-800',
    inactive: 'bg-gray-100 text-gray-800',
    out_of_stock: 'bg-red-100 text-red-800',

    // Neutral
    no_show: 'bg-gray-100 text-gray-800',
  };

  return statusMap[status] || 'bg-gray-100 text-gray-800';
}

export function truncateText(text: string, maxLength: number = 50): string {
  if (text.length <= maxLength) return text;
  return text.slice(0, maxLength) + '...';
}
