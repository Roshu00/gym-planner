import 'package:chalkline/gallery/examples.dart';
import 'package:chalkline/gallery/gallery_app.dart';
import 'package:chalkline/gallery/sections.dart';
import 'package:chalkline/ui/chalkline_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final pages = <String, Widget Function()>{
  'colors': () => const ColorsPage(),
  'typography': () => const TypographyPage(),
  'spacing': () => const SpacingPage(),
  'icons': () => const IconsPage(),
  'buttons': () => const ButtonsPage(),
  'tags': () => const TagsPage(),
  'media': () => const MediaPage(),
  'hero': () => const HeroPage(),
  'statbar': () => const StatBarPage(),
  'settable': () => const SetTablePage(),
  'resttimer': () => const RestTimerPage(),
  'programcard': () => const ProgramCardPage(),
  'lists': () => const ListsPage(),
  'inputs': () => const InputsPage(),
  'summary': () => const SummaryPage(),
  'chart': () => const ChartPage(),
  'nav': () => const NavPage(),
  'today': () => const TodayExample(),
  'workout': () => const WorkoutExample(),
  'summary example': () => const SummaryExample(),
};

Future<void> pumpPage(WidgetTester tester, Widget page, ClTheme theme) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(theme: theme.toThemeData(), home: page));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> scrollThrough(WidgetTester tester) async {
  final scrollables = find.byType(Scrollable);
  if (scrollables.evaluate().isEmpty) return;
  for (var i = 0; i < 12; i++) {
    await tester.drag(scrollables.first, const Offset(0, -500), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  for (final entry in pages.entries) {
    for (final theme in [ClTheme.dark, ClTheme.light]) {
      testWidgets('${entry.key} renders without overflow (${theme.colors.brightness.name})', (tester) async {
        await pumpPage(tester, entry.value(), theme);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('gallery home lists every section', (tester) async {
    await pumpPage(tester, const GalleryHome(), ClTheme.dark);
    expect(find.text('CHALKLINE'), findsOneWidget);
    await scrollThrough(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirming a set marks it done and moves current', (tester) async {
    await pumpPage(tester, const SetTablePage(), ClTheme.dark);
    expect(find.bySemanticsLabel('Završi set 2'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Završi set 2'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel('Poništi set 2'), findsOneWidget);
  });

  testWidgets('heavier set than last time shows a PR tag', (tester) async {
    await pumpPage(tester, const SetTablePage(), ClTheme.dark);
    final before = find.text('PR').evaluate().length;
    await tester.enterText(find.byType(TextField).first, '85'); // set 1 is done, so this is set 2 kg
    await tester.tap(find.bySemanticsLabel('Završi set 2'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('PR').evaluate().length, before + 1);
  });
}
