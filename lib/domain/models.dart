/// Domain model: Exercise → Workout → Program → UserPlan → Session.
/// Sessions snapshot names and targets so history stays exact when a
/// creator later edits their content.
library;

enum Equipment {
  barbell('Šipka'),
  dumbbell('Bučice'),
  bench('Klupa'),
  machine('Mašine'),
  cable('Sajla'),
  kettlebell('Girja'),
  pullupBar('Vratilo'),
  band('Elastične trake'),
  bodyweight('Bez opreme');

  const Equipment(this.label);
  final String label;

  static const gym = {barbell, dumbbell, bench, machine, cable, kettlebell, pullupBar, band};
  static const home = {dumbbell, band};
}

enum Muscle {
  chest('Grudi'),
  back('Leđa'),
  shoulders('Ramena'),
  biceps('Biceps'),
  triceps('Triceps'),
  quads('Kvadricepsi'),
  hamstrings('Zadnja loža'),
  glutes('Gluteus'),
  calves('Listovi'),
  core('Trup');

  const Muscle(this.label);
  final String label;
}

enum Goal {
  strength('Snaga'),
  muscle('Mišićna masa'),
  conditioning('Kondicija'),
  general('Opšta forma');

  const Goal(this.label);
  final String label;
}

enum Experience {
  beginner('Početnik'),
  intermediate('Srednji nivo'),
  advanced('Napredni');

  const Experience(this.label);
  final String label;
}

enum Place {
  gym('Teretana'),
  home('Kod kuće');

  const Place(this.label);
  final String label;
}

/// Used to address the user in Serbian (`Pojavio/Pojavila si se.`).
enum Gender {
  female('Žensko'),
  male('Muško'),
  unspecified('Ne želim da kažem');

  const Gender(this.label);
  final String label;
}

enum Audience {
  public('Javno'),
  subscribers('Za pretplatnike');

  const Audience(this.label);
  final String label;
}

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.where((v) => v.name == name).firstOrNull ?? fallback;

class Creator {
  const Creator({
    required this.id,
    required this.name,
    required this.handle,
    required this.tagline,
    required this.bio,
    this.followers = 0,
    this.priceMonthly = 4.99,
    this.isMine = false,
  });

  final String id;
  final String name;

  /// Without the @.
  final String handle;
  final String tagline;
  final String bio;
  final int followers;
  final double priceMonthly;

  /// Created in this app's creator mode.
  final bool isMine;

  Creator copyWith({String? name, String? handle, String? tagline, String? bio}) => Creator(
    id: id,
    name: name ?? this.name,
    handle: handle ?? this.handle,
    tagline: tagline ?? this.tagline,
    bio: bio ?? this.bio,
    followers: followers,
    priceMonthly: priceMonthly,
    isMine: isMine,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'handle': handle,
    'tagline': tagline,
    'bio': bio,
    'followers': followers,
    'priceMonthly': priceMonthly,
    'isMine': isMine,
  };

  factory Creator.fromJson(Map<String, Object?> j) => Creator(
    id: j['id'] as String,
    name: j['name'] as String,
    handle: j['handle'] as String,
    tagline: j['tagline'] as String? ?? '',
    bio: j['bio'] as String? ?? '',
    followers: j['followers'] as int? ?? 0,
    priceMonthly: (j['priceMonthly'] as num?)?.toDouble() ?? 4.99,
    isMine: j['isMine'] as bool? ?? false,
  );
}

class Exercise {
  const Exercise({
    required this.id,
    required this.creatorId,
    required this.name,
    required this.muscle,
    required this.equipment,
    this.note = '',
    this.visibility = Audience.public,
  });

  final String id;
  final String creatorId;
  final String name;
  final Muscle muscle;

  /// Everything needed at once. Empty or [Equipment.bodyweight] means none.
  final Set<Equipment> equipment;

  /// The creator's cue, in their voice.
  final String note;
  final Audience visibility;

  bool get isBodyweight => equipment.every((e) => e == Equipment.bodyweight);

