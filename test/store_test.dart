import 'dart:convert';

import 'package:chalkline/data/app_store.dart';
import 'package:chalkline/data/storage.dart';
import 'package:chalkline/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

const gymProfile = UserProfile(
  name: 'Ana',
  goal: Goal.strength,
  experience: Experience.beginner,
  place: Place.gym,
  daysPerWeek: 3,
  equipment: Equipment.gym,
);

void main() {
  late DateTime clock;
  late MemoryStore storage;
  late AppStore store;

  setUp(() async {
    clock = DateTime(2026, 9, 30, 18);
    storage = MemoryStore();
    store = AppStore(storage: storage, clock: () => clock);
    await store.load();
    store.completeOnboarding(gymProfile);
  });

  group('calendar: the plan suggests, the user decides', () {
    // p_m_start: Celo telo A / B on Mon, Wed, Fri. The clock is Wednesday 30. 9.
    final wed = DateTime(2026, 9, 30);
    final thu = DateTime(2026, 10, 1);
    final fri = DateTime(2026, 10, 2);
    final mon = DateTime(2026, 10, 5);
    final wedNext = DateTime(2026, 10, 7);
    const a = 'w_m_full_a';
    const b = 'w_m_full_b';

    Map<DateTime, String> week() => store.schedule(DateTime(2026, 10, 8));

    setUp(() => store.startProgram('p_m_start'));

    test('the forecast follows the training days', () {
      expect(week(), {wed: a, fri: b, mon: a, wedNext: b});
    });

    test('a rest day moves the next workouts forward', () {
      store.restOn(wed);
      expect(week(), {fri: a, mon: b, wedNext: a});
      expect(store.plannedOn(wed), isNull);
    });

    test('moving a day uses up the next rest day, the week after stays', () {
      expect(store.shiftFrom(wed), thu);
      expect(week(), {thu: a, fri: b, mon: a, wedNext: b});
    });

    test('a break of several days, then the plan continues', () {
      store.pause(wed, 7);
      expect(week(), {wedNext: a});
      expect(store.dayPlan(fri)!.note, 'Pauza');
    });

    test('training on a rest day takes the next workout', () {
      store.trainOn(thu);
      expect(week(), {wed: a, thu: b, fri: a, mon: b, wedNext: a});
    });

    test('another workout today; the plan\'s next one waits', () {
      store.swapWorkoutOn(wed, b);
      expect(week(), {wed: b, fri: a, mon: b, wedNext: a});
      store.startToday();
      store.finishSession();
      expect(store.nextWorkout!.id, a, reason: 'a different workout does not advance the rotation');
    });

    test('a shorter version keeps the rotation and is what today starts', () {
      final full = store.workoutsById[a]!.exercises;
      store.quickVersionOn(wed);
      final planned = store.plannedOn(wed)!;
      expect(planned.custom!.note, 'Kraća verzija');
      expect(planned.exercises.length, lessThanOrEqualTo(full.length));
      expect(planned.exercises.first.sets, full.first.sets - 1);
      expect(week(), {wed: a, fri: b, mon: a, wedNext: b});
      final session = store.startToday();
      expect(session.exercises.length, planned.exercises.length);
      expect(session.exercises.first.sets.length, planned.exercises.first.sets);
      store.finishSession();
      expect(store.nextWorkout!.id, b);
    });

    test('edited exercises only change that day', () {
      final list = [...store.workoutsById[a]!.exercises]..removeLast();
      store.editDayExercises(fri, [...store.workoutsById[b]!.exercises]..removeLast());
      expect(store.plannedOn(fri)!.exercises.length, store.workoutsById[b]!.exercises.length - 1);
      expect(store.plannedOn(wedNext)!.exercises.length, store.workoutsById[b]!.exercises.length);
      store.editDayExercises(wed, list);
      expect(store.startToday().exercises.length, list.length);
    });

    test('moving an edited day takes the edits along', () {
      store.quickVersionOn(wed);
      store.shiftFrom(wed);
      expect(store.dayPlan(wed)!.train, isFalse);
      expect(store.plannedOn(thu)!.custom!.note, 'Kraća verzija');
    });

    test('dragging a workout to a free day moves exactly that workout', () {
      expect(store.canMoveTraining(wed, thu), isTrue);
      store.moveTraining(wed, thu);
      expect(week(), {thu: a, fri: b, mon: a, wedNext: b});
      expect(store.dayPlan(wed)!.train, isFalse);
      // Back again: the usual week, no leftover changes.
      store.moveTraining(thu, wed);
      expect(week(), {wed: a, fri: b, mon: a, wedNext: b});
      expect(store.dayPlan(thu), isNull);
    });

    test('a workout cannot jump over another one, onto one or into the past', () {
      expect(store.canMoveTraining(wed, DateTime(2026, 10, 3)), isFalse, reason: 'Friday is in between');
      expect(store.canMoveTraining(wed, fri), isFalse, reason: 'Friday has a workout');
      expect(store.canMoveTraining(wed, DateTime(2026, 9, 29)), isFalse, reason: 'the past');
    });

    test('a moved day keeps its own changes', () {
      store.quickVersionOn(wed);
      store.moveTraining(wed, thu);
      expect(store.plannedOn(thu)!.custom!.note, 'Kraća verzija');
    });

    test('back to the plan', () {
      store.restOn(wed);
      store.setDayPlan(wed, null);
      expect(week(), {wed: a, fri: b, mon: a, wedNext: b});
    });

    test('a forgotten workout is logged on its own day', () {
      store.startSession(workoutId: a, loggedFor: DateTime(2026, 9, 28));
      store.toggleSet(0, 0);
      store.updateSet(0, 0, const SetLog(kg: 40, reps: 8));
      store.toggleSet(0, 0);
      final done = store.finishSession();
      expect(done.finishedAt!.day, 28);
      expect(store.nextWorkout!.id, b, reason: 'it counts for the plan');
    });

    test('day changes survive a restart', () async {
      store.quickVersionOn(wed);
      store.restOn(fri);
      await Future<void>.delayed(Duration.zero);
      final again = AppStore(storage: storage, clock: () => clock);
      await again.load();
      expect(again.dayPlan(fri)!.train, isFalse);
      expect(again.plannedOn(wed)!.custom!.note, 'Kraća verzija');
      expect(again.schedule(DateTime(2026, 10, 8)), {wed: a, mon: b, wedNext: a});
    });
  });

  test('starting a program creates a plan at its first workout', () {
    final plan = store.startProgram('p_m_start');
    expect(plan.workoutIds, ['w_m_full_a', 'w_m_full_b']);
    expect(store.nextWorkout!.name, 'Celo telo A');
    expect(plan.swaps, isEmpty);
    expect(store.isFollowing('c_marko'), isTrue);
  });

  test('home equipment pre-swaps exercises the user cannot do', () {
    store.updateProfile(gymProfile.copyWith(equipment: {Equipment.dumbbell}));
    final plan = store.startProgram('p_m_start');
    // Squat, bench, row, deadlift, OHP and lat pulldown all need gear the user lacks.
    expect(plan.swaps.keys, containsAll(['m_squat', 'm_bench']));
    for (final replacement in plan.swaps.values) {
      final e = store.exercisesById[replacement]!;
      expect(e.equipment.every((x) => x == Equipment.bodyweight || x == Equipment.dumbbell), isTrue);
    }
    final session = store.startSession();
    expect(session.exercises.first.swappedFrom, 'Čučanj');
    expect(
      session.exercises.first.noteBy,
      isNot('Marko Petrović'),
      reason: 'the swap is another creator\'s exercise',
    );
    // No workout gets the same replacement twice when alternatives exist.
    for (final id in store.plan!.workoutIds) {
      final names = store.workoutsById[id]!.exercises
          .map((we) => store.resolveExercise(we.exerciseId)!.id)
          .toList();
      expect(names.toSet().length, names.length, reason: id);
    }
  });

  test('a full session: confirm sets, record, finish, advance plan', () {
    store.startProgram('p_m_start');
    store.startSession();
    // First time: prescription fills reps, weight is required.
    expect(store.toggleSet(0, 0), ConfirmSetResult.needsWeight);
    store.updateSet(0, 0, const SetLog(kg: 60));
    expect(store.toggleSet(0, 0), ConfirmSetResult.done);
    expect(store.active!.exercises[0].sets[0].reps, 8);
    expect(store.active!.exercises[0].sets[0].isPr, isFalse);
    final first = store.finishSession();
    expect(first.exercises, hasLength(1), reason: 'exercises without done sets are dropped');
    expect(store.plan!.nextIndex, 1);
    expect(store.plan!.completed, 1);
    expect(store.thisWeek, 1);
    expect(store.streak, 1);

    // Next A session: empty fields take last time's values; heavier is a PR.
    clock = clock.add(const Duration(days: 2));
    store.setNextWorkout(0);
    store.startSession();
    expect(store.toggleSet(0, 0), ConfirmSetResult.done);
    expect(store.active!.exercises[0].sets[0].kg, 60);
    expect(store.active!.exercises[0].sets[0].isPr, isFalse);
    store.updateSet(0, 1, const SetLog(kg: 65, reps: 8));
    store.toggleSet(0, 1);
    expect(store.active!.exercises[0].sets[1].isPr, isTrue);
    // Equal to the in-session best is not another record.
    store.updateSet(0, 2, const SetLog(kg: 65, reps: 8));
    store.toggleSet(0, 2);
    expect(store.active!.exercises[0].sets[2].isPr, isFalse);
    final second = store.finishSession();
    expect(second.prCount, 1);
    expect(second.volume, 60 * 8 + 65 * 8 * 2);
  });

  test('first time: weight carries over from the previous set', () {
    store.startProgram('p_m_start');
    store.startSession();
    store.updateSet(0, 0, const SetLog(kg: 60, reps: 8));
    store.toggleSet(0, 0);
    expect(store.toggleSet(0, 1), ConfirmSetResult.done);
    expect(store.active!.exercises[0].sets[1].kg, 60);
  });

  test('history keeps names after the plan swaps', () {
    store.startProgram('p_m_start');
    store.setPlanSwap('m_squat', 'm_legpress');
    final s = store.startSession();
    expect(s.exercises.first.name, 'Nožna presa');
    expect(s.exercises.first.swappedFrom, 'Čučanj');
    store.setPlanSwap('m_squat', null);
    expect(store.plan!.swaps, isEmpty);
    expect(store.active!.exercises.first.name, 'Nožna presa');
  });

  test('session swap resets sets but keeps their count', () {
    store.startProgram('p_m_start');
    store.startSession();
    store.addSet(0);
    store.swapSessionExercise(0, 'm_legpress');
    final e = store.active!.exercises.first;
    expect(e.name, 'Nožna presa');
    expect(e.sets, hasLength(4));
    expect(e.sets.every((s) => !s.done), isTrue);
  });

  test('a one-off workout does not advance the plan', () {
    store.startProgram('p_m_start');
    store.startSession(workoutId: 'w_m_push');
    store.updateSet(0, 0, const SetLog(kg: 70, reps: 6));
    store.toggleSet(0, 0);
    store.finishSession();
    expect(store.plan!.nextIndex, 0);
    expect(store.sessions, hasLength(1));
  });

  test('subscriber content needs a subscription', () {
    final p = store.programsById['p_m_strength']!;
    expect(store.canAccess(p.visibility, p.creatorId), isFalse);
    store.subscribe('c_marko');
    expect(store.canAccess(p.visibility, p.creatorId), isTrue);
    store.unsubscribe('c_marko');
    expect(store.canAccess(p.visibility, p.creatorId), isFalse);
    expect(store.isFollowing('c_marko'), isTrue);
  });

  test('state survives a restart', () async {
    store.startProgram('p_j_home');
    store.subscribe('c_jelena');
    store.startSession();
    await Future<void>.delayed(Duration.zero);
    final again = AppStore(storage: storage, clock: () => clock);
    await again.load();
    expect(again.profile!.name, 'Ana');
    expect(again.plan!.programId, 'p_j_home');
    expect(again.isSubscribed('c_jelena'), isTrue);
    expect(again.active!.workoutName, 'Donji deo');
  });

  test('unavailable storage still runs the app', () async {
    final s = AppStore(storage: _FailingStore());
    await s.load();
    expect(s.loaded, isTrue);
    s.completeOnboarding(gymProfile);
    await Future<void>.delayed(Duration.zero);
    expect(s.profile, isNotNull);
    await s.resetAll();
  });

  test('unreadable saved state starts fresh', () async {
    final broken = AppStore(storage: MemoryStore({AppStore.storageKey: '{nope'}));
    await broken.load();
    expect(broken.loaded, isTrue);
    expect(broken.profile, isNull);
  });

  test('a creator\'s highlights are saved, replaced, deleted and kept', () async {
    store.saveMyCreator(name: 'Ana Trener', handle: 'ana.trener');
    const photo = HighlightItem(url: 'https://x.test/a.jpg');
    const clip = HighlightItem(url: 'https://x.test/b.mp4', video: true);
    store.saveHighlight(const Highlight(id: 'h1', title: 'O meni', items: [clip, photo]));
    store.saveHighlight(const Highlight(id: 'h2', title: 'Rezultati', items: [photo]));
    store.saveHighlight(const Highlight(id: 'h1', title: 'Ko sam', items: [clip, photo]));
    expect(store.myCreator!.highlights.map((h) => h.title), ['Ko sam', 'Rezultati']);
    expect(store.myCreator!.highlights.first.cover, photo.url, reason: 'the first photo, not the video');

    store.deleteHighlight('h2');
    final reopened = AppStore(storage: storage, clock: () => clock);
    await reopened.load();
    final kept = reopened.myCreator!.highlights.single;
    expect(kept.title, 'Ko sam');
    expect(kept.items.first.video, isTrue);
    expect(reopened.creator(reopened.myCreator!.id)!.highlights, hasLength(1));
  });

  test('creator mode content joins the catalog', () {
    final me = store.saveMyCreator(name: 'Ana Trener', handle: 'ana.trener');
    store.saveExercise(
      Exercise(
        id: 'e1',
        creatorId: me.id,
        name: 'Sklek',
        muscle: Muscle.chest,
        equipment: const {Equipment.bodyweight},
      ),
    );
    store.saveWorkout(
      Workout(
        id: 'w1',
        creatorId: me.id,
        name: 'Moj trening',
        exercises: const [WorkoutExercise(exerciseId: 'e1')],
      ),
    );
    store.saveProgram(
      Program(
        id: 'p1',
        creatorId: me.id,
        name: 'Moj program',
        workoutIds: const ['w1'],
        visibility: Audience.subscribers,
      ),
    );
    expect(store.creatorByHandle('ANA.trener')!.isMine, isTrue);
    expect(store.canAccess(Audience.subscribers, me.id), isTrue);
    store.startProgram('p1');
    expect(store.nextWorkout!.name, 'Moj trening');
    store.deleteExercise('e1');
    expect(store.workoutsById['w1']!.exercises, isEmpty);
    expect(jsonDecode(storage.values[AppStore.storageKey]!)['myPrograms'], hasLength(1));
  });
}

class _FailingStore implements KeyValueStore {
  @override
  Future<String?> read(String key) => Future.error(StateError('blocked'));
  @override
  Future<void> write(String key, String value) => Future.error(StateError('blocked'));
  @override
  Future<void> delete(String key) => Future.error(StateError('blocked'));
}
