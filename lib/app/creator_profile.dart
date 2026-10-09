import 'package:flutter/material.dart';

import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'creator_mode.dart';
import 'discover.dart';
import 'subscribe_sheet.dart';

/// Creator profile: photo header, numbers, subscribe, programs.
class CreatorProfileScreen extends StatelessWidget {
  const CreatorProfileScreen({super.key, required this.creatorId});

  final String creatorId;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final c = store.creator(creatorId);
    if (c == null) {
      return AppScreen(
        topBar: const ClTopBar(),
        children: const [ClEmptyState(title: 'Nema trenera.', message: 'Ovaj profil više ne postoji.')],
      );
    }
    final cl = context.cl;
    final programs = store.programsOf(c.id).where((p) => p.workoutIds.isNotEmpty).toList();
    final subscribed = store.subscriptions.contains(c.id);

    final List<Widget> actions;
    if (c.isMine) {
      actions = [
        const ClNotice('Ovako pratioci vide tvoj profil.'),
        gapS,
        ClButton(
          label: 'Režim kreatora',
          variant: ClButtonVariant.secondary,
          expand: true,
          onPressed: () => pushScreen(context, const CreatorModeScreen(), theme: ClTheme.light),
        ),
      ];
    } else if (subscribed) {
      actions = [
        Row(
          children: [
            Expanded(child: ClNotice('Pretplaćen si · ${formatPrice(c.priceMonthly)} mesečno')),
            ClButton(
              label: 'Otkaži',
              variant: ClButtonVariant.text,
              onPressed: () async {
                final ok = await confirmClSheet(
                  context,
                  title: 'Otkaži pretplatu?',
                  message: 'Sadržaj za pretplatnike se zaključava. Tvoja istorija treninga ostaje.',
                  confirmLabel: 'Otkaži pretplatu',
                  danger: true,
                );
                if (ok && context.mounted) context.readStore.unsubscribe(c.id);
              },
            ),
          ],
        ),
      ];
    } else {
      actions = [
        Row(
          children: [
            Expanded(
              child: ClButton(
                label: 'Pretplati se',
                variant: ClButtonVariant.pop,
                expand: true,
                onPressed: () => showSubscribeSheet(context, c),
              ),
            ),
            const SizedBox(width: ClSpace.s3),
            ClButton(
              label: store.follows.contains(c.id) ? 'Pratiš' : 'Zaprati',
              variant: ClButtonVariant.secondary,
              onPressed: () => context.readStore.toggleFollow(c.id),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        ClNotice('${formatPrice(c.priceMonthly)} mesečno. Praćenje je besplatno i otključava javni sadržaj.'),
      ];
    }

    return AppScreen(
      safeTop: false,
      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s4, ClSpace.s4, ClSpace.s12),
      collapsed: Row(
        children: [
          ClAvatar(name: c.name, image: photoOf(c.photo)),
          const SizedBox(width: ClSpace.s2),
          Expanded(
            child: Text(
              c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.clText.bodyStrong,
            ),
          ),
        ],
      ),
      header: ClWorkoutHero(
        title: c.name,
        image: photoOf(c.photo),
        color: context.clColors.popFor(c.id),
        label: '@${c.handle} · ${c.tagline}',
        height: 320,
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
      children: [
        if (c.bio.isNotEmpty) ...[Text(c.bio, style: cl.text.body), const SizedBox(height: ClSpace.s6)],
        ClStatBar(
          stats: [
            ClStat(label: 'Pratioci', value: formatCompact(c.followers)),
            ClStat(label: 'Programi', value: '${programs.length}'),
            ClStat(label: 'Vežbe', value: '${store.exercisesOf(c.id).length}'),
          ],
        ),
        const SizedBox(height: ClSpace.s6),
        ...actions,
        gap,
        ClSectionHeader(
          label: 'Programi',
          trailing: Text('${programs.length}', style: cl.text.label),
        ),
        if (programs.isEmpty) const ClNotice('Još nema objavljenih programa.'),
        for (final p in programs) ...[ProgramTile(program: p), const SizedBox(height: ClSpace.s8)],
      ],
    );
  }
}
