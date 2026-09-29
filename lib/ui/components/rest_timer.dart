import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../theme.dart';
import '../tokens/spacing.dart';
import 'button.dart';
import 'rule.dart';
import 'stat_bar.dart';

/// Rest countdown: `label`, big `metric-l` clock, thin progress line.
/// Keeps counting past zero in `danger` (rest time over). Give it a new key to restart.
class ClRestTimer extends StatefulWidget {
  const ClRestTimer({
    super.key,
    required this.duration,
    this.onSkip,
    this.onFinished,
    this.step = const Duration(seconds: 15),
  });

  final Duration duration;
  final VoidCallback? onSkip;
  final VoidCallback? onFinished;
  final Duration step;

  @override
  State<ClRestTimer> createState() => _ClRestTimerState();
}

class _ClRestTimerState extends State<ClRestTimer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick)..start();
  late Duration _total = widget.duration;
  Duration _elapsed = Duration.zero;
  bool _finishedFired = false;

  Duration get _remaining => _total - _elapsed;

  void _onTick(Duration t) {
    final next = t;
    if (next.inSeconds != _elapsed.inSeconds) {
      setState(() => _elapsed = next);
      if (!_finishedFired && _remaining <= Duration.zero) {
        _finishedFired = true;
        HapticFeedback.mediumImpact();
        widget.onFinished?.call();
      }
    } else {
      _elapsed = next;
    }
  }

  void _adjust(Duration d) => setState(() {
    _total += d;
    if (_total < Duration.zero) _total = Duration.zero;
    if (_remaining > Duration.zero) _finishedFired = false;
  });

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final over = _remaining < Duration.zero;
    final shown = Duration(seconds: (_remaining.inMilliseconds / 1000).ceil());
    final progress = _total.inMilliseconds == 0 ? 1.0 : _elapsed.inMilliseconds / _total.inMilliseconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClRule(),
        const SizedBox(height: ClSpace.s3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(over ? 'ODMOR JE GOTOV' : 'ODMOR', style: cl.text.label),
                  const SizedBox(height: ClSpace.s1),
                  Semantics(
                    liveRegion: true,
                    label: over ? 'Odmor je gotov' : 'Odmor ${formatClock(shown)}',
                    excludeSemantics: true,
                    child: Text(
                      formatClock(over ? -_remaining : shown),
                      style: cl.text.metricL.copyWith(color: over ? cl.colors.danger : cl.colors.ink),
                    ),
                  ),
                ],
              ),
            ),
            _Step(label: '−${widget.step.inSeconds} s', onPressed: () => _adjust(-widget.step)),
            const SizedBox(width: ClSpace.s2),
            _Step(label: '+${widget.step.inSeconds} s', onPressed: () => _adjust(widget.step)),
          ],
        ),
        const SizedBox(height: ClSpace.s3),
        ClProgressLine(value: progress),
        if (widget.onSkip != null)
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(label: 'Preskoči odmor', variant: ClButtonVariant.text, onPressed: widget.onSkip),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      ClButton(label: label, variant: ClButtonVariant.secondary, onPressed: onPressed);
}
