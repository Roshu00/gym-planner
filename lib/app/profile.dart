import 'package:flutter/material.dart';

import '../config.dart';
import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'creator_mode.dart';
import 'creator_profile.dart';
import 'plan_screen.dart';

/// The user: weekly goal, equipment, subscriptions, plan, creator mode.
/// Light theme.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final profile = store.profile;
    if (profile == null) return const SizedBox.shrink();
    final cl = context.cl;
    final subs = store.creators.where((c) => store.subscriptions.contains(c.id)).toList();

    return AppScreen(
      children: [
        const SizedBox(height: ClSpace.s4),
        ClScreenTitle(
          label: '${profile.goal.label} · ${profile.experience.label} · ${profile.place.label}',
          title: profile.name,
        ),
        const SizedBox(height: ClSpace.s6),
        ClStatBar(
          stats: [
            ClStat(label: 'Treninzi', value: '${store.sessions.length}'),
            ClStat(label: 'Niz', value: '${store.streak}', unit: 'ned.', highlight: true),
            ClStat(label: 'Pretplate', value: '${subs.length}'),
          ],
        ),
        gap,
        ClSectionHeader(label: 'Nedeljni cilj · ${store.thisWeek}/${profile.daysPerWeek} ove nedelje'),
        Wrap(
          spacing: ClSpace.s2,
          children: [
            for (final d in [2, 3, 4, 5, 6])
              ClFilter(
                label: '$d× nedeljno',
                selected: profile.daysPerWeek == d,
                onChanged: (_) => context.readStore.updateProfile(profile.copyWith(daysPerWeek: d)),
              ),
          ],
        ),
        gap,
        const ClSectionHeader(label: 'Oprema'),
        Wrap(
          spacing: ClSpace.s2,
          children: [
            for (final e in Equipment.values.where((e) => e != Equipment.bodyweight))
              ClFilter(
                label: e.label,
                selected: profile.equipment.contains(e),
                onChanged: (on) => context.readStore.updateProfile(
                  profile.copyWith(
                    equipment: on ? {...profile.equipment, e} : ({...profile.equipment}..remove(e)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        const ClNotice('Vežbe za koje nemaš opremu dobijaju zamenu u planu.'),
        gap,
        const ClSectionHeader(label: 'Plan'),
        if (store.plan == null)
          const ClNotice('Nemaš aktivan program.')
        else
          ClListRow(
            title: store.plan!.name,
            meta:
                '${store.creator(store.plan!.creatorId)?.name ?? ''} · Nedelja ${store.plan!.currentWeek} / ${store.plan!.weeks}',
            onPressed: () => pushScreen(context, const PlanScreen()),
          ),
        gap,
        ClSectionHeader(
          label: 'Pretplate',
          trailing: Text('${subs.length}', style: cl.text.label),
        ),
        if (subs.isEmpty) const ClNotice('Nemaš pretplate. Sadržaj za pretplatnike je zaključan.'),
        for (final c in subs)
          ClCreatorRow(
            name: c.name,
            handle: '${formatPrice(c.priceMonthly)} mesečno',
            followers: formatCompact(c.followers),
            onPressed: () => pushScreen(context, CreatorProfileScreen(creatorId: c.id), theme: ClTheme.light),
          ),
        gap,
        const ClSectionHeader(label: 'Za trenere'),
        ClListRow(
          title: 'Režim kreatora',
          meta: store.myCreator == null
              ? 'Objavi vežbe, treninge i programe'
              : '@${store.myCreator!.handle} · ${countLabel(store.myPrograms.length, 'program', 'programa', 'programa')}',
          onPressed: () => pushScreen(context, const CreatorModeScreen(), theme: ClTheme.light),
        ),
        gap,
        const ClSectionHeader(label: 'Podaci'),
        Text(
          'Podaci su sačuvani na ovom uređaju. $appName još nema nalog u oblaku.',
          style: cl.text.body.copyWith(color: cl.colors.inkMuted),
        ),
        gapS,
        Align(
          alignment: Alignment.centerLeft,
          child: ClButton(
            label: 'Obriši sve podatke',
            variant: ClButtonVariant.danger,
            onPressed: () async {
              final ok = await confirmClSheet(
                context,
                title: 'Obriši sve?',
                message: 'Profil, plan, pretplate i cela istorija treninga se brišu sa ovog uređaja.',
                confirmLabel: 'Obriši sve',
                danger: true,
              );
              if (ok && context.mounted) await context.readStore.resetAll();
            },
          ),
        ),
      ],
    );
  }
}
