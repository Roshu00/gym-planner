import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../theme.dart';
import '../tokens/colors.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'rule.dart';

class ClChartPoint {
  const ClChartPoint(this.label, this.value);

  /// X-axis label, e.g. `N1` or `12.9.`
  final String label;
  final double value;
}

/// Progress chart: 2px `ink` line, no fills or gradients. Only the current or
/// best point uses `signal`, with its value in `signal-text`.
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ClRule(),
          const SizedBox(height: ClSpace.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: Text(title.toUpperCase(), style: cl.text.label)),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: formatNumber(best.value),
                      style: cl.text.metric.copyWith(color: cl.colors.signalText),
                    ),
                    if (unit != null) TextSpan(text: ' $unit', style: cl.text.unit),
                  ],
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
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.miter
        ..strokeCap = StrokeCap.square,
    );

    final h = at(highlight);
    canvas.drawRect(Rect.fromCenter(center: h, width: 10, height: 10), Paint()..color = colors.signal);

    final labelStyle = text.label;
    for (var i = 0; i < points.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: points[i].label.toUpperCase(),
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
