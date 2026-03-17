'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/AuthContext';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isRegister, setIsRegister] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { user, signIn, register, signInWithGoogle } = useAuth();
  const router = useRouter();

  if (user) {
    router.replace('/articles');
    return null;
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      if (isRegister) await register(email, password);
      else await signIn(email, password);
      router.replace('/articles');
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Authentication failed');
    } finally {
      setLoading(false);
    }
  };

  const handleGoogle = async () => {
    setError('');
    setLoading(true);
    try {
      await signInWithGoogle();
      router.replace('/articles');
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Google sign-in failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ maxWidth: 400, margin: '48px auto', padding: 24 }}>
      <h1 style={{ marginBottom: 8 }}>News Admin</h1>
      <p style={{ color: '#666', marginBottom: 24 }}>
        {isRegister ? 'Create an account' : 'Sign in to continue'}
      </p>
      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        <input
          type="email"
          placeholder="Email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          style={{ padding: 12, border: '1px solid #ccc', borderRadius: 8 }}
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          minLength={isRegister ? 6 : 1}
          style={{ padding: 12, border: '1px solid #ccc', borderRadius: 8 }}
        />
        {error && <p style={{ color: 'crimson', fontSize: 14 }}>{error}</p>}
        <button
          type="submit"
          disabled={loading}
          style={{
            padding: 12,
            background: '#1976d2',
            color: 'white',
            border: 'none',
            borderRadius: 8,
            cursor: loading ? 'not-allowed' : 'pointer',
          }}
        >
          {loading ? 'Please wait...' : isRegister ? 'Register' : 'Sign In'}
        </button>
      </form>
      <button
        type="button"
        onClick={handleGoogle}
        disabled={loading}
        style={{
          marginTop: 16,
          width: '100%',
          padding: 12,
          background: '#fff',
          border: '1px solid #ccc',
          borderRadius: 8,
          cursor: loading ? 'not-allowed' : 'pointer',
        }}
      >
        Continue with Google
      </button>
      <button
        type="button"
        onClick={() => { setIsRegister(!isRegister); setError(''); }}
        style={{ marginTop: 16, background: 'none', border: 'none', cursor: 'pointer', color: '#666', fontSize: 14 }}
      >
        {isRegister ? 'Already have an account? Sign in' : 'Need an account? Register'}
      </button>
    </div>
  );
}