  String get equipmentLabel => isBodyweight
      ? Equipment.bodyweight.label
      : equipment.where((e) => e != Equipment.bodyweight).map((e) => e.label).join(', ');

  Map<String, Object?> toJson() => {
    'id': id,
    'creatorId': creatorId,
    'name': name,
    'muscle': muscle.name,
    'equipment': equipment.map((e) => e.name).toList(),
    'note': note,
    'visibility': visibility.name,
  };

  factory Exercise.fromJson(Map<String, Object?> j) => Exercise(
    id: j['id'] as String,
    creatorId: j['creatorId'] as String,
    name: j['name'] as String,
    muscle: _enum(Muscle.values, j['muscle'], Muscle.chest),
    equipment: {
      for (final e in (j['equipment'] as List? ?? const [])) _enum(Equipment.values, e, Equipment.bodyweight),
    },
    note: j['note'] as String? ?? '',
    visibility: _enum(Audience.values, j['visibility'], Audience.public),
  );
}

/// One exercise inside a workout, with its prescription.
class WorkoutExercise {
  const WorkoutExercise({
    required this.exerciseId,
    this.sets = 3,
    this.repsMin = 8,
    this.repsMax = 10,
    this.rir,
    this.restSeconds = 90,
  });

  final String exerciseId;
  final int sets;
  final int repsMin;
  final int repsMax;
  final int? rir;
  final int restSeconds;

  /// `4 × 6–8`
  String get target => '$sets × ${repsMin == repsMax ? '$repsMin' : '$repsMin–$repsMax'}';

  WorkoutExercise copyWith({String? exerciseId, int? sets, int? repsMin, int? repsMax, int? restSeconds}) =>
      WorkoutExercise(
        exerciseId: exerciseId ?? this.exerciseId,
        sets: sets ?? this.sets,
        repsMin: repsMin ?? this.repsMin,
        repsMax: repsMax ?? this.repsMax,
        rir: rir,
        restSeconds: restSeconds ?? this.restSeconds,
      );

  Map<String, Object?> toJson() => {
    'exerciseId': exerciseId,
    'sets': sets,
    'repsMin': repsMin,
    'repsMax': repsMax,
    'rir': rir,
    'restSeconds': restSeconds,
  };

  factory WorkoutExercise.fromJson(Map<String, Object?> j) => WorkoutExercise(
    exerciseId: j['exerciseId'] as String,
    sets: j['sets'] as int? ?? 3,
    repsMin: j['repsMin'] as int? ?? 8,
    repsMax: j['repsMax'] as int? ?? 10,
    rir: j['rir'] as int?,
    restSeconds: j['restSeconds'] as int? ?? 90,
  );
}

class Workout {
  const Workout({
    required this.id,
    required this.creatorId,
    required this.name,
    required this.exercises,
    this.finishMessage = '',
    this.visibility = Audience.public,
  });

  final String id;
  final String creatorId;
  final String name;
  final List<WorkoutExercise> exercises;

  /// Shown on the summary, in the creator's voice.
  final String finishMessage;
  final Audience visibility;

  int get totalSets => exercises.fold(0, (s, e) => s + e.sets);

  /// ~45 s per set plus prescribed rest, rounded to 5 min.
  int get estimatedMinutes {
    final seconds = exercises.fold(0, (s, e) => s + e.sets * (45 + e.restSeconds));
    return ((seconds / 60) / 5).ceil() * 5;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'creatorId': creatorId,
    'name': name,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'finishMessage': finishMessage,
    'visibility': visibility.name,
  };

  factory Workout.fromJson(Map<String, Object?> j) => Workout(
    id: j['id'] as String,
    creatorId: j['creatorId'] as String,
    name: j['name'] as String,
    exercises: [
      for (final e in (j['exercises'] as List? ?? const []))
        WorkoutExercise.fromJson(e as Map<String, Object?>),
    ],
    finishMessage: j['finishMessage'] as String? ?? '',
    visibility: _enum(Audience.values, j['visibility'], Audience.public),
  );
}

