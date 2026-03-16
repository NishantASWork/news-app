import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/article.dart';

class ArticleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Article>> getArticles() async {
    final snap = await _firestore
        .collection('articles')
        .orderBy('publishedAt', descending: true)
        .get();
    return snap.docs
        .map((d) => Article.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  Stream<List<Article>> articlesStream() {
    return _firestore
        .collection('articles')
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Article.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<Article?> getArticle(String id) async {
    final doc = await _firestore.collection('articles').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Article.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
  }

  /// Generates a new document ID without writing. Use with [createArticleWithId] after uploading images.
  String generateArticleId() {
    return _firestore.collection('articles').doc().id;
  }

  /// Creates an article with the given ID and data (e.g. after uploading image with this id).
  Future<void> createArticleWithId(String id, Map<String, dynamic> data) async {
    await _firestore.collection('articles').doc(id).set({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateArticle(String id, Map<String, dynamic> data) async {
    await _firestore.collection('articles').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteArticle(String id) async {
    await _firestore.collection('articles').doc(id).delete();
  }
}
