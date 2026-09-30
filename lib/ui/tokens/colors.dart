import 'dart:ui';

/// The only file in the codebase allowed to contain hex color values.
///
/// Color Pop: a warm off-white base, black ink, and three bright pop colors
/// (lime, lilac, peach) used as big rounded blocks. Text on a pop color is
/// always [ClColors.onPop], in both themes.
const _lime = Color(0xFFD4F54A);
const _lilac = Color(0xFFC9B6FF);
const _peach = Color(0xFFFFC6A3);
const _onPop = Color(0xFF111111);

class ClColors {
  const ClColors({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.rule,
    required this.borderStrong,
    required this.ink,
    required this.inkMuted,
    required this.signal,
    required this.onSignal,
    required this.signalText,
    required this.signalSoft,
    required this.danger,
    required this.focus,
    required this.photoEmpty,
    required this.photoScrim,
    required this.onPhoto,
  });

  final Brightness brightness;

  /// Page background.
  final Color bg;

  /// Cards, rows and sheets that sit on [bg].
  final Color surface;

  /// Fields and chips: the recessed fill inside a card.
  final Color surfaceRaised;
  final Color border;

  /// Separators that should read as a line, not a hairline.
  final Color rule;

  /// Outlines of interactive objects: set rows, checks, secondary buttons.
  final Color borderStrong;
  final Color ink;
  final Color inkMuted;

  /// Lime. Done, current, records, the accent of a number.
  final Color signal;
  final Color onSignal;

  /// Accent used as text or a thin line, readable on [bg].
  final Color signalText;

  /// Tinted background for a quiet highlight.
  final Color signalSoft;
  final Color danger;
  final Color focus;

  /// Empty or loading media frame. Dark in both themes.
  final Color photoEmpty;
  final Color photoScrim;

  /// Text over photos. White in both themes, always on [photoScrim].
  final Color onPhoto;

  Color get lime => _lime;
  Color get lilac => _lilac;
  Color get peach => _peach;

  /// Text and icons on any pop color.
  Color get onPop => _onPop;

  /// The pop colors in rotation order, e.g. one per workout of a program.
  List<Color> get pops => const [_lime, _lilac, _peach];

  /// A stable pop color for a key, so the same workout always has the same color.
  Color popFor(String key) => pops[key.codeUnits.fold(0, (a, b) => a + b) % pops.length];

  static const light = ClColors(
    brightness: Brightness.light,
    bg: Color(0xFFFAF8F4),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEFECE5),
    border: Color(0xFFE6E2D8),
    rule: Color(0xFF111111),
    borderStrong: Color(0xFF111111),
    ink: Color(0xFF111111),
    inkMuted: Color(0xFF5A5750),
    signal: _lime,
    onSignal: _onPop,
    signalText: Color(0xFF3F6B00),
    signalSoft: Color(0xFFF0FBC4),
    danger: Color(0xFFD92D20),
    focus: Color(0xFF111111),
    photoEmpty: Color(0xFF1F1E1B),
    photoScrim: Color(0x8C000000),
    onPhoto: Color(0xFFFFFFFF),
  );

  static const dark = ClColors(
    brightness: Brightness.dark,
    bg: Color(0xFF111111),
    surface: Color(0xFF1C1C1B),
    surfaceRaised: Color(0xFF2A2927),
    border: Color(0xFF2E2D2A),
    rule: Color(0xFFFAF8F4),
    borderStrong: Color(0xFFFAF8F4),
    ink: Color(0xFFFAF8F4),
    inkMuted: Color(0xFFA9A59C),
    signal: _lime,
    onSignal: _onPop,
    signalText: _lime,
    signalSoft: Color(0xFF2C3310),
    danger: Color(0xFFFF6B5E),
    focus: _lime,
    photoEmpty: Color(0xFF2A2927),
    photoScrim: Color(0x8C000000),
    onPhoto: Color(0xFFFFFFFF),
  );

  /// Name/value pairs, for the gallery swatches.
  Map<String, Color> get all => {
    'bg': bg,
    'surface': surface,
    'surface-raised': surfaceRaised,
    'border': border,
    'rule': rule,
    'ink': ink,
    'ink-muted': inkMuted,
    'signal (lime)': signal,
    'lilac': lilac,
    'peach': peach,
    'on-pop': onPop,
    'signal-text': signalText,
    'signal-soft': signalSoft,
    'danger': danger,
    'photo-empty': photoEmpty,
  };
}
