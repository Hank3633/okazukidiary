import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'data/categories.dart';
import 'models/category_item.dart';
import 'models/transaction_record.dart';
import 'pages/record_page.dart';
import 'pages/statistics_page.dart';
import 'pages/icon_settings_page.dart';
import 'pages/placeholder_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  double _categoryIconSize = 36;
  final List<TransactionRecord> _records = [];
  Set<String> _hiddenExpenses = {};
  Set<String> _hiddenIncome = {};
  SharedPreferences? _preferences;
  List<CategoryItem> _expenseOrder = List.of(expenseCategories);
  List<CategoryItem> _incomeOrder = List.of(incomeCategories);

  List<CategoryItem> _restoreOrder(
    List<CategoryItem> defaults,
    List<String>? paths,
  ) {
    final byPath = {for (final category in defaults) category.id: category};
    return [
      for (final path in paths ?? <String>[])
        if (byPath.containsKey(path)) byPath.remove(path)!,
      ...byPath.values,
    ];
  }

  void _reorder(bool income, int oldIndex, int newIndex) {
    setState(() {
      final categories = income ? _incomeOrder : _expenseOrder;
      categories.insert(newIndex, categories.removeAt(oldIndex));
    });
    _savePreferences();
  }

  List<CategoryItem> _readCustom(SharedPreferences prefs, String key) {
    try {
      final list = jsonDecode(prefs.getString(key) ?? '[]') as List;
      return list
          .map(
            (item) =>
                CategoryItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _saveCategory(bool income, CategoryItem category) {
    setState(() {
      final list = income ? _incomeOrder : _expenseOrder;
      final index = list.indexWhere((c) => c.id == category.id);
      if (index < 0) {
        list.add(category);
      } else {
        list[index] = category;
      }
    });
    _savePreferences();
  }

  void _deleteCategory(bool income, CategoryItem category) {
    final list = income ? _incomeOrder : _expenseOrder;
    final hidden = income ? _hiddenIncome : _hiddenExpenses;
    if (!hidden.contains(category.id) &&
        list.where((c) => !hidden.contains(c.id)).length <= 1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('至少保留一個分類')));
      return;
    }
    setState(() {
      list.removeWhere((c) => c.id == category.id);
      hidden.remove(category.id);
    });
    _savePreferences();
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _expenseOrder = _restoreOrder([
        ...expenseCategories,
        ..._readCustom(preferences, 'custom_expenses'),
      ], preferences.getStringList('expense_order'));
      _incomeOrder = _restoreOrder([
        ...incomeCategories,
        ..._readCustom(preferences, 'custom_income'),
      ], preferences.getStringList('income_order'));
      _hiddenExpenses = (preferences.getStringList('hidden_expenses') ?? [])
          .toSet();
      _hiddenIncome = (preferences.getStringList('hidden_income') ?? [])
          .toSet();
      if (_expenseOrder.every((c) => _hiddenExpenses.contains(c.id))) {
        _hiddenExpenses.clear();
      }
      if (_incomeOrder.every((c) => _hiddenIncome.contains(c.id))) {
        _hiddenIncome.clear();
      }
      final size = preferences.getDouble('category_icon_size');
      if ([28.0, 32.0, 36.0].contains(size)) _categoryIconSize = size!;
    });
  }

  Future<void> _savePreferences() async {
    final preferences = _preferences;
    if (preferences == null) return;
    final expense = _hiddenExpenses.toList();
    final income = _hiddenIncome.toList();
    final size = _categoryIconSize;
    final expenseOrder = _expenseOrder.map((c) => c.id).toList();
    final incomeOrder = _incomeOrder.map((c) => c.id).toList();
    await preferences.setStringList('hidden_expenses', expense);
    await preferences.setStringList('hidden_income', income);
    await preferences.setDouble('category_icon_size', size);
    await preferences.setStringList('expense_order', expenseOrder);
    await preferences.setStringList('income_order', incomeOrder);
    await preferences.setString(
      'custom_expenses',
      jsonEncode(
        _expenseOrder.where((c) => c.isCustom).map((c) => c.toJson()).toList(),
      ),
    );
    await preferences.setString(
      'custom_income',
      jsonEncode(
        _incomeOrder.where((c) => c.isCustom).map((c) => c.toJson()).toList(),
      ),
    );
  }

  void _setVisibility(bool income, String path, bool visible) {
    final hidden = income ? _hiddenIncome : _hiddenExpenses;
    final categories = income ? _incomeOrder : _expenseOrder;
    if (!visible &&
        categories.where((c) => !hidden.contains(c.id)).length <= 1) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('至少保留一個分類')));
      return;
    }
    setState(() {
      visible ? hidden.remove(path) : hidden.add(path);
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RecordPage(
            iconSize: _categoryIconSize,
            categories: _expenseOrder
                .where((c) => !_hiddenExpenses.contains(c.id))
                .toList(),
            transactionName: '支出',
            onRecorded: _addRecord,
          ),
          RecordPage(
            iconSize: _categoryIconSize,
            categories: _incomeOrder
                .where((c) => !_hiddenIncome.contains(c.id))
                .toList(),
            transactionName: '收入',
            onRecorded: _addRecord,
          ),
          IconSizeSettingsPage(
            selectedSize: _categoryIconSize,
            onSelected: (size) {
              setState(() => _categoryIconSize = size);
              _savePreferences();
            },
            hiddenExpenses: _hiddenExpenses,
            hiddenIncome: _hiddenIncome,
            onVisibilityChanged: _setVisibility,
            expenseOrder: _expenseOrder,
            incomeOrder: _incomeOrder,
            onReorder: _reorder,
            onSaveCategory: _saveCategory,
            onDeleteCategory: _deleteCategory,
          ),
          StatisticsPage(records: _records),
          const PlaceholderPage(title: '設定', icon: Icons.settings),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF26C6A0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '記帳'),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: '收入'),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: '圖標設定'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '收支統計'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
      ),
    );
  }

  void _addRecord(TransactionRecord record) =>
      setState(() => _records.add(record));
}
