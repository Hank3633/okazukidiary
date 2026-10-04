import 'package:flutter/material.dart';

import '../models/ledger_account.dart';
import '../models/transaction_record.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({
    super.key,
    required this.accounts,
    required this.records,
    required this.onSaved,
    this.closeOnSave = true,
  });

  final List<LedgerAccount> accounts;
  final List<TransactionRecord> records;
  final ValueChanged<List<LedgerAccount>> onSaved;
  final bool closeOnSave;

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  late List<LedgerAccount> _accounts;
  final _newAccountName = TextEditingController();
  final Map<String, TextEditingController> _balances = {};
  final Map<String, TextEditingController> _names = {};

  @override
  void initState() {
    super.initState();
    _accounts = List.of(widget.accounts);
    for (final account in _accounts) {
      _balances[account.id] = TextEditingController(
        text: account.openingBalance.toStringAsFixed(0),
      );
      _names[account.id] = TextEditingController(text: account.name);
    }
  }

  @override
  void dispose() {
    _newAccountName.dispose();
    for (final controller in _balances.values) {
      controller.dispose();
    }
    for (final controller in _names.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _balance(LedgerAccount account) {
    return account.openingBalance +
        widget.records
            .where((record) => record.accountId == account.id)
            .fold<double>(
              0,
              (total, record) =>
                  total + (record.isIncome ? record.amount : -record.amount),
            );
  }

  String _money(double value) =>
      'NT\$ ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => ',')}';

  void _save() {
    final newName = _newAccountName.text.trim();
    if (newName.isNotEmpty &&
        !_accounts.any((account) => account.name == newName)) {
      final account = LedgerAccount(
        id: 'account_${DateTime.now().microsecondsSinceEpoch}',
        name: newName,
      );
      _accounts.add(account);
      _balances[account.id] = TextEditingController(text: '0');
      _names[account.id] = TextEditingController(text: newName);
      _newAccountName.clear();
    }
    final accounts = _accounts
        .map(
          (account) => account.copyWith(
            name: account.id == 'cash'
                ? '現金付款'
                : (_names[account.id]!.text.trim().isEmpty
                      ? account.name
                      : _names[account.id]!.text.trim()),
            openingBalance:
                double.tryParse(_balances[account.id]!.text.trim()) ?? 0,
          ),
        )
        .toList();
    setState(() => _accounts = accounts);
    widget.onSaved(accounts);
    if (widget.closeOnSave) Navigator.pop(context);
  }

  void _move(int index, int delta) {
    final next = index + delta;
    if (next < 0 || next >= _accounts.length) return;
    setState(() {
      final account = _accounts.removeAt(index);
      _accounts.insert(next, account);
    });
  }

  void _delete(int index) {
    if (_accounts.length == 1) return;
    final account = _accounts.removeAt(index);
    _balances.remove(account.id)?.dispose();
    _names.remove(account.id)?.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('帳戶管理'), centerTitle: true),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('收款會增加帳戶餘額，付款會減少帳戶餘額。'),
        const SizedBox(height: 12),
        TextField(
          controller: _newAccountName,
          decoration: const InputDecoration(labelText: '新增銀行／帳戶名稱'),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: _save, child: const Text('儲存帳戶')),
        const SizedBox(height: 12),
        ..._accounts.asMap().entries.map((entry) {
          final index = entry.key;
          final account = entry.value;
          final isCash = account.id == 'cash';
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCash)
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('現金帳戶'),
                    )
                  else
                    TextField(
                      controller: _names[account.id],
                      decoration: const InputDecoration(labelText: '帳戶名稱'),
                    ),
                  Text('目前餘額：${_money(_balance(account))}'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _balances[account.id],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: '帳戶起始存款'),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: []),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}
