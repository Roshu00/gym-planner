import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'story_share.dart';
import 'team.dart';
import 'trial_offer.dart';

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
    final planned = store.plannedSets(s);
    // The trainer's "great workout" only fits a workout done (nearly) in full.
    final message = !store.finishedInFull(s) && planned != null
        ? 'Urađeno ${s.doneSets} od ${countLabel(planned, 'seta', 'seta', 'setova')}. '
              'I to se računa. Sledeći put idemo do kraja.'
        : s.finishMessage.isNotEmpty
        ? s.finishMessage
        : (store.nextWorkout == null
              ? 'Vidimo se na sledećem treningu.'
              : 'Sledeće je ${store.nextWorkout!.name}. Isti ritam.');

    final number = store.history.where((x) => !x.finishedAt!.isAfter(date)).length;
    final work = sessionWork(s);
    final records = [
      for (final e in s.exercises)
        if (e.hasPr && topSet(e) != null) (exercise: e, top: topSet(e)!, gain: _gain(store.sessions, s, e)),
    ];
    final weeks = weeklyVolume(store.sessions, date, 8);
    final bestWeek =
        weeks.length > 1 &&
        weeks.last.volume > 0 &&
        weeks.sublist(0, weeks.length - 1).any((w) => w.volume > 0) &&
        weeks.last.volume >
            weeks.sublist(0, weeks.length - 1).map((w) => w.volume).reduce((a, b) => a > b ? a : b);
    final String headline;
    final String? highlight;
    if (!justFinished) {
      headline = '${weekdayName(date)} ${formatDate(date)}';
      highlight = null;
    } else if (first) {
      headline = 'Prvi trening.';
      highlight = 'Najteži korak je iza tebe.';
    } else {
      headline = 'Trening $number.';
      highlight = bestWeek
          ? 'Najjača nedelja do sada.'
          : records.isNotEmpty
          ? '${countLabel(records.length, 'novi rekord', 'nova rekorda', 'novih rekorda')}.'
          : store.profile?.says('Pojavio si se.', 'Pojavila si se.', 'Odrađeno.') ?? 'Odrađeno.';
    }
    final cl = context.cl;
    final c = cl.colors;

    Widget stat(String value, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(ClSpace.s3),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(ClRadius.sm - 2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: cl.text.metric),
            ),
            Text(label, style: cl.text.label),
          ],
        ),
      ),
    );

    return AppScreen(
      topBar: ClTopBar(backLabel: justFinished ? 'Zatvori' : 'Nazad'),
      bottom: Row(
        children: [
          Expanded(
            child: ClButton(
              label: 'Podeli na story',
              variant: justFinished ? ClButtonVariant.secondary : ClButtonVariant.primary,
              expand: true,
              onPressed: () => pushScreen(context, StoryComposerScreen(session: s)),
            ),
          ),
          if (justFinished) ...[
            const SizedBox(width: ClSpace.s2),
            Expanded(
              child: store.postedSessions.contains(s.id)
                  ? ClButton(label: 'Gotovo', expand: true, onPressed: () => Navigator.of(context).pop())
                  : ClButton(
                      label: 'Pokaži timu',
                      expand: true,
                      onPressed: () {
                        store.showToTeam(s);
                        pushScreen(context, TeamScreen(creatorId: s.creatorId), replace: true);
                      },
                    ),
            ),
          ],
        ],
      ),
      children: [
        if (justFinished && store.streak > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: c.signalSoft,
                borderRadius: BorderRadius.circular(ClRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ClIcons.streak, size: 14, color: c.signalText),
                  const SizedBox(width: 6),
                  Text(
                    '${countLabel(store.streak, 'nedelja', 'nedelje', 'nedelja')} zaredom',
                    style: cl.text.label.copyWith(color: c.signalText),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: ClSpace.s3),
        Semantics(
          header: true,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: headline),
                if (highlight != null) ...[
                  const TextSpan(text: '\n'),
                  TextSpan(
                    text: highlight,
                    style: TextStyle(color: c.signal),
                  ),
                ],
              ],
            ),
            style: cl.text.displayXl.copyWith(fontSize: justFinished ? 44 : 34, height: 1.02),
          ),
        ),
        if (!justFinished) ...[const SizedBox(height: 4), Text(s.workoutName, style: cl.text.bodyStrong)],
        gap,
        Row(
          children: [
            stat(formatDuration(s.duration), 'vreme'),
            const SizedBox(width: ClSpace.s2),
            stat(work.value, work.label.toLowerCase()),
            const SizedBox(width: ClSpace.s2),
            stat('${s.prCount > 0 ? s.prCount : s.doneSets}', s.prCount > 0 ? 'rekorda' : 'setova'),
          ],
        ),
        if (records.isNotEmpty) ...[
          gapS,
          for (final (i, r) in records.indexed) ...[
            if (i > 0) const SizedBox(height: ClSpace.s2),
            Container(
              padding: const EdgeInsets.all(ClSpace.s4),
              decoration: BoxDecoration(
                color: i == 0 ? c.signal : c.surface,
                borderRadius: BorderRadius.circular(ClRadius.sm),
              ),
              child: Row(
                children: [
                  Icon(ClIcons.record, color: i == 0 ? c.onSignal : c.signal),
                  const SizedBox(width: ClSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${r.exercise.name} · ${setLabel(r.top, timed: r.exercise.timed)}',
                          style: cl.text.bodyStrong.copyWith(color: i == 0 ? c.onSignal : c.ink),
                        ),
                        Text(
                          r.gain == null ? 'Novi rekord' : 'Novi rekord · ${r.gain}',
                          style: cl.text.label.copyWith(
                            color: i == 0 ? c.onSignal.withValues(alpha: 0.75) : c.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
        const SizedBox(height: ClSpace.s4),
        ClCreatorMessage(
          name: s.creatorName,
          message: message,
          image: photoOf(store.creator(s.creatorId)?.photo),
        ),
        if (justFinished) ...[const SizedBox(height: ClSpace.s4), TrialOffer(session: s)],
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

  /// How much more than the best before this session: "+5 kg" or "+2 pon.".
  static String? _gain(List<Session> all, Session s, SessionExercise e) {
    final top = topSet(e);
    if (top == null) return null;
    SetLog? before;
    for (final x in all) {
      final earlier = x.finishedAt != null && x.finishedAt!.isBefore(s.finishedAt ?? s.startedAt);
      if (x.id == s.id || !earlier) continue;
      for (final xe in x.exercises.where((xe) => xe.exerciseId == e.exerciseId)) {
        final t = topSet(xe);
        if (t != null && (before == null || (t.kg ?? 0) > (before.kg ?? 0))) before = t;
      }
    }
    if (before == null) return null;
    final dkg = (top.kg ?? 0) - (before.kg ?? 0);
    if (dkg > 0) return '+${formatNumber(dkg)} kg';
    final dr = (top.reps ?? 0) - (before.reps ?? 0);
    if (dr > 0) return e.timed ? '+$dr s' : '+$dr pon.';
    return null;
  }

  static String _detail(SessionExercise e) {
    final top = topSet(e);
    final sets = countLabel(e.doneSets.length, 'set', 'seta', 'setova');
    return top == null ? sets : '$sets · najbolji ${setLabel(top, timed: e.timed)}';
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
        if (topSet(e) case final top?) (e.name, setLabel(top, timed: e.timed)),
    ];
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(ClRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tvoji početni rezultati', style: cl.text.displayM.copyWith(fontSize: 24)),
          const SizedBox(height: ClSpace.s1),
          Text(
            'Od danas se meri svaki napredak. Sledeći put ih obaraš.',
            style: cl.text.body.copyWith(color: c.inkMuted),
          ),
          const SizedBox(height: ClSpace.s3),
          for (final (name, best) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: ClSpace.s1),
              child: Row(
                children: [
                  Expanded(child: Text(name, style: cl.text.body)),
                  Text(best, style: cl.text.data),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
