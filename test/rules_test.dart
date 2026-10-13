import 'package:chalkline/domain/models.dart';
import 'package:chalkline/domain/rules.dart';
import 'package:chalkline/ui/format.dart';
import 'package:flutter_test/flutter_test.dart';

Session session(DateTime finished, {String exerciseId = 'bench', List<SetLog>? sets}) => Session(
  id: 's${finished.microsecondsSinceEpoch}',
  workoutId: 'w',
  workoutName: 'Push day',
  creatorId: 'c',
  creatorName: 'Marko',
  startedAt: finished.subtract(const Duration(hours: 1)),
  finishedAt: finished,
  exercises: [
    SessionExercise(
      exerciseId: exerciseId,
      name: 'Bench press',
      muscle: Muscle.chest,
      target: '3 × 8',
      restSeconds: 90,
      sets: sets ?? const [SetLog(kg: 80, reps: 8, done: true)],
    ),
  ],
);

void main() {
  // Wednesday.
  final now = DateTime(2026, 9, 30, 18);

  group('weekStart', () {
    test('is Monday midnight', () {
      expect(weekStart(now), DateTime(2026, 9, 28));
      expect(weekStart(DateTime(2026, 9, 28, 0, 5)), DateTime(2026, 9, 28));
      expect(weekStart(DateTime(2026, 10, 4, 23)), DateTime(2026, 9, 28));
    });
  });

  group('streakWeeks', () {
    test('counts consecutive weeks including this one', () {
      final s = [
        session(DateTime(2026, 9, 29)),
        session(DateTime(2026, 9, 22)),
        session(DateTime(2026, 9, 15)),
      ];
      expect(streakWeeks(s, now), 3);
    });

    test('an empty current week does not break the streak yet', () {
      final s = [session(DateTime(2026, 9, 22)), session(DateTime(2026, 9, 16))];
      expect(streakWeeks(s, now), 2);
    });

    test('a missed full week resets it', () {
      final s = [session(DateTime(2026, 9, 29)), session(DateTime(2026, 9, 15))];
      expect(streakWeeks(s, now), 1);
    });

    test('no sessions is zero', () => expect(streakWeeks(const [], now), 0));
  });

  test('sessionsThisWeek counts only since Monday', () {
    final s = [session(DateTime(2026, 9, 28, 7)), session(DateTime(2026, 9, 27, 20))];
    expect(sessionsThisWeek(s, now), 1);
  });

  group('records', () {
    test('first time is never a record', () {
      expect(isRecord(null, const SetLog(kg: 100, reps: 5, done: true)), isFalse);
    });

    test('heavier estimated 1RM beats the best', () {
      final best = bestScore([session(DateTime(2026, 9, 22))], 'bench');
      expect(best, closeTo(e1rm(80, 8), 1e-9));
      expect(isRecord(best, const SetLog(kg: 85, reps: 8, done: true)), isTrue);
      expect(isRecord(best, const SetLog(kg: 80, reps: 8, done: true)), isFalse);
      expect(isRecord(best, const SetLog(kg: 80, reps: 9, done: true)), isTrue);
    });

    test('bodyweight sets compare on reps', () {
      final h = [
        session(DateTime(2026, 9, 22), sets: const [SetLog(kg: 0, reps: 6, done: true)]),
      ];
      final best = bestScore(h, 'bench');
      expect(best, 6);
      expect(isRecord(best, const SetLog(kg: 0, reps: 7, done: true)), isTrue);
    });

    test('previousSets returns the latest session', () {
      final h = [
        session(DateTime(2026, 9, 15), sets: const [SetLog(kg: 70, reps: 8, done: true)]),
        session(
          DateTime(2026, 9, 22),
          sets: const [SetLog(kg: 75, reps: 8, done: true), SetLog(kg: 75, reps: 7, done: true)],
        ),
      ];
      final prev = previousSets(h, 'bench');
      expect(prev.map((s) => s.kg), [75, 75]);
      expect(previousSets(h, 'squat'), isEmpty);
    });
  });

  group('equipment', () {
    const bench = Exercise(
      id: 'b',
      creatorId: 'c1',
      name: 'Bench',
      muscle: Muscle.chest,
      equipment: {Equipment.barbell, Equipment.bench},
    );
    const pushup = Exercise(
      id: 'p',
      creatorId: 'c2',
      name: 'Sklekovi',
      muscle: Muscle.chest,
      equipment: {Equipment.bodyweight},
    );
    const dbPress = Exercise(
      id: 'd',
      creatorId: 'c1',
      name: 'Potisak bučicama',
      muscle: Muscle.chest,
      equipment: {Equipment.dumbbell},
    );
    const row = Exercise(
      id: 'r',
      creatorId: 'c1',
      name: 'Veslanje',
      muscle: Muscle.back,
      equipment: {Equipment.dumbbell},
    );

    test('canDo needs every item; bodyweight is always available', () {
      expect(canDo(bench, {Equipment.barbell}), isFalse);
      expect(canDo(bench, {Equipment.barbell, Equipment.bench}), isTrue);
      expect(canDo(pushup, {}), isTrue);
    });

    test('substitutes prefer a similar name over the same creator', () {
      const ohp = Exercise(
        id: 'o',
        creatorId: 'c1',
        name: 'Rameni potisak',
        muscle: Muscle.shoulders,
        equipment: {Equipment.barbell},
      );
      const lateral = Exercise(
        id: 'l',
        creatorId: 'c1',
        name: 'Odručenje',
        muscle: Muscle.shoulders,
        equipment: {Equipment.dumbbell},
      );
      const dbOhp = Exercise(
        id: 'dp',
        creatorId: 'c2',
        name: 'Rameni potisak bučicama',
        muscle: Muscle.shoulders,
        equipment: {Equipment.dumbbell},
      );
      expect(substitutes(ohp, [lateral, dbOhp], {Equipment.dumbbell}).map((e) => e.id), ['dp', 'l']);
    });

    test('substitutes: same muscle, doable, same creator first', () {
      final alts = substitutes(bench, [bench, pushup, dbPress, row], {Equipment.dumbbell});
      expect(alts.map((e) => e.id), ['d', 'p']);
    });

    test('programFit counts unique exercises', () {
      const w = Workout(
        id: 'w',
        creatorId: 'c1',
        name: 'W',
        exercises: [
          WorkoutExercise(exerciseId: 'b'),
          WorkoutExercise(exerciseId: 'p'),
          WorkoutExercise(exerciseId: 'b'),
        ],
      );
      const p = Program(id: 'pr', creatorId: 'c1', name: 'P', workoutIds: ['w']);
      final fit = programFit(p, {'w': w}, {'b': bench, 'p': pushup}, {Equipment.dumbbell});
      expect(fit, (doable: 1, total: 2));
    });
  });

  test('weeklyVolume buckets by week, oldest first', () {
    final v = weeklyVolume([session(DateTime(2026, 9, 29)), session(DateTime(2026, 9, 21))], now, 3);
    expect(v.map((x) => x.week), [DateTime(2026, 9, 14), DateTime(2026, 9, 21), DateTime(2026, 9, 28)]);
    expect(v.map((x) => x.volume), [0, 640, 640]);
  });

  test('plural follows Serbian rules', () {
    expect([1, 2, 5, 11, 12, 21, 22, 25].map((n) => plural(n, 'nedelja', 'nedelje', 'nedelja')).toList(), [
      'nedelja',
      'nedelje',
      'nedelja',
      'nedelja',
      'nedelja',
      'nedelja',
      'nedelje',
      'nedelja',
    ]);
    expect(plural(3, 'trening', 'treninga', 'treninga'), 'treninga');
    expect(plural(1, 'trening', 'treninga', 'treninga'), 'trening');
  });

  group('projectSchedule', () {
    final plan = UserPlan(
      id: 'p',
      programId: 'x',
      creatorId: 'c',
      name: 'N',
      workoutIds: const ['A', 'B', 'C'],
      weeks: 8,
      daysPerWeek: 3,
      startedAt: DateTime(2026, 9, 1),
      nextIndex: 1,
      trainingDays: const {1, 3, 5},
    );

    test('puts the next workouts on training days, starting today', () {
      // Wednesday 30. 9. is a training day.
      final s = projectSchedule(plan, const [], now, DateTime(2026, 10, 6));
      expect(s, {DateTime(2026, 9, 30): 'B', DateTime(2026, 10, 2): 'C', DateTime(2026, 10, 5): 'A'});
    });

    test('a workout done today moves the forecast to the next training day', () {
      final s = projectSchedule(plan, [session(DateTime(2026, 9, 30, 8))], now, DateTime(2026, 10, 5));
      expect(s.keys.first, DateTime(2026, 10, 2));
      expect(s.values.first, 'B');
    });

    test('no training days, no forecast', () {
      expect(
        projectSchedule(plan.copyWith(trainingDays: {}), const [], now, DateTime(2026, 10, 30)),
        isEmpty,
      );
    });

    test('sessionsOn matches the calendar day', () {
      final h = [session(DateTime(2026, 9, 29, 23, 30)), session(DateTime(2026, 9, 30, 0, 10))];
      expect(sessionsOn(h, DateTime(2026, 9, 29)), hasLength(1));
    });

    test('default training days spread rest', () {
      expect(defaultTrainingDays(3), {1, 3, 5});
      expect(defaultTrainingDays(4), {1, 2, 4, 5});
    });
  });

  test('matchProgram ranks the closest program first', () {
    const criteria = (goal: Goal.strength, level: Experience.beginner, place: Place.gym, daysPerWeek: 3);
    const exact = Program(
      id: 'a',
      creatorId: 'c',
      name: 'A',
      workoutIds: ['w'],
      goal: Goal.strength,
      level: Experience.beginner,
      place: Place.gym,
      daysPerWeek: 3,
    );
    const home = Program(
      id: 'b',
      creatorId: 'c',
      name: 'B',
      workoutIds: ['w'],
      goal: Goal.general,
      level: Experience.beginner,
      place: Place.home,
      daysPerWeek: 3,
    );
    final a = matchProgram(exact, criteria, (doable: 4, total: 4));
    final b = matchProgram(home, criteria, (doable: 2, total: 4));
    expect(a.score, 100);
    expect(a.reasons, containsAll(['Snaga', 'Početnik', 'Teretana', '3× nedeljno', 'Imaš svu opremu']));
    expect(b.score, lessThan(a.score));
  });

  group('progression: next time\'s numbers', () {
    Progression? next(List<SetLog> last, {bool bodyweight = false}) =>
        nextProgression(last: last, repsMin: 8, repsMax: 10, step: 2.5, bodyweight: bodyweight);

    test('the first time there is nothing to move on from', () {
      expect(next(const []), isNull);
    });

    test('easy sets get heavier, back to the bottom of the range', () {
      final p = next(const [SetLog(kg: 20, reps: 8, rir: 3), SetLog(kg: 20, reps: 8, rir: 3)])!;
      expect(p.kind, ProgressionKind.heavier);
      expect(p.wasEasy, isTrue);
      expect(p.sets.map((s) => (s.kg, s.reps)), [(22.5, 8), (22.5, 8)]);
    });

    test('the top of the range gets heavier too', () {
      final p = next(const [SetLog(kg: 40, reps: 10, rir: 2), SetLog(kg: 40, reps: 10)])!;
      expect(p.kind, ProgressionKind.heavier);
      expect(p.wasEasy, isFalse);
      expect(p.sets.first.kg, 42.5);
    });

    test('in the range: same weight, one more rep', () {
      final p = next(const [SetLog(kg: 30, reps: 8, rir: 2), SetLog(kg: 30, reps: 9, rir: 2)])!;
      expect(p.kind, ProgressionKind.moreReps);
      expect(p.sets.map((s) => (s.kg, s.reps)), [(30.0, 9), (30.0, 10)]);
    });

    test('hard or short of the range: the same numbers again', () {
      final p = next(const [SetLog(kg: 50, reps: 6, rir: 0), SetLog(kg: 50, reps: 7, rir: 0)])!;
      expect(p.kind, ProgressionKind.same);
      expect(p.sets.map((s) => (s.kg, s.reps)), [(50.0, 6), (50.0, 7)]);
    });

    test('bodyweight moves on by reps, past the range', () {
      final p = next(const [SetLog(kg: 0, reps: 10, rir: 3)], bodyweight: true)!;
      expect(p.kind, ProgressionKind.moreReps);
      expect(p.sets.single.reps, 11);
    });

    test('weights start and step by equipment', () {
      expect(weightSteps({Equipment.barbell, Equipment.bench}), (start: 20.0, step: 2.5));
      expect(weightSteps({Equipment.dumbbell}), (start: 2.0, step: 2.0));
      expect(weightSteps({Equipment.machine}), (start: 10.0, step: 5.0));
    });
  });

  group('how exercises are measured', () {
    Exercise ex(Set<Equipment> eq, {Measure? measure}) =>
        Exercise(id: 'x', creatorId: 'c', name: 'X', muscle: Muscle.core, equipment: eq, measure: measure);

    test('nothing to load counts reps, a load counts weight', () {
      expect(ex({Equipment.bodyweight}).measured, Measure.reps);
      expect(ex({Equipment.pullupBar}).measured, Measure.reps, reason: 'pull-ups');
      expect(ex({Equipment.band}).measured, Measure.reps);
      expect(ex({Equipment.barbell, Equipment.bench}).measured, Measure.weight);
      expect(ex({Equipment.dumbbell}).measured, Measure.weight);
      expect(
        ex({Equipment.bodyweight}, measure: Measure.time).measured,
        Measure.time,
        reason: 'set by the trainer',
      );
    });

    test('a held exercise moves on by five seconds', () {
      final p = nextProgression(
        last: const [SetLog(kg: 0, reps: 30, rir: 2)],
        repsMin: 30,
        repsMax: 45,
        step: 2.5,
        bodyweight: true,
        repStep: 5,
      )!;
      expect(p.kind, ProgressionKind.moreReps);
      expect(p.sets.single.reps, 35);
    });

    test('prescriptions read in seconds for held exercises', () {
      const we = WorkoutExercise(exerciseId: 'x', sets: 3, repsMin: 30, repsMax: 45);
      expect(we.targetFor(Measure.time), '3 × 30–45 s');
      expect(we.targetFor(Measure.reps), '3 × 30–45');
      expect(formatSeconds(45), '45 s');
      expect(formatSeconds(90), '1:30');
    });
  });

  group('month recap', () {
    test('adds up the month: workouts, kilograms, the biggest gain, the best run of days', () {
      final sessions = [
        session(DateTime(2026, 9, 30, 18), sets: const [SetLog(kg: 100, reps: 5, done: true)]),
        session(DateTime(2026, 10, 1, 18), sets: const [SetLog(kg: 60, reps: 8, done: true)]),
        session(DateTime(2026, 10, 2, 18), sets: const [SetLog(kg: 62.5, reps: 8, done: true)]),
        session(DateTime(2026, 10, 3, 18), sets: const [SetLog(kg: 65, reps: 8, done: true)]),
        session(DateTime(2026, 10, 10, 18), sets: const [SetLog(kg: 67.5, reps: 8, done: true)]),
      ];
      final r = monthRecap(sessions, DateTime(2026, 10, 12));
      expect(r.workouts, 4, reason: 'September is not counted');
      expect(r.volume, (60 + 62.5 + 65 + 67.5) * 8);
      expect(r.biggestGain?.from, 60);
      expect(r.biggestGain?.to, 67.5);
      expect(r.bestStreakDays, 3);
    });

    test('a month without training is empty', () {
      final r = monthRecap(const [], DateTime(2026, 10));
      expect(r.workouts, 0);
      expect(r.biggestGain, isNull);
    });

    test('kilograms as something to picture', () {
      expect(volumeComparison(38000), 'Kao 3 autobusa.');
      expect(volumeComparison(3200), 'Kao 2 automobila.');
      expect(volumeComparison(5000), 'Kao jedan slon.');
      expect(volumeComparison(100), 'Svaki kilogram se računa.');
    });
  });
}
