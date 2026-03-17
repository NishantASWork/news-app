import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../app.dart';
import '../models/article.dart';
import '../models/category.dart';
import '../services/article_repository.dart';
import '../services/category_repository.dart';
import '../widgets/article_card.dart';
import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PagingController<DocumentSnapshot?, Article> _pagingController =
      PagingController(firstPageKey: null);
  static const int _pageSize = 10;
  final ArticleRepository _articleRepo = ArticleRepository();
  List<Category> _categories = [];
  String? _selectedCategoryId;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _categoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final repo = CategoryRepository();
    final list = await repo.getCategories();
    if (mounted) setState(() {
      _categories = list;
      _categoriesLoading = false;
    });
  }

  Future<void> _fetchPage(DocumentSnapshot? cursor) async {
    try {
      final result = await _articleRepo.getArticles(
        categoryId: _selectedCategoryId,
        startAfter: cursor,
        useCache: cursor == null,
      );
      final list = result.articles;
      final filtered = _searchQuery.isEmpty
          ? list
          : list
              .where((a) =>
                  a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  a.description.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
      final isLast = list.length < _pageSize;
      if (isLast) {
        _pagingController.appendLastPage(filtered);
      } else {
        _pagingController.appendPage(filtered, result.lastDoc);
      }
    } catch (e) {
      _pagingController.error = e;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    _articleRepo.clearCache();
    _pagingController.refresh();
  }

  void _applyFilter(String? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _articleRepo.clearCache();
    _pagingController.refresh();
  }

  void _applySearch(String query) {
    setState(() => _searchQuery = query);
    _pagingController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('News'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Push notifications are enabled. When the server sends a notification, it will appear here.',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
          ),
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
            onPressed: _refresh,
          ),
        ],
      ),
      body: _categoriesLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search news...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _applySearch,
            ),
          ),
          if (_categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategoryId == null,
                      onSelected: (_) => _applyFilter(null),
                    ),
                  ),
                  ..._categories.map((c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(c.name),
                          selected: _selectedCategoryId == c.id,
                          onSelected: (_) => _applyFilter(c.id),
                        ),
                      )),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _pagingController.refresh(),
              child: PagedListView<DocumentSnapshot?, Article>.separated(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<Article>(
                  itemBuilder: (context, article, index) {
                    final categoryName = _categories
                        .cast<Category?>()
                        .firstWhere(
                          (c) => c?.id == article.categoryId,
                          orElse: () => null,
                        )
                        ?.name;
                    return ArticleCard(
                      article: article,
                      categoryName: categoryName,
                      onTap: () => context.push('/article/${article.id}'),
                    );
                  },
                  firstPageErrorIndicatorBuilder: (context) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        Text('${_pagingController.error}'),
                        TextButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  noItemsFoundIndicatorBuilder: (context) => const Center(
                    child: Text('No articles found'),
                  ),
                ),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

