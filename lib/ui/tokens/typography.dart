import 'package:flutter/painting.dart';

import 'colors.dart';

const _display = 'Manrope';
const _text = 'Manrope';
const _fallback = ['Helvetica Neue', 'Arial', 'sans-serif'];

/// Manrope, one variable font: 800 tight for titles and big numbers, 400–700
/// for everything else.
/// All text is sentence case; no style expects uppercase input.
TextStyle _style({
  required String family,
  required double size,
  required double lineHeight,
  required int weight,
  required Color color,
  double tracking = 0,
  bool numbers = false,
}) {
  return TextStyle(
    fontFamily: family,
    fontFamilyFallback: _fallback,
    fontSize: size,
    height: lineHeight / size,
    leadingDistribution: TextLeadingDistribution.even,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    // The variable font needs the axis set; the weight alone picks no cut.
    fontVariations: [FontVariation.weight(weight.toDouble())],
    fontFeatures: numbers ? const [FontFeature.tabularFigures()] : null,
    letterSpacing: size * tracking,
    color: color,
  );
}

class ClTypography {
  ClTypography(ClColors c)
    : displayXl = _disp(60, 56, c.ink),
      displayL = _disp(44, 42, c.ink),
      displayM = _disp(32, 32, c.ink),
      button = _style(family: _text, size: 16, lineHeight: 20, weight: 700, color: c.ink),
      buttonBlock = _style(family: _text, size: 17, lineHeight: 22, weight: 700, color: c.ink),
      metricL = _num(40, 42, c.ink),
      metric = _num(26, 28, c.ink),
      data = _style(family: _text, size: 16, lineHeight: 20, weight: 700, color: c.ink, numbers: true),
      unit = _style(family: _text, size: 12, lineHeight: 16, weight: 600, color: c.inkMuted),
      body = _style(family: _text, size: 15, lineHeight: 22, weight: 400, color: c.ink),
      bodyStrong = _style(family: _text, size: 15, lineHeight: 20, weight: 700, color: c.ink),
      label = _style(family: _text, size: 12, lineHeight: 16, weight: 700, color: c.inkMuted),
      tag = _style(family: _text, size: 11, lineHeight: 14, weight: 800, color: c.ink),
      filter = _style(family: _text, size: 13, lineHeight: 16, weight: 700, color: c.ink);

  static TextStyle _disp(double size, double line, Color color) =>
      _style(family: _display, size: size, lineHeight: line, weight: 800, tracking: -0.03, color: color);

  static TextStyle _num(double size, double line, Color color) => _style(
    family: _display,
    size: size,
    lineHeight: line,
    weight: 800,
    tracking: -0.03,
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

  /// Small bold caption above a value or a section. Sentence case.
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
