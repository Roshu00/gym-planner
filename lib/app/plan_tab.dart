import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'plan_finder.dart';
import 'plan_screen.dart';
import 'summary_screen.dart';
import 'swap_sheet.dart';
import 'workout_session.dart';

const _dayShort = ['Pon', 'Uto', 'Sre', 'Čet', 'Pet', 'Sub', 'Ned'];

/// The user's calendar. The plan only suggests: every day can be changed in
/// one tap (rest, move by a day, a break, another workout, a shorter
/// version, own exercises) and every change can be undone. Missed days never
/// count against the user; the rotation simply moves forward.
class PlanTabScreen extends StatefulWidget {
  const PlanTabScreen({super.key});

  @override
  State<PlanTabScreen> createState() => _PlanTabScreenState();
}

class _PlanTabScreenState extends State<PlanTabScreen> {
  DateTime? _selected;
  DateTime? _month;

  /// What the last change did, and the days before it, for "Poništi".
  String? _done;
  Map<String, DayPlan>? _undo;

  /// Runs a change to the calendar and offers to undo it.
  void _change(String message, void Function() change) {
    final store = context.readStore;
    final before = store.plan?.days;
    change();
    setState(() {
      _done = message;
      _undo = before;
    });
  }

  void _undoChange() {
    final days = _undo;
    if (days != null) context.readStore.restoreDays(days);
    setState(() {
      _done = null;
      _undo = null;
    });
  }

  /// When something happens, as it reads in a sentence: `danas`, `sutra`,
  /// `u subotu 3. 10`. No trailing dot, so it can end a sentence.
  String _dayName(DateTime d, DateTime today) {
    if (d == today) return 'danas';
    if (d == today.add(const Duration(days: 1))) return 'sutra';
    const on = ['u ponedeljak', 'u utorak', 'u sredu', 'u četvrtak', 'u petak', 'u subotu', 'u nedelju'];
    final date = formatDate(d, now: today);
    return '${on[d.weekday - 1]} ${date.substring(0, date.length - 1)}';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final today = dateOnly(store.now);
    final selected = _selected ?? today;
    final month = _month ?? DateTime(today.year, today.month);
    final plan = store.plan;

    final monthEnd = DateTime(month.year, month.month + 1, 0);
    var horizon = monthEnd.isAfter(today) ? monthEnd : today;
    if (selected.isAfter(horizon)) horizon = selected;
    horizon = horizon.add(const Duration(days: 14));
    final schedule = store.schedule(horizon);

    // Rest days are shown from the start of the user's activity onwards.
    final firstSession = store.sessions
        .map((s) => dateOnly(s.finishedAt!))
        .fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
    final activeFrom = [
      ?firstSession,
      if (plan != null) dateOnly(plan.startedAt),
    ].fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);

    ClDayMark markFor(DateTime day) {
      if (sessionsOn(store.sessions, day).isNotEmpty) return ClDayMark.done;
      if (schedule.containsKey(day)) return ClDayMark.planned;
      final isPast = day.isBefore(today);
      if (isPast) return activeFrom != null && !day.isBefore(activeFrom) ? ClDayMark.rest : ClDayMark.none;
      return plan == null ? ClDayMark.none : ClDayMark.rest;
    }

    final daySessions = sessionsOn(store.sessions, selected);
    final planned = selected.isBefore(today) ? null : store.plannedOn(selected);
    final canStart = selected == today && planned != null && daySessions.isEmpty;

