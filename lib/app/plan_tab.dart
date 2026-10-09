import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'change_day.dart';
import 'common.dart';
import 'plan_finder.dart';
import 'plan_screen.dart';
import 'summary_screen.dart';
import 'workout_session.dart';

const _dayShort = ['Pon', 'Uto', 'Sre', 'Čet', 'Pet', 'Sub', 'Ned'];
const _dayLong = ['Ponedeljak', 'Utorak', 'Sreda', 'Četvrtak', 'Petak', 'Subota', 'Nedelja'];

/// The user's week as seven rows: a training day is a card with the
/// workout's photo, a rest day a quiet line. Tap a card to see or change the
/// day; hold it and drag it to a free day to move it. Every change can be
/// undone. Missed days never count against the user.
class PlanTabScreen extends StatefulWidget {
  const PlanTabScreen({super.key});

  @override
  State<PlanTabScreen> createState() => _PlanTabScreenState();
}

class _PlanTabScreenState extends State<PlanTabScreen> {
  /// Monday of the week on screen; null is this week.
  DateTime? _week;

  /// The day being dragged, so free days can light up.
  DateTime? _dragging;

  /// Runs a change to the calendar and offers to undo it.
  void _change(String message, void Function() change) {
    final store = context.readStore;
    final before = store.plan?.days;
    change();
    _toast(message, before);
  }

  Future<void> _changeDay(DateTime day) async {
    final result = await changeDay(context, day);
    if (result == null || !mounted) return;
    _toast(result.message, result.before);
  }

  void _toast(String message, Map<String, DayPlan>? before) {
    final store = context.readStore;
    showUndoToast(context, message, onUndo: before == null ? null : () => store.restoreDays(before));
  }

