import 'package:flutter/material.dart';

import '../models/ledger_account.dart';
import '../models/transaction_record.dart';
import '../models/account_transfer.dart';
import 'account_detail_page.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({
    super.key,
    required this.accounts,
    required this.records,
    required this.transfers,
    required this.onSaved,
    required this.onTransferAdded,
    required this.onTransferDeleted,
    required this.onDeleteRecord,
    this.closeOnSave = true,
  });

  final List<LedgerAccount> accounts;
  final List<TransactionRecord> records;
  final List<AccountTransfer> transfers;
  final ValueChanged<List<LedgerAccount>> onSaved;
  final ValueChanged<AccountTransfer> onTransferAdded;
  final ValueChanged<String> onTransferDeleted;
  final ValueChanged<TransactionRecord> onDeleteRecord;
  final bool closeOnSave;

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  static const _teal = Color(0xFF26C6A0);

  // 銀行帳戶輪換的圖示底色
  static const _bankColors = <Color>[
    Color(0xFF4A90D9),
    Color(0xFFF5A623),
    Color(0xFF9B59B6),
    Color(0xFFE74C3C),
    Color(0xFF2E9E5B),
  ];

  late List<LedgerAccount> _accounts;
  final _newAccountName = TextEditingController();
  final _transferAmount = TextEditingController();
  final Map<String, TextEditingController> _balances = {};
  final Map<String, TextEditingController> _names = {};
  bool _showTransferForm = false;
  String? _sourceAccountId;
  String? _targetAccountId;
  DateTime _transferDate = DateUtils.dateOnly(DateTime.now());

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
    _resetTransferAccounts();
  }

  @override
  void dispose() {
    _newAccountName.dispose();
    _transferAmount.dispose();
    for (final controller in _balances.values) {
      controller.dispose();
    }
    for (final controller in _names.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _balance(LedgerAccount account) {
    final base =
        account.openingBalance +
        widget.records
            .where((record) => record.accountId == account.id)
            .fold<double>(
              0,
              (total, record) =>
                  total + (record.isIncome ? record.amount : -record.amount),
            );
    final transferIn = widget.transfers
        .where((transfer) => transfer.targetAccountId == account.id)
        .fold<double>(0, (sum, transfer) => sum + transfer.amount);
    final transferOut = widget.transfers
        .where((transfer) => transfer.sourceAccountId == account.id)
        .fold<double>(0, (sum, transfer) => sum + transfer.amount);
    return base + transferIn - transferOut;
  }

  double get _total =>
      _accounts.fold<double>(0, (sum, account) => sum + _balance(account));

  // 本月收支變動（所有帳戶合計）
  double get _monthChange {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return widget.records
        .where((record) {
          final day = DateUtils.dateOnly(record.date);
          return !day.isBefore(start) && !day.isAfter(end);
        })
        .fold<double>(
          0,
          (sum, record) =>
              sum + (record.isIncome ? record.amount : -record.amount),
        );
  }

  String _number(double value) => value
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => ',');

  String _money(double value) => 'NT\$ ${_number(value)}';

  // 依目前編輯狀態組出要儲存的帳戶清單（現金帳戶名稱固定）
  List<LedgerAccount> _currentAccounts() {
    return _accounts
        .map(
          (account) => account.copyWith(
            name: account.id == 'cash'
                ? '現金帳戶'
                : (_names[account.id]!.text.trim().isEmpty
                      ? account.name
                      : _names[account.id]!.text.trim()),
            openingBalance:
                double.tryParse(_balances[account.id]!.text.trim()) ??
                account.openingBalance,
          ),
        )
        .toList();
  }

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
    final accounts = _currentAccounts();
    setState(() => _accounts = accounts);
    widget.onSaved(accounts);
    if (widget.closeOnSave) Navigator.pop(context);
  }

  void _saveOpeningBalance(LedgerAccount account) {
    final balance = double.tryParse(_balances[account.id]!.text.trim());
    if (balance == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('請輸入有效的起始存款金額')));
      return;
    }
    final index = _accounts.indexWhere((item) => item.id == account.id);
    if (index < 0) return;
    final updated = account.copyWith(openingBalance: balance);
    setState(() => _accounts[index] = updated);
    widget.onSaved(List.of(_accounts));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('起始存款已儲存')));
  }

  Future<void> _delete(LedgerAccount account) async {
    if (account.id == 'cash' || _accounts.length <= 1) return;
    final hasRecords = widget.records.any((r) => r.accountId == account.id);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除帳戶'),
        content: Text(
          hasRecords
              ? '確定要刪除「${account.name}」嗎？此帳戶的既有紀錄仍會保留，但會改以「付款方式」顯示。'
              : '確定要刪除「${account.name}」嗎？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD9534F),
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _accounts.removeWhere((a) => a.id == account.id);
      _balances.remove(account.id)?.dispose();
      _names.remove(account.id)?.dispose();
      _resetTransferAccounts();
    });
    widget.onSaved(_currentAccounts());
  }

  void _openDetail(LedgerAccount account) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountDetailPage(
          account: account,
          records: widget.records,
          transfers: widget.transfers,
          accounts: _accounts,
          onDeleteRecord: widget.onDeleteRecord,
          onDeleteTransfer: widget.onTransferDeleted,
        ),
      ),
    );
  }

  void _resetTransferAccounts() {
    if (_accounts.length < 2) {
      _sourceAccountId = null;
      _targetAccountId = null;
      return;
    }
    _sourceAccountId ??= _accounts.first.id;
    if (!_accounts.any((account) => account.id == _sourceAccountId)) {
      _sourceAccountId = _accounts.first.id;
    }
    _targetAccountId ??= _accounts
        .firstWhere((account) => account.id != _sourceAccountId)
        .id;
    if (_targetAccountId == _sourceAccountId ||
        !_accounts.any((account) => account.id == _targetAccountId)) {
      _targetAccountId = _accounts
          .firstWhere((account) => account.id != _sourceAccountId)
          .id;
    }
  }

  void _toggleTransferForm() {
    if (_accounts.length < 2) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('至少需要兩個帳戶才能轉帳')));
      return;
    }
    setState(() {
      _resetTransferAccounts();
      _showTransferForm = !_showTransferForm;
    });
  }

  void _submitTransfer() {
    final amount = double.tryParse(_transferAmount.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('請輸入大於 0 的轉帳金額')));
      return;
    }
    if (_sourceAccountId == null ||
        _targetAccountId == null ||
        _sourceAccountId == _targetAccountId)
      return;
    widget.onTransferAdded(
      AccountTransfer(
        id: 'transfer_${DateTime.now().microsecondsSinceEpoch}',
        sourceAccountId: _sourceAccountId!,
        targetAccountId: _targetAccountId!,
        amount: amount,
        date: _transferDate,
      ),
    );
    setState(() {
      _transferAmount.clear();
      _transferDate = DateUtils.dateOnly(DateTime.now());
      _showTransferForm = false;
      _resetTransferAccounts();
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('轉帳完成')));
  }

  @override
  Widget build(BuildContext context) {
    final banks = _accounts.where((account) => account.id != 'cash').toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('銀行管理'),
        centerTitle: true,
        actions: const [],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(),
          const SizedBox(height: 12),
          for (final account in _accounts.where((a) => a.id == 'cash'))
            _accountCard(account, isCash: true, bankIndex: 0),
          for (var i = 0; i < banks.length; i++)
            _accountCard(banks[i], isCash: false, bankIndex: i),
          _addCard(),
          const SizedBox(height: 12),
          _transferCard(),
        ],
      ),
    );
  }

  Widget _transferCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F142823),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: _toggleTransferForm,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  const Icon(
                    Icons.swap_horiz,
                    size: 17,
                    color: Color(0xFF26C6A0),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '帳戶轉帳',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showTransferForm
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF8A8A8A),
                  ),
                ],
              ),
            ),
          ),
          if (_showTransferForm) ...[
            const Divider(height: 22),
            _transferForm(),
          ],
        ],
      ),
    );
  }

  Widget _transferForm() {
    final availableTargets = _accounts
        .where((account) => account.id != _sourceAccountId)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: _sourceAccountId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '從哪個帳戶轉出'),
          items: _accounts
              .map(
                (account) => DropdownMenuItem(
                  value: account.id,
                  child: Text(account.name),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _sourceAccountId = value;
              _resetTransferAccounts();
            });
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _targetAccountId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '轉入哪個帳戶'),
          items: availableTargets
              .map(
                (account) => DropdownMenuItem(
                  value: account.id,
                  child: Text(account.name),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _targetAccountId = value),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _transferAmount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '轉帳金額',
            prefixText: 'NT\$ ',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _submitTransfer,
          icon: const Icon(Icons.check),
          label: const Text('確認轉帳'),
        ),
      ],
    );
  }

  Widget _summaryCard() {
    final change = _monthChange;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF2AD6AD), Color(0xFF1F9E83), Color(0xFF17856F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D26C6A0),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                '資產總計',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _money(_total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '本月 ${change >= 0 ? '+' : '-'} ${_number(change.abs())}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '${_accounts.length} 個帳戶',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _accountCard(
    LedgerAccount account, {
    required bool isCash,
    required int bankIndex,
  }) {
    final color = isCash ? _teal : _bankColors[bankIndex % _bankColors.length];
    final icon = isCash ? Icons.payments : Icons.account_balance_wallet;
    final balance = _balance(account);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F142823),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openDetail(account),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color,
                    child: Icon(icon, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: isCash
                        ? const Row(
                            children: [
                              Text(
                                '現金帳戶',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1C1C1E),
                                ),
                              ),
                              SizedBox(width: 5),
                              Icon(
                                Icons.lock_outline,
                                size: 13,
                                color: Color(0xFFB0B0B0),
                              ),
                            ],
                          )
                        : TextField(
                            controller: _names[account.id],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1E),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: '帳戶名稱',
                              hintStyle: TextStyle(
                                color: Color(0xFFB0B0B0),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _money(balance),
                        style: const TextStyle(
                          color: Color(0xFF2E9E5B),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        '目前餘額',
                        style: TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  if (!isCash)
                    IconButton(
                      onPressed: () => _delete(account),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Color(0xFFC0C0C0),
                      ),
                      tooltip: '刪除帳戶',
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextField(
              controller: _balances[account.id],
              textInputAction: TextInputAction.done,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onSubmitted: (_) => _saveOpeningBalance(account),
              decoration: const InputDecoration(
                labelText: '起始存款',
                isDense: true,
                labelStyle: TextStyle(color: Color(0xFF8A8A8A)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFE4E7E6)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF26C6A0), width: 1.4),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () => _openDetail(account),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '查看交易明細',
                      style: TextStyle(
                        color: _teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: _teal),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addCard() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F142823),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 15,
                color: Color(0xFF26C6A0),
              ),
              SizedBox(width: 6),
              Text(
                '新增帳戶',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newAccountName,
            decoration: InputDecoration(
              hintText: '銀行／帳戶名稱',
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF7FAF9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE4E7E6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE4E7E6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF26C6A0),
                  width: 1.4,
                ),
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF26C6A0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '新增並儲存',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
