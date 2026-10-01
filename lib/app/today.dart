import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import '../ui/chalkline_ui.dart';
import 'common.dart';
import 'creator_profile.dart';
import 'plan_finder.dart';
import 'plan_screen.dart';
import 'program_detail.dart';
import 'shell.dart';
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
    final c = cl.colors;
    final plan = store.plan;
    final next = store.nextWorkout;
    final active = store.active;
    final today = store.now;

    final workoutColor = next == null ? c.lime : c.popFor(next.id);
    final week = ClPopBlock(
      color: workoutColor == c.lilac ? c.peach : c.lilac,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  store.weeklyGoal == 0
                      ? '${countLabel(store.thisWeek, 'trening', 'treninga', 'treninga')} ove nedelje'
                      : '${store.thisWeek} od ${store.weeklyGoal} ove nedelje',
                  style: cl.text.bodyStrong.copyWith(fontSize: 17),
                ),
              ),
              Text('Niz ${store.streak} ned.', style: cl.text.bodyStrong.copyWith(fontSize: 13)),
            ],
          ),
          if (store.weeklyGoal > 0) ...[
            const SizedBox(height: ClSpace.s3),
            ClSegmentBar(
              total: store.weeklyGoal,
              done: store.thisWeek.clamp(0, store.weeklyGoal),
              onPop: true,
            ),
          ],
        ],
      ),
    );

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
    final title = active?.workoutName ?? workout.name;
    final day = dateOnly(today);
    return AppScreen(
      bottom: ClButton.block(
        label: active == null ? 'Počni trening' : 'Nastavi trening',
        onPressed: () {
          store.startToday();
          pushScreen(context, const WorkoutSessionScreen());
        },
      ),
      children: [
        const SizedBox(height: ClSpace.s4),
        greeting,
        gapS,
        ClPopBlock(
          color: workoutColor,
          sticker: ClSticker(changed?.note ?? 'Nedelja ${plan.currentWeek}/${plan.weeks}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                todayPlan == null ? 'Danas je odmor · možeš i da treniraš' : 'Danas · ${creator?.name ?? ''}',
                style: cl.text.bodyStrong.copyWith(fontSize: 13),
              ),
              const SizedBox(height: ClSpace.s1),
              Semantics(header: true, child: Text(title, maxLines: 2, style: cl.text.displayL)),
              const SizedBox(height: ClSpace.s1),
              Text(
                '${countLabel(exercises.length, 'vežba', 'vežbe', 'vežbi')} · ~${workout.estimatedMinutes} min',
                style: cl.text.body,
              ),
              const SizedBox(height: ClSpace.s8),
            ],
          ),
        ),
        if (active == null) ...[
          const SizedBox(height: ClSpace.s2),
          Wrap(
            spacing: ClSpace.s2,
            children: [
              if (todayPlan != null) ...[
                if (changed?.note != 'Kraća verzija')
                  ClActionChip(
                    label: 'Kraća verzija',
                    icon: ClIcons.timer,
                    onPressed: () => store.quickVersionOn(day),
                  ),
                ClActionChip(
                  label: 'Pomeri za sutra',
                  icon: ClIcons.arrowRight,
                  onPressed: () => store.shiftFrom(day),
                ),
                ClActionChip(label: 'Odmor danas', icon: ClIcons.rest, onPressed: () => store.restOn(day)),
              ],
              if (changed != null)
                ClActionChip(
                  label: 'Vrati na plan',
                  icon: ClIcons.sync,
                  onPressed: () => store.setDayPlan(day, null),
                ),
            ],
          ),
        ],
        gapS,
        week,
        gap,
        ClSectionHeader(
          label: plan.name,
          trailing: ClButton(
            label: 'Moj plan',
            variant: ClButtonVariant.text,
            onPressed: () => pushScreen(context, const PlanScreen()),
          ),
        ),
        for (final (i, we) in exercises.indexed)
          if (store.resolveExercise(we.exerciseId) case final e?)
            ClExerciseRow(
              index: i + 1,
              name: e.name,
              detail: _detail(we.target, previousSets(store.sessions, e.id).firstOrNull),
            ),
        if (active != null) ...[
          gapS,
          ClNotice(
            'Trening je započet ${formatDuration(store.now.difference(active.startedAt))} ranije. Nastavi gde si ${store.profile?.says('stao', 'stala') ?? 'stao'}.',
          ),
        ],
      ],
    );
  }

  static String _detail(String target, SetLog? last) =>
      last == null ? target : '$target · Prošli put ${setLabel(last)}';
}

