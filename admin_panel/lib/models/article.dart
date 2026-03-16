import 'package:cloud_firestore/cloud_firestore.dart';

class Article {
  final String id;
  final String title;
  final String description;
  final String content;
  final String categoryId;
  final String? imageUrl;
  final String author;
  final DateTime publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Article({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.categoryId,
    this.imageUrl,
    required this.author,
    required this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Article.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Article(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      content: data['content'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      author: data['author'] as String? ?? '',
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'author': author,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
