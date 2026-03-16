import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/article.dart';
import '../../models/category.dart';
import '../../services/article_service.dart';
import '../../services/category_service.dart';
import 'article_form_screen.dart';

class AdminArticlesScreen extends StatelessWidget {
  const AdminArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/articles/new'),
          ),
        ],
      ),
      body: StreamBuilder<List<Article>>(
        stream: context.read<ArticleService>().articlesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final articles = snapshot.data ?? [];
          if (articles.isEmpty) {
            return const Center(child: Text('No articles yet. Add one.'));
          }
          return FutureBuilder<List<Category>>(
            future: context.read<CategoryService>().getCategories(),
            builder: (context, catSnap) {
              final categories = catSnap.data ?? [];
              String categoryName(String id) {
                try {
                  return categories.firstWhere((c) => c.id == id).name;
                } catch (_) {
                  return '';
                }
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: articles.length,
                itemBuilder: (context, index) {
                  final a = articles[index];
                  return Card(
                    child: ListTile(
                      title: Text(a.title),
                      subtitle: Text(
                        '${categoryName(a.categoryId)} · ${a.author}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => context.push('/admin/articles/${a.id}'),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, a),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Article a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete article?'),
        content: Text('Delete "${a.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<ArticleService>().deleteArticle(a.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    }
  }
}
