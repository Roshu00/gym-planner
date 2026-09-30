import 'package:flutter/material.dart';

import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'shell.dart';
import 'swap_sheet.dart';

/// The follower's copy of a program: order, next workout, exercise swaps.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final plan = store.plan;
    final cl = context.cl;
    if (plan == null) {
      return AppScreen(
        topBar: const ClTopBar(label: 'Moj plan'),
        children: [
          ClEmptyState(
            title: 'Nema plana.',
            message: 'Izaberi program trenera i on postaje tvoj plan.',
            action: ClButton(
              label: 'Otkrij programe',
              expand: true,
              onPressed: () => HomeShell.goTo(context, AppTab.discover),
            ),
          ),
        ],
      );
    }
    final c = store.creator(plan.creatorId);
    final nextIndex = plan.nextIndex % plan.workoutIds.length;

    return AppScreen(
      topBar: const ClTopBar(label: 'Moj plan'),
      children: [
        ClScreenTitle(label: '${c?.name ?? ''} · od ${formatDate(plan.startedAt)}', title: plan.name),
        const SizedBox(height: ClSpace.s6),
        ClStatBar(
          stats: [
            ClStat(label: 'Nedelja', value: '${plan.currentWeek}/${plan.weeks}', highlight: true),
            ClStat(label: 'Urađeno', value: '${plan.completed}'),
            ClStat(label: 'Zamene', value: '${plan.swaps.length}'),
          ],
          segments: ClSegmentBar(total: plan.weeks, done: plan.currentWeek - 1),
        ),
        gapS,
        const ClNotice('Plan ne zavisi od datuma. Sledeći trening te čeka dok ga ne uradiš.'),
        gap,
        const ClSectionHeader(label: 'Redosled'),
        for (final (i, id) in plan.workoutIds.indexed)
          if (store.workoutsById[id] case final w?)
            ClListRow(
              leading: SizedBox(
                width: 24,
                child: Text(
                  '${i + 1}'.padLeft(2, '0'),
                  style: cl.text.data.copyWith(color: i == nextIndex ? cl.colors.ink : cl.colors.inkMuted),
                ),
              ),
              title: w.name,
              meta: workoutMeta(w),
              tags: [
                if (i == nextIndex) const ClTag('Sledeći'),
                if (w.exercises.any((we) => plan.swaps.containsKey(we.exerciseId)))
                  ClTag(
                    countLabel(
                      w.exercises.where((we) => plan.swaps.containsKey(we.exerciseId)).length,
                      'zamena',
                      'zamene',
                      'zamena',
                    ),
                  ),
              ],
              onPressed: () => pushScreen(context, PlanWorkoutScreen(index: i)),
            ),
        gap,
        Align(
          alignment: Alignment.centerLeft,
          child: ClButton(
            label: 'Napusti program',
            variant: ClButtonVariant.danger,
            onPressed: () async {
              final ok = await confirmClSheet(
                context,
                title: 'Napusti program?',
                message: 'Plan se briše. Istorija treninga i rekordi ostaju.',
                confirmLabel: 'Napusti program',
                danger: true,
              );
              if (ok && context.mounted) {
                context.readStore.leavePlan();
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ],
    );
  }
}

/// One workout inside the plan: swap exercises, make it the next one.
class PlanWorkoutScreen extends StatelessWidget {
  const PlanWorkoutScreen({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final plan = store.plan;
    final w = plan == null || index >= plan.workoutIds.length
        ? null
        : store.workoutsById[plan.workoutIds[index]];
    if (plan == null || w == null) {
      return AppScreen(
        topBar: const ClTopBar(),
        children: const [ClEmptyState(title: 'Nema treninga.', message: 'Ovaj trening više nije u planu.')],
      );
    }
    final cl = context.cl;
    final isNext = plan.nextIndex % plan.workoutIds.length == index;

    return AppScreen(
      topBar: ClTopBar(label: '${plan.name} · ${index + 1} / ${plan.workoutIds.length}'),
      bottom: isNext
          ? null
          : ClButton(
              label: 'Postavi kao sledeći',
              variant: ClButtonVariant.secondary,
              expand: true,
              onPressed: () {
                context.readStore.setNextWorkout(index);
                Navigator.of(context).pop();
              },
            ),
      children: [
        ClScreenTitle(label: workoutMeta(w), title: w.name),
        if (isNext) ...[const SizedBox(height: ClSpace.s2), const ClNotice('Ovo je tvoj sledeći trening.')],
        gap,
        const ClSectionHeader(label: 'Vežbe · zameni šta ne možeš da radiš'),
        for (final we in w.exercises)
          if ((store.exercisesById[we.exerciseId], store.resolveExercise(we.exerciseId)) case (
            final original?,
            final e?,
          ))
            ClListRow(
              title: e.name,
              meta: [
                if (e.id != original.id) 'Zamena za ${original.name}',
                prescription(we.target, we.rir, we.restSeconds),
              ].join(' · '),
              tags: [
                if (!canDo(e, store.equipment)) const ClTag('Nemaš opremu', variant: ClTagVariant.danger),
              ],
              trailing: ClIconButton(
                icon: ClIcons.swap,
                semanticLabel: 'Zameni ${e.name}',
                onPressed: () async {
                  final id = await showSwapSheet(context, e, originalId: original.id);
                  if (id != null && context.mounted) context.readStore.setPlanSwap(original.id, id);
                },
              ),
            ),
        gapS,
        Text(
          'Zamena važi za svaki sledeći put kad radiš ovaj trening. Urađeni treninzi ostaju tačni.',
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
      ],
    );
  }
}
