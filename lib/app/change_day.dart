import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'swap_sheet.dart';

/// What a change did, and the plan's days before it, for "Poništi".
typedef DayChange = ({String message, Map<String, DayPlan>? before});

/// When something happens, as it reads in a sentence: `danas`, `sutra`,
/// `u subotu 3. 10`. No trailing dot, so it can end a sentence.
String dayInSentence(DateTime d, DateTime today) {
  if (d == today) return 'danas';
  if (d == today.add(const Duration(days: 1))) return 'sutra';
  const on = ['u ponedeljak', 'u utorak', 'u sredu', 'u četvrtak', 'u petak', 'u subotu', 'u nedelju'];
  final date = formatDate(d, now: today);
  return '${on[d.weekday - 1]} ${date.substring(0, date.length - 1)}';
}

enum _Action { cantTrain, shorter, other, edit, rest, pause, train }

/// "Promeni dan": one list of what can happen to [day], the common choices
/// first, each with a sentence saying what it does. Used from Today and the
/// Plan tab so both name things the same. Returns null when nothing changed.
Future<DayChange?> changeDay(BuildContext context, DateTime day) async {
  final store = context.readStore;
  final today = dateOnly(store.now);
  final planned = store.plannedOn(day);
  final name = dayInSentence(day, today);
  final isToday = day == today;

  Widget option(BuildContext context, _Action a, IconData icon, String title, String meta) => ClListRow(
    title: title,
    meta: meta,
    leading: Icon(icon, size: ClSize.icon, color: context.clColors.ink),
    onPressed: () => Navigator.of(context).pop(a),
  );

  final action = await showClSheet<_Action>(
    context,
    title: 'Promeni dan',
    label: planned == null ? '${weekdayName(day)} · odmor' : '${weekdayName(day)} · ${planned.workout.name}',
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: planned == null
          ? [
              option(
                context,
                _Action.train,
                ClIcons.barbell,
                'Treniraj ovaj dan',
                'Plan nastavlja od ovog treninga',
              ),
              option(
                context,
                _Action.pause,
                ClIcons.days,
                'Pauza više dana',
                'Putovanje, bolest, gužva na poslu',
              ),
            ]
          : [
              option(
                context,
                _Action.cantTrain,
                ClIcons.arrowRight,
                isToday ? 'Danas ne mogu' : 'Ne mogu taj dan',
                '${planned.workout.name} ide na sledeći slobodan dan',
              ),
              if (planned.custom?.note != 'Kraća verzija')
                option(context, _Action.shorter, ClIcons.timer, 'Kraća verzija', 'Manje vežbi i set manje'),
              option(
                context,
                _Action.other,
                ClIcons.swap,
                'Drugi trening',
                'Iz plana ili biblioteke trenera',
              ),
              const SizedBox(height: ClSpace.s2),
              const ClSectionHeader(label: 'Više'),
              option(
                context,
                _Action.edit,
                ClIcons.barbell,
                'Izmeni vežbe',
                'Samo za ovaj dan, program ostaje isti',
              ),
              option(context, _Action.rest, ClIcons.rest, 'Dan odmora', 'Ceo plan ide jedan trening dalje'),
              option(
                context,
                _Action.pause,
                ClIcons.days,
                'Pauza više dana',
                'Putovanje, bolest, gužva na poslu',
              ),
            ],
    ),
  );
  if (action == null || !context.mounted) return null;

  final before = store.plan?.days;
  DayChange done(String message) => (message: message, before: before);

  switch (action) {
    case _Action.cantTrain:
      final taken = store.shiftFrom(day);
      return done(
        taken == null
            ? 'Treninzi su pomereni za jedan dan.'
            : '${planned!.workout.name} je sada ${dayInSentence(taken, today)}. Posle toga sve ide po planu.',
      );
    case _Action.shorter:
      store.quickVersionOn(day);
      return done('Kraća verzija $name: manje vežbi, set manje.');
    case _Action.other:
      final id = await pickWorkout(context, title: 'Drugi trening', except: planned!.workout.id);
      if (id == null || !context.mounted) return null;
      store.swapWorkoutOn(day, id);
      return done(
        '${store.workoutsById[id]?.name} $name. ${planned.workout.name} ostaje za sledeći trening.',
      );
    case _Action.edit:
      final saved = await showClSheet<bool>(
        context,
        title: 'Vežbe za ovaj dan',
        label: '${planned!.workout.name} · ${weekdayName(day)} ${formatDate(day, now: today)}',
        builder: (_) => _EditDaySheet(day: day),
      );
      return saved == true ? done('Vežbe su izmenjene samo za ovaj dan. Program ostaje isti.') : null;
    case _Action.rest:
      store.restOn(day);
      return done('Odmor $name. Treninzi posle idu po jedan trening dalje.');
    case _Action.pause:
      final count = await showClSheet<int>(
        context,
        title: 'Pauza',
        label: 'Putovanje, bolest, gužva na poslu',
        builder: (_) => const _PauseSheet(),
      );
      if (count == null || !context.mounted) return null;
      store.pause(day, count);
      final end = day.add(Duration(days: count - 1));
      return done(
        'Pauza do ${formatDate(end, now: today)} Posle nastavljaš '
        '${store.profile?.says('gde si stao', 'gde si stala', 'odakle je stalo') ?? 'odakle je stalo'}, '
        'ništa se ne preskače.',
      );
    case _Action.train:
      store.trainOn(day);
      return done('Trening $name. Plan nastavlja od njega.');
  }
}

/// Picks a workout: the plan's own first, then workouts of followed creators.
Future<String?> pickWorkout(BuildContext context, {required String title, String? except}) {
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
          'Treninzi čekaju. Posle pauze nastavljaš tačno ${context.store.profile?.says('gde si stao', 'gde si stala', 'odakle je stalo') ?? 'odakle je stalo'}, i niz se ne prekida.',
        ),
        gapS,
        ClButton(label: 'Uzmi pauzu', expand: true, onPressed: () => Navigator.of(context).pop(_days)),
      ],
    );
  }
}

/// The day's own exercise list: swap, remove, add, more or fewer sets.
/// Saved for this day only; the program stays the same. Pops true on save.
class _EditDaySheet extends StatefulWidget {
  const _EditDaySheet({required this.day});

  final DateTime day;

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
        ClButton(label: 'Dodaj vežbu', variant: ClButtonVariant.text, icon: ClIcons.add, onPressed: _add),
        gapS,
        ClButton(
          label: 'Sačuvaj za ovaj dan',
          expand: true,
          onPressed: () {
            store.editDayExercises(widget.day, _list);
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}