    return AppScreen(
      bottom: canStart
          ? ClButton.block(
              label: store.active == null ? 'Počni trening' : 'Nastavi trening',
              onPressed: () {
                store.startToday();
                pushScreen(context, const WorkoutSessionScreen());
              },
            )
          : null,
      children: [
        const SizedBox(height: ClSpace.s4),
        ClScreenTitle(
          label: plan == null
              ? 'Istorija i planirani dani'
              : store.weeklyGoal == 0
              ? plan.name
              : '${plan.name} · ${store.thisWeek} od ${store.weeklyGoal} ove nedelje',
          title: 'Plan',
          large: true,
        ),
        gapS,
        ClCalendar(
          month: month,
          selected: selected,
          today: today,
          markFor: markFor,
          isEdited: (d) => !d.isBefore(today) && store.dayPlan(d) != null,
          onSelect: (d) => setState(() {
            _selected = d;
            _done = null;
          }),
          onMonthChanged: (m) => setState(() => _month = m),
        ),
        const SizedBox(height: ClSpace.s2),
        const Padding(
          padding: EdgeInsets.only(left: ClSpace.s1),
          child: ClCalendarLegend(),
        ),
        gap,
        ClSectionHeader(
          label:
              '${weekdayName(selected)} ${formatDate(selected, now: store.now)}${selected == today ? ' · Danas' : ''}',
        ),
        if (_done != null) ...[_UndoBar(message: _done!, onUndo: _undo == null ? null : _undoChange), gapS],
        ..._dayDetail(context, selected, today, daySessions, planned, schedule),
        if (plan != null) ...[
          gap,
          ClMenuGroup(
            children: [
              ClMenuRow(
                icon: ClIcons.days,
                title: 'Dani treninga',
                value: [for (final d in plan.trainingDays.toList()..sort()) _dayShort[d - 1]].join(', '),
                onPressed: () => showClSheet<void>(
                  context,
                  title: 'Dani treninga',
                  builder: (_) => const _TrainingDaysSheet(),
                ),
              ),
              ClMenuRow(
                icon: ClIcons.swap,
                title: 'Program i zamene vežbi',
                onPressed: () => pushScreen(context, const PlanScreen()),
              ),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _dayDetail(
    BuildContext context,
    DateTime day,
    DateTime today,
    List<Session> sessions,
    ({Workout workout, List<WorkoutExercise> exercises, DayPlan? custom})? planned,
    Map<DateTime, String> schedule,
  ) {
    final store = context.store;
    final cl = context.cl;
    final muted = cl.text.body.copyWith(color: cl.colors.inkMuted);
    final custom = store.dayPlan(day);
    final name = _dayName(day, today);
    String g(String male, String female) => store.profile?.says(male, female) ?? male;

    Widget actions(List<Widget> chips) => Wrap(spacing: ClSpace.s2, children: chips);
    final backToPlan = custom == null || day.isBefore(today)
        ? const SizedBox.shrink()
        : Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              label: 'Vrati na plan',
              variant: ClButtonVariant.text,
              icon: ClIcons.sync,
              onPressed: () => _change('Dan je vraćen na plan.', () => store.setDayPlan(day, null)),
            ),
          );

    if (sessions.isNotEmpty) {
      return [
        for (final s in sessions)
          ClListRow(
            title: s.workoutName,
            meta: '${sessionMeta(s)} · ${s.creatorName}',
            trailing: s.prCount > 0 ? const ClTag.pr() : null,
            onPressed: () => pushScreen(context, SummaryScreen(sessionId: s.id), theme: ClTheme.light),
          ),
      ];
    }

    if (store.plan == null) {
      return [
        Text(
          day.isBefore(today) ? 'Tog dana nije bilo treninga.' : 'Bez plana nema planiranih dana.',
          style: muted,
        ),
        gapS,
        ClButton(
          label: 'Pronađi plan',
          variant: ClButtonVariant.secondary,
          icon: ClIcons.find,
          onPressed: () => pushScreen(context, const PlanFinderScreen()),
        ),
      ];
    }

    // A past day without a workout: maybe it was done and not logged.
    if (day.isBefore(today)) {
      return [
        Text('Nema zabeleženog treninga.', style: cl.text.bodyStrong),
        const SizedBox(height: ClSpace.s1),
        Text(
          '${g('Trenirao', 'Trenirala')} si, a nisi ${g('zabeležio', 'zabeležila')}? Unesi ga sada, ostaje na ovom danu.',
          style: muted,
        ),
        gapS,
        actions([
          ClActionChip(
            label: 'Zabeleži naknadno',
            icon: ClIcons.add,
            onPressed: () async {
              final id = await _pickWorkout(context, title: 'Šta si ${g('radio', 'radila')}?');
              if (id == null || !context.mounted) return;
              context.readStore.startSession(workoutId: id, loggedFor: day);
              pushScreen(context, const WorkoutSessionScreen());
            },
          ),
        ]),
      ];
    }

    if (planned != null) {
      final w = planned.workout;
      final note = planned.custom?.note;
      final minutes = (w.estimatedMinutes * planned.exercises.length / w.exercises.length.clamp(1, 99))
          .round();
      return [
        ClPopBlock(
          color: cl.colors.popFor(w.id),
          sticker: note == null ? null : ClSticker(note),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day == today ? 'Danas' : 'Planirano'} · '
                '${countLabel(planned.exercises.length, 'vežba', 'vežbe', 'vežbi')} · ~$minutes min',
                style: cl.text.bodyStrong.copyWith(fontSize: 13),
              ),
              const SizedBox(height: ClSpace.s1),
              Text(w.name, style: cl.text.displayM),
            ],
          ),
        ),
        gapS,
        actions([
          ClActionChip(
            label: 'Odmor',
            icon: ClIcons.rest,
            onPressed: () =>
                _change('Odmor $name. Treninzi posle idu po jedan trening dalje.', () => store.restOn(day)),
          ),
          ClActionChip(
            label: 'Pomeri za dan',
            icon: ClIcons.arrowRight,
            onPressed: () {
              final before = store.plan?.days;
              final taken = store.shiftFrom(day);
              setState(() {
                _undo = before;
                _done = taken == null
                    ? 'Treninzi su pomereni za jedan dan.'
                    : 'Treninzi su pomereni za jedan dan. Trening je sada i ${_dayName(taken, today)}, posle toga sve ide po planu.';
              });
            },
          ),
          if (note != 'Kraća verzija')
            ClActionChip(
              label: 'Kraća verzija',
              icon: ClIcons.timer,
              onPressed: () =>
                  _change('Kraća verzija $name: manje vežbi, set manje.', () => store.quickVersionOn(day)),
            ),
          ClActionChip(
            label: 'Drugi trening',
            icon: ClIcons.swap,
            onPressed: () async {
              final id = await _pickWorkout(context, title: 'Drugi trening', except: w.id);
              if (id == null || !context.mounted) return;
              _change(
                '${store.workoutsById[id]?.name} $name. ${w.name} ostaje za sledeći trening.',
                () => store.swapWorkoutOn(day, id),
              );
            },
          ),
          ClActionChip(
            label: 'Izmeni vežbe',
            icon: ClIcons.barbell,
            onPressed: () => showClSheet<void>(
              context,
              title: 'Vežbe za ovaj dan',
              label: '${w.name} · ${weekdayName(day)} ${formatDate(day, now: today)}',
              builder: (_) => _EditDaySheet(day: day, onSaved: (m) => _change(m, () {})),
            ),
          ),
          ClActionChip(label: 'Pauza', icon: ClIcons.days, onPressed: () => _openPause(context, day, today)),
        ]),
        backToPlan,
        gapS,
        for (final (i, we) in planned.exercises.indexed)
          if (store.resolveExercise(we.exerciseId) case final e?)
            ClExerciseRow(
              index: i + 1,
              name: e.name,
              detail: prescription(we.target, we.rir, we.restSeconds),
            ),
      ];
    }

