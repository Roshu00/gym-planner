import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'creator_profile.dart';
import 'library.dart';
import 'plan_finder.dart';
import 'program_detail.dart';

/// Creators and their programs. Filters combine across groups.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  Set<String> _filters = {};
  int _section = 0;

  static final _groups = <List<(String, bool Function(Program))>>[
    [for (final p in Place.values) (p.label, (x) => x.place == p)],
    [for (final e in Experience.values) (e.label, (x) => x.level == e)],
    [
      for (final g in [Goal.strength, Goal.muscle, Goal.general]) (g.label, (x) => x.goal == g),
    ],
  ];

  bool _matches(Program p) {
    for (final group in _groups) {
      final active = group.where((f) => _filters.contains(f.$1));
      if (active.isNotEmpty && !active.any((f) => f.$2(p))) return false;
    }
    return true;
  }

  Future<void> _openFilters() => showClSheet<void>(
    context,
    title: 'Filteri',
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: ClSpace.s2,
            children: [
              for (final group in _groups)
                for (final (label, _) in group)
                  ClFilter(
                    label: label,
                    selected: _filters.contains(label),
                    onChanged: (on) {
                      setState(() => _filters = on ? {..._filters, label} : ({..._filters}..remove(label)));
                      setSheet(() {});
                    },
                  ),
            ],
          ),
          gapS,
          ClButton(label: 'Prikaži', expand: true, onPressed: () => Navigator.of(context).pop()),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final programs = store.allPrograms.where((p) => p.workoutIds.isNotEmpty && _matches(p)).toList();
    final creatorIds = programs.map((p) => p.creatorId).toSet();
    final creators = store.creators.where((c) => creatorIds.contains(c.id)).toList()
      // Creators the user already follows come first.
      ..sort((a, b) {
        final followed = store.isFollowing(b.id).toString().compareTo(store.isFollowing(a.id).toString());
        return followed != 0 ? followed : b.followers.compareTo(a.followers);
      });

    final header = [
      const SizedBox(height: ClSpace.s4),
      const ClScreenTitle(label: 'Treneri i programi', title: 'Otkrij', large: true),
      gapS,
      ClTabs(
        tabs: const ['Otkrij', 'Biblioteka'],
        selected: _section,
        onChanged: (i) => setState(() => _section = i),
      ),
      gapS,
    ];
    if (_section == 1) {
      return AppScreen(
        children: [
          ...header,
          LibraryContent(onDiscover: () => setState(() => _section = 0)),
        ],
      );
    }

    return AppScreen(
      children: [
        ...header,
        Row(
          children: [
            Expanded(
              child: ClButton(
                label: 'Pronađi plan za sebe',
                icon: ClIcons.find,
                expand: true,
                onPressed: () => pushScreen(context, const PlanFinderScreen()),
              ),
            ),
            const SizedBox(width: ClSpace.s2),
            ClButton(
              label: _filters.isEmpty ? 'Filteri' : 'Filteri · ${_filters.length}',
              variant: ClButtonVariant.secondary,
              onPressed: _openFilters,
            ),
          ],
        ),
        if (_filters.isNotEmpty) ...[
          const SizedBox(height: ClSpace.s2),
          Wrap(
            spacing: ClSpace.s2,
            children: [
              for (final f in _filters)
                ClFilter(
                  label: f,
                  selected: true,
                  onChanged: (_) => setState(() => _filters = {..._filters}..remove(f)),
                ),
            ],
          ),
        ],
        gap,
        ClSectionHeader(
          label: 'Treneri',
          trailing: Text('${creators.length}', style: context.clText.label),
        ),
        for (final c in creators)
          ClCreatorRow(
            status: followStatus(store, c.id),
            name: c.name,
            handle: '@${c.handle} · ${c.tagline}',
            followers: formatCompact(c.followers),
            onPressed: () => pushScreen(context, CreatorProfileScreen(creatorId: c.id), theme: ClTheme.light),
          ),
        gap,
        ClSectionHeader(
          label: 'Programi',
          trailing: Text('${programs.length}', style: context.clText.label),
        ),
        if (programs.isEmpty)
          const ClNotice('Nijedan program ne odgovara ovim filterima.')
        else
          for (final p in programs) ...[ProgramTile(program: p), const SizedBox(height: ClSpace.s8)],
      ],
    );
  }
}

/// A program as a magazine cover, wired to its detail screen.
class ProgramTile extends StatelessWidget {
  const ProgramTile({super.key, required this.program});

  final Program program;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final c = store.creator(program.creatorId);
    final fit = store.fitOf(program);
    return ClProgramCard(
      title: program.name,
      color: context.clColors.popFor(program.id),
      meta: programMeta(program),
      creatorName: c?.name ?? '',
      followers: followersLabel(c?.followers ?? 0),
      tags: [
        program.level.label,
        program.place.label,
        if (fit.total > 0 && fit.doable < fit.total) 'Oprema ${(fit.doable * 100 / fit.total).round()}%',
      ],
      locked: !store.canAccess(program.visibility, program.creatorId),
      onPressed: () => pushScreen(context, ProgramDetailScreen(programId: program.id)),
    );
  }
}
