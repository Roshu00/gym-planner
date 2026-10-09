import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../domain/models.dart';
import '../domain/reminders.dart';
import '../domain/rules.dart';
import 'auth.dart';
import 'rows.dart';
import 'seed.dart';
import 'reminder_scheduler.dart';
import 'storage.dart';
import 'sync.dart';

enum ConfirmSetResult { done, undone, needsWeight, needsReps }

/// Single source of app state.
///
/// Local mode (no [remote]): the catalog is [SeedCatalog] plus the user's own
/// creator content, and everything is kept on the device.
///
/// Cloud mode: the catalog and the user's data come from [remote]. Every change
/// is applied here first, cached on the device and queued as a [Mutation];
/// the queue survives restarts and is sent in order, so training works offline.
class AppStore extends ChangeNotifier {
  AppStore({
    required this.storage,
    this.remote,
    this.auth,
    this.account,
    DateTime Function()? clock,
    math.Random? random,
    this.reminders = const NoReminders(),
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? math.Random();

  static const storageKey = 'chalkline.state.v1';

  final KeyValueStore storage;

  /// Puts training-day reminders on the phone.
  final ReminderScheduler reminders;
  final Remote? remote;
  final AuthService? auth;

  /// Signed-in account in cloud mode. Updated when a guest saves their account.
  AuthUser? account;
  final DateTime Function() _clock;
  final math.Random _random;

  DateTime get now => _clock();

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Loads and syncs finish asynchronously, possibly after sign-out.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void updateAccount(AuthUser user) {
    account = user;
    notifyListeners();
  }

  bool get isCloud => remote != null;
  String get _key => remote == null ? storageKey : '$storageKey.${remote!.userId}';

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
  ReminderSettings reminderSettings = const ReminderSettings();

  // Catalog from other creators: the seed locally, the server in cloud mode.
  List<Creator> _baseCreators = SeedCatalog.creators;
  List<Exercise> _baseExercises = SeedCatalog.exercises;
  List<Workout> _baseWorkouts = SeedCatalog.workouts;
  List<Program> _basePrograms = SeedCatalog.programs;

  final Outbox _outbox = Outbox();
  bool _flushing = false;
  bool _catalogStale = false;

  /// Last sync problem, in Serbian, or null when everything was sent.
  String? syncError;
  bool _syncErrorRetryable = true;

  void dismissSyncError() {
    syncError = null;
    notifyListeners();
  }

  /// Changes not yet confirmed by the server.
  int get pendingChanges => _outbox.length;

  // ───────────────────────── Persistence

  /// Storage can be unavailable (private browsing, blocked site data); the
  /// app then works for this visit without remembering anything.
  ///
  /// In cloud mode a cached state shows immediately and refreshes in the
  /// background; without a cache (new device) it waits for the server so a
  /// returning user is not sent through onboarding again.
  Future<void> load() async {
    try {
      final raw = await storage.read(_key);
      if (raw != null) _fromJson(jsonDecode(raw) as Map<String, Object?>);
    } on Object catch (e) {
      debugPrint('Starting fresh, saved state unavailable: $e');
    }
    if (remote != null) {
      if (profile == null) {
        await refresh();
      } else {
        unawaited(refresh());
      }
    }
    loaded = true;
    notifyListeners();
    _syncReminders();
  }

  // ───────────────────────── Reminders

  /// What is on the phone now, so unchanged reminders are not rescheduled.
  List<Reminder> _scheduled = const [];

  /// Reminders for the next two weeks of the plan.
  List<Reminder> get upcomingReminders {
    final today = dateOnly(now);
    final until = today.add(const Duration(days: 14));
    final days = <PlannedDay>[
      for (final e in schedule(until).entries)
        if (workoutsById[e.value] case final w?)
          (
            day: e.key,
            workout: w.name,
            creator: creator(w.creatorId)?.name ?? '',
            minutes: w.estimatedMinutes,
            intro: w.intro,
          ),
    ];
    return remindersFor(days, reminderSettings, now, doneToday: sessionsOn(sessions, today).isNotEmpty);
  }

  void _syncReminders() {
    final next = upcomingReminders;
    if (listEquals(next, _scheduled)) return;
    _scheduled = next;
    unawaited(reminders.replaceAll(next).catchError((Object e) => debugPrint('Reminders not scheduled: $e')));
  }

  /// Turns reminders on (after asking the phone) or off. False when the
  /// phone does not allow notifications.
  Future<bool> setRemindersEnabled(bool on) async {
    if (on && !await reminders.requestPermission()) {
      reminderSettings = reminderSettings.copyWith(asked: true);
      _commit();
      return false;
    }
    reminderSettings = reminderSettings.copyWith(enabled: on, asked: true);
    _commit();
    return true;
  }

  void setReminderTime(int hour, int minute) {
    reminderSettings = reminderSettings.copyWith(hour: hour, minute: minute);
    _commit();
  }

  /// "Ne sada" on the offer.
  void dismissReminderOffer() {
    reminderSettings = reminderSettings.copyWith(asked: true);
    _commit();
  }

  void _commit() {
    notifyListeners();
    _persist();
    _syncReminders();
    if (remote != null) unawaited(_flush());
  }

  void _persist() => unawaited(
    storage.write(_key, jsonEncode(_toJson())).catchError((Object e) => debugPrint('Not saved: $e')),
  );

  void _send(Mutation m) {
    if (remote != null) _outbox.add(m);
  }

  String get _uid => remote!.userId;

  /// Sends pending changes, then reloads everything from the server.
  /// Pending changes always go first so the server never overwrites them.
  Future<void> refresh() async {
    final r = remote;
    if (r == null) return;
    await _flush();
    if (_outbox.isNotEmpty) return;
    try {
      final (catalog, user) = await (r.fetchCatalog(), r.fetchUser()).wait;
      if (_outbox.isNotEmpty) return;
      _applyCatalog(catalog);
      profile = user.profile;
      follows = user.follows;
      subscriptions = user.subscriptions;
      plan = user.plan;
      sessions = user.sessions;
      active = user.active;
      if (_syncErrorRetryable) syncError = null;
      notifyListeners();
      _persist();
    } on ParallelWaitError<(Catalog?, UserData?), (AsyncError?, AsyncError?)> catch (e) {
      _reportSync(e.errors.$1?.error ?? e.errors.$2?.error);
    } on RemoteError catch (e) {
      _reportSync(e);
    }
  }

  void _reportSync(Object? error) {
    syncError = error is RemoteError ? error.message : 'Nije sačuvano na serveru. Proveri internet.';
    _syncErrorRetryable = error is! RemoteError || error.retryable;
    notifyListeners();
  }

  void _applyCatalog(Catalog c) {
    final mine = c.creators.where((x) => x.isMine).firstOrNull;
    bool isMine(String creatorId) => creatorId == mine?.id;
    myCreator = mine;
    myExercises = c.exercises.where((x) => isMine(x.creatorId)).toList();
    myWorkouts = c.workouts.where((x) => isMine(x.creatorId)).toList();
    myPrograms = c.programs.where((x) => isMine(x.creatorId)).toList();
    _baseCreators = c.creators.where((x) => !x.isMine).toList();
    _baseExercises = c.exercises.where((x) => !isMine(x.creatorId)).toList();
    _baseWorkouts = c.workouts.where((x) => !isMine(x.creatorId)).toList();
    _basePrograms = c.programs.where((x) => !isMine(x.creatorId)).toList();
    _catalogStale = false;
  }

  Future<void> _refreshCatalog() async {
    try {
      _applyCatalog(await remote!.fetchCatalog());
      notifyListeners();
      _persist();
    } on RemoteError catch (e) {
      _catalogStale = true;
      _reportSync(e);
    }
  }

  /// Sends queued mutations in order. Stops at the first retryable failure;
  /// drops a mutation the server rejects and reports why.
  Future<void> _flush() async {
    final r = remote;
    if (r == null || _flushing) return;
    _flushing = true;
    try {
      while (_outbox.isNotEmpty) {
        final m = _outbox.first;
        try {
          await r.apply(m);
          _outbox.remove(m);
          if (m.table == 'subscriptions') _catalogStale = true;
          // A rejection stays visible; a connection problem is over.
          if (_syncErrorRetryable) syncError = null;
        } on RemoteError catch (e) {
          syncError = e.message;
          _syncErrorRetryable = e.retryable;
          if (e.retryable) break;
          _outbox.remove(m);
        }
        _persist();
        notifyListeners();
      }
    } finally {
      _flushing = false;
    }
    // A subscription change unlocks or locks content: reload what RLS allows.
    if (_outbox.isEmpty && _catalogStale) await _refreshCatalog();
  }

  /// Retries sending after a failure (e.g. back online).
  Future<void> retrySync() => refresh();

  /// Handles are unique across creators; asks the server in cloud mode.
  Future<bool> isHandleAvailable(String handle) async {
    final taken = creatorByHandle(handle);
    if (taken != null && !taken.isMine) return false;
    return await remote?.isHandleAvailable(handle) ?? true;
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
    'reminders': reminderSettings.toJson(),
    if (remote != null) ...{
      'outbox': _outbox.toJson(),
      'catalog': {
        'creators': _baseCreators.map((e) => e.toJson()).toList(),
        'exercises': _baseExercises.map((e) => e.toJson()).toList(),
        'workouts': _baseWorkouts.map((e) => e.toJson()).toList(),
        'programs': _basePrograms.map((e) => e.toJson()).toList(),
      },
    },
  };

  void _fromJson(Map<String, Object?> j) {
    Map<String, Object?> m(Object? o) => o as Map<String, Object?>;
    List<Object?> l(Object? o) => (o as List?) ?? const [];
    profile = j['profile'] == null ? null : UserProfile.fromJson(m(j['profile']));
    if (j['reminders'] != null) reminderSettings = ReminderSettings.fromJson(m(j['reminders']));
    myCreator = j['myCreator'] == null ? null : Creator.fromJson(m(j['myCreator']));
    myExercises = [for (final e in l(j['myExercises'])) Exercise.fromJson(m(e))];
    myWorkouts = [for (final e in l(j['myWorkouts'])) Workout.fromJson(m(e))];
    myPrograms = [for (final e in l(j['myPrograms'])) Program.fromJson(m(e))];
    subscriptions = {for (final e in l(j['subscriptions'])) e as String};
    follows = {for (final e in l(j['follows'])) e as String};
    plan = j['plan'] == null ? null : UserPlan.fromJson(m(j['plan']));
    sessions = [for (final e in l(j['sessions'])) Session.fromJson(m(e))];
    active = j['active'] == null ? null : Session.fromJson(m(j['active']));
    if (remote != null) {
      _outbox
        ..clear()
        ..addAll(Outbox.fromJson(j['outbox'] as List?).pending);
      final c = j['catalog'] as Map<String, Object?>?;
      if (c != null) {
        _baseCreators = [for (final e in l(c['creators'])) Creator.fromJson(m(e))];
        _baseExercises = [for (final e in l(c['exercises'])) Exercise.fromJson(m(e))];
        _baseWorkouts = [for (final e in l(c['workouts'])) Workout.fromJson(m(e))];
        _basePrograms = [for (final e in l(c['programs'])) Program.fromJson(m(e))];
      }
    }
  }

  /// Deletes the user's data: on the device, and on the server in cloud mode.
  /// (Deleting the account itself needs the service role; see README.)
  Future<void> resetAll() async {
    if (remote != null) {
      for (final table in ['sessions', 'plans', 'follows', 'subscriptions', 'profiles']) {
        _send(Mutation.delete(table, {'user_id': _uid}));
      }
      if (myCreator != null) _send(Mutation.delete('creators', {'id': myCreator!.id}));
    }
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
    if (remote != null) {
      _persist();
      await _flush();
      return;
    }
    try {
      await storage.delete(_key);
    } on Object catch (e) {
      debugPrint('Not deleted: $e');
    }
  }

  /// Forgets this account's cache on the device (sign-out).
  Future<void> clearDeviceCache() async {
    try {
      await storage.delete(_key);
    } on Object catch (e) {
      debugPrint('Not deleted: $e');
    }
  }

  String _id(String prefix) =>
      '${prefix}_${now.microsecondsSinceEpoch.toRadixString(36)}${_random.nextInt(1 << 20).toRadixString(36)}';

  // ───────────────────────── Catalog

  List<Creator> get creators => [..._baseCreators, ?myCreator];
  List<Exercise> get allExercises => [..._baseExercises, ...myExercises];
  List<Workout> get allWorkouts => [..._baseWorkouts, ...myWorkouts];
  List<Program> get allPrograms => [..._basePrograms, ...myPrograms];

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

  void completeOnboarding(UserProfile p) => updateProfile(p);

  void updateProfile(UserProfile p) {
    profile = p;
    if (isCloud) _send(Mutation.upsert('profiles', profileRow(p, _uid)));
    _commit();
  }

  Row _link(String creatorId) => {'user_id': _uid, 'creator_id': creatorId};

  void _follow(String creatorId) {
    if (follows.contains(creatorId)) return;
    follows = {...follows, creatorId};
    if (isCloud) _send(Mutation.upsert('follows', _link(creatorId), ignoreDuplicates: true));
  }

  void subscribe(String creatorId) {
    subscriptions = {...subscriptions, creatorId};
    _follow(creatorId);
    if (isCloud) _send(Mutation.upsert('subscriptions', _link(creatorId), ignoreDuplicates: true));
    _commit();
  }

  void unsubscribe(String creatorId) {
    subscriptions = {...subscriptions}..remove(creatorId);
    if (isCloud) _send(Mutation.delete('subscriptions', _link(creatorId)));
    _commit();
  }

  void toggleFollow(String creatorId) {
    if (follows.contains(creatorId)) {
      follows = {...follows}..remove(creatorId);
      if (isCloud) _send(Mutation.delete('follows', _link(creatorId)));
    } else {
      _follow(creatorId);
    }
    _commit();
  }

  // ───────────────────────── Plan

  /// Copies [programId] into the user's plan and pre-swaps exercises their
  /// equipment can't cover. Replaces any current plan; history is untouched.
  UserPlan startProgram(String programId, {Set<int>? trainingDays}) {
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
      trainingDays: trainingDays ?? defaultTrainingDays(p.daysPerWeek),
    );
    _follow(p.creatorId);
    _savePlan();
    return plan!;
  }

  void _savePlan() {
    if (isCloud) _send(Mutation.upsert('plans', planRow(plan!, _uid), onConflict: 'user_id'));
    _commit();
  }

  void leavePlan() {
    plan = null;
    if (isCloud) _send(Mutation.delete('plans', {'user_id': _uid}));
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
    _savePlan();
  }

  void setTrainingDays(Set<int> days) {
    if (plan == null || days.isEmpty) return;
    plan = plan!.copyWith(trainingDays: days);
    _savePlan();
  }

  void setNextWorkout(int index) {
    if (plan == null) return;
    plan = plan!.copyWith(nextIndex: index);
    _savePlan();
  }

  Workout? get nextWorkout => plan == null ? null : workoutsById[plan!.nextWorkoutId];

  // ───────────────────────── Calendar: the plan suggests, the user decides

  /// The plan's forecast from today through [until], with the user's day changes.
  Map<DateTime, String> schedule(DateTime until) =>
      plan == null ? const {} : projectSchedule(plan!, sessions, now, until);

  /// The user's own choice for [day], if they changed it.
  DayPlan? dayPlan(DateTime day) => plan?.days[dayKey(day)];

  /// What is planned on [day] (today or later): the workout and the exact
  /// exercises, or null on a rest day.
  ({Workout workout, List<WorkoutExercise> exercises, DayPlan? custom})? plannedOn(DateTime day) {
    final d = dateOnly(day);
    final id = schedule(d)[d];
    final w = id == null ? null : workoutsById[id];
    if (w == null) return null;
    final custom = dayPlan(d);
    return (workout: w, exercises: custom?.exercises ?? w.exercises, custom: custom);
  }

  /// Sets or clears (null) the user's choice for one day. Old past days are
  /// dropped so the plan row stays small.
  void setDayPlan(DateTime day, DayPlan? p) {
    final current = plan;
    if (current == null) return;
    final cutoff = dayKey(dateOnly(now).subtract(const Duration(days: 60)));
    final days = {
      for (final e in current.days.entries)
        if (e.key.compareTo(cutoff) >= 0) e.key: e.value,
    };
    if (p == null) {
      days.remove(dayKey(day));
    } else {
      days[dayKey(day)] = p;
    }
    plan = current.copyWith(days: days);
    _savePlan();
  }

  /// Puts back an earlier set of day changes (undo).
  void restoreDays(Map<String, DayPlan> days) {
    if (plan == null) return;
    plan = plan!.copyWith(days: days);
    _savePlan();
  }

  /// Rest on [day]. The workouts after it move forward by one training day.
  void restOn(DateTime day) => setDayPlan(day, const DayPlan.rest());

  /// Train on [day], with the next workout of the rotation or [workoutId].
  void trainOn(DateTime day, {String? workoutId}) => setDayPlan(day, DayPlan.train(workoutId: workoutId));

  /// Can't train on [day]: it becomes a rest day and the next rest day becomes
  /// a training day, so the workouts in between slide by one day and the
  /// week after stays the same. Returns the day that was given up, if any.
  DateTime? shiftFrom(DateTime day) {
    if (plan == null) return null;
    final d = dateOnly(day);
    DateTime at(int i) => DateTime(d.year, d.month, d.day + i);
    final moved = dayPlan(d);
    DateTime? taken;
    for (var i = 1; i <= 14 && taken == null; i++) {
      if (!isTrainingDay(plan!, at(i))) taken = at(i);
    }
    restOn(d);
    if (taken != null) setDayPlan(taken, const DayPlan.train());
    // An edited workout takes its edits to the day it lands on.
    if (moved != null && moved.train && moved.edited) {
      for (var i = 1; i <= 14; i++) {
        if (isTrainingDay(plan!, at(i))) {
          setDayPlan(at(i), moved);
          break;
        }
      }
    }
    return taken;
  }

  /// Whether the workout planned on [from] can be dragged to [to]: both today
  /// or later, [to] free, and no other training day in between, so the
  /// rotation keeps its order and the same workout lands where it was dropped.
  bool canMoveTraining(DateTime from, DateTime to) {
    final current = plan;
    if (current == null) return false;
    final f = dateOnly(from), t = dateOnly(to), today = dateOnly(now);
    if (f == t || f.isBefore(today) || t.isBefore(today)) return false;
    if (plannedOn(f) == null || sessionsOn(sessions, f).isNotEmpty) return false;
    if (isTrainingDay(current, t)) return false;
    final step = t.isAfter(f) ? 1 : -1;
    for (
      var d = DateTime(f.year, f.month, f.day + step);
      d != t;
      d = DateTime(d.year, d.month, d.day + step)
    ) {
      if (isTrainingDay(current, d)) return false;
    }
    return true;
  }

  /// Moves the workout planned on [from] to the free day [to], with its own
  /// changes (shorter version, other exercises).
  void moveTraining(DateTime from, DateTime to) {
    if (!canMoveTraining(from, to)) return;
    final current = plan!;
    final moved = dayPlan(from);
    final f = dateOnly(from), t = dateOnly(to);
    // Back to the usual week where that is what the day already is.
    setDayPlan(f, current.trainingDays.contains(f.weekday) ? const DayPlan.rest() : null);
    final usual = current.trainingDays.contains(t.weekday);
    setDayPlan(t, moved != null && moved.train ? moved : (usual ? null : const DayPlan.train()));
  }

  /// A break of [count] days from [from] (travel, illness, a busy week).
  /// The plan continues where it stopped afterwards.
  void pause(DateTime from, int count) {
    final d = dateOnly(from);
    for (var i = 0; i < count; i++) {
      final x = DateTime(d.year, d.month, d.day + i);
      if (isTrainingDay(plan!, x)) setDayPlan(x, const DayPlan.rest(note: 'Pauza'));
    }
  }

  /// Another workout on [day] instead of the planned one. The plan's next
  /// workout waits for the following training day.
  void swapWorkoutOn(DateTime day, String workoutId) =>
      setDayPlan(day, DayPlan.train(workoutId: workoutId, note: 'Drugi trening'));

  /// A shorter version of [day]'s workout for a low-energy day.
  void quickVersionOn(DateTime day) {
    final p = plannedOn(day);
    if (p == null) return;
    setDayPlan(
      day,
      DayPlan.train(
        workoutId: p.workout.id,
        exercises: quickVersion(p.workout.exercises),
        note: 'Kraća verzija',
      ),
    );
  }

  /// [day]'s own exercise list: swapped, removed, added or with other sets.
  void editDayExercises(DateTime day, List<WorkoutExercise> exercises) {
    final p = plannedOn(day);
    if (p == null) return;
    setDayPlan(day, DayPlan.train(workoutId: p.workout.id, exercises: exercises, note: 'Prilagođeno'));
  }

  /// Starts what is planned today, with the day's own changes, or the plan's
  /// next workout on a rest day.
  Session startToday() {
    final p = plannedOn(now);
    return startSession(workoutId: p?.workout.id, exercises: p?.custom?.exercises);
  }

  /// The exercise actually performed for [originalId] under the plan's swaps.
  Exercise? resolveExercise(String originalId, {bool usePlan = true}) {
    final id = usePlan ? (plan?.swaps[originalId] ?? originalId) : originalId;
    return exercisesById[id] ?? exercisesById[originalId];
  }

  // ───────────────────────── Sessions

  List<Session> get history => [...sessions]..sort((a, b) => b.finishedAt!.compareTo(a.finishedAt!));

  /// Starts [workoutId] (the plan's next workout by default). Returns the
  /// running session if one exists.
  /// [exercises] replaces the workout's list for this session (an edited day).
  /// [loggedFor] records a workout done on an earlier day the user forgot
  /// to log.
  Session startSession({String? workoutId, List<WorkoutExercise>? exercises, DateTime? loggedFor}) {
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
      startedAt: loggedFor == null ? now : DateTime(loggedFor.year, loggedFor.month, loggedFor.day, 18),
      finishMessage: w.finishMessage,
      exercises: [
        for (final we in exercises ?? w.exercises)
          if (resolveExercise(we.exerciseId, usePlan: fromPlan) case final e?)
            _sessionExercise(
              we,
              e,
              swappedFrom: e.id == we.exerciseId ? null : exercisesById[we.exerciseId]?.name,
            ),
      ],
    );
    _saveActive();
    return active!;
  }