/// First open: no plan and no workouts yet. Sells the idea, then shows real
/// creators and programs so the next tap is concrete.
class _WelcomeToday extends StatelessWidget {
  const _WelcomeToday();

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final cl = context.cl;
    final c = cl.colors;
    final profile = store.profile;
    return AppScreen(
      children: [
        const SizedBox(height: ClSpace.s4),
        Text(
          '${profile?.says('Dobro došao', 'Dobro došla') ?? 'Dobro došao'}, ${profile?.name.split(' ').first ?? ''}',
          style: cl.text.label,
        ),
        const SizedBox(height: ClSpace.s3),
        ClPopBlock(
          color: c.lime,
          sticker: const ClSticker('Novo'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tvoj trener.\nTvoj plan.', style: cl.text.displayL),
              const SizedBox(height: ClSpace.s3),
              Text(
                'Treniraj po programu trenera kog pratiš. Svaki set se beleži, a napredak vidiš odmah.',
                style: cl.text.body,
              ),
              const SizedBox(height: ClSpace.s6),
              ClButton(
                label: 'Pronađi plan za sebe',
                icon: ClIcons.arrowRight,
                expand: true,
                onPressed: () => pushScreen(context, const PlanFinderScreen()),
              ),
            ],
          ),
        ),
        gap,
        const _ProgramCarousel(title: 'Programi za tebe'),
        gap,
        const _CreatorCarousel(),
        gap,
        ClPopBlock(
          color: c.peach,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Kako radi', style: cl.text.displayM.copyWith(fontSize: 22, height: 26 / 22)),
              const SizedBox(height: ClSpace.s4),
              for (final (i, step) in const [
                'Izaberi trenera kog već pratiš.',
                'Uzmi njegov program kao svoj plan.',
                'Treniraj set po set. Aplikacija pamti sve.',
              ].indexed) ...[
                if (i > 0) const SizedBox(height: ClSpace.s3),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.onPop, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: cl.text.bodyStrong.copyWith(color: c.lime)),
                    ),
                    const SizedBox(width: ClSpace.s3),
                    Expanded(child: Text(step, style: cl.text.bodyStrong)),
                  ],
                ),
              ],
            ],
          ),
        ),
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
      builder: (context, box) => SizedBox(
        height: height,
        child: OverflowBox(
          minWidth: box.maxWidth + ClSpace.s4 * 2,
          maxWidth: box.maxWidth + ClSpace.s4 * 2,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ClSpace.s4),
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

/// Creators to follow, as white cards with their pop color avatar.
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
        _Bleed(
          height: 176,
          children: [
            for (final x in creators)
              ClPressable(
                onPressed: () => pushScreen(context, CreatorProfileScreen(creatorId: x.id)),
                semanticLabel: '${x.name}, @${x.handle}',
                radius: ClRadius.sm,
                builder: (context, pressed) => Container(
                  width: 148,
                  padding: const EdgeInsets.all(ClSpace.s3),
                  decoration: BoxDecoration(
                    color: pressed ? c.surfaceRaised : c.surface,
                    borderRadius: BorderRadius.circular(ClRadius.sm),
                    boxShadow: ClElevation.card(c.shadow),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClAvatar(
                        name: x.name,
                        size: 56,
                        ring: followStatus(store, x.id) != ClFollowStatus.none,
                      ),
                      const Spacer(),
                      Text(x.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: cl.text.bodyStrong),
                      const SizedBox(height: 2),
                      Text(
                        '@${x.handle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: cl.text.label,
                      ),
                      const SizedBox(height: ClSpace.s1),
                      switch (followStatus(store, x.id)) {
                        ClFollowStatus.subscribed => const ClTag('Pretplata', variant: ClTagVariant.pr),
                        ClFollowStatus.following => const ClTag(
                          'Pratiš',
                          variant: ClTagVariant.active,
                          icon: ClIcons.check,
                        ),
                        ClFollowStatus.none => Text(
                          followersLabel(x.followers),
                          style: cl.text.label.copyWith(color: c.ink),
                        ),
                      },
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
