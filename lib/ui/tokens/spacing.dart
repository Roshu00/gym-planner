import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

abstract final class ClSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;

  /// Screen gutter.
  static const double s4 = 16;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s12 = 48;
}

abstract final class ClRadius {
  /// Fields and small inner boxes.
  static const double xs = 12;

  /// Rows, cards, photos inside a block.
  static const double sm = 20;

  /// Color blocks, big photos, sheets.
  static const double lg = 28;

  /// Hard edge, only for full-bleed media.
  static const double none = 0;

  /// Buttons, tags, filters, avatars, checks.
  static const double full = 999;
}

abstract final class ClSize {
  static const double target = 48;
  static const double targetWorkout = 56;
  static const double rule = 1.5;
  static const double hairline = 1;
  static const double bar = 10;
  static const double barGap = 6;
  static const double focusRing = 2;
  static const double icon = 24;
  static const double avatarList = 28;
  static const double avatarProfile = 56;
}

abstract final class ClMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 200);
  static const sheet = Duration(milliseconds: 250);
  static const curve = Curves.easeOut;

  /// Tab changes: the nav pill and the screen move together.
  static const tab = Duration(milliseconds: 320);
  static const tabCurve = Curves.easeOutCubic;
}

/// Soft shadow that lifts white cards off the warm background. Only on
/// `surface` cards (rows, tiles, menus, calendar); pop blocks and controls
/// stay flat.
abstract final class ClElevation {
  static List<BoxShadow> card(Color shadow) => [
    BoxShadow(color: shadow, blurRadius: 18, spreadRadius: -6, offset: const Offset(0, 6)),
    BoxShadow(
      color: shadow.withValues(alpha: shadow.a * 0.5),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];
}
