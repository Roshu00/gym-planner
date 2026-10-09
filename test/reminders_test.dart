import 'package:chalkline/data/app_store.dart';
import 'package:chalkline/data/reminder_scheduler.dart';
import 'package:chalkline/data/storage.dart';
import 'package:chalkline/domain/models.dart';
import 'package:chalkline/domain/reminders.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeScheduler implements ReminderScheduler {
  bool allow = true;
  final calls = <List<Reminder>>[];
  List<Reminder> get last => calls.isEmpty ? const [] : calls.last;

  @override
  Future<bool> requestPermission() async => allow;

  @override
  Future<void> replaceAll(List<Reminder> reminders) async => calls.add(reminders);
}

const gym = UserProfile(
  name: 'Ana',
  goal: Goal.strength,
  experience: Experience.beginner,
  place: Place.gym,
  daysPerWeek: 3,
  equipment: Equipment.gym,
);

void main() {
  // Wednesday 30. 9. 2026, 7:00. p_m_start trains Mon, Wed, Fri.
  var clock = DateTime(2026, 9, 30, 7);
  late FakeScheduler phone;
  late AppStore store;

  setUp(() async {
    clock = DateTime(2026, 9, 30, 7);
    phone = FakeScheduler();
    store = AppStore(storage: MemoryStore(), clock: () => clock, reminders: phone);
    await store.load();
    store.completeOnboarding(gym);
    store.startProgram('p_m_start', trainingDays: {1, 3, 5});
  });

  test('nothing is scheduled until the user turns reminders on', () {
    expect(phone.last, isEmpty);
  });

  test('on: one reminder per training day at the chosen time, named after the workout', () async {
    expect(await store.setRemindersEnabled(true), isTrue);
    final r = phone.last;
    expect(r.first.at, DateTime(2026, 9, 30, 8));
    expect(r.first.title, 'Danas: Celo telo A');
    expect(r.map((x) => x.at.weekday).toSet(), {DateTime.monday, DateTime.wednesday, DateTime.friday});
    expect(r.every((x) => x.at.hour == 8), isTrue);

    store.setReminderTime(19, 0);
    expect(phone.last.first.at, DateTime(2026, 9, 30, 19));
  });

  test('a moved workout moves its reminder', () async {
    await store.setRemindersEnabled(true);
    store.moveTraining(DateTime(2026, 9, 30), DateTime(2026, 10, 1));
    final days = phone.last.map((x) => DateTime(x.at.year, x.at.month, x.at.day));
    expect(days, contains(DateTime(2026, 10, 1)));
    expect(days, isNot(contains(DateTime(2026, 9, 30))));
  });

  test('no reminder for a time already past today', () async {
    clock = DateTime(2026, 9, 30, 9); // after 8:00
    await store.setRemindersEnabled(true);
    expect(phone.last.first.at.day, isNot(30));
  });

  test('if the phone says no, reminders stay off and the offer is not repeated', () async {
    phone.allow = false;
    expect(await store.setRemindersEnabled(true), isFalse);
    expect(store.reminderSettings.enabled, isFalse);
    expect(store.reminderSettings.asked, isTrue);
  });

  test('off cancels everything', () async {
    await store.setRemindersEnabled(true);
    await store.setRemindersEnabled(false);
    expect(phone.last, isEmpty);
  });

  test('settings survive a restart', () async {
    final storage = MemoryStore();
    final a = AppStore(storage: storage, clock: () => clock, reminders: phone);
    await a.load();
    a.completeOnboarding(gym);
    await a.setRemindersEnabled(true);
    a.setReminderTime(17, 0);
    await Future<void>.delayed(Duration.zero);
    final b = AppStore(storage: storage, clock: () => clock, reminders: phone);
    await b.load();
    expect(b.reminderSettings.enabled, isTrue);
    expect(b.reminderSettings.timeLabel, '17:00');
  });
}
