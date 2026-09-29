import 'package:chalkline/app/app.dart';
import 'package:chalkline/app/common.dart';
import 'package:chalkline/app/creator_editors.dart';
import 'package:chalkline/app/creator_mode.dart';
import 'package:chalkline/app/creator_profile.dart';
import 'package:chalkline/app/discover.dart';
import 'package:chalkline/app/exercise_detail.dart';
import 'package:chalkline/app/library.dart';
import 'package:chalkline/app/onboarding.dart';
import 'package:chalkline/app/plan_screen.dart';
import 'package:chalkline/app/profile.dart';
import 'package:chalkline/app/program_detail.dart';
import 'package:chalkline/app/progress.dart';
import 'package:chalkline/app/summary_screen.dart';
import 'package:chalkline/app/today.dart';
import 'package:chalkline/app/workout_detail.dart';
import 'package:chalkline/app/workout_session.dart';
import 'package:chalkline/data/app_store.dart';
import 'package:chalkline/data/seed.dart';
import 'package:chalkline/data/storage.dart';
import 'package:chalkline/domain/models.dart';
import 'package:chalkline/ui/chalkline_ui.dart';
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
    'library': ((_) => const LibraryScreen(), ClTheme.dark),
    'discover': ((_) => const DiscoverScreen(), ClTheme.dark),
    'progress': ((_) => const ProgressScreen(), ClTheme.light),
    'profile': ((_) => const ProfileScreen(), ClTheme.light),
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
    ('library', const LibraryScreen()),
    ('progress', const ProgressScreen()),
    ('plan', const PlanScreen()),
    ('creator mode', const CreatorModeScreen()),
  ]) {
    testWidgets('$name empty state renders', (tester) async {
      await pump(tester, await freshStore(), screen, ClTheme.dark);
      await scrollThrough(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('workout session renders mid-workout with rest timer', (tester) async {
    final store = await seasonedStore();
    store.startSession();
    await pump(tester, store, const WorkoutSessionScreen(), ClTheme.dark);
    await tester.tap(find.bySemanticsLabel('Završi set 1'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('ODMOR'), findsOneWidget);
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

    expect(find.text('KAKO SE ZOVEŠ?'), findsOneWidget);
    expect(find.text('Jelena Ilić'), findsOneWidget, reason: 'invited by the creator link');
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pump();
    await tapText('DALJE');
    await tapText('Opšta forma');
    await tapText('DALJE');
    await tapText('Početnik');
    await tapText('DALJE');
    await tapText('Kod kuće');
    await tapText('DALJE');
    await tapText('DALJE');
    await tapText('3 dana nedeljno');
    await tapText('POČNI');

    // The creator link opens the creator's profile.
    expect(find.text('JELENA ILIĆ'), findsOneWidget);
    await tapText('KUĆA 30');
    await tapText('POČNI PROGRAM');
    expect(store.plan!.programId, 'p_j_home');
    expect(find.text('DONJI DEO'), findsOneWidget);

    await tapText('POČNI TRENING');
    expect(find.text('GOBL ČUČANJ'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '12');
    await tapText('ZAVRŠI SET');
    await tapText('ZAVRŠI SET');
    expect(store.active!.exercises.first.sets[1].kg, 12, reason: 'weight carries over');
    await tapText('ZAVRŠI SET');
    await tapText('SLEDEĆA VEŽBA');
    await tapText('Završi trening');
    await tapText('ZAVRŠI TRENING');
    expect(find.text('POJAVIO SI SE.'), findsOneWidget);
    await tapText('GOTOVO');
    expect(find.text('GORNJI DEO'), findsOneWidget, reason: 'the plan moved to the next workout');
    expect(store.thisWeek, 1);
  });

  test('creator link parsing', () {
    expect(creatorHandleFromUri(Uri.parse('https://chalkline.app/c/marko.lifts')), 'marko.lifts');
    expect(creatorHandleFromUri(Uri.parse('https://x.app/#/c/jelena.moves')), 'jelena.moves');
    expect(creatorHandleFromUri(Uri.parse('https://x.app/')), isNull);
  });
}
