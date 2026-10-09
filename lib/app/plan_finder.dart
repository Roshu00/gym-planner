import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'program_detail.dart';

/// Programs ranked for the user's profile, best first. Nothing to fill in:
/// the answers from onboarding are already known.
List<({Program program, int score, List<String> reasons})> rankedPrograms(BuildContext context) {
  final store = context.store;
  final profile = store.profile;
  if (profile == null) return const [];
  final PlanCriteria criteria = (
    goal: profile.goal,
    level: profile.experience,
    place: profile.place,
    daysPerWeek: profile.daysPerWeek,
  );
  return [
    for (final p in store.allPrograms.where((p) => p.workoutIds.isNotEmpty))
      if (matchProgram(p, criteria, store.fitOf(p)) case final m)
        (program: p, score: m.score, reasons: m.reasons),
  ]..sort((a, b) => b.score.compareTo(a.score));
}

/// "Snaga · Početnik · Teretana · 3× nedeljno".
String criteriaLabel(UserProfile p) =>
    '${p.goal.label} · ${p.experience.label} · ${p.place.label} · ${p.daysPerWeek}× nedeljno';

/// The best program for the user: one recommendation, two alternatives and
/// one button. "Promeni" edits the answers in place.
class PlanFinderScreen extends StatelessWidget {
  const PlanFinderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final profile = store.profile;
    final ranked = rankedPrograms(context);
    if (profile == null || ranked.isEmpty) {
      return AppScreen(
        topBar: const ClTopBar(label: 'Tvoj plan'),
        children: const [
          ClEmptyState(title: 'Nema programa.', message: 'Treneri još nisu objavili programe.'),
        ],
      );
    }
    final best = ranked.first.program;
    return AppScreen(
      topBar: const ClTopBar(label: 'Tvoj plan'),
      bottom: PlanStartButton(program: best),
      children: [
        CriteriaRow(profile: profile),
        gap,
        PlanRecommendation(program: best, reasons: ranked.first.reasons),
        if (ranked.length > 1) ...[
          gap,
          ClSectionHeader(
            label: 'Još ${ranked.length > 2 ? 2 : 1} ${ranked.length > 2 ? 'opcije' : 'opcija'}',
          ),
          for (final r in ranked.skip(1).take(2))
            ClListRow(
              title: r.program.name,
              meta: '${store.creator(r.program.creatorId)?.name ?? ''} · ${programMeta(r.program)}',
              trailing: Icon(ClIcons.chevron, size: 18, color: context.clColors.inkMuted),
              onPressed: () => pushScreen(context, ProgramDetailScreen(programId: r.program.id)),
            ),
        ],
      ],
    );
  }
}

/// What the recommendation is based on, with "Promeni".
class CriteriaRow extends StatelessWidget {
  const CriteriaRow({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s3, ClSpace.s2, ClSpace.s3),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.sm),
        boxShadow: ClElevation.card(cl.colors.shadow),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Biramo prema', style: cl.text.label),
                const SizedBox(height: 2),
                Text(criteriaLabel(profile), style: cl.text.bodyStrong),
              ],
            ),
          ),
          ClButton(
            label: 'Promeni',
            variant: ClButtonVariant.text,
            onPressed: () =>
                showClSheet<void>(context, title: 'Tvoji odgovori', builder: (_) => const _CriteriaSheet()),
          ),
        ],
      ),
    );
  }
}

/// The one program to start with, as a big pop block.
class PlanRecommendation extends StatelessWidget {
  const PlanRecommendation({super.key, required this.program, this.reasons = const []});

  final Program program;
  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final creator = store.creator(program.creatorId);
    final locked = !store.canAccess(program.visibility, program.creatorId);
    return ClPhotoBlock(
      color: cl.colors.popFor(program.id),
      image: photoOf(program.image),
      height: 320,
      sticker: const ClSticker('Najbolje se uklapa'),
      avatar: ClAvatar(name: creator?.name ?? '', image: photoOf(creator?.photo), color: cl.colors.surface),
      label: creator?.name,
      title: program.name,
      meta: [programMeta(program), if (locked) 'za pretplatnike'].join(' · '),
      onPressed: () => pushScreen(context, ProgramDetailScreen(programId: program.id)),
    );
  }
}

/// "Počni ovaj plan", or the step before it when the program is locked or
/// already the plan.
class PlanStartButton extends StatelessWidget {
  const PlanStartButton({super.key, required this.program});

  final Program program;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    if (store.plan?.programId == program.id) {
      return ClButton.block(label: 'Ovo je tvoj plan', onPressed: null);
    }
    if (!store.canAccess(program.visibility, program.creatorId)) {
      return ClButton.block(
        label: 'Pogledaj program',
        onPressed: () => pushScreen(context, ProgramDetailScreen(programId: program.id)),
      );
    }
    return ClButton.block(label: 'Počni ovaj plan', onPressed: () => startProgramFlow(context, program.id));
  }
}

/// The onboarding answers, one list per question. Saved to the profile.
class _CriteriaSheet extends StatelessWidget {
  const _CriteriaSheet();

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final profile = store.profile!;
    void save(UserProfile p) => store.updateProfile(p);

    Widget group<T>(String label, List<(T, String)> options, T selected, UserProfile Function(T) apply) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: context.clText.label),
            const SizedBox(height: ClSpace.s2),
            for (final (value, title) in options)
              ClOptionRow(title: title, selected: value == selected, onPressed: () => save(apply(value))),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        group(
          'Cilj',
          [for (final g in Goal.values) (g, g.label)],
          profile.goal,
          (g) => profile.copyWith(goal: g),
        ),
        gapS,
        group(
          'Iskustvo',
          [for (final e in Experience.values) (e, e.label)],
          profile.experience,
          (e) => profile.copyWith(experience: e),
        ),
        gapS,
        group(
          'Gde treniraš',
          [for (final p in Place.values) (p, p.label)],
          profile.place,
          (p) => p == profile.place
              ? profile
              : profile.copyWith(place: p, equipment: {...(p == Place.gym ? Equipment.gym : Equipment.home)}),
        ),
        gapS,
        group(
          'Dana nedeljno',
          [(2, '2 dana'), (3, '3 dana'), (4, '4 dana'), (5, '5 i više')],
          profile.daysPerWeek.clamp(2, 5),
          (d) => profile.copyWith(daysPerWeek: d),
        ),
        gapS,
        ClButton(label: 'Gotovo', expand: true, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
