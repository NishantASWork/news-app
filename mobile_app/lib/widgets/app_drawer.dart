import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'News App',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin panel'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/articles');
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
    );
  }
}
