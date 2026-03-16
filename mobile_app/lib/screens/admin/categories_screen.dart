import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Category>>(
        stream: context.read<CategoryService>().categoriesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No categories. Add one.'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add category'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final c = categories[index];
              return Card(
                child: ListTile(
                  title: Text(c.name),
                  subtitle: Text(c.slug),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCategory(context, c),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (slugController.text.isEmpty) {
                  slugController.text = nameController.text
                      .toLowerCase()
                      .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: slugController,
              decoration: const InputDecoration(
                labelText: 'Slug',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<CategoryService>().createCategory({
        'name': nameController.text.trim(),
        'slug': slugController.text.trim(),
        'order': 0,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category added')));
      }
    }
    nameController.dispose();
    slugController.dispose();
  }

  Future<void> _deleteCategory(BuildContext context, Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Delete "${c.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<CategoryService>().deleteCategory(c.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    }
  }
}
