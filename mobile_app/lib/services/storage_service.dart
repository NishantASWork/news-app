import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadArticleImage(String articleId, Uint8List bytes, String extension) async {
    final ref = _storage.ref().child('articles').child('$articleId.$extension');
    try {
      await ref.putData(bytes);
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      // -13010 = OBJECT_NOT_FOUND (404): bucket missing or wrong, or Storage not enabled
      if (e.code == 'object-not-found' ||
          e.code == 'storage/object-not-found' ||
          (e.message?.contains('404') ?? false)) {
        throw StorageUploadException(
          'Storage upload failed (404). Enable Firebase Storage: '
          'Console → Build → Storage → Get started. If already enabled, ensure the project is on Blaze plan if required.',
          cause: e,
        );
      }
      rethrow;
    }
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

/// Thrown when a storage upload fails with a known cause (e.g. 404 / bucket not set up).
class StorageUploadException implements Exception {
  final String message;
  final FirebaseException? cause;

  StorageUploadException(this.message, {this.cause});

  @override
  String toString() => cause != null ? '$message (${cause!.message})' : message;
}
