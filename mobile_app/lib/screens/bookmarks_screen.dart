import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app.dart';
import '../models/article.dart';
import '../models/category.dart';
import '../services/bookmark_repository.dart';
import '../services/category_repository.dart';
import 'package:go_router/go_router.dart';
import '../widgets/article_card.dart';
import '../widgets/app_drawer.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarkRepository _bookmarkRepo = BookmarkRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await _categoryRepo.getCategories();
    if (mounted) setState(() => _categories = list);
  }

  String? _categoryName(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId).name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('My Bookmarks'),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeNotifier>().modeKey == ThemeNotifier.darkKey
                  ? Icons.light_mode
                  : context.watch<ThemeNotifier>().modeKey == ThemeNotifier.lightKey
                      ? Icons.dark_mode
                      : Icons.brightness_auto,
            ),
            onPressed: () => context.read<ThemeNotifier>().cycleMode(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: StreamBuilder<List<Article>>(
        stream: _bookmarkRepo.bookmarkedArticlesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(snapshot.error.toString()),
                ],
              ),
            );
          }
          final articles = snapshot.data ?? [];
          if (articles.isEmpty) {
            return const Center(
              child: Text('No bookmarks yet. Save articles from the home screen.'),
            );
          }
          return RefreshIndicator(
            onRefresh: _loadCategories,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: articles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final article = articles[index];
                return ArticleCard(
                  article: article,
                  categoryName: _categoryName(article.categoryId),
                  onTap: () => context.push('/article/${article.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
