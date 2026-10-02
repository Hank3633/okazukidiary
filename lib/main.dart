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

/// 主外殼：底部導覽列 + 四個分頁
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

/// 佔位頁（另外三個分頁先放預設畫面）
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
  int _selectedCategory = 0; // 目前選中的分類圖示

  // ---- 計算機狀態 ----
  String _display = '0';          // 畫面顯示（算式）
  bool _waitingForSecond = false; // 是否等待輸入第二個運算元
  bool _justCalculated = false;   // 是否剛按過 =

  void _onKey(String key) {
    setState(() {
      // 數字鍵 / 小數點 / 00
      if (RegExp(r'^[0-9.]$').hasMatch(key) || key == '00') {
        if (_justCalculated) {
          // 按完 = 後再輸入數字，重新開始
          _display = (key == '00') ? '0' : key;
          _justCalculated = false;
          _waitingForSecond = false;
          return;
        }
        if (_waitingForSecond) {
          // 等待輸入第二個運算元：接在算式後面
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
            // 避免同一個數字有多個小數點
            final parts = _display.split(RegExp(r'[+\-×÷]'));
            final current = parts.last;
            if (!current.contains('.')) _display += '.';
          } else if (key == '00') {
            if (_display != '0') _display += '00';
          } else {
            if (_display == '0') {
              _display = key;
            } else {
              _display += key;
            }
          }
        }
        return;
      }

      // 運算子：附加到算式後面
      if (key == '+' || key == '-' || key == '×' || key == '÷') {
        if (_justCalculated) {
          // 按完 = 後直接按運算子，把結果接續
          _display = '$_display $key ';
          _waitingForSecond = true;
          _justCalculated = false;
          return;
        }
        if (_waitingForSecond) {
          // 連續按運算子：替換運算子
          _display = '${_display.substring(0, _display.length - 3)} $key ';
        } else {
          // 第一次按運算子
          _display = '$_display $key ';
          _waitingForSecond = true;
        }
        return;
      }

      // 等號：計算完整算式
      if (key == '=') {
        if (_waitingForSecond) return; // 算式結尾是運算子，不計算
        final result = _evaluateExpression(_display);
        if (result == null) return;
        _display = _formatNumber(result);
        _waitingForSecond = false;
        _justCalculated = true;
        return;
      }

      // 倒退
      if (key == 'back') {
        if (_justCalculated) {
          // 按完 = 後不允許倒退
          return;
        }
        if (_waitingForSecond) {
          // 剛按完運算子：倒退刪掉運算子和空格
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

      // OK（完成記帳）
      if (key == 'done') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已記帳：$_display 元')),
        );
      }
    });
  }

  /// 解析並計算完整算式字串（例如 "12 × 3 + 4 ÷ 3"），乘除優先
  double? _evaluateExpression(String expr) {
    final tokens = expr.trim().split(RegExp(r'\s+'));
    if (tokens.isEmpty) return null;

    // 先把數字和運算子分開
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
    if (numbers.length == 1) return numbers.first; // 只有數字沒有運算子

    // 第一輪：處理 × 和 ÷
    var i = 0;
    while (i < operators.length) {
      if (operators[i] == '×') {
        numbers[i] = numbers[i] * numbers[i + 1];
        numbers.removeAt(i + 1);
        operators.removeAt(i);
      } else if (operators[i] == '÷') {
        if (numbers[i + 1] == 0) {
          numbers[i] = 0;
        } else {
          numbers[i] = numbers[i] / numbers[i + 1];
        }
        numbers.removeAt(i + 1);
        operators.removeAt(i);
      } else {
        i++;
      }
    }

    // 第二輪：處理 + 和 −（由左到右）
    var result = numbers[0];
    for (var j = 0; j < operators.length; j++) {
      if (operators[j] == '+') {
        result += numbers[j + 1];
      } else if (operators[j] == '-') {
        result -= numbers[j + 1];
      }
    }
    return result;
  }

  /// 格式化數字：整數不顯示小數點
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
            // 上方可捲動區域：分類圖示
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCategoryGrid(),
                  ],
                ),
              ),
            ),
            // 下方固定：日期算式列 + 數字鍵盤（合併為同一卡片）
            Container(
              margin: const EdgeInsets.all(12),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.white,
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

  /* ---------- 日期 + 算式列（與計算機同一卡片） ---------- */
  Widget _buildDateAmountRow() {
    final display = _display;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 22, color: Colors.grey),
          const SizedBox(width: 6),
          Text(
            '10/2',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
          ),
          const Spacer(),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                display,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ---------- 分類圖示網格 ---------- */
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
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.95,
        children: List.generate(categories.length, (i) {
          final c = categories[i];
          final selected = i == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE3F2FD) : Colors.white,
                border: Border.all(
                  color: selected ? const Color(0xFF64B5F6) : Colors.grey.shade200,
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(c.icon, size: 30, color: c.color),
                  const SizedBox(height: 4),
                  Text(c.label, style: const TextStyle(fontSize: 11)),
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
    return SizedBox(
      height: 280,
      child: Row(
        children: [
            // 左邊 3 欄數字鍵
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
            // 第 4 欄：運算子
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _funcKey('+', () => _onKey('+')),
                  _funcKey('-', () => _onKey('-')),
                  _funcKey('×', () => _onKey('×')),
                  _funcKey('÷', () => _onKey('÷')),
                ],
              ),
            ),
            // 第 5 欄：AC / 倒退 / = / OK
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() {
                        _display = '0';
                        _waitingForSecond = false;
                        _justCalculated = false;
                      }),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: const Text('AC', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _onKey('back'),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Icon(Icons.backspace_outlined, size: 26, color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _onKey('='),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: const Text('=', style: TextStyle(fontSize: 28)),
                      ),
                    ),
                  ),
                  // OK 按鈕（與其他鍵同高）
                  Expanded(
                    child: InkWell(
                      onTap: () => _onKey('done'),
                      child: Container(
                        alignment: Alignment.center,
                        color: const Color(0xFFB4E600),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 28,
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
      child: Row(
        children: keys.map((k) {
          return Expanded(
            child: InkWell(
              onTap: () => _onKey(k),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.grey.shade200),
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Text(
                  k,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _funcKey(String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

/// 分類項目資料
class _CategoryItem {
  final IconData icon;
  final String label;
  final Color color;
  _CategoryItem(this.icon, this.label, this.color);
}
