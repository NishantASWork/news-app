'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
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

export default function ArticlesPage() {
  const [articles, setArticles] = useState<Article[]>([]);
  const [loading, setLoading] = useState(true);

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

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this article?')) return;
    await deleteDoc(doc(db, 'articles', id));
  };

  if (loading) return <p>Loading articles...</p>;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <h1>Articles</h1>
        <Link
          href="/articles/new"
          style={{
            padding: '10px 20px',
            background: '#1976d2',
            color: 'white',
            borderRadius: 8,
          }}
        >
          Add article
        </Link>
      </div>
      <ul style={{ listStyle: 'none' }}>
        {articles.map((a) => (
          <li
            key={a.id}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 16,
              padding: '12px 0',
              borderBottom: '1px solid #eee',
            }}
          >
            {a.imageUrl && (
              <img
                src={a.imageUrl}
                alt=""
                style={{ width: 80, height: 56, objectFit: 'cover', borderRadius: 4 }}
              />
            )}
            <div style={{ flex: 1 }}>
              <Link href={`/articles/${a.id}`} style={{ fontWeight: 600 }}>
                {a.title}
              </Link>
              <div style={{ fontSize: 14, color: '#666' }}>
                {a.author} · {a.publishedAt.toLocaleDateString()}
              </div>
            </div>
            <button
              type="button"
              onClick={() => handleDelete(a.id)}
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
      {articles.length === 0 && <p style={{ color: '#666' }}>No articles yet.</p>}
    </div>
  );
}
