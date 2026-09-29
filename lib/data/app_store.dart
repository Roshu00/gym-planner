import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../domain/rules.dart';
import 'seed.dart';
import 'storage.dart';

enum ConfirmSetResult { done, undone, needsWeight, needsReps }

/// Single source of app state. Persists everything the user owns; the demo
/// catalog comes from [SeedCatalog].
class AppStore extends ChangeNotifier {
  AppStore({required this.storage, DateTime Function()? clock, math.Random? random})
    : _clock = clock ?? DateTime.now,
      _random = random ?? math.Random();

  static const storageKey = 'chalkline.state.v1';

  final KeyValueStore storage;
  final DateTime Function() _clock;
  final math.Random _random;

  DateTime get now => _clock();

  bool loaded = false;
  UserProfile? profile;
  Creator? myCreator;
  List<Exercise> myExercises = [];
  List<Workout> myWorkouts = [];
  List<Program> myPrograms = [];
  Set<String> subscriptions = {};
  Set<String> follows = {};
  UserPlan? plan;
  List<Session> sessions = [];
  Session? active;

  // ───────────────────────── Persistence

  /// Storage can be unavailable (private browsing, blocked site data); the
  /// app then works for this visit without remembering anything.
  Future<void> load() async {
    try {
      final raw = await storage.read(storageKey);
      if (raw != null) _fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object catch (e) {
      debugPrint('Starting fresh, saved state unavailable: $e');
    }
    loaded = true;
    notifyListeners();
  }

  void _commit() {
    notifyListeners();
    unawaited(
      storage.write(storageKey, jsonEncode(_toJson())).catchError((Object e) => debugPrint('Not saved: $e')),
    );
  }

  Map<String, Object?> _toJson() => {
    'profile': profile?.toJson(),
    'myCreator': myCreator?.toJson(),
    'myExercises': myExercises.map((e) => e.toJson()).toList(),
    'myWorkouts': myWorkouts.map((e) => e.toJson()).toList(),
    'myPrograms': myPrograms.map((e) => e.toJson()).toList(),
    'subscriptions': subscriptions.toList(),
    'follows': follows.toList(),
    'plan': plan?.toJson(),
    'sessions': sessions.map((s) => s.toJson()).toList(),
    'active': active?.toJson(),
  };

  void _fromJson(Map<String, Object?> j) {
    Map<String, Object?> m(Object? o) => o as Map<String, Object?>;
    List<Object?> l(Object? o) => (o as List?) ?? const [];
    profile = j['profile'] == null ? null : UserProfile.fromJson(m(j['profile']));
    myCreator = j['myCreator'] == null ? null : Creator.fromJson(m(j['myCreator']));
    myExercises = [for (final e in l(j['myExercises'])) Exercise.fromJson(m(e))];
    myWorkouts = [for (final e in l(j['myWorkouts'])) Workout.fromJson(m(e))];
    myPrograms = [for (final e in l(j['myPrograms'])) Program.fromJson(m(e))];
    subscriptions = {for (final e in l(j['subscriptions'])) e as String};
    follows = {for (final e in l(j['follows'])) e as String};
    plan = j['plan'] == null ? null : UserPlan.fromJson(m(j['plan']));
    sessions = [for (final e in l(j['sessions'])) Session.fromJson(m(e))];
    active = j['active'] == null ? null : Session.fromJson(m(j['active']));
  }

  Future<void> resetAll() async {
    profile = null;
    myCreator = null;
    myExercises = [];
    myWorkouts = [];
    myPrograms = [];
    subscriptions = {};
    follows = {};
    plan = null;
    sessions = [];
    active = null;
    notifyListeners();
    try {
      await storage.delete(storageKey);
    } on Object catch (e) {
      debugPrint('Not deleted: $e');
    }
  }

  String _id(String prefix) =>
      '${prefix}_${now.microsecondsSinceEpoch.toRadixString(36)}${_random.nextInt(1 << 20).toRadixString(36)}';

  // ───────────────────────── Catalog

  List<Creator> get creators => [...SeedCatalog.creators, ?myCreator];
  List<Exercise> get allExercises => [...SeedCatalog.exercises, ...myExercises];
  List<Workout> get allWorkouts => [...SeedCatalog.workouts, ...myWorkouts];
  List<Program> get allPrograms => [...SeedCatalog.programs, ...myPrograms];

  Map<String, Exercise> get exercisesById => {for (final e in allExercises) e.id: e};
  Map<String, Workout> get workoutsById => {for (final w in allWorkouts) w.id: w};
  Map<String, Program> get programsById => {for (final p in allPrograms) p.id: p};

  Creator? creator(String id) => creators.where((c) => c.id == id).firstOrNull;
  Creator? creatorByHandle(String handle) =>
      creators.where((c) => c.handle.toLowerCase() == handle.toLowerCase()).firstOrNull;

  bool isSubscribed(String creatorId) => subscriptions.contains(creatorId) || creatorId == myCreator?.id;
  bool isFollowing(String creatorId) => follows.contains(creatorId) || isSubscribed(creatorId);

  bool canAccess(Audience v, String creatorId) => v == Audience.public || isSubscribed(creatorId);

  List<Program> programsOf(String creatorId) => allPrograms.where((p) => p.creatorId == creatorId).toList();
  List<Workout> workoutsOf(String creatorId) => allWorkouts.where((w) => w.creatorId == creatorId).toList();
  List<Exercise> exercisesOf(String creatorId) =>
      allExercises.where((e) => e.creatorId == creatorId).toList();

  /// Creators whose content shows in the Library: followed, subscribed, or mine.
  List<Creator> get libraryCreators => creators.where((c) => isFollowing(c.id)).toList();

  Set<Equipment> get equipment => profile?.equipment ?? Equipment.gym;

  ({int doable, int total}) fitOf(Program p) => programFit(p, workoutsById, exercisesById, equipment);

  /// True when any exercise in [w] needs equipment the user doesn't have.
  bool needsEquipmentSwap(Workout w) => w.exercises.any((we) {
    final e = exercisesById[we.exerciseId];
    return e != null && !canDo(e, equipment);
  });

  /// Alternatives the user can do and has access to.
  List<Exercise> substitutesFor(Exercise e) =>
      substitutes(e, allExercises.where((x) => canAccess(x.visibility, x.creatorId)), equipment);

  // ───────────────────────── Profile & creators

  void completeOnboarding(UserProfile p) {
    profile = p;
    _commit();
  }

  void updateProfile(UserProfile p) {
    profile = p;
    _commit();
  }

  void subscribe(String creatorId) {
    subscriptions = {...subscriptions, creatorId};
    follows = {...follows, creatorId};
    _commit();
  }

  void unsubscribe(String creatorId) {
    subscriptions = {...subscriptions}..remove(creatorId);
    _commit();
  }

  void toggleFollow(String creatorId) {
    follows = follows.contains(creatorId) ? ({...follows}..remove(creatorId)) : {...follows, creatorId};
    _commit();
  }

  // ───────────────────────── Plan

  /// Copies [programId] into the user's plan and pre-swaps exercises their
  /// equipment can't cover. Replaces any current plan; history is untouched.
  UserPlan startProgram(String programId) {
    final p = programsById[programId]!;
    final swaps = <String, String>{};
    for (final w in p.workoutIds.map((id) => workoutsById[id]).nonNulls) {
      // Avoid the same replacement twice in one workout when there's a choice.
      final used = {for (final we in w.exercises) swaps[we.exerciseId] ?? we.exerciseId};
      for (final we in w.exercises) {
        final e = exercisesById[we.exerciseId];
        if (e == null || canDo(e, equipment) || swaps.containsKey(e.id)) continue;
        final alts = substitutesFor(e);
        final alt = alts.where((x) => !used.contains(x.id)).firstOrNull ?? alts.firstOrNull;
        if (alt != null) {
          swaps[e.id] = alt.id;
          used.add(alt.id);
        }
      }
    }
    plan = UserPlan(
      id: _id('plan'),
      programId: p.id,
      creatorId: p.creatorId,
      name: p.name,
      workoutIds: p.workoutIds.where(workoutsById.containsKey).toList(),
      weeks: p.weeks,
      daysPerWeek: p.daysPerWeek,
      startedAt: now,
      swaps: swaps,
    );
    follows = {...follows, p.creatorId};
    _commit();
    return plan!;
  }

  void leavePlan() {
    plan = null;
    _commit();
  }

  void setPlanSwap(String originalId, String? replacementId) {
    final current = plan;
    if (current == null) return;
    final swaps = {...current.swaps};
    if (replacementId == null || replacementId == originalId) {
      swaps.remove(originalId);
    } else {
      swaps[originalId] = replacementId;
    }
    plan = current.copyWith(swaps: swaps);
    _commit();
  }

  void setNextWorkout(int index) {
    if (plan == null) return;
    plan = plan!.copyWith(nextIndex: index);
    _commit();
  }

  Workout? get nextWorkout => plan == null ? null : workoutsById[plan!.nextWorkoutId];

  /// The exercise actually performed for [originalId] under the plan's swaps.
  Exercise? resolveExercise(String originalId, {bool usePlan = true}) {
    final id = usePlan ? (plan?.swaps[originalId] ?? originalId) : originalId;
    return exercisesById[id] ?? exercisesById[originalId];
  }

  // ───────────────────────── Sessions

  List<Session> get history => [...sessions]..sort((a, b) => b.finishedAt!.compareTo(a.finishedAt!));

  /// Starts [workoutId] (the plan's next workout by default). Returns the
  /// running session if one exists.
  Session startSession({String? workoutId}) {
    if (active != null) return active!;
    final fromPlan = workoutId == null || (plan != null && workoutId == plan!.nextWorkoutId);
    final w = workoutsById[workoutId ?? plan!.nextWorkoutId]!;
    final c = creator(w.creatorId);
    active = Session(
      id: _id('s'),
      planId: fromPlan ? plan?.id : null,
      workoutId: w.id,
      workoutName: w.name,
      creatorId: w.creatorId,
      creatorName: c?.name ?? '',
      startedAt: now,
      finishMessage: w.finishMessage,
      exercises: [
        for (final we in w.exercises)
          if (resolveExercise(we.exerciseId, usePlan: fromPlan) case final e?)
            _sessionExercise(
              we,
              e,
              swappedFrom: e.id == we.exerciseId ? null : exercisesById[we.exerciseId]?.name,
            ),
      ],
    );
    _commit();
    return active!;
  }

  SessionExercise _sessionExercise(WorkoutExercise we, Exercise e, {String? swappedFrom}) => SessionExercise(
    exerciseId: e.id,
    name: e.name,
    muscle: e.muscle,
    target: we.target,
    repsMin: we.repsMin,
    repsMax: we.repsMax,
    bodyweight: e.isBodyweight,
    restSeconds: we.restSeconds,
    rir: we.rir,
    note: e.note,
    noteBy: creator(e.creatorId)?.name,
    swappedFrom: swappedFrom,
    sets: List.generate(we.sets, (_) => const SetLog()),
  );

  void _updateExercise(int exIndex, SessionExercise Function(SessionExercise) f) {
    final s = active;
    if (s == null) return;
    final list = [...s.exercises];
    list[exIndex] = f(list[exIndex]);
    active = s.copyWith(exercises: list);
    _commit();
  }

  void updateSet(int exIndex, int setIndex, SetLog log) =>
      _updateExercise(exIndex, (e) => e.copyWith(sets: [...e.sets]..[setIndex] = log));

  void addSet(int exIndex) => _updateExercise(exIndex, (e) => e.copyWith(sets: [...e.sets, const SetLog()]));

  void removeSet(int exIndex, int setIndex) => _updateExercise(
    exIndex,
    (e) => e.sets.length <= 1 ? e : e.copyWith(sets: [...e.sets]..removeAt(setIndex)),
  );

  /// Confirms (or reopens) a set. Empty fields take last time's values, then
  /// the prescription. A set is a record when it beats every earlier set of
  /// the exercise, in history and earlier in this session.
  ConfirmSetResult toggleSet(int exIndex, int setIndex) {
    final e = active!.exercises[exIndex];
    final s = e.sets[setIndex];
    if (s.done) {
      updateSet(exIndex, setIndex, s.copyWith(done: false, isPr: false));
      return ConfirmSetResult.undone;
    }
    final ref = suggestedSet(e, setIndex);
    final kg = s.kg ?? ref?.kg ?? (e.bodyweight ? 0 : null);
    final reps = s.reps ?? ref?.reps ?? e.repsMin;
    if (kg == null) return ConfirmSetResult.needsWeight;
    if (reps <= 0) return ConfirmSetResult.needsReps;

    var best = bestScore(sessions, e.exerciseId);
    if (best != null) {
      for (final other in e.sets) {
        final score = other.done ? setScore(other) : null;
        if (score != null && score > best!) best = score;
      }
    }
    final confirmed = s.copyWith(kg: kg, reps: reps, done: true);
    updateSet(exIndex, setIndex, confirmed.copyWith(isPr: isRecord(best, confirmed)));
    return ConfirmSetResult.done;
  }

  /// What an empty set defaults to: the same set last time, else the
  /// previous set done in this session.
  SetLog? suggestedSet(SessionExercise e, int setIndex) {
    final prev = previousSets(sessions, e.exerciseId);
    if (prev.isNotEmpty) return prev[math.min(setIndex, prev.length - 1)];
    for (var i = setIndex - 1; i >= 0; i--) {
      if (e.sets[i].done) return e.sets[i];
    }
    return null;
  }

  /// Swaps an exercise for this session only; logged sets start over.
  void swapSessionExercise(int exIndex, String exerciseId) {
    final e = exercisesById[exerciseId];
    if (e == null) return;
    _updateExercise(exIndex, (old) {
      final we = WorkoutExercise(
        exerciseId: e.id,
        sets: old.sets.length,
        repsMin: old.repsMin,
        repsMax: old.repsMax,
        rir: old.rir,
        restSeconds: old.restSeconds,
      );
      return _sessionExercise(we, e, swappedFrom: old.swappedFrom ?? old.name);
    });
  }

  /// Saves the session to history and moves the plan to its next workout.
  Session finishSession() {
    final done = active!.copyWith(
      finishedAt: now,
      exercises: [
        for (final e in active!.exercises)
          if (e.doneSets.isNotEmpty) e.copyWith(sets: e.doneSets.toList()),
      ],
    );
    sessions = [...sessions, done];
    active = null;
    if (plan != null && done.planId == plan!.id) {
      plan = plan!.copyWith(
        nextIndex: (plan!.nextIndex + 1) % plan!.workoutIds.length,
        completed: plan!.completed + 1,
      );
    }
    _commit();
    return done;
  }

  void discardSession() {
    active = null;
    _commit();
  }

  Session? sessionById(String id) => sessions.where((s) => s.id == id).firstOrNull;

  int get streak => streakWeeks(sessions, now);
  int get thisWeek => sessionsThisWeek(sessions, now);
  int get weeklyGoal => profile?.daysPerWeek ?? 3;

  // ───────────────────────── Creator mode

  Creator saveMyCreator({
    required String name,
    required String handle,
    String tagline = '',
    String bio = '',
  }) {
    myCreator =
        (myCreator ??
                Creator(id: 'c_me', name: name, handle: handle, tagline: tagline, bio: bio, isMine: true))
            .copyWith(name: name, handle: handle, tagline: tagline, bio: bio);
    _commit();
    return myCreator!;
  }

  String newId(String prefix) => _id(prefix);

  void saveExercise(Exercise e) {
    myExercises = _upsert(myExercises, e, (x) => x.id);
    _commit();
  }

  void saveWorkout(Workout w) {
    myWorkouts = _upsert(myWorkouts, w, (x) => x.id);
    _commit();
  }

  void saveProgram(Program p) {
    myPrograms = _upsert(myPrograms, p, (x) => x.id);
    _commit();
  }

  void deleteExercise(String id) {
    myExercises = myExercises.where((e) => e.id != id).toList();
    myWorkouts = [
      for (final w in myWorkouts)
        Workout(
          id: w.id,
          creatorId: w.creatorId,
          name: w.name,
          finishMessage: w.finishMessage,
          visibility: w.visibility,
          exercises: w.exercises.where((we) => we.exerciseId != id).toList(),
        ),
    ];
    _commit();
  }

  void deleteWorkout(String id) {
    myWorkouts = myWorkouts.where((w) => w.id != id).toList();
    myPrograms = [
      for (final p in myPrograms)
        Program(
          id: p.id,
          creatorId: p.creatorId,
          name: p.name,
          description: p.description,
          weeks: p.weeks,
          daysPerWeek: p.daysPerWeek,
          level: p.level,
          goal: p.goal,
          place: p.place,
          visibility: p.visibility,
          workoutIds: p.workoutIds.where((w) => w != id).toList(),
        ),
    ];
    _commit();
  }

  void deleteProgram(String id) {
    myPrograms = myPrograms.where((p) => p.id != id).toList();
    _commit();
  }

  static List<T> _upsert<T>(List<T> list, T item, String Function(T) id) {
    final i = list.indexWhere((x) => id(x) == id(item));
    return i < 0 ? [...list, item] : ([...list]..[i] = item);
  }
}
