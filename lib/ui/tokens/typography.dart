import 'package:flutter/painting.dart';

import 'colors.dart';

const _family = 'Archivo';
const _fallback = ['Helvetica Neue', 'Arial', 'sans-serif'];

/// Archivo at three widths: condensed (62%) for titles, normal (100%) for
/// text, wide (125%) for every number.
TextStyle _archivo({
  required double size,
  required double lineHeight,
  required double width,
  required int weight,
  required Color color,
  double tracking = 0,
  bool numbers = false,
}) {
  return TextStyle(
    fontFamily: _family,
    fontFamilyFallback: _fallback,
    fontSize: size,
    height: lineHeight / size,
    leadingDistribution: TextLeadingDistribution.even,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation.weight(weight.toDouble()), FontVariation.width(width)],
    fontFeatures: numbers ? const [FontFeature.tabularFigures()] : null,
    letterSpacing: size * tracking,
    color: color,
  );
}

/// Text styles from DESIGN.md §3.2. Condensed styles expect UPPERCASE input;
/// components uppercase their own strings.
class ClTypography {
  ClTypography(ClColors c)
    : displayXl = _cond(96, 82, c.ink),
      displayL = _cond(72, 62, c.ink),
      displayM = _cond(48, 42, c.ink),
      button = _cond(20, 20, c.ink),
      buttonBlock = _cond(26, 26, c.ink),
      metricL = _wide(40, 44, c.ink),
      metric = _wide(24, 28, c.ink),
      data = _wide(15, 20, c.ink),
      unit = _archivo(size: 12, lineHeight: 16, width: 100, weight: 600, color: c.inkMuted),
      body = _archivo(size: 15, lineHeight: 22, width: 100, weight: 400, color: c.ink),
      bodyStrong = _archivo(size: 15, lineHeight: 20, width: 100, weight: 700, color: c.ink),
      label = _archivo(size: 11, lineHeight: 14, width: 100, weight: 600, tracking: 0.08, color: c.inkMuted),
      tag = _archivo(size: 10, lineHeight: 12, width: 100, weight: 700, tracking: 0.06, color: c.ink),
      filter = _archivo(size: 12, lineHeight: 16, width: 100, weight: 600, tracking: 0.06, color: c.ink);

  static TextStyle _cond(double size, double line, Color color) =>
      _archivo(size: size, lineHeight: line, width: 62, weight: 900, tracking: -0.01, color: color);

  static TextStyle _wide(double size, double line, Color color) => _archivo(
    size: size,
    lineHeight: line,
    width: 125,
    weight: 800,
    tracking: -0.02,
    color: color,
    numbers: true,
  );

  final TextStyle displayXl;
  final TextStyle displayL;
  final TextStyle displayM;
  final TextStyle button;
  final TextStyle buttonBlock;
  final TextStyle metricL;
  final TextStyle metric;
  final TextStyle data;

  /// Units next to numbers ("kg", "min"): 12/600.
  final TextStyle unit;
  final TextStyle body;
  final TextStyle bodyStrong;
  final TextStyle label;
  final TextStyle tag;
  final TextStyle filter;

  Map<String, TextStyle> get all => {
    'display-xl': displayXl,
    'display-l': displayL,
    'display-m': displayM,
    'button': button,
    'metric-l': metricL,
    'metric': metric,
    'data': data,
    'body': body,
    'body-strong': bodyStrong,
    'label': label,
  };
}