    // A rest day, by the plan or by the user's choice.
    final next = schedule.entries.where((e) => e.key.isAfter(day)).firstOrNull;
    final nextWorkout = next == null ? null : store.workoutsById[next.value];
    return [
      Text(custom?.note == 'Pauza' ? 'Pauza.' : 'Odmor.', style: cl.text.displayM),
      const SizedBox(height: ClSpace.s2),
      Text(
        [
          'Dan odmora ne prekida niz.',
          if (nextWorkout != null) 'Sledeći je ${nextWorkout.name}, ${_dayName(next!.key, today)}.',
        ].join(' '),
        style: muted,
      ),
      gapS,
      actions([
        ClActionChip(
          label: 'Treniraj ovaj dan',
          icon: ClIcons.barbell,
          onPressed: () => _change('Trening $name. Plan nastavlja od njega.', () => store.trainOn(day)),
        ),
        ClActionChip(label: 'Pauza', icon: ClIcons.days, onPressed: () => _openPause(context, day, today)),
      ]),
      backToPlan,
    ];
  }

  Future<void> _openPause(BuildContext context, DateTime day, DateTime today) async {
    final store = context.readStore;
    final count = await showClSheet<int>(
      context,
      title: 'Pauza',
      label: 'Putovanje, bolest, gužva na poslu',
      builder: (_) => const _PauseSheet(),
    );
    if (count == null || !mounted) return;
    final end = day.add(Duration(days: count - 1));
    _change(
      'Pauza do ${formatDate(end, now: today)} Posle nastavljaš gde si ${store.profile?.says('stao', 'stala') ?? 'stao'}, ništa se ne preskače.',
      () => store.pause(day, count),
    );
  }
}

