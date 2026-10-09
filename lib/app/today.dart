import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'change_day.dart';
import 'common.dart';
import 'creator_profile.dart';
import 'plan_finder.dart';
import 'program_detail.dart';
import 'shell.dart';
import 'summary_screen.dart';
import 'workout_session.dart';

/// Every morning. Three states:
/// - with a plan: today's workout on a pop color block, the week, the
///   exercises, one button;
/// - a new user: an inspiring welcome with creators and programs to start;
/// - between plans: what the user has done so far and programs to continue.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final plan = store.plan;
    final next = store.nextWorkout;
    final active = store.active;
    final today = store.now;

    final greeting = ClScreenTitle(
      label: '${weekdayName(today)}, ${formatDate(today, now: today)}',
      title: 'Zdravo, ${store.profile?.name.split(' ').first ?? ''}',
    );

    if (plan == null || next == null) {
      return store.sessions.isEmpty ? const _WelcomeToday() : _BetweenPlansToday(greeting: greeting);
    }

    final creator = store.creator(plan.creatorId);
    // What the calendar says for today, with the user's own changes. On a
    // rest day the plan's next workout is still one tap away.
    final todayPlan = store.plannedOn(today);
    final changed = store.dayPlan(today);
    final workout = todayPlan?.workout ?? next;
    final exercises = todayPlan?.exercises ?? next.exercises;
    final day = dateOnly(today);
    final name = store.profile?.name.split(' ').first ?? '';

    void start() {
      store.startToday();
      pushScreen(context, const WorkoutSessionScreen());
    }

    // Done for today: praise and the proof, the next workout only as a line.
    final doneToday = active == null ? sessionsOn(store.sessions, day).lastOrNull : null;
    if (doneToday != null) {
      final doneWorkout = store.workoutsById[doneToday.workoutId];
      final doneBy = store.creator(doneToday.creatorId) ?? creator;
      final upcoming = store
          .schedule(day.add(const Duration(days: 21)))
          .entries
          .where((e) => e.key.isAfter(day))
          .firstOrNull;
      final upcomingName = upcoming == null ? null : store.workoutsById[upcoming.value]?.name;
      void openSummary() => pushScreen(context, SummaryScreen(sessionId: doneToday.id), theme: ClTheme.light);
      return AppScreen(
        safeTop: false,
        padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s4, ClSpace.s4, ClSpace.s12),
        header: _TodayHero(
          greeting: '${weekdayName(today)} · Bravo, $name',
          title: doneToday.workoutName,
          meta: store.isFirstSession(doneToday.id)
              ? 'Prvi trening je iza tebe · ${formatDuration(doneToday.duration)}'
              : 'Odrađeno danas · ${formatDuration(doneToday.duration)}',
          color: cl.colors.popFor(doneToday.workoutId),
          image: photoOf(doneWorkout?.image),
          creator: doneBy,
          action: 'Pogledaj rezime',
          done: true,
          onStart: openSummary,
          onExercises: openSummary,
        ),
        children: [
          _WeekDots(today: day),
          if (upcoming != null && upcomingName != null) ...[
            const SizedBox(height: ClSpace.s2),
            Text('Sledeće: $upcomingName, ${dayInSentence(upcoming.key, day)}', style: cl.text.bodyStrong),
          ],
          if (doneToday.finishMessage.isNotEmpty && doneBy != null) ...[
            gap,
            _CreatorQuote(creator: doneBy, text: doneToday.finishMessage),
          ],
          // The best moment to offer reminders: right after showing up.
          if (!store.reminderSettings.enabled && !store.reminderSettings.asked && upcoming != null) ...[
            gap,
            const _ReminderOffer(),
          ],
        ],
      );
    }

    // Nothing trained yet: the first workout is the whole point of today.
    final first = store.sessions.isEmpty && active == null;
    final String? status = active != null
        ? 'Započet pre ${formatDuration(store.now.difference(active.startedAt))}'
        : first
        ? 'Tvoj prvi trening'
        : todayPlan == null
        ? 'Danas je odmor, ali možeš da treniraš'
        : changed?.note;

    return AppScreen(
      safeTop: false,
      padding: const EdgeInsets.fromLTRB(ClSpace.s4, ClSpace.s4, ClSpace.s4, ClSpace.s12),
      header: _TodayHero(
        greeting: '${weekdayName(today)} · Zdravo, $name',
        title: active?.workoutName ?? workout.name,
        meta: [?status, '~${workout.estimatedMinutes} min'].join(' · '),
        color: cl.colors.popFor(workout.id),
        image: photoOf(workout.image),
        creator: creator,
        action: active != null
            ? 'Nastavi'
            : first
            ? 'Počni prvi trening'
            : 'Počni',
        onStart: start,
        onExercises: () => _showExercises(context, workout.name, exercises),
        onChangeDay: active == null
            ? () async {
                final result = await changeDay(context, day);
                if (result == null || !context.mounted) return;
                final before = result.before;
                showUndoToast(
                  context,
                  result.message,
                  onUndo: before == null ? null : () => store.restoreDays(before),
                );
              }
            : null,
        onBackToPlan: active == null && changed != null ? () => store.setDayPlan(day, null) : null,
      ),
      children: [
        if (first) ...[const _FirstWorkoutSteps(), gap] else _WeekDots(today: day),
        if (workout.intro.isNotEmpty && creator != null) ...[
          gap,
          _CreatorQuote(creator: creator, text: workout.intro),
        ],
      ],
    );
  }

  /// Today's exercises with their pictures, one tap from the hero.
  static Future<void> _showExercises(BuildContext context, String title, List<WorkoutExercise> exercises) {
    final store = context.readStore;
    return showClSheet<void>(
      context,
      title: title,
      label: countLabel(exercises.length, 'vežba', 'vežbe', 'vežbi'),
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, we) in exercises.indexed)
            if (store.resolveExercise(we.exerciseId) case final e?)
              ClExerciseRow(
                index: i + 1,
                image: photoOf(e.image),
                name: e.name,
                detail: _detail(we.target, previousSets(store.sessions, e.id).firstOrNull),
              ),
        ],
      ),
    );
  }

  static String _detail(String target, SetLog? last) =>
      last == null ? target : '$target · Prošli put ${setLabel(last)}';
}

