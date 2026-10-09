import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'exercise_media.dart';
import 'subscribe_sheet.dart';

/// One exercise: the creator's cue, the user's record and recent sets.
class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final e = store.exercisesById[exerciseId];
    if (e == null) {
      return AppScreen(
        topBar: const ClTopBar(),
        children: const [ClEmptyState(title: 'Nema vežbe.', message: 'Trener je uklonio ovu vežbu.')],
      );
    }
    final cl = context.cl;
    final c = store.creator(e.creatorId);
    final locked = !store.canAccess(e.visibility, e.creatorId);
    final history = [
      for (final s in store.history)
        for (final x in s.exercises.where((x) => x.exerciseId == e.id)) (session: s, exercise: x),
    ];
    final best = bestScore(store.sessions, e.id);
    SetLog? bestSet;
    for (final h in history) {
      for (final s in h.exercise.doneSets) {
        if (setScore(s) == best) bestSet ??= s;
      }
    }

    return AppScreen(
      safeTop: false,
      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s4, ClSpace.s4, ClSpace.s12),
      collapsed: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.clText.bodyStrong),
      // A clip under the status bar: light text on it.
      header: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SizedBox(
          height: 320,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(ClRadius.lg)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ExerciseMedia(exercise: e),
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: ClIconButton.onMedia(
                      icon: ClIcons.back,
                      semanticLabel: 'Nazad',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      children: [
        ClScreenTitle(label: '${e.muscle.label} · ${e.equipmentLabel}', title: e.name),
        gapS,
        if (c != null) ClCreatorLine(name: c.name, image: photoOf(c.photo), trailing: e.visibility.label),
        if (locked) ...[
          gapS,
          const ClNotice('Napomene i video su za pretplatnike.'),
          gapS,
          if (c != null)
            ClButton(
              label: 'Pretplati se',
              variant: ClButtonVariant.pop,
              expand: true,
              onPressed: () => showSubscribeSheet(context, c),
            ),
        ] else if (e.note.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s3),
          Text(e.note, style: cl.text.body),
        ],
        if (!canDo(e, store.equipment)) ...[
          gapS,
          const Align(
            alignment: Alignment.centerLeft,
            child: ClTag('Nemaš opremu', variant: ClTagVariant.danger),
          ),
        ],
        gap,
        ClStatBar(
          stats: [
            ClStat(label: 'Najbolji set', value: bestSet == null ? '—' : setLabel(bestSet)),
            ClStat(
              label: e.isBodyweight ? 'Najviše pon.' : 'Procenjeni 1RM',
              value: best == null ? '—' : formatNumber(best, maxDecimals: e.isBodyweight ? 0 : 1),
              unit: best == null || e.isBodyweight ? null : 'kg',
              highlight: best != null,
            ),
            ClStat(label: 'Urađeno', value: '${history.length}', unit: '×'),
          ],
        ),
        gap,
        const ClSectionHeader(label: 'Istorija'),
        if (history.isEmpty)
          const ClNotice('Još nisi radio ovu vežbu. Posle prvog treninga ovde su tvoji setovi.'),
        for (final h in history.take(8))
          ClListRow(
            title: formatDate(h.session.finishedAt!),
            meta: h.exercise.doneSets.map(setLabel).join(' · '),
            trailing: h.exercise.hasPr ? const ClTag.pr() : null,
          ),
      ],
    );
  }
}
