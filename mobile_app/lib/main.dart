import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/article_service.dart';
import 'services/category_service.dart';
import 'services/storage_service.dart';

const _keyThemeMode = 'theme_mode'; // 'system' | 'light' | 'dark'

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final modeKey = prefs.getString(_keyThemeMode) ?? 'system';
  final scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  final notificationService = NotificationService(scaffoldKey: scaffoldKey);
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<NotificationService>.value(value: notificationService),
        Provider<ArticleService>(create: (_) => ArticleService()),
        Provider<CategoryService>(create: (_) => CategoryService()),
        Provider<StorageService>(create: (_) => StorageService()),
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(
            initialModeKey: modeKey,
            onModeChanged: (key) => prefs.setString(_keyThemeMode, key),
          ),
        ),
      ],
      child: App(scaffoldKey: scaffoldKey),
    ),
  );
  notificationService.init();
}
