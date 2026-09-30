import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'program_detail.dart';

/// "Find a plan for me": goal, level, place and days per week, then
/// programs ranked by how well they fit, with the reasons.
class PlanFinderScreen extends StatefulWidget {
  const PlanFinderScreen({super.key});

  @override
  State<PlanFinderScreen> createState() => _PlanFinderScreenState();
}

class _PlanFinderScreenState extends State<PlanFinderScreen> {
  late final _profile = context.readStore.profile;
  late Goal _goal = _profile?.goal ?? Goal.general;
  late Experience _level = _profile?.experience ?? Experience.beginner;
  late Place _place = _profile?.place ?? Place.gym;
  int _days = 3;
  bool _searched = false;

  Widget _choice<T>(
    String label,
    List<T> values,
    T selected,
    String Function(T) name,
    ValueChanged<T> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: context.clText.label),
      const SizedBox(height: ClSpace.s1),
      Wrap(
        spacing: ClSpace.s2,
        children: [
          for (final v in values)
            ClFilter(
              label: name(v),
              selected: v == selected,
              onChanged: (_) => setState(() {
                onChanged(v);
                _searched = false;
              }),
            ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final criteria = (goal: _goal, level: _level, place: _place, daysPerWeek: _days);
    final results = [
      for (final p in store.allPrograms.where((p) => p.workoutIds.isNotEmpty))
        (program: p, match: matchProgram(p, criteria, store.fitOf(p))),
    ]..sort((a, b) => b.match.score.compareTo(a.match.score));

    return AppScreen(
      topBar: const ClTopBar(label: 'Pronađi plan'),
      bottom: _searched
          ? null
          : ClButton.block(label: 'Pronađi', onPressed: () => setState(() => _searched = true)),
      children: [
        const ClScreenTitle(label: 'Četiri pitanja', title: 'Plan za tebe.'),
        const SizedBox(height: ClSpace.s6),
        _choice('Cilj', Goal.values, _goal, (g) => g.label, (g) => _goal = g),
        gapS,
        _choice('Nivo', Experience.values, _level, (e) => e.label, (e) => _level = e),
        gapS,
        _choice('Gde treniraš', Place.values, _place, (p) => p.label, (p) => _place = p),
        gapS,
        _choice('Dana nedeljno', const [2, 3, 4, 5, 6], _days, (d) => '$d×', (d) => _days = d),
        const SizedBox(height: ClSpace.s2),
        const ClNotice('Opremu uzimamo iz tvog profila.'),
        if (_searched) ...[
          gap,
          ClSectionHeader(label: 'Najbolje se uklapa · ${results.length}'),
          for (final r in results)
            ClListRow(
              title: r.program.name,
              meta: '${store.creator(r.program.creatorId)?.name ?? ''} · ${programMeta(r.program)}',
              tags: [
                for (final reason in r.match.reasons) ClTag(reason),
                if (!store.canAccess(r.program.visibility, r.program.creatorId))
                  const ClTag('Za pretplatnike'),
              ],
              leading: SizedBox(
                width: 52,
                child: Text(
                  '${r.match.score}%',
                  style: context.clText.data.copyWith(
                    color: r == results.first ? context.clColors.ink : context.clColors.inkMuted,
                  ),
                ),
              ),
              onPressed: () => pushScreen(context, ProgramDetailScreen(programId: r.program.id)),
            ),
        ],
      ],
    );
  }
}
