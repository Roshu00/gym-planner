import 'package:chalkline/app/app.dart';
import 'package:chalkline/app/common.dart';
import 'package:chalkline/app/creator_editors.dart';
import 'package:chalkline/app/creator_mode.dart';
import 'package:chalkline/app/creator_profile.dart';
import 'package:chalkline/app/discover.dart';
import 'package:chalkline/app/exercise_detail.dart';
import 'package:chalkline/app/onboarding.dart';
import 'package:chalkline/app/plan_finder.dart';
import 'package:chalkline/app/plan_screen.dart';
import 'package:chalkline/app/plan_tab.dart';
import 'package:chalkline/app/profile.dart';
import 'package:chalkline/app/program_detail.dart';
import 'package:chalkline/app/library.dart';
import 'package:chalkline/app/summary_screen.dart';
import 'package:chalkline/app/today.dart';
import 'package:chalkline/app/workout_detail.dart';
import 'package:chalkline/app/workout_session.dart';
import 'package:chalkline/data/app_store.dart';
import 'package:chalkline/data/seed.dart';
import 'package:chalkline/data/storage.dart';
import 'package:chalkline/domain/models.dart';
import 'package:chalkline/ui/chalkline_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const profile = UserProfile(
  name: 'Ana',
  goal: Goal.strength,
  experience: Experience.beginner,
  place: Place.home,
  daysPerWeek: 3,
  equipment: {Equipment.dumbbell, Equipment.band},
);

var _clock = DateTime(2026, 9, 30, 18);

/// A user two weeks in: plan with swaps, finished sessions with a record,
/// a subscription and a creator profile of their own.
Future<AppStore> seasonedStore() async {
  _clock = DateTime(2026, 9, 16, 18);
  final store = AppStore(storage: MemoryStore(), clock: () => _clock);
  await store.load();
  store.completeOnboarding(profile);
  store.subscribe('c_marko');
  store.startProgram('p_m_strength');
  for (var day = 0; day < 4; day++) {
    store.startSession();
    for (var e = 0; e < store.active!.exercises.length; e++) {
      for (var s = 0; s < store.active!.exercises[e].sets.length; s++) {
        store.updateSet(e, s, SetLog(kg: 20.0 + day * 2.5, reps: 10));
        store.toggleSet(e, s);
      }
    }
    store.finishSession();
    _clock = _clock.add(const Duration(days: 3));
  }
  final me = store.saveMyCreator(name: 'Ana Trener', handle: 'ana.trener', tagline: 'Kod kuće');
  store.saveExercise(
    Exercise(
      id: 'e1',
      creatorId: me.id,
      name: 'Sklek',
      muscle: Muscle.chest,
      equipment: const {Equipment.bodyweight},
    ),
  );
  store.saveWorkout(
    Workout(
      id: 'w1',
      creatorId: me.id,
      name: 'Jutro',
      exercises: const [WorkoutExercise(exerciseId: 'e1')],
    ),
  );
  store.saveProgram(Program(id: 'p1', creatorId: me.id, name: 'Moj program', workoutIds: const ['w1']));
  return store;
}

Future<AppStore> freshStore() async {
  final store = AppStore(storage: MemoryStore(), clock: () => _clock);
  await store.load();
  store.completeOnboarding(profile);
  return store;
}

