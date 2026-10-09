import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'story_share.dart';

/// Proof of the workout: praise for showing up, volume, records, the
/// creator's message, on a card made to be shared. Also the history detail view.
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.sessionId, this.justFinished = false});

  final String sessionId;
  final bool justFinished;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String get sessionId => widget.sessionId;
  bool get justFinished => widget.justFinished;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final s = store.sessionById(sessionId);
    if (s == null) {
      return AppScreen(
        topBar: const ClTopBar(),
        children: const [
          ClEmptyState(title: 'Nema treninga.', message: 'Ovaj trening više nije u istoriji.'),
        ],
      );
    }
    final date = s.finishedAt ?? s.startedAt;
    final first = store.isFirstSession(s.id);
    final message = s.finishMessage.isNotEmpty
        ? s.finishMessage
        : (store.nextWorkout == null
              ? 'Vidimo se na sledećem treningu.'
              : 'Sledeće je ${store.nextWorkout!.name}. Isti ritam.');

    return AppScreen(
      topBar: ClTopBar(
        label: justFinished ? null : s.workoutName,
        backLabel: justFinished ? 'Zatvori' : 'Nazad',
      ),
      bottom: Row(
        children: [
          Expanded(
            child: ClButton(
              label: 'Podeli na story',
              variant: ClButtonVariant.pop,
              expand: true,
              onPressed: () => pushScreen(context, StoryComposerScreen(session: s)),
            ),
          ),
          if (justFinished) ...[
            const SizedBox(width: ClSpace.s2),
            Expanded(
              child: ClButton(label: 'Gotovo', expand: true, onPressed: () => Navigator.of(context).pop()),
            ),
          ],
        ],
      ),
      children: [
        // The sticker already names the workout; the title says when.
        ClScreenTitle(
          label: justFinished && store.streak > 0
              ? '${countLabel(store.streak, 'nedelja', 'nedelje', 'nedelja')} zaredom'
              : null,
          title: justFinished && first
              ? 'Prvi trening.'
              : justFinished
              ? (store.profile?.says('Pojavio si se.', 'Pojavila si se.', 'Odrađeno.') ?? 'Odrađeno.')
              : '${weekdayName(date)} ${formatDate(date)}',
        ),
        gapS,
        // The same photo + sticker the story will have; a tap opens it.
        ClPressable(
          onPressed: () => pushScreen(context, StoryComposerScreen(session: s)),
          semanticLabel: 'Podeli na story',
          radius: ClRadius.lg,
          builder: (context, pressed) => AnimatedScale(
            duration: context.motion(ClMotion.fast),
            scale: pressed ? 0.98 : 1,
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: LayoutBuilder(
                builder: (context, box) => ClipRRect(
                  borderRadius: BorderRadius.circular(ClRadius.lg),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: context.clColors.popFor(s.workoutId)),
                      if (photoOf(store.workoutsById[s.workoutId]?.image) case final cover?)
                        ClPhoto(image: cover, placeholderLabel: ''),
                      const ClPhotoScrim(coverage: 0.6),
                      Positioned(
                        left: ClSpace.s4,
                        right: ClSpace.s4,
                        bottom: ClSpace.s4,
                        child: StorySticker(
                          session: s,
                          first: first,
                          handle: store.creator(s.creatorId)?.handle,
                          creatorPhoto: photoOf(store.creator(s.creatorId)?.photo),
                          scale: box.maxWidth / 360,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: ClSpace.s4),
        ClCreatorMessage(
          name: s.creatorName,
          message: message,
          image: photoOf(store.creator(s.creatorId)?.photo),
        ),
        // The first time the baseline is the exercise list.
        if (first) ...[
          const SizedBox(height: ClSpace.s4),
          _Baseline(session: s),
        ] else ...[
          const SizedBox(height: ClSpace.s6),
          const ClSectionHeader(label: 'Vežbe'),
          for (final e in s.exercises) ClExerciseRow(name: e.name, detail: _detail(e), isPr: e.hasPr),
        ],
      ],
    );
  }

  static String _detail(SessionExercise e) {
    final top = topSet(e);
    final sets = countLabel(e.doneSets.length, 'set', 'seta', 'setova');
    return top == null ? sets : '$sets · najbolji ${setLabel(top)}';
  }
}

/// After the very first workout there are no records to beat yet; every
/// number is a starting point. Says so, with the best set of each exercise.
class _Baseline extends StatelessWidget {
  const _Baseline({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final rows = [
      for (final e in session.exercises)
        if (topSet(e) case final top?) (e.name, setLabel(top)),
    ];
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(ClRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tvoji početni rezultati', style: cl.text.displayM.copyWith(color: c.bg, fontSize: 24)),
          const SizedBox(height: ClSpace.s1),
          Text(
            'Od danas se meri svaki napredak. Sledeći put ih obaraš.',
            style: cl.text.body.copyWith(color: c.bg.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: ClSpace.s3),
          for (final (name, best) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ClSpace.s1),
              child: Row(
                children: [
                  Expanded(
                    child: Text(name, style: cl.text.body.copyWith(color: c.bg)),
                  ),
                  Text(best, style: cl.text.data.copyWith(color: c.bg)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
