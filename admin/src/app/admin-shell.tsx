'use client';

import { usePathname } from 'next/navigation';
import { useEffect } from 'react';
import { Sidebar } from '@/components/layout/sidebar';
import { Header } from '@/components/layout/header';
import { useAuthStore } from '@/store/auth-store';

export function AdminShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const { hydrate } = useAuthStore();
  const isLoginPage = pathname === '/login';

  useEffect(() => {
    hydrate();
  }, [hydrate]);

  if (isLoginPage) {
    return <>{children}</>;
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Sidebar />
      <div className="pl-64">
        <Header />
        <main className="p-6">{children}</main>
      </div>
    </div>
  );
}
