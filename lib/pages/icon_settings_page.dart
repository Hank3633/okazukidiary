import 'package:flutter/material.dart';

import '../widgets/category_icon.dart';
import 'category_editor.dart';

import '../models/category_item.dart';

class IconSizeSettingsPage extends StatefulWidget {
  const IconSizeSettingsPage({
    super.key,
    required this.selectedSize,
    required this.onSelected,
    required this.hiddenExpenses,
    required this.hiddenIncome,
    required this.onVisibilityChanged,
    required this.expenseOrder,
    required this.incomeOrder,
    required this.onReorder,
    required this.onSaveCategory,
    required this.onDeleteCategory,
  });

  final double selectedSize;
  final void Function(bool income, CategoryItem category) onSaveCategory;
  final void Function(bool income, CategoryItem category) onDeleteCategory;
  final ValueChanged<double> onSelected;
  final Set<String> hiddenExpenses;
  final Set<String> hiddenIncome;
  final List<CategoryItem> expenseOrder;
  final List<CategoryItem> incomeOrder;
  final void Function(bool income, int oldIndex, int newIndex) onReorder;
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('分類名稱已存在，請使用不同名稱')));
      return;
    }
    widget.onSaveCategory(income, result);
  }

  Future<void> _delete(bool income, CategoryItem category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('刪除「${category.label}」？'),
        content: const Text('此分類會從圖標清單移除，既有記錄與統計仍會保留。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) widget.onDeleteCategory(income, category);
  }

  @override
  Widget build(BuildContext context) {
    const sizes = [28.0, 32.0, 36.0];
    return Scaffold(
      appBar: AppBar(title: const Text('圖標設定'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Center(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('支出圖標')),
                  ButtonSegment(value: true, label: Text('收入圖標')),
                ],
                selected: {_showIncome},
                onSelectionChanged: (selection) =>
                    setState(() => _showIncome = selection.first),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '分類圖示尺寸',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('可直接切換並回到「記帳」頁查看效果。'),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: sizes
                  .map(
                    (size) => ChoiceChip(
                      label: Text('${size.toInt()} px'),
                      selected: widget.selectedSize == size,
                      onSelected: (_) => widget.onSelected(size),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            _section(
              _showIncome ? '收入圖標' : '支出圖標',
              _showIncome ? widget.incomeOrder : widget.expenseOrder,
              _showIncome ? widget.hiddenIncome : widget.hiddenExpenses,
              _showIncome,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    String title,
    List<CategoryItem> categories,
    Set<String> hidden,
    bool income,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Text('勾選顯示分類；拖曳右側把手調整順序。'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _edit(income),
          icon: const Icon(Icons.add),
          label: const Text('新增分類'),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: categories.length,
          onReorderItem: (oldIndex, newIndex) =>
              widget.onReorder(income, oldIndex, newIndex),
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
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('編輯')),
                        PopupMenuItem(value: 'delete', child: Text('刪除')),
                      ],
                    ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.drag_handle, semanticLabel: '拖曳排序'),
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