class Program {
  const Program({
    required this.id,
    required this.creatorId,
    required this.name,
    required this.workoutIds,
    this.description = '',
    this.weeks = 8,
    this.daysPerWeek = 3,
    this.level = Experience.beginner,
    this.goal = Goal.general,
    this.place = Place.gym,
    this.visibility = Audience.public,
  });

  final String id;
  final String creatorId;
  final String name;

  /// Rotation order. Workouts repeat; the plan is not tied to dates.
  final List<String> workoutIds;
  final String description;
  final int weeks;
  final int daysPerWeek;
  final Experience level;
  final Goal goal;
  final Place place;
  final Audience visibility;

  Map<String, Object?> toJson() => {
    'id': id,
    'creatorId': creatorId,
    'name': name,
    'workoutIds': workoutIds,
    'description': description,
    'weeks': weeks,
    'daysPerWeek': daysPerWeek,
    'level': level.name,
    'goal': goal.name,
    'place': place.name,
    'visibility': visibility.name,
  };

  factory Program.fromJson(Map<String, Object?> j) => Program(
    id: j['id'] as String,
    creatorId: j['creatorId'] as String,
    name: j['name'] as String,
    workoutIds: [for (final w in (j['workoutIds'] as List? ?? const [])) w as String],
    description: j['description'] as String? ?? '',
    weeks: j['weeks'] as int? ?? 8,
    daysPerWeek: j['daysPerWeek'] as int? ?? 3,
    level: _enum(Experience.values, j['level'], Experience.beginner),
    goal: _enum(Goal.values, j['goal'], Goal.general),
    place: _enum(Place.values, j['place'], Place.gym),
    visibility: _enum(Audience.values, j['visibility'], Audience.public),
  );
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.goal,
    required this.experience,
    required this.place,
    required this.daysPerWeek,
    required this.equipment,
    this.gender = Gender.unspecified,
  });

  final String name;
  final Gender gender;
  final Goal goal;
  final Experience experience;
  final Place place;

  /// Weekly goal.
  final int daysPerWeek;
  final Set<Equipment> equipment;

  UserProfile copyWith({int? daysPerWeek, Set<Equipment>? equipment, String? name, Gender? gender}) =>
      UserProfile(
        name: name ?? this.name,
        gender: gender ?? this.gender,
        goal: goal,
        experience: experience,
        place: place,
        daysPerWeek: daysPerWeek ?? this.daysPerWeek,
        equipment: equipment ?? this.equipment,
      );

  /// Picks the grammatical form for this user: [female] for women, [male]
  /// otherwise (Serbian's default when gender is not given).
  String says(String male, String female) => gender == Gender.female ? female : male;

  Map<String, Object?> toJson() => {
    'name': name,
    'gender': gender.name,
    'goal': goal.name,
    'experience': experience.name,
    'place': place.name,
    'daysPerWeek': daysPerWeek,
    'equipment': equipment.map((e) => e.name).toList(),
  };

  factory UserProfile.fromJson(Map<String, Object?> j) => UserProfile(
    name: j['name'] as String? ?? '',
    gender: _enum(Gender.values, j['gender'], Gender.unspecified),
    goal: _enum(Goal.values, j['goal'], Goal.general),
    experience: _enum(Experience.values, j['experience'], Experience.beginner),
    place: _enum(Place.values, j['place'], Place.gym),
    daysPerWeek: j['daysPerWeek'] as int? ?? 3,
    equipment: {
      for (final e in (j['equipment'] as List? ?? const [])) _enum(Equipment.values, e, Equipment.bodyweight),
    },
  );
}

/// `2026-10-01`: the key of a calendar day.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The user's own decision for one calendar day. The plan only suggests;
/// a day plan wins over it.
class DayPlan {
  const DayPlan.rest({this.note}) : train = false, workoutId = null, exercises = null;

