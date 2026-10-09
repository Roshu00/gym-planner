import 'package:flutter/material.dart';

import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'exercise_detail.dart';
import 'subscribe_sheet.dart';
import 'workout_session.dart';

/// One workout from a creator's library. Can be done once, outside the plan.
class WorkoutDetailScreen extends StatelessWidget {
  const WorkoutDetailScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final w = store.workoutsById[workoutId];
    if (w == null) {
      return AppScreen(
        topBar: const ClTopBar(),
        children: const [ClEmptyState(title: 'Nema treninga.', message: 'Trener je uklonio ovaj trening.')],
      );
    }
    final cl = context.cl;
    final c = store.creator(w.creatorId);
    final locked = !store.canAccess(w.visibility, w.creatorId);
    final active = store.active;

    final Widget action;
    if (locked) {
      action = ClButton(
        label: 'Pretplati se',
        variant: ClButtonVariant.pop,
        expand: true,
        onPressed: c == null ? null : () => showSubscribeSheet(context, c),
      );
    } else if (active != null) {
      action = ClButton.block(
        label: 'Nastavi trening',
        onPressed: () => pushScreen(context, const WorkoutSessionScreen()),
      );
    } else {
      action = ClButton.block(
        label: 'Počni trening',
        onPressed: () {
          context.readStore.startSession(workoutId: w.id);
          pushScreen(context, const WorkoutSessionScreen(), replace: true);
        },
      );
    }

    return AppScreen(
      safeTop: false,
      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s4, ClSpace.s4, ClSpace.s8),
      collapsed: Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.clText.bodyStrong),
      header: ClWorkoutHero(
        title: w.name,
        image: photoOf(w.image),
        color: context.clColors.popFor(w.id),
        label: '${c?.name ?? ''} · ${workoutMeta(w)}',
        height: 320,
        compact: true,
        topBar: Row(
          children: [
            ClIconButton.onMedia(
              icon: ClIcons.back,
              semanticLabel: 'Nazad',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
      bottom: action,
      children: [
        ClStatBar(
          stats: [
            ClStat(label: 'Vežbe', value: '${w.exercises.length}'),
            ClStat(label: 'Setovi', value: '${w.totalSets}'),
            ClStat(label: 'Trajanje', value: '${w.estimatedMinutes}', unit: 'min'),
          ],
        ),
        if (active != null && !locked) ...[
          gapS,
          ClNotice('Već imaš započet trening „${active.workoutName}”. Završi ga pre novog.'),
        ],
        gap,
        const ClSectionHeader(label: 'Vežbe'),
        for (final (i, we) in w.exercises.indexed)
          if (store.exercisesById[we.exerciseId] case final e?)
            ClListRow(
              leading: SizedBox(
                width: 24,
                child: Text(
                  '${i + 1}'.padLeft(2, '0'),
                  style: cl.text.data.copyWith(color: cl.colors.inkMuted),
                ),
              ),
              title: e.name,
              meta: prescription(we.target, we.rir, we.restSeconds),
              tags: [
                if (!canDo(e, store.equipment)) const ClTag('Nemaš opremu', variant: ClTagVariant.danger),
              ],
              onPressed: () => pushScreen(context, ExerciseDetailScreen(exerciseId: e.id)),
            ),
      ],
    );
  }
}
