/// Domain ↔ database rows (snake_case columns, see supabase/migrations).
/// Nested values (prescriptions, swaps, session sets) stay camelCase JSON.
library;

import '../domain/models.dart';

typedef Row = Map<String, Object?>;

List<String> _names(Iterable<Enum> values) => [for (final v in values) v.name];

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.where((v) => v.name == name).firstOrNull ?? fallback;

List<Object?> _list(Object? o) => (o as List?) ?? const [];

// ───────────────────────── Catalog

Row creatorRow(Creator c, {String? userId}) => {
  'id': c.id,
  'user_id': ?userId,
  'name': c.name,
  'handle': c.handle,
  'tagline': c.tagline,
  'bio': c.bio,
  'followers': c.followers,
  'price_monthly': c.priceMonthly,
  'photo_url': c.photo,
};

Creator creatorFromRow(Row r, {String? currentUserId}) => Creator(
  id: r['id'] as String,
  name: r['name'] as String,
  handle: r['handle'] as String,
  tagline: r['tagline'] as String? ?? '',
  bio: r['bio'] as String? ?? '',
  followers: (r['followers'] as num?)?.toInt() ?? 0,
  priceMonthly: (r['price_monthly'] as num?)?.toDouble() ?? 4.99,
  isMine: currentUserId != null && r['user_id'] == currentUserId,
  photo: r['photo_url'] as String?,
);

Row exerciseRow(Exercise e) => {
  'id': e.id,
  'creator_id': e.creatorId,
  'name': e.name,
  'muscle': e.muscle.name,
  'equipment': _names(e.equipment),
  'note': e.note,
  'audience': e.visibility.name,
  'image_url': e.image,
  'video_url': e.video,
};

Exercise exerciseFromRow(Row r) => Exercise(
  id: r['id'] as String,
  creatorId: r['creator_id'] as String,
  name: r['name'] as String,
  muscle: _enum(Muscle.values, r['muscle'], Muscle.chest),
  equipment: {for (final e in _list(r['equipment'])) _enum(Equipment.values, e, Equipment.bodyweight)},
  note: r['note'] as String? ?? '',
  visibility: _enum(Audience.values, r['audience'], Audience.public),
  image: r['image_url'] as String?,
  video: r['video_url'] as String?,
);

Row workoutRow(Workout w) => {
  'id': w.id,
  'creator_id': w.creatorId,
  'name': w.name,
  'exercises': [for (final e in w.exercises) e.toJson()],
  'finish_message': w.finishMessage,
  'audience': w.visibility.name,
  'image_url': w.image,
  'intro': w.intro,
};

Workout workoutFromRow(Row r) => Workout(
  id: r['id'] as String,
  creatorId: r['creator_id'] as String,
  name: r['name'] as String,
  exercises: [for (final e in _list(r['exercises'])) WorkoutExercise.fromJson((e as Map).cast())],
  finishMessage: r['finish_message'] as String? ?? '',
  visibility: _enum(Audience.values, r['audience'], Audience.public),
  image: r['image_url'] as String?,
  intro: r['intro'] as String? ?? '',
);

Row programRow(Program p) => {
  'id': p.id,
  'creator_id': p.creatorId,
  'name': p.name,
  'description': p.description,
  'workout_ids': p.workoutIds,
  'weeks': p.weeks,
  'days_per_week': p.daysPerWeek,
  'level': p.level.name,
  'goal': p.goal.name,
  'place': p.place.name,
  'audience': p.visibility.name,
  'image_url': p.image,
};

Program programFromRow(Row r) => Program(
  id: r['id'] as String,
  creatorId: r['creator_id'] as String,
  name: r['name'] as String,
  description: r['description'] as String? ?? '',
  workoutIds: [for (final w in _list(r['workout_ids'])) w as String],
  weeks: (r['weeks'] as num?)?.toInt() ?? 8,
  daysPerWeek: (r['days_per_week'] as num?)?.toInt() ?? 3,
  level: _enum(Experience.values, r['level'], Experience.beginner),
  goal: _enum(Goal.values, r['goal'], Goal.general),
  place: _enum(Place.values, r['place'], Place.gym),
  visibility: _enum(Audience.values, r['audience'], Audience.public),
  image: r['image_url'] as String?,
);

