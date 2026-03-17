import type { Timestamp } from 'firebase/firestore';

export interface Article {
  id: string;
  title: string;
  description: string;
  content: string;
  categoryId: string;
  imageUrl: string | null;
  author: string;
  publishedAt: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

export interface ArticleData {
  title: string;
  description: string;
  content: string;
  categoryId: string;
  imageUrl: string | null;
  author: string;
  publishedAt: Timestamp;
}
