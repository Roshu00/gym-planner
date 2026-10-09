import 'package:flutter/material.dart';

import '../config.dart';
import '../data/app_store.dart';
import '../domain/models.dart';
import '../ui/chalkline_ui.dart';
import 'auth_screen.dart';
import 'common.dart';
import 'creator_mode.dart';
import 'creator_profile.dart';
import 'plan_finder.dart';
import 'plan_screen.dart';
import 'progress.dart';
import 'shell.dart';

/// The user, like a social profile: who they are and their numbers
/// (progress, records, history). Everything else lives one tap away in
/// [SettingsScreen], behind the icon in the corner.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final profile = store.profile;
    if (profile == null) return const SizedBox.shrink();
    return AppScreen(
      children: [
        const SizedBox(height: ClSpace.s2),
        Row(
          children: [
            ClAvatar.profile(name: profile.name),
            const SizedBox(width: ClSpace.s4),
            Expanded(
              child: ClScreenTitle(
                title: profile.name,
                label: store.plan == null ? profile.goal.label : store.plan!.name,
              ),
            ),
            ClIconButton(
              icon: ClIcons.settings,
              semanticLabel: 'Podešavanja',
              onPressed: () => pushScreen(context, const SettingsScreen()),
            ),
          ],
        ),
        gap,
        const ProgressContent(),
      ],
    );
  }
}

/// The secondary things: plan, subscriptions, equipment, account, creator
/// mode. Each row opens a sheet or a screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final profile = store.profile;
    if (profile == null) return const SizedBox.shrink();
    final subs = store.creators.where((c) => store.subscriptions.contains(c.id)).toList();
    final plan = store.plan;
    final account = store.account;

    return AppScreen(
      topBar: const ClTopBar(label: 'Podešavanja'),
      children: [
        ClMenuGroup(
          title: 'Treniranje',
          children: [
            ClMenuRow(
              icon: ClIcons.plan,
              title: 'Moj plan',
              value: plan?.name ?? 'Nema',
              onPressed: () =>
                  pushScreen(context, plan == null ? const PlanFinderScreen() : const PlanScreen()),
            ),
            ClMenuRow(
              icon: ClIcons.subscriptions,
              title: 'Pretplate',
              value: subs.isEmpty ? 'Nema' : '${subs.length}',
              onPressed: () =>
                  showClSheet<void>(context, title: 'Pretplate', builder: (_) => const _SubscriptionsSheet()),
            ),
            ClMenuRow(
              icon: ClIcons.timer,
              title: 'Podsetnici',
              value: store.reminderSettings.enabled ? store.reminderSettings.timeLabel : 'Isključeni',
              onPressed: () =>
                  showClSheet<void>(context, title: 'Podsetnici', builder: (_) => const RemindersSheet()),
            ),
            ClMenuRow(
              icon: ClIcons.barbell,
              title: 'Oprema',
              value: countLabel(
                profile.equipment.where((e) => e != Equipment.bodyweight).length,
                'komad',
                'komada',
                'komada',
              ),
              onPressed: () =>
                  showClSheet<void>(context, title: 'Oprema', builder: (_) => const _EquipmentSheet()),
            ),
          ],
        ),
        gap,
        ClMenuGroup(
          title: 'Nalog',
          children: [
            ClMenuRow(
              icon: ClIcons.account,
              title: 'Pol',
              value: profile.gender.label,
              onPressed: () => showClSheet<void>(context, title: 'Pol', builder: (_) => const _GenderSheet()),
            ),
            ClMenuRow(
              icon: store.isCloud ? ClIcons.sync : ClIcons.settings,
              title: store.isCloud ? 'Nalog i sinhronizacija' : 'Podaci',
              value: !store.isCloud
                  ? 'Na uređaju'
                  : (store.pendingChanges > 0 || store.syncError != null)
                  ? 'Čeka slanje'
                  : (account?.isGuest ?? false)
                  ? 'Gost'
                  : null,
              onPressed: () => showClSheet<void>(
                context,
                title: store.isCloud ? 'Nalog' : 'Podaci',
                builder: (_) => const _DataSection(),
              ),
            ),
          ],
        ),
        gap,
        ClMenuGroup(
          title: 'Za trenere',
          children: [
            ClMenuRow(
              icon: ClIcons.creators,
              title: 'Režim kreatora',
              value: store.myCreator == null ? null : '@${store.myCreator!.handle}',
              onPressed: () => pushScreen(context, const CreatorModeScreen(), theme: ClTheme.light),
            ),
          ],
        ),
      ],
    );
  }
}