  const DayPlan.train({this.workoutId, this.exercises, this.note}) : train = true;

  /// Training day (true) or rest day (false).
  final bool train;

  /// A specific workout for this day. Null takes the plan's next workout,
  /// which keeps the rotation moving.
  final String? workoutId;

  /// This day's own exercise list (swapped, removed, added, shortened).
  /// Null uses the workout as it is.
  final List<WorkoutExercise>? exercises;

  /// Why the day differs from the plan, shown on the day: `Kraća verzija`.
  final String? note;

  bool get edited => exercises != null || workoutId != null;

  Map<String, Object?> toJson() => {
    'train': train,
    if (workoutId != null) 'workoutId': workoutId,
    if (exercises != null) 'exercises': [for (final e in exercises!) e.toJson()],
    if (note != null) 'note': note,
  };

  factory DayPlan.fromJson(Map<String, Object?> j) => (j['train'] as bool? ?? true)
      ? DayPlan.train(
          workoutId: j['workoutId'] as String?,
          exercises: j['exercises'] == null
              ? null
              : [
                  for (final e in j['exercises'] as List)
                    WorkoutExercise.fromJson((e as Map).cast<String, Object?>()),
                ],
          note: j['note'] as String?,
        )
      : DayPlan.rest(note: j['note'] as String?);
}

Map<String, DayPlan> dayPlansFromJson(Object? json) => {
  for (final e in ((json as Map?) ?? const {}).entries)
    e.key as String: DayPlan.fromJson((e.value as Map).cast<String, Object?>()),
};

/// The follower's own copy of a program: workout order plus exercise swaps.
class UserPlan {
  const UserPlan({
    required this.id,
    required this.programId,
    required this.creatorId,
    required this.name,
    required this.workoutIds,
    required this.weeks,
    required this.daysPerWeek,
    required this.startedAt,
    this.swaps = const {},
    this.nextIndex = 0,
    this.completed = 0,
    this.trainingDays = const {},
    this.days = const {},
  });

  final String id;
  final String programId;
  final String creatorId;
  final String name;
  final List<String> workoutIds;
  final int weeks;
  final int daysPerWeek;
  final DateTime startedAt;

  /// Original exercise id → replacement exercise id.
  final Map<String, String> swaps;

  /// Position in [workoutIds] of the next workout.
  final int nextIndex;

  /// Workouts finished within this plan.
  final int completed;

  /// Weekdays the user plans to train (1 = Monday … 7 = Sunday). Planned days
  /// are a forecast: a missed day just moves the next workout forward.
  final Set<int> trainingDays;

  /// The user's changes to single days, by [dayKey]. Days without an entry
  /// follow [trainingDays] and the rotation.
  final Map<String, DayPlan> days;

  String get nextWorkoutId => workoutIds[nextIndex % workoutIds.length];

  /// 1-based program week, capped at [weeks].
  int get currentWeek => (completed ~/ daysPerWeek + 1).clamp(1, weeks);

  UserPlan copyWith({
    Map<String, String>? swaps,
    int? nextIndex,
    int? completed,
    Set<int>? trainingDays,
    Map<String, DayPlan>? days,
  }) => UserPlan(
    id: id,
    programId: programId,
    creatorId: creatorId,
    name: name,
    workoutIds: workoutIds,
    weeks: weeks,
    daysPerWeek: daysPerWeek,
    startedAt: startedAt,
    swaps: swaps ?? this.swaps,
    nextIndex: nextIndex ?? this.nextIndex,
    completed: completed ?? this.completed,
    trainingDays: trainingDays ?? this.trainingDays,
    days: days ?? this.days,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'programId': programId,
    'creatorId': creatorId,
    'name': name,
    'workoutIds': workoutIds,
    'weeks': weeks,
    'daysPerWeek': daysPerWeek,
    'startedAt': startedAt.toIso8601String(),
    'swaps': swaps,
    'nextIndex': nextIndex,
    'completed': completed,
    'trainingDays': (trainingDays.toList()..sort()),
    'days': {for (final e in days.entries) e.key: e.value.toJson()},
  };

