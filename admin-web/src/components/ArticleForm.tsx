'use client';

import { useEffect, useState } from 'react';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  collection,
  serverTimestamp,
  Timestamp,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { uploadArticleImage } from '@/lib/storage';
import type { Article } from '@/types/article';
import type { Category } from '@/types/category';
import type { Timestamp as FSTimestamp } from 'firebase/firestore';

type ArticleFormProps = {
  articleId: string | null;
  onSaved: () => void;
  onCancel: () => void;
};

export function ArticleForm({ articleId, onSaved, onCancel }: ArticleFormProps) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [content, setContent] = useState('');
  const [author, setAuthor] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [publishedAt, setPublishedAt] = useState(() =>
    new Date().toISOString().slice(0, 16)
  );
  const [imageUrl, setImageUrl] = useState<string | null>(null);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(!!articleId);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    const loadCategories = async () => {
      const { collection: col, getDocs } = await import('firebase/firestore');
      const snap = await getDocs(col(db, 'categories'));
      const list = snap.docs.map((d) => ({
        id: d.id,
        name: (d.data().name as string) ?? '',
        slug: (d.data().slug as string) ?? '',
        order: (d.data().order as number) ?? 0,
      }));
      list.sort((a, b) => a.order - b.order);
      setCategories(list);
    };
    loadCategories();
  }, []);

  useEffect(() => {
    if (!articleId) return;
    const load = async () => {
      const d = await getDoc(doc(db, 'articles', articleId));
      if (!d.exists()) {
        setLoading(false);
        return;
      }
      const data = d.data();
      setTitle((data?.title as string) ?? '');
      setDescription((data?.description as string) ?? '');
      setContent((data?.content as string) ?? '');
      setAuthor((data?.author as string) ?? '');
      setCategoryId((data?.categoryId as string) ?? '');
      const pt = data?.publishedAt as FSTimestamp | undefined;
      if (pt?.toDate) {
        setPublishedAt(pt.toDate().toISOString().slice(0, 16));
      }
      setImageUrl((data?.imageUrl as string) ?? null);
      setLoading(false);
    };
    load();
  }, [articleId]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setSaving(true);
    try {
      let finalImageUrl = imageUrl;
      const id = articleId ?? doc(collection(db, 'articles')).id;

      if (imageFile) {
        finalImageUrl = await uploadArticleImage(id, imageFile);
      }

      const payload = {
        title: title.trim(),
        description: description.trim(),
        content: content.trim(),
        author: author.trim(),
        categoryId: categoryId || '',
        imageUrl: finalImageUrl,
        publishedAt: Timestamp.fromDate(new Date(publishedAt)),
        updatedAt: serverTimestamp(),
      };

      if (articleId) {
        await updateDoc(doc(db, 'articles', id), payload);
      } else {
        await setDoc(doc(db, 'articles', id), {
          ...payload,
          createdAt: serverTimestamp(),
        });
      }
      onSaved();
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to save');
    } finally {
      setSaving(false);
    }
  };

  if (loading) return <p>Loading...</p>;

  const formStyle = { display: 'flex', flexDirection: 'column' as const, gap: 16, maxWidth: 600 };
  const inputStyle = { padding: 12, border: '1px solid #ccc', borderRadius: 8 };
  const labelStyle = { fontWeight: 600, fontSize: 14 };

  return (
    <form onSubmit={handleSubmit} style={formStyle}>
      <div>
        <label style={labelStyle}>Title</label>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          required
          style={{ ...inputStyle, width: '100%' }}
        />
      </div>
      <div>
        <label style={labelStyle}>Description</label>
        <input
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          style={{ ...inputStyle, width: '100%' }}
        />
      </div>
      <div>
        <label style={labelStyle}>Content</label>
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          required
          rows={6}
          style={{ ...inputStyle, width: '100%' }}
        />
      </div>
      <div>
        <label style={labelStyle}>Author</label>
        <input
          value={author}
          onChange={(e) => setAuthor(e.target.value)}
          required
          style={{ ...inputStyle, width: '100%' }}
        />
      </div>
      <div>
        <label style={labelStyle}>Category</label>
        <select
          value={categoryId}
          onChange={(e) => setCategoryId(e.target.value)}
          style={inputStyle}
        >
          <option value="">— Select —</option>
          {categories.map((c) => (
            <option key={c.id} value={c.id}>
              {c.name}
            </option>
          ))}
        </select>
      </div>
      <div>
        <label style={labelStyle}>Publish date</label>
        <input
          type="datetime-local"
          value={publishedAt}
          onChange={(e) => setPublishedAt(e.target.value)}
          style={inputStyle}
        />
      </div>
      <div>
        <label style={labelStyle}>Image</label>
        {imageUrl && (
          <div style={{ marginBottom: 8 }}>
            <img
              src={imageUrl}
              alt="Current"
              style={{ maxWidth: 200, maxHeight: 120, objectFit: 'cover', borderRadius: 8 }}
            />
          </div>
        )}
        <input
          type="file"
          accept="image/*"
          onChange={(e) => {
            const f = e.target.files?.[0];
            setImageFile(f ?? null);
            if (f) setImageUrl(null);
          }}
        />
        {imageFile && <span style={{ marginLeft: 8 }}>{imageFile.name}</span>}
      </div>
      {error && <p style={{ color: 'crimson' }}>{error}</p>}
      <div style={{ display: 'flex', gap: 12 }}>
        <button
          type="submit"
          disabled={saving}
          style={{
            padding: '10px 20px',
            background: '#1976d2',
            color: 'white',
            border: 'none',
            borderRadius: 8,
            cursor: saving ? 'not-allowed' : 'pointer',
          }}
        >
          {saving ? 'Saving...' : 'Save'}
        </button>
        <button
          type="button"
          onClick={onCancel}
          style={{
            padding: '10px 20px',
            background: '#fff',
            border: '1px solid #ccc',
            borderRadius: 8,
            cursor: 'pointer',
          }}
        >
          Cancel
        </button>
      </div>
    </form>
  );
}
