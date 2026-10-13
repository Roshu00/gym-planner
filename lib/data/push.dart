import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// What a tapped notification asks the app to open.
typedef PushTarget = ({String type, String? creatorId});

/// Push notifications from the server (the trainer answered, the team said
/// "Bravo", today's message). Swapped for a fake in tests.
abstract interface class PushService {
  /// Asks to notify and returns this phone's token, or null when not allowed.
  Future<String?> register();

  /// New tokens (Firebase rotates them now and then).
  Stream<String> get tokenChanges;

  /// Notifications the user tapped, including the one that opened the app.
  Stream<PushTarget> get opened;
}

/// Does nothing: web, tests, and builds without a Firebase config.
class NoPush implements PushService {
  const NoPush();

  @override
  Future<String?> register() async => null;

  @override
  Stream<String> get tokenChanges => const Stream.empty();

  @override
  Stream<PushTarget> get opened => const Stream.empty();
}

/// Firebase Cloud Messaging: APNs on iOS, FCM on Android. Needs
/// `GoogleService-Info.plist` (iOS) / `google-services.json` (Android) in
/// the app; see docs/PUSH.md.
class FirebasePush implements PushService {
  FirebasePush._();

  final _opened = StreamController<PushTarget>.broadcast();

  /// Firebase when its config is in the app, else [NoPush], so a build
  /// without it still runs.
  static Future<PushService> start() async {
    try {
      await Firebase.initializeApp();
    } on Object catch (e) {
      debugPrint('Push off, Firebase not configured: $e');
      return const NoPush();
    }
    final push = FirebasePush._();
    FirebaseMessaging.onMessageOpenedApp.listen((m) => push._opened.add(_target(m.data)));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      // After the app has listeners.
      Timer(const Duration(milliseconds: 600), () => push._opened.add(_target(initial.data)));
    }
    return push;
  }

  static PushTarget _target(Map<String, dynamic> data) =>
      (type: data['type'] as String? ?? '', creatorId: data['creator_id'] as String?);

  @override
  Future<String?> register() async {
    final m = FirebaseMessaging.instance;
    final settings = await m.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return null;
    }
    // Shown as a banner while the app is open too.
    await m.setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true);
    try {
      // On iOS the APNs token comes first; FCM's token waits for it.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var i = 0; i < 10 && await m.getAPNSToken() == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
      }
      return await m.getToken();
    } on Object catch (e) {
      debugPrint('No push token: $e');
      return null;
    }
  }

  @override
  Stream<String> get tokenChanges => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<PushTarget> get opened => _opened.stream;
}