/// The trainer and today's workout over most of the screen: a small greeting
/// at the top, the workout name and one button at the bottom. Tapping the
/// photo lists the exercises; "⋯" changes the day.
class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.greeting,
    required this.title,
    required this.meta,
    required this.color,
    required this.image,
    required this.creator,
    required this.action,
    required this.onStart,
    required this.onExercises,
    this.onChangeDay,
    this.onBackToPlan,
    this.done = false,
  });

  /// Today's workout is finished: a check next to the title.
  final bool done;

  final String greeting;
  final String title;
  final String meta;
  final Color color;
  final ImageProvider? image;
  final Creator? creator;
  final String action;
  final VoidCallback onStart;
  final VoidCallback onExercises;
  final VoidCallback? onChangeDay;
  final VoidCallback? onBackToPlan;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    final onPhoto = image == null ? c.onPop : c.onPhoto;
    final height = (MediaQuery.sizeOf(context).height * 0.62).clamp(420.0, 620.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: image == null ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(ClRadius.lg)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: color),
              if (image != null) ...[
                ClPhoto(image: image, placeholderLabel: ''),
                const ClPhotoScrim(coverage: 0.65),
                // Keeps the greeting and the status bar readable on bright photos.
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [c.photoScrim, c.photoScrim.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // The photo itself opens the exercise list.
              Positioned.fill(
                child: ClPressable(
                  onPressed: onExercises,
                  semanticLabel: 'Vežbe za $title',
                  builder: (context, pressed) => const SizedBox.expand(),
                ),
              ),
              Positioned(
                top: 0,
                left: ClSpace.s4,
                right: ClSpace.s2,
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          greeting,
                          style: cl.text.bodyStrong.copyWith(fontSize: 14, color: onPhoto),
                        ),
                      ),
                      if (onChangeDay != null)
                        ClIconButton.onMedia(
                          icon: ClIcons.more,
                          semanticLabel: 'Promeni dan',
                          onPressed: onChangeDay,
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: ClSpace.s4,
                right: ClSpace.s4,
                bottom: ClSpace.s4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (creator != null)
                      Row(
                        children: [
                          ClAvatar(name: creator!.name, image: photoOf(creator!.photo)),
                          const SizedBox(width: ClSpace.s2),
                          Text(
                            creator!.name,
                            style: cl.text.bodyStrong.copyWith(fontSize: 14, color: onPhoto),
                          ),
                        ],
                      ),
                    const SizedBox(height: ClSpace.s2),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: cl.text.displayXl.copyWith(color: onPhoto, fontSize: 48, height: 46 / 48),
                      ),
                    ),
                    const SizedBox(height: ClSpace.s1),
                    Row(
                      children: [
                        if (done) ...[
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(color: onPhoto, shape: BoxShape.circle),
                            child: Icon(ClIcons.check, size: 12, color: image == null ? c.bg : c.ink),
                          ),
                          const SizedBox(width: ClSpace.s2),
                        ],
                        Flexible(
                          child: Text(meta, style: cl.text.body.copyWith(color: onPhoto)),
                        ),
                      ],
                    ),
                    const SizedBox(height: ClSpace.s4),
                    _HeroButton(label: action, onPressed: onStart, dark: image == null),
                    if (onBackToPlan != null)
                      Center(
                        child: TextButton(
                          onPressed: onBackToPlan,
                          child: Text('Vrati na plan', style: cl.text.bodyStrong.copyWith(color: onPhoto)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A full-width pill on the photo: light over a photo, ink over a pop color.
class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.label, required this.onPressed, required this.dark});

  final String label;
  final VoidCallback onPressed;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    return ClPressable(
      onPressed: onPressed,
      semanticLabel: label,
      radius: ClRadius.full,
      builder: (context, pressed) => AnimatedScale(
        duration: context.motion(ClMotion.fast),
        scale: pressed ? 0.97 : 1,
        child: Container(
          height: ClSize.targetWorkout,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: dark ? c.ink : c.bg,
            borderRadius: BorderRadius.circular(ClRadius.full),
          ),
          child: Text(label, style: cl.text.button.copyWith(color: dark ? c.bg : c.ink)),
        ),
      ),
    );
  }
}

