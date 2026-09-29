import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';

/// Proof of the workout: praise for showing up, volume, records, the
/// creator's message. Also the history detail view. Light theme.
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.sessionId, this.justFinished = false});

  final String sessionId;
  final bool justFinished;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final s = store.sessionById(sessionId);
    if (s == null) {
      return AppScreen(
        topBar: const ClTopBar(),
        children: const [
          ClEmptyState(title: 'Nema treninga.', message: 'Ovaj trening više nije u istoriji.'),
        ],
      );
    }
    final date = s.finishedAt ?? s.startedAt;
    final label = justFinished
        ? [
            'Trening završen',
            formatDuration(s.duration),
            if (store.streak > 0) 'Niz ${store.streak} ned.',
          ].join(' · ')
        : '${weekdayName(date)} ${formatDate(date)} · ${formatDuration(s.duration)}';
    final message = s.finishMessage.isNotEmpty
        ? s.finishMessage
        : (store.nextWorkout == null
              ? 'Vidimo se na sledećem treningu.'
              : 'Sledeće je ${store.nextWorkout!.name}. Isti ritam.');

    return AppScreen(
      topBar: ClTopBar(
        label: justFinished ? null : s.workoutName,
        backLabel: justFinished ? 'Zatvori' : 'Nazad',
      ),
      bottom: justFinished
          ? ClButton(
              label: 'Gotovo',
              variant: ClButtonVariant.ink,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      children: [
        ClSummary(
          label: label,
          headline: justFinished ? 'Pojavio si se.' : s.workoutName,
          stats: [
            ClStat(label: 'Volumen', value: formatNumber(s.volume, maxDecimals: 0), unit: 'kg'),
            ClStat(label: 'Rekordi', value: '${s.prCount}', unit: 'PR', highlight: s.prCount > 0),
          ],
          exercises: [
            for (final e in s.exercises) ClSummaryExercise(name: e.name, detail: _detail(e), isPr: e.hasPr),
          ],
          creatorName: s.creatorName,
          creatorMessage: message,
        ),
      ],
    );
  }

  static String _detail(SessionExercise e) {
    final top = topSet(e);
    final sets = countLabel(e.doneSets.length, 'set', 'seta', 'setova');
    return top == null ? sets : '$sets · najbolji ${setLabel(top)}';
  }
}
