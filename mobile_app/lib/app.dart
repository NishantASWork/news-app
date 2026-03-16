import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/detail_screen.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier({bool initialDark = false, this.onToggle}) : _isDark = initialDark;
  bool _isDark;
  final void Function(bool isDark)? onToggle;
  bool get isDark => _isDark;
  set isDark(bool v) {
    if (_isDark == v) return;
    _isDark = v;
    onToggle?.call(_isDark);
    notifyListeners();
  }
  void toggle() {
    _isDark = !_isDark;
    onToggle?.call(_isDark);
    notifyListeners();
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, auth, _) {
        final isLoggedIn = auth.currentUser != null;
        final goRouter = GoRouter(
          initialLocation: '/',
          redirect: (context, state) {
            final onLogin = state.matchedLocation == '/login';
            if (!isLoggedIn && !onLogin) return '/login';
            if (isLoggedIn && onLogin) return '/';
            return null;
          },
          routes: [
            GoRoute(
              path: '/login',
              builder: (_, __) => const LoginScreen(),
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
          builder: (context, theme, _) => MaterialApp.router(
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
            themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
            routerConfig: goRouter,
          ),
        );
      },
    );
  }
}
