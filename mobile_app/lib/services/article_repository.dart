// Redis-style cache-aside: we keep an in-memory cache with TTL (see _cacheTtl).
// List and detail reads check cache first; on miss or expiry we hit Firestore and
// populate the cache. Paginated/filtered list queries only use cache for the first
// page with no category filter. clearCache() invalidates everything (e.g. on
// pull-to-refresh). See project README for the high-level explanation.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/article.dart';

const int _pageSize = 10;
const Duration _cacheTtl = Duration(minutes: 5);

class ArticleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Article>? _listCache;
  DateTime? _listCacheTime;
  final Map<String, Article> _detailCache = {};
  final Map<String, DateTime> _detailCacheTime = {};

  /// Returns articles and the last document snapshot for pagination (null if no next page).
  Future<({List<Article> articles, DocumentSnapshot? lastDoc})> getArticles({
    String? categoryId,
    DocumentSnapshot? startAfter,
    bool useCache = true,
  }) async {
    if (useCache && categoryId == null && startAfter == null && _listCache != null && _listCacheTime != null) {
      if (DateTime.now().difference(_listCacheTime!) < _cacheTtl) {
        return (articles: _listCache!, lastDoc: null);
      }
    }
    Query<Map<String, dynamic>> q = _firestore
        .collection('articles')
        .orderBy('publishedAt', descending: true)
        .limit(_pageSize);
    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId);
    }
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    final snap = await q.get();
    final list = snap.docs.map((d) => Article.fromFirestore(d)).toList();
    if (categoryId == null && startAfter == null) {
      _listCache = list;
      _listCacheTime = DateTime.now();
    }
    final lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
    return (articles: list, lastDoc: lastDoc);
  }

  Future<Article?> getArticleById(String id, {bool useCache = true}) async {
    if (useCache && _detailCache.containsKey(id)) {
      final t = _detailCacheTime[id];
      if (t != null && DateTime.now().difference(t) < _cacheTtl) {
        return _detailCache[id];
      }
    }
    final doc = await _firestore.collection('articles').doc(id).get();
    if (!doc.exists) return null;
    final article = Article.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
    _detailCache[id] = article;
    _detailCacheTime[id] = DateTime.now();
    return article;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> articlesStream({String? categoryId}) {
    Query<Map<String, dynamic>> q = _firestore
        .collection('articles')
        .orderBy('publishedAt', descending: true)
        .limit(50);
    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId);
    }
    return q.snapshots();
  }

  void clearCache() {
    _listCache = null;
    _listCacheTime = null;
    _detailCache.clear();
    _detailCacheTime.clear();
  }
}
