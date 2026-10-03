import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'data/categories.dart';
import 'l10n/app_localizations.dart';
import 'models/category_item.dart';
import 'models/transaction_record.dart';
import 'pages/record_page.dart';
import 'pages/statistics_page.dart';
import 'pages/icon_settings_page.dart';
import 'pages/record_management_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
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

  void _reorderGroup(
    bool income,
    bool custom,
    int oldIndex,
    int newIndex,
  ) {
    setState(() {
      final categories = income ? _incomeOrder : _expenseOrder;
      final builtIn = categories
          .where((category) => !category.isCustom)
          .toList();
      final customCategories = categories
          .where((category) => category.isCustom)
          .toList();
      final group = custom ? customCategories : builtIn;
      if (oldIndex < newIndex) newIndex -= 1;
      group.insert(newIndex, group.removeAt(oldIndex));

      categories
        ..clear()
        ..addAll(builtIn)
        ..addAll(customCategories);
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

  List<TransactionRecord> _readRecords(SharedPreferences prefs) {
    try {
      final list =
          jsonDecode(prefs.getString('transaction_records') ?? '[]') as List;
      return list
          .map(
            (item) => TransactionRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.keepOneCategory)),
      );
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
      _records
        ..clear()
        ..addAll(_readRecords(preferences));
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
    });
  }

  Future<void> _savePreferences() async {
    final preferences = _preferences;
    if (preferences == null) return;
    final expense = _hiddenExpenses.toList();
    final income = _hiddenIncome.toList();
    final expenseOrder = _expenseOrder.map((c) => c.id).toList();
    final incomeOrder = _incomeOrder.map((c) => c.id).toList();
    await preferences.setStringList('hidden_expenses', expense);
    await preferences.setStringList('hidden_income', income);
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
    await preferences.setString(
      'transaction_records',
      jsonEncode(_records.map((record) => record.toJson()).toList()),
    );
  }

  void _setVisibility(bool income, String path, bool visible) {
    final hidden = income ? _hiddenIncome : _hiddenExpenses;
    final categories = income ? _incomeOrder : _expenseOrder;
    if (!visible &&
        categories.where((c) => !hidden.contains(c.id)).length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.keepOneCategory)),
      );
      return;
    }
    setState(() {
      visible ? hidden.remove(path) : hidden.add(path);
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RecordPage(
            categories: _expenseOrder
                .where((c) => !_hiddenExpenses.contains(c.id))
                .toList(),
            transactionName: l10n.expense,
            isIncome: false,
            onRecorded: _addRecord,
          ),
          RecordPage(
            categories: _incomeOrder
                .where((c) => !_hiddenIncome.contains(c.id))
                .toList(),
            transactionName: l10n.income,
            isIncome: true,
            onRecorded: _addRecord,
          ),
          StatisticsPage(records: _records),
          RecordManagementPage(
            records: _records,
            expenseCategories: _expenseOrder,
            incomeCategories: _incomeOrder,
            onUpdated: _updateRecord,
            onDeleted: _deleteRecord,
          ),
          IconSizeSettingsPage(
            hiddenExpenses: _hiddenExpenses,
            hiddenIncome: _hiddenIncome,
            onVisibilityChanged: _setVisibility,
            expenseOrder: _expenseOrder,
            incomeOrder: _incomeOrder,
            onReorderGroup: _reorderGroup,
            onSaveCategory: _saveCategory,
            onDeleteCategory: _deleteCategory,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF26C6A0),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: l10n.expense,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.savings),
            label: l10n.income,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: l10n.statistics,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_alt),
            label: l10n.recordManagement,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.apps),
            label: l10n.iconSettings,
          ),
        ],
      ),
    );
  }

  void _addRecord(TransactionRecord record) {
    setState(() => _records.add(record));
    _savePreferences();
  }

  void _updateRecord(int index, TransactionRecord record) {
    setState(() => _records[index] = record);
    _savePreferences();
  }

  void _deleteRecord(int index) {
    setState(() => _records.removeAt(index));
    _savePreferences();
  }
}
