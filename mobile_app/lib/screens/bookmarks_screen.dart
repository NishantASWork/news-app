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
  List<Article> _articles = [];
  List<Category> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final articles = await _bookmarkRepo.getBookmarkedArticles();
      final categories = await _categoryRepo.getCategories();
      if (mounted) {
        setState(() {
          _articles = articles;
          _categories = categories;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Bookmarks')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(_error!),
              TextButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
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
            onPressed: _load,
          ),
        ],
      ),
      body: _articles.isEmpty
          ? const Center(
              child: Text('No bookmarks yet. Save articles from the home screen.'),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _articles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final article = _articles[index];
                  return ArticleCard(
                    article: article,
                    categoryName: _categoryName(article.categoryId),
                    onTap: () => context.push('/article/${article.id}'),
                  );
                },
              ),
            ),
    );
  }
}