  void _saveActive() {
    if (isCloud && active != null) _send(Mutation.upsert('sessions', sessionRow(active!, _uid)));
    _commit();
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
    _saveActive();
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
    final started = active!.startedAt;
    // Logged later for an earlier day: it stays on that day.
    final late = dateOnly(started).isBefore(dateOnly(now));
    final done = active!.copyWith(
      finishedAt: late ? started.add(const Duration(hours: 1)) : now,
      exercises: [
        for (final e in active!.exercises)
          if (e.doneSets.isNotEmpty) e.copyWith(sets: e.doneSets.toList()),
      ],
    );
    sessions = [...sessions, done];
    active = null;
    if (isCloud) _send(Mutation.upsert('sessions', sessionRow(done, _uid)));
    if (plan != null && done.planId == plan!.id) {
      plan = plan!.copyWith(
        nextIndex: (plan!.nextIndex + 1) % plan!.workoutIds.length,
        completed: plan!.completed + 1,
      );
      _savePlan();
    } else {
      _commit();
    }
    return done;
  }

  void discardSession() {
    final s = active;
    active = null;
    if (isCloud && s != null) _send(Mutation.delete('sessions', {'id': s.id}));
    _commit();
  }

  Session? sessionById(String id) => sessions.where((s) => s.id == id).firstOrNull;

