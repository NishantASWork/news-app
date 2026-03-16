import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String slug;
  final int order;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.order = 0,
  });

  factory Category.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Category(
      id: doc.id,
      name: data['name'] as String? ?? '',
      slug: data['slug'] as String? ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }
}
