import 'dart:io';

/// Reads IMGBB_API_KEY from the process environment (e.g. export IMGBB_API_KEY=...).
String getImgBbApiKey() => Platform.environment['IMGBB_API_KEY'] ?? '';