Future<void> pump(WidgetTester tester, AppStore store, Widget screen, ClTheme theme) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppScope(
      store: store,
      child: MaterialApp(
        home: ClThemeScope(theme: theme, child: screen),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

/// Scrolls until [text] is on screen, then taps it.
Future<void> tapVisible(WidgetTester tester, String text) async {
  final target = find.text(text).hitTestable();
  for (var i = 0; i < 20 && target.evaluate().isEmpty; i++) {
    await tester.drag(
      find.byType(Scrollable).hitTestable().first,
      const Offset(0, -200),
      warnIfMissed: false,
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.tap(target.first);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Brings the control with this accessible [label] into view and taps it.
Future<void> tapLabel(WidgetTester tester, String label) async {
  final target = find.bySemanticsLabel(label).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Taps a row in a sheet; its label also carries the row's description.
Future<void> tapOption(WidgetTester tester, String title) async {
  final target = find.bySemanticsLabel(RegExp('^${RegExp.escape(title)}')).last;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> scrollThrough(WidgetTester tester) async {
  final scrollables = find.byType(Scrollable);
  for (var i = 0; i < 15 && scrollables.evaluate().isNotEmpty; i++) {
    await tester.drag(scrollables.first, const Offset(0, -500), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final screens = <String, (Widget Function(AppStore), ClTheme)>{
    'today': ((_) => const TodayScreen(), ClTheme.dark),
    'plan tab': ((_) => const PlanTabScreen(), ClTheme.dark),
    'plan finder': ((_) => const PlanFinderScreen(), ClTheme.dark),
    'discover': ((_) => const DiscoverScreen(), ClTheme.dark),
    'settings': ((_) => const SettingsScreen(), ClTheme.dark),
    'library': ((_) => const LibraryScreen(), ClTheme.dark),
    'profile': ((_) => const ProfileScreen(), ClTheme.dark),
    'plan': ((_) => const PlanScreen(), ClTheme.dark),
    'plan workout': ((_) => const PlanWorkoutScreen(index: 1), ClTheme.dark),
    'summary': ((s) => SummaryScreen(sessionId: s.sessions.last.id, justFinished: true), ClTheme.light),
    'history detail': ((s) => SummaryScreen(sessionId: s.sessions.first.id), ClTheme.light),
    'creator mode': ((_) => const CreatorModeScreen(), ClTheme.light),
    'creator profile editor': ((_) => const CreatorProfileEditor(), ClTheme.light),
    'exercise editor': ((_) => const ExerciseEditor(exerciseId: 'e1'), ClTheme.light),
    'workout editor': ((_) => const WorkoutEditor(workoutId: 'w1'), ClTheme.light),
    'program editor': ((_) => const ProgramEditor(programId: 'p1'), ClTheme.light),
    'onboarding': ((_) => const OnboardingScreen(), ClTheme.dark),
    for (final c in [...SeedCatalog.creators.map((c) => c.id), 'c_me'])
      'creator $c': ((_) => CreatorProfileScreen(creatorId: c), ClTheme.light),
    for (final p in SeedCatalog.programs)
      'program ${p.id}': ((_) => ProgramDetailScreen(programId: p.id), ClTheme.dark),
    for (final w in SeedCatalog.workouts)
      'workout ${w.id}': ((_) => WorkoutDetailScreen(workoutId: w.id), ClTheme.dark),
    for (final e in ['m_bench', 'j_band_abduction', 'n_pullup'])
      'exercise $e': ((_) => ExerciseDetailScreen(exerciseId: e), ClTheme.dark),
  };

  for (final MapEntry(key: name, value: (build, theme)) in screens.entries) {
    testWidgets('$name renders without overflow', (tester) async {
      final store = await seasonedStore();
      await pump(tester, store, build(store), theme);
      await scrollThrough(tester);
      expect(tester.takeException(), isNull);
    });
  }

  for (final (name, screen) in [
    ('today', const TodayScreen()),
    ('plan tab', const PlanTabScreen()),
    ('discover', const DiscoverScreen()),
    ('profile', const ProfileScreen()),
    ('library', const LibraryScreen()),
    ('plan', const PlanScreen()),
    ('creator mode', const CreatorModeScreen()),
  ]) {
    testWidgets('$name empty state renders', (tester) async {
      await pump(tester, await freshStore(), screen, ClTheme.dark);
      await scrollThrough(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Today greets a new user differently from one between plans', (tester) async {
    final store = await freshStore();
    await pump(tester, store, const TodayScreen(), ClTheme.light);
    expect(find.text('Tvoj plan je spreman.'), findsOneWidget);
    expect(find.text('Najbolje se uklapa'), findsOneWidget);
    expect(find.text('Nova nedelja.'), findsNothing);

    final seasoned = await seasonedStore();
    seasoned.leavePlan();
    await pump(tester, seasoned, const TodayScreen(), ClTheme.light);
    expect(find.text('Nova nedelja.'), findsOneWidget);
    expect(find.textContaining('Do sada 4 treninga'), findsOneWidget);
    expect(find.text('Tvoj plan je spreman.'), findsNothing);
  });

  testWidgets('Discover marks followed and subscribed creators and lists them first', (tester) async {
    final store = await freshStore();
    store.toggleFollow('c_nikola');
    store.subscribe('c_marko');
    await pump(tester, store, const DiscoverScreen(), ClTheme.light);
    // A small mark next to the name, announced to screen readers.
    expect(find.bySemanticsLabel(RegExp(r'^Nikola Jovanović, pratiš')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Marko Petrović, pretplaćen si')), findsOneWidget);
    double y(String name) => tester.getTopLeft(find.text(name).first).dy;
    expect(y('Nikola Jovanović'), lessThan(y('Jelena Ilić')), reason: 'followed before more popular');
    expect(y('Marko Petrović'), lessThan(y('Jelena Ilić')));
  });

  testWidgets('Discover searches creators and programs by name, without accents', (tester) async {
    await pump(tester, await freshStore(), const DiscoverScreen(), ClTheme.light);
    await tester.enterText(find.byType(TextField), 'jovanovic');
    await tester.pump();
    expect(find.text('Nikola Jovanović'), findsWidgets);
    expect(find.text('Jelena Ilić'), findsNothing);
    expect(find.text('Marko Petrović'), findsNothing);
  });

  testWidgets('settings menus open their sheets, gender can be changed', (tester) async {
    final store = await seasonedStore();
    await pump(tester, store, const SettingsScreen(), ClTheme.light);
    for (final row in ['Oprema', 'Pretplate', 'Podaci']) {
      await tester.tap(find.text(row).hitTestable());
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Zatvori'), findsOneWidget, reason: '$row opens a sheet');
      await tester.tap(find.bySemanticsLabel('Zatvori'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Pol').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Žensko').hitTestable());
    await tester.pumpAndSettle();
    expect(store.profile!.gender, Gender.female);
    expect(find.text('Žensko'), findsOneWidget, reason: 'the menu row shows the new value');
    expect(tester.takeException(), isNull);
  });

  testWidgets('workout session renders mid-workout with rest timer', (tester) async {
    final store = await seasonedStore();
    store.startSession();
    await pump(tester, store, const WorkoutSessionScreen(), ClTheme.dark);
    await tester.tap(find.bySemanticsLabel('Završi set 1'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Odmor'), findsOneWidget);
    expect(store.active!.exercises.first.sets.first.done, isTrue);
    await scrollThrough(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('from onboarding to a finished workout', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = AppStore(storage: MemoryStore(), clock: () => _clock);
    await store.load();
    await tester.pumpWidget(ChalklineApp(store: store, initialCreatorHandle: 'jelena.moves'));
    await tester.pump();

    // Only what is on screen: hidden tabs keep their own copies of texts.
    Future<void> tapText(String text) async {
      final target = find.text(text).hitTestable();
      for (var i = 0; i < 20 && target.evaluate().isEmpty; i++) {
        await tester.drag(
          find.byType(Scrollable).hitTestable().first,
          const Offset(0, -300),
          warnIfMissed: false,
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(target.last);
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    }

    expect(find.text('Kako se zoveš?'), findsOneWidget);
    expect(find.text('Jelena Ilić'), findsOneWidget, reason: 'invited by the creator link');
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pump();
    await tapText('Dalje');
    // Answers move on by themselves; gender and equipment are not asked.
    for (final answer in ['Opšta forma', 'Tek počinjem', 'Kod kuće', '3 dana']) {
      await tapText(answer);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }
    expect(store.profile!.gender, Gender.unspecified);
    expect(store.profile!.daysPerWeek, 3);
    expect(store.profile!.equipment, Equipment.home);

    // The creator link opens the creator's profile.
    expect(find.text('Jelena Ilić'), findsWidgets);
    expect(find.textContaining('@jelena.moves'), findsOneWidget, reason: 'the creator profile is open');
    await tapText('Kuća 30');
    await tapText('Počni program');
    expect(store.plan!.programId, 'p_j_home');
    expect(find.text('Donji deo'), findsOneWidget);

    // Today: one button on the trainer's photo.
    await tester.tap(find.bySemanticsLabel('Počni'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Gobl čučanj'), findsWidgets);
    await tester.enterText(find.byType(TextField).first, '12');
    await tapText('Završi set');
    await tapText('Završi set');
    expect(store.active!.exercises.first.sets[1].kg, 12, reason: 'weight carries over');
    await tapText('Završi set');
    await tapText('Sledeća vežba');
    await tapText('Završi trening');
    await tapText('Završi trening');
    expect(find.text('Odrađeno.'), findsOneWidget, reason: 'neutral praise without gender');
    await tapText('Gotovo');
    expect(find.text('Gornji deo'), findsOneWidget, reason: 'the plan moved to the next workout');
    expect(store.thisWeek, 1);
  });

  test('creator link parsing', () {
    expect(creatorHandleFromUri(Uri.parse('https://chalkline.app/c/marko.lifts')), 'marko.lifts');
    expect(creatorHandleFromUri(Uri.parse('https://x.app/#/c/jelena.moves')), 'jelena.moves');
    expect(creatorHandleFromUri(Uri.parse('https://x.app/')), isNull);
  });

  /// Opens today's card on the Plan tab (its label ends with "danas").
  Future<void> openToday(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(RegExp(r', danas$')));
    await tester.pumpAndSettle();
  }

  testWidgets('Plan tab: change a day from its card and undo it', (tester) async {
    final store = await seasonedStore();
    _clock = DateTime(2026, 9, 30, 18); // Wednesday, a training day
    store.setTrainingDays({1, 3, 5});
    final wed = DateTime(2026, 9, 30);
    final thu = DateTime(2026, 10, 1);
    await pump(tester, store, const PlanTabScreen(), ClTheme.light);
    expect(store.plannedOn(wed), isNotNull);

    // Every change goes through one sheet, "Promeni dan", from the day's card.
    await openToday(tester);
    await tapLabel(tester, 'Promeni današnji dan');
    await tapOption(tester, 'Dan odmora');
    expect(store.dayPlan(wed)!.train, isFalse);
    expect(find.textContaining('Odmor danas'), findsOneWidget);
    await tapLabel(tester, 'Poništi');
    expect(store.dayPlan(wed), isNull);

    await openToday(tester);
    await tapLabel(tester, 'Promeni današnji dan');
    await tapOption(tester, 'Danas ne mogu');
    expect(store.plannedOn(thu), isNotNull, reason: 'Thursday was the next rest day');
    expect(find.textContaining('je sada sutra'), findsOneWidget);
    await tapLabel(tester, 'Poništi');
    expect(store.plannedOn(thu), isNull);

    await openToday(tester);
    await tapLabel(tester, 'Promeni današnji dan');
    await tapOption(tester, 'Kraća verzija');
    expect(store.dayPlan(wed)!.note, 'Kraća verzija');

    await openToday(tester);
    await tapLabel(tester, 'Vrati na plan');
    expect(store.dayPlan(wed), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Plan tab: hold a workout and drag it to a free day', (tester) async {
    final store = await seasonedStore();
    _clock = DateTime(2026, 9, 30, 18);
    store.setTrainingDays({1, 3, 5});
    final wed = DateTime(2026, 9, 30);
    final thu = DateTime(2026, 10, 1);
    final name = store.plannedOn(wed)!.workout.name;
    await pump(tester, store, const PlanTabScreen(), ClTheme.light);

    final gesture = await tester.startGesture(tester.getCenter(find.bySemanticsLabel(RegExp(r', danas$'))));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('Slobodan dan').first));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(store.plannedOn(thu)!.workout.name, name);
    expect(store.plannedOn(wed), isNull);
    expect(find.textContaining('je sada sutra'), findsOneWidget);
    await tapLabel(tester, 'Poništi');
    expect(store.plannedOn(wed)!.workout.name, name);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Plan tab: edit a day\'s exercises in a sheet', (tester) async {
    final store = await seasonedStore();
    _clock = DateTime(2026, 9, 30, 18);
    store.setTrainingDays({1, 3, 5});
    final wed = DateTime(2026, 9, 30);
    final before = store.plannedOn(wed)!.exercises.length;
    await pump(tester, store, const PlanTabScreen(), ClTheme.light);
    await openToday(tester);
    await tapLabel(tester, 'Promeni današnji dan');
    await tapOption(tester, 'Izmeni vežbe');
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Ukloni ')).first);
    await tester.pump();
    await tapLabel(tester, 'Sačuvaj za ovaj dan');
    expect(store.plannedOn(wed)!.exercises.length, before - 1);
    expect(store.dayPlan(wed)!.note, 'Prilagođeno');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Plan tab: the week, other weeks and training days', (tester) async {
    final store = await seasonedStore();
    _clock = DateTime(2026, 9, 30, 18); // Wednesday
    store.setTrainingDays({1, 3, 5});
    final thu = DateTime(2026, 10, 1);
    await pump(tester, store, const PlanTabScreen(), ClTheme.dark);
    expect(find.text('Ova nedelja'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r', danas$')), findsOneWidget);
    expect(store.plannedOn(thu), isNull, reason: 'Thursday is a rest day');

    await tester.tap(find.bySemanticsLabel('Sledeća nedelja'));
    await tester.pump();
    expect(find.text('Kasnije'), findsOneWidget);
    expect(find.textContaining('5.–11. okt'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Prethodna nedelja'));
    await tester.pump();

    // Making Thursday a training day plans a workout on it.
    await tapVisible(tester, 'Dani treninga');
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Četvrtak');
    await tester.pump();
    expect(store.plan!.trainingDays, {1, 3, 4, 5});
    expect(store.plannedOn(thu), isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Plan tab without a plan offers the plan finder', (tester) async {
    final store = await freshStore();
    await pump(tester, store, const PlanTabScreen(), ClTheme.dark);
    await tapVisible(tester, 'Pronađi plan');
    await tester.pumpAndSettle();
    // No form: the answers from onboarding are shown with the best program.
    expect(find.textContaining('Biramo prema'), findsOneWidget);
    expect(find.text('Najbolje se uklapa'), findsOneWidget);
    expect(find.text('Počni ovaj plan'), findsOneWidget);

    // "Promeni" edits the answers and the recommendation follows.
    await tester.tap(find.text('Promeni'));
    await tester.pumpAndSettle();
    await tapVisible(tester, 'Teretana');
    await tester.pumpAndSettle();
    expect(store.profile!.place, Place.gym);
    expect(store.profile!.equipment, Equipment.gym, reason: 'equipment follows the place');
    expect(tester.takeException(), isNull);
  });
}
