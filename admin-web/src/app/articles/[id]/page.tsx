'use client';

import { useParams, useRouter } from 'next/navigation';
import { ArticleForm } from '@/components/ArticleForm';

export default function EditArticlePage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;
  if (id === 'new') {
    router.replace('/articles/new');
    return null;
  }
  return (
    <div>
      <h1 style={{ marginBottom: 24 }}>Edit article</h1>
      <ArticleForm
        articleId={id}
        onSaved={() => router.push('/articles')}
        onCancel={() => router.back()}
      />
    </div>
  );
}
