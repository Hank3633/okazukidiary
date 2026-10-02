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
  String _display = '0';          // 畫面顯示
  double? _firstOperand;          // 第一個運算元
  String? _operator;              // 運算子 (+ - × ÷)
  bool _waitingForSecond = false; // 是否等待輸入第二個運算元

  void _onKey(String key) {
    setState(() {
      // 數字鍵 / 小數點 / 00
      if (RegExp(r'^[0-9.]$').hasMatch(key) || key == '00') {
        if (_waitingForSecond) {
          _display = (key == '00') ? '0' : key;
          _waitingForSecond = false;
        } else {
          if (key == '.') {
            if (!_display.contains('.')) _display += '.';
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

      // 運算子
      if (key == '+' || key == '-' || key == '×' || key == '÷') {
        if (_firstOperand == null || !_waitingForSecond) {
          _firstOperand = double.tryParse(_display);
          _operator = key;
          _waitingForSecond = true;
        } else if (_operator != null) {
          // 連續運算：先算前一個
          _compute();
          _operator = key;
          _waitingForSecond = true;
        }
        return;
      }

      // 等號
      if (key == '=') {
        _compute();
        _operator = null;
        _firstOperand = null;
        _waitingForSecond = true;
        return;
      }

      // 倒退
      if (key == 'back') {
        if (!_waitingForSecond && _display.isNotEmpty) {
          _display = _display.substring(0, _display.length - 1);
          if (_display.isEmpty || _display == '-') _display = '0';
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

  /// 執行目前運算並把結果放到 _display
  void _compute() {
    if (_firstOperand == null || _operator == null) return;
    final second = double.tryParse(_display) ?? 0;
    double result;
    switch (_operator) {
      case '+':
        result = _firstOperand! + second;
        break;
      case '-':
        result = _firstOperand! - second;
        break;
      case '×':
        result = _firstOperand! * second;
        break;
      case '÷':
        result = second == 0 ? 0 : _firstOperand! / second;
        break;
      default:
        return;
    }
    // 整數不顯示小數點
    if (result == result.roundToDouble()) {
      _display = result.toInt().toString();
    } else {
      _display = result.toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    _firstOperand = result;
    _waitingForSecond = true;
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
            // 中間固定：日期金額列
            _buildDateAmountRow(),
            // 下方固定：數字鍵盤
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  /* ---------- 日期 + 金額列（在分類網格下方） ---------- */
  Widget _buildDateAmountRow() {
    final display = _display;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time, size: 28, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '10/2',
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey.shade400,
            ),
          ),
          const Spacer(),
          Text(
            display,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
    return Container(
      margin: const EdgeInsets.all(12),
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
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
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _display = '0';
                      _firstOperand = null;
                      _operator = null;
                      _waitingForSecond = false;
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
                  child: GestureDetector(
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
                  child: GestureDetector(
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
                  child: GestureDetector(
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
            child: GestureDetector(
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
      child: GestureDetector(
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
