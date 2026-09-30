import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/chalkline_ui.dart';
import 'auth_screen.dart';
import 'common.dart';
import 'creator_editors.dart';
import 'creator_profile.dart';

/// Where a creator builds their system once: exercises, workouts, programs,
/// what is public and what is for subscribers.
class CreatorModeScreen extends StatefulWidget {
  const CreatorModeScreen({super.key});

  @override
  State<CreatorModeScreen> createState() => _CreatorModeScreenState();
}

class _CreatorModeScreenState extends State<CreatorModeScreen> {
  int _tab = 0;
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final me = store.myCreator;
    if (store.account?.isGuest ?? false) {
      return AppScreen(
        topBar: const ClTopBar(label: 'Režim kreatora'),
        children: [
          ClEmptyState(
            title: 'Sačuvaj nalog.',
            message: 'Objavljivanje traži nalog sa emailom, da bi pratioci mogli da te nađu i da tvoj sadržaj ostane tvoj.',
            action: ClButton(
              label: 'Sačuvaj nalog',
              expand: true,
              onPressed: () => pushScreen(context, AuthScreen(auth: store.auth!, saveAccount: true)),
            ),
          ),
        ],
      );
    }
    if (me == null) return const CreatorProfileEditor();
    final cl = context.cl;
    final link = 'chalkline.app/c/${me.handle}';

    final (String addLabel, Widget editor, List<Widget> rows) = switch (_tab) {
      0 => (
        'Nova vežba',
        const ExerciseEditor(),
        [
          for (final e in store.myExercises)
            ClListRow(
              title: e.name,
              meta: '${e.muscle.label} · ${e.equipmentLabel}',
              tags: [ClTag(e.visibility.label)],
              onPressed: () => pushScreen(context, ExerciseEditor(exerciseId: e.id), theme: ClTheme.light),
            ),
        ],
      ),
      1 => (
        'Novi trening',
        const WorkoutEditor(),
        [
          for (final w in store.myWorkouts)
            ClListRow(
              title: w.name,
              meta: workoutMeta(w),
              tags: [ClTag(w.visibility.label)],
              onPressed: () => pushScreen(context, WorkoutEditor(workoutId: w.id), theme: ClTheme.light),
            ),
        ],
      ),
      _ => (
        'Novi program',
        const ProgramEditor(),
        [
          for (final p in store.myPrograms)
            ClListRow(
              title: p.name,
              meta:
                  '${programMeta(p)} · ${countLabel(p.workoutIds.length, 'trening', 'treninga', 'treninga')}',
              tags: [ClTag(p.visibility.label), ClTag(p.level.label)],
              onPressed: () => pushScreen(context, ProgramEditor(programId: p.id), theme: ClTheme.light),
            ),
        ],
      ),
    };

    return AppScreen(
      topBar: ClTopBar(
        label: 'Režim kreatora',
        actions: [
          ClButton(
            label: 'Uredi profil',
            variant: ClButtonVariant.text,
            onPressed: () => pushScreen(context, const CreatorProfileEditor(), theme: ClTheme.light),
          ),
          const SizedBox(width: ClSpace.s3),
        ],
      ),
      children: [
        ClScreenTitle(label: '@${me.handle}', title: me.name),
        const SizedBox(height: ClSpace.s6),
        ClStatBar(
          stats: [
            ClStat(label: 'Programi', value: '${store.myPrograms.length}'),
            ClStat(label: 'Treninzi', value: '${store.myWorkouts.length}'),
            ClStat(label: 'Vežbe', value: '${store.myExercises.length}'),
          ],
        ),
        gap,
        const ClSectionHeader(label: 'Link za biografiju'),
        Text(link, style: cl.text.data),
        const SizedBox(height: ClSpace.s2),
        Wrap(
          spacing: ClSpace.s3,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ClButton(
              label: _copied ? 'Kopirano' : 'Kopiraj link',
              variant: ClButtonVariant.secondary,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: 'https://$link'));
                if (mounted) setState(() => _copied = true);
              },
            ),
            ClButton(
              label: 'Pogledaj profil',
              variant: ClButtonVariant.text,
              onPressed: () =>
                  pushScreen(context, CreatorProfileScreen(creatorId: me.id), theme: ClTheme.light),
            ),
          ],
        ),
        const SizedBox(height: ClSpace.s2),
        const ClNotice('Pratilac koji otvori link ide pravo na tvoj profil.'),
        gap,
        ClTabs(
          tabs: [
            'Vežbe ${store.myExercises.length}',
            'Treninzi ${store.myWorkouts.length}',
            'Programi ${store.myPrograms.length}',
          ],
          selected: _tab,
          onChanged: (i) => setState(() => _tab = i),
        ),
        if (rows.isEmpty) ...[
          gapS,
          ClNotice(switch (_tab) {
            0 => 'Počni od vežbi. Treninzi se slažu od njih.',
            1 =>
              store.myExercises.isEmpty
                  ? 'Prvo napravi bar jednu vežbu.'
                  : 'Složi prvi trening od svojih vežbi.',
            _ =>
              store.myWorkouts.isEmpty
                  ? 'Prvo napravi bar jedan trening.'
                  : 'Program je redosled treninga kroz nedelje.',
          }),
        ],
        ...rows,
        gapS,
        ClButton(
          label: addLabel,
          variant: ClButtonVariant.secondary,
          icon: ClIcons.add,
          expand: true,
          onPressed: () => pushScreen(context, editor, theme: ClTheme.light),
        ),
      ],
    );
  }
}
