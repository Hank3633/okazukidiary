import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:convert';
import 'dart:io';

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
import 'pages/settings_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _defaultExpenseLabels = {
    '餐點',
    '飲料',
    '住宿',
    '交通',
    '衣服',
    '雑貨',
    '餐廳',
    '電費',
    '電話費',
    '加油費',
    '娛樂',
    '美容',
    '教育',
    '醫療',
    '禮金',
    '其他',
  };
  static const _defaultIncomeLabels = {
    '薪資',
    '獎金',
    '接案',
    '投資',
    '利息',
    '退款',
    '禮金',
    '其他',
  };
  static const _categoryDefaultsKey = 'category_visibility_defaults_v1';
  static const _backupFormat = 'okazukidiary-backup';
  static const _backupVersion = 1;
  static const _backupPreferenceKeys = {
    _categoryDefaultsKey,
    'hidden_expenses',
    'hidden_income',
    'expense_order',
    'income_order',
    'custom_expenses',
    'custom_income',
    'ledger_accounts',
    'transaction_records',
    'account_transfers',
  };
  static const _backupStringListKeys = {
    'hidden_expenses',
    'hidden_income',
    'expense_order',
    'income_order',
  };
  static const _backupStringKeys = {
    'custom_expenses',
    'custom_income',
    'ledger_accounts',
    'transaction_records',
    'account_transfers',
  };

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
    final applyCategoryDefaults = !preferences.containsKey(
      _categoryDefaultsKey,
    );
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
      if (applyCategoryDefaults) {
        _hiddenExpenses = _expenseOrder
            .where(
              (category) => !_defaultExpenseLabels.contains(category.label),
            )
            .map((category) => category.id)
            .toSet();
        _hiddenIncome = _incomeOrder
            .where((category) => !_defaultIncomeLabels.contains(category.label))
            .map((category) => category.id)
            .toSet();
      }
      if (_expenseOrder.every((c) => _hiddenExpenses.contains(c.id))) {
        _hiddenExpenses.clear();
      }
      if (_incomeOrder.every((c) => _hiddenIncome.contains(c.id))) {
        _hiddenIncome.clear();
      }
    });
    if (applyCategoryDefaults) {
      await preferences.setBool(_categoryDefaultsKey, true);
      await _savePreferences();
    }
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

  Future<Map<String, dynamic>> _createBackup() async {
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    final savedPreferences = <String, dynamic>{
      for (final key in _backupPreferenceKeys)
        if (preferences.containsKey(key)) key: preferences.get(key),
    };
    final customImages = <String, String>{};
    for (final category in [..._expenseOrder, ..._incomeOrder]) {
      if (!category.isCustom || category.imagePath.startsWith('assets/')) {
        continue;
      }
      try {
        customImages[category.id] = base64Encode(
          await File(category.imagePath).readAsBytes(),
        );
      } catch (_) {
        // A missing custom image does not prevent the rest of the data backup.
      }
    }
    return {
      'format': _backupFormat,
      'version': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'preferences': savedPreferences,
      'customImages': customImages,
    };
  }

  Future<void> _restoreBackup(Map<String, dynamic> backup) async {
    if (backup['format'] != _backupFormat ||
        backup['version'] != _backupVersion ||
        backup['preferences'] is! Map) {
      throw const FormatException('Unsupported backup file.');
    }
    final preferencesData = Map<String, dynamic>.from(
      backup['preferences'] as Map,
    );
    if (preferencesData.keys.any((key) => !_backupPreferenceKeys.contains(key))) {
      throw const FormatException('Unexpected backup preference.');
    }
    final customImages = backup['customImages'] is Map
        ? Map<String, dynamic>.from(backup['customImages'] as Map)
        : <String, dynamic>{};
    _validateBackupData(preferencesData, customImages);
    final preferences = _preferences ?? await SharedPreferences.getInstance();
    for (final key in _backupPreferenceKeys) {
      await preferences.remove(key);
    }
    for (final entry in preferencesData.entries) {
      final key = entry.key;
      final value = entry.value;
      if (_backupStringListKeys.contains(key)) {
        if (value is! List || value.any((item) => item is! String)) {
          throw const FormatException('Invalid category list.');
        }
        await preferences.setStringList(key, List<String>.from(value));
      } else if (_backupStringKeys.contains(key) && value is String) {
        if (key == 'custom_expenses' || key == 'custom_income') {
          await preferences.setString(
            key,
            await _restoreCustomImagePaths(value, customImages),
          );
        } else {
          await preferences.setString(key, value);
        }
      } else if (key == _categoryDefaultsKey && value is bool) {
        await preferences.setBool(key, value);
      } else {
        throw const FormatException('Invalid backup value.');
      }
    }
    await _loadPreferences();
  }

  void _validateBackupData(
    Map<String, dynamic> preferencesData,
    Map<String, dynamic> customImages,
  ) {
    for (final entry in preferencesData.entries) {
      final key = entry.key;
      final value = entry.value;
      if (_backupStringListKeys.contains(key)) {
        if (value is! List || value.any((item) => item is! String)) {
          throw const FormatException('Invalid category list.');
        }
      } else if (_backupStringKeys.contains(key)) {
        if (value is! String) throw const FormatException('Invalid backup text.');
        if (key == 'custom_expenses' || key == 'custom_income') {
          final categories = jsonDecode(value);
          if (categories is! List || categories.any((item) => item is! Map)) {
            throw const FormatException('Invalid custom categories.');
          }
        }
      } else if (key != _categoryDefaultsKey || value is! bool) {
        throw const FormatException('Invalid backup value.');
      }
    }
    for (final entry in customImages.entries) {
      if (entry.value is! String) {
        throw const FormatException('Invalid custom image.');
      }
      base64Decode(entry.value as String);
    }
  }

  Future<String> _restoreCustomImagePaths(
    String value,
    Map<String, dynamic> customImages,
  ) async {
    final categories = jsonDecode(value) as List;
    final directory = await getApplicationSupportDirectory();
    final imageDirectory = Directory('${directory.path}/category_images');
    await imageDirectory.create(recursive: true);
    for (final category in categories) {
      if (category is! Map) throw const FormatException('Invalid category.');
      final data = Map<String, dynamic>.from(category);
      final id = data['id'];
      final image = customImages[id];
      if (id is String && image is String) {
        final file = File('${imageDirectory.path}/$id.png');
        await file.writeAsBytes(base64Decode(image));
        data['image'] = file.path;
      }
      category
        ..clear()
        ..addAll(data);
    }
    return jsonEncode(categories);
  }

  Future<List<int>> _createExcel() async {
    final excel = Excel.createExcel();
    const sheetName = '收支紀錄';
    excel.rename(excel.getDefaultSheet()!, sheetName);
    final sheet = excel[sheetName];
    final records = List<TransactionRecord>.of(_records)
      ..sort((a, b) => a.date.compareTo(b.date));
    final accounts = {for (final account in _accounts) account.id: account.name};
    const headers = ['日期', '類型', '分類', '帳戶', '金額'];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (var column = 0; column < headers.length; column++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: 0)).cellStyle =
          CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('FFB2DFDB'),
          );
    }
    for (final record in records) {
      sheet.appendRow([
        DateCellValue(
          year: record.date.year,
          month: record.date.month,
          day: record.date.day,
        ),
        TextCellValue(record.isIncome ? '收入' : '支出'),
        TextCellValue(record.category.label),
        TextCellValue(accounts[record.accountId] ?? record.accountId),
        DoubleCellValue(record.amount),
      ]);
    }
    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 10);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 14);
    for (var row = 1; row <= records.length; row++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).cellStyle =
          CellStyle(
            numberFormat: CustomDateTimeNumFormat(formatCode: 'yyyy-mm-dd'),
          );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).cellStyle =
          CellStyle(
            numberFormat: CustomNumericNumFormat(formatCode: '#,##0.##'),
          );
    }
    return excel.save() ?? <int>[];
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
          SettingsPage(
            onCreateBackup: _createBackup,
            onRestoreBackup: _restoreBackup,
            onCreateExcel: _createExcel,
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
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settings,
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
