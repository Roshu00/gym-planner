import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'plan_finder.dart';
import 'plan_screen.dart';
import 'summary_screen.dart';
import 'workout_session.dart';

const _dayShort = ['Pon', 'Uto', 'Sre', 'Čet', 'Pet', 'Sub', 'Ned'];

/// History and planned days on one calendar. Today is selected on open.
/// Planned days are a forecast from the training days: a missed day moves
/// the next workout forward and never counts against the user.
class PlanTabScreen extends StatefulWidget {
  const PlanTabScreen({super.key});

  @override
  State<PlanTabScreen> createState() => _PlanTabScreenState();
}

class _PlanTabScreenState extends State<PlanTabScreen> {
  DateTime? _selected;
  DateTime? _month;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final today = dateOnly(store.now);
    final selected = _selected ?? today;
    final month = _month ?? DateTime(today.year, today.month);
    final plan = store.plan;

    final monthEnd = DateTime(month.year, month.month + 1, 0);
    final horizon = monthEnd.isAfter(today) ? monthEnd : today;
    final schedule = plan == null
        ? const <DateTime, String>{}
        : projectSchedule(plan, store.sessions, today, horizon.isAfter(selected) ? horizon : selected);

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

    final plannedId = schedule[selected];
    final isToday = selected == today;
    final daySessions = sessionsOn(store.sessions, selected);
    final canStart = isToday && plannedId != null && daySessions.isEmpty;

    return AppScreen(
      bottom: canStart
          ? ClButton.block(
              label: store.active == null ? 'Počni trening' : 'Nastavi trening',
              onPressed: () {
                store.startSession();
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
          onSelect: (d) => setState(() => _selected = d),
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
              '${weekdayName(selected)} ${formatDate(selected, now: store.now)}${isToday ? ' · Danas' : ''}',
        ),
        ..._dayDetail(context, selected, today, daySessions, plannedId, schedule, markFor(selected)),
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
    String? plannedId,
    Map<DateTime, String> schedule,
    ClDayMark mark,
  ) {
    final store = context.store;
    final cl = context.cl;
    final muted = cl.text.body.copyWith(color: cl.colors.inkMuted);

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

    final w = plannedId == null ? null : store.workoutsById[plannedId];
    if (w != null) {
      return [
        ClPopBlock(
          color: cl.colors.popFor(w.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day == today ? 'Danas' : 'Planirano'} · ${workoutMeta(w)}',
                style: cl.text.bodyStrong.copyWith(fontSize: 13),
              ),
              const SizedBox(height: ClSpace.s1),
              Text(w.name, style: cl.text.displayM),
            ],
          ),
        ),
        gapS,
        for (final (i, we) in w.exercises.indexed)
          if (store.resolveExercise(we.exerciseId) case final e?)
            ClExerciseRow(
              index: i + 1,
              name: e.name,
              detail: prescription(we.target, we.rir, we.restSeconds),
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

    if (mark == ClDayMark.rest) {
      final next = schedule.entries.where((e) => e.key.isAfter(day)).firstOrNull;
      final nextWorkout = next == null ? null : store.workoutsById[next.value];
      return [
        Text('Odmor.', style: cl.text.displayM),
        const SizedBox(height: ClSpace.s2),
        Text(
          [
            'Dan odmora ne prekida niz.',
            if (nextWorkout != null)
              'Sledeći je ${nextWorkout.name}, ${weekdayName(next!.key).toLowerCase()} ${formatDate(next.key, now: store.now)}',
          ].join(' '),
          style: muted,
        ),
      ];
    }
    return [Text('Tog dana nije bilo treninga.', style: muted)];
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
          'Program predviđa ${plan.daysPerWeek}× nedeljno. Propušten dan samo pomera sledeći trening, niz se ne prekida.',
        ),
      ],
    );
  }
}
