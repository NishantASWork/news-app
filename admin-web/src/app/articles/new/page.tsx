'use client';

import { useRouter } from 'next/navigation';
import { ArticleForm } from '@/components/ArticleForm';

export default function NewArticlePage() {
  const router = useRouter();
  return (
    <div>
      <h1 className="page-title">New article</h1>
      <ArticleForm
        articleId={null}
        onSaved={() => router.push('/articles')}
        onCancel={() => router.back()}
      />
    </div>
  );
}
