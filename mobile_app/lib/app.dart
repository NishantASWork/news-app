import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/detail_screen.dart';
import 'screens/admin/articles_screen.dart';
import 'screens/admin/article_form_screen.dart';
import 'screens/admin/categories_screen.dart';
import 'widgets/admin_layout.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String systemKey = 'system';
  static const String lightKey = 'light';
  static const String darkKey = 'dark';

  ThemeNotifier({String initialModeKey = systemKey, this.onModeChanged})
      : _modeKey = initialModeKey;

  String _modeKey;
  final void Function(String modeKey)? onModeChanged;

  String get modeKey => _modeKey;
  ThemeMode get themeMode {
    switch (_modeKey) {
      case lightKey:
        return ThemeMode.light;
      case darkKey:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  void setMode(String key) {
    if (_modeKey == key) return;
    _modeKey = key;
    onModeChanged?.call(_modeKey);
    notifyListeners();
  }

  void cycleMode() {
    final next = _modeKey == systemKey
        ? lightKey
        : _modeKey == lightKey
            ? darkKey
            : systemKey;
    setMode(next);
  }

  bool get isDark => _modeKey == darkKey;
}


class App extends StatelessWidget {
  const App({super.key, this.scaffoldKey});

  final GlobalKey<ScaffoldMessengerState>? scaffoldKey;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final isLoggedIn = auth.currentUser != null;
        final goRouter = GoRouter(
          initialLocation: '/',
          redirect: (context, state) {
            final loc = state.matchedLocation;
            final onLogin = loc == '/login';
            if (!isLoggedIn && !onLogin) return '/login';
            if (isLoggedIn && onLogin) return '/';
            if (isLoggedIn && (loc.startsWith('/admin') || loc == '/admin')) {
              if (!auth.isAdmin) return '/';
            }
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
                  path: '/admin/articles',
                  builder: (_, __) => const AdminArticlesScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (_, __) => const AdminArticleFormScreen(articleId: 'new'),
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (context, state) {
                        final id = state.pathParameters['id']!;
                        return AdminArticleFormScreen(articleId: id == 'new' ? 'new' : id);
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: '/admin/categories',
                  builder: (_, __) => const AdminCategoriesScreen(),
                ),
              ],
            ),
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) => Scaffold(
                body: navigationShell,
                bottomNavigationBar: NavigationBar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) => navigationShell.goBranch(index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.bookmark_border),
                      selectedIcon: Icon(Icons.bookmark),
                      label: 'Bookmarks',
                    ),
                  ],
                ),
              ),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/',
                      builder: (_, __) => const HomeScreen(),
                    ),
                  ],
                ),
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: '/bookmarks',
                      builder: (_, __) => const BookmarksScreen(),
                    ),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/article/:id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return DetailScreen(articleId: id);
              },
            ),
          ],
        );
        return Consumer<ThemeNotifier>(
          builder: (context, theme, _) {
            if (scaffoldKey != null) {
              final notifier = context.read<NotificationService>();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                notifier.setGoRouter(goRouter);
              });
            }
            return MaterialApp.router(
            scaffoldMessengerKey: scaffoldKey,
            title: 'News App',
            theme: ThemeData.from(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            darkTheme: ThemeData.from(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            themeMode: theme.themeMode,
            routerConfig: goRouter,
          );
          },
        );
      },
    );
  }
}
