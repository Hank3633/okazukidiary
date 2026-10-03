import 'dart:math' as math;

import 'package:flutter/material.dart';

class PieChartPainter extends CustomPainter {
  PieChartPainter(this.values, this.colors);
  final List<double> values;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    double start = -1.5708;
    final rect = Offset.zero & size;
    final center = size.center(Offset.zero);
    for (var i = 0; i < values.length; i++) {
      final sweep = 6.28318 * values[i] / total;
      canvas.drawArc(
        rect.deflate(8),
        start,
        sweep,
        true,
        Paint()..color = colors[i % colors.length],
      );
      canvas.drawArc(
        rect.deflate(8),
        start,
        sweep,
        true,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      // 小區塊的占比保留在列表，避免圖上的文字互相重疊。
      if (values[i] / total >= 0.05) {
        final angle = start + sweep / 2;
        final radius = (math.min(size.width, size.height) / 2 - 8) * 0.72;
        final position =
            center + Offset(math.cos(angle), math.sin(angle)) * radius;
        final label = TextPainter(
          text: TextSpan(
            text: '${(values[i] / total * 100).toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(
          canvas,
          position - Offset(label.width / 2, label.height / 2),
        );
      }
      start += sweep;
    }
    canvas.drawCircle(center, 34, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant PieChartPainter old) =>
      old.values != values || old.colors != colors;
}
