import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text(
                'News Admin',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Articles'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/articles');
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/categories');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.newspaper),
              title: const Text('Back to News'),
              onTap: () {
                Navigator.pop(context);
                context.go('/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthService>().signOut();
              },
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}
