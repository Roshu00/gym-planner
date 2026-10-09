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
          title: justFinished
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
        const SizedBox(height: ClSpace.s6),
        const ClSectionHeader(label: 'Vežbe'),
        for (final e in s.exercises) ClExerciseRow(name: e.name, detail: _detail(e), isPr: e.hasPr),
      ],
    );
  }

  static String _detail(SessionExercise e) {
    final top = topSet(e);
    final sets = countLabel(e.doneSets.length, 'set', 'seta', 'setova');
    return top == null ? sets : '$sets · najbolji ${setLabel(top)}';
  }
}
