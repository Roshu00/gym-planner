import 'dart:ui';

/// The only file in the codebase allowed to contain hex color values.
///
/// "Mekana noć": a soft near-black ground, raised graphite surfaces, white
/// ink and one orange accent. Blocks without a photo use the pop colors
/// (orange, apricot, mist) with [ClColors.onPop] text.
const _orange = Color(0xFFFF5B1F);
const _apricot = Color(0xFFFFB089);
const _mist = Color(0xFFD9D9DE);
const _onPop = Color(0xFF0E0E10);

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
    required this.shadow,
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

  /// Orange. Done, current, records, the accent of a number.
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

  /// Soft warm shadow under white cards (see `ClElevation`).
  final Color shadow;

  Color get lime => _orange;
  Color get lilac => _mist;
  Color get peach => _apricot;

  /// Text and icons on any pop color.
  Color get onPop => _onPop;

  /// The pop colors in rotation order, e.g. one per workout of a program.
  List<Color> get pops => const [_orange, _apricot, _mist];

  /// A stable pop color for a key, so the same workout always has the same color.
  Color popFor(String key) => pops[key.codeUnits.fold(0, (a, b) => a + b) % pops.length];

  /// The app has one look; both names give the same dark palette, so screens
  /// that ask for "light" (a summary, a sheet) stay in it.
  static const light = ClColors(
    brightness: Brightness.dark,
    bg: Color(0xFF0E0E10),
    surface: Color(0xFF19191C),
    surfaceRaised: Color(0xFF242428),
    border: Color(0xFF2A2A2F),
    rule: Color(0xFF3A3A40),
    borderStrong: Color(0xFFF4F4F5),
    ink: Color(0xFFF4F4F5),
    inkMuted: Color(0xFFA1A1AA),
    signal: _orange,
    onSignal: _onPop,
    signalText: Color(0xFFFF8A5C),
    signalSoft: Color(0xFF2E1B12),
    danger: Color(0xFFFF6B5E),
    focus: _orange,
    photoEmpty: Color(0xFF19191C),
    photoScrim: Color(0x99000000),
    onPhoto: Color(0xFFFFFFFF),
    shadow: Color(0x66000000),
  );

  static const dark = ClColors(
    brightness: Brightness.dark,
    bg: Color(0xFF0E0E10),
    surface: Color(0xFF19191C),
    surfaceRaised: Color(0xFF242428),
    border: Color(0xFF2A2A2F),
    rule: Color(0xFF3A3A40),
    borderStrong: Color(0xFFF4F4F5),
    ink: Color(0xFFF4F4F5),
    inkMuted: Color(0xFFA1A1AA),
    signal: _orange,
    onSignal: _onPop,
    signalText: Color(0xFFFF8A5C),
    signalSoft: Color(0xFF2E1B12),
    danger: Color(0xFFFF6B5E),
    focus: _orange,
    photoEmpty: Color(0xFF19191C),
    photoScrim: Color(0x99000000),
    onPhoto: Color(0xFFFFFFFF),
    shadow: Color(0x66000000),
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
    'signal (orange)': signal,
    'lilac': lilac,
    'peach': peach,
    'on-pop': onPop,
    'signal-text': signalText,
    'signal-soft': signalSoft,
    'danger': danger,
    'photo-empty': photoEmpty,
  };
}