/// What the last change did, with undo.
class _UndoBar extends StatelessWidget {
  const _UndoBar({required this.message, required this.onUndo});

  final String message;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s1, ClSpace.s2, ClSpace.s1),
      decoration: BoxDecoration(
        color: cl.colors.signalSoft,
        borderRadius: BorderRadius.circular(ClRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(message, style: cl.text.body.copyWith(fontSize: 14)),
            ),
          ),
          if (onUndo != null) ClButton(label: 'Poništi', variant: ClButtonVariant.text, onPressed: onUndo),
        ],
      ),
    );
  }
}

/// Picks a workout: the plan's own first, then workouts of followed creators.
Future<String?> _pickWorkout(BuildContext context, {required String title, String? except}) {
  final store = context.readStore;
  final plan = store.plan;
  final fromPlan = [
    for (final id in plan?.workoutIds ?? const <String>[])
      if (id != except) ?store.workoutsById[id],
  ];
  final others = [
    for (final w in store.allWorkouts)
      if (w.id != except &&
          !(plan?.workoutIds.contains(w.id) ?? false) &&
          w.exercises.isNotEmpty &&
          store.isFollowing(w.creatorId) &&
          store.canAccess(w.visibility, w.creatorId))
        w,
  ];
  Widget row(BuildContext context, Workout w) => ClListRow(
    title: w.name,
    meta: '${workoutMeta(w)} · ${store.creator(w.creatorId)?.name ?? ''}',
    onPressed: () => Navigator.of(context).pop(w.id),
  );
  return showClSheet<String>(
    context,
    title: title,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fromPlan.isNotEmpty) ...[
          const ClSectionHeader(label: 'Iz plana'),
          for (final w in fromPlan) row(context, w),
        ],
        if (others.isNotEmpty) ...[
          gapS,
          const ClSectionHeader(label: 'Biblioteka'),
          for (final w in others) row(context, w),
        ],
      ],
    ),
  );
}

class _PauseSheet extends StatefulWidget {
  const _PauseSheet();

  @override
  State<_PauseSheet> createState() => _PauseSheetState();
}

class _PauseSheetState extends State<_PauseSheet> {
  int _days = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClStepper(
          label: 'Broj dana',
          value: _days,
          min: 1,
          max: 28,
          format: (n) => '$n ${plural(n, 'dan', 'dana', 'dana')}',
          onChanged: (v) => setState(() => _days = v),
        ),
        const SizedBox(height: ClSpace.s2),
        ClNotice(
          'Treninzi čekaju. Posle pauze nastavljaš tačno gde si ${context.store.profile?.says('stao', 'stala') ?? 'stao'}, i niz se ne prekida.',
        ),
        gapS,
        ClButton(label: 'Uzmi pauzu', expand: true, onPressed: () => Navigator.of(context).pop(_days)),
      ],
    );
  }
}

/// The day's own exercise list: swap, remove, add, more or fewer sets.
/// Saved for this day only; the program stays the same.
class _EditDaySheet extends StatefulWidget {
  const _EditDaySheet({required this.day, required this.onSaved});

  final DateTime day;
  final ValueChanged<String> onSaved;

  @override
  State<_EditDaySheet> createState() => _EditDaySheetState();
}

class _EditDaySheetState extends State<_EditDaySheet> {
  late List<WorkoutExercise> _list = [...?context.readStore.plannedOn(widget.day)?.exercises];

