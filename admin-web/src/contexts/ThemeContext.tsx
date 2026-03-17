'use client';

import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';

const STORAGE_KEY = 'admin-theme';

export type ThemePreference = 'light' | 'dark' | 'system';

type ThemeContextValue = {
  preference: ThemePreference;
  setPreference: (p: ThemePreference) => void;
  cyclePreference: () => void;
  resolved: 'light' | 'dark';
};

const ThemeContext = createContext<ThemeContextValue | null>(null);

function getSystemDark(): boolean {
  if (typeof window === 'undefined') return false;
  return window.matchMedia('(prefers-color-scheme: dark)').matches;
}

function resolveTheme(preference: ThemePreference): 'light' | 'dark' {
  if (preference === 'system') return getSystemDark() ? 'dark' : 'light';
  return preference;
}

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [preference, setPreferenceState] = useState<ThemePreference>('system');
  const [resolved, setResolved] = useState<'light' | 'dark'>('light');
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY) as ThemePreference | null;
    if (stored === 'light' || stored === 'dark' || stored === 'system') {
      setPreferenceState(stored);
    }
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!mounted) return;
    const next = resolveTheme(preference);
    setResolved(next);
    document.documentElement.setAttribute('data-theme', next);
  }, [preference, mounted]);

  useEffect(() => {
    if (!mounted || preference !== 'system') return;
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const handle = () => setResolved(getSystemDark() ? 'dark' : 'light');
    mq.addEventListener('change', handle);
    return () => mq.removeEventListener('change', handle);
  }, [preference, mounted]);

  const setPreference = useCallback((p: ThemePreference) => {
    setPreferenceState(p);
    if (typeof window !== 'undefined') localStorage.setItem(STORAGE_KEY, p);
  }, []);

  const cyclePreference = useCallback(() => {
    const next: ThemePreference =
      preference === 'system' ? 'light' : preference === 'light' ? 'dark' : 'system';
    setPreference(next);
  }, [preference, setPreference]);

  const value: ThemeContextValue = {
    preference,
    setPreference,
    cyclePreference,
    resolved,
  };

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
}
