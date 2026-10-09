import '../domain/models.dart';
import 'rows.dart';

/// One change to send to the backend. Upserts and deletes are idempotent,
/// so replaying a mutation after a failure is safe.
class Mutation {
  const Mutation.upsert(this.table, this.data, {this.onConflict, this.ignoreDuplicates = false})
    : delete = false,
      match = null;

  /// Deletes rows in [table] matching every column in [match].
  const Mutation.delete(this.table, Row this.match)
    : delete = true,
      data = const {},
      onConflict = null,
      ignoreDuplicates = false;

  final String table;
  final bool delete;
  final Row data;
  final Row? match;

  /// Unique columns to merge on, when not the primary key (e.g. `user_id`).
  final String? onConflict;

  /// Insert-only rows (follows, subscriptions): an existing row is kept as is.
  final bool ignoreDuplicates;

  static const _keys = {
    'profiles': ['user_id'],
    'plans': ['user_id'],
    'follows': ['user_id', 'creator_id'],
    'subscriptions': ['user_id', 'creator_id'],
  };

  /// Identifies the row(s) touched. A newer mutation with the same key
  /// replaces an older pending one.
  String get key {
    final source = delete ? match! : data;
    final columns = [
      ...(delete ? source.keys : (_keys[table] ?? const ['id'])),
    ]..sort();
    return '$table:${columns.map((c) => '$c=${source[c]}').join('&')}';
  }

  Map<String, Object?> toJson() => {
    'table': table,
    'delete': delete,
    'data': data,
    'match': match,
    'onConflict': onConflict,
    'ignoreDuplicates': ignoreDuplicates,
  };

  factory Mutation.fromJson(Map<String, Object?> j) {
    final table = j['table'] as String;
    return j['delete'] == true
        ? Mutation.delete(table, (j['match'] as Map).cast())
        : Mutation.upsert(
            table,
            (j['data'] as Map).cast(),
            onConflict: j['onConflict'] as String?,
            ignoreDuplicates: j['ignoreDuplicates'] == true,
          );
  }
}

/// Pending mutations, oldest first. Coalescing keeps a replaced mutation's
/// position so rows are still created before the rows that reference them.
class Outbox {
  Outbox([List<Mutation>? pending]) : _pending = [...?pending];

  final List<Mutation> _pending;

  List<Mutation> get pending => List.unmodifiable(_pending);
  bool get isEmpty => _pending.isEmpty;
  bool get isNotEmpty => _pending.isNotEmpty;
  int get length => _pending.length;
  Mutation get first => _pending.first;

  void add(Mutation m) {
    final i = _pending.indexWhere((p) => p.key == m.key);
    if (i < 0) {
      _pending.add(m);
    } else {
      _pending[i] = m;
    }
  }

  /// Removes [m] once applied, unless a newer version replaced it meanwhile.
  void remove(Mutation m) => _pending.remove(m);

  void clear() => _pending.clear();

  void addAll(Iterable<Mutation> mutations) => mutations.forEach(add);

  List<Map<String, Object?>> toJson() => [for (final m in _pending) m.toJson()];

  factory Outbox.fromJson(List<Object?>? list) =>
      Outbox([for (final m in list ?? const []) Mutation.fromJson((m as Map).cast())]);
}

/// A failed remote call. Retryable errors (no connection, timeouts) keep the
/// mutation queued; others (a rejected row) drop it and tell the user.
class RemoteError implements Exception {
  const RemoteError(this.message, {required this.retryable});

  /// User-facing, in Serbian.
  final String message;
  final bool retryable;

  @override
  String toString() => 'RemoteError($message, retryable: $retryable)';
}

typedef Catalog = ({
  List<Creator> creators,
  List<Exercise> exercises,
  List<Workout> workouts,
  List<Program> programs,
});

typedef UserData = ({
  UserProfile? profile,
  Set<String> follows,
  Set<String> subscriptions,
  UserPlan? plan,
  List<Session> sessions,
  Session? active,
});

/// The backend as the store sees it. Implemented by SupabaseRemote.
abstract interface class Remote {
  String get userId;

  /// Everything the current user may see (RLS decides).
  Future<Catalog> fetchCatalog();
  Future<UserData> fetchUser();
  Future<void> apply(Mutation m);
  Future<bool> isHandleAvailable(String handle);

  /// Stores a creator's file (a video of an exercise, a highlight photo) under the user's own
  /// folder and returns the public link to it.
  Future<String> uploadMedia(String path, {required String extension, required String contentType});
}
