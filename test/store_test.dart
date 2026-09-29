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
