import 'dart:ui';

/// The only file in the codebase allowed to contain hex color values.
/// Changing the brand color is a one-line change to [_signal], [_signalTextDark]
/// and the two `signalSoft` values.
const _signal = Color(0xFF2F4BFF);
const _signalTextDark = Color(0xFF6E82FF);

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
  final Color bg;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color rule;
  final Color borderStrong;
  final Color ink;
  final Color inkMuted;
  final Color signal;
  final Color onSignal;

  /// Signal used as text or a thin line. Lighter on dark for contrast.
  final Color signalText;

  /// Rare tinted background. Never put body text on it.
  final Color signalSoft;
  final Color danger;
  final Color focus;

  /// Empty or loading media frame. Dark in both themes.
  final Color photoEmpty;
  final Color photoScrim;

  /// Text over photos. White in both themes, always on [photoScrim].
  final Color onPhoto;

  static const dark = ClColors(
    brightness: Brightness.dark,
    bg: Color(0xFF000000),
    surface: Color(0xFF111111),
    surfaceRaised: Color(0xFF1C1C1C),
    border: Color(0xFF262626),
    rule: Color(0xFFFFFFFF),
    borderStrong: Color(0xFF666666),
    ink: Color(0xFFFFFFFF),
    inkMuted: Color(0xFF8A8A8A),
    signal: _signal,
    onSignal: Color(0xFFFFFFFF),
    signalText: _signalTextDark,
    signalSoft: Color(0xFF0F1740),
    danger: Color(0xFFFF6B5E),
    focus: _signalTextDark,
    photoEmpty: Color(0xFF1C1C1C),
    photoScrim: Color(0x8C000000),
    onPhoto: Color(0xFFFFFFFF),
  );

  static const light = ClColors(
    brightness: Brightness.light,
    bg: Color(0xFFFFFFFF),
    surface: Color(0xFFF5F5F5),
    surfaceRaised: Color(0xFFEDEDED),
    border: Color(0xFFE3E3E3),
    rule: Color(0xFF000000),
    borderStrong: Color(0xFF8A8A8A),
    ink: Color(0xFF000000),
    inkMuted: Color(0xFF6B6B6B),
    signal: _signal,
    onSignal: Color(0xFFFFFFFF),
    signalText: _signal,
    signalSoft: Color(0xFFE6EAFF),
    danger: Color(0xFFD92D20),
    focus: _signal,
    photoEmpty: Color(0xFF1C1C1C),
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
    'border-strong': borderStrong,
    'ink': ink,
    'ink-muted': inkMuted,
    'signal': signal,
    'on-signal': onSignal,
    'signal-text': signalText,
    'signal-soft': signalSoft,
    'danger': danger,
    'focus': focus,
    'photo-empty': photoEmpty,
    'photo-scrim': photoScrim,
  };
}
