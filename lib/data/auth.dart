/// Signed-in person. Guests (anonymous sign-in) can train; publishing as a
/// creator needs an email account.
class AuthUser {
  const AuthUser({required this.id, this.email, this.isGuest = false});

  final String id;
  final String? email;
  final bool isGuest;
}

/// User-facing auth failure, in Serbian.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure($message)';
}

/// Email one-time codes: no passwords and no links that break on mobile.
abstract interface class AuthService {
  AuthUser? get current;
  Stream<AuthUser?> get changes;

  Future<void> sendCode(String email);
  Future<void> verifyCode(String email, String code);
  Future<void> continueAsGuest();

  /// Turns a guest into an email account, keeping all their data.
  Future<void> saveAccount(String email);
  Future<void> verifySavedAccount(String email, String code);

  Future<void> signOut();
}

final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidEmail(String email) => _email.hasMatch(email.trim());
