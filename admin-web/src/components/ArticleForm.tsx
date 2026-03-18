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
        description: (d.data().description as string) ?? '',
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

  if (loading) {
    return (
      <div className="card" style={{ padding: 24 }}>
        <div className="skeleton" style={{ width: '100%', height: 44, marginBottom: 20 }} />
        <div className="skeleton" style={{ width: '80%', height: 44, marginBottom: 20 }} />
        <div className="skeleton" style={{ width: '100%', height: 120, marginBottom: 20 }} />
      </div>
    );
  }

  return (
    <div className="card article-form-card">
      <form onSubmit={handleSubmit} className="article-form">
        <div className="form-group">
          <label className="label" htmlFor="title">Title</label>
          <input
            id="title"
            type="text"
            className="input"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
            placeholder="Article title"
          />
        </div>
        <div className="form-group">
          <label className="label" htmlFor="description">Description</label>
          <input
            id="description"
            type="text"
            className="input"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="Short description"
          />
        </div>
        <div className="form-group">
          <label className="label" htmlFor="content">Content</label>
          <textarea
            id="content"
            className="textarea"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            required
            rows={6}
            placeholder="Full article content..."
          />
        </div>
        <div className="article-form-row">
          <div className="form-group" style={{ flex: 1 }}>
            <label className="label" htmlFor="author">Author</label>
            <input
              id="author"
              type="text"
              className="input"
              value={author}
              onChange={(e) => setAuthor(e.target.value)}
              required
              placeholder="Author name"
            />
          </div>
          <div className="form-group" style={{ flex: 1 }}>
            <label className="label" htmlFor="category">Category</label>
            <select
              id="category"
              className="select"
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
            >
              <option value="">— Select —</option>
              {categories.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>
        </div>
        <div className="form-group">
          <label className="label" htmlFor="publishedAt">Publish date</label>
          <input
            id="publishedAt"
            type="datetime-local"
            className="input"
            value={publishedAt}
            onChange={(e) => setPublishedAt(e.target.value)}
          />
        </div>
        <div className="form-group">
          <label className="label">Image</label>
          <div className="article-form-image">
            {imageUrl && (
              <div className="article-form-image-preview">
                <img src={imageUrl} alt="Current" />
              </div>
            )}
            <div className="article-form-image-upload">
              <input
                type="file"
                accept="image/*"
                id="image-upload"
                onChange={(e) => {
                  const f = e.target.files?.[0];
                  setImageFile(f ?? null);
                  if (f) setImageUrl(null);
                }}
                className="article-form-file-input"
              />
              <label htmlFor="image-upload" className="article-form-file-label">
                {imageFile ? imageFile.name : 'Choose image'}
              </label>
            </div>
          </div>
        </div>
        {error && <p className="article-form-error">{error}</p>}
        <div className="article-form-actions">
          <button type="submit" className="btn btn-primary" disabled={saving}>
            {saving ? 'Saving...' : 'Save'}
          </button>
          <button type="button" className="btn btn-secondary" onClick={onCancel}>
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}
