import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import 'imgbb_env_io.dart' if (dart.library.html) 'imgbb_env_web.dart' as env;

/// Uploads article images to ImgBB (free). Image URL is then stored in Firestore.
/// Get a free API key at https://api.imgbb.com/
///
/// Set via environment variable (mobile/desktop) or dart-define (all platforms):
///   export IMGBB_API_KEY=your_key
///   flutter run -d chrome
/// or:
///   flutter run --dart-define=IMGBB_API_KEY=your_key
class StorageService {
  static String get _apiKey {
    final fromEnv = env.getImgBbApiKey();
    if (fromEnv.isNotEmpty) return fromEnv;
    final fromDefine = const String.fromEnvironment('IMGBB_API_KEY', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;
    return '';
  }

  static const _uploadUrl = 'https://api.imgbb.com/1/upload';

  Future<String> uploadArticleImage(String articleId, Uint8List bytes, String extension) async {
    if (_apiKey.isEmpty) {
      throw ImageUploadException(
        'ImgBB API key missing. Get a free key at https://api.imgbb.com/ '
        'then set env: export IMGBB_API_KEY=your_key '
        'or run with: --dart-define=IMGBB_API_KEY=your_key',
      );
    }
    final base64Image = base64Encode(bytes);
    final response = await http.post(
      Uri.parse('$_uploadUrl?key=$_apiKey'),
      body: {'image': base64Image},
    );
    if (response.statusCode != 200) {
      throw ImageUploadException(
        'Image upload failed (${response.statusCode}). ${response.body}',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final success = json['success'] as bool? ?? false;
    if (!success) {
      final error = json['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? response.body;
      throw ImageUploadException('Image upload failed: $message');
    }
    final data = json['data'] as Map<String, dynamic>?;
    final url = data?['url'] as String?;
    if (url == null || url.isEmpty) {
      throw ImageUploadException('Image upload succeeded but no URL returned.');
    }
    return url;
  }

  /// ImgBB hosts images externally; we don't delete them from here.
  Future<void> deleteArticleImage(String pathOrUrl) async {
    // No-op: images stay on ImgBB.
  }
}

class ImageUploadException implements Exception {
  final String message;
  ImageUploadException(this.message);
  @override
  String toString() => message;
}
