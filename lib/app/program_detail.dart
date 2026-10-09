import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'creator_profile.dart';
import 'plan_screen.dart';
import 'shell.dart';
import 'subscribe_sheet.dart';
import 'workout_detail.dart';

/// Makes [programId] the user's plan, asking first when it replaces one,
/// then shows Today.
Future<void> startProgramFlow(BuildContext context, String programId) async {
  final store = context.readStore;
  final current = store.plan;
  if (current != null) {
    final ok = await confirmClSheet(
      context,
      title: 'Novi program?',
      message: 'Trenutni plan „${current.name}” se zamenjuje. Istorija treninga ostaje.',
      confirmLabel: 'Počni program',
    );
    if (!ok || !context.mounted) return;
  }
  store.startProgram(programId);
  HomeShell.goTo(context, AppTab.today);
}

/// A creator's program: what it is, how well it fits the user's equipment,
/// its workouts, and one action.
class ProgramDetailScreen extends StatelessWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final p = store.programsById[programId];
    if (p == null) {
      return AppScreen(
        topBar: const ClTopBar(),
        children: const [ClEmptyState(title: 'Nema programa.', message: 'Trener je uklonio ovaj program.')],
      );
    }
    final cl = context.cl;
    final c = store.creator(p.creatorId);
    final fit = store.fitOf(p);
    final locked = !store.canAccess(p.visibility, p.creatorId);
    final isCurrent = store.plan?.programId == p.id;
    final missing = fit.total - fit.doable;
    final workouts = p.workoutIds.map((id) => store.workoutsById[id]).nonNulls.toList();

    final Widget action;
    if (locked) {
      action = ClButton(
        label: 'Pretplati se',
        variant: ClButtonVariant.pop,
        expand: true,
        onPressed: c == null ? null : () => showSubscribeSheet(context, c),
      );
    } else if (isCurrent) {
      action = ClButton(
        label: 'Otvori plan',
        variant: ClButtonVariant.secondary,
        expand: true,
        onPressed: () => pushScreen(context, const PlanScreen()),
      );
    } else {
      action = ClButton.block(label: 'Počni program', onPressed: () => startProgramFlow(context, programId));
    }

    return AppScreen(
      safeTop: false,
      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s4, ClSpace.s4, ClSpace.s8),
      collapsed: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.clText.bodyStrong),
      header: ClWorkoutHero(
        title: p.name,
        image: photoOf(p.image),
        color: context.clColors.popFor(p.id),
        label: '${c?.name ?? ''} · ${programMeta(p)}',
        height: 300,
        topBar: Row(
          children: [
            ClIconButton.onMedia(
              icon: ClIcons.back,
              semanticLabel: 'Nazad',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
      bottom: action,
      children: [
        ClStatBar(
          stats: [
            ClStat(label: 'Nedelje', value: '${p.weeks}'),
            ClStat(label: 'Nedeljno', value: '${p.daysPerWeek}×'),
            ClStat(
              label: 'Tvoja oprema',
              value: fit.total == 0 ? '—' : '${(fit.doable * 100 / fit.total).round()}',
              unit: fit.total == 0 ? null : '%',
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s6),
        if (c != null)
          GestureDetector(
            onTap: () => pushScreen(context, CreatorProfileScreen(creatorId: c.id), theme: ClTheme.light),
            child: ClCreatorLine(
              name: c.name,
              image: photoOf(c.photo),
              trailing: followersLabel(c.followers),
            ),
          ),
        if (p.description.isNotEmpty) ...[gapS, Text(p.description, style: cl.text.body)],
        gapS,
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ClTag(p.level.label),
            ClTag(p.place.label),
            ClTag(p.goal.label),
            if (p.visibility == Audience.subscribers) const ClTag('Za pretplatnike'),
          ],
        ),
        if (missing > 0 && !locked) ...[
          gapS,
          ClNotice(
            '${countLabel(missing, 'vežba traži', 'vežbe traže', 'vežbi traži')} opremu koju nemaš. '
            'Plan ih menja vežbama koje možeš da radiš, a zamene menjaš u planu.',
          ),
        ],
        gap,
        ClSectionHeader(
          label: 'Treninzi · ${countLabel(workouts.length, 'trening', 'treninga', 'treninga')} u rotaciji',
        ),
        for (final (i, w) in workouts.indexed)
          ClListRow(
            leading: SizedBox(
              width: 24,
              child: Text(
                '${i + 1}'.padLeft(2, '0'),
                style: cl.text.data.copyWith(color: cl.colors.inkMuted),
              ),
            ),
            title: w.name,
            meta: workoutMeta(w),
            tags: [
              if (store.needsEquipmentSwap(w)) const ClTag('Zamena opreme', variant: ClTagVariant.danger),
            ],
            onPressed: () => pushScreen(context, WorkoutDetailScreen(workoutId: w.id)),
          ),
      ],
    );
  }
}
