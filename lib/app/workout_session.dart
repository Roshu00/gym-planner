import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'exercise_media.dart';
import 'summary_screen.dart';
import 'swap_sheet.dart';

/// The workout, one step at a time, full screen:
/// - a set: the exercise moving at the top, the numbers to do below (last
///   time's already in, − and + in thumb reach) and one button;
/// - rest: a dark screen with the clock, one question about the set just
///   done and what comes next; it moves on by itself when time is up;
/// - the end: the question for the last set and "Završi trening".
/// Everything else (the list, swaps, extra sets) waits behind "⋯".
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

  /// What the progression set for today, in the trainer's words.
  String? _progressHint(SessionExercise e) {
    final p = _store.progressionFor(e);
    if (p == null) return null;
    final kg = p.sets.first.kg;
    return switch (p.kind) {
      ProgressionKind.heavier when kg != null =>
        p.wasEasy
            ? 'Prošli put je bilo lako. Danas ${formatNumber(kg)} kg.'
            : 'Prošli put gornja granica ponavljanja. Danas ${formatNumber(kg)} kg.',
      ProgressionKind.moreReps when e.timed => 'Pet sekundi duže nego prošli put.',
      ProgressionKind.moreReps when e.bodyweight => 'Jedno ponavljanje više nego prošli put.',
      ProgressionKind.moreReps => 'Ista težina, jedno ponavljanje više nego prošli put.',
      ProgressionKind.same => 'Prošli put je bilo teško. Danas isti brojevi, čistije.',
      _ => null,
    };
  }

  /// Typing a number, for when − and + are too far off (first time, a jump).
  Future<void> _typeValue(int setIndex, {required bool kg}) async {
    final e = _store.active!.exercises[_exercise!];
    final v = _valuesOf(e, setIndex);
    final result = await showClSheet<String>(
      context,
      title: kg ? 'Težina' : (e.timed ? 'Sekunde' : 'Ponavljanja'),
      label: 'Set ${setIndex + 1} · ${e.name}',
      builder: (context) => _NumberSheet(
        label: kg ? 'kg' : (e.timed ? 'sekundi' : 'ponavljanja'),
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
  Future<void> _showHowTo(SessionExercise e, Exercise? exercise, Creator? author) {
    final cl = context.cl;
    return showClSheet<void>(
      context,
      title: e.name,
      label: '${e.muscle.label} · ${e.target}',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The clip of how it is done, or its pictures taking turns.
          if (exercise != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(ClRadius.lg),
              child: SizedBox(height: 320, child: ExerciseMedia(exercise: exercise)),
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
      setState(
        () => _notice =
            'Završi bar jedan set da bi ${_store.profile?.says('sačuvao', 'sačuvala') ?? 'sačuvao'} trening.',
      );
      return;
    }
    if (open > 0) {
      final ok = await confirmClSheet(
        context,
        title: 'Završi trening?',
        message:
            '${countLabel(open, 'set nije završen', 'seta nisu završena', 'setova nije završeno')}. '
            'Čuvamo samo ono što si ${_store.profile?.says('uradio', 'uradila') ?? 'uradio'}.',
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
          ClMenuGroup(
            children: [
              ClMenuRow(
                icon: ClIcons.plan,
                title: 'Sve vežbe',
                onPressed: () => Navigator.of(context).pop('list'),
              ),
              ClMenuRow(
                icon: ClIcons.swap,
                title: 'Zameni vežbu',
                onPressed: () => Navigator.of(context).pop('swap'),
              ),
              ClMenuRow(
                icon: ClIcons.add,
                title: 'Dodaj set',
                onPressed: () => Navigator.of(context).pop('add'),
              ),
              if (canRemove)
                ClMenuRow(
                  icon: ClIcons.remove,
                  title: 'Ukloni poslednji set',
                  onPressed: () => Navigator.of(context).pop('remove'),
                ),
              ClMenuRow(
                icon: ClIcons.check,
                title: 'Završi trening',
                onPressed: () => Navigator.of(context).pop('finish'),
              ),
            ],
          ),
          gapS,
          ClButton(
            label: 'Prekini trening',
            variant: ClButtonVariant.text,
            onPressed: () => Navigator.of(context).pop('discard'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'list') return _showExercises();
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

  /// Rest is over (by time or by "Kreni"): the next set, or the next
  /// exercise when this one is done.
  void _endRest() {
    if (!mounted || !_resting) return;
    final session = _store.active;
    if (session == null) return;
    final i = _exercise!;
    setState(() {
      _resting = false;
      if (session.exercises[i].isComplete && i < session.exercises.length - 1) _exercise = i + 1;
    });
  }

  /// A held set ended: what was held is the set.
  void _held(int setIndex, int seconds) {
    _setReps(setIndex, seconds);
    _toggle(setIndex);
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
    final allDone = session.exercises.every((x) => x.isComplete);

    final Widget phase;
    if (_resting || allDone) {
      phase = _restPhase(session, i, allDone);
    } else {
      phase = _setPhase(session, i, e);
    }
    return AnimatedSwitcher(
      duration: context.motion(const Duration(milliseconds: 280)),
      switchInCurve: ClMotion.curve,
      child: KeyedSubtree(key: ValueKey('${_resting || allDone}-$i'), child: phase),
    );
  }

  /// The set to do: the exercise big, the numbers, one button.
  Widget _setPhase(Session session, int i, SessionExercise e) {
    final store = context.store;
    final cl = context.cl;
    final c = cl.colors;
    final exercise = store.resolveExercise(e.exerciseId);
    final author = store.creators.where((x) => x.name == (e.noteBy ?? session.creatorName)).firstOrNull;
    final current = e.sets.indexWhere((s) => !s.done);
    final prev = previousSets(store.sessions, e.exerciseId);
    final isLast = i == session.exercises.length - 1;

    final Widget numbers;
    final Widget action;
    if (current < 0) {
      // Opened from the list after it was done.
      numbers = Padding(
        padding: const EdgeInsets.symmetric(vertical: ClSpace.s4),
        child: Text(
          'Gotovo · ${countLabel(e.sets.length, 'set', 'seta', 'setova')}',
          style: cl.text.bodyStrong,
        ),
      );
      action = isLast
          ? ClButton.block(label: 'Završi trening', onPressed: _finish)
          : ClButton.block(label: 'Sledeća vežba', onPressed: () => _goTo(i + 1));
    } else {
      final v = _valuesOf(e, current);
      final steps = store.weightStepsFor(e);
      numbers = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!e.bodyweight) ...[
            _Stepper(
              value: v.kg == null ? null : formatNumber(v.kg!),
              unit: 'kg',
              empty: 'Upiši kg',
              onMinus: v.kg == null ? null : () => _setKg(current, v.kg! - steps.step),
              onPlus: () => _setKg(current, v.kg == null ? steps.start : v.kg! + steps.step),
              onType: () => _typeValue(current, kg: true),
            ),
            const SizedBox(height: ClSpace.s2),
          ],
          if (e.timed)
            _Stepper(
              value: formatSeconds(v.reps),
              unit: 'drži',
              onMinus: v.reps > 5 ? () => _setReps(current, v.reps - 5) : null,
              onPlus: () => _setReps(current, v.reps + 5),
              onType: () => _typeValue(current, kg: false),
            )
          else
            _Stepper(
              value: '${v.reps}',
              unit: 'ponavljanja',
              onMinus: v.reps > 1 ? () => _setReps(current, v.reps - 1) : null,
              onPlus: () => _setReps(current, v.reps + 1),
              onType: () => _typeValue(current, kg: false),
            ),
        ],
      );
      action = e.timed
          ? _HoldButton(key: ValueKey('hold-$i-$current'), seconds: v.reps, onDone: (s) => _held(current, s))
          : ClButton.block(label: 'Završi set', onPressed: () => _toggle(current));
    }

    final hint = current < 0 ? null : _progressHint(e);
    final last = current < 0 || prev.isEmpty
        ? null
        : setLabel(prev[current.clamp(0, prev.length - 1)], timed: e.timed);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.bg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The exercise, moving, edge to edge. Tap for the whole cue.
            Expanded(
              child: GestureDetector(
                onTap: () => _showHowTo(e, exercise, author),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (exercise != null)
                      ExerciseMedia(exercise: exercise)
                    else
                      ColoredBox(color: c.popFor(e.exerciseId)),
                    const ClPhotoScrim(coverage: 0.55),
                    // Keeps the top controls readable on bright pictures.
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 140,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x73000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: ClSpace.s2),
                          child: Row(
                            children: [
                              ClIconButton.onMedia(
                                icon: ClIcons.close,
                                semanticLabel: 'Zatvori, trening se nastavlja',
                                onPressed: () => Navigator.of(context).maybePop(),
                              ),
                              Expanded(
                                child: _ExerciseProgress(
                                  session: session,
                                  current: i,
                                  onPressed: _showExercises,
                                ),
                              ),
                              ClIconButton.onMedia(
                                icon: ClIcons.more,
                                semanticLabel: 'Opcije treninga',
                                onPressed: _menu,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: ClSpace.s4,
                      right: ClSpace.s4,
                      bottom: ClSpace.s6 + ClSpace.s2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              'Vežba ${i + 1} od ${session.exercises.length}',
                              if (e.swappedFrom != null) 'zamena za ${e.swappedFrom}',
                            ].join(' · '),
                            style: cl.text.label.copyWith(color: c.onPhoto),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            e.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: cl.text.displayL.copyWith(color: c.onPhoto, fontSize: 36, height: 1.02),
                          ),
                          if (e.note.isNotEmpty) ...[
                            const SizedBox(height: ClSpace.s2),
                            Row(
                              children: [
                                ClAvatar(
                                  name: author?.name ?? e.noteBy ?? '',
                                  image: photoOf(author?.photo),
                                  size: 22,
                                ),
                                const SizedBox(width: ClSpace.s2),
                                Expanded(
                                  child: Text(
                                    e.note,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: cl.text.body.copyWith(color: c.onPhoto, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // The set: which one, the numbers, the button. Nothing else.
            Transform.translate(
              offset: const Offset(0, -ClSpace.s4),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  ClSpace.s4,
                  ClSpace.s4,
                  ClSpace.s4,
                  // The panel is lifted by s4 over the picture; the gap below is bg.
                  math.max(MediaQuery.paddingOf(context).bottom - ClSpace.s4, ClSpace.s2),
                ),
                decoration: BoxDecoration(
                  color: c.bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(ClRadius.lg)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            current < 0 ? e.target : 'Set ${current + 1} od ${e.sets.length}',
                            style: cl.text.bodyStrong.copyWith(fontSize: 17),
                          ),
                        ),
                        _SetDots(sets: e.sets, current: current, onReopen: (j) => _toggle(j)),
                      ],
                    ),
                    if (hint != null || last != null) ...[
                      const SizedBox(height: 2),
                      Text(hint ?? 'Prošli put $last', style: cl.text.label),
                    ],
                    const SizedBox(height: ClSpace.s3),
                    numbers,
                    if (_notice != null) ...[
                      const SizedBox(height: ClSpace.s2),
                      ClNotice(_notice!, danger: true),
                    ],
                    const SizedBox(height: ClSpace.s4),
                    action,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rest: the clock, how the set felt, what comes next. Or the end.
  Widget _restPhase(Session session, int i, bool allDone) {
    final store = context.store;
    final e = session.exercises[i];
    final rested = _restedSet != null && _restedSet! < e.sets.length ? e.sets[_restedSet!] : null;
    final nextSet = e.sets.indexWhere((s) => !s.done);
    final nextExercise = !allDone && nextSet < 0 && i + 1 < session.exercises.length
        ? session.exercises[i + 1]
        : null;
    final String? upNext;
    final String? upNextDetail;
    final ImageProvider? upNextImage;
    if (allDone) {
      upNext = null;
      upNextDetail = null;
      upNextImage = null;
    } else if (nextExercise != null) {
      upNext = nextExercise.name;
      upNextDetail = 'Sledeća vežba · ${nextExercise.target}';
      upNextImage = photoOf(store.resolveExercise(nextExercise.exerciseId)?.image);
    } else {
      final v = _valuesOf(e, nextSet);
      upNext = 'Set ${nextSet + 1} od ${e.sets.length}';
      upNextDetail = e.timed
          ? formatSeconds(v.reps)
          : v.kg == null || e.bodyweight
          ? '${v.reps} pon.'
          : '${formatNumber(v.kg!)} kg × ${v.reps}';
      upNextImage = photoOf(store.resolveExercise(e.exerciseId)?.image);
    }
    return _RestScreen(
      key: ValueKey('rest-$_restRun'),
      duration: allDone ? null : Duration(seconds: e.restSeconds),
      done: rested == null ? null : '${e.name} · ${setLabel(rested, timed: e.timed)}',
      isPr: rested?.isPr ?? false,
      rir: rested?.rir,
      onFeel: _setFeel,
      upNext: upNext,
      upNextDetail: upNextDetail,
      upNextImage: upNextImage,
      onClose: () => Navigator.of(context).maybePop(),
      onMenu: _menu,
      onGo: allDone ? _finish : _endRest,
      onTimeUp: _endRest,
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

/// One segment per exercise: done, current, still to do. Tap for the list.
class _ExerciseProgress extends StatelessWidget {
  const _ExerciseProgress({required this.session, required this.current, required this.onPressed});

  final Session session;
  final int current;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
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
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: x.isComplete || j == current ? white : white.withValues(alpha: 0.35),
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

/// The sets of this exercise as dots: done (tap to fix), now, to come.
class _SetDots extends StatelessWidget {
  const _SetDots({required this.sets, required this.current, required this.onReopen});

  final List<SetLog> sets;
  final int current;
  final ValueChanged<int> onReopen;

  @override
  Widget build(BuildContext context) {
    final c = context.clColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (j, s) in sets.indexed)
          ClPressable(
            onPressed: s.done ? () => onReopen(j) : null,
            semanticLabel: s.done ? 'Set ${j + 1} urađen, ispravi' : 'Set ${j + 1}',
            radius: ClRadius.full,
            builder: (context, pressed) => Padding(
              padding: const EdgeInsets.all(4),
              child: AnimatedContainer(
                duration: context.motion(ClMotion.fast),
                width: j == current ? 22 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: s.done || j == current ? c.ink : c.border,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A held set's button: "Pokreni · 30 s", then the countdown in its place.
/// Stopping early logs what was held.
class _HoldButton extends StatefulWidget {
  const _HoldButton({super.key, required this.seconds, required this.onDone});

  final int seconds;
  final ValueChanged<int> onDone;

  @override
  State<_HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<_HoldButton> {
  Timer? _timer;
  int _left = 0;

  void _start() {
    HapticFeedback.mediumImpact();
    setState(() => _left = widget.seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_left <= 1) {
        t.cancel();
        HapticFeedback.heavyImpact();
        widget.onDone(widget.seconds);
        return;
      }
      if (_left <= 4) HapticFeedback.selectionClick();
      setState(() => _left--);
    });
  }

  void _stop() {
    _timer?.cancel();
    widget.onDone((widget.seconds - _left).clamp(1, widget.seconds));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    if (_timer == null) {
      return ClButton.block(label: 'Pokreni · ${formatSeconds(widget.seconds)}', onPressed: _start);
    }
    return ClPressable(
      onPressed: _stop,
      semanticLabel: 'Zaustavi, ostalo ${formatSeconds(_left)}',
      radius: ClRadius.full,
      builder: (context, pressed) => Container(
        height: 64,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(ClRadius.full)),
        child: Stack(
          children: [
            // The bar fills the button as time runs.
            FractionallySizedBox(
              widthFactor: 1 - _left / widget.seconds,
              child: ColoredBox(color: c.ink, child: const SizedBox.expand()),
            ),
            Center(
              child: Text(
                '${formatClock(Duration(seconds: _left))} · Zaustavi',
                style: cl.text.bodyStrong.copyWith(
                  color: _left / widget.seconds < 0.5 ? c.bg : c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rest between sets, the whole screen: the clock in a ring, how the set
/// felt (asked once), what comes next and "Kreni". Moves on by itself when
/// the time is up. Without [duration] it is the end of the workout.
class _RestScreen extends StatefulWidget {
  const _RestScreen({
    super.key,
    required this.duration,
    required this.done,
    required this.isPr,
    required this.rir,
    required this.onFeel,
    required this.upNext,
    required this.upNextDetail,
    required this.upNextImage,
    required this.onClose,
    required this.onMenu,
    required this.onGo,
    required this.onTimeUp,
  });

  final Duration? duration;

  /// The set just done, e.g. "Plank · 30 s".
  final String? done;
  final bool isPr;
  final int? rir;
  final ValueChanged<int> onFeel;
  final String? upNext;
  final String? upNextDetail;
  final ImageProvider? upNextImage;
  final VoidCallback onClose;
  final VoidCallback onMenu;
  final VoidCallback onGo;
  final VoidCallback onTimeUp;

  @override
  State<_RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<_RestScreen> {
  late DateTime _end = DateTime.now().add(widget.duration ?? Duration.zero);
  late Duration _total = widget.duration ?? Duration.zero;
  Timer? _timer;
  bool _changingFeel = false;

  @override
  void initState() {
    super.initState();
    if (widget.duration == null) return;
    _timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (!mounted) return t.cancel();
      final left = _end.difference(DateTime.now());
      if (left <= Duration.zero) {
        t.cancel();
        HapticFeedback.heavyImpact();
        widget.onTimeUp();
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _add() {
    HapticFeedback.selectionClick();
    setState(() {
      _end = _end.add(const Duration(seconds: 15));
      _total += const Duration(seconds: 15);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final ink = c.bg;
    final muted = c.bg.withValues(alpha: 0.6);
    final end = widget.duration == null;
    final left = _end.difference(DateTime.now());
    final shown = left <= Duration.zero ? Duration.zero : left + const Duration(milliseconds: 999);
    final progress = _total.inMilliseconds == 0
        ? 1.0
        : 1 - (left.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);

    const feels = [('Lako', 3), ('Taman', 2), ('Teško', 0)];
    final answered = feels.where((f) => f.$2 == widget.rir).firstOrNull;

    Widget feelChip(String label, int rir) => Expanded(
      child: ClPressable(
        onPressed: () {
          HapticFeedback.selectionClick();
          widget.onFeel(rir);
          setState(() => _changingFeel = false);
        },
        semanticLabel: label,
        radius: ClRadius.full,
        builder: (context, pressed) => AnimatedContainer(
          duration: context.motion(ClMotion.fast),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pressed ? ink.withValues(alpha: 0.18) : ink.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(ClRadius.full),
          ),
          child: Text(label, style: cl.text.bodyStrong.copyWith(color: ink)),
        ),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.ink,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ClIconButton.onMedia(
                      icon: ClIcons.close,
                      semanticLabel: 'Zatvori, trening se nastavlja',
                      onPressed: widget.onClose,
                    ),
                    const Spacer(),
                    ClIconButton.onMedia(
                      icon: ClIcons.more,
                      semanticLabel: 'Opcije treninga',
                      onPressed: widget.onMenu,
                    ),
                  ],
                ),
                const SizedBox(height: ClSpace.s4),
                if (widget.done != null)
                  Row(
                    children: [
                      Icon(widget.isPr ? ClIcons.record : ClIcons.check, size: 18, color: ink),
                      const SizedBox(width: ClSpace.s2),
                      Expanded(
                        child: Text(
                          widget.isPr ? 'Novi rekord · ${widget.done}' : widget.done!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: cl.text.bodyStrong.copyWith(color: ink),
                        ),
                      ),
                    ],
                  ),
                // The clock in a ring, or the end.
                Expanded(
                  child: Center(
                    child: end
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Sve vežbe\nsu gotove.',
                                textAlign: TextAlign.center,
                                style: cl.text.displayL.copyWith(color: ink, fontSize: 44, height: 1.02),
                              ),
                            ],
                          )
                        : SizedBox.square(
                            dimension: 240,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: 1 - progress,
                                  strokeWidth: 6,
                                  strokeCap: StrokeCap.round,
                                  color: ink,
                                  backgroundColor: ink.withValues(alpha: 0.12),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Odmor', style: cl.text.label.copyWith(color: muted)),
                                    Text(
                                      formatClock(shown),
                                      style: cl.text.metricL.copyWith(
                                        color: ink,
                                        fontSize: 64,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                    ClPressable(
                                      onPressed: _add,
                                      semanticLabel: 'Još 15 sekundi',
                                      radius: ClRadius.full,
                                      builder: (context, pressed) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: ClSpace.s3,
                                          vertical: ClSpace.s2,
                                        ),
                                        child: Text(
                                          '+15 s',
                                          style: cl.text.bodyStrong.copyWith(color: muted),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                // Asked once; then it steps aside.
                if (widget.done != null)
                  AnimatedSwitcher(
                    duration: context.motion(ClMotion.fast),
                    child: answered == null || _changingFeel
                        ? Column(
                            key: const ValueKey('ask'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Kako je bilo?', style: cl.text.label.copyWith(color: muted)),
                              const SizedBox(height: ClSpace.s2),
                              Row(
                                children: [
                                  for (final (j, f) in feels.indexed) ...[
                                    if (j > 0) const SizedBox(width: ClSpace.s2),
                                    feelChip(f.$1, f.$2),
                                  ],
                                ],
                              ),
                            ],
                          )
                        : Align(
                            key: const ValueKey('told'),
                            alignment: Alignment.centerLeft,
                            child: ClPressable(
                              onPressed: () => setState(() => _changingFeel = true),
                              semanticLabel: 'Bilo je ${answered.$1.toLowerCase()}, promeni',
                              radius: ClRadius.sm,
                              builder: (context, pressed) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: ClSpace.s2),
                                child: Text(
                                  '${answered.$1} · zabeleženo',
                                  style: cl.text.label.copyWith(color: muted),
                                ),
                              ),
                            ),
                          ),
                  ),
                const SizedBox(height: ClSpace.s4),
                // What comes next, then one button.
                if (widget.upNext != null) ...[
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(ClRadius.sm - 6),
                        child: SizedBox(
                          width: 44,
                          height: 55,
                          child: widget.upNextImage == null
                              ? ColoredBox(color: ink.withValues(alpha: 0.1))
                              : ClPhoto(image: widget.upNextImage, placeholderLabel: ''),
                        ),
                      ),
                      const SizedBox(width: ClSpace.s3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sledeće', style: cl.text.label.copyWith(color: muted)),
                            Text(
                              widget.upNext!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: cl.text.bodyStrong.copyWith(color: ink, fontSize: 17),
                            ),
                            if (widget.upNextDetail != null)
                              Text(widget.upNextDetail!, style: cl.text.label.copyWith(color: muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ClSpace.s4),
                ],
                ClThemeScope(
                  theme: ClTheme.dark,
                  child: ClButton.block(label: end ? 'Završi trening' : 'Kreni', onPressed: widget.onGo),
                ),
                const SizedBox(height: ClSpace.s2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
