import { AuthGuard } from '@/components/AuthGuard';
import { AdminLayout } from '@/components/AdminLayout';

export default function CategoriesLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AuthGuard>
      <AdminLayout>{children}</AdminLayout>
    </AuthGuard>
  );
}
