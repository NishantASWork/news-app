'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';
import { useTheme } from '@/contexts/ThemeContext';
import { sendPushNotification } from '@/lib/sendNotification';

export function AdminLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { signOut } = useAuth();
  const { preference, cyclePreference } = useTheme();
  const [notificationStatus, setNotificationStatus] = useState<'idle' | 'sending' | 'success' | 'error'>('idle');
  const [notificationMessage, setNotificationMessage] = useState('');

  const handleSignOut = async () => {
    await signOut();
    router.replace('/login');
  };

  const handleSendNotification = async () => {
    setNotificationStatus('sending');
    setNotificationMessage('');
    const result = await sendPushNotification();
    if (result.ok) {
      setNotificationStatus('success');
      setNotificationMessage(result.message ?? 'Notification sent to all devices.');
    } else {
      setNotificationStatus('error');
      setNotificationMessage(result.error ?? 'Failed to send');
    }
    setTimeout(() => setNotificationStatus('idle'), 3000);
  };

  return (
    <div className="admin-shell">
      <aside className="admin-sidebar">
        <div className="admin-sidebar-brand">News Admin</div>
        <nav className="admin-nav">
          <Link
            href="/articles"
            className={`nav-link ${pathname.startsWith('/articles') ? 'active' : ''}`}
          >
            <ArticlesIcon />
            Articles
          </Link>
          <Link
            href="/categories"
            className={`nav-link ${pathname.startsWith('/categories') ? 'active' : ''}`}
          >
            <CategoriesIcon />
            Categories
          </Link>
        </nav>
        <div className="admin-sidebar-actions">
          <button
            type="button"
            onClick={cyclePreference}
            className="admin-theme-btn"
            title={`Theme: ${preference} (click to cycle)`}
          >
            <ThemeIcon preference={preference} />
            {preference === 'system' ? 'System' : preference === 'light' ? 'Light' : 'Dark'}
          </button>
          <button
            type="button"
            onClick={handleSendNotification}
            disabled={notificationStatus === 'sending'}
            title="Click to send push notification to all app devices"
            className={`admin-push-btn ${notificationStatus}`}
          >
            {notificationStatus === 'sending' && <span className="admin-spinner" />}
            {notificationStatus === 'success' && <CheckIcon />}
            {notificationStatus === 'error' && <AlertIcon />}
            {notificationStatus === 'idle' && <BellIcon />}
            {notificationStatus === 'sending' && 'Sending...'}
            {notificationStatus === 'success' && 'Sent'}
            {notificationStatus === 'error' && 'Failed'}
            {notificationStatus === 'idle' && 'Send to all devices'}
          </button>
          {notificationMessage && (
            <span className="admin-push-message">{notificationMessage}</span>
          )}
        </div>
        <button type="button" className="admin-signout" onClick={handleSignOut}>
          <SignOutIcon />
          Sign out
        </button>
      </aside>
      <main className="admin-main">{children}</main>
    </div>
  );
}

function ArticlesIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
      <polyline points="14 2 14 8 20 8" />
      <line x1="16" y1="13" x2="8" y2="13" />
      <line x1="16" y1="17" x2="8" y2="17" />
      <polyline points="10 9 9 9 8 9" />
    </svg>
  );
}

function CategoriesIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z" />
    </svg>
  );
}

function BellIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
      <path d="M13.73 21a2 2 0 0 1-3.46 0" />
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="20 6 9 17 4 12" />
    </svg>
  );
}

function AlertIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="10" />
      <line x1="12" y1="8" x2="12" y2="12" />
      <line x1="12" y1="16" x2="12.01" y2="16" />
    </svg>
  );
}

function ThemeIcon({ preference }: { preference: string }) {
  if (preference === 'dark') {
    return (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
      </svg>
    );
  }
  if (preference === 'light') {
    return (
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
        <circle cx="12" cy="12" r="5" />
        <line x1="12" y1="1" x2="12" y2="3" />
        <line x1="12" y1="21" x2="12" y2="23" />
        <line x1="4.22" y1="4.22" x2="5.64" y2="5.64" />
        <line x1="18.36" y1="18.36" x2="19.78" y2="19.78" />
        <line x1="1" y1="12" x2="3" y2="12" />
        <line x1="21" y1="12" x2="23" y2="12" />
        <line x1="4.22" y1="19.78" x2="5.64" y2="18.36" />
        <line x1="18.36" y1="5.64" x2="19.78" y2="4.22" />
      </svg>
    );
  }
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <rect x="2" y="3" width="20" height="14" rx="2" ry="2" />
      <line x1="8" y1="21" x2="16" y2="21" />
      <line x1="12" y1="17" x2="12" y2="21" />
    </svg>
  );
}

function SignOutIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
      <polyline points="16 17 21 12 16 7" />
      <line x1="21" y1="12" x2="9" y2="12" />
    </svg>
  );
}
