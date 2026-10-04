import 'package:flutter/material.dart';

import '../models/ledger_account.dart';
import '../models/transaction_record.dart';
import '../models/account_transfer.dart';
import '../widgets/category_icon.dart';

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({
    super.key,
    required this.account,
    required this.records,
    required this.transfers,
    required this.accounts,
    required this.onDeleteRecord,
    required this.onDeleteTransfer,
  });

  final LedgerAccount account;
  final List<TransactionRecord> records;
  final List<AccountTransfer> transfers;
  final List<LedgerAccount> accounts;
  final ValueChanged<TransactionRecord> onDeleteRecord;
  final ValueChanged<String> onDeleteTransfer;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  late List<TransactionRecord> _records;
  late List<AccountTransfer> _transfers;

  @override
  void initState() {
    super.initState();
    _records = widget.records
        .where((record) => record.accountId == widget.account.id)
        .toList();
    _transfers = widget.transfers
        .where(
          (transfer) =>
              transfer.sourceAccountId == widget.account.id ||
              transfer.targetAccountId == widget.account.id,
        )
        .toList();
  }

  double get _balance {
    final base =
        widget.account.openingBalance +
        _records.fold<double>(
          0,
          (sum, record) =>
              sum + (record.isIncome ? record.amount : -record.amount),
        );
    final transferIn = _transfers
        .where((transfer) => transfer.targetAccountId == widget.account.id)
        .fold<double>(0, (sum, transfer) => sum + transfer.amount);
    final transferOut = _transfers
        .where((transfer) => transfer.sourceAccountId == widget.account.id)
        .fold<double>(0, (sum, transfer) => sum + transfer.amount);
    return base + transferIn - transferOut;
  }

  String _accountName(String id) {
    for (final account in widget.accounts) {
      if (account.id == id) return account.name;
    }
    return '付款方式';
  }

  String _date(DateTime value) =>
      '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';

  String _money(double value) =>
      'NT\$ ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => ',')}';

  Future<void> _confirmDeleteRecord(TransactionRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除紀錄'),
        content: const Text('確定要刪除這筆紀錄嗎？'),
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
    setState(() => _records.removeWhere((item) => identical(item, record)));
    widget.onDeleteRecord(record);
  }

  Future<void> _confirmDeleteTransfer(AccountTransfer transfer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除轉帳'),
        content: Text(
          '確定要刪除這筆「${_accountName(transfer.sourceAccountId)} → ${_accountName(transfer.targetAccountId)}」轉帳嗎？',
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
    setState(() => _transfers.removeWhere((item) => item.id == transfer.id));
    widget.onDeleteTransfer(transfer.id);
  }

  @override
  Widget build(BuildContext context) {
    final isCash = widget.account.id == 'cash';
    final color = isCash ? const Color(0xFF26C6A0) : const Color(0xFF4A90D9);
    final icon = isCash ? Icons.payments : Icons.account_balance_wallet;

    final items = <_DetailItem>[
      for (final record in _records) _DetailItem(record: record),
      for (final transfer in _transfers) _DetailItem(transfer: transfer),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.account.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: color,
                  child: Icon(icon, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      Text(
                        '起始存款 ${_money(widget.account.openingBalance)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF8A8A8A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 106,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _money(_balance),
                          style: const TextStyle(
                            color: Color(0xFF2E9E5B),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
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
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('此帳戶尚無交易紀錄'))
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isTransfer = item.isTransfer;
                      if (isTransfer) {
                        final transfer = item.transfer!;
                        final isIn =
                            transfer.targetAccountId == widget.account.id;
                        final counterpartId = isIn
                            ? transfer.sourceAccountId
                            : transfer.targetAccountId;
                        return ListTile(
                          leading: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFE6F4EF),
                            child: Icon(
                              Icons.swap_horiz,
                              size: 20,
                              color: Color(0xFF26C6A0),
                            ),
                          ),
                          title: Text(isIn ? '轉入' : '轉出'),
                          subtitle: Text(
                            '${isIn ? '來自' : '轉至'} ${_accountName(counterpartId)} · ${_date(transfer.date)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: SizedBox(
                            width: 132,
                            child: Row(
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${isIn ? '+' : '-'} ${_money(transfer.amount)}',
                                      style: TextStyle(
                                        color: isIn
                                            ? const Color(0xFF2E9E5B)
                                            : const Color(0xFFE67E22),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (_) =>
                                      _confirmDeleteTransfer(transfer),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('刪除轉帳'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final record = item.record!;
                      return ListTile(
                        leading: CategoryIcon(category: record.category),
                        title: Text(record.category.label),
                        subtitle: Text(_date(record.date)),
                        trailing: SizedBox(
                          width: 132,
                          child: Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${record.isIncome ? '+' : '-'} ${_money(record.amount)}',
                                    style: TextStyle(
                                      color: record.isIncome
                                          ? const Color(0xFF2E9E5B)
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (_) => _confirmDeleteRecord(record),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('刪除紀錄'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem {
  _DetailItem({this.record, this.transfer});
  final TransactionRecord? record;
  final AccountTransfer? transfer;

  bool get isTransfer => transfer != null;
  DateTime get date => record?.date ?? transfer!.date;
}
