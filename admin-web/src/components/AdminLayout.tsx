'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';

export function AdminLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { signOut } = useAuth();

  const handleSignOut = async () => {
    await signOut();
    router.replace('/login');
  };

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      <aside
        style={{
          width: 220,
          borderRight: '1px solid #eee',
          padding: 24,
          display: 'flex',
          flexDirection: 'column',
          gap: 8,
        }}
      >
        <Link
          href="/articles"
          style={{
            fontWeight: pathname.startsWith('/articles') ? 600 : 400,
            color: pathname.startsWith('/articles') ? '#1976d2' : 'inherit',
          }}
        >
          Articles
        </Link>
        <Link
          href="/categories"
          style={{
            fontWeight: pathname.startsWith('/categories') ? 600 : 400,
            color: pathname.startsWith('/categories') ? '#1976d2' : 'inherit',
          }}
        >
          Categories
        </Link>
        <button
          type="button"
          onClick={handleSignOut}
          style={{
            marginTop: 'auto',
            padding: 8,
            background: 'none',
            border: 'none',
            cursor: 'pointer',
            textAlign: 'left',
            color: '#666',
          }}
        >
          Sign out
        </button>
      </aside>
      <main style={{ flex: 1, padding: 24 }}>{children}</main>
    </div>
  );
}
