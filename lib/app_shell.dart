import 'package:flutter/material.dart';

import 'data/categories.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          RecordPage(
            iconSize: _categoryIconSize,
            categories: expenseCategories,
            transactionName: '支出',
            onRecorded: _addRecord,
          ),
          RecordPage(
            iconSize: _categoryIconSize,
            categories: incomeCategories,
            transactionName: '收入',
            onRecorded: _addRecord,
          ),
          IconSizeSettingsPage(
            selectedSize: _categoryIconSize,
            onSelected: (size) => setState(() => _categoryIconSize = size),
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
