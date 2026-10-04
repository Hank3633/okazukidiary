import 'package:flutter/material.dart';

import '../models/category_item.dart';
import '../l10n/app_localizations.dart';
import '../models/transaction_record.dart';
import '../widgets/pie_chart.dart';
import '../widgets/category_icon.dart';
import 'record_management_page.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({
    super.key,
    required this.records,
    required this.recordManagement,
  });
  final List<TransactionRecord> records;
  final RecordManagementPage recordManagement;
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _showIncome = false;
  int _tab = 0;
  late DateTimeRange _dateRange;

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
    _dateRange = _currentMonth();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (!mounted || picked == null) return;
    setState(() => _dateRange = picked);
  }

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  String _formatCurrency(double amount) {
    final digits = amount.toStringAsFixed(0);
    final withThousands = digits.replaceAllMapped(
      RegExp(r'(?<!^)(?=(\d{3})+$)'),
      (_) => ',',
    );
    return 'NT\$ $withThousands';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = widget.records.where((r) {
      final day = DateUtils.dateOnly(r.date);
      return r.isIncome == _showIncome &&
          !day.isBefore(_dateRange.start) &&
          !day.isAfter(_dateRange.end);
    }).toList();
    final totals = <String, double>{};
    final items = <String, CategoryItem>{};
    for (final r in filtered) {
      totals[r.category.id] = (totals[r.category.id] ?? 0) + r.amount;
      items[r.category.id] = r.category;
    }
    final rows = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = rows.fold<double>(0, (sum, e) => sum + e.value);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.statistics),
          centerTitle: true,
          bottom: TabBar(
            onTap: (index) => setState(() {
              _tab = index;
              _showIncome = index == 1;
            }),
            tabs: [
              Tab(text: l10n.expense),
              Tab(text: l10n.income),
              const Tab(text: '紀錄'),
            ],
          ),
        ),
        body: _tab == 2
            ? widget.recordManagement
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: TextButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.date_range, size: 20),
                            label: Text(
                              '${_formatDate(_dateRange.start)} ～ ${_formatDate(_dateRange.end)}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _dateRange = _currentMonth()),
                          child: Text(l10n.thisMonth),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 190,
                    child: total == 0
                        ? Center(child: Text(l10n.noRecords))
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(190, 190),
                                painter: PieChartPainter(
                                  rows.map((e) => e.value).toList(),
                                  rows.map((e) => items[e.key]!.color).toList(),
                                ),
                              ),
                              ClipOval(
                                child: Image.asset(
                                  'assets/images/branding/desktop_icon.png',
                                  width: 62,
                                  height: 62,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: Text(l10n.total(_formatCurrency(total))),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final e = rows[i];
                        final c = items[e.key]!;
                        final p = e.value / total;
                        return ListTile(
                          leading: CategoryIcon(category: c),
                          title: Text(
                            '${c.label}  ${(p * 100).toStringAsFixed(1)}%',
                          ),
                          subtitle: LinearProgressIndicator(
                            value: p,
                            color: c.color,
                            backgroundColor: const Color(0xFFECECEC),
                          ),
                          trailing: Text(
                            '${_showIncome ? '+' : '-'} ${_formatCurrency(e.value)}',
                            style: TextStyle(
                              color: _showIncome ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
