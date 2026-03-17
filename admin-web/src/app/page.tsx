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
    <div style={{ padding: 24, textAlign: 'center' }}>
      Loading...
    </div>
  );
}
