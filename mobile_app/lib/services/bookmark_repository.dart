import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/article.dart';

class BookmarkRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  Future<void> addBookmark(String articleId) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(articleId)
        .set({'articleId': articleId, 'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> removeBookmark(String articleId) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(articleId)
        .delete();
  }

  Future<bool> isBookmarked(String articleId) async {
    final uid = _uid;
    if (uid == null) return false;
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .doc(articleId)
        .get();
    return doc.exists;
  }

  Stream<List<String>> bookmarkIdsStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => d.data()['articleId'] as String? ?? d.id)
            .where((id) => id.isNotEmpty)
            .toList());
  }

  Future<List<Article>> getBookmarkedArticles() async {
    final uid = _uid;
    if (uid == null) return [];
    final bookmarksSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .orderBy('createdAt', descending: true)
        .get();
    if (bookmarksSnap.docs.isEmpty) return [];
    final ids = bookmarksSnap.docs
        .map((d) => d.data()['articleId'] as String? ?? d.id)
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return [];
    final articles = <Article>[];
    for (final id in ids) {
      final doc = await _firestore.collection('articles').doc(id).get();
      if (doc.exists && doc.data() != null) {
        articles.add(Article.fromFirestore(doc));
      }
    }
    return articles;
  }

  /// Stream of bookmarked articles — updates in real time when user adds/removes bookmarks.
  Stream<List<Article>> bookmarkedArticlesStream() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((bookmarksSnap) async {
          if (bookmarksSnap.docs.isEmpty) return <Article>[];
          final ids = bookmarksSnap.docs
              .map((d) => d.data()['articleId'] as String? ?? d.id)
              .where((id) => id.isNotEmpty)
              .toList();
          if (ids.isEmpty) return <Article>[];
          final articles = <Article>[];
          for (final id in ids) {
            final doc = await _firestore.collection('articles').doc(id).get();
            if (doc.exists && doc.data() != null) {
              articles.add(Article.fromFirestore(doc));
            }
          }
          return articles;
        });
  }
}