/// On or off, and at what time on training days.
class RemindersSheet extends StatefulWidget {
  const RemindersSheet({super.key});

  @override
  State<RemindersSheet> createState() => _RemindersSheetState();
}

class _RemindersSheetState extends State<RemindersSheet> {
  String? _error;

  static const _times = [(7, 0), (8, 0), (12, 0), (17, 0), (19, 0)];

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final r = store.reminderSettings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'U dane treninga, poruka sa imenom treninga i rečenicom trenera.',
          style: context.clText.body.copyWith(color: context.clColors.inkMuted),
        ),
        gapS,
        ClOptionRow(
          title: 'Uključeni',
          selected: r.enabled,
          onPressed: () async {
            final ok = await store.setRemindersEnabled(true);
            if (mounted) {
              setState(
                () => _error = ok
                    ? null
                    : 'Telefon ne dozvoljava obaveštenja. Uključi ih u podešavanjima telefona.',
              );
            }
          },
        ),
        ClOptionRow(
          title: 'Isključeni',
          selected: !r.enabled,
          onPressed: () => store.setRemindersEnabled(false),
        ),
        if (_error != null) ...[const SizedBox(height: ClSpace.s2), ClNotice(_error!, danger: true)],
        if (r.enabled) ...[
          gapS,
          Text('Vreme', style: context.clText.label),
          const SizedBox(height: ClSpace.s2),
          for (final (h, m) in _times)
            ClOptionRow(
              title: '$h:${m.toString().padLeft(2, '0')}',
              selected: r.hour == h && r.minute == m,
              onPressed: () => store.setReminderTime(h, m),
            ),
        ],
      ],
    );
  }
}

class _SubscriptionsSheet extends StatelessWidget {
  const _SubscriptionsSheet();

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final subs = store.creators.where((c) => store.subscriptions.contains(c.id)).toList();
    if (subs.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ClNotice(
            'Nemaš pretplate. Sadržaj za pretplatnike je zaključan dok se ne pretplatiš kod trenera.',
          ),
          gapS,
          ClButton(
            label: 'Otkrij trenere',
            variant: ClButtonVariant.secondary,
            expand: true,
            onPressed: () {
              Navigator.of(context).pop();
              HomeShell.goTo(context, AppTab.discover);
            },
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in subs)
          ClCreatorRow(
            status: ClFollowStatus.subscribed,
            name: c.name,
            image: photoOf(c.photo),
            handle: '${formatPrice(c.priceMonthly)} mesečno',
            followers: formatCompact(c.followers),
            onPressed: () => pushScreen(context, CreatorProfileScreen(creatorId: c.id), theme: ClTheme.light),
          ),
      ],
    );
  }
}

class _EquipmentSheet extends StatelessWidget {
  const _EquipmentSheet();

  @override
  Widget build(BuildContext context) {
    final profile = context.store.profile!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClNotice('Vežbe za koje nemaš opremu dobijaju zamenu u planu.'),
        gapS,
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
      ],
    );
  }
}

class _GenderSheet extends StatelessWidget {
  const _GenderSheet();

  @override
  Widget build(BuildContext context) {
    final profile = context.store.profile!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in Gender.values)
          ClOptionRow(
            title: g.label,
            selected: profile.gender == g,
            onPressed: () {
              context.readStore.updateProfile(profile.copyWith(gender: g));
              Navigator.of(context).pop();
            },
          ),
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
