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
  final _card = GlobalKey();
  final _shareButton = GlobalKey();
  bool _sharing = false;

  String get sessionId => widget.sessionId;
  bool get justFinished => widget.justFinished;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final box = _shareButton.currentContext?.findRenderObject() as RenderBox?;
    try {
      await shareStory(
        context,
        _card,
        origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        onReady: () {
          if (mounted) setState(() => _sharing = false);
        },
      );
    } on Object {
      if (mounted) showUndoToast(context, 'Slika nije napravljena. Pokušaj ponovo.');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

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
    final label = justFinished
        ? '${s.workoutName} · ${formatDuration(s.duration)}'
        : '${weekdayName(date)} ${formatDate(date)} · ${formatDuration(s.duration)}';
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
              key: _shareButton,
              label: _sharing ? 'Pripremam…' : 'Podeli na story',
              variant: ClButtonVariant.pop,
              expand: true,
              onPressed: _sharing ? null : _share,
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
        ClSummary(
          cardKey: _card,
          label: label,
          headline: justFinished
              ? (store.profile?.says('Pojavio si se.', 'Pojavila si se.', 'Odrađeno.') ?? 'Odrađeno.')
              : s.workoutName,
          stats: [
            ClStat(label: 'Volumen', value: formatNumber(s.volume, maxDecimals: 0), unit: 'kg'),
            // A zero reads like a failure; without records the sets count.
            if (s.prCount > 0)
              ClStat(label: 'Rekordi', value: '${s.prCount}', unit: 'PR', highlight: true)
            else
              ClStat(label: 'Setova', value: '${s.doneSets}'),
            if (justFinished && store.streak > 0)
              ClStat(label: 'Niz', value: '${store.streak}', unit: 'ned.'),
          ],
          exercises: [
            for (final e in s.exercises) ClSummaryExercise(name: e.name, detail: _detail(e), isPr: e.hasPr),
          ],
          creatorName: s.creatorName,
          creatorHandle: store.creator(s.creatorId)?.handle,
          creatorImage: photoOf(store.creator(s.creatorId)?.photo),
          creatorMessage: message,
        ),
      ],
    );
  }

  static String _detail(SessionExercise e) {
    final top = topSet(e);
    final sets = countLabel(e.doneSets.length, 'set', 'seta', 'setova');
    return top == null ? sets : '$sets · najbolji ${setLabel(top)}';
  }
}
