import 'dart:math' as math;

import 'models.dart';

/// Monday 00:00 of the week containing [d], in local time.
DateTime weekStart(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

Iterable<Session> finished(Iterable<Session> sessions) => sessions.where((s) => s.isFinished);

/// Consecutive weeks with at least one finished workout, counting back from
/// this week. An empty current week does not break the streak until it ends:
/// a rest day is a fresh start, never a failure.
int streakWeeks(Iterable<Session> sessions, DateTime now) {
  final weeks = {for (final s in finished(sessions)) weekStart(s.finishedAt!)};
  var cursor = weekStart(now);
  if (!weeks.contains(cursor)) cursor = _previousWeek(cursor);
  var streak = 0;
  while (weeks.contains(cursor)) {
    streak++;
    cursor = _previousWeek(cursor);
  }
  return streak;
}

// Calendar arithmetic, not 7×24h, so DST changes don't shift weeks.
DateTime _previousWeek(DateTime monday) => DateTime(monday.year, monday.month, monday.day - 7);

int sessionsThisWeek(Iterable<Session> sessions, DateTime now) {
  final start = weekStart(now);
  return finished(sessions).where((s) => !s.finishedAt!.isBefore(start)).length;
}

/// Estimated one-rep max (Epley).
double e1rm(double kg, int reps) => reps <= 1 ? kg : kg * (1 + reps / 30);

/// What a set is compared on: estimated 1RM when loaded, reps when bodyweight.
double? setScore(SetLog s) {
  if (!s.done || s.reps == null || s.reps! <= 0) return null;
  final kg = s.kg ?? 0;
  return kg > 0 ? e1rm(kg, s.reps!) : s.reps!.toDouble();
}

/// Best score for [exerciseId] across finished sessions, or null if never done.
double? bestScore(Iterable<Session> history, String exerciseId) {
  double? best;
  for (final session in finished(history)) {
    for (final e in session.exercises.where((e) => e.exerciseId == exerciseId)) {
      for (final s in e.sets) {
        final score = setScore(s);
        if (score != null && (best == null || score > best)) best = score;
      }
    }
  }
  return best;
}

/// A set is a record only when it beats an existing best. The first time an
/// exercise is done there is nothing to beat yet.
bool isRecord(double? previousBest, SetLog set) {
  final score = setScore(set);
  return previousBest != null && score != null && score > previousBest + 1e-9;
}

/// Sets from the most recent finished session that included [exerciseId].
List<SetLog> previousSets(Iterable<Session> history, String exerciseId) {
  final sorted = finished(history).toList()..sort((a, b) => b.finishedAt!.compareTo(a.finishedAt!));
  for (final s in sorted) {
    for (final e in s.exercises) {
      if (e.exerciseId == exerciseId) return e.doneSets.toList();
    }
  }
  return const [];
}

bool canDo(Exercise e, Set<Equipment> available) =>
    e.equipment.every((x) => x == Equipment.bodyweight || available.contains(x));

/// How many of the program's exercises the user can do with their equipment.
({int doable, int total}) programFit(
  Program p,
  Map<String, Workout> workouts,
  Map<String, Exercise> exercises,
  Set<Equipment> available,
) {
  final ids = <String>{
    for (final w in p.workoutIds.map((id) => workouts[id]).nonNulls)
      for (final we in w.exercises) we.exerciseId,
  };
  final list = ids.map((id) => exercises[id]).nonNulls.toList();
  return (doable: list.where((e) => canDo(e, available)).length, total: list.length);
}

Set<String> _words(String name) =>
    name.toLowerCase().split(RegExp(r'[^a-zčćžšđ]+')).where((w) => w.length >= 4).toSet();

/// Alternatives for [original]: same muscle, doable with [available].
/// Closest first: shared name words (a dumbbell press for a barbell press),
/// then the same creator, then alphabetical.
List<Exercise> substitutes(Exercise original, Iterable<Exercise> candidates, Set<Equipment> available) {
  final words = _words(original.name);
  int similarity(Exercise e) => _words(e.name).intersection(words).length;
  final list = candidates
      .where((e) => e.id != original.id && e.muscle == original.muscle && canDo(e, available))
      .toList();
  list.sort((a, b) {
    final sim = similarity(b) - similarity(a);
    if (sim != 0) return sim;
    final sameA = a.creatorId == original.creatorId ? 0 : 1;
    final sameB = b.creatorId == original.creatorId ? 0 : 1;
    if (sameA != sameB) return sameA - sameB;
    return a.name.compareTo(b.name);
  });
  // A name can exist once per creator; keep the first (preferred) one.
  final seen = <String>{};
  return [
    for (final e in list)
      if (seen.add(e.name.toLowerCase())) e,
  ];
}

int totalRecords(Iterable<Session> sessions) => finished(sessions).fold(0, (n, s) => n + s.prCount);

/// Volume per week for the last [weeks] weeks, oldest first.
List<({DateTime week, double volume})> weeklyVolume(Iterable<Session> sessions, DateTime now, int weeks) {
  final current = weekStart(now);
  final result = [
    for (var i = weeks - 1; i >= 0; i--)
      (week: DateTime(current.year, current.month, current.day - 7 * i), volume: 0.0),
  ];
  for (final s in finished(sessions)) {
    final w = weekStart(s.finishedAt!);
    final i = result.indexWhere((r) => r.week == w);
    if (i >= 0) result[i] = (week: w, volume: result[i].volume + s.volume);
  }
  return result;
}

/// Best score per finished session for [exerciseId], oldest first.
List<({DateTime date, double score})> exerciseHistory(Iterable<Session> sessions, String exerciseId) {
  final sorted = finished(sessions).toList()..sort((a, b) => a.finishedAt!.compareTo(b.finishedAt!));
  final result = <({DateTime date, double score})>[];
  for (final s in sorted) {
    double? best;
    for (final e in s.exercises.where((e) => e.exerciseId == exerciseId)) {
      for (final set in e.sets) {
        final score = setScore(set);
        if (score != null) best = math.max(best ?? score, score);
      }
    }
    if (best != null) result.add((date: s.finishedAt!, score: best));
  }
  return result;
}

/// The heaviest done set, for summary lines: highest kg, then most reps.
SetLog? topSet(SessionExercise e) {
  SetLog? top;
  for (final s in e.doneSets) {
    if (top == null ||
        (s.kg ?? 0) > (top.kg ?? 0) ||
        ((s.kg ?? 0) == (top.kg ?? 0) && (s.reps ?? 0) > (top.reps ?? 0))) {
      top = s;
    }
  }
  return top;
}
