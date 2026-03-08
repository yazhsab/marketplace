'use client';

import { useState } from 'react';
import { usePathname } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import { LogOut, ChevronDown, User } from 'lucide-react';

const pageTitles: Record<string, string> = {
  '/': 'Dashboard',
  '/vendors': 'Vendors',
  '/vendors/pending': 'Pending Vendors',
  '/products': 'Products',
  '/categories': 'Categories',
  '/orders': 'Orders',
  '/bookings': 'Bookings',
  '/services': 'Services',
  '/users': 'Users',
  '/payments': 'Payments',
  '/payments/payouts': 'Payouts',
  '/reviews': 'Reviews',
  '/notifications': 'Notifications',
  '/settings': 'Settings',
};

function getPageTitle(pathname: string): string {
  if (pageTitles[pathname]) return pageTitles[pathname];

  if (/^\/vendors\/[^/]+$/.test(pathname)) return 'Vendor Details';
  if (/^\/orders\/[^/]+$/.test(pathname)) return 'Order Details';
  if (/^\/bookings\/[^/]+$/.test(pathname)) return 'Booking Details';
  if (/^\/users\/[^/]+$/.test(pathname)) return 'User Details';

  const segments = pathname.split('/').filter(Boolean);
  if (segments.length > 0) {
    return segments[segments.length - 1]
      .replace(/-/g, ' ')
      .replace(/\b\w/g, (c) => c.toUpperCase());
  }

  return 'Dashboard';
}

export function Header() {
  const pathname = usePathname();
  const { user, logout } = useAuthStore();
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const title = getPageTitle(pathname);

  return (
    <header className="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-gray-200 bg-white px-6">
      <h1 className="text-xl font-semibold text-gray-900">{title}</h1>

      <div className="relative">
        <button
          onClick={() => setDropdownOpen(!dropdownOpen)}
          className="flex items-center gap-2 rounded-lg px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
        >
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-indigo-100">
            <User className="h-4 w-4 text-indigo-600" />
          </div>
          <span className="font-medium">
            {user ? `${user.first_name} ${user.last_name}` : 'Admin'}
          </span>
          <ChevronDown className="h-4 w-4" />
        </button>

        {dropdownOpen && (
          <>
            <div
              className="fixed inset-0 z-40"
              onClick={() => setDropdownOpen(false)}
            />
            <div className="absolute right-0 z-50 mt-1 w-48 rounded-lg border border-gray-200 bg-white py-1 shadow-lg">
              <div className="border-b border-gray-100 px-4 py-2">
                <p className="text-sm font-medium text-gray-900">
                  {user ? `${user.first_name} ${user.last_name}` : 'Admin'}
                </p>
                <p className="text-xs text-gray-500">{user?.email || 'admin@example.com'}</p>
              </div>
              <button
                onClick={() => {
                  setDropdownOpen(false);
                  logout();
                }}
                className="flex w-full items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
              >
                <LogOut className="h-4 w-4" />
                Sign Out
              </button>
            </div>
          </>
        )}
      </div>
    </header>
  );
}
