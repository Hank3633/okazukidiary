import 'package:flutter/material.dart';

import '../models/category_item.dart';
import '../models/transaction_record.dart';
import '../widgets/pie_chart.dart';
import '../widgets/category_icon.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.records});
  final List<TransactionRecord> records;
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _showIncome = false;
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
  @override
  Widget build(BuildContext context) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('收支統計'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('支出明細')),
                ButtonSegment(value: true, label: Text('收入明細')),
              ],
              selected: {_showIncome},
              onSelectionChanged: (v) => setState(() => _showIncome = v.first),
            ),
          ),
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
                  onPressed: () => setState(() => _dateRange = _currentMonth()),
                  child: const Text('本月'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 190,
            child: total == 0
                ? const Center(child: Text('此日期區間尚無記錄'))
                : CustomPaint(
                    size: const Size(190, 190),
                    painter: PieChartPainter(
                      rows.map((e) => e.value).toList(),
                      rows.map((e) => items[e.key]!.color).toList(),
                    ),
                  ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Text('總計：\$ ${total.toStringAsFixed(0)}'),
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = rows[i];
                final c = items[e.key]!;
                final p = e.value / total;
                return ListTile(
                  leading: CategoryIcon(category: c),
                  title: Text('${c.label}  ${(p * 100).toStringAsFixed(1)}%'),
                  subtitle: LinearProgressIndicator(
                    value: p,
                    color: c.color,
                    backgroundColor: const Color(0xFFECECEC),
                  ),
                  trailing: Text(
                    '${_showIncome ? '+' : '-'} \$ ${e.value.toStringAsFixed(0)}',
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
    );
  }
}
