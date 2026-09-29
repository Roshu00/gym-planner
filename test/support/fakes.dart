import 'dart:async';
import 'dart:convert';

import 'package:chalkline/data/auth.dart';
import 'package:chalkline/data/rows.dart';
import 'package:chalkline/data/seed.dart';
import 'package:chalkline/data/sync.dart';

const uid = '00000000-0000-0000-0000-00000000000b';

/// In-memory stand-in for Supabase: tables of rows, the same access rules for
/// subscriber content, and switchable failures.
class FakeRemote implements Remote {
  FakeRemote({this.userId = uid});

  @override
  final String userId;

  final tables = <String, List<Row>>{
    'creators': [for (final c in SeedCatalog.creators) creatorRow(c)],
    'exercises': [for (final e in SeedCatalog.exercises) exerciseRow(e)],
    'workouts': [for (final w in SeedCatalog.workouts) workoutRow(w)],
    'programs': [for (final p in SeedCatalog.programs) programRow(p)],
    'profiles': [],
    'follows': [],
    'subscriptions': [],
    'plans': [],
    'sessions': [],
  };

  bool offline = false;

  /// Tables whose writes the server rejects (like an RLS violation).
  final rejected = <String>{};
  final applied = <Mutation>[];

  void _check() {
    if (offline) throw const RemoteError('Nije sačuvano na serveru. Proveri internet.', retryable: true);
  }

  // Mirrors the policies in supabase/migrations: subscriber content needs a
  // subscription or ownership.
  bool _visible(Row r) {
    if (r['audience'] != 'subscribers') return true;
    final creator = r['creator_id'];
    final subscribed = tables['subscriptions']!.any(
      (s) => s['user_id'] == userId && s['creator_id'] == creator,
    );
    final owns = tables['creators']!.any((c) => c['id'] == creator && c['user_id'] == userId);
    return subscribed || owns;
  }

  List<Row> _mine(String table) => tables[table]!.where((r) => r['user_id'] == userId).toList();

  Row _roundTrip(Row r) => (jsonDecode(jsonEncode(r)) as Map).cast();

  @override
  Future<Catalog> fetchCatalog() async {
    _check();
    return (
      creators: [for (final r in tables['creators']!) creatorFromRow(_roundTrip(r), currentUserId: userId)],
      exercises: [for (final r in tables['exercises']!.where(_visible)) exerciseFromRow(_roundTrip(r))],
      workouts: [for (final r in tables['workouts']!.where(_visible)) workoutFromRow(_roundTrip(r))],
      programs: [for (final r in tables['programs']!) programFromRow(_roundTrip(r))],
    );
  }

  @override
  Future<UserData> fetchUser() async {
    _check();
    final sessions = [for (final r in _mine('sessions')) sessionFromRow(_roundTrip(r))];
    return (
      profile: _mine('profiles').map((r) => profileFromRow(_roundTrip(r))).firstOrNull,
      follows: {for (final r in _mine('follows')) r['creator_id'] as String},
      subscriptions: {for (final r in _mine('subscriptions')) r['creator_id'] as String},
      plan: _mine('plans').map((r) => planFromRow(_roundTrip(r))).firstOrNull,
      sessions: sessions.where((s) => s.isFinished).toList(),
      active: sessions.where((s) => !s.isFinished).firstOrNull,
    );
  }

  @override
  Future<void> apply(Mutation m) async {
    _check();
    if (rejected.contains(m.table)) {
      throw const RemoteError('Nemaš dozvolu za ovu izmenu.', retryable: false);
    }
    final rows = tables[m.table]!;
    if (m.delete) {
      rows.removeWhere((r) => m.match!.entries.every((e) => r[e.key] == e.value));
    } else {
      final keys =
          (m.onConflict ??
                  (m.table == 'profiles'
                      ? 'user_id'
                      : m.table == 'follows' || m.table == 'subscriptions'
                      ? 'user_id,creator_id'
                      : 'id'))
              .split(',');
      final i = rows.indexWhere((r) => keys.every((k) => r[k] == m.data[k]));
      final row = _roundTrip(m.data);
      if (i < 0) {
        rows.add(row);
      } else if (!m.ignoreDuplicates) {
        rows[i] = {...rows[i], ...row};
      }
    }
    applied.add(m);
  }

  @override
  Future<bool> isHandleAvailable(String handle) async {
    _check();
    return !tables['creators']!.any((c) => c['handle'] == handle.toLowerCase() && c['user_id'] != userId);
  }
}

/// Auth without a server: code "123456" is right, anything else is wrong.
class FakeAuth implements AuthService {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;
  final sentTo = <String>[];

  @override
  AuthUser? get current => _current;

  @override
  Stream<AuthUser?> get changes => _controller.stream;

  void _set(AuthUser? u) {
    _current = u;
    _controller.add(u);
  }

  @override
  Future<void> sendCode(String email) async => sentTo.add(email);

  @override
  Future<void> verifyCode(String email, String code) async {
    if (code != '123456') throw const AuthFailure('Kod nije tačan ili je istekao.');
    _set(AuthUser(id: uid, email: email));
  }

  @override
  Future<void> continueAsGuest() async => _set(const AuthUser(id: uid, isGuest: true));

  @override
  Future<void> saveAccount(String email) async => sentTo.add(email);

  @override
  Future<void> verifySavedAccount(String email, String code) async {
    if (code != '123456') throw const AuthFailure('Kod nije tačan ili je istekao.');
    _set(AuthUser(id: _current!.id, email: email));
  }

  @override
  Future<void> signOut() async => _set(null);
}
