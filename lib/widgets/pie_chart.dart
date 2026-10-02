import 'package:flutter/material.dart';

class PieChartPainter extends CustomPainter {
  PieChartPainter(this.values);
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    final colors = [
      const Color(0xFFE84383),
      const Color(0xFFFFA000),
      const Color(0xFF7CB342),
      const Color(0xFF42A5F5),
      const Color(0xFFAB47BC),
      const Color(0xFF26A69A),
    ];
    double start = -1.5708;
    final rect = Offset.zero & size;
    for (var i = 0; i < values.length; i++) {
      final sweep = 6.28318 * values[i] / total;
      canvas.drawArc(
        rect.deflate(8),
        start,
        sweep,
        true,
        Paint()..color = colors[i % colors.length],
      );
      start += sweep;
    }
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, 34, Paint()..color = Colors.white);
    final text = TextPainter(
      text: const TextSpan(
        text: '%',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant PieChartPainter old) => old.values != values;
}
