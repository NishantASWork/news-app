import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/article.dart';
import '../models/category.dart';
import '../services/article_repository.dart';
import '../services/bookmark_repository.dart';
import '../services/category_repository.dart';

class DetailScreen extends StatefulWidget {
  final String articleId;

  const DetailScreen({super.key, required this.articleId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ArticleRepository _articleRepo = ArticleRepository();
  final BookmarkRepository _bookmarkRepo = BookmarkRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  Article? _article;
  String? _categoryName;
  bool _isBookmarked = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? _categoryNameFor(List<Category> list, String id) {
    try {
      return list.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return null;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final article = await _articleRepo.getArticleById(widget.articleId);
      final categories = await _categoryRepo.getCategories();
      final bookmarked = await _bookmarkRepo.isBookmarked(widget.articleId);
      if (mounted) {
        setState(() {
          _article = article;
          _categoryName = article != null
              ? _categoryNameFor(categories, article!.categoryId)
              : null;
          _isBookmarked = bookmarked;
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

  Future<void> _toggleBookmark() async {
    if (_article == null) return;
    try {
      if (_isBookmarked) {
        await _bookmarkRepo.removeBookmark(_article!.id);
      } else {
        await _bookmarkRepo.addBookmark(_article!.id);
      }
      if (mounted) {
        setState(() => _isBookmarked = !_isBookmarked);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isBookmarked ? 'Bookmarked' : 'Removed from bookmarks'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _share() {
    if (_article == null) return;
    Share.share(
      '${_article!.title}\n\n${_article!.description}',
      subject: _article!.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _article == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(_error ?? 'Article not found'),
              ],
            ),
          ),
        ),
      );
    }
    final article = _article!;
    final dateStr = DateFormat.yMMMd().add_jm().format(article.publishedAt);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: article.imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                placeholder: (_, __) => const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => const SizedBox(height: 220),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_categoryName != null && _categoryName!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Chip(label: Text(_categoryName!)),
                    ),
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${article.author} · $dateStr',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
