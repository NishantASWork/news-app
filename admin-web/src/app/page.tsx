'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';

export default function HomePage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (loading) return;
    if (user) router.replace('/articles');
    else router.replace('/login');
  }, [user, loading, router]);

  return (
    <div className="admin-main" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div style={{ textAlign: 'center' }}>
        <span className="admin-spinner" style={{ borderColor: 'var(--admin-border)', borderTopColor: 'var(--admin-primary)', width: 32, height: 32, marginBottom: 16, display: 'inline-block' }} />
        <p style={{ color: 'var(--admin-text-muted)', fontSize: 14 }}>Loading...</p>
      </div>
    </div>
  );
}
