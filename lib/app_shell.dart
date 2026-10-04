import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'data/categories.dart';
import 'l10n/app_localizations.dart';
import 'models/category_item.dart';
import 'models/ledger_account.dart';
import 'models/transaction_record.dart';
import 'models/account_transfer.dart';
import 'pages/record_page.dart';
import 'pages/statistics_page.dart';
import 'pages/icon_settings_page.dart';
import 'pages/record_management_page.dart';
import 'pages/account_management_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final List<TransactionRecord> _records = [];
  List<AccountTransfer> _transfers = [];
  Set<String> _hiddenExpenses = {};
  Set<String> _hiddenIncome = {};
  SharedPreferences? _preferences;
  List<CategoryItem> _expenseOrder = List.of(expenseCategories);
  List<CategoryItem> _incomeOrder = List.of(incomeCategories);
  List<LedgerAccount> _accounts = const [
    LedgerAccount(id: 'cash', name: '現金帳戶'),
  ];

  List<LedgerAccount> _readAccounts(SharedPreferences prefs) {
    try {
      final values =
          jsonDecode(prefs.getString('ledger_accounts') ?? '[]') as List;
      final loaded = values
          .map(
            (value) =>
                LedgerAccount.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .map(
            (account) => switch (account.id) {
              'cash' => account.copyWith(name: '現金帳戶'),
              _ => account,
            },
          )
          .where((account) => account.id != 'bank')
          .toList();
      if (!loaded.any((account) => account.id == 'cash')) {
        return [const LedgerAccount(id: 'cash', name: '現金帳戶'), ...loaded];
      }
      return loaded;
    } catch (_) {
      return _accounts;
    }
  }

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

  void _reorderGroup(bool income, bool custom, int oldIndex, int newIndex) {
    setState(() {
      final categories = income ? _incomeOrder : _expenseOrder;
      final builtIn = categories
          .where((category) => !category.isCustom)
          .toList();
      final customCategories = categories
          .where((category) => category.isCustom)
          .toList();
      final group = custom ? customCategories : builtIn;
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

  List<AccountTransfer> _readTransfers(SharedPreferences prefs) {
    try {
      final list =
          jsonDecode(prefs.getString('account_transfers') ?? '[]') as List;
      return list
          .map(
            (item) => AccountTransfer.fromJson(
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
      _accounts = _readAccounts(preferences);
      _records
        ..clear()
        ..addAll(_readRecords(preferences));
      _transfers = _readTransfers(preferences);
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
      'ledger_accounts',
      jsonEncode(_accounts.map((account) => account.toJson()).toList()),
    );
    await preferences.setString(
      'transaction_records',
      jsonEncode(_records.map((record) => record.toJson()).toList()),
    );
    await preferences.setString(
      'account_transfers',
      jsonEncode(_transfers.map((transfer) => transfer.toJson()).toList()),
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
            accounts: _accounts,
          ),
          RecordPage(
            categories: _incomeOrder
                .where((c) => !_hiddenIncome.contains(c.id))
                .toList(),
            transactionName: l10n.income,
            isIncome: true,
            onRecorded: _addRecord,
            accounts: _accounts,
          ),
          StatisticsPage(
            records: _records,
            recordManagement: RecordManagementPage(
              records: _records,
              expenseCategories: _expenseOrder,
              incomeCategories: _incomeOrder,
              accounts: _accounts,
              onUpdated: _updateRecord,
              onDeleted: _deleteRecord,
              embedded: true,
            ),
          ),
          AccountManagementPage(
            accounts: _accounts,
            records: _records,
            transfers: _transfers,
            onSaved: _saveAccounts,
            onTransferAdded: _addTransfer,
            onTransferDeleted: _deleteTransfer,
            onDeleteRecord: _deleteRecordByMatch,
            closeOnSave: false,
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
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: '銀行管理',
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

  void _addTransfer(AccountTransfer transfer) {
    setState(() => _transfers.add(transfer));
    _savePreferences();
  }

  void _deleteTransfer(String id) {
    setState(() => _transfers.removeWhere((transfer) => transfer.id == id));
    _savePreferences();
  }

  // 依物件身分刪除單筆紀錄（供帳戶明細等過濾檢視使用）
  void _deleteRecordByMatch(TransactionRecord target) {
    final index = _records.indexWhere((record) => identical(record, target));
    if (index < 0) return;
    setState(() => _records.removeAt(index));
    _savePreferences();
  }

  void _saveAccounts(List<LedgerAccount> accounts) {
    setState(() => _accounts = accounts);
    _savePreferences();
  }
}
