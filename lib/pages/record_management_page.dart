import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/category_item.dart';
import '../models/ledger_account.dart';
import '../models/transaction_record.dart';
import '../widgets/category_icon.dart';

class RecordManagementPage extends StatefulWidget {
  const RecordManagementPage({
    super.key,
    required this.records,
    required this.expenseCategories,
    required this.incomeCategories,
    required this.accounts,
    required this.onUpdated,
    required this.onDeleted,
    this.embedded = false,
  });

  final List<TransactionRecord> records;
  final List<CategoryItem> expenseCategories;
  final List<CategoryItem> incomeCategories;
  final List<LedgerAccount> accounts;
  final void Function(int index, TransactionRecord record) onUpdated;
  final ValueChanged<int> onDeleted;
  final bool embedded;

  @override
  State<RecordManagementPage> createState() => _RecordManagementPageState();
}

class _RecordManagementPageState extends State<RecordManagementPage> {
  late DateTimeRange _range;
  bool _showIncome = false;

  DateTimeRange _currentMonth() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  @override
  void initState() {
    super.initState();
    _range = _currentMonth();
  }

  String _date(DateTime value) =>
      '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';

  String _money(double value) {
    final digits = value.toStringAsFixed(0);
    return 'NT\$ ${digits.replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (_) => ',')}';
  }

  String _accountName(String id) {
    for (final account in widget.accounts) {
      if (account.id == id) return account.name;
    }
    return '付款方式';
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null && mounted) setState(() => _range = picked);
  }

  Future<void> _edit(int index, TransactionRecord record) async {
    final l10n = AppLocalizations.of(context)!;
    final amount = TextEditingController(
      text: record.amount.toStringAsFixed(0),
    );
    final choices = [
      ...(record.isIncome ? widget.incomeCategories : widget.expenseCategories),
      if (!(record.isIncome
              ? widget.incomeCategories
              : widget.expenseCategories)
          .any((item) => item.id == record.category.id))
        record.category,
    ];
    var categoryId = record.category.id;
    var accountId =
        widget.accounts.any((account) => account.id == record.accountId)
        ? record.accountId
        : widget.accounts.first.id;
    var date = record.date;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.editRecord),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: categoryId,
                decoration: InputDecoration(labelText: l10n.category),
                items: choices
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => categoryId = value!),
              ),
              DropdownButtonFormField<String>(
                initialValue: accountId,
                decoration: const InputDecoration(labelText: '帳戶'),
                items: widget.accounts
                    .map(
                      (account) => DropdownMenuItem(
                        value: account.id,
                        child: Text(account.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => accountId = value!),
              ),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: l10n.amount),
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setDialogState(() => date = picked);
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('${l10n.date}: ${_date(date)}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    final parsed = double.tryParse(amount.text);
    amount.dispose();
    if (saved != true || parsed == null || parsed <= 0 || !mounted) return;
    final category = choices.firstWhere((item) => item.id == categoryId);
    widget.onUpdated(
      index,
      record.copyWith(
        category: category,
        amount: parsed,
        date: date,
        accountId: accountId,
      ),
    );
  }

  Future<void> _delete(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.deleteRecordMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) widget.onDeleted(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = widget.records.asMap().entries.where((entry) {
      final record = entry.value;
      final day = DateUtils.dateOnly(record.date);
      return record.isIncome == _showIncome &&
          !day.isBefore(_range.start) &&
          !day.isAfter(_range.end);
    }).toList()..sort((a, b) => b.value.date.compareTo(a.value.date));
    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(l10n.recordManagement),
              centerTitle: true,
              actions: const [],
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.expense)),
                ButtonSegment(value: true, label: Text(l10n.income)),
              ],
              selected: {_showIncome},
              onSelectionChanged: (selection) =>
                  setState(() => _showIncome = selection.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: TextButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range, size: 20),
                    label: Text(
                      '${_date(_range.start)} - ${_date(_range.end)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _range = _currentMonth()),
                  child: Text(l10n.thisMonth),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entries.isEmpty
                ? Center(child: Text(l10n.noMatchingRecords))
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, position) {
                      final entry = entries[position];
                      final record = entry.value;
                      return ListTile(
                        leading: CategoryIcon(category: record.category),
                        title: Text(record.category.label),
                        subtitle: Text(
                          '${_date(record.date)} · ${_accountName(record.accountId)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${record.isIncome ? '+' : '-'} ${_money(record.amount)}',
                              style: TextStyle(
                                color: record.isIncome
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (action) => action == 'edit'
                                  ? _edit(entry.key, record)
                                  : _delete(entry.key),
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(l10n.editRecord),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(l10n.deleteRecord),
                                ),
                              ],
                            ),
                          ],
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
