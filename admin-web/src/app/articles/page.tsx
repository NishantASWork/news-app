'use client';

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useDebounce } from '@/hooks/useDebounce';
import {
  collection,
  orderBy,
  query,
  onSnapshot,
  deleteDoc,
  doc,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import type { Article } from '@/types/article';
import type { Category } from '@/types/category';
import type { Timestamp } from 'firebase/firestore';

function toArticle(id: string, data: Record<string, unknown>): Article {
  const publishedAt = (data.publishedAt as Timestamp)?.toDate?.() ?? new Date();
  return {
    id,
    title: (data.title as string) ?? '',
    description: (data.description as string) ?? '',
    content: (data.content as string) ?? '',
    categoryId: (data.categoryId as string) ?? '',
    imageUrl: (data.imageUrl as string) ?? null,
    author: (data.author as string) ?? '',
    publishedAt,
  };
}

/** Search by title only: all words must match. */
function searchTerms(q: string): string[] {
  return q
    .trim()
    .toLowerCase()
    .split(/\s+/)
    .filter((s) => s.length > 0);
}

function matchesSearch(article: Article, q: string): boolean {
  const terms = searchTerms(q);
  if (terms.length === 0) return true;
  const title = article.title.toLowerCase();
  return terms.every((term) => title.includes(term));
}

export default function ArticlesPage() {
  const [articles, setArticles] = useState<Article[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const debouncedQuery = useDebounce(searchQuery, 280);

  useEffect(() => {
    const unsub = onSnapshot(collection(db, 'categories'), (snap) => {
      const list = snap.docs.map((d) => {
        const data = d.data();
        return {
          id: d.id,
          name: (data.name as string) ?? '',
          description: (data.description as string) ?? '',
          slug: (data.slug as string) ?? '',
          order: (data.order as number) ?? 0,
        };
      });
      list.sort((a, b) => a.order - b.order);
      setCategories(list);
    });
    return () => unsub();
  }, []);

  useEffect(() => {
    const q = query(
      collection(db, 'articles'),
      orderBy('publishedAt', 'desc')
    );
    const unsub = onSnapshot(q, (snap) => {
      setArticles(
        snap.docs.map((d) => toArticle(d.id, d.data() as Record<string, unknown>))
      );
      setLoading(false);
    });
    return () => unsub();
  }, []);

  const filteredArticles = useMemo(
    () => articles.filter((a) => matchesSearch(a, debouncedQuery)),
    [articles, debouncedQuery]
  );

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this article?')) return;
    await deleteDoc(doc(db, 'articles', id));
  };

  if (loading) {
    return (
      <div>
        <div className="articles-header">
          <div className="skeleton" style={{ width: 160, height: 32 }} />
          <div className="skeleton" style={{ width: 120, height: 40 }} />
        </div>
        <div className="card" style={{ padding: 24 }}>
          {[1, 2, 3].map((i) => (
            <div key={i} style={{ display: 'flex', gap: 16, alignItems: 'center', padding: '16px 0', borderBottom: '1px solid var(--admin-border)' }}>
              <div className="skeleton" style={{ width: 80, height: 56, borderRadius: 8 }} />
              <div style={{ flex: 1 }}>
                <div className="skeleton" style={{ width: '70%', height: 18, marginBottom: 8 }} />
                <div className="skeleton" style={{ width: '40%', height: 14 }} />
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  const categoryName = (categoryId: string) =>
    categories.find((c) => c.id === categoryId)?.name ?? '';

  return (
    <div>
      <div className="articles-header">
        <h1 className="page-title" style={{ marginBottom: 0 }}>Articles</h1>
        <Link href="/articles/new" className="btn btn-primary">
          <PlusIcon />
          Add article
        </Link>
      </div>
      {articles.length > 0 && (
        <div className="admin-search-wrap" style={{ marginBottom: 16 }}>
          <div className="admin-search-field">
            <span className="admin-search-icon" aria-hidden>
              <SearchIcon />
            </span>
            <input
              type="search"
              className="input admin-search-input"
              placeholder="Search by article title…"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              aria-label="Search articles"
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
              ? `${filteredArticles.length} of ${articles.length} article${articles.length === 1 ? '' : 's'}`
              : `${articles.length} article${articles.length === 1 ? '' : 's'}`}
          </span>
        </div>
      )}
      <div className="card">
        {articles.length === 0 ? (
          <div className="empty-state">
            <p style={{ marginBottom: 8 }}>No articles yet.</p>
            <Link href="/articles/new" className="btn btn-primary" style={{ marginTop: 16 }}>
              Add your first article
            </Link>
          </div>
        ) : filteredArticles.length === 0 ? (
          <div className="empty-state">
            <p style={{ marginBottom: 8 }}>
              No articles match &quot;{searchQuery.trim()}&quot;. Try different words or clear search.
            </p>
          </div>
        ) : (
          <ul className="articles-list">
            {filteredArticles.map((a) => (
              <li key={a.id} className="articles-item">
                {a.imageUrl ? (
                  <img src={a.imageUrl} alt="" className="articles-item-image" />
                ) : (
                  <div className="articles-item-placeholder" />
                )}
                <div className="articles-item-body">
                  <Link href={`/articles/${a.id}`} className="articles-item-title">
                    {a.title}
                  </Link>
                  <div className="articles-item-meta">
                    {categoryName(a.categoryId) && (
                      <span style={{ marginRight: 8 }}>{categoryName(a.categoryId)}</span>
                    )}
                    {a.author} · {a.publishedAt.toLocaleDateString()}
                  </div>
                </div>
                <button
                  type="button"
                  className="btn btn-danger"
                  onClick={() => handleDelete(a.id)}
                >
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

function PlusIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <line x1="12" y1="5" x2="12" y2="19" />
      <line x1="5" y1="12" x2="19" y2="12" />
    </svg>
  );
}
