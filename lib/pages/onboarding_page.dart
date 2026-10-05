import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onCompleted});

  final Future<void> Function() onCompleted;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  var _page = 0;

  static const _steps = [
    (
      title: '開始記帳',
      message: '在銀行管理頁面，新增銀行帳戶與存款金額。',
      navigationIndex: 3,
    ),
    (
      title: '整理常用分類',
      message: '在「圖標設定」中調整顯示項目與順序，也能新增自己的分類。',
      navigationIndex: 4,
    ),
    (
      title: '掌握收支狀況',
      message: '用「收支統計」可以查看或編輯花費；重要資料可在「設定」備份或匯出 Excel。',
      navigationIndex: 2,
    ),
  ];

  Future<void> _complete() async {
    await widget.onCompleted();
    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _page == _steps.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _complete, child: const Text('略過')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _NavigationPreview(highlightIndex: step.navigationIndex),
                        const SizedBox(height: 44),
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.message,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: index == _page ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == _page ? const Color(0xFF26C6A0) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLastPage
                      ? _complete
                      : () => _controller.nextPage(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOut,
                          ),
                  child: Text(isLastPage ? '開始使用' : '下一步'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationPreview extends StatelessWidget {
  const _NavigationPreview({required this.highlightIndex});

  final int highlightIndex;

  static const _items = [
    (icon: Icons.book, label: '支出'),
    (icon: Icons.savings, label: '收入'),
    (icon: Icons.bar_chart, label: '收支統計'),
    (icon: Icons.account_balance, label: '銀行管理'),
    (icon: Icons.apps, label: '圖標設定'),
    (icon: Icons.settings, label: '設定'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / _items.length;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  for (var index = 0; index < _items.length; index++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _items[index].icon,
                            size: 23,
                            color: index == highlightIndex
                                ? const Color(0xFF26C6A0)
                                : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _items[index].label,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: TextStyle(
                              color: index == highlightIndex
                                  ? const Color(0xFF168B72)
                                  : Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              Positioned(
                left: itemWidth * highlightIndex + (itemWidth - 52) / 2,
                top: -4,
                child: IgnorePointer(
                  child: Container(
                    width: 52,
                    height: 72,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 2.5),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
