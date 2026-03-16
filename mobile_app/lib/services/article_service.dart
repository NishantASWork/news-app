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

  Future<String> createArticle(Map<String, dynamic> data) async {
    final ref = await _firestore.collection('articles').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateArticle(String id, Map<String, dynamic> data) async {
    await _firestore.collection('articles').doc(id).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteArticle(String id) async {
    await _firestore.collection('articles').doc(id).delete();
  }
}
