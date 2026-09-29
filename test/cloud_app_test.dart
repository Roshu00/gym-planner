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

  setUp(() {
    auth = FakeAuth();
    remote = FakeRemote();
    storage = MemoryStore();
  });

  testWidgets('sign in with an email code, then onboarding', (tester) async {
    await pumpApp(tester);
    expect(find.text('PRIJAVI SE.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ana@primer.rs');
    await tester.pump();
    await tapText(tester, 'POŠALJI KOD');
    expect(auth.sentTo, ['ana@primer.rs']);
    expect(find.text('UPIŠI KOD.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pump();
    await tapText(tester, 'PRIJAVI SE');
    expect(find.text('Kod nije tačan ili je istekao.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tapText(tester, 'PRIJAVI SE');
    await tester.pumpAndSettle();
    expect(find.text('KAKO SE ZOVEŠ?'), findsOneWidget, reason: 'no profile on the server yet');
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
    expect(find.text('ZDRAVO, BOBAN'), findsOneWidget);
  });

  testWidgets('guest trains, saves the account, then signs out', (tester) async {
    await pumpApp(tester);
    await tapText(tester, 'Probaj bez naloga');
    await tester.pumpAndSettle();
    expect(find.text('KAKO SE ZOVEŠ?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Gost');
    await tester.pump();
    await tapText(tester, 'DALJE');
    await tapText(tester, 'Snaga');
    await tapText(tester, 'DALJE');
    await tapText(tester, 'Početnik');
    await tapText(tester, 'DALJE');
    await tapText(tester, 'Teretana');
    await tapText(tester, 'DALJE');
    await tapText(tester, 'POČNI');
    expect(remote.tables['profiles']!.single['name'], 'Gost');

    // Creator mode asks for a real account first.
    await tapText(tester, 'PROFIL');
    expect(find.text('Gost'), findsOneWidget);
    await tapText(tester, 'Režim kreatora');
    expect(find.text('SAČUVAJ NALOG.'), findsOneWidget);
    await tapText(tester, 'SAČUVAJ NALOG');
    await tester.enterText(find.byType(TextField), 'gost@primer.rs');
    await tester.pump();
    await tapText(tester, 'POŠALJI KOD');
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tapText(tester, 'SAČUVAJ NALOG');
    await tester.pumpAndSettle();
    expect(auth.current!.isGuest, isFalse);
    expect(find.text('TVOJ PROFIL.'), findsOneWidget, reason: 'creator mode is open now');
    await tester.tap(find.bySemanticsLabel('Nazad').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('gost@primer.rs'), findsOneWidget);
    expect(remote.tables['profiles']!.single['name'], 'Gost', reason: 'same user, same data');

    await tapText(tester, 'ODJAVI SE');
    await tapText(tester, 'ODJAVI SE');
    await tester.pumpAndSettle();
    expect(find.text('PRIJAVI SE.'), findsOneWidget);
  });

  testWidgets('a sync problem shows on every tab and can be retried', (tester) async {
    await auth.verifyCode('ana@primer.rs', '123456');
    await pumpApp(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pump();
    remote.offline = true;
    await tapText(tester, 'DALJE');
    await tapText(tester, 'Snaga');
    await tapText(tester, 'DALJE');
    await tapText(tester, 'Početnik');
    await tapText(tester, 'DALJE');
    await tapText(tester, 'Teretana');
    await tapText(tester, 'DALJE');
    await tapText(tester, 'POČNI');
    expect(find.text('Nije sačuvano na serveru. Proveri internet.'), findsOneWidget);
    remote.offline = false;
    await tapText(tester, 'Ponovo');
    await tester.pumpAndSettle();
    expect(find.text('Nije sačuvano na serveru. Proveri internet.'), findsNothing);
    expect(remote.tables['profiles']!.single['name'], 'Ana');
  });
}
