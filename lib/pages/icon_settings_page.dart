import 'package:flutter/material.dart';

import '../widgets/category_icon.dart';
import '../l10n/app_localizations.dart';
import 'category_editor.dart';

import '../models/category_item.dart';

class IconSizeSettingsPage extends StatefulWidget {
  const IconSizeSettingsPage({
    super.key,
    required this.hiddenExpenses,
    required this.hiddenIncome,
    required this.onVisibilityChanged,
    required this.expenseOrder,
    required this.incomeOrder,
    required this.onReorderGroup,
    required this.onSaveCategory,
    required this.onDeleteCategory,
  });

  final void Function(bool income, CategoryItem category) onSaveCategory;
  final void Function(bool income, CategoryItem category) onDeleteCategory;
  final Set<String> hiddenExpenses;
  final Set<String> hiddenIncome;
  final List<CategoryItem> expenseOrder;
  final List<CategoryItem> incomeOrder;
  final void Function(bool income, bool custom, int oldIndex, int newIndex)
  onReorderGroup;
  final void Function(bool income, String path, bool visible)
  onVisibilityChanged;

  @override
  State<IconSizeSettingsPage> createState() => _IconSizeSettingsPageState();
}

class _IconSizeSettingsPageState extends State<IconSizeSettingsPage> {
  bool _showIncome = false;

  Future<void> _edit(bool income, [CategoryItem? category]) async {
    final result = await Navigator.push<CategoryItem>(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryEditor(category: category),
      ),
    );
    if (!mounted || result == null) return;
    final list = income ? widget.incomeOrder : widget.expenseOrder;
    if (list.any((c) => c.id != result.id && c.label == result.label)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.categoryNameExists),
        ),
      );
      return;
    }
    widget.onSaveCategory(income, result);
  }

  Future<void> _delete(bool income, CategoryItem category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.deleteCategoryTitle(category.label),
        ),
        content: Text(AppLocalizations.of(context)!.deleteCategoryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) widget.onDeleteCategory(income, category);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.iconSettings), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Center(
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.expenseIcons)),
                  ButtonSegment(value: true, label: Text(l10n.incomeIcons)),
                ],
                selected: {_showIncome},
                onSelectionChanged: (selection) =>
                    setState(() => _showIncome = selection.first),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _edit(_showIncome),
              icon: const Icon(Icons.add),
              label: Text(l10n.addCategory),
            ),
            const SizedBox(height: 20),
            _section(
              title: l10n.builtInCategories,
              categories: (_showIncome
                      ? widget.incomeOrder
                      : widget.expenseOrder)
                  .where((category) => !category.isCustom)
                  .toList(),
              _showIncome ? widget.hiddenIncome : widget.hiddenExpenses,
              _showIncome,
              custom: false,
            ),
            const SizedBox(height: 24),
            _section(
              title: l10n.customCategories,
              categories: (_showIncome
                      ? widget.incomeOrder
                      : widget.expenseOrder)
                  .where((category) => category.isCustom)
                  .toList(),
              _showIncome ? widget.hiddenIncome : widget.hiddenExpenses,
              _showIncome,
              custom: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required List<CategoryItem> categories,
    required Set<String> hidden,
    required bool income,
    required bool custom,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(l10n.showAndReorderHint),
        const SizedBox(height: 8),
        if (categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(l10n.noCustomCategories),
          ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: categories.length,
          onReorder: (oldIndex, newIndex) =>
              widget.onReorderGroup(income, custom, oldIndex, newIndex),
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              key: ValueKey(category.id),
              contentPadding: EdgeInsets.zero,
              leading: Checkbox(
                value: !hidden.contains(category.id),
                onChanged: (visible) {
                  if (visible != null) {
                    widget.onVisibilityChanged(income, category.id, visible);
                  }
                },
              ),
              title: Row(
                children: [
                  CategoryIcon(category: category),
                  const SizedBox(width: 12),
                  Expanded(child: Text(category.label)),
                ],
              ),
              onTap: category.isCustom ? () => _edit(income, category) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (category.isCustom)
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          _edit(income, category);
                        } else {
                          _delete(income, category);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(l10n.editCategory),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.drag_handle,
                        semanticLabel: l10n.dragToReorder,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
