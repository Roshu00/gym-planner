/// A creator's team: everyone who follows or subscribes to them. Members
/// show a finished workout to the team, cheer each other ("Bravo"), and the
/// creator replies and writes a word for the day.
library;

class TeamPost {
  const TeamPost({
    required this.id,
    required this.creatorId,
    required this.userId,
    required this.authorName,
    required this.workoutName,
    required this.createdAt,
    this.records = const [],
    this.streakWeeks = 0,
    this.cheers = 0,
    this.cheeredByMe = false,
    this.reply,
  });

  final String id;
  final String creatorId;
  final String userId;
  final String authorName;
  final String workoutName;
  final DateTime createdAt;

  /// Records set in that workout, as short labels: "Hip thrust 45 kg".
  final List<String> records;
  final int streakWeeks;
  final int cheers;
  final bool cheeredByMe;

  /// The creator's answer, if any.
  final String? reply;

  TeamPost copyWith({int? cheers, bool? cheeredByMe, String? reply}) => TeamPost(
    id: id,
    creatorId: creatorId,
    userId: userId,
    authorName: authorName,
    workoutName: workoutName,
    createdAt: createdAt,
    records: records,
    streakWeeks: streakWeeks,
    cheers: cheers ?? this.cheers,
    cheeredByMe: cheeredByMe ?? this.cheeredByMe,
    reply: reply ?? this.reply,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'creatorId': creatorId,
    'userId': userId,
    'authorName': authorName,
    'workoutName': workoutName,
    'createdAt': createdAt.toIso8601String(),
    'records': records,
    'streakWeeks': streakWeeks,
    'cheers': cheers,
    'cheeredByMe': cheeredByMe,
    'reply': reply,
  };

  factory TeamPost.fromJson(Map<String, Object?> j) => TeamPost(
    id: j['id'] as String,
    creatorId: j['creatorId'] as String,
    userId: j['userId'] as String? ?? '',
    authorName: j['authorName'] as String? ?? '',
    workoutName: j['workoutName'] as String? ?? '',
    createdAt: DateTime.parse(j['createdAt'] as String),
    records: [for (final r in (j['records'] as List?) ?? const []) r as String],
    streakWeeks: j['streakWeeks'] as int? ?? 0,
    cheers: j['cheers'] as int? ?? 0,
    cheeredByMe: j['cheeredByMe'] as bool? ?? false,
    reply: j['reply'] as String?,
  );
}

/// The creator's word for the day, shown on Danas as a message.
class TrainerNote {
  const TrainerNote({required this.id, required this.creatorId, required this.text, required this.createdAt});

  final String id;
  final String creatorId;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'creatorId': creatorId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TrainerNote.fromJson(Map<String, Object?> j) => TrainerNote(
    id: j['id'] as String,
    creatorId: j['creatorId'] as String,
    text: j['text'] as String? ?? '',
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

/// What the app knows about one team right now.
class Team {
  const Team({
    required this.creatorId,
    this.members = 0,
    this.activeToday = 0,
    this.posts = const [],
    this.notes = const [],
  });

  final String creatorId;
  final int members;
  final int activeToday;

  /// Newest first.
  final List<TeamPost> posts;

  /// Newest first.
  final List<TrainerNote> notes;

  Team copyWith({int? members, int? activeToday, List<TeamPost>? posts, List<TrainerNote>? notes}) => Team(
    creatorId: creatorId,
    members: members ?? this.members,
    activeToday: activeToday ?? this.activeToday,
    posts: posts ?? this.posts,
    notes: notes ?? this.notes,
  );

  Map<String, Object?> toJson() => {
    'creatorId': creatorId,
    'members': members,
    'activeToday': activeToday,
    'posts': [for (final p in posts) p.toJson()],
    'notes': [for (final n in notes) n.toJson()],
  };

  factory Team.fromJson(Map<String, Object?> j) => Team(
    creatorId: j['creatorId'] as String,
    members: j['members'] as int? ?? 0,
    activeToday: j['activeToday'] as int? ?? 0,
    posts: [for (final p in (j['posts'] as List?) ?? const []) TeamPost.fromJson((p as Map).cast())],
    notes: [for (final n in (j['notes'] as List?) ?? const []) TrainerNote.fromJson((n as Map).cast())],
  );
}
