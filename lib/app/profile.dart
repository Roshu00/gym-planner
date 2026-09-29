import 'package:flutter/material.dart';

import '../config.dart';
import '../data/app_store.dart';
import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'auth_screen.dart';
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
        const _DataSection(),
      ],
    );
  }
}

/// Local mode: data lives on the device. Cloud mode: account, sync status,
/// saving a guest account, signing out.
class _DataSection extends StatelessWidget {
  const _DataSection();

  Future<void> _signOut(BuildContext context, AppStore store) async {
    final guest = store.account?.isGuest ?? false;
    final pending = store.pendingChanges;
    final ok = await confirmClSheet(
      context,
      title: 'Odjavi se?',
      message: [
        if (guest) 'Gost nalog se ne može vratiti. Sačuvaj nalog da ne izgubiš istoriju.',
        if (pending > 0)
          '${countLabel(pending, 'izmena još nije poslata', 'izmene još nisu poslate', 'izmena još nije poslato')} na server.',
        if (!guest && pending == 0) 'Tvoji podaci ostaju na nalogu. Prijavi se istim emailom da ih vratiš.',
      ].join(' '),
      confirmLabel: 'Odjavi se',
      danger: guest || pending > 0,
    );
    if (!ok || !context.mounted) return;
    await store.clearDeviceCache();
    await store.auth!.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final muted = cl.text.body.copyWith(color: cl.colors.inkMuted);
    final account = store.account;

    final Widget status;
    if (!store.isCloud) {
      status = Text(
        'Podaci su sačuvani na ovom uređaju. $appName radi u lokalnom demo režimu.',
        style: muted,
      );
    } else if (store.pendingChanges > 0 || store.syncError != null) {
      status = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (store.syncError != null) ClNotice(store.syncError!, danger: true),
          if (store.pendingChanges > 0)
            ClNotice(
              '${countLabel(store.pendingChanges, 'izmena čeka', 'izmene čekaju', 'izmena čeka')} slanje. '
              'Trening radi i bez interneta.',
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              label: 'Pošalji ponovo',
              variant: ClButtonVariant.text,
              onPressed: store.retrySync,
            ),
          ),
        ],
      );
    } else {
      status = Text('Sve je sačuvano na nalogu.', style: muted);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSectionHeader(label: store.isCloud ? 'Nalog' : 'Podaci'),
        if (account != null) ...[
          Text(account.isGuest ? 'Gost' : (account.email ?? ''), style: cl.text.bodyStrong),
          const SizedBox(height: ClSpace.s1),
          if (account.isGuest) ...[
            Text('Podaci su vezani za ovaj telefon dok ne sačuvaš nalog.', style: muted),
            gapS,
            ClButton(
              label: 'Sačuvaj nalog',
              variant: ClButtonVariant.secondary,
              expand: true,
              onPressed: () => pushScreen(context, AuthScreen(auth: store.auth!, saveAccount: true)),
            ),
            gapS,
          ],
        ],
        status,
        gapS,
        Wrap(
          spacing: ClSpace.s3,
          runSpacing: ClSpace.s3,
          children: [
            if (store.isCloud && store.auth != null)
              ClButton(
                label: 'Odjavi se',
                variant: ClButtonVariant.secondary,
                onPressed: () => _signOut(context, store),
              ),
            ClButton(
              label: 'Obriši moje podatke',
              variant: ClButtonVariant.danger,
              onPressed: () async {
                final ok = await confirmClSheet(
                  context,
                  title: 'Obriši sve?',
                  message: store.isCloud
                      ? 'Profil, plan, pretplate, profil trenera i cela istorija treninga se brišu sa naloga i ovog uređaja.'
                      : 'Profil, plan, pretplate i cela istorija treninga se brišu sa ovog uređaja.',
                  confirmLabel: 'Obriši sve',
                  danger: true,
                );
                if (ok && context.mounted) await context.readStore.resetAll();
              },
            ),
          ],
        ),
      ],
    );
  }
}
