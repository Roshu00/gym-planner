import 'package:flutter/animation.dart';

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
}
