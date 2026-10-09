import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'summary_screen.dart';
import 'swap_sheet.dart';

/// Set-by-set workout, made for one thumb between sets: the current set is
/// big with − and + for weight and reps (last time's numbers already in), the
/// other sets are thin lines, and what matters right now (what to fill in,
/// the rest clock) sits right above the one button.
class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  int? _exercise;
  bool _resting = false;
  int _restRun = 0;
  String? _notice;

  /// The set the rest belongs to, for "Kako je bilo?".
  int? _restedSet;

  AppStore get _store => context.readStore;

  int _firstOpenExercise(Session s) {
    final i = s.exercises.indexWhere((e) => !e.isComplete);
    return i < 0 ? s.exercises.length - 1 : i;
  }

  /// What a set shows before the user touches it: their own number, else
  /// the weight they just used on the set before (a change carries on),
  /// else last time / the suggestion, else the prescription.
  ({double? kg, int reps}) _valuesOf(SessionExercise e, int setIndex) {
    final s = e.sets[setIndex];
    final ref = _store.suggestedSet(e, setIndex);
    final before = setIndex > 0 ? _valuesOf(e, setIndex - 1).kg : null;
    // Only a weight the user changed carries on; otherwise each set keeps
    // its own number from last time (a pyramid stays a pyramid).
    final changedBefore =
        setIndex > 0 && before != null && before != _store.suggestedSet(e, setIndex - 1)?.kg;
    return (
      kg: s.kg ?? (changedBefore ? before : null) ?? ref?.kg ?? before ?? (e.bodyweight ? 0 : null),
      reps: s.reps ?? ref?.reps ?? e.repsMin,
    );
  }

  void _toggle(int setIndex) {
    final i = _exercise!;
    // Save exactly what the screen shows, so nothing else gets logged.
    final set = _store.active!.exercises[i].sets[setIndex];
    if (!set.done) {
      final v = _valuesOf(_store.active!.exercises[i], setIndex);
      if (set.kg == null && v.kg != null || set.reps == null) {
        _store.updateSet(i, setIndex, set.copyWith(kg: set.kg ?? v.kg, reps: set.reps ?? v.reps));
      }
    }
    final result = _store.toggleSet(i, setIndex);
    setState(() {
      _notice = switch (result) {
        ConfirmSetResult.needsWeight => 'Upiši težinu za set ${setIndex + 1}.',
        ConfirmSetResult.needsReps => 'Upiši broj ponavljanja za set ${setIndex + 1}.',
        _ => null,
      };
      if (result == ConfirmSetResult.done) {
        _resting = true;
        _restRun++;
        _restedSet = setIndex;
        final pr = _store.active!.exercises[i].sets[setIndex].isPr;
        pr ? HapticFeedback.mediumImpact() : HapticFeedback.lightImpact();
      }
    });
  }

  void _setKg(int setIndex, double kg) {
    final e = _store.active!.exercises[_exercise!];
    _store.updateSet(_exercise!, setIndex, e.sets[setIndex].copyWith(kg: kg < 0 ? 0 : kg));
    HapticFeedback.selectionClick();
    if (_notice != null) setState(() => _notice = null);
  }

  void _setReps(int setIndex, int reps) {
    final e = _store.active!.exercises[_exercise!];
    _store.updateSet(_exercise!, setIndex, e.sets[setIndex].copyWith(reps: reps < 1 ? 1 : reps));
    HapticFeedback.selectionClick();
    if (_notice != null) setState(() => _notice = null);
  }

  /// "Kako je bilo?" stored as reps in reserve.
  void _setFeel(int rir) {
    final i = _exercise!, j = _restedSet;
    if (j == null) return;
    final set = _store.active!.exercises[i].sets[j];
    _store.updateSet(i, j, set.copyWith(rir: rir));
    HapticFeedback.selectionClick();
  }

  /// Typing a number, for when − and + are too far off (first time, a jump).
  Future<void> _typeValue(int setIndex, {required bool kg}) async {
    final e = _store.active!.exercises[_exercise!];
    final v = _valuesOf(e, setIndex);
    final result = await showClSheet<String>(
      context,
      title: kg ? 'Težina' : 'Ponavljanja',
      label: 'Set ${setIndex + 1} · ${e.name}',
      builder: (context) => _NumberSheet(
        label: kg ? 'kg' : 'ponavljanja',
        initial: kg ? (v.kg == null ? '' : formatNumber(v.kg!)) : '${v.reps}',
      ),
    );
    if (result == null || !mounted) return;
    if (kg) {
      final value = parseDecimal(result);
      if (value != null) _setKg(setIndex, value);
    } else {
      final value = int.tryParse(result.trim());
      if (value != null) _setReps(setIndex, value);
    }
  }

  void _goTo(int index) => setState(() {
    _exercise = index;
    _resting = false;
    _notice = null;
  });

  Future<void> _showExercises() async {
    final session = _store.active!;
    final picked = await showClSheet<int>(
      context,
      title: session.workoutName,
      label: '${session.doneSets} / ${session.exercises.fold(0, (n, x) => n + x.sets.length)} setova',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (j, x) in session.exercises.indexed)
            ClExerciseRow(
              index: j + 1,
              image: photoOf(_store.resolveExercise(x.exerciseId)?.image),
              name: x.name,
              detail: '${x.doneSets.length} / ${x.sets.length} · ${x.target}',
              isPr: x.hasPr,
              onPressed: () => Navigator.of(context).pop(j),
            ),
        ],
      ),
    );
    if (picked != null && mounted) _goTo(picked);
  }

  /// The picture big, with the trainer's whole cue.
  Future<void> _showHowTo(SessionExercise e, ImageProvider? picture, Creator? author) {
    final cl = context.cl;
    return showClSheet<void>(
      context,
      title: e.name,
      label: '${e.muscle.label} · ${e.target}',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (picture != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(ClRadius.lg),
              child: AspectRatio(
                aspectRatio: 3 / 2,
                child: ClPhoto(image: picture, placeholderLabel: '', semanticLabel: e.name),
              ),
            ),
          if (e.note.isNotEmpty) ...[
            gapS,
            ClCreatorLine(name: author?.name ?? e.noteBy ?? '', image: photoOf(author?.photo)),
            const SizedBox(height: ClSpace.s2),
            Text(e.note, style: cl.text.body),
          ],
        ],
      ),
    );
  }

  Future<void> _finish() async {
    final s = _store.active!;
    final open = s.exercises.fold(0, (n, e) => n + e.sets.where((x) => !x.done).length);
    if (s.doneSets == 0) {
      setState(() => _notice = 'Završi bar jedan set da bi sačuvao trening.');
      return;
    }
    if (open > 0) {
      final ok = await confirmClSheet(
        context,
        title: 'Završi trening?',
        message:
            '${countLabel(open, 'set nije završen', 'seta nisu završena', 'setova nije završeno')}. '
            'Čuvamo samo ono što si uradio.',
        confirmLabel: 'Završi trening',
      );
      if (!ok || !mounted) return;
    }
    HapticFeedback.mediumImpact();
    final done = _store.finishSession();
    pushScreen(
      context,
      SummaryScreen(sessionId: done.id, justFinished: true),
      theme: ClTheme.light,
      replace: true,
    );
  }

  Future<void> _swap() async {
    final e = _store.active!.exercises[_exercise!];
    final exercise = _store.exercisesById[e.exerciseId];
    if (exercise == null) return;
    final id = await showSwapSheet(context, exercise);
    if (id == null || !mounted) return;
    _store.swapSessionExercise(_exercise!, id);
    setState(() {
      _resting = false;
      _notice = null;
    });
  }

  Future<void> _menu() async {
    final i = _exercise!;
    final sets = _store.active!.exercises[i].sets;
    final canRemove = sets.length > 1 && !sets.last.done;
    final action = await showClSheet<String>(
      context,
      title: 'Trening',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClButton(
            label: 'Dodaj set',
            variant: ClButtonVariant.secondary,
            icon: ClIcons.add,
            expand: true,
            onPressed: () => Navigator.of(context).pop('add'),
          ),
          if (canRemove) ...[
            const SizedBox(height: ClSpace.s3),
            ClButton(
              label: 'Ukloni poslednji set',
              variant: ClButtonVariant.secondary,
              icon: ClIcons.remove,
              expand: true,
              onPressed: () => Navigator.of(context).pop('remove'),
            ),
          ],
          const SizedBox(height: ClSpace.s3),
          ClButton(
            label: 'Zameni vežbu',
            variant: ClButtonVariant.secondary,
            icon: ClIcons.swap,
            expand: true,
            onPressed: () => Navigator.of(context).pop('swap'),
          ),
          const SizedBox(height: ClSpace.s3),
          ClButton(
            label: 'Završi trening',
            variant: ClButtonVariant.secondary,
            icon: ClIcons.check,
            expand: true,
            onPressed: () => Navigator.of(context).pop('finish'),
          ),
          const SizedBox(height: ClSpace.s3),
          ClButton(
            label: 'Prekini trening',
            variant: ClButtonVariant.danger,
            expand: true,
            onPressed: () => Navigator.of(context).pop('discard'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'add') return _store.addSet(i);
    if (action == 'remove') return _store.removeSet(i, sets.length - 1);
    if (action == 'swap') return _swap();
    if (action == 'finish') return _finish();
    if (action == 'discard') {
      final ok = await confirmClSheet(
        context,
        title: 'Prekini trening?',
        message: 'Setovi iz ovog treninga se neće sačuvati. Plan ostaje na istom treningu.',
        confirmLabel: 'Prekini',
        danger: true,
      );
      if (!ok || !mounted) return;
      _store.discardSession();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final session = store.active;
    if (session == null || session.exercises.isEmpty) {
      return AppScreen(
        topBar: const ClTopBar(),
        children: const [
          ClEmptyState(title: 'Nema treninga.', message: 'Ovaj trening je završen ili prekinut.'),
        ],
      );
    }
    final i = (_exercise ??= _firstOpenExercise(session)).clamp(0, session.exercises.length - 1);
    final e = session.exercises[i];
    final prev = previousSets(store.sessions, e.exerciseId);
    final current = e.sets.indexWhere((s) => !s.done);
    final isLast = i == session.exercises.length - 1;
    final cl = context.cl;
    final c = cl.colors;
    final picture = photoOf(store.resolveExercise(e.exerciseId)?.image);
    // The cue's author, found by name: the exercise may come from another creator.
    final author = store.creators.where((x) => x.name == (e.noteBy ?? session.creatorName)).firstOrNull;
    final next = isLast ? null : session.exercises[i + 1];

    final Widget action;
    if (current >= 0) {
      action = ClButton.block(label: 'Završi set', onPressed: () => _toggle(current));
    } else if (next != null) {
      action = ClButton.block(label: 'Sledeća vežba', onPressed: () => _goTo(i + 1));
    } else {
      action = ClButton.block(label: 'Završi trening', onPressed: _finish);
    }

    final restedRir = _restedSet != null && _restedSet! < e.sets.length ? e.sets[_restedSet!].rir : null;

    return AppScreen(
      topBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s1),
        child: Row(
          children: [
            ClIconButton(
              icon: ClIcons.close,
              semanticLabel: 'Zatvori, trening se nastavlja',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: _ExerciseProgress(session: session, current: i, onPressed: _showExercises),
            ),
            ClIconButton(icon: ClIcons.more, semanticLabel: 'Opcije treninga', onPressed: _menu),
          ],
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_notice != null) ...[ClNotice(_notice!, danger: true), const SizedBox(height: ClSpace.s2)],
          if (_resting) ...[
            _RestBar(
              key: ValueKey(_restRun),
              duration: Duration(seconds: e.restSeconds),
              rir: restedRir,
              onFeel: _setFeel,
              onSkip: () => setState(() => _resting = false),
            ),
            const SizedBox(height: ClSpace.s2),
          ],
          action,
        ],
      ),
      children: [
        const SizedBox(height: ClSpace.s2),
        // The exercise: a small picture (tap for the big one and the whole
        // cue), the name and what to do.
        ClPressable(
          onPressed: () => _showHowTo(e, picture, author),
          semanticLabel: '${e.name}, kako se radi',
          radius: ClRadius.sm,
          builder: (context, pressed) => Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(ClRadius.sm - 6),
                child: SizedBox.square(
                  dimension: 64,
                  child: picture == null
                      ? ColoredBox(
                          color: c.popFor(e.exerciseId),
                          child: Icon(ClIcons.barbell, color: c.onPop),
                        )
                      : ClPhoto(image: picture, placeholderLabel: ''),
                ),
              ),
              const SizedBox(width: ClSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: cl.text.displayM),
                    const SizedBox(height: 2),
                    Text(
                      [
                        current < 0
                            ? 'Gotovo · ${countLabel(e.sets.length, 'set', 'seta', 'setova')}'
                            : e.target,
                        'odmor ${formatClock(Duration(seconds: e.restSeconds))}',
                      ].join(' · '),
                      style: cl.text.body.copyWith(color: c.inkMuted, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (e.swappedFrom != null) ...[
          const SizedBox(height: ClSpace.s2),
          ClNotice('Zamena za ${e.swappedFrom}'),
        ],
        if (e.note.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s3),
          Row(
            children: [
              ClAvatar(name: author?.name ?? e.noteBy ?? '', image: photoOf(author?.photo), size: 24),
              const SizedBox(width: ClSpace.s2),
              Expanded(
                child: Text(
                  e.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cl.text.body.copyWith(color: c.inkMuted, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
        gap,
        if (current >= 0)
          _FocusSet(
            number: current + 1,
            total: e.sets.length,
            previous: prev.isEmpty ? null : setLabel(prev[current.clamp(0, prev.length - 1)]),
            kg: _valuesOf(e, current).kg,
            reps: _valuesOf(e, current).reps,
            bodyweight: e.bodyweight,
            onKg: (v) => _setKg(current, v),
            onReps: (v) => _setReps(current, v),
            onTypeKg: () => _typeValue(current, kg: true),
            onTypeReps: () => _typeValue(current, kg: false),
          ),
        const SizedBox(height: ClSpace.s3),
        for (final (j, s) in e.sets.indexed)
          if (j != current)
            _SetLine(
              number: j + 1,
              label: s.done
                  ? setLabel(s)
                  : () {
                      final v = _valuesOf(e, j);
                      return v.kg == null || e.bodyweight
                          ? '${v.reps} pon.'
                          : '${formatNumber(v.kg!)} kg × ${v.reps}';
                    }(),
              done: s.done,
              isPr: s.isPr,
              // A done set opens again with a tap, to fix a number.
              onPressed: s.done ? () => _toggle(j) : null,
            ),
        if (current < 0 && next != null) ...[
          gap,
          Text('Sledeće', style: cl.text.label),
          const SizedBox(height: ClSpace.s2),
          ClExerciseRow(
            image: photoOf(store.resolveExercise(next.exerciseId)?.image),
            index: i + 2,
            name: next.name,
            detail: next.target,
            onPressed: () => _goTo(i + 1),
          ),
        ],
      ],
    );
  }
}

/// Typing one number; owns its field so it outlives the sheet's close.
class _NumberSheet extends StatefulWidget {
  const _NumberSheet({required this.label, required this.initial});

  final String label;
  final String initial;

  @override
  State<_NumberSheet> createState() => _NumberSheetState();
}

class _NumberSheetState extends State<_NumberSheet> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClTextField(
        label: widget.label,
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      gapS,
      ClButton(label: 'Sačuvaj', expand: true, onPressed: () => Navigator.of(context).pop(_controller.text)),
    ],
  );
}

/// One segment per exercise: done, current, still to do. Tap for the list.
class _ExerciseProgress extends StatelessWidget {
  const _ExerciseProgress({required this.session, required this.current, required this.onPressed});

  final Session session;
  final int current;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: 'Vežba ${current + 1} od ${session.exercises.length}, sve vežbe',
      radius: ClRadius.sm,
      builder: (context, pressed) => SizedBox(
        height: ClSize.target,
        child: Row(
          children: [
            for (final (j, x) in session.exercises.indexed) ...[
              if (j > 0) const SizedBox(width: 4),
              Expanded(
                child: AnimatedContainer(
                  duration: context.motion(ClMotion.base),
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: x.isComplete
                        ? c.ink
                        : j == current
                        ? c.inkMuted
                        : c.border,
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

/// The set being done: big numbers with − and + in thumb reach. Tapping a
/// number lets the user type it instead.
class _FocusSet extends StatelessWidget {
  const _FocusSet({
    required this.number,
    required this.total,
    required this.previous,
    required this.kg,
    required this.reps,
    required this.bodyweight,
    required this.onKg,
    required this.onReps,
    required this.onTypeKg,
    required this.onTypeReps,
  });

  final int number;
  final int total;
  final String? previous;
  final double? kg;
  final int reps;
  final bool bodyweight;
  final ValueChanged<double> onKg;
  final ValueChanged<int> onReps;
  final VoidCallback onTypeKg;
  final VoidCallback onTypeReps;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s3, ClSpace.s4, ClSpace.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(ClRadius.lg),
        border: Border.all(color: c.ink, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Set $number od $total', style: cl.text.bodyStrong)),
              if (previous != null) Text('Prošli put $previous', style: cl.text.label),
            ],
          ),
          if (!bodyweight) ...[
            const SizedBox(height: ClSpace.s3),
            _Stepper(
              value: kg == null ? null : formatNumber(kg!),
              unit: 'kg',
              empty: 'Upiši kg',
              onMinus: kg == null ? null : () => onKg(kg! - 2.5),
              onPlus: () => onKg((kg ?? 0) + 2.5),
              onType: onTypeKg,
            ),
          ],
          const SizedBox(height: ClSpace.s3),
          _Stepper(
            value: '$reps',
            unit: 'ponavljanja',
            onMinus: reps > 1 ? () => onReps(reps - 1) : null,
            onPlus: () => onReps(reps + 1),
            onType: onTypeReps,
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.unit,
    required this.onPlus,
    required this.onType,
    this.onMinus,
    this.empty,
  });

  final String? value;
  final String unit;
  final String? empty;
  final VoidCallback? onMinus;
  final VoidCallback onPlus;
  final VoidCallback onType;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    Widget round(IconData icon, String label, VoidCallback? onPressed) => ClPressable(
      onPressed: onPressed,
      semanticLabel: '$label $unit',
      radius: ClRadius.full,
      builder: (context, pressed) => AnimatedScale(
        duration: context.motion(ClMotion.fast),
        scale: pressed ? 0.9 : 1,
        child: Container(
          width: ClSize.targetWorkout,
          height: ClSize.targetWorkout,
          decoration: BoxDecoration(color: c.surfaceRaised, shape: BoxShape.circle),
          child: Icon(icon, color: onPressed == null ? c.inkMuted : c.ink),
        ),
      ),
    );
    return Row(
      children: [
        round(ClIcons.remove, 'Manje', onMinus),
        Expanded(
          child: ClPressable(
            onPressed: onType,
            semanticLabel: value == null ? (empty ?? unit) : '$value $unit, upiši',
            radius: ClRadius.sm,
            builder: (context, pressed) => Column(
              children: [
                Text(
                  value ?? (empty ?? '—'),
                  style: value == null
                      ? cl.text.bodyStrong.copyWith(fontSize: 18)
                      : cl.text.metricL.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
                Text(unit, style: cl.text.label),
              ],
            ),
          ),
        ),
        round(ClIcons.add, 'Više', onPlus),
      ],
    );
  }
}

/// A set that is not the current one: thin, done ones with a check.
class _SetLine extends StatelessWidget {
  const _SetLine({
    required this.number,
    required this.label,
    required this.done,
    required this.isPr,
    this.onPressed,
  });

  final int number;
  final String label;
  final bool done;
  final bool isPr;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: 'Set $number, $label${done ? ', urađen' : ''}',
      radius: ClRadius.xs,
      builder: (context, pressed) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2, vertical: ClSpace.s2),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('$number', style: cl.text.data.copyWith(color: done ? c.ink : c.inkMuted)),
            ),
            Expanded(
              child: Text(label, style: cl.text.data.copyWith(color: done ? c.ink : c.inkMuted)),
            ),
            if (isPr) ...[const ClTag.pr(), const SizedBox(width: ClSpace.s2)],
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? c.ink : null,
                border: Border.all(color: done ? c.ink : c.border, width: 1.5),
              ),
              child: done ? Icon(ClIcons.check, size: 13, color: c.bg) : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rest between sets, right above the button: the clock, a line that runs
/// out, +15 s and skip. Also one optional question instead of a RIR column.
class _RestBar extends StatefulWidget {
  const _RestBar({super.key, required this.duration, required this.onSkip, required this.onFeel, this.rir});

  final Duration duration;
  final VoidCallback onSkip;
  final ValueChanged<int> onFeel;

  /// The answer already given for this set, as reps in reserve.
  final int? rir;

  @override
  State<_RestBar> createState() => _RestBarState();
}

class _RestBarState extends State<_RestBar> {
  late DateTime _end = DateTime.now().add(widget.duration);
  late Duration _total = widget.duration;
  Timer? _timer;
  bool _buzzed = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      final left = _end.difference(DateTime.now());
      if (left <= Duration.zero && !_buzzed) {
        _buzzed = true;
        HapticFeedback.heavyImpact();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _add() => setState(() {
    _end = _end.add(const Duration(seconds: 15));
    _total += const Duration(seconds: 15);
    _buzzed = false;
  });

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final left = _end.difference(DateTime.now());
    final over = left <= Duration.zero;
    final shown = over ? Duration.zero : left + const Duration(milliseconds: 999);
    final progress = _total.inMilliseconds == 0
        ? 1.0
        : 1 - (left.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
    final muted = c.bg.withValues(alpha: 0.7);
    Widget feel(String label, int rir) {
      final on = widget.rir == rir;
      return ClPressable(
        onPressed: () => widget.onFeel(rir),
        selected: on,
        semanticLabel: label,
        radius: ClRadius.full,
        builder: (context, pressed) => Container(
          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3, vertical: 6),
          decoration: BoxDecoration(
            color: on ? c.bg : null,
            borderRadius: BorderRadius.circular(ClRadius.full),
            border: Border.all(color: on ? c.bg : muted),
          ),
          alignment: Alignment.center,
          child: Text(label, style: cl.text.label.copyWith(color: on ? c.ink : c.bg)),
        ),
      );
    }

    Widget action(String label, VoidCallback onPressed) => ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      radius: ClRadius.full,
      builder: (context, pressed) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2, vertical: ClSpace.s3),
        child: Text(label, style: cl.text.bodyStrong.copyWith(color: pressed ? muted : c.bg)),
      ),
    );

    return Semantics(
      liveRegion: over,
      child: Container(
        padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s3, ClSpace.s3, ClSpace.s3),
        decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(ClRadius.sm)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(over ? 'Spreman si' : 'Odmor', style: cl.text.label.copyWith(color: muted)),
                    Text(
                      formatClock(shown),
                      style: cl.text.metric.copyWith(
                        color: c.bg,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                // Shrinks rather than overflows on narrow phones or large text.
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(children: [action('+15 s', _add), action('Preskoči', widget.onSkip)]),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: ClSpace.s2),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: c.bg,
                backgroundColor: c.bg.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: ClSpace.s3),
            Text('Kako je bilo?', style: cl.text.label.copyWith(color: muted)),
            const SizedBox(height: ClSpace.s2),
            Row(
              children: [
                Expanded(child: feel('Lako', 3)),
                const SizedBox(width: 6),
                Expanded(child: feel('Taman', 2)),
                const SizedBox(width: 6),
                Expanded(child: feel('Teško', 0)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