/// Monday to Sunday as seven circles: filled = done, thick ring = today,
/// dashed-looking ring = a workout is planned. One line of numbers below.
class _WeekDots extends StatelessWidget {
  const _WeekDots({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final c = cl.colors;
    const letters = ['P', 'U', 'S', 'Č', 'P', 'S', 'N'];
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final goal = store.weeklyGoal;
    final summary = [
      goal == 0
          ? countLabel(store.thisWeek, 'trening', 'treninga', 'treninga')
          : '${store.thisWeek} od $goal ove nedelje',
      if (store.streak > 0) '${countLabel(store.streak, 'nedelja', 'nedelje', 'nedelja')} zaredom',
    ].join(' · ');

    return Semantics(
      label: summary,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++)
                  Builder(
                    builder: (context) {
                      final day = DateTime(monday.year, monday.month, monday.day + i);
                      final done = sessionsOn(store.sessions, day).isNotEmpty;
                      final isToday = day == today;
                      final planned = !done && !day.isBefore(today) && store.plannedOn(day) != null;
                      return Column(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done ? c.ink : null,
                              border: Border.all(
                                color: done || isToday || planned ? c.ink : c.border,
                                width: isToday ? 2.5 : (planned ? 1.5 : 1.5),
                              ),
                            ),
                            child: done
                                ? Icon(ClIcons.check, size: 15, color: c.bg)
                                : planned && !isToday
                                ? Center(
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: ClSpace.s1),
                          Text(
                            letters[i],
                            style: cl.text.label.copyWith(color: isToday ? c.ink : c.inkMuted),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: ClSpace.s3),
            Text(summary, style: cl.text.body.copyWith(color: c.inkMuted)),
          ],
        ),
      ),
    );
  }
}

