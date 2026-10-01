import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'pressable.dart';

enum ClButtonVariant {
  /// Black pill. One per screen.
  primary,

  /// Lime pill: the one action that should pop ("Pretplati se").
  pop,

  /// 1.5px ink outline, transparent.
  secondary,

  /// Plain ink label without a fill, for a secondary link next to a button.
  text,

  /// Full width, 56px, black pill. Pinned to the bottom of the screen.
  block,

  /// Destructive: danger outline, danger label.
  danger,
}

/// 1–2 words, verb first, sentence case: `Počni trening`, `Završi set`.
class ClButton extends StatelessWidget {
  const ClButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ClButtonVariant.primary,
    this.icon,
    this.expand = false,
  });

  const ClButton.block({super.key, required this.label, required this.onPressed, this.icon})
    : variant = ClButtonVariant.block,
      expand = true;

  final String label;
  final VoidCallback? onPressed;
  final ClButtonVariant variant;

  /// Trailing icon, e.g. an arrow. The label always stays.
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final enabled = onPressed != null;

    if (variant == ClButtonVariant.text) {
      final style = cl.text.bodyStrong.copyWith(color: enabled ? c.ink : c.inkMuted);
      return ClPressable(
        onPressed: onPressed,
        builder: (context, pressed) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ClSize.target),
          child: Opacity(
            opacity: pressed ? 0.6 : 1,
            child: Align(
              widthFactor: 1,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(label, style: style)),
                  if (icon != null) ...[
                    const SizedBox(width: ClSpace.s1),
                    Icon(icon, size: 18, color: style.color),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final isBlock = variant == ClButtonVariant.block;
    final (Color fill, Color fg, Color? outline) = switch (variant) {
      _ when !enabled => (c.border, c.inkMuted, null),
      ClButtonVariant.primary || ClButtonVariant.block => (c.ink, c.bg, null),
      ClButtonVariant.pop => (c.signal, c.onSignal, c.onPop),
      ClButtonVariant.danger => (Colors.transparent, c.danger, c.danger),
      _ => (Colors.transparent, c.ink, c.borderStrong),
    };

    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      radius: ClRadius.full,
      builder: (context, pressed) {
        final pressedFill = fill == Colors.transparent ? c.surfaceRaised : fill.withValues(alpha: 0.82);
        return AnimatedContainer(
          duration: context.motion(ClMotion.fast),
          curve: ClMotion.curve,
          height: isBlock ? ClSize.targetWorkout : ClSize.target,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: isBlock ? ClSpace.s6 : ClSpace.s4 + 4),
          decoration: BoxDecoration(
            color: pressed ? pressedFill : fill,
            borderRadius: BorderRadius.circular(ClRadius.full),
            border: outline == null ? null : Border.all(color: outline, width: 1.5),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (isBlock ? cl.text.buttonBlock : cl.text.button).copyWith(color: fg),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: ClSpace.s2),
                Icon(icon, size: isBlock ? 24 : 20, color: fg),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Icon-only button. A semantic label is required; prefer a text label when possible.
class ClIconButton extends StatelessWidget {
  const ClIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// Defaults to `ink`; pass `onPhoto` over media.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, pressed) => SizedBox.square(
        dimension: ClSize.target,
        child: Opacity(
          opacity: onPressed == null ? 0.4 : (pressed ? 0.6 : 1),
          child: Icon(icon, size: ClSize.icon, color: color ?? c.ink),
        ),
      ),
    );
  }
}
