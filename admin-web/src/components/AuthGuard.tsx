'use client';

import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';

export function AuthGuard({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (loading) return;
    if (!user && pathname !== '/login') {
      router.replace('/login');
      return;
    }
  }, [user, loading, pathname, router]);

  if (loading) return <div style={{ padding: 24 }}>Loading...</div>;
  if (!user && pathname !== '/login') return null;
  return <>{children}</>;
}
