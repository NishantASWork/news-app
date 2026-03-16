import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'services/auth_service.dart';

const _keyDarkMode = 'dark_mode';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final darkMode = prefs.getBool(_keyDarkMode) ?? false;
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(
            initialDark: darkMode,
            onToggle: (v) => prefs.setBool(_keyDarkMode, v),
          ),
        ),
      ],
      child: const App(),
    ),
  );
}
