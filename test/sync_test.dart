import 'dart:convert';
import 'dart:io';

import 'package:chalkline/data/app_store.dart';
import 'package:chalkline/data/rows.dart';
import 'package:chalkline/data/seed.dart';
import 'package:chalkline/data/seed_sql.dart';
import 'package:chalkline/data/storage.dart';
import 'package:chalkline/data/sync.dart';
import 'package:chalkline/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

const profile = UserProfile(
  name: 'Boban',
  goal: Goal.strength,
  experience: Experience.beginner,
  place: Place.gym,
  daysPerWeek: 3,
  equipment: Equipment.gym,
);

void main() {
  late DateTime clock;
  late MemoryStore storage;
  late FakeRemote remote;

  Future<AppStore> open() async {
    final s = AppStore(storage: storage, remote: remote, clock: () => clock);
    await s.load();
    return s;
  }

  Future<void> settle() =>
      Future<void>.delayed(Duration.zero).then((_) => Future<void>.delayed(Duration.zero));

  setUp(() {
    clock = DateTime(2026, 9, 30, 18);
    storage = MemoryStore();
    remote = FakeRemote();
  });

  test('a new device waits for the server: a returning user skips onboarding', () async {
    remote.tables['profiles']!.add(profileRow(profile, uid));
    final store = await open();
    expect(store.profile!.name, 'Boban');
    expect(store.programsById.keys, contains('p_m_strength'), reason: 'program pages are public');
    expect(store.workoutsById.containsKey('w_m_upper'), isFalse, reason: 'subscriber workout is locked');
  });

  test('gender survives the profile row and local JSON', () {
    final p = profile.copyWith(gender: Gender.female);
    expect(profileFromRow(profileRow(p, 'u1')).gender, Gender.female);
    expect(UserProfile.fromJson(p.toJson()).gender, Gender.female);
    expect(UserProfile.fromJson({'name': 'Stari'}).gender, Gender.unspecified, reason: 'older caches');
    expect(p.says('Pojavio', 'Pojavila'), 'Pojavila');
    expect(profile.says('Pojavio', 'Pojavila'), 'Pojavio');
  });

  test('changes reach the server in order', () async {
    final store = await open();
    store.completeOnboarding(profile);
    store.startProgram('p_m_start');
    store.startSession();
    store.updateSet(0, 0, const SetLog(kg: 60, reps: 8));
    store.toggleSet(0, 0);
    store.finishSession();
    await settle();
    expect(store.pendingChanges, 0);
    expect(remote.tables['profiles'], hasLength(1));
    expect(remote.tables['follows']!.single['creator_id'], 'c_marko');
    expect(remote.tables['plans']!.single['next_index'], 1);
    final session = remote.tables['sessions']!.single;
    expect(session['finished_at'], isNotNull);
    expect(sessionFromRow(session).exercises.single.sets.single.kg, 60);
  });

  test('typing into a set coalesces into one pending session write', () async {
    final store = await open();
    store.completeOnboarding(profile);
    store.startProgram('p_m_start');
    await settle();
    remote.offline = true;
    store.startSession();
    for (final kg in ['6', '60', '62', '62.5']) {
      store.updateSet(0, 0, SetLog(kg: double.parse(kg)));
    }
    await settle();
    expect(store.pendingChanges, 1);
    expect(store.syncError, contains('internet'));
  });

  test('offline: the workout continues, survives a restart and syncs later', () async {
    final store = await open();
    store.completeOnboarding(profile);
    store.startProgram('p_m_start');
    await settle();
    remote.offline = true;
    store.startSession();
    store.updateSet(0, 0, const SetLog(kg: 70, reps: 5));
    store.toggleSet(0, 0);
    store.finishSession();
    await settle();
    expect(store.pendingChanges, greaterThan(0));
    expect(remote.tables['sessions'], isEmpty);

    // App restarts while still offline: the cache shows everything.
    final again = await open();
    await settle();
    expect(again.sessions, hasLength(1));
    expect(again.plan!.nextIndex, 1);
    expect(again.pendingChanges, store.pendingChanges);

    // Back online: pending changes go first, then the server state loads.
    remote.offline = false;
    await again.retrySync();
    expect(again.pendingChanges, 0);
    expect(again.syncError, isNull);
    expect(remote.tables['sessions']!.single['finished_at'], isNotNull);
    expect(again.sessions, hasLength(1));
    expect(again.plan!.nextIndex, 1, reason: 'the server did not overwrite local progress');
  });

  test('subscribing unlocks subscriber content from the server', () async {
    final store = await open();
    store.completeOnboarding(profile);
    await settle();
    expect(store.workoutsById.containsKey('w_m_upper'), isFalse);
    store.subscribe('c_marko');
    await settle();
    await settle();
    expect(store.workoutsById.containsKey('w_m_upper'), isTrue);
    store.unsubscribe('c_marko');
    await settle();
    await settle();
    expect(store.workoutsById.containsKey('w_m_upper'), isFalse);
    expect(store.isFollowing('c_marko'), isTrue);
  });

  test('a rejected change is dropped and explained; the rest still syncs', () async {
    final store = await open();
    store.completeOnboarding(profile);
    await settle();
    remote.rejected.add('creators');
    store.saveMyCreator(name: 'Boban', handle: 'boban.fit');
    store.toggleFollow('c_jelena');
    await settle();
    expect(store.pendingChanges, 0);
    expect(store.syncError, 'Nemaš dozvolu za ovu izmenu.');
    expect(remote.tables['follows']!.single['creator_id'], 'c_jelena');
  });

  test('creator content is written under the user and read back as mine', () async {
    final store = await open();
    store.completeOnboarding(profile);
    final me = store.saveMyCreator(name: 'Boban', handle: 'boban.fit');
    expect(me.id, isNot('c_me'));
    store.saveExercise(
      Exercise(
        id: 'e1',
        creatorId: me.id,
        name: 'Sklek',
        muscle: Muscle.chest,
        equipment: const {Equipment.bodyweight},
        visibility: Audience.subscribers,
      ),
    );
    store.saveWorkout(
      Workout(
        id: 'w1',
        creatorId: me.id,
        name: 'Jutro',
        exercises: const [WorkoutExercise(exerciseId: 'e1')],
      ),
    );
    store.saveProgram(Program(id: 'p1', creatorId: me.id, name: 'Moj program', workoutIds: const ['w1']));
    await settle();
    expect(remote.tables['creators']!.last['user_id'], uid);

    final other = await open(); // same user on another device
    await other.refresh();
    expect(other.myCreator!.handle, 'boban.fit');
    expect(other.myExercises.single.name, 'Sklek', reason: 'owners see their subscriber content');
    expect(other.myPrograms.single.workoutIds, ['w1']);

    store.deleteExercise('e1');
    await settle();
    expect(remote.tables['exercises']!.where((r) => r['id'] == 'e1'), isEmpty);
    expect((remote.tables['workouts']!.firstWhere((r) => r['id'] == 'w1')['exercises'] as List), isEmpty);
  });

  test('handle availability asks the server', () async {
    final store = await open();
    expect(await store.isHandleAvailable('marko.lifts'), isFalse);
    expect(await store.isHandleAvailable('novi.trener'), isTrue);
  });

  test('deleting my data removes it from the server', () async {
    final store = await open();
    store.completeOnboarding(profile);
    store.subscribe('c_jelena');
    store.startProgram('p_j_home');
    store.startSession();
    store.saveMyCreator(name: 'Boban', handle: 'boban.fit');
    await settle();
    await store.resetAll();
    await settle();
    for (final t in ['profiles', 'follows', 'subscriptions', 'plans', 'sessions']) {
      expect(remote.tables[t], isEmpty, reason: t);
    }
    expect(remote.tables['creators']!.where((c) => c['user_id'] == uid), isEmpty);
    expect(store.profile, isNull);
  });

  test('outbox survives serialization and keeps order when coalescing', () {
    final box = Outbox()
      ..add(const Mutation.upsert('creators', {'id': 'c1', 'name': 'A'}))
      ..add(const Mutation.upsert('exercises', {'id': 'e1', 'creator_id': 'c1'}))
      ..add(const Mutation.upsert('creators', {'id': 'c1', 'name': 'B'}))
      ..add(const Mutation.delete('follows', {'user_id': uid, 'creator_id': 'c1'}))
      ..add(const Mutation.upsert('follows', {'user_id': uid, 'creator_id': 'c1'}, ignoreDuplicates: true));
    final again = Outbox.fromJson(jsonDecode(jsonEncode(box.toJson())) as List);
    expect(again.pending.map((m) => '${m.table}:${m.delete}').toList(), [
      'creators:false',
      'exercises:false',
      'follows:false',
    ]);
    expect(again.first.data['name'], 'B', reason: 'the creator stays before the exercise that references it');
    expect(again.pending.last.ignoreDuplicates, isTrue);
  });

  test('rows round-trip through the database shape', () {
    final plan = UserPlan(
      id: 'p',
      programId: 'x',
      creatorId: 'c',
      name: 'N',
      workoutIds: const ['a', 'b'],
      weeks: 6,
      daysPerWeek: 3,
      startedAt: DateTime(2026, 9, 1, 8),
      swaps: const {'a': 'b'},
      nextIndex: 1,
      completed: 4,
    );
    final back = planFromRow((jsonDecode(jsonEncode(planRow(plan, uid))) as Map).cast());
    expect(back.startedAt, plan.startedAt);
    expect(back.swaps, plan.swaps);
    expect(back.completed, 4);
    for (final w in SeedCatalog.workouts) {
      final r = workoutFromRow((jsonDecode(jsonEncode(workoutRow(w))) as Map).cast());
      expect(r.exercises.map((e) => e.target), w.exercises.map((e) => e.target));
    }
  });

  test('supabase/seed.sql matches the demo catalog (run tool/gen_seed.dart)', () {
    expect(File('supabase/seed.sql').readAsStringSync(), buildSeedSql());
  });
}
