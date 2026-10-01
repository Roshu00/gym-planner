import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';

class ClStat {
  const ClStat({required this.label, required this.value, this.unit, this.highlight = false});

  final String label;

  /// Pre-formatted number, e.g. `8.240`, `3/4`.
  final String value;
  final String? unit;

  /// Progress or record number: the tile turns lime. Use on one tile at most.
  final bool highlight;
}

/// 2–3 equal rounded tiles, `label` on top, `metric` (or `metric-l` when
/// [large]) below. The highlighted tile is lime.
class ClStatBar extends StatelessWidget {
  const ClStatBar({super.key, required this.stats, this.segments, this.large = false});

  final List<ClStat> stats;

  /// Optional segment bar below, e.g. workouts done this week.
  final ClSegmentBar? segments;
  final bool large;

  @override
  Widget build(BuildContext context) {
    assert(stats.length >= 2 && stats.length <= 3, 'StatBar takes 2–3 stats');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const SizedBox(width: ClSpace.s2),
                Expanded(
                  child: _StatCell(stat: stats[i], large: large),
                ),
              ],
            ],
          ),
        ),
        if (segments != null) ...[const SizedBox(height: ClSpace.s3), segments!],
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.stat, required this.large});

  final ClStat stat;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final fg = stat.highlight ? c.onPop : c.ink;
    return Semantics(
      label: '${stat.label}: ${stat.value}${stat.unit == null ? '' : ' ${stat.unit}'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(ClSpace.s3, ClSpace.s3, ClSpace.s2, ClSpace.s3),
        decoration: BoxDecoration(
          color: stat.highlight ? c.lime : c.surface,
          borderRadius: BorderRadius.circular(ClRadius.sm),
          boxShadow: stat.highlight ? null : ClElevation.card(c.shadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cl.text.label.copyWith(color: stat.highlight ? c.onPop : null),
            ),
            const SizedBox(height: ClSpace.s1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: stat.value,
                      style: (large ? cl.text.metricL : cl.text.metric).copyWith(color: fg),
                    ),
                    if (stat.unit != null)
                      TextSpan(
                        text: ' ${stat.unit}',
                        style: cl.text.unit.copyWith(color: stat.highlight ? c.onPop : null),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded 10px segments: done = `ink`, remaining = `border`.
class ClSegmentBar extends StatelessWidget {
  const ClSegmentBar({super.key, required this.total, required this.done, this.onPop = false})
    : assert(total > 0 && done >= 0);

  final int total;
  final int done;

  /// Sitting on a pop color block: the remaining segments turn translucent ink.
  final bool onPop;

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
    final doneColor = onPop ? c.onPop : c.ink;
    final restColor = onPop ? c.onPop.withValues(alpha: 0.15) : c.border;
    return Semantics(
      label: '$done od $total',
      child: SizedBox(
        height: ClSize.bar,
        child: Row(
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: ClSize.barGap),
              Expanded(
                child: AnimatedContainer(
                  duration: context.motion(ClMotion.base),
                  curve: ClMotion.curve,
                  decoration: BoxDecoration(
                    color: i < done ? doneColor : restColor,
                    borderRadius: BorderRadius.circular(ClRadius.full),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Continuous rounded progress line (rest timer, uploads). [value] is 0..1.
class ClProgressLine extends StatelessWidget {
  const ClProgressLine({super.key, required this.value, this.height = 8, this.onPop = false});

  final double value;
  final double height;

  /// Sitting on a pop color block: ink on translucent ink.
  final bool onPop;

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
    final radius = BorderRadius.circular(ClRadius.full);
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: onPop ? c.onPop.withValues(alpha: 0.15) : c.border),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0, 1),
              child: DecoratedBox(
                decoration: BoxDecoration(color: onPop ? c.onPop : c.ink, borderRadius: radius),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
