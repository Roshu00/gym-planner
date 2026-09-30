import 'package:flutter/material.dart';

import 'tokens/colors.dart';
import 'tokens/typography.dart';

class ClTheme extends ThemeExtension<ClTheme> {
  ClTheme(this.colors) : text = ClTypography(colors);

  final ClColors colors;
  final ClTypography text;

  static final dark = ClTheme(ClColors.dark);
  static final light = ClTheme(ClColors.light);

  static ClTheme of(BuildContext context) => Theme.of(context).extension<ClTheme>() ?? light;

  @override
  ClTheme copyWith({ClColors? colors}) => ClTheme(colors ?? this.colors);

  @override
  ClTheme lerp(ClTheme? other, double t) => t < 0.5 || other == null ? this : other;

  ThemeData toThemeData() {
    final c = colors;
    final isDark = c.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      fontFamily: 'Bricolage',
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      dividerColor: c.border,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: c.surface,
      focusColor: c.surface,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.ink,
        selectionColor: c.signalSoft,
        selectionHandleColor: c.signal,
      ),
      colorScheme: (isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
        primary: c.signal,
        onPrimary: c.onSignal,
        secondary: c.ink,
        onSecondary: c.bg,
        surface: c.bg,
        onSurface: c.ink,
        error: c.danger,
        outline: c.borderStrong,
        outlineVariant: c.border,
      ),
      textTheme: TextTheme(bodyMedium: text.body, bodyLarge: text.body, labelSmall: text.label),
      extensions: [this],
    );
  }
}

extension ClThemeContext on BuildContext {
  ClTheme get cl => ClTheme.of(this);
  ClColors get clColors => ClTheme.of(this).colors;
  ClTypography get clText => ClTheme.of(this).text;

  /// Respect the platform "reduce motion" setting.
  Duration motion(Duration d) => MediaQuery.maybeDisableAnimationsOf(this) == true ? Duration.zero : d;
}

/// Forces a subtree into one theme, e.g. a light Summary inside a dark app.
class ClThemeScope extends StatelessWidget {
  const ClThemeScope({super.key, required this.theme, required this.child});

  final ClTheme theme;
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: theme.toThemeData(),
    child: DefaultTextStyle(style: theme.text.body, child: child),
  );
}
