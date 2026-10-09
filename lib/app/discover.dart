import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'creator_profile.dart';
import 'plan_finder.dart';
import 'program_detail.dart';

/// Creators and their programs. Search by name; filters combine across groups.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  Set<String> _filters = {};
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Case- and accent-insensitive: "jovanovic" finds "Jovanović".
  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll('č', 'c')
      .replaceAll('ć', 'c')
      .replaceAll('š', 's')
      .replaceAll('ž', 'z')
      .replaceAll('đ', 'dj');

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
    final query = _fold(_search.text.trim());
    bool found(String text) => query.isEmpty || _fold(text).contains(query);
    bool creatorFound(String id) {
      final c = store.creator(id);
      return c != null && (found(c.name) || found(c.handle));
    }

    final programs = store.allPrograms
        .where((p) => p.workoutIds.isNotEmpty && _matches(p) && (found(p.name) || creatorFound(p.creatorId)))
        .toList();
    final withPrograms = store.allPrograms
        .where((p) => p.workoutIds.isNotEmpty)
        .map((p) => p.creatorId)
        .toSet();
    final filtered = programs.map((p) => p.creatorId).toSet();
    final creators =
        store.creators
            .where(
              (c) =>
                  withPrograms.contains(c.id) &&
                  (_filters.isEmpty || filtered.contains(c.id)) &&
                  (creatorFound(c.id) || filtered.contains(c.id)),
            )
            .toList()
          // Creators the user already follows come first.
          ..sort((a, b) {
            final followed = store.isFollowing(b.id).toString().compareTo(store.isFollowing(a.id).toString());
            return followed != 0 ? followed : b.followers.compareTo(a.followers);
          });

    return AppScreen(
      children: [
        const SizedBox(height: ClSpace.s4),
        const ClScreenTitle(label: 'Treneri i programi', title: 'Otkrij', large: true),
        gapS,
        ClTextField(
          hint: 'Pretraži trenere i programe',
          icon: ClIcons.search,
          controller: _search,
          onChanged: (_) => setState(() {}),
        ),
        gapS,
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
            image: photoOf(c.photo),
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
          ClNotice(
            query.isEmpty
                ? 'Nijedan program ne odgovara ovim filterima.'
                : 'Nema programa za „${_search.text.trim()}”.',
          )
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
      image: photoOf(program.image),
      creatorImage: photoOf(c?.photo),
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