  void _set(int i, WorkoutExercise e) => setState(() => _list = [..._list]..[i] = e);

  Future<void> _swap(int i) async {
    final store = context.readStore;
    final e = store.resolveExercise(_list[i].exerciseId);
    if (e == null) return;
    final id = await showSwapSheet(context, e);
    if (id != null && mounted) _set(i, _list[i].copyWith(exerciseId: id));
  }

  Future<void> _add() async {
    final store = context.readStore;
    final w = store.plannedOn(widget.day)?.workout;
    final inList = {for (final we in _list) store.resolveExercise(we.exerciseId)?.id};
    final options = [
      for (final e in store.allExercises)
        if (!inList.contains(e.id) &&
            canDo(e, store.equipment) &&
            store.isFollowing(e.creatorId) &&
            store.canAccess(e.visibility, e.creatorId))
          e,
    ]..sort((a, b) => (a.creatorId == w?.creatorId ? 0 : 1).compareTo(b.creatorId == w?.creatorId ? 0 : 1));
    final id = await showClSheet<String>(
      context,
      title: 'Dodaj vežbu',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in options)
            ClListRow(
              title: e.name,
              meta: '${e.muscle.label} · ${e.equipmentLabel}',
              onPressed: () => Navigator.of(context).pop(e.id),
            ),
        ],
      ),
    );
    if (id != null && mounted) setState(() => _list = [..._list, WorkoutExercise(exerciseId: id)]);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, we) in _list.indexed)
          if (store.resolveExercise(we.exerciseId) case final e?)
            Padding(
              padding: const EdgeInsets.only(bottom: ClSpace.s2),
              child: Container(
                padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s2, ClSpace.s1, ClSpace.s2),
                decoration: BoxDecoration(
                  color: cl.colors.surface,
                  borderRadius: BorderRadius.circular(ClRadius.sm),
                  boxShadow: ClElevation.card(cl.colors.shadow),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(e.name, style: cl.text.bodyStrong)),
                        ClIconButton(
                          icon: ClIcons.swap,
                          semanticLabel: 'Zameni ${e.name}',
                          onPressed: () => _swap(i),
                        ),
                        ClIconButton(
                          icon: ClIcons.close,
                          semanticLabel: 'Ukloni ${e.name}',
                          onPressed: _list.length <= 1
                              ? null
                              : () => setState(() => _list = [..._list]..removeAt(i)),
                        ),
                      ],
                    ),
                    ClStepper(
                      label: 'Setovi',
                      value: we.sets,
                      min: 1,
                      max: 10,
                      onChanged: (v) => _set(i, we.copyWith(sets: v)),
                    ),
                  ],
                ),
              ),
            ),
        ClActionChip(label: 'Dodaj vežbu', icon: ClIcons.add, onPressed: _add),
        gapS,
        ClButton(
          label: 'Sačuvaj za ovaj dan',
          expand: true,
          onPressed: () {
            store.editDayExercises(widget.day, _list);
            Navigator.of(context).pop();
            widget.onSaved('Vežbe su izmenjene samo za ovaj dan. Program ostaje isti.');
          },
        ),
      ],
    );
  }
}

class _TrainingDaysSheet extends StatelessWidget {
  const _TrainingDaysSheet();

  @override
  Widget build(BuildContext context) {
    final plan = context.store.plan;
    if (plan == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: ClSpace.s2,
          children: [
            for (var d = 1; d <= 7; d++)
              ClFilter(
                label: _dayShort[d - 1],
                selected: plan.trainingDays.contains(d),
                onChanged: (on) {
                  final days = on ? {...plan.trainingDays, d} : ({...plan.trainingDays}..remove(d));
                  if (days.isNotEmpty) context.readStore.setTrainingDays(days);
                },
              ),
          ],
        ),
        gapS,
        ClNotice(
          'Program predviđa ${plan.daysPerWeek}× nedeljno. Ovo su tvoji uobičajeni dani; svaki dan možeš i posebno da promeniš u kalendaru.',
        ),
      ],
    );
  }
}
