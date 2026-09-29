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
}
