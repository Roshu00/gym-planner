import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'exercise_detail.dart';
import 'program_detail.dart';
import 'shell.dart';
import 'workout_detail.dart';

/// Programs, workouts and exercises from followed creators. Dark theme.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final creators = store.libraryCreators;
    final ids = creators.map((c) => c.id).toSet();
    String by(String creatorId) => store.creator(creatorId)?.name ?? '';
    Widget lock(Audience a, String creatorId) => store.canAccess(a, creatorId)
        ? const SizedBox.shrink()
        : Icon(ClIcons.lock, size: 18, color: cl.colors.inkMuted);

    final programs = store.allPrograms
        .where((p) => ids.contains(p.creatorId) && p.workoutIds.isNotEmpty)
        .toList();
    final workouts = store.allWorkouts
        .where((w) => ids.contains(w.creatorId) && w.exercises.isNotEmpty)
        .toList();
    final exercises = store.allExercises.where((e) => ids.contains(e.creatorId)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final List<Widget> rows = switch (_tab) {
      0 => [
        for (final p in programs)
          ClListRow(
            title: p.name,
            meta: '${programMeta(p)} · ${by(p.creatorId)}',
            tags: [
              ClTag(p.level.label),
              ClTag(p.place.label),
              if (store.plan?.programId == p.id) const ClTag('Tvoj plan'),
            ],
            trailing: lock(p.visibility, p.creatorId),
            onPressed: () => pushScreen(context, ProgramDetailScreen(programId: p.id)),
          ),
      ],
      1 => [
        for (final w in workouts)
          ClListRow(
            title: w.name,
            meta: '${workoutMeta(w)} · ${by(w.creatorId)}',
            trailing: lock(w.visibility, w.creatorId),
            onPressed: () => pushScreen(context, WorkoutDetailScreen(workoutId: w.id)),
          ),
      ],
      _ => [
        for (final e in exercises)
          ClListRow(
            title: e.name,
            meta: '${e.muscle.label} · ${e.equipmentLabel} · ${by(e.creatorId)}',
            tags: [if (!canDo(e, store.equipment)) const ClTag('Nemaš opremu', variant: ClTagVariant.danger)],
            trailing: lock(e.visibility, e.creatorId),
            onPressed: () => pushScreen(context, ExerciseDetailScreen(exerciseId: e.id)),
          ),
      ],
    };
    final counts = [programs.length, workouts.length, exercises.length];

    return AppScreen(
      children: [
        const SizedBox(height: ClSpace.s4),
        ClScreenTitle(
          label: creators.isEmpty
              ? 'Od trenera koje pratiš'
              : '${countLabel(creators.length, 'trener', 'trenera', 'trenera')} · ${countLabel(exercises.length, 'vežba', 'vežbe', 'vežbi')}',
          title: 'Biblioteka',
        ),
        gapS,
        if (creators.isEmpty)
          ClEmptyState(
            title: 'Prazna polica.',
            message: 'Zaprati trenera ili se pretplati i ovde su njegovi programi, treninzi i vežbe.',
            action: ClButton(
              label: 'Otkrij trenere',
              expand: true,
              onPressed: () => HomeShell.goTo(context, AppTab.discover),
            ),
          )
        else ...[
          ClTabs(
            tabs: ['Programi ${counts[0]}', 'Treninzi ${counts[1]}', 'Vežbe ${counts[2]}'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          ...rows,
        ],
      ],
    );
  }
}
