import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/article_service.dart';
import 'services/category_service.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/articles_screen.dart';
import 'screens/article_form_screen.dart';
import 'screens/categories_screen.dart';
import 'widgets/admin_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ArticleService>(create: (_) => ArticleService()),
        Provider<CategoryService>(create: (_) => CategoryService()),
        Provider<StorageService>(create: (_) => StorageService()),
      ],
      child: const AdminApp(),
    ),
  );
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final isLoggedIn = auth.currentUser != null;
        final router = GoRouter(
          initialLocation: '/articles',
          redirect: (context, state) {
            final onLogin = state.matchedLocation == '/login';
            if (!isLoggedIn && !onLogin) return '/login';
            if (isLoggedIn && onLogin) return '/articles';
            return null;
          },
          routes: [
            GoRoute(
              path: '/login',
              builder: (_, __) => const LoginScreen(),
            ),
            ShellRoute(
              builder: (context, state, child) => AdminLayout(child: child),
              routes: [
                GoRoute(
                  path: '/articles',
                  builder: (_, __) => const ArticlesScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (_, __) => const ArticleFormScreen(articleId: 'new'),
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (context, state) {
                        final id = state.pathParameters['id']!;
                        return ArticleFormScreen(articleId: id == 'new' ? 'new' : id);
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: '/categories',
                  builder: (_, __) => const CategoriesScreen(),
                ),
              ],
            ),
          ],
        );
        return MaterialApp.router(
          title: 'News Admin',
          theme: ThemeData.from(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
          ).copyWith(
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              contentTextStyle: const TextStyle(fontSize: 13),
            ),
          ),
          routerConfig: router,
        );
      },
    );
  }
}
