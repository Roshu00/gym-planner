import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminders.dart';

/// Hands reminders to the phone. Swapped for a fake in tests.
abstract interface class ReminderScheduler {
  /// Asks for permission to notify. True when allowed.
  Future<bool> requestPermission();

  /// Cancels what was scheduled before and schedules [reminders].
  Future<void> replaceAll(List<Reminder> reminders);
}

/// Does nothing: web, tests, and platforms without notifications.
class NoReminders implements ReminderScheduler {
  const NoReminders();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> replaceAll(List<Reminder> reminders) async {}
}

/// Local notifications scheduled on the phone itself: no server needed, and
/// they arrive even when the app is closed.
class LocalReminderScheduler implements ReminderScheduler {
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _ready;

  Future<void> _init() => _ready ??= () async {
    tzdata.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object catch (e) {
      debugPrint('Time zone unknown, using UTC: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked when the user turns reminders on, not at start.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  @override
  Future<bool> requestPermission() async {
    await _init();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) return await ios.requestPermissions(alert: true, sound: true) ?? false;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    return false;
  }

  @override
  Future<void> replaceAll(List<Reminder> reminders) async {
    await _init();
    await _plugin.cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails('training', 'Podsetnici za trening', importance: Importance.high),
      iOS: DarwinNotificationDetails(),
    );
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