// ───────────────────────── Follower data

Row profileRow(UserProfile p, String userId) => {
  'user_id': userId,
  'name': p.name,
  'gender': p.gender.name,
  'goal': p.goal.name,
  'experience': p.experience.name,
  'place': p.place.name,
  'days_per_week': p.daysPerWeek,
  'equipment': _names(p.equipment),
};

UserProfile profileFromRow(Row r) => UserProfile(
  name: r['name'] as String,
  gender: _enum(Gender.values, r['gender'], Gender.unspecified),
  goal: _enum(Goal.values, r['goal'], Goal.general),
  experience: _enum(Experience.values, r['experience'], Experience.beginner),
  place: _enum(Place.values, r['place'], Place.gym),
  daysPerWeek: (r['days_per_week'] as num?)?.toInt() ?? 3,
  equipment: {for (final e in _list(r['equipment'])) _enum(Equipment.values, e, Equipment.bodyweight)},
);

Row planRow(UserPlan p, String userId) => {
  'id': p.id,
  'user_id': userId,
  'program_id': p.programId,
  'creator_id': p.creatorId,
  'name': p.name,
  'workout_ids': p.workoutIds,
  'weeks': p.weeks,
  'days_per_week': p.daysPerWeek,
  'started_at': p.startedAt.toUtc().toIso8601String(),
  'swaps': p.swaps,
  'next_index': p.nextIndex,
  'completed': p.completed,
  'training_days': (p.trainingDays.toList()..sort()),
  'days': {for (final e in p.days.entries) e.key: e.value.toJson()},
};

UserPlan planFromRow(Row r) => UserPlan(
  id: r['id'] as String,
  programId: r['program_id'] as String,
  creatorId: r['creator_id'] as String,
  name: r['name'] as String,
  workoutIds: [for (final w in _list(r['workout_ids'])) w as String],
  weeks: (r['weeks'] as num?)?.toInt() ?? 8,
  daysPerWeek: (r['days_per_week'] as num?)?.toInt() ?? 3,
  startedAt: DateTime.parse(r['started_at'] as String).toLocal(),
  swaps: {for (final e in ((r['swaps'] as Map?) ?? const {}).entries) e.key as String: e.value as String},
  nextIndex: (r['next_index'] as num?)?.toInt() ?? 0,
  completed: (r['completed'] as num?)?.toInt() ?? 0,
  trainingDays: {for (final d in _list(r['training_days'])) (d as num).toInt()},
  days: dayPlansFromJson(r['days']),
);

Row sessionRow(Session s, String userId) => {
  'id': s.id,
  'user_id': userId,
  'plan_id': s.planId,
  'workout_id': s.workoutId,
  'workout_name': s.workoutName,
  'creator_id': s.creatorId,
  'creator_name': s.creatorName,
  'started_at': s.startedAt.toUtc().toIso8601String(),
  'finished_at': s.finishedAt?.toUtc().toIso8601String(),
  'finish_message': s.finishMessage,
  'exercises': [for (final e in s.exercises) e.toJson()],
};

Session sessionFromRow(Row r) => Session(
  id: r['id'] as String,
  planId: r['plan_id'] as String?,
  workoutId: r['workout_id'] as String,
  workoutName: r['workout_name'] as String,
  creatorId: r['creator_id'] as String,
  creatorName: r['creator_name'] as String,
  startedAt: DateTime.parse(r['started_at'] as String).toLocal(),
  finishedAt: r['finished_at'] == null ? null : DateTime.parse(r['finished_at'] as String).toLocal(),
  finishMessage: r['finish_message'] as String? ?? '',
  exercises: [for (final e in _list(r['exercises'])) SessionExercise.fromJson((e as Map).cast())],
);
