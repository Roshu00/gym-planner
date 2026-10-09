import 'package:chalkline/app/app.dart';
import 'package:chalkline/data/app_store.dart';
import 'package:chalkline/data/rows.dart';
import 'package:chalkline/data/storage.dart';
import 'package:chalkline/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fakes.dart';

void main() {
  late FakeAuth auth;
  late FakeRemote remote;
  late MemoryStore storage;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChalklineApp.cloud(
        auth: auth,
        storeFor: (u) => AppStore(storage: storage, remote: remote, auth: auth, account: u),
      ),
    );
    await tester.pump();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
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

  /// Onboarding answers move on by themselves after a short pause.
  Future<void> choose(WidgetTester tester, String text) async {
    await tapText(tester, text);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  setUp(() {
    auth = FakeAuth();
    remote = FakeRemote();
    storage = MemoryStore();
  });

  testWidgets('sign in with an email code, then onboarding', (tester) async {
    await pumpApp(tester);
    expect(find.text('Prijavi se.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ana@primer.rs');
    await tester.pump();
    await tapText(tester, 'Pošalji kod');
    expect(auth.sentTo, ['ana@primer.rs']);
    expect(find.text('Upiši kod.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tapText(tester, 'Prijavi se');
    expect(find.text('Kod nije tačan ili je istekao.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tapText(tester, 'Prijavi se');
    await tester.pumpAndSettle();
    expect(find.text('Šta želiš?'), findsOneWidget, reason: 'no profile on the server yet');
  });

  testWidgets('a returning user on a new device goes straight to Today', (tester) async {
    remote.tables['profiles']!.add(
      profileRow(
        const UserProfile(
          name: 'Boban',
          goal: Goal.strength,
          experience: Experience.beginner,
          place: Place.gym,
          daysPerWeek: 3,
          equipment: Equipment.gym,
        ),
        uid,
      ),
    );
    await auth.verifyCode('boban@primer.rs', '123456');
    await pumpApp(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('Boban'), findsOneWidget);
  });

  testWidgets('guest trains, saves the account, then signs out', (tester) async {
    await pumpApp(tester);
    await tapText(tester, 'Probaj bez naloga');
    await tester.pumpAndSettle();
    expect(find.text('Šta želiš?'), findsOneWidget);
    await choose(tester, 'Da treniram');
    await tester.enterText(find.byType(TextField), 'Gost');
    await tester.pump();
    await tapText(tester, 'Dalje');
    for (final answer in ['Snaga', 'Tek počinjem', 'Teretana', '3 dana']) {
      await choose(tester, answer);
    }
    expect(remote.tables['profiles']!.single['name'], 'Gost');

    // Creator mode asks for a real account first.
    // Idle nav items show only an icon; tap by their label for screen readers.
    await tester.tap(find.bySemanticsLabel('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Gost').hitTestable(), findsWidgets);
    // Anyone can become a trainer from the settings; Studio becomes a tab.
    await tester.tap(find.bySemanticsLabel('Podešavanja'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Postani trener');
    expect(find.text('Sačuvaj nalog.'), findsOneWidget);
    await tapText(tester, 'Sačuvaj nalog');
    await tester.enterText(find.byType(TextField), 'gost@primer.rs');
    await tester.pump();
    await tapText(tester, 'Pošalji kod');
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tapText(tester, 'Sačuvaj nalog');
    await tester.pumpAndSettle();
    expect(auth.current!.isGuest, isFalse);
    expect(find.text('Tvoj profil trenera.'), findsOneWidget, reason: 'the Studio tab is open now');
    await tester.tap(find.bySemanticsLabel('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Podešavanja'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Nalog i sinhronizacija');
    expect(find.text('gost@primer.rs'), findsOneWidget);
    expect(remote.tables['profiles']!.single['name'], 'Gost', reason: 'same user, same data');

    await tapText(tester, 'Odjavi se');
    await tapText(tester, 'Odjavi se');
    await tester.pumpAndSettle();
    expect(find.text('Prijavi se.'), findsOneWidget);
  });

  testWidgets('a sync problem shows on every tab and can be retried', (tester) async {
    await auth.verifyCode('ana@primer.rs', '123456');
    await pumpApp(tester);
    await tester.pumpAndSettle();
    await choose(tester, 'Da treniram');
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pump();
    remote.offline = true;
    await tapText(tester, 'Dalje');
    for (final answer in ['Snaga', 'Tek počinjem', 'Teretana', '3 dana']) {
      await choose(tester, answer);
    }
    expect(find.text('Nije sačuvano na serveru. Proveri internet.'), findsOneWidget);
    remote.offline = false;
    await tapText(tester, 'Ponovo');
    await tester.pumpAndSettle();
    expect(find.text('Nije sačuvano na serveru. Proveri internet.'), findsNothing);
    expect(remote.tables['profiles']!.single['name'], 'Ana');
  });
}
