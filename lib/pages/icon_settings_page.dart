import 'package:flutter/material.dart';

class IconSizeSettingsPage extends StatelessWidget {
  const IconSizeSettingsPage({
    super.key,
    required this.selectedSize,
    required this.onSelected,
  });

  final double selectedSize;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    const sizes = [28.0, 32.0, 36.0];
    return Scaffold(
      appBar: AppBar(title: const Text('圖標設定'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '分類圖示尺寸',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('可直接切換並回到「記帳」頁查看效果。'),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              children: sizes
                  .map(
                    (size) => ChoiceChip(
                      label: Text('${size.toInt()} px'),
                      selected: selectedSize == size,
                      onSelected: (_) => onSelected(size),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
