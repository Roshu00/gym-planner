import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class ClChartPoint {
  const ClChartPoint(this.label, this.value);

  /// X-axis label, e.g. `N1` or `12.9.`
  final String label;
  final double value;
}

/// Progress chart on a white card: a rounded 2.5px ink line. The current or
/// best point is a lime dot, its value in a lime pill.
class ClLineChart extends StatelessWidget {
  const ClLineChart({
    super.key,
    required this.points,
    required this.title,
    this.unit,
    this.highlightIndex,
    this.height = 180,
  });

  final List<ClChartPoint> points;
  final String title;
  final String? unit;

  /// Defaults to the last (current) point.
  final int? highlightIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    assert(points.length >= 2, 'A chart needs at least 2 points');
    final cl = context.cl;
    final hi = highlightIndex ?? points.length - 1;
    final best = points[hi];
    return Semantics(
      label: '$title. ${points.map((p) => '${p.label}: ${formatNumber(p.value)}').join(', ')}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s4),
        decoration: BoxDecoration(
          color: cl.colors.surface,
          borderRadius: BorderRadius.circular(ClRadius.lg),
          boxShadow: ClElevation.card(cl.colors.shadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Text(title, style: cl.text.bodyStrong)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3, vertical: 2),
                  decoration: BoxDecoration(
                    color: cl.colors.lime,
                    borderRadius: BorderRadius.circular(ClRadius.full),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: formatNumber(best.value),
                          style: cl.text.metric.copyWith(color: cl.colors.onPop),
                        ),
                        if (unit != null)
                          TextSpan(
                            text: ' $unit',
                            style: cl.text.unit.copyWith(color: cl.colors.onPop),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            SizedBox(
              height: height,
              child: CustomPaint(
                size: Size.infinite,
                painter: _LineChartPainter(points, hi, cl.colors, cl.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.points, this.highlight, this.colors, this.text);

  final List<ClChartPoint> points;
  final int highlight;
  final ClColors colors;
  final ClTypography text;

  @override
  void paint(Canvas canvas, Size size) {
    const labelH = 20.0;
    const pad = 6.0;
    final chartH = size.height - labelH;
    final values = points.map((p) => p.value);
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    if (hi == lo) {
      hi += 1;
      lo -= 1;
    }
    final range = hi - lo;
    lo -= range * 0.1;
    hi += range * 0.1;

    final grid = Paint()
      ..color = colors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = (chartH - 1) * i / 2 + 0.5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    Offset at(int i) => Offset(
      pad + (size.width - pad * 2) * i / (points.length - 1),
      chartH - (points[i].value - lo) / (hi - lo) * chartH,
    );

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final h = at(highlight);
    canvas.drawCircle(h, 8, Paint()..color = colors.lime);
    canvas.drawCircle(
      h,
      8,
      Paint()
        ..color = colors.onPop
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final labelStyle = text.label;
    for (var i = 0; i < points.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: points[i].label,
          style: i == highlight ? labelStyle.copyWith(color: colors.ink) : labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = (at(i).dx - tp.width / 2).clamp(0.0, size.width - tp.width);
      tp.paint(canvas, Offset(x, size.height - tp.height));
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.points != points || old.highlight != highlight || old.colors != colors;
}
