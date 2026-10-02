import 'package:flutter/material.dart';

import '../widgets/category_icon.dart';

import '../models/category_item.dart';
import '../models/transaction_record.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({
    super.key,
    required this.iconSize,
    required this.categories,
    required this.transactionName,
    required this.onRecorded,
  });

  final double iconSize;
  final List<CategoryItem> categories;
  final String transactionName;
  final ValueChanged<TransactionRecord> onRecorded;

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  int _selectedCategory = 0;
  @override
  void didUpdateWidget(covariant RecordPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final path = oldWidget.categories[_selectedCategory].id;
    final index = widget.categories.indexWhere((c) => c.id == path);
    _selectedCategory = index < 0 ? 0 : index;
  }

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100, 12, 31),
    );
    if (!mounted || picked == null) return;
    setState(() => _selectedDate = DateUtils.dateOnly(picked));
  }

  // ---- 計算機狀態 ----
  String _display = '0';
  bool _waitingForSecond = false;
  bool _justCalculated = false;

  void _onKey(String key) {
    setState(() {
      if (RegExp(r'^[0-9.]$').hasMatch(key) || key == '00') {
        if (_justCalculated) {
          _display = (key == '00') ? '0' : key;
          _justCalculated = false;
          _waitingForSecond = false;
          return;
        }
        if (_waitingForSecond) {
          if (key == '00') {
            _display += '00';
          } else if (key == '.') {
            _display += '.';
          } else {
            _display += key;
          }
          _waitingForSecond = false;
        } else {
          if (key == '.') {
            final parts = _display.split(RegExp(r'[+\-×÷]'));
            if (!parts.last.contains('.')) _display += '.';
          } else if (key == '00') {
            if (_display != '0') _display += '00';
          } else {
            _display = (_display == '0') ? key : _display + key;
          }
        }
        return;
      }

      if (key == '+' || key == '-' || key == '×' || key == '÷') {
        if (_justCalculated) {
          _display = '$_display $key ';
          _waitingForSecond = true;
          _justCalculated = false;
          return;
        }
        if (_waitingForSecond) {
          _display = '${_display.substring(0, _display.length - 3)} $key ';
        } else {
          _display = '$_display $key ';
          _waitingForSecond = true;
        }
        return;
      }

      if (key == '=') {
        if (_waitingForSecond) return;
        final result = _evaluateExpression(_display);
        if (result == null) return;
        _display = _formatNumber(result);
        _waitingForSecond = false;
        _justCalculated = true;
        return;
      }

      if (key == 'back') {
        if (_justCalculated) return;
        if (_waitingForSecond) {
          if (_display.length > 3) {
            _display = _display.substring(0, _display.length - 3);
          }
          _waitingForSecond = false;
          return;
        }
        if (_display.isNotEmpty) {
          _display = _display.substring(0, _display.length - 1);
          if (_display.isEmpty) _display = '0';
        }
        return;
      }

      if (key == 'done') {
        final amount = _evaluateExpression(_display) ?? 0;
        if (amount <= 0) return;
        widget.onRecorded(
          TransactionRecord(
            category: widget.categories[_selectedCategory],
            amount: amount,
            isIncome: widget.transactionName == '收入',
            date: _selectedDate,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '已記${widget.transactionName}・${widget.categories[_selectedCategory].label}：${_formatNumber(amount)} 元',
            ),
          ),
        );
        _display = '0';
        _waitingForSecond = false;
        _justCalculated = false;
      }
    });
  }

  double? _evaluateExpression(String expr) {
    final tokens = expr.trim().split(RegExp(r'\s+'));
    if (tokens.isEmpty) return null;
    final numbers = <double>[];
    final operators = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      if (i % 2 == 0) {
        final n = double.tryParse(tokens[i]);
        if (n == null) return null;
        numbers.add(n);
      } else {
        operators.add(tokens[i]);
      }
    }
    if (numbers.length == 1) return numbers.first;

    var i = 0;
    while (i < operators.length) {
      if (operators[i] == '×') {
        numbers[i] = numbers[i] * numbers[i + 1];
        numbers.removeAt(i + 1);
        operators.removeAt(i);
      } else if (operators[i] == '÷') {
        numbers[i] = numbers[i + 1] == 0 ? 0 : numbers[i] / numbers[i + 1];
        numbers.removeAt(i + 1);
        operators.removeAt(i);
      } else {
        i++;
      }
    }

    var result = numbers[0];
    for (var j = 0; j < operators.length; j++) {
      if (operators[j] == '+') result += numbers[j + 1];
      if (operators[j] == '-') result -= numbers[j + 1];
    }
    return result;
  }

  String _formatNumber(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v
        .toStringAsFixed(4)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: SingleChildScrollView(child: _buildCategoryGrid())),
            // 日期算式列 + 鍵盤（同一卡片）
            Container(
              margin: const EdgeInsets.all(12),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_buildDateAmountRow(), _buildKeypad()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateAmountRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${_selectedDate.month}/${_selectedDate.day}',
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _display,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisExtent:
            widget.iconSize +
            24 +
            MediaQuery.textScalerOf(context).scale(11) * 2.4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: List.generate(widget.categories.length, (i) {
          final c = widget.categories[i];
          final selected = i == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFE3F2FD)
                    : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF64B5F6)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: widget.iconSize,
                    height: widget.iconSize,
                    child: CategoryIcon(category: c, size: widget.iconSize),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /* ---------- 數字鍵盤 ---------- */
  Widget _buildKeypad() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          // 數字區
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _keyRow(['7', '8', '9']),
                _keyRow(['4', '5', '6']),
                _keyRow(['1', '2', '3']),
                _keyRow(['0', '00', '.']),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 運算子區
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _opKey('+', () => _onKey('+')),
                _opKey('-', () => _onKey('-')),
                _opKey('×', () => _onKey('×')),
                _opKey('÷', () => _onKey('÷')),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // AC / 倒退 / = / OK
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _actionKey(
                  label: 'AC',
                  bgColor: const Color(0xFFFFEBEE),
                  textColor: const Color(0xFFE53935),
                  onTap: () => setState(() {
                    _display = '0';
                    _waitingForSecond = false;
                    _justCalculated = false;
                  }),
                ),
                const SizedBox(height: 8),
                _actionKey(
                  icon: Icons.backspace_outlined,
                  bgColor: const Color(0xFFF5F5F5),
                  onTap: () => _onKey('back'),
                ),
                const SizedBox(height: 8),
                _actionKey(
                  label: '=',
                  bgColor: const Color(0xFFF5F5F5),
                  onTap: () => _onKey('='),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _onKey('done'),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB4E600),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB4E600)
                                .withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keyRow(List<String> keys) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: keys.asMap().entries.map((e) {
            final isLast = e.key == keys.length - 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _onKey(e.value),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _opKey(String label, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 22,
                color: Color(0xFF1976D2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionKey({
    String? label,
    IconData? icon,
    Color bgColor = const Color(0xFFF5F5F5),
    Color textColor = Colors.black87,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: label != null
              ? Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Icon(icon, size: 22, color: Colors.grey.shade700),
        ),
      ),
    );
  }
}
