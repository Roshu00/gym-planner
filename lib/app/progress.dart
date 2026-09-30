import 'package:flutter/material.dart';

import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'summary_screen.dart';

/// Numbers that prove discipline: streak, workouts, records, volume,
/// per-exercise progress and the full history.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? _exerciseId;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final history = store.history;

    final stats = ClStatBar(
      stats: [
        ClStat(label: 'Niz', value: '${store.streak}', unit: 'ned.'),
        ClStat(label: 'Treninzi', value: '${history.length}'),
        ClStat(
          label: 'Rekordi',
          value: '${totalRecords(history)}',
          unit: 'PR',
          highlight: totalRecords(history) > 0,
        ),
      ],
    );

    if (history.isEmpty) {
      return AppScreen(
        children: [
          const SizedBox(height: ClSpace.s4),
          const ClScreenTitle(label: 'Tvoji brojevi', title: 'Napredak', large: true),
          const SizedBox(height: ClSpace.s6),
          stats,
          gap,
          const ClEmptyState(
            title: 'Prvi trening.',
            message: 'Posle prvog treninga ovde su volumen, rekordi i sva istorija.',
          ),
        ],
      );
    }

    // Exercises by how often they were done, most frequent first.
    final frequency = <String, ({String name, int count, bool bodyweight})>{};
    for (final s in history) {
      for (final e in s.exercises) {
        final f = frequency[e.exerciseId];
        frequency[e.exerciseId] = (name: e.name, count: (f?.count ?? 0) + 1, bodyweight: e.bodyweight);
      }
    }
    final top = frequency.entries.toList()..sort((a, b) => b.value.count.compareTo(a.value.count));
    final selected = frequency.containsKey(_exerciseId) ? _exerciseId! : top.first.key;
    final exerciseInfo = frequency[selected]!;
    final points = exerciseHistory(history, selected);
    final volume = weeklyVolume(history, store.now, 8);
    final bestWeek = volume.indexed.reduce((a, b) => b.$2.volume > a.$2.volume ? b : a).$1;

    return AppScreen(
      children: [
        const SizedBox(height: ClSpace.s4),
        const ClScreenTitle(label: 'Tvoji brojevi', title: 'Napredak', large: true),
        const SizedBox(height: ClSpace.s6),
        stats,
        gap,
        ClLineChart(
          title: 'Nedeljni volumen · najbolja nedelja',
          unit: 'kg',
          highlightIndex: bestWeek,
          height: 150,
          points: [for (final v in volume) ClChartPoint(formatDate(v.week, now: store.now), v.volume)],
        ),
        gap,
        ClSectionHeader(
          label: 'Vežba · ${exerciseInfo.bodyweight ? 'najviše ponavljanja' : 'procenjeni 1RM'}',
        ),
        Wrap(
          spacing: ClSpace.s2,
          children: [
            for (final e in top.take(6))
              ClFilter(
                label: e.value.name,
                selected: e.key == selected,
                onChanged: (_) => setState(() => _exerciseId = e.key),
              ),
          ],
        ),
        gapS,
        if (points.length < 2)
          ClNotice('Još jedan trening sa vežbom ${exerciseInfo.name} i ovde je grafikon.')
        else
          ClLineChart(
            title: exerciseInfo.name,
            unit: exerciseInfo.bodyweight ? 'pon.' : 'kg',
            height: 150,
            points: [
              for (final p in points.length > 8 ? points.sublist(points.length - 8) : points)
                ClChartPoint(formatDate(p.date, now: store.now), double.parse(p.score.toStringAsFixed(1))),
            ],
          ),
        gap,
        ClSectionHeader(
          label: 'Istorija',
          trailing: Text('${history.length}', style: context.clText.label),
        ),
        for (final s in history)
          ClListRow(
            title: s.workoutName,
            meta: '${sessionMeta(s)} · ${s.creatorName}',
            trailing: s.prCount > 0 ? const ClTag.pr() : null,
            onPressed: () => pushScreen(context, SummaryScreen(sessionId: s.id), theme: ClTheme.light),
          ),
      ],
    );
  }
}
