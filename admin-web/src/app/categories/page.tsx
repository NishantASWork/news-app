'use client';

import { useEffect, useState } from 'react';
import {
  collection,
  onSnapshot,
  addDoc,
  deleteDoc,
  doc,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import type { Category } from '@/types/category';

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [newName, setNewName] = useState('');
  const [adding, setAdding] = useState(false);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'categories'), (snap) => {
      const list = snap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          name: (data.name as string) ?? '',
          slug: (data.slug as string) ?? '',
          order: (data.order as number) ?? 0,
        };
      });
      list.sort((a, b) => a.order - b.order);
      setCategories(list);
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const handleAdd = async (e: React.FormEvent) => {
    e.preventDefault();
    const name = newName.trim();
    if (!name) return;
    setAdding(true);
    try {
      await addDoc(collection(db, 'categories'), {
        name,
        slug: name.toLowerCase().replace(/\s+/g, '-'),
        order: categories.length,
      });
      setNewName('');
    } finally {
      setAdding(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this category?')) return;
    await deleteDoc(doc(db, 'categories', id));
  };

  if (loading) return <p>Loading categories...</p>;

  return (
    <div>
      <h1 style={{ marginBottom: 24 }}>Categories</h1>
      <form
        onSubmit={handleAdd}
        style={{ display: 'flex', gap: 12, marginBottom: 24, alignItems: 'center' }}
      >
        <input
          value={newName}
          onChange={(e) => setNewName(e.target.value)}
          placeholder="Category name"
          style={{ padding: 12, border: '1px solid #ccc', borderRadius: 8, width: 240 }}
        />
        <button
          type="submit"
          disabled={adding}
          style={{
            padding: '10px 20px',
            background: '#1976d2',
            color: 'white',
            border: 'none',
            borderRadius: 8,
            cursor: adding ? 'not-allowed' : 'pointer',
          }}
        >
          Add category
        </button>
      </form>
      <ul style={{ listStyle: 'none' }}>
        {categories.map((c) => (
          <li
            key={c.id}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 16,
              padding: '12px 0',
              borderBottom: '1px solid #eee',
            }}
          >
            <span style={{ flex: 1, fontWeight: 500 }}>{c.name}</span>
            <span style={{ fontSize: 14, color: '#666' }}>{c.slug}</span>
            <button
              type="button"
              onClick={() => handleDelete(c.id)}
              style={{
                padding: '6px 12px',
                background: '#fff',
                border: '1px solid #ccc',
                borderRadius: 6,
                cursor: 'pointer',
                color: '#c62828',
              }}
            >
              Delete
            </button>
          </li>
        ))}
      </ul>
      {categories.length === 0 && <p style={{ color: '#666' }}>No categories yet. Add one above.</p>}
    </div>
  );
}
