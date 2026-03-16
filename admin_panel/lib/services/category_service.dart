import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Category>> getCategories() async {
    final snap = await _firestore
        .collection('categories')
        .orderBy('order')
        .get();
    return snap.docs
        .map((d) => Category.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

  Stream<List<Category>> categoriesStream() {
    return _firestore
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Category.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    await _firestore.collection('categories').add(data);
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _firestore.collection('categories').doc(id).update(data);
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.collection('categories').doc(id).delete();
  }
}
