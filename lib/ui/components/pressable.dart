import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../tokens/spacing.dart';

/// Shared tap/press/focus behavior: keyboard activation, a 2px focus ring,
/// and a `pressed` flag passed to [builder]. No ripples anywhere.
class ClPressable extends StatefulWidget {
  const ClPressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.semanticLabel,
    this.radius = ClRadius.sm,
    this.selected,
    this.button = true,
  });

  final VoidCallback? onPressed;
  final Widget Function(BuildContext context, bool pressed) builder;
  final String? semanticLabel;
  final double radius;
  final bool? selected;
  final bool button;

  @override
  State<ClPressable> createState() => _ClPressableState();
}

class _ClPressableState extends State<ClPressable> {
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
    return Semantics(
      button: widget.button,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          onTap: widget.onPressed,
          child: Container(
            foregroundDecoration: _focused
                ? BoxDecoration(
                    border: Border.all(
                      color: c.focus,
                      width: ClSize.focusRing,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                    borderRadius: BorderRadius.circular(widget.radius + ClSize.focusRing),
                  )
                : null,
            child: widget.builder(context, _pressed),
          ),
        ),
      ),
    );
  }
}