  int get streak => streakWeeks(sessions, now);
  int get thisWeek => sessionsThisWeek(sessions, now);

  /// Planned training days per week; 0 without a plan.
  int get weeklyGoal =>
      plan == null ? 0 : (plan!.trainingDays.isEmpty ? plan!.daysPerWeek : plan!.trainingDays.length);

  // ───────────────────────── Creator mode

  Creator saveMyCreator({
    required String name,
    required String handle,
    String tagline = '',
    String bio = '',
  }) {
    myCreator =
        (myCreator ??
                Creator(
                  id: isCloud ? _id('c') : 'c_me',
                  name: name,
                  handle: handle,
                  tagline: tagline,
                  bio: bio,
                  isMine: true,
                ))
            .copyWith(name: name, handle: handle, tagline: tagline, bio: bio);
    if (isCloud) _send(Mutation.upsert('creators', creatorRow(myCreator!, userId: _uid)));
    _commit();
    return myCreator!;
  }

  String newId(String prefix) => _id(prefix);

  /// Largest video a creator may add to an exercise.
  static const maxVideoBytes = 50 * 1024 * 1024;

  /// Sends a creator's video of an exercise and returns its link: the
  /// server's in the cloud, the file itself on this device in local mode.
  Future<String> uploadExerciseVideo(String path) async {
    final extension = path.toLowerCase().endsWith('.mov') ? 'mov' : 'mp4';
    final contentType = extension == 'mov' ? 'video/quicktime' : 'video/mp4';
    final remote = this.remote;
    if (remote == null) return Uri.file(path).toString();
    return remote.uploadMedia(path, extension: extension, contentType: contentType);
  }

