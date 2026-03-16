import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../services/article_service.dart';
import '../../services/category_service.dart';
import '../../services/storage_service.dart';

class AdminArticleFormScreen extends StatefulWidget {
  final String? articleId;

  const AdminArticleFormScreen({super.key, this.articleId});

  @override
  State<AdminArticleFormScreen> createState() => _AdminArticleFormScreenState();
}

class _AdminArticleFormScreenState extends State<AdminArticleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  final _authorController = TextEditingController();
  String? _categoryId;
  DateTime _publishedAt = DateTime.now();
  String? _imageUrl;
  Uint8List? _pickedImageBytes;
  String _pickedExtension = 'jpg';
  bool _saving = false;
  List<Category> _categories = [];

  bool get isEditing => widget.articleId != null && widget.articleId != 'new';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (isEditing) _loadArticle();
  }

  Future<void> _loadCategories() async {
    final list = await context.read<CategoryService>().getCategories();
    if (mounted) setState(() => _categories = list);
  }

  Future<void> _loadArticle() async {
    final a = await context.read<ArticleService>().getArticle(widget.articleId!);
    if (a != null && mounted) {
      setState(() {
        _titleController.text = a.title;
        _descriptionController.text = a.description;
        _contentController.text = a.content;
        _authorController.text = a.author;
        _categoryId = a.categoryId;
        _publishedAt = a.publishedAt;
        _imageUrl = a.imageUrl;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes != null) {
      setState(() {
        _pickedImageBytes = file.bytes;
        _pickedExtension = file.extension ?? 'jpg';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final articleService = context.read<ArticleService>();
      final storageService = context.read<StorageService>();
      String? imageUrl = _imageUrl;
      String articleId = widget.articleId ?? '';

      if (isEditing) {
        articleId = widget.articleId!;
        if (_pickedImageBytes != null) {
          imageUrl = await storageService.uploadArticleImage(
            articleId,
            _pickedImageBytes!,
            _pickedExtension,
          );
        }
        await articleService.updateArticle(articleId, {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'content': _contentController.text.trim(),
          'author': _authorController.text.trim(),
          'categoryId': _categoryId ?? '',
          'imageUrl': imageUrl,
          'publishedAt': Timestamp.fromDate(_publishedAt),
        });
      } else {
        // Get ID first, upload image (if any), then create article in one write — no update step.
        articleId = articleService.generateArticleId();
        if (_pickedImageBytes != null) {
          imageUrl = await storageService.uploadArticleImage(
            articleId,
            _pickedImageBytes!,
            _pickedExtension,
          );
        }
        await articleService.createArticleWithId(articleId, {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'content': _contentController.text.trim(),
          'author': _authorController.text.trim(),
          'categoryId': _categoryId ?? '',
          'imageUrl': imageUrl,
          'publishedAt': Timestamp.fromDate(_publishedAt),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
        context.go('/admin/articles');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Article' : 'New Article'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _categoryId != null &&
                      _categories.any((c) => c.id == _categoryId)
                  ? _categoryId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Select category'),
                ),
                ..._categories
                    .map((c) => DropdownMenuItem<String?>(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Publish date'),
              subtitle: Text(DateFormat.yMMMd().format(_publishedAt)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _publishedAt,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _publishedAt = date);
              },
            ),
            const SizedBox(height: 16),
            const Text('Image', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            if (_imageUrl != null && _pickedImageBytes == null)
              Image.network(_imageUrl!, height: 120, fit: BoxFit.cover),
            if (_pickedImageBytes != null)
              Image.memory(_pickedImageBytes!, height: 120, fit: BoxFit.cover),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload image'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
