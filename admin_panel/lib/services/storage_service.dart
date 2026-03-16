import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadArticleImage(String articleId, Uint8List bytes, String extension) async {
    final ref = _storage.ref().child('articles').child('$articleId.$extension');
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }

  Future<void> deleteArticleImage(String pathOrUrl) async {
    try {
      final ref = _storage.refFromURL(pathOrUrl);
      await ref.delete();
    } catch (_) {
      // Ignore if ref from path
    }
  }
}
