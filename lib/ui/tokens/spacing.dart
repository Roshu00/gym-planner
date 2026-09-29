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
  /// Tags.
  static const double xs = 2;

  /// Buttons, inputs, filters.
  static const double sm = 4;

  /// Photos and sections.
  static const double none = 0;

  /// Avatar only.
  static const double full = 999;
}

abstract final class ClSize {
  static const double target = 48;
  static const double targetWorkout = 56;
  static const double rule = 2;
  static const double hairline = 1;
  static const double bar = 4;
  static const double barGap = 3;
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
