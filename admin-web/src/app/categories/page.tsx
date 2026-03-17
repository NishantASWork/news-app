'use client';

import { useEffect, useMemo, useState } from 'react';
import {
  collection,
  onSnapshot,
  addDoc,
  deleteDoc,
  doc,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { useDebounce } from '@/hooks/useDebounce';
import type { Category } from '@/types/category';

/** Search by category name only. */
function categoryMatchesSearch(c: Category, q: string): boolean {
  const terms = q
    .trim()
    .toLowerCase()
    .split(/\s+/)
    .filter((s) => s.length > 0);
  if (terms.length === 0) return true;
  const name = c.name.toLowerCase();
  return terms.every((term) => name.includes(term));
}

export default function CategoriesPage() {
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [newName, setNewName] = useState('');
  const [adding, setAdding] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const debouncedQuery = useDebounce(searchQuery, 280);

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

  const filteredCategories = useMemo(
    () => categories.filter((c) => categoryMatchesSearch(c, debouncedQuery)),
    [categories, debouncedQuery]
  );

  if (loading) {
    return (
      <div>
        <div className="skeleton" style={{ width: 140, height: 32, marginBottom: 24 }} />
        <div className="card" style={{ padding: 24 }}>
          <div className="skeleton" style={{ width: '100%', height: 44, marginBottom: 16 }} />
          {[1, 2, 3].map((i) => (
            <div key={i} className="skeleton" style={{ width: '100%', height: 52, marginBottom: 8, borderRadius: 8 }} />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div>
      <h1 className="page-title">Categories</h1>
      <div className="card categories-form-card">
        <form onSubmit={handleAdd} className="categories-form">
          <div className="form-group" style={{ marginBottom: 0, flex: 1 }}>
            <label className="label" htmlFor="category-name">Category name</label>
            <input
              id="category-name"
              type="text"
              className="input"
              placeholder="e.g. Technology"
              value={newName}
              onChange={(e) => setNewName(e.target.value)}
            />
          </div>
          <button type="submit" className="btn btn-primary" disabled={adding} style={{ alignSelf: 'flex-end' }}>
            {adding ? 'Adding...' : 'Add category'}
          </button>
        </form>
      </div>
      {categories.length > 0 && (
        <div className="admin-search-wrap" style={{ marginTop: 24, marginBottom: 0 }}>
          <div className="admin-search-field">
            <span className="admin-search-icon" aria-hidden>
              <SearchIcon />
            </span>
            <input
              type="search"
              className="input admin-search-input"
              placeholder="Search by category name…"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              aria-label="Search categories"
            />
          </div>
          {searchQuery && (
            <button
              type="button"
              className="admin-search-clear"
              onClick={() => setSearchQuery('')}
              aria-label="Clear search"
            >
              <ClearIcon />
            </button>
          )}
          <span className="admin-search-count">
            {searchQuery
              ? `${filteredCategories.length} of ${categories.length} categor${categories.length === 1 ? 'y' : 'ies'}`
              : `${categories.length} categor${categories.length === 1 ? 'y' : 'ies'}`}
          </span>
        </div>
      )}
      <div className="card" style={{ marginTop: 24 }}>
        {categories.length === 0 ? (
          <div className="empty-state">
            No categories yet. Add one above.
          </div>
        ) : filteredCategories.length === 0 ? (
          <div className="empty-state">
            No categories match &quot;{searchQuery.trim()}&quot;. Try different words or clear search.
          </div>
        ) : (
          <ul className="categories-list">
            {filteredCategories.map((c) => (
              <li key={c.id} className="categories-item">
                <span className="categories-item-name">{c.name}</span>
                <span className="categories-item-slug">{c.slug}</span>
                <button type="button" className="btn btn-danger" onClick={() => handleDelete(c.id)}>
                  Delete
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}

function SearchIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="11" cy="11" r="8" />
      <path d="m21 21-4.35-4.35" />
    </svg>
  );
}

function ClearIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <path d="M18 6 6 18" />
      <path d="m6 6 12 12" />
    </svg>
  );
}
