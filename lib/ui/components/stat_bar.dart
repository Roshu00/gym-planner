import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens/spacing.dart';
import 'rule.dart';

class ClStat {
  const ClStat({required this.label, required this.value, this.unit, this.highlight = false});

  final String label;

  /// Pre-formatted number, e.g. `8.240`, `3/4`.
  final String value;
  final String? unit;

  /// Progress or record number, shown in `signal-text`. Use on one cell at most.
  final bool highlight;
}

/// 2–3 equal columns under a 2px rule, 1px dividers between columns.
/// `label` on top, `metric` (or `metric-l` when [large]) below.
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
        const ClRule(),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) const ClDivider(vertical: true),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(i == 0 ? 0 : ClSpace.s3, ClSpace.s3, ClSpace.s2, ClSpace.s3),
                    child: _StatCell(stat: stats[i], large: large),
                  ),
                ),
              ],
            ],
          ),
        ),
        ?segments,
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
    final color = stat.highlight ? cl.colors.signalText : cl.colors.ink;
    return Semantics(
      label: '${stat.label}: ${stat.value}${stat.unit == null ? '' : ' ${stat.unit}'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stat.label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: cl.text.label),
          const SizedBox(height: ClSpace.s1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: stat.value,
                    style: (large ? cl.text.metricL : cl.text.metric).copyWith(color: color),
                  ),
                  if (stat.unit != null) TextSpan(text: ' ${stat.unit}', style: cl.text.unit),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `bar-h` 4px segments with 3px gaps: done = `signal`, remaining = `border`.
class ClSegmentBar extends StatelessWidget {
  const ClSegmentBar({super.key, required this.total, required this.done}) : assert(total > 0 && done >= 0);

  final int total;
  final int done;

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
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
                  color: i < done ? c.signal : c.border,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Continuous thin progress line (rest timer, uploads). [value] is 0..1.
class ClProgressLine extends StatelessWidget {
  const ClProgressLine({super.key, required this.value, this.height = ClSize.rule});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: c.border),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0, 1),
            child: ColoredBox(color: c.signal),
          ),
        ],
      ),
    );
  }
}