/// "Podseti me" once, after a finished workout. Asks the phone for
/// permission only when the user says yes.
class _ReminderOffer extends StatelessWidget {
  const _ReminderOffer();

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    return Container(
      padding: const EdgeInsets.all(ClSpace.s4),
      decoration: BoxDecoration(
        color: cl.colors.surface,
        borderRadius: BorderRadius.circular(ClRadius.sm),
        boxShadow: ClElevation.card(cl.colors.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Da te podsetimo na sledeći trening?', style: cl.text.bodyStrong),
          const SizedBox(height: ClSpace.s1),
          Text(
            'U ${store.reminderSettings.timeLabel} na dan treninga. Vreme menjaš u podešavanjima.',
            style: cl.text.body.copyWith(color: cl.colors.inkMuted),
          ),
          gapS,
          Row(
            children: [
              Expanded(
                child: ClButton(
                  label: 'Podseti me',
                  expand: true,
                  onPressed: () async {
                    final ok = await store.setRemindersEnabled(true);
                    if (!context.mounted) return;
                    showUndoToast(
                      context,
                      ok
                          ? 'Podsetnik u ${store.reminderSettings.timeLabel} na dan treninga.'
                          : 'Telefon ne dozvoljava obaveštenja. Uključi ih u podešavanjima telefona.',
                    );
                  },
                ),
              ),
              const SizedBox(width: ClSpace.s2),
              ClButton(
                label: 'Ne sada',
                variant: ClButtonVariant.text,
                onPressed: store.dismissReminderOffer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Before the very first workout: how it goes, in three short lines, so
/// nothing on the next screen is a surprise.
class _FirstWorkoutSteps extends StatelessWidget {
  const _FirstWorkoutSteps();

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    final c = cl.colors;
    const steps = [
      ('Brojevi su već upisani', 'Menjaš ih sa − i +, a ako ne znaš koliko, kreni lakše.'),
      ('Završi set', 'Odmor se meri sam. Ti samo dišeš.'),
      ('Na kraju: tvoji početni rezultati', 'Od njih se meri svaki sledeći trening.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Kako ide', style: cl.text.label),
        const SizedBox(height: ClSpace.s2),
        for (final (i, (title, text)) in steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: ClSpace.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: cl.text.bodyStrong.copyWith(color: c.bg, fontSize: 14)),
                ),
                const SizedBox(width: ClSpace.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: cl.text.bodyStrong),
                      Text(text, style: cl.text.body.copyWith(color: c.inkMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One sentence from the trainer, in their voice, with their face.
class _CreatorQuote extends StatelessWidget {
  const _CreatorQuote({required this.creator, required this.text});

  final Creator creator;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cl = context.cl;
    return ClPressable(
      onPressed: () => pushScreen(context, CreatorProfileScreen(creatorId: creator.id)),
      semanticLabel: '${creator.name}: $text',
      radius: ClRadius.sm,
      builder: (context, pressed) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClAvatar(name: creator.name, image: photoOf(creator.photo), size: 40),
          const SizedBox(width: ClSpace.s3),
          Expanded(
            child: Text('„$text”', style: cl.text.bodyStrong.copyWith(fontSize: 17, height: 24 / 17)),
          ),
        ],
      ),
    );
  }
}

/// First open: no plan and no workouts yet. The plan is already picked from
/// the onboarding answers, so the next tap starts it.
class _WelcomeToday extends StatelessWidget {
  const _WelcomeToday();

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final profile = store.profile;
    final ranked = rankedPrograms(context);
    final best = ranked.firstOrNull;
    return AppScreen(
      bottom: best == null ? null : PlanStartButton(program: best.program),
      children: [
        const SizedBox(height: ClSpace.s4),
        ClScreenTitle(
          label: 'Zdravo, ${profile?.name.split(' ').first ?? ''}',
          title: best == null ? 'Dobrodošlica.' : 'Tvoj plan je spreman.',
        ),
        if (best != null) ...[
          gapS,
          PlanRecommendation(program: best.program, reasons: best.reasons),
          const SizedBox(height: ClSpace.s2),
          Align(
            alignment: Alignment.centerLeft,
            child: ClButton(
              label: 'Vidi još opcija',
              variant: ClButtonVariant.text,
              icon: ClIcons.arrowRight,
              onPressed: () => pushScreen(context, const PlanFinderScreen()),
            ),
          ),
        ],
        gap,
        const _CreatorCarousel(),
      ],
    );
  }
}

/// Has trained before but has no active plan: proof of what was done, then
/// programs to continue with.
class _BetweenPlansToday extends StatelessWidget {
  const _BetweenPlansToday({required this.greeting});

  final Widget greeting;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final c = cl.colors;
    final records = store.sessions.fold(0, (n, s) => n + s.prCount);
    return AppScreen(
      children: [
        const SizedBox(height: ClSpace.s4),
        greeting,
        gapS,
        ClPopBlock(
          color: c.lilac,
          sticker: store.streak > 0 ? ClSticker('Niz ${store.streak} ned.') : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nova nedelja.', style: cl.text.displayL),
              const SizedBox(height: ClSpace.s2),
              Text(
                [
                  'Do sada ${countLabel(store.sessions.length, 'trening', 'treninga', 'treninga')}',
                  if (records > 0) countLabel(records, 'rekord', 'rekorda', 'rekorda'),
                ].join(' · '),
                style: cl.text.bodyStrong,
              ),
              const SizedBox(height: ClSpace.s1),
              Text('Izaberi sledeći program i nastavi u istom ritmu.', style: cl.text.body),
              const SizedBox(height: ClSpace.s6),
              ClButton(
                label: 'Pronađi plan',
                icon: ClIcons.arrowRight,
                expand: true,
                onPressed: () => pushScreen(context, const PlanFinderScreen()),
              ),
            ],
          ),
        ),
        gap,
        const _ProgramCarousel(title: 'Sledeći korak'),
        gap,
        const _CreatorCarousel(),
      ],
    );
  }
}

/// Horizontal list that runs to the screen edges inside the padded column.
class _Bleed extends StatelessWidget {
  const _Bleed({required this.height, required this.children});

  final double height;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      // Extra room under the cards so their shadows are not cut off.
      builder: (context, box) => SizedBox(
        height: height + ClSpace.s3,
        child: OverflowBox(
          minWidth: box.maxWidth + ClSpace.s4 * 2,
          maxWidth: box.maxWidth + ClSpace.s4 * 2,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(ClSpace.s4, 0, ClSpace.s4, ClSpace.s3),
            itemCount: children.length,
            separatorBuilder: (_, _) => const SizedBox(width: ClSpace.s3),
            itemBuilder: (_, i) => children[i],
          ),
        ),
      ),
    );
  }
}

