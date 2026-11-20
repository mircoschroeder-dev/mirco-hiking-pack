import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packliste_core/item_repository.dart';
import 'package:wanderrucksack/data/list_repository.dart';
import 'package:wanderrucksack/main.dart';
import 'package:wanderrucksack/state/providers.dart';
import 'package:wanderrucksack/texte.dart';

void main() {
  final seed = File(
    'packages/packliste_core/assets/items.json',
  ).readAsStringSync();
  final seedEn = File(
    'packages/packliste_core/assets/items_en.json',
  ).readAsStringSync();
  late Directory dir;

  Future<void> startApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          itemRepositoryProvider.overrideWith(
            (ref) async => ItemRepository.fromJsonString(
              seed,
              translations: seedEn,
              english: Texte.english,
            ),
          ),
          listRepositoryProvider.overrideWithValue(
            ListRepository(() async => dir),
          ),
        ],
        child: const WanderrucksackApp(),
      ),
    );
    await settle(tester);
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('wanderrucksack_test');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> tapText(WidgetTester tester, String text) async {
    // .last: Dialoge und Bottom Sheets liegen ueber gleichem Text.
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  Future<void> rowAction(WidgetTester tester, int row, String action) async {
    await tester.tap(find.byIcon(Icons.more_horiz).at(row));
    await settle(tester);
    await tapText(tester, action);
  }

  Future<void> openHerbstRegen(WidgetTester tester) async {
    await tapText(tester, 'Tageswanderung');
    await tapText(tester, 'Herbst');
    await tapText(tester, 'Regengefahr');
    await tapText(tester, Texte.listeOeffnen);
  }

  testWidgets(
    'Tageswanderung, Herbst, Regengefahr oeffnet die richtige Liste',
    (tester) async {
      await startApp(tester);
      expect(find.text(Texte.uebernachtung.toUpperCase()), findsNothing);
      await openHerbstRegen(tester);
      expect(
        find.text('Tageswanderung · Herbst · Regengefahr'),
        findsOneWidget,
      );
      expect(find.text('5,8 kg'), findsOneWidget);
      expect(find.text('0 von 32 gepackt'), findsOneWidget);
      await tester.dragUntilVisible(
        find.text('Regenhose'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Regenhose'), findsOneWidget);
    },
  );

  testWidgets('Mehrere Tage fragen nach dem Zelt', (tester) async {
    await startApp(tester);
    await tapText(tester, '2–3 Tage');
    expect(find.text(Texte.uebernachtung.toUpperCase()), findsOneWidget);
    await tapText(tester, 'Sommer');
    await tapText(tester, 'Trocken');
    final button = find.widgetWithText(FilledButton, Texte.listeOeffnen);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tapText(tester, Texte.mitZelt);
    await tapText(tester, Texte.listeOeffnen);
    await tester.dragUntilVisible(
      find.text('Zelt'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('Zelt'), findsOneWidget);
  });

  testWidgets('Extra Foto blendet ein und aus, Gewicht folgt', (tester) async {
    await startApp(tester);
    await openHerbstRegen(tester);
    await tapText(tester, 'Foto & Video');
    expect(find.text('0 von 38 gepackt'), findsOneWidget);
    await tapText(tester, 'Foto & Video');
    expect(find.text('0 von 32 gepackt'), findsOneWidget);
    expect(find.text('5,8 kg'), findsOneWidget);
    expect(find.text('Kochen'), findsNothing);
  });

  testWidgets('Abhaken, alles abhaken, alles zuruecksetzen', (tester) async {
    await startApp(tester);
    await openHerbstRegen(tester);
    await tester.tap(find.byType(Checkbox).first);
    await settle(tester);
    expect(find.text('1 von 32 gepackt'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.adaptive.more));
    await settle(tester);
    await tapText(tester, Texte.allesAbhaken);
    expect(find.text('32 von 32 gepackt'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.adaptive.more));
    await settle(tester);
    await tapText(tester, Texte.allesZuruecksetzen);
    expect(find.text('0 von 32 gepackt'), findsOneWidget);
  });

  testWidgets('Nicht mitnehmen zaehlt nicht und laesst sich zurueckholen', (
    tester,
  ) async {
    await startApp(tester);
    await openHerbstRegen(tester);
    await rowAction(tester, 0, Texte.nichtMitnehmen);
    expect(find.text('0 von 31 gepackt'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text(Texte.nichtMitnehmen.toUpperCase()),
      find.byType(ListView),
      const Offset(0, -600),
    );
    await settle(tester);
    await tester.tap(find.byIcon(Icons.more_horiz).last);
    await settle(tester);
    await tapText(tester, Texte.dochMitnehmen);
    expect(find.text('0 von 32 gepackt'), findsOneWidget);
  });

  testWidgets('Zu Kaufendes bleibt beim Alles-Abhaken offen', (tester) async {
    await startApp(tester);
    await openHerbstRegen(tester);
    await rowAction(tester, 0, Texte.mussGekauftWerden);
    expect(find.text('${Texte.statusKaufen} 1'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.adaptive.more));
    await settle(tester);
    await tapText(tester, Texte.allesAbhaken);
    expect(find.text('31 von 32 gepackt'), findsOneWidget);
  });

  testWidgets('Gegenstand hinzufuegen und loeschen mit Rueckgaengig', (
    tester,
  ) async {
    await startApp(tester);
    await openHerbstRegen(tester);
    await tapText(tester, Texte.gegenstandHinzufuegen);
    await tester.enterText(
      find.widgetWithText(TextFormField, Texte.feldName),
      'Fernglas',
    );
    await tapText(tester, Texte.speichern);
    expect(find.text('0 von 33 gepackt'), findsOneWidget);

    await rowAction(tester, 0, Texte.vonListeLoeschen);
    expect(find.text('0 von 32 gepackt'), findsOneWidget);
    await tapText(tester, Texte.rueckgaengig);
    expect(find.text('0 von 33 gepackt'), findsOneWidget);
  });

  testWidgets('Liste neu aufbauen fragt nach und setzt zurueck', (
    tester,
  ) async {
    await startApp(tester);
    await openHerbstRegen(tester);
    await rowAction(tester, 0, Texte.vonListeLoeschen);
    expect(find.text('0 von 31 gepackt'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.adaptive.more));
    await settle(tester);
    await tapText(tester, Texte.listeNeuAufbauen);
    await tapText(tester, Texte.neuAufbauen);
    expect(find.text('0 von 32 gepackt'), findsOneWidget);
  });

  testWidgets('Englisches Handy: englische Texte und Gegenstaende', (
    tester,
  ) async {
    Texte.english = true;
    addTearDown(() => Texte.english = false);
    await startApp(tester);
    await tapText(tester, 'Day hike');
    await tapText(tester, 'Autumn');
    await tapText(tester, 'Chance of rain');
    await tapText(tester, 'Open list');
    expect(find.text('Day hike · Autumn · Chance of rain'), findsOneWidget);
    expect(find.text('5.8 kg'), findsOneWidget);
    expect(find.text('0 of 32 packed'), findsOneWidget);
    expect(find.text('BACKPACK & CARRYING'), findsOneWidget);
  });

  testWidgets('Kaputte Datei: Hinweis statt Absturz', (tester) async {
    File('${dir.path}/wanderrucksack.json').writeAsStringSync('{kaputt');
    await startApp(tester);
    expect(find.text(Texte.dateiDefekt), findsOneWidget);
    expect(find.text(Texte.listeOeffnen), findsOneWidget);
  });
}

// Dateizugriffe sind echte asynchrone Arbeit; im Testmodus laufen sie nur
// innerhalb von runAsync weiter.
Future<void> settle(WidgetTester tester) async {
  final loading = find.byType(CircularProgressIndicator);
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    if (i >= 4 && loading.evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}
