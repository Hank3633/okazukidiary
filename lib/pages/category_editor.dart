import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../data/categories.dart';
import '../l10n/app_localizations.dart';
import '../models/category_item.dart';
import '../widgets/category_icon.dart';

class CategoryEditor extends StatefulWidget {
  const CategoryEditor({super.key, this.category});
  final CategoryItem? category;
  @override
  State<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<CategoryEditor> {
  late final TextEditingController _name;
  late String _image;
  late Color _color;
  String? _error;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category?.label ?? '');
    _image = widget.category?.imagePath ?? expenseCategories.first.imagePath;
    _color = widget.category?.color ?? const Color(0xFF26C6A0);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: '圖片',
            extensions: ['png', 'jpg', 'jpeg', 'webp'],
            mimeTypes: ['image/png', 'image/jpeg', 'image/webp'],
            uniformTypeIdentifiers: ['public.image'],
          ),
        ],
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      final decoded = await decodeImageFromList(bytes);
      decoded.dispose();
      if (!mounted) return;
      setState(() {
        _image = file.path;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.imageReadFailed);
      }
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '請輸入分類名稱');
      return;
    }
    setState(() => _saving = true);
    try {
      var image = _image;
      if (!image.startsWith('assets/')) {
        final directory = await getApplicationSupportDirectory();
        final folder = Directory('${directory.path}/category_images');
        await folder.create(recursive: true);
        if (!image.startsWith('${folder.path}/')) {
          final destination =
              '${folder.path}/${DateTime.now().microsecondsSinceEpoch}.png';
          await File(image).copy(destination);
          image = destination;
        }
      }
      if (!mounted) return;
      Navigator.pop(
        context,
        CategoryItem(
          image,
          name,
          _color,
          customId:
              widget.category?.customId ??
              'custom_${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppLocalizations.of(context)!.imageSaveFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const colors = [
      Colors.lightBlue,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.brown,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category == null ? l10n.addCategory : l10n.editCategory,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CategoryIcon(
              category: CategoryItem(_image, '', _color),
              size: 80,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            maxLength: 20,
            decoration: InputDecoration(labelText: l10n.categoryName),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          OutlinedButton.icon(
            onPressed: _saving ? null : _import,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(l10n.importImage),
          ),
          Text(l10n.selectBuiltInIcon),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [...expenseCategories, ...incomeCategories]
                .map(
                  (c) => InkWell(
                    onTap: () => setState(() => _image = c.imagePath),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _image == c.imagePath
                              ? Colors.teal
                              : Colors.transparent,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CategoryIcon(category: c),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Text(l10n.statisticsColor),
          Wrap(
            spacing: 8,
            children: colors
                .map(
                  (color) => IconButton(
                    onPressed: () => setState(() => _color = color),
                    icon: Icon(
                      _color.toARGB32() == color.toARGB32()
                          ? Icons.check_circle
                          : Icons.circle,
                      color: color,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? l10n.saving : l10n.saveCategory),
          ),
        ],
      ),
    );
  }
}
