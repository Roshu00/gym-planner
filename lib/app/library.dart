import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'exercise_detail.dart';
import 'program_detail.dart';
import 'workout_detail.dart';

/// Programs, workouts and exercises from followed creators. Shown as the
/// "Biblioteka" tab of Otkrij.
class LibraryContent extends StatefulWidget {
  const LibraryContent({super.key, required this.onDiscover});

  /// Switches to the "Otkrij" tab.
  final VoidCallback onDiscover;

  @override
  State<LibraryContent> createState() => _LibraryContentState();
}

class _LibraryContentState extends State<LibraryContent> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (creators.isEmpty)
          ClEmptyState(
            title: 'Prazna polica.',
            message: 'Zaprati trenera ili se pretplati i ovde su njegovi programi, treninzi i vežbe.',
            action: ClButton(label: 'Otkrij trenere', expand: true, onPressed: widget.onDiscover),
          )
        else ...[
          Text(
            '${countLabel(creators.length, 'trener', 'trenera', 'trenera')} koje pratiš'.toUpperCase(),
            style: context.clText.label,
          ),
          const SizedBox(height: ClSpace.s2),
          Wrap(
            spacing: ClSpace.s2,
            children: [
              for (final (i, name) in ['Programi', 'Treninzi', 'Vežbe'].indexed)
                ClFilter(
                  label: '$name ${counts[i]}',
                  selected: _tab == i,
                  onChanged: (_) => setState(() => _tab = i),
                ),
            ],
          ),
          const SizedBox(height: ClSpace.s2),
          const ClDivider(),
          ...rows,
        ],
      ],
    );
  }
}
