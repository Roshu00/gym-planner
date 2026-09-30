import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'pressable.dart';

/// Big rounded block in a pop color (lime, lilac, peach): the signature
/// surface of the app. Everything inside renders in the light theme, so text
/// is always ink on the color, in both themes.
class ClPopBlock extends StatelessWidget {
  const ClPopBlock({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.all(ClSpace.s4),
    this.sticker,
    this.onPressed,
    this.semanticLabel,
  });

  final Color color;
  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Optional [ClSticker] pinned over the top-right corner.
  final Widget? sticker;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget block(bool pressed) => AnimatedScale(
      duration: context.motion(ClMotion.fast),
      curve: ClMotion.curve,
      scale: pressed ? 0.98 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(ClRadius.lg)),
            child: ClThemeScope(theme: ClTheme.light, child: child),
          ),
          if (sticker != null) Positioned(top: -ClSpace.s2, right: ClSpace.s3, child: sticker!),
        ],
      ),
    );
    if (onPressed == null) return block(false);
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      radius: ClRadius.lg,
      builder: (context, pressed) => block(pressed),
    );
  }
}

/// Tilted black pill with lime text, like a sticker: "Nedelja 3/8", "Novi PR".
/// One per block at most.
class ClSticker extends StatelessWidget {
  const ClSticker(this.label, {super.key, this.angle = 6});

  final String label;

  /// Tilt in degrees.
  final double angle;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Transform.rotate(
      angle: angle * math.pi / 180,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3, vertical: 6),
        decoration: BoxDecoration(color: cl.colors.onPop, borderRadius: BorderRadius.circular(ClRadius.full)),
        child: Text(
          label,
          style: cl.text.tag.copyWith(fontSize: 12, height: 16 / 12, color: cl.colors.lime),
        ),
      ),
    );
  }
}
