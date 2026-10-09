import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'auth.dart';
import 'rows.dart';
import 'sync.dart';

/// Supabase project settings, passed at build time:
/// `flutter run --dart-define-from-file=supabase.json`
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');

  /// The project's publishable key (`sb_publishable_…`). Safe in the app:
  /// Row Level Security decides what each user may read and write.
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  /// Without settings the app runs in local demo mode.
  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}

RemoteError _remoteError(Object e) {
  if (e is PostgrestException) {
    final code = e.code ?? '';
    // Constraint and permission errors will not succeed on retry.
    if (code == '23505') {
      return const RemoteError('Već postoji. Promeni naziv ili korisničko ime.', retryable: false);
    }
    if (code.startsWith('23') || code.startsWith('22')) {
      return const RemoteError('Server je odbio izmenu. Proveri podatke.', retryable: false);
    }
    if (code == '42501' || code.startsWith('PGRST')) {
      return const RemoteError('Nemaš dozvolu za ovu izmenu.', retryable: false);
    }
  }
  return const RemoteError('Nije sačuvano na serveru. Proveri internet.', retryable: true);
}

/// Storage bucket for creators' videos (see the media migration).
const mediaBucket = 'exercise-media';

class SupabaseRemote implements Remote {
  SupabaseRemote(this._client, this.userId);

  @override
  Future<String> uploadMedia(String path, {required String extension, required String contentType}) async {
    // Each user writes only into their own folder (storage policy).
    final name = '$userId/${DateTime.now().microsecondsSinceEpoch}.$extension';
    try {
      await _client.storage
          .from(mediaBucket)
          .upload(name, File(path), fileOptions: FileOptions(contentType: contentType))
          .timeout(const Duration(minutes: 3));
      return _client.storage.from(mediaBucket).getPublicUrl(name);
    } on Object {
      throw const RemoteError('Video nije poslat. Proveri internet i pokušaj ponovo.', retryable: true);
    }
  }

  final SupabaseClient _client;

  @override
  final String userId;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(const Duration(seconds: 20));
    } on Object catch (e) {
      throw _remoteError(e);
    }
  }

  @override
  Future<Catalog> fetchCatalog() => _guard(() async {
    final results = await Future.wait([
      _client.from('creators').select(),
      _client.from('exercises').select(),
      _client.from('workouts').select(),
      _client.from('programs').select(),
    ]);
    return (
      creators: [for (final r in results[0]) creatorFromRow(r, currentUserId: userId)],
      exercises: [for (final r in results[1]) exerciseFromRow(r)],
      workouts: [for (final r in results[2]) workoutFromRow(r)],
      programs: [for (final r in results[3]) programFromRow(r)],
    );
  });

  @override
  Future<UserData> fetchUser() => _guard(() async {
    final results = await Future.wait<Object?>([
      _client.from('profiles').select().eq('user_id', userId).maybeSingle(),
      _client.from('follows').select('creator_id').eq('user_id', userId),
      _client.from('subscriptions').select('creator_id').eq('user_id', userId),
      _client.from('plans').select().eq('user_id', userId).maybeSingle(),
      _client.from('sessions').select().eq('user_id', userId).order('started_at'),
    ]);
    final sessions = [for (final r in results[4] as List) sessionFromRow((r as Map).cast())];
    Set<String> ids(Object? rows) => {for (final r in rows as List) (r as Map)['creator_id'] as String};
    return (
      profile: results[0] == null ? null : profileFromRow((results[0] as Map).cast()),
      follows: ids(results[1]),
      subscriptions: ids(results[2]),
      plan: results[3] == null ? null : planFromRow((results[3] as Map).cast()),
      sessions: sessions.where((s) => s.isFinished).toList(),
      active: sessions.where((s) => !s.isFinished).lastOrNull,
    );
  });

  @override
  Future<void> apply(Mutation m) => _guard(() async {
    final table = _client.from(m.table);
    if (m.delete) {
      await table.delete().match(m.match!.cast());
    } else {
      await table.upsert(m.data, onConflict: m.onConflict, ignoreDuplicates: m.ignoreDuplicates);
    }
  });

  @override
  Future<bool> isHandleAvailable(String handle) => _guard(() async {
    final row = await _client
        .from('creators')
        .select('user_id')
        .eq('handle', handle.toLowerCase())
        .maybeSingle();
    return row == null || row['user_id'] == userId;
  });
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  static AuthUser? _user(User? u) =>
      u == null ? null : AuthUser(id: u.id, email: u.email, isGuest: u.isAnonymous);

  @override
  AuthUser? get current => _user(_client.auth.currentUser);

  @override
  Stream<AuthUser?> get changes => _client.auth.onAuthStateChange.map((s) => _user(s.session?.user));

  Future<void> _guard(Future<Object?> Function() call) async {
    try {
      await call().timeout(const Duration(seconds: 20));
    } on Object catch (e) {
      throw authFailureFor(e);
    }
  }

  @override
  Future<void> sendCode(String email) => _guard(() => _client.auth.signInWithOtp(email: email.trim()));

  @override
  Future<void> verifyCode(String email, String code) =>
      _guard(() => _client.auth.verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.email));

  @override
  Future<void> continueAsGuest() => _guard(() => _client.auth.signInAnonymously());

  @override
  Future<void> saveAccount(String email) =>
      _guard(() => _client.auth.updateUser(UserAttributes(email: email.trim())));

  @override
  Future<void> verifySavedAccount(String email, String code) => _guard(() async {
    await _client.auth.verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.emailChange);
    return _client.auth.refreshSession();
  });

  @override
  Future<void> signOut() => _guard(() => _client.auth.signOut());
}

/// Maps Supabase Auth errors to messages a user can act on. Uses the error
/// codes, not message text, and treats anything network-like as offline.
AuthFailure authFailureFor(Object e) {
  if (e is AuthFailure) return e;
  if (e is TimeoutException) return const AuthFailure('Server ne odgovara. Proveri internet.');
  if (e is AuthRetryableFetchException || e is AuthUnknownException || e is! AuthException) {
    return const AuthFailure('Nema veze sa serverom. Proveri internet i pokušaj ponovo.');
  }
  return switch (e.code) {
    'otp_expired' => const AuthFailure('Kod nije tačan ili je istekao.'),
    'over_email_send_rate_limit' ||
    'over_request_rate_limit' => const AuthFailure('Previše pokušaja. Sačekaj minut pa probaj ponovo.'),
    'anonymous_provider_disabled' => const AuthFailure('Prijava bez naloga trenutno nije dostupna.'),
    'email_exists' ||
    'user_already_exists' => const AuthFailure('Ovaj email već ima nalog. Odjavi se i prijavi se njime.'),
    'email_address_invalid' || 'validation_failed' => const AuthFailure('Proveri email adresu.'),
    _ when e.statusCode == '429' => const AuthFailure('Previše pokušaja. Sačekaj minut pa probaj ponovo.'),
    _ => const AuthFailure('Prijava nije uspela. Pokušaj ponovo.'),
  };
}