  factory UserPlan.fromJson(Map<String, Object?> j) => UserPlan(
    id: j['id'] as String,
    programId: j['programId'] as String,
    creatorId: j['creatorId'] as String,
    name: j['name'] as String,
    workoutIds: [for (final w in (j['workoutIds'] as List? ?? const [])) w as String],
    weeks: j['weeks'] as int? ?? 8,
    daysPerWeek: j['daysPerWeek'] as int? ?? 3,
    startedAt: DateTime.parse(j['startedAt'] as String),
    swaps: {for (final e in ((j['swaps'] as Map?) ?? const {}).entries) e.key as String: e.value as String},
    nextIndex: j['nextIndex'] as int? ?? 0,
    completed: j['completed'] as int? ?? 0,
    trainingDays: {for (final d in (j['trainingDays'] as List? ?? const [])) d as int},
    days: dayPlansFromJson(j['days']),
  );
}

class SetLog {
  const SetLog({this.kg, this.reps, this.rir, this.done = false, this.isPr = false});

  final double? kg;
  final int? reps;
  final int? rir;
  final bool done;
  final bool isPr;

  double get volume => done ? (kg ?? 0) * (reps ?? 0) : 0;

  SetLog copyWith({
    double? kg,
    int? reps,
    int? rir,
    bool? done,
    bool? isPr,
    bool clearKg = false,
    bool clearReps = false,
    bool clearRir = false,
  }) => SetLog(
    kg: clearKg ? null : (kg ?? this.kg),
    reps: clearReps ? null : (reps ?? this.reps),
    rir: clearRir ? null : (rir ?? this.rir),
    done: done ?? this.done,
    isPr: isPr ?? this.isPr,
  );

  Map<String, Object?> toJson() => {'kg': kg, 'reps': reps, 'rir': rir, 'done': done, 'isPr': isPr};

  factory SetLog.fromJson(Map<String, Object?> j) => SetLog(
    kg: (j['kg'] as num?)?.toDouble(),
    reps: j['reps'] as int?,
    rir: j['rir'] as int?,
    done: j['done'] as bool? ?? false,
    isPr: j['isPr'] as bool? ?? false,
  );
}

class SessionExercise {
  const SessionExercise({
    required this.exerciseId,
    required this.name,
    required this.muscle,
    required this.target,
    required this.restSeconds,
    required this.sets,
    this.repsMin = 8,
    this.repsMax = 10,
    this.bodyweight = false,
    this.rir,
    this.note = '',
    this.noteBy,
    this.swappedFrom,
  });

  final String exerciseId;
  final String name;
  final Muscle muscle;
  final int repsMin;
  final int repsMax;

  /// Weight is optional (added load) when true.
  final bool bodyweight;

  /// Snapshot of the prescription, e.g. `4 × 6–8`.
  final String target;
  final int restSeconds;
  final int? rir;
  final String note;

  /// Author of the exercise and its note (may differ from the workout's creator after a swap).
  final String? noteBy;
  final List<SetLog> sets;

  /// Original exercise name when swapped during the session or in the plan.
  final String? swappedFrom;

  Iterable<SetLog> get doneSets => sets.where((s) => s.done);
  bool get isComplete => sets.isNotEmpty && sets.every((s) => s.done);
  bool get hasPr => sets.any((s) => s.isPr);
  double get volume => sets.fold(0, (v, s) => v + s.volume);

  SessionExercise copyWith({List<SetLog>? sets}) => SessionExercise(
    exerciseId: exerciseId,
    name: name,
    muscle: muscle,
    target: target,
    repsMin: repsMin,
    repsMax: repsMax,
    bodyweight: bodyweight,
    restSeconds: restSeconds,
    rir: rir,
    note: note,
    noteBy: noteBy,
    sets: sets ?? this.sets,
    swappedFrom: swappedFrom,
  );

