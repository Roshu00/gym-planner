import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_store.dart';
import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'summary_screen.dart';
import 'swap_sheet.dart';

/// Set-by-set workout. Last time's result is the hint, confirming a set
/// starts the rest timer, records show immediately.
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

  AppStore get _store => context.readStore;

  int _firstOpenExercise(Session s) {
    final i = s.exercises.indexWhere((e) => !e.isComplete);
    return i < 0 ? s.exercises.length - 1 : i;
  }

  void _toggle(int setIndex) {
    final i = _exercise!;
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
        if (_store.active!.exercises[i].sets[setIndex].isPr) HapticFeedback.mediumImpact();
      }
    });
  }

  void _onChanged(int setIndex, ClSetData d) {
    final old = _store.active!.exercises[_exercise!].sets[setIndex];
    final kg = parseDecimal(d.kg);
    final reps = int.tryParse(d.reps);
    final rir = int.tryParse(d.rir);
    _store.updateSet(
      _exercise!,
      setIndex,
      old.copyWith(
        kg: kg,
        reps: reps,
        rir: rir,
        clearKg: kg == null,
        clearReps: reps == null,
        clearRir: rir == null,
      ),
    );
    if (_notice != null) setState(() => _notice = null);
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
    final action = await showClSheet<String>(
      context,
      title: 'Trening',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClButton(
            label: 'Zameni vežbu',
            variant: ClButtonVariant.secondary,
            icon: ClIcons.swap,
            expand: true,
            onPressed: () => Navigator.of(context).pop('swap'),
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
    if (action == 'swap') return _swap();
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

    String fmt(num? v) => v == null ? '' : formatNumber(v);
    final rows = [
      for (final (j, s) in e.sets.indexed)
        ClSetData(
          previousKg: prev.isEmpty ? null : prev[j.clamp(0, prev.length - 1)].kg ?? 0,
          previousReps: prev.isEmpty ? null : prev[j.clamp(0, prev.length - 1)].reps,
          hintKg: store.suggestedSet(e, j)?.kg ?? (e.bodyweight ? 0 : null),
          hintReps: store.suggestedSet(e, j)?.reps ?? e.repsMin,
          kg: fmt(s.kg),
          reps: fmt(s.reps),
          rir: fmt(s.rir),
          state: s.done ? ClSetState.done : (j == current ? ClSetState.current : ClSetState.pending),
          isPr: s.isPr,
        ),
    ];

    final Widget action;
    if (current >= 0) {
      action = ClButton.block(label: 'Završi set', onPressed: () => _toggle(current));
    } else if (!isLast) {
      action = ClButton.block(
        label: 'Sledeća vežba',
        onPressed: () => setState(() {
          _exercise = i + 1;
          _notice = null;
        }),
      );
    } else {
      action = ClButton.block(label: 'Završi trening', onPressed: _finish);
    }

    return AppScreen(
      topBar: ClTopBar(
        label: '${session.workoutName} · Vežba ${i + 1} / ${session.exercises.length}',
        actions: [
          ClIconButton(icon: ClIcons.swap, semanticLabel: 'Zameni vežbu', onPressed: _swap),
          ClIconButton(icon: ClIcons.more, semanticLabel: 'Opcije treninga', onPressed: _menu),
        ],
      ),
      bottom: action,
      children: [
        ClScreenTitle(label: prescription(e.target, e.rir, e.restSeconds), title: e.name),
        if (e.swappedFrom != null) ...[
          const SizedBox(height: ClSpace.s2),
          ClNotice('Zamena za ${e.swappedFrom}'),
        ],
        gapS,
        ClCreatorLine(name: e.noteBy ?? session.creatorName, trailing: e.muscle.label),
        if (e.note.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s2),
          Text(e.note, style: cl.text.body.copyWith(color: cl.colors.inkMuted)),
        ],
        const SizedBox(height: ClSpace.s6),
        ClSetTable(sets: rows, onChanged: _onChanged, onToggleDone: _toggle),
        if (_notice != null) ...[const SizedBox(height: ClSpace.s2), ClNotice(_notice!, danger: true)],
        Row(
          children: [
            ClButton(label: 'Dodaj set', variant: ClButtonVariant.text, onPressed: () => store.addSet(i)),
            const Spacer(),
            if (e.sets.length > 1 && !e.sets.last.done)
              ClButton(
                label: 'Ukloni set',
                variant: ClButtonVariant.text,
                onPressed: () => store.removeSet(i, e.sets.length - 1),
              ),
          ],
        ),
        if (_resting) ...[
          gapS,
          ClRestTimer(
            key: ValueKey(_restRun),
            duration: Duration(seconds: e.restSeconds),
            onSkip: () => setState(() => _resting = false),
          ),
        ],
        gap,
        ClSectionHeader(
          label:
              'Trening · ${session.doneSets} / ${session.exercises.fold(0, (n, x) => n + x.sets.length)} setova',
        ),
        for (final (j, x) in session.exercises.indexed)
          ClListRow(
            title: x.name,
            meta: '${x.doneSets.length} / ${x.sets.length} · ${x.target}',
            leading: SizedBox(
              width: 24,
              child: Text(
                '${j + 1}'.padLeft(2, '0'),
                style: cl.text.data.copyWith(color: j == i ? cl.colors.ink : cl.colors.inkMuted),
              ),
            ),
            trailing: x.hasPr
                ? const ClTag.pr()
                : (x.isComplete ? Icon(ClIcons.check, size: 18, color: cl.colors.ink) : null),
            onPressed: j == i
                ? null
                : () => setState(() {
                    _exercise = j;
                    _resting = false;
                    _notice = null;
                  }),
          ),
        gapS,
        if (current >= 0 || !isLast)
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(label: 'Završi trening', variant: ClButtonVariant.text, onPressed: _finish),
          ),
      ],
    );
  }
}