  void saveExercise(Exercise e) {
    myExercises = _upsert(myExercises, e, (x) => x.id);
    if (isCloud) _send(Mutation.upsert('exercises', exerciseRow(e)));
    _commit();
  }

  void saveWorkout(Workout w) {
    myWorkouts = _upsert(myWorkouts, w, (x) => x.id);
    if (isCloud) _send(Mutation.upsert('workouts', workoutRow(w)));
    _commit();
  }

  void saveProgram(Program p) {
    myPrograms = _upsert(myPrograms, p, (x) => x.id);
    if (isCloud) _send(Mutation.upsert('programs', programRow(p)));
    _commit();
  }

  void deleteExercise(String id) {
    final changed = myWorkouts
        .where((w) => w.exercises.any((we) => we.exerciseId == id))
        .map((w) => w.id)
        .toSet();
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
    if (isCloud) {
      for (final w in myWorkouts.where((w) => changed.contains(w.id))) {
        _send(Mutation.upsert('workouts', workoutRow(w)));
      }
      _send(Mutation.delete('exercises', {'id': id}));
    }
    _commit();
  }

  void deleteWorkout(String id) {
    final changed = myPrograms.where((p) => p.workoutIds.contains(id)).map((p) => p.id).toSet();
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
    if (isCloud) {
      for (final p in myPrograms.where((p) => changed.contains(p.id))) {
        _send(Mutation.upsert('programs', programRow(p)));
      }
      _send(Mutation.delete('workouts', {'id': id}));
    }
    _commit();
  }

  void deleteProgram(String id) {
    myPrograms = myPrograms.where((p) => p.id != id).toList();
    if (isCloud) _send(Mutation.delete('programs', {'id': id}));
    _commit();
  }

  static List<T> _upsert<T>(List<T> list, T item, String Function(T) id) {
    final i = list.indexWhere((x) => id(x) == id(item));
    return i < 0 ? [...list, item] : ([...list]..[i] = item);
  }
}