  Map<String, Object?> toJson() => {
    'exerciseId': exerciseId,
    'name': name,
    'muscle': muscle.name,
    'target': target,
    'repsMin': repsMin,
    'repsMax': repsMax,
    'bodyweight': bodyweight,
    'restSeconds': restSeconds,
    'rir': rir,
    'note': note,
    'noteBy': noteBy,
    'sets': sets.map((s) => s.toJson()).toList(),
    'swappedFrom': swappedFrom,
  };

  factory SessionExercise.fromJson(Map<String, Object?> j) => SessionExercise(
    exerciseId: j['exerciseId'] as String,
    name: j['name'] as String,
    muscle: _enum(Muscle.values, j['muscle'], Muscle.chest),
    target: j['target'] as String? ?? '',
    repsMin: j['repsMin'] as int? ?? 8,
    repsMax: j['repsMax'] as int? ?? 10,
    bodyweight: j['bodyweight'] as bool? ?? false,
    restSeconds: j['restSeconds'] as int? ?? 90,
    rir: j['rir'] as int?,
    note: j['note'] as String? ?? '',
    noteBy: j['noteBy'] as String?,
    sets: [for (final s in (j['sets'] as List? ?? const [])) SetLog.fromJson(s as Map<String, Object?>)],
    swappedFrom: j['swappedFrom'] as String?,
  );
}

class Session {
  const Session({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.creatorId,
    required this.creatorName,
    required this.startedAt,
    required this.exercises,
    this.planId,
    this.finishedAt,
    this.finishMessage = '',
  });

  final String id;
  final String? planId;
  final String workoutId;
  final String workoutName;
  final String creatorId;
  final String creatorName;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<SessionExercise> exercises;
  final String finishMessage;

  bool get isFinished => finishedAt != null;
  Duration get duration => (finishedAt ?? startedAt).difference(startedAt);
  double get volume => exercises.fold(0, (v, e) => v + e.volume);
  int get prCount => exercises.fold(0, (n, e) => n + e.sets.where((s) => s.isPr).length);
  int get doneSets => exercises.fold(0, (n, e) => n + e.doneSets.length);

  Session copyWith({List<SessionExercise>? exercises, DateTime? finishedAt, String? finishMessage}) =>
      Session(
        id: id,
        planId: planId,
        workoutId: workoutId,
        workoutName: workoutName,
        creatorId: creatorId,
        creatorName: creatorName,
        startedAt: startedAt,
        finishedAt: finishedAt ?? this.finishedAt,
        exercises: exercises ?? this.exercises,
        finishMessage: finishMessage ?? this.finishMessage,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'planId': planId,
    'workoutId': workoutId,
    'workoutName': workoutName,
    'creatorId': creatorId,
    'creatorName': creatorName,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'finishMessage': finishMessage,
  };

  factory Session.fromJson(Map<String, Object?> j) => Session(
    id: j['id'] as String,
    planId: j['planId'] as String?,
    workoutId: j['workoutId'] as String,
    workoutName: j['workoutName'] as String,
    creatorId: j['creatorId'] as String,
    creatorName: j['creatorName'] as String,
    startedAt: DateTime.parse(j['startedAt'] as String),
    finishedAt: j['finishedAt'] == null ? null : DateTime.parse(j['finishedAt'] as String),
    exercises: [
      for (final e in (j['exercises'] as List? ?? const []))
        SessionExercise.fromJson(e as Map<String, Object?>),
    ],
    finishMessage: j['finishMessage'] as String? ?? '',
  );
}

/// A sensible weekly pattern for [daysPerWeek], with rest days spread out.
Set<int> defaultTrainingDays(int daysPerWeek) => switch (daysPerWeek) {
  <= 1 => {1},
  2 => {1, 4},
  3 => {1, 3, 5},
  4 => {1, 2, 4, 5},
  5 => {1, 2, 3, 4, 5},
  6 => {1, 2, 3, 4, 5, 6},
  _ => {1, 2, 3, 4, 5, 6, 7},
};
