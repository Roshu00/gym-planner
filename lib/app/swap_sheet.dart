import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';

/// Lists alternatives for [exercise] the user can do and has access to.
/// Returns the chosen exercise id, or [originalId] when "Vrati original" is picked.
Future<String?> showSwapSheet(BuildContext context, Exercise exercise, {String? originalId}) {
  final store = context.readStore;
  final alts = store.substitutesFor(exercise);
  return showClSheet<String>(
    context,
    title: 'Zameni vežbu',
    label: '${exercise.name} · ${exercise.muscle.label}',
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (originalId != null && originalId != exercise.id)
          ClListRow(
            title: 'Vrati original',
            meta: store.exercisesById[originalId]?.name,
            onPressed: () => Navigator.of(context).pop(originalId),
          ),
        if (alts.isEmpty)
          ClNotice(
            'Nema zamene za ${exercise.muscle.label.toLowerCase()} sa opremom koju imaš. Dodaj opremu u profilu.',
          )
        else
          for (final e in alts)
            ClListRow(
              title: e.name,
              meta: '${e.equipmentLabel} · ${store.creator(e.creatorId)?.name ?? ''}',
              onPressed: () => Navigator.of(context).pop(e.id),
            ),
      ],
    ),
  );
}
