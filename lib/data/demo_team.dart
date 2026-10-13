import '../domain/models.dart';
import '../domain/team.dart';

/// A believable team for a creator in local mode, where there is no server
/// to share posts: a few fictional members who trained today and yesterday,
/// some with records, one answered by the creator. Stable for a day.
Team demoTeam(Creator creator, List<Workout> workouts, DateTime now) {
  const names = ['Mila J.', 'Jovana S.', 'Tea K.', 'Nina P.', 'Sara M.', 'Luka D.', 'Marija V.', 'Ivana R.'];
  const records = ['Hip thrust 60 kg', 'Čučanj 50 kg', 'Rumunsko 45 kg', 'Sklekovi 15 pon.', 'Plank 1:10'];
  final members = (creator.followers / 100).round().clamp(24, 4800);
  final seed = creator.id.codeUnits.fold(0, (a, b) => a + b) + now.day;
  final day = DateTime(now.year, now.month, now.day);
  final names_ = workouts.isEmpty ? ['Trening'] : [for (final w in workouts) w.name];
  final posts = <TeamPost>[
    for (var i = 0; i < 6; i++)
      TeamPost(
        id: 'demo-${creator.id}-${now.day}-$i',
        creatorId: creator.id,
        userId: 'demo-$i',
        authorName: names[(seed + i) % names.length],
        workoutName: names_[(seed + i) % names_.length],
        // Three this morning and afternoon, the rest yesterday.
        createdAt: i < 3
            ? day.add(Duration(hours: 7 + i * 3, minutes: (seed * 7 + i * 13) % 60))
            : day.subtract(Duration(hours: 3 + i * 2)),
        records: (seed + i) % 3 == 0 ? [records[(seed + i) % records.length]] : const [],
        streakWeeks: (seed + i) % 5 + 1,
        cheers: 4 + (seed * (i + 3)) % 90,
        reply: i == 1 ? 'Svaka čast, vidi se napredak. Sledeće nedelje malo teže.' : null,
      ),
  ]..removeWhere((p) => p.createdAt.isAfter(now));
  return Team(
    creatorId: creator.id,
    members: members,
    activeToday: (members * 0.14).round() + seed % 9,
    posts: posts,
  );
}