  static DateTime _mondayOf(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

  String _range(DateTime monday) {
    const months = ['jan', 'feb', 'mar', 'apr', 'maj', 'jun', 'jul', 'avg', 'sep', 'okt', 'nov', 'dec'];
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    return monday.month == sunday.month
        ? '${monday.day}.–${sunday.day}. ${months[sunday.month - 1]}'
        : '${monday.day}. ${months[monday.month - 1]} – ${sunday.day}. ${months[sunday.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final today = dateOnly(store.now);
    final thisWeek = _mondayOf(today);
    final monday = _week ?? thisWeek;
    final plan = store.plan;
    final days = [for (var i = 0; i < 7; i++) DateTime(monday.year, monday.month, monday.day + i)];
    final canDrag = days.any((d) => !d.isBefore(today) && store.plannedOn(d) != null);

    return AppScreen(
      children: [
        const SizedBox(height: ClSpace.s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ClScreenTitle(
                label: plan == null
                    ? _range(monday)
                    : store.weeklyGoal == 0 || monday != thisWeek
                    ? '${plan.name} · ${_range(monday)}'
                    : '${plan.name} · ${store.thisWeek} od ${store.weeklyGoal}',
                title: monday == thisWeek
                    ? 'Ova nedelja'
                    : (monday.isBefore(thisWeek) ? 'Ranije' : 'Kasnije'),
                large: true,
              ),
            ),
            ClIconButton(
              icon: ClIcons.back,
              semanticLabel: 'Prethodna nedelja',
              onPressed: () => setState(() => _week = DateTime(monday.year, monday.month, monday.day - 7)),
            ),
            ClIconButton(
              icon: ClIcons.chevron,
              semanticLabel: 'Sledeća nedelja',
              onPressed: () => setState(() => _week = DateTime(monday.year, monday.month, monday.day + 7)),
            ),
          ],
        ),
        gapS,
        for (final day in days) _row(context, day, today),
        if (plan == null) ...[
          gapS,
          ClButton(
            label: 'Pronađi plan',
            variant: ClButtonVariant.secondary,
            icon: ClIcons.find,
            expand: true,
            onPressed: () => pushScreen(context, const PlanFinderScreen()),
          ),
        ] else ...[
          if (canDrag) ...[
            gapS,
            Text(
              'Drži trening i prevuci ga na slobodan dan.',
              textAlign: TextAlign.center,
              style: cl.text.label,
            ),
          ],
          gap,
          ClMenuGroup(
            children: [
              ClMenuRow(
                icon: ClIcons.days,
                title: 'Dani treninga',
                value: [for (final d in plan.trainingDays.toList()..sort()) _dayShort[d - 1]].join(', '),
                onPressed: () => showClSheet<void>(
                  context,
                  title: 'Dani treninga',
                  builder: (_) => const _TrainingDaysSheet(),
                ),
              ),
              ClMenuRow(
                icon: ClIcons.swap,
                title: 'Program i zamene vežbi',
                onPressed: () => pushScreen(context, const PlanScreen()),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// One day: the date on the left, the day itself on the right.
  Widget _row(BuildContext context, DateTime day, DateTime today) {
    final store = context.store;
    final cl = context.cl;
    final c = cl.colors;
    final sessions = sessionsOn(store.sessions, day);
    final planned = day.isBefore(today) ? null : store.plannedOn(day);
    final isToday = day == today;
    final custom = store.dayPlan(day);

    final Widget body;
    if (sessions.isNotEmpty) {
      final s = sessions.first;
      final w = store.workoutsById[s.workoutId];
      body = _DayCard(
        title: s.workoutName,
        meta: sessionMeta(s),
        color: c.popFor(s.workoutId),
        image: photoOf(w?.image),
        done: true,
        today: isToday,
        onPressed: () => pushScreen(context, SummaryScreen(sessionId: s.id), theme: ClTheme.light),
      );
    } else if (planned != null) {
      final w = planned.workout;
      final minutes = (w.estimatedMinutes * planned.exercises.length / w.exercises.length.clamp(1, 99))
          .round();
      final card = _DayCard(
        title: w.name,
        meta: [?custom?.note, '~$minutes min'].join(' · '),
        color: c.popFor(w.id),
        image: photoOf(w.image),
        today: isToday,
        onPressed: () => _openDay(context, day, today),
      );
      body = LongPressDraggable<DateTime>(
        data: day,
        hapticFeedbackOnStart: true,
        onDragStarted: () => setState(() => _dragging = day),
        onDragEnd: (_) => setState(() => _dragging = null),
        feedback: SizedBox(
          width: MediaQuery.sizeOf(context).width - ClSpace.s4 * 2 - 52,
          child: Transform.rotate(
            angle: -0.02,
            child: Material(type: MaterialType.transparency, child: card),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: card),
        child: card,
      );
    } else {
      final past = day.isBefore(today);
      body = DragTarget<DateTime>(
        onWillAcceptWithDetails: (d) => store.canMoveTraining(d.data, day),
        onAcceptWithDetails: (d) {
          final name = store.plannedOn(d.data)?.workout.name ?? 'Trening';
          _change('$name je sada ${dayInSentence(day, today)}.', () => store.moveTraining(d.data, day));
        },
        builder: (context, candidates, _) {
          final canDrop = _dragging != null && store.canMoveTraining(_dragging!, day);
          return _FreeDay(
            label: custom?.note == 'Pauza'
                ? 'Pauza'
                : past
                ? null
                : 'Odmor',
            highlight: canDrop,
            hovered: candidates.isNotEmpty,
            onPressed: store.plan == null
                ? null
                : past
                ? () => _logLater(context, day)
                : () => _changeDay(day),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: ClSpace.s2),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(
                  '${day.day}',
                  style: cl.text.data.copyWith(
                    fontSize: 18,
                    color: isToday ? c.ink : c.ink.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  isToday ? 'danas' : _dayShort[day.weekday - 1].toLowerCase(),
                  style: cl.text.label.copyWith(color: isToday ? c.ink : c.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: ClSpace.s2),
          Expanded(child: body),
        ],
      ),
    );
  }

  /// A planned day: its exercises, then start (today) or change it.
  Future<void> _openDay(BuildContext context, DateTime day, DateTime today) async {
    final store = context.readStore;
    final planned = store.plannedOn(day);
    if (planned == null) return;
    final action = await showClSheet<String>(
      context,
      title: planned.workout.name,
      label: '${weekdayName(day)} ${formatDate(day, now: today)}',
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, we) in planned.exercises.indexed)
            if (store.resolveExercise(we.exerciseId) case final e?)
              ClExerciseRow(
                index: i + 1,
                image: photoOf(e.image),
                name: e.name,
                detail: '${we.target} · ${restLabel(we.restSeconds)}',
              ),
          gapS,
          if (day == today)
            ClButton(
              label: store.active == null ? 'Počni trening' : 'Nastavi trening',
              expand: true,
              onPressed: () => Navigator.of(context).pop('start'),
            ),
          const SizedBox(height: ClSpace.s2),
          ClButton(
            label: day == today ? 'Promeni današnji dan' : 'Promeni dan',
            variant: ClButtonVariant.secondary,
            expand: true,
            onPressed: () => Navigator.of(context).pop('change'),
          ),
          if (store.dayPlan(day) != null) ...[
            const SizedBox(height: ClSpace.s2),
            ClButton(
              label: 'Vrati na plan',
              variant: ClButtonVariant.text,
              icon: ClIcons.sync,
              onPressed: () => Navigator.of(context).pop('reset'),
            ),
          ],
        ],
      ),
    );
    if (!mounted || action == null || !context.mounted) return;
    switch (action) {
      case 'start':
        store.startToday();
        pushScreen(context, const WorkoutSessionScreen());
      case 'change':
        await _changeDay(day);
      case 'reset':
        _change('Dan je vraćen na plan.', () => store.setDayPlan(day, null));
    }
  }

  /// A past day without a workout: maybe it was done and not logged.
  Future<void> _logLater(BuildContext context, DateTime day) async {
    final id = await pickWorkout(context, title: 'Šta je urađeno tog dana?');
    if (id == null || !context.mounted) return;
    context.readStore.startSession(workoutId: id, loggedFor: day);
    pushScreen(context, const WorkoutSessionScreen());
  }
}

/// A training day: the workout's photo (or its pop color), the name and one
/// line. Done days get a check; today gets an ink outline.
class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.title,
    required this.meta,
    required this.color,
    required this.image,
    required this.onPressed,
    this.done = false,
    this.today = false,
  });

  final String title;
  final String meta;
  final Color color;
  final ImageProvider? image;
  final VoidCallback onPressed;
  final bool done;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final ink = image == null ? c.onPop : c.onPhoto;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: [title, meta, if (done) 'urađeno', if (today) 'danas'].join(', '),
      radius: ClRadius.sm,
      builder: (context, pressed) => AnimatedScale(
        duration: context.motion(ClMotion.fast),
        scale: pressed ? 0.98 : 1,
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClRadius.sm + 2),
            border: today ? Border.all(color: c.ink, width: 2) : null,
          ),
          padding: EdgeInsets.all(today ? 2 : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ClRadius.sm),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: color),
                if (image != null) ...[
                  ClPhoto(image: image, placeholderLabel: ''),
                  const ClPhotoScrim(coverage: 1),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3, vertical: ClSpace.s2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cl.text.bodyStrong.copyWith(fontSize: 17, color: ink),
                      ),
                      Text(meta, maxLines: 1, style: cl.text.label.copyWith(color: ink)),
                    ],
                  ),
                ),
                if (done)
                  Positioned(
                    top: ClSpace.s2,
                    right: ClSpace.s2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(color: c.bg, shape: BoxShape.circle),
                      child: Icon(ClIcons.check, size: 13, color: c.ink),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A day without a workout: a thin line with a moon. While a workout is
/// dragged, the days it can land on light up.
class _FreeDay extends StatelessWidget {
  const _FreeDay({this.label, this.onPressed, this.highlight = false, this.hovered = false});

  final String? label;
  final VoidCallback? onPressed;
  final bool highlight;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label ?? 'Bez treninga',
      radius: ClRadius.sm,
      builder: (context, pressed) => AnimatedContainer(
        duration: context.motion(ClMotion.fast),
        height: highlight ? 84 : 40,
        padding: const EdgeInsets.symmetric(horizontal: ClSpace.s3),
        decoration: BoxDecoration(
          color: hovered || pressed ? c.surfaceRaised : null,
          borderRadius: BorderRadius.circular(ClRadius.sm),
          // Only a place to drop a workout gets an outline.
          border: Border.all(color: highlight ? c.ink : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            if (highlight)
              Expanded(
                child: Text(
                  hovered ? 'Pusti ovde' : 'Slobodan dan',
                  style: cl.text.bodyStrong.copyWith(color: c.ink),
                ),
              )
            else ...[
              if (label != null) Icon(ClIcons.rest, size: 16, color: c.inkMuted),
              if (label != null) ...[const SizedBox(width: ClSpace.s2), Text(label!, style: cl.text.label)],
            ],
          ],
        ),
      ),
    );
  }
}

class _TrainingDaysSheet extends StatelessWidget {
  const _TrainingDaysSheet();

  @override
  Widget build(BuildContext context) {
    final plan = context.store.plan;
    if (plan == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var d = 1; d <= 7; d++)
          ClOptionRow(
            title: _dayLong[d - 1],
            selected: plan.trainingDays.contains(d),
            onPressed: () {
              final on = !plan.trainingDays.contains(d);
              final days = on ? {...plan.trainingDays, d} : ({...plan.trainingDays}..remove(d));
              if (days.isNotEmpty) context.readStore.setTrainingDays(days);
            },
          ),
        gapS,
        ClNotice(
          'Program predviđa ${plan.daysPerWeek}× nedeljno. Ovo su tvoji uobičajeni dani; svaki dan možeš i posebno da promeniš u kalendaru.',
        ),
      ],
    );
  }
}
