import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'pressable.dart';

enum ClTagVariant {
  /// Personal record. Signal fill.
  pr,

  /// Inset 1px border-strong.
  outline,

  /// Outline in danger.
  danger,
}

/// 18px, radius 2, 10/700 UPPERCASE.
class ClTag extends StatefulWidget {
  const ClTag(this.label, {super.key, this.variant = ClTagVariant.outline, this.animateIn = false});

  const ClTag.pr({super.key, this.animateIn = false}) : label = 'PR', variant = ClTagVariant.pr;

  final String label;
  final ClTagVariant variant;

  /// Scale in once (a freshly set record).
  final bool animateIn;

  @override
  State<ClTag> createState() => _ClTagState();
}

class _ClTagState extends State<ClTag> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: ClMotion.base);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.animateIn && !_ctrl.isAnimating && _ctrl.value == 0) {
      _ctrl.duration = context.motion(ClMotion.base);
      _ctrl.forward();
    } else if (!widget.animateIn) {
      _ctrl.value = 1;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final (Color? fill, Color fg, Color? line) = switch (widget.variant) {
      ClTagVariant.pr => (c.signal, c.onSignal, null),
      ClTagVariant.outline => (null, c.ink, c.borderStrong),
      ClTagVariant.danger => (null, c.danger, c.danger),
    };
    return ScaleTransition(
      scale: CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
      child: Container(
        height: 18,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(ClRadius.xs),
          border: line == null ? null : Border.all(color: line),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(widget.label.toUpperCase(), style: cl.text.tag.copyWith(color: fg)),
        ),
      ),
    );
  }
}

/// 32px, radius 4, 12/600 UPPERCASE. Selected = ink fill with bg text.
class ClFilter extends StatelessWidget {
  const ClFilter({super.key, required this.label, required this.selected, required this.onChanged});

  final String label;
  final bool selected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return ClPressable(
      selected: selected,
      semanticLabel: label,
      onPressed: onChanged == null ? null : () => onChanged!(!selected),
      builder: (context, pressed) => Padding(
        padding: const EdgeInsets.symmetric(vertical: (ClSize.target - 32) / 2),
        child: AnimatedContainer(
          duration: context.motion(ClMotion.fast),
          curve: ClMotion.curve,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.ink : (pressed ? c.surfaceRaised : Colors.transparent),
            borderRadius: BorderRadius.circular(ClRadius.sm),
            border: Border.all(color: selected ? c.ink : c.borderStrong),
          ),
          child: Text(label.toUpperCase(), style: cl.text.filter.copyWith(color: selected ? c.bg : c.ink)),
        ),
      ),
    );
  }
}

/// Horizontally scrolling row of filters with the screen gutter.
class ClFilterRow extends StatelessWidget {
  const ClFilterRow({super.key, required this.options, required this.selected, required this.onChanged});

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
      child: Row(
        children: [
          for (final o in options) ...[
            ClFilter(
              label: o,
              selected: selected.contains(o),
              onChanged: (on) => onChanged(on ? {...selected, o} : ({...selected}..remove(o))),
            ),
            if (o != options.last) const SizedBox(width: ClSpace.s2),
          ],
        ],
      ),
    );
  }
}
