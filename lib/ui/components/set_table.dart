import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../theme.dart';
import '../tokens/spacing.dart';
import 'icons.dart';
import 'inputs.dart';
import 'pressable.dart';
import 'tag.dart';

enum ClSetState { pending, current, done }

class ClSetData {
  const ClSetData({
    this.previousKg,
    this.previousReps,
    this.hintKg,
    this.hintReps,
    this.kg = '',
    this.reps = '',
    this.rir = '',
    this.state = ClSetState.pending,
    this.isPr = false,
  });

  /// Last time's result, shown in the "Prethodno" column.
  final double? previousKg;
  final int? previousReps;

  /// Placeholder in empty inputs; defaults to last time's result.
  final double? hintKg;
  final int? hintReps;

  /// Raw input text as typed (may contain a decimal comma).
  final String kg;
  final String reps;
  final String rir;
  final ClSetState state;
  final bool isPr;

  bool get isDone => state == ClSetState.done;

  ClSetData copyWith({String? kg, String? reps, String? rir, ClSetState? state, bool? isPr}) => ClSetData(
    previousKg: previousKg,
    previousReps: previousReps,
    hintKg: hintKg,
    hintReps: hintReps,
    kg: kg ?? this.kg,
    reps: reps ?? this.reps,
    rir: rir ?? this.rir,
    state: state ?? this.state,
    isPr: isPr ?? this.isPr,
  );
}

const _colIndex = 28.0;
const _colCheck = ClSize.targetWorkout;
const _flexPrev = 30;
const _flexKg = 26;
const _flexReps = 20;
const _flexRir = 16;

/// Columns: # · previous · kg · reps · RIR · check. Each set is a rounded
/// 56px row: done = lime, current = ink outline. Confirming a set should start
/// the rest timer.
class ClSetTable extends StatelessWidget {
  const ClSetTable({
    super.key,
    required this.sets,
    required this.onChanged,
    required this.onToggleDone,
    this.showRir = true,
  });

  final List<ClSetData> sets;
  final void Function(int index, ClSetData data) onChanged;
  final void Function(int index) onToggleDone;
  final bool showRir;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    Widget head(String t, {int? flex, double? width, TextAlign align = TextAlign.center}) {
      final text = Text(t, style: cl.text.label, textAlign: align);
      return width != null ? SizedBox(width: width, child: text) : Expanded(flex: flex!, child: text);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 28,
          child: Row(
            children: [
              const SizedBox(width: ClSpace.s3),
              head('#', width: _colIndex, align: TextAlign.left),
              head('Prethodno', flex: _flexPrev, align: TextAlign.left),
              head('kg', flex: _flexKg),
              head('Pon.', flex: _flexReps),
              if (showRir) head('RIR', flex: _flexRir),
              const SizedBox(width: _colCheck + ClSpace.s1),
            ],
          ),
        ),
        for (var i = 0; i < sets.length; i++)
          ClSetRow(
            number: i + 1,
            data: sets[i],
            showRir: showRir,
            onChanged: (d) => onChanged(i, d),
            onToggleDone: () => onToggleDone(i),
          ),
      ],
    );
  }
}

class ClSetRow extends StatelessWidget {
  const ClSetRow({
    super.key,
    required this.number,
    required this.data,
    required this.onChanged,
    required this.onToggleDone,
    this.showRir = true,
  });

  final int number;
  final ClSetData data;
  final ValueChanged<ClSetData> onChanged;
  final VoidCallback onToggleDone;
  final bool showRir;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final done = data.isDone;
    final prev = data.previousKg != null && data.previousReps != null
        ? (data.previousKg! > 0
              ? formatSet(data.previousKg!, data.previousReps!)
              : '${data.previousReps} pon.')
        : '—';

    final current = data.state == ClSetState.current;
    final text = done ? c.onPop : null;

    Widget cell(int flex, Widget child) => Expanded(
      flex: flex,
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: child),
    );

    Widget value(String v, {bool pr = false}) => Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(v.isEmpty ? '—' : v, style: cl.text.data.copyWith(color: text)),
            if (pr) ...[const SizedBox(width: ClSpace.s1), const ClTag.pr(animateIn: true)],
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s2),
      child: AnimatedContainer(
        duration: context.motion(ClMotion.base),
        curve: ClMotion.curve,
        height: ClSize.targetWorkout + ClSpace.s1,
        padding: const EdgeInsets.only(left: ClSpace.s3, right: ClSpace.s1),
        decoration: BoxDecoration(
          color: done ? c.lime : c.surface,
          borderRadius: BorderRadius.circular(ClRadius.sm),
          boxShadow: done ? null : ClElevation.card(c.shadow),
          border: Border.all(
            color: done ? c.onPop : (current ? c.borderStrong : c.border),
            width: current || done ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: _colIndex,
              child: Text('$number', style: cl.text.data.copyWith(color: done ? c.onPop : c.inkMuted)),
            ),
            Expanded(
              flex: _flexPrev,
              child: Text(
                prev,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: cl.text.data.copyWith(
                  color: done ? c.onPop.withValues(alpha: 0.6) : c.inkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (done) ...[
              cell(_flexKg, value(data.kg, pr: data.isPr)),
              cell(_flexReps, value(data.reps)),
              if (showRir) cell(_flexRir, value(data.rir)),
            ] else ...[
              cell(
                _flexKg,
                ClNumberField(
                  value: data.kg,
                  decimal: true,
                  hint: (data.hintKg ?? data.previousKg) == null
                      ? null
                      : formatNumber(data.hintKg ?? data.previousKg!),
                  semanticLabel: 'Set $number, kilogrami',
                  onChanged: (v) => onChanged(data.copyWith(kg: v)),
                ),
              ),
              cell(
                _flexReps,
                ClNumberField(
                  value: data.reps,
                  hint: (data.hintReps ?? data.previousReps)?.toString(),
                  semanticLabel: 'Set $number, ponavljanja',
                  onChanged: (v) => onChanged(data.copyWith(reps: v)),
                ),
              ),
              if (showRir)
                cell(
                  _flexRir,
                  ClNumberField(
                    value: data.rir,
                    semanticLabel: 'Set $number, RIR',
                    textInputAction: TextInputAction.done,
                    onChanged: (v) => onChanged(data.copyWith(rir: v)),
                  ),
                ),
            ],
            SizedBox(
              width: _colCheck,
              child: ClSetCheck(
                done: done,
                semanticLabel: done ? 'Poništi set $number' : 'Završi set $number',
                onPressed: () {
                  if (!done) {
                    data.isPr ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
                  }
                  onToggleDone();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round set confirmation check. Done = lime fill with an ink check. Never color alone.
class ClSetCheck extends StatelessWidget {
  const ClSetCheck({super.key, required this.done, required this.onPressed, this.semanticLabel});

  final bool done;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      radius: ClRadius.full,
      selected: done,
      builder: (context, pressed) => SizedBox.square(
        dimension: ClSize.targetWorkout,
        child: Center(
          child: AnimatedContainer(
            duration: context.motion(ClMotion.fast),
            curve: ClMotion.curve,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: done ? c.lime : (pressed ? c.surfaceRaised : Colors.transparent),
              shape: BoxShape.circle,
              border: Border.all(color: done ? c.onPop : c.borderStrong, width: 1.5),
            ),
            child: AnimatedScale(
              duration: context.motion(ClMotion.fast),
              curve: ClMotion.curve,
              scale: done ? 1 : 0.6,
              child: AnimatedOpacity(
                duration: context.motion(ClMotion.fast),
                opacity: done ? 1 : 0,
                child: Icon(ClIcons.check, size: 20, color: c.onPop),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
