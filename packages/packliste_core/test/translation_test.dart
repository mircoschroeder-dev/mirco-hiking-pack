import 'dart:io';

import 'package:packliste_core/generator.dart';
import 'package:packliste_core/item_repository.dart';
import 'package:packliste_core/models.dart';
import 'package:packliste_core/weights.dart';
import 'package:test/test.dart';

void main() {
  final de = File('assets/items.json').readAsStringSync();
  final en = File('assets/items_en.json').readAsStringSync();
  final german = ItemRepository.fromJsonString(de, translations: en);
  final english = ItemRepository.fromJsonString(
    de,
    translations: en,
    english: true,
  );

  TripItem saved(String id, String name, String category) => TripItem(
    id: id,
    name: name,
    category: category,
    quantity: 1,
    weightType: WeightType.base,
  );

  test('Englische Namen sind vollstaendig und eindeutig', () {
    expect(english.items.length, 74);
    expect(english.items.map((i) => i.name).toSet().length, 74);
    expect(english.categories.first, 'Backpack & carrying');
    expect(english.byId('muetze')!.name, 'Beanie');
    expect(english.byId('verpflegung')!.category, 'Kitchen & food');
  });

  test('Deutsche Namen haben Umlaute', () {
    expect(german.byId('muetze')!.name, 'Mütze');
    expect(german.categories, contains('Küche & Verpflegung'));
    expect(german.byId('trowel')!.name, 'Toilettenschaufel');
  });

  test('Die Sprache aendert keine Gewichte und keine Reihenfolge', () {
    const config = TripConfig(
      tourType: TourType.tent,
      days: 5,
      tempBand: TempBand.cold,
      options: {TripOption.rain, TripOption.cooking},
    );
    final listDe = PacklistGenerator(german).generateList(config);
    final listEn = PacklistGenerator(english).generateList(config);
    expect(listEn.length, listDe.length);
    expect(
      summarizeWeights(listEn).packStartG,
      summarizeWeights(listDe).packStartG,
    );
  });

  group('Gespeicherte Gegenstaende nachziehen', () {
    test('Alte Schreibweise ohne Umlaut wird korrigiert', () {
      final item = german.refresh(saved('muetze', 'Muetze', 'Kleidung'));
      expect(item.name, 'Mütze');
      final food = german.refresh(
        saved('verpflegung', 'Verpflegung', 'Kueche & Verpflegung'),
      );
      expect(food.category, 'Küche & Verpflegung');
    });

    test('Frueherer Name wird ersetzt', () {
      final item = german.refresh(saved('trowel', 'Klappspaten', 'Hygiene'));
      expect(item.name, 'Toilettenschaufel');
    });

    test('Wechsel der Handysprache uebersetzt Standardnamen', () {
      final item = english.refresh(saved('muetze', 'Muetze', 'Kleidung'));
      expect(item.name, 'Beanie');
      expect(item.category, 'Clothing');
      expect(german.refresh(item).name, 'Mütze');
    });

    test('Selbst geaenderter Name bleibt erhalten', () {
      final item = german.refresh(
        saved('muetze', 'Rote Wollmütze', 'Kleidung'),
      );
      expect(item.name, 'Rote Wollmütze');
    });

    test('Eigener Gegenstand: nur die Kategorie wird uebersetzt', () {
      final item = english.refresh(saved('eigen_1', 'Fernglas', 'Sonstiges'));
      expect(item.name, 'Fernglas');
      expect(item.category, 'Other');
    });
  });

  test('Fehlende Uebersetzung wird beim Laden gemeldet', () {
    expect(
      () => ItemRepository.fromJsonString(
        de,
        translations: '{"categories": {}, "items": {}}',
      ),
      throwsFormatException,
    );
  });
}
