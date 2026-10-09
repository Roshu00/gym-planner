/// Training-day reminders: what to say and when. Pure, so it can be tested
/// without a phone; lib/data/reminder_scheduler.dart hands them to the OS.
library;

/// The user's choice. Kept on this device only.
class ReminderSettings {
  const ReminderSettings({this.enabled = false, this.hour = 8, this.minute = 0, this.asked = false});

  final bool enabled;
  final int hour;
  final int minute;

  /// The user has already answered the offer on Today (yes or no).
  final bool asked;

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute, bool? asked}) => ReminderSettings(
    enabled: enabled ?? this.enabled,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    asked: asked ?? this.asked,
  );

  String get timeLabel => '$hour:${minute.toString().padLeft(2, '0')}';

  Map<String, Object?> toJson() => {'enabled': enabled, 'hour': hour, 'minute': minute, 'asked': asked};

  factory ReminderSettings.fromJson(Map<String, Object?> j) => ReminderSettings(
    enabled: j['enabled'] as bool? ?? false,
    hour: j['hour'] as int? ?? 8,
    minute: j['minute'] as int? ?? 0,
    asked: j['asked'] as bool? ?? false,
  );
}

/// One notification on one day.
class Reminder {
  const Reminder({required this.id, required this.at, required this.title, required this.body});

  /// Stable per day (yyyymmdd), so rescheduling replaces rather than doubles.
  final int id;
  final DateTime at;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is Reminder && other.id == id && other.at == at && other.title == title && other.body == body;

  @override
  int get hashCode => Object.hash(id, at, title, body);

  @override
  String toString() => 'Reminder($at, $title)';
}

/// What a planned day looks like for a reminder.
typedef PlannedDay = ({DateTime day, String workout, String creator, int minutes, String intro});

/// Reminders for the planned training days, at the chosen time, from now on.
/// Today's is left out once its time has passed or the workout is done.
List<Reminder> remindersFor(
  List<PlannedDay> days,
  ReminderSettings settings,
  DateTime now, {
  bool doneToday = false,
}) {
  if (!settings.enabled) return const [];
  final today = DateTime(now.year, now.month, now.day);
  return [
    for (final d in days)
      if (DateTime(d.day.year, d.day.month, d.day.day, settings.hour, settings.minute) case final at
          when at.isAfter(now) && !(doneToday && d.day == today))
        Reminder(
          id: d.day.year * 10000 + d.day.month * 100 + d.day.day,
          at: at,
          title: 'Danas: ${d.workout}',
          body: d.intro.isNotEmpty
              ? '${d.creator}: „${d.intro}”'
              : 'Sa trenerom ${d.creator} · ~${d.minutes} min',
        ),
  ];
}
