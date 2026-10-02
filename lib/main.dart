import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'おかず日記',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF26C6A0)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
      ),
      home: const MainShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 主外殼：底部導覽列 + 分頁
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _pages = [
    RecordPage(),
    PlaceholderPage(title: '收入', icon: Icons.savings),
    PlaceholderPage(title: '圖標設定', icon: Icons.apps),
    PlaceholderPage(title: '收支統計', icon: Icons.bar_chart),
    PlaceholderPage(title: '設定', icon: Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
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
}

/// 佔位頁
class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  const PlaceholderPage({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
 * 記帳頁
 * ============================================================ */
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  int _selectedCategory = 0;

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已記帳：$_display 元')),
        );
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
    return v.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _buildCategoryGrid(),
              ),
            ),
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
                  children: [
                    _buildDateAmountRow(),
                    _buildKeypad(),
                  ],
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
          const Icon(Icons.access_time, size: 20, color: Colors.grey),
          const SizedBox(width: 6),
          Text('10/2', style: TextStyle(fontSize: 15, color: Colors.grey.shade400)),
          const Spacer(),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _display,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = <_CategoryItem>[
      _CategoryItem(Icons.restaurant, '食費', const Color(0xFF4FC3F7)),
      _CategoryItem(Icons.wine_bar, '嗜好品', const Color(0xFFF48FB1)),
      _CategoryItem(Icons.lunch_dining, '外食費', const Color(0xFFBCAAA4)),
      _CategoryItem(Icons.home, '住居', const Color(0xFFEF5350)),
      _CategoryItem(Icons.bed, '家具・家電', const Color(0xFF66BB6A)),
      _CategoryItem(Icons.card_giftcard, '日用雑貨', const Color(0xFFFFB74D)),
      _CategoryItem(Icons.bolt, '光熱費', const Color(0xFFFFCA28)),
      _CategoryItem(Icons.checkroom, '衣服', const Color(0xFF7986CB)),
      _CategoryItem(Icons.medical_services, '医療', const Color(0xFF80CBC4)),
      _CategoryItem(Icons.sentiment_satisfied, '美容・衛生', const Color(0xFFBA68C8)),
      _CategoryItem(Icons.school, '教育', const Color(0xFF9CCC65)),
      _CategoryItem(Icons.sports_baseball, '娯楽', const Color(0xFFFFD54F)),
      _CategoryItem(Icons.people, '交際', const Color(0xFFFFB74D)),
      _CategoryItem(Icons.tram, '交通・通信', const Color(0xFF4DD0E1)),
      _CategoryItem(Icons.add_circle, '保険', const Color(0xFFA1887F)),
    ];

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
        childAspectRatio: 0.95,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        children: List.generate(categories.length, (i) {
          final c = categories[i];
          final selected = i == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE3F2FD) : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? const Color(0xFF64B5F6) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(c.icon, size: 28, color: c.color),
                  const SizedBox(height: 4),
                  Text(c.label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
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
                            color: const Color(0xFFB4E600).withValues(alpha: 0.45),
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
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
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
              ? Text(label, style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.bold))
              : Icon(icon, size: 22, color: Colors.grey.shade700),
        ),
      ),
    );
  }
}

class _CategoryItem {
  final IconData icon;
  final String label;
  final Color color;
  _CategoryItem(this.icon, this.label, this.color);
}