/// Programs ranked for the user's profile, as pop color cards.
class _ProgramCarousel extends StatelessWidget {
  const _ProgramCarousel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final profile = store.profile;
    if (profile == null) return const SizedBox.shrink();
    final PlanCriteria criteria = (
      goal: profile.goal,
      level: profile.experience,
      place: profile.place,
      daysPerWeek: profile.daysPerWeek,
    );
    final ranked = [
      for (final p in store.allPrograms.where((p) => p.workoutIds.isNotEmpty))
        (program: p, score: matchProgram(p, criteria, store.fitOf(p)).score),
    ]..sort((a, b) => b.score.compareTo(a.score));
    if (ranked.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClSectionHeader(
          label: title,
          trailing: ClButton(
            label: 'Sve',
            variant: ClButtonVariant.text,
            onPressed: () => HomeShell.goTo(context, AppTab.discover),
          ),
        ),
        _Bleed(
          height: 210,
          children: [
            for (final r in ranked.take(5))
              SizedBox(
                width: 230,
                child: ClPopBlock(
                  color: cl.colors.popFor(r.program.id),
                  semanticLabel: r.program.name,
                  onPressed: () => pushScreen(context, ProgramDetailScreen(programId: r.program.id)),
                  child: SizedBox(
                    height: 178,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClTag('${r.score}% za tebe'),
                        const SizedBox(height: ClSpace.s3),
                        Text(
                          r.program.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: cl.text.displayM.copyWith(fontSize: 26, height: 28 / 26),
                        ),
                        const SizedBox(height: ClSpace.s1),
                        Text(programMeta(r.program), style: cl.text.body.copyWith(fontSize: 13)),
                        const Spacer(),
                        Row(
                          children: [
                            ClAvatar(
                              name: store.creator(r.program.creatorId)?.name ?? '',
                              image: photoOf(store.creator(r.program.creatorId)?.photo),
                              color: cl.colors.surface,
                            ),
                            const SizedBox(width: ClSpace.s2),
                            Expanded(
                              child: Text(
                                store.creator(r.program.creatorId)?.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: cl.text.bodyStrong.copyWith(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Creators to follow, as portrait cards with their photo.
class _CreatorCarousel extends StatelessWidget {
  const _CreatorCarousel();

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final c = cl.colors;
    final creators = store.creators.where((x) => !x.isMine).toList()
      ..sort((a, b) => b.followers.compareTo(a.followers));
    if (creators.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClSectionHeader(label: 'Treneri'),
        // Portrait cards: the trainer's photo is the card, the name sits on it.
        _Bleed(
          height: 208,
          children: [
            for (final x in creators)
              ClPressable(
                onPressed: () => pushScreen(context, CreatorProfileScreen(creatorId: x.id)),
                semanticLabel: '${x.name}, @${x.handle}, ${followersLabel(x.followers)}',
                radius: ClRadius.sm,
                builder: (context, pressed) => AnimatedScale(
                  duration: context.motion(ClMotion.fast),
                  scale: pressed ? 0.97 : 1,
                  child: SizedBox(
                    width: 156,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(ClRadius.sm),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(color: c.popFor(x.id)),
                          if (photoOf(x.photo) case final photo?) ClPhoto(image: photo, placeholderLabel: ''),
                          const ClPhotoScrim(coverage: 0.6),
                          if (followStatus(store, x.id) != ClFollowStatus.none)
                            Positioned(
                              top: ClSpace.s2,
                              left: ClSpace.s2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.bg,
                                  borderRadius: BorderRadius.circular(ClRadius.full),
                                ),
                                child: Text(
                                  followStatus(store, x.id) == ClFollowStatus.subscribed
                                      ? 'Pretplata'
                                      : 'Pratiš',
                                  style: cl.text.label.copyWith(color: c.ink, fontSize: 11),
                                ),
                              ),
                            ),
                          Positioned(
                            left: ClSpace.s3,
                            right: ClSpace.s3,
                            bottom: ClSpace.s3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  x.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: cl.text.bodyStrong.copyWith(
                                    color: c.onPhoto,
                                    fontSize: 16,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  x.tagline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: cl.text.label.copyWith(color: c.onPhoto.withValues(alpha: 0.85)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
