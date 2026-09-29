import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'plan_finder.dart';
import 'plan_screen.dart';
import 'shell.dart';
import 'workout_session.dart';

/// Every morning: the creator's photo, today's workout, the week streak,
/// one button. Dark theme.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final plan = store.plan;
    final next = store.nextWorkout;
    final active = store.active;

    final stats = ClStatBar(
      stats: [
        ClStat(label: 'Niz', value: '${store.streak}', unit: 'ned.'),
        ClStat(
          label: 'Ova nedelja',
          value: store.weeklyGoal == 0 ? '${store.thisWeek}' : '${store.thisWeek}/${store.weeklyGoal}',
          highlight: true,
        ),
        ClStat(
          label: 'Trajanje',
          value: next == null ? '—' : '${next.estimatedMinutes}',
          unit: next == null ? null : 'min',
        ),
      ],
      segments: store.weeklyGoal == 0
          ? null
          : ClSegmentBar(total: store.weeklyGoal, done: store.thisWeek.clamp(0, store.weeklyGoal)),
    );

    if (plan == null || next == null) {
      return AppScreen(
        children: [
          const SizedBox(height: ClSpace.s6),
          ClScreenTitle(
            label: 'Zdravo, ${store.profile?.name ?? ''}',
            title: store.sessions.isEmpty ? 'Izaberi trenera.' : 'Nova nedelja.',
          ),
          const SizedBox(height: ClSpace.s3),
          Text(
            'Pronađi trenera kog pratiš i uzmi njegov program. Aplikacija ti svaki dan kaže šta je sledeće.',
            style: context.clText.body.copyWith(color: context.clColors.inkMuted),
          ),
          gap,
          stats,
          gap,
          ClButton(
            label: 'Pronađi plan',
            icon: ClIcons.find,
            expand: true,
            onPressed: () => pushScreen(context, const PlanFinderScreen()),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              label: 'Ili otkrij trenere',
              variant: ClButtonVariant.text,
              onPressed: () => HomeShell.goTo(context, AppTab.discover),
            ),
          ),
        ],
      );
    }

    final creator = store.creator(plan.creatorId);
    return AppScreen(
      safeTop: false,
      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s4, ClSpace.s4, ClSpace.s8),
      header: ClWorkoutHero(
        title: active?.workoutName ?? next.name,
        label: '${creator?.name ?? ''} · Nedelja ${plan.currentWeek} / ${plan.weeks}',
        height: 420,
      ),
      bottom: ClButton.block(
        label: active == null ? 'Počni trening' : 'Nastavi trening',
        onPressed: () {
          store.startSession();
          pushScreen(context, const WorkoutSessionScreen());
        },
      ),
      children: [
        stats,
        gap,
        ClSectionHeader(
          label: '${plan.name} · ${countLabel(next.exercises.length, 'vežba', 'vežbe', 'vežbi')}',
          trailing: ClButton(
            label: 'Moj plan',
            variant: ClButtonVariant.text,
            onPressed: () => pushScreen(context, const PlanScreen()),
          ),
        ),
        for (final (i, we) in next.exercises.indexed)
          if (store.resolveExercise(we.exerciseId) case final e?)
            ClExerciseRow(
              index: i + 1,
              name: e.name,
              detail: _detail(we.target, previousSets(store.sessions, e.id).firstOrNull),
            ),
        if (active != null) ...[
          gapS,
          ClNotice(
            'Trening je započet ${formatDuration(store.now.difference(active.startedAt))} ranije. Nastavi gde si stao.',
          ),
        ],
      ],
    );
  }

  static String _detail(String target, SetLog? last) =>
      last == null ? target : '$target · Prošli put ${setLabel(last)}';
}
