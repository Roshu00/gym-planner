import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'plan_finder.dart';
import 'plan_screen.dart';
import 'shell.dart';
import 'workout_session.dart';

/// Every morning: today's workout on a pop color block, the week on a second
/// block, the exercises, one button.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final c = cl.colors;
    final plan = store.plan;
    final next = store.nextWorkout;
    final active = store.active;
    final today = store.now;

    final workoutColor = next == null ? c.lime : c.popFor(next.id);
    final week = ClPopBlock(
      color: workoutColor == c.lilac ? c.peach : c.lilac,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  store.weeklyGoal == 0
                      ? '${countLabel(store.thisWeek, 'trening', 'treninga', 'treninga')} ove nedelje'
                      : '${store.thisWeek} od ${store.weeklyGoal} ove nedelje',
                  style: cl.text.bodyStrong.copyWith(fontSize: 17),
                ),
              ),
              Text('Niz ${store.streak} ned.', style: cl.text.bodyStrong.copyWith(fontSize: 13)),
            ],
          ),
          if (store.weeklyGoal > 0) ...[
            const SizedBox(height: ClSpace.s3),
            ClSegmentBar(
              total: store.weeklyGoal,
              done: store.thisWeek.clamp(0, store.weeklyGoal),
              onPop: true,
            ),
          ],
        ],
      ),
    );

    final greeting = ClScreenTitle(
      label: '${weekdayName(today)}, ${formatDate(today, now: today)}',
      title: 'Zdravo, ${store.profile?.name.split(' ').first ?? ''}',
    );

    if (plan == null || next == null) {
      return AppScreen(
        children: [
          const SizedBox(height: ClSpace.s4),
          greeting,
          gapS,
          ClPopBlock(
            color: c.lime,
            sticker: const ClSticker('Korak 1'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(store.sessions.isEmpty ? 'Izaberi trenera.' : 'Nova nedelja.', style: cl.text.displayM),
                const SizedBox(height: ClSpace.s2),
                Text(
                  'Pronađi trenera kog pratiš i uzmi njegov program. Aplikacija ti svaki dan kaže šta je sledeće.',
                  style: cl.text.body,
                ),
                const SizedBox(height: ClSpace.s4),
                ClButton(
                  label: 'Pronađi plan',
                  icon: ClIcons.find,
                  expand: true,
                  onPressed: () => pushScreen(context, const PlanFinderScreen()),
                ),
              ],
            ),
          ),
          gapS,
          week,
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
    final title = active?.workoutName ?? next.name;
    return AppScreen(
      bottom: ClButton.block(
        label: active == null ? 'Počni trening' : 'Nastavi trening',
        onPressed: () {
          store.startSession();
          pushScreen(context, const WorkoutSessionScreen());
        },
      ),
      children: [
        const SizedBox(height: ClSpace.s4),
        greeting,
        gapS,
        ClPopBlock(
          color: workoutColor,
          sticker: ClSticker('Nedelja ${plan.currentWeek}/${plan.weeks}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Danas · ${creator?.name ?? ''}', style: cl.text.bodyStrong.copyWith(fontSize: 13)),
              const SizedBox(height: ClSpace.s1),
              Semantics(header: true, child: Text(title, maxLines: 2, style: cl.text.displayL)),
              const SizedBox(height: ClSpace.s1),
              Text(workoutMeta(next), style: cl.text.body),
              const SizedBox(height: ClSpace.s8),
            ],
          ),
        ),
        gapS,
        week,
        gap,
        ClSectionHeader(
          label: plan.name,
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
