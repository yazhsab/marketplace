'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import {
  LayoutDashboard,
  Store,
  Package,
  Grid3x3,
  ShoppingCart,
  Calendar,
  Wrench,
  Users,
  CreditCard,
  Star,
  Bell,
  Settings,
  ChevronLeft,
  ChevronRight,
  Bike,
  ClipboardList,
} from 'lucide-react';

const navItems = [
  { label: 'Dashboard', href: '/', icon: LayoutDashboard },
  { label: 'Vendors', href: '/vendors', icon: Store },
  { label: 'Products', href: '/products', icon: Package },
  { label: 'Categories', href: '/categories', icon: Grid3x3 },
  { label: 'Orders', href: '/orders', icon: ShoppingCart },
  { label: 'Bookings', href: '/bookings', icon: Calendar },
  { label: 'Services', href: '/services', icon: Wrench },
  { label: 'Delivery Partners', href: '/delivery-partners', icon: Bike },
  { label: 'Assignments', href: '/delivery-assignments', icon: ClipboardList },
  { label: 'Users', href: '/users', icon: Users },
  { label: 'Payments', href: '/payments', icon: CreditCard },
  { label: 'Reviews', href: '/reviews', icon: Star },
  { label: 'Notifications', href: '/notifications', icon: Bell },
  { label: 'Settings', href: '/settings', icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);

  const isActive = (href: string) => {
    if (href === '/') return pathname === '/';
    return pathname.startsWith(href);
  };

  return (
    <aside
      className={cn(
        'fixed left-0 top-0 z-40 h-screen border-r border-gray-200 bg-white transition-all duration-300',
        collapsed ? 'w-16' : 'w-64'
      )}
    >
      <div className="flex h-16 items-center justify-between border-b border-gray-200 px-4">
        {!collapsed && (
          <Link href="/" className="text-xl font-bold text-indigo-600">
            Admin Panel
          </Link>
        )}
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="rounded-lg p-1.5 text-gray-500 hover:bg-gray-100"
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          {collapsed ? <ChevronRight className="h-5 w-5" /> : <ChevronLeft className="h-5 w-5" />}
        </button>
      </div>

      <nav className="flex flex-col gap-1 p-3">
        {navItems.map((item) => {
          const Icon = item.icon;
          const active = isActive(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                'flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors',
                active
                  ? 'bg-indigo-50 text-indigo-700'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              )}
              title={collapsed ? item.label : undefined}
            >
              <Icon className={cn('h-5 w-5 shrink-0', active ? 'text-indigo-700' : 'text-gray-400')} />
              {!collapsed && <span>{item.label}</span>}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
