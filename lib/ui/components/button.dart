import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'pressable.dart';

enum ClButtonVariant {
  /// Signal fill. One per screen.
  primary,

  /// Ink fill on bg ("PRETPLATI SE" on the creator profile).
  ink,

  /// 1px border-strong, transparent.
  secondary,

  /// Underlined, sentence case.
  text,

  /// Full width, 56px, signal fill. Pinned to the bottom of the screen.
  block,

  /// Destructive: 1px danger outline, danger label.
  danger,
}

/// 1–2 words, verb first: `POČNI TRENING`, `ZAVRŠI SET`.
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
      final style = cl.text.bodyStrong.copyWith(
        color: enabled ? c.ink : c.inkMuted,
        decoration: TextDecoration.underline,
        decorationColor: enabled ? c.ink : c.inkMuted,
        decorationThickness: 1.5,
      );
      return ClPressable(
        onPressed: onPressed,
        builder: (context, pressed) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: ClSize.target),
          child: Opacity(
            opacity: pressed ? 0.6 : 1,
            child: Align(
              widthFactor: 1,
              alignment: Alignment.centerLeft,
              child: Text(label, style: style),
            ),
          ),
        ),
      );
    }

    final isBlock = variant == ClButtonVariant.block;
    final (Color fill, Color fg, Color? outline) = switch (variant) {
      _ when !enabled => (c.border, c.inkMuted, null),
      ClButtonVariant.primary || ClButtonVariant.block => (c.signal, c.onSignal, null),
      ClButtonVariant.ink => (c.ink, c.bg, null),
      ClButtonVariant.danger => (Colors.transparent, c.danger, c.danger),
      _ => (Colors.transparent, c.ink, c.borderStrong),
    };

    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      builder: (context, pressed) {
        final pressedFill = outline != null ? c.surfaceRaised : fill.withValues(alpha: 0.82);
        return AnimatedContainer(
          duration: context.motion(ClMotion.fast),
          curve: ClMotion.curve,
          height: isBlock ? ClSize.targetWorkout : ClSize.target,
          width: expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: isBlock ? ClSpace.s6 : ClSpace.s4 + 4),
          decoration: BoxDecoration(
            color: pressed ? pressedFill : fill,
            borderRadius: BorderRadius.circular(ClRadius.sm),
            border: outline == null ? null : Border.all(color: outline),
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label.toUpperCase(),
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
