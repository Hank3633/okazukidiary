import 'package:flutter/material.dart';

import '../models/category_item.dart';
import '../models/transaction_record.dart';
import '../widgets/pie_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, required this.records});
  final List<TransactionRecord> records;
  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  bool _showIncome = false;
  @override
  Widget build(BuildContext context) {
    final filtered = widget.records
        .where((r) => r.isIncome == _showIncome)
        .toList();
    final totals = <String, double>{};
    final items = <String, CategoryItem>{};
    for (final r in filtered) {
      totals[r.category.label] = (totals[r.category.label] ?? 0) + r.amount;
      items[r.category.label] = r.category;
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
          Text(
            '${DateTime.now().year}/${DateTime.now().month.toString().padLeft(2, '0')}/01～本月',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 190,
            child: total == 0
                ? const Center(child: Text('本月尚無記錄'))
                : CustomPaint(
                    size: const Size(190, 190),
                    painter: PieChartPainter(rows.map((e) => e.value).toList()),
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
                  leading: Image.asset(c.imagePath, width: 36, height: 36),
                  title: Text(c.label),
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
