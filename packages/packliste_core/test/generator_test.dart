import 'dart:io';

import 'package:packliste_core/generator.dart';
import 'package:packliste_core/item_repository.dart';
import 'package:packliste_core/models.dart';
import 'package:test/test.dart';

void main() {
  final repository = ItemRepository.fromJsonString(
    File('assets/items.json').readAsStringSync(),
  );
  final generator = PacklistGenerator(repository);

  Set<String> ids(TripConfig config) =>
      generator.generateList(config).map((i) => i.id).toSet();

  test('Seed-Daten haben 74 Gegenstaende und 13 Kategorien', () {
    expect(repository.items.length, 74);
    expect(repository.categories.length, 13);
  });

  test('Tagestour enthaelt kein Zelt, keinen Schlafsack, keinen Kocher', () {
    for (final band in TempBand.values) {
      final list = ids(
        TripConfig(
          tourType: TourType.day,
          days: 1,
          tempBand: band,
          options: TripOption.values.toSet(),
        ),
      );
      expect(list, isNot(contains('zelt')));
      expect(list.where((id) => id.contains('schlafsack')), isEmpty);
      expect(list, isNot(contains('kocher')));
    }
  });

  test('Huettentour enthaelt kein Zelt, aber einen Huettenschlafsack', () {
    for (final band in TempBand.values) {
      final list = ids(
        TripConfig(tourType: TourType.hut, days: 3, tempBand: band),
      );
      expect(list, isNot(contains('zelt')));
      expect(list, contains('huettenschlafsack'));
    }
  });

  test('Option photo veraendert genau die sechs Foto-Gegenstaende', () {
    const fotoBlock = {
      'kamera',
      'kamera_akkus',
      'speicherkarten',
      'stativ',
      'mikrofon',
      'objektivtuch',
    };
    for (final tour in TourType.values) {
      for (final band in TempBand.values) {
        final days = tour == TourType.day ? 1 : 5;
        final ohne = generator.generateList(
          TripConfig(tourType: tour, days: days, tempBand: band),
        );
        final mit = generator.generateList(
          TripConfig(
            tourType: tour,
            days: days,
            tempBand: band,
            options: const {TripOption.photo},
          ),
        );
        expect(
          mit
              .map((i) => i.id)
              .toSet()
              .difference(ohne.map((i) => i.id).toSet()),
          fotoBlock,
        );
        expect(
          mit.where((i) => !fotoBlock.contains(i.id)).map((i) => i.toJson()),
          ohne.map((i) => i.toJson()),
        );
      }
    }
  });

  test(
    'days = 1 und days = 21 liefern fuer alle Kombinationen gueltige Listen',
    () {
      for (final days in [1, 21]) {
        for (final tour in TourType.values) {
          for (final band in TempBand.values) {
            final list = generator.generateList(
              TripConfig(
                tourType: tour,
                days: days,
                tempBand: band,
                options: TripOption.values.toSet(),
              ),
            );
            expect(list, isNotEmpty);
            expect(list.every((i) => i.quantity >= 1), isTrue);
          }
        }
      }
    },
  );

  test('minDays wird beachtet', () {
    const config1 = TripConfig(
      tourType: TourType.tent,
      days: 1,
      tempBand: TempBand.warm,
    );
    const config2 = TripConfig(
      tourType: TourType.tent,
      days: 2,
      tempBand: TempBand.warm,
    );
    expect(ids(config1), isNot(contains('wasserfilter')));
    expect(ids(config2), contains('wasserfilter'));
  });

  test('eigenes Gewicht geht vor Standardgewicht', () {
    final list = generator.generateList(
      const TripConfig(
        tourType: TourType.day,
        days: 1,
        tempBand: TempBand.warm,
        customWeightsG: {'regenjacke': 111},
      ),
    );
    expect(list.firstWhere((i) => i.id == 'regenjacke').weightG, 111);
    expect(list.firstWhere((i) => i.id == 'karte').weightG, 100);
  });

  test('Duplikate werden zusammengefasst, hoechste Menge gewinnt', () {
    final dup = ItemRepository.fromJsonString('''
      {"categories": ["K"], "items": [
        {"id": "a", "name": "A", "category": "K", "weightType": "base",
         "rule": {"tourTypes": ["day"], "tempBands": ["warm"], "quantity": "2"}},
        {"id": "a", "name": "A", "category": "K", "weightType": "base",
         "rule": {"tourTypes": ["day"], "tempBands": ["warm"], "quantity": "5"}},
        {"id": "a", "name": "A", "category": "K", "weightType": "base",
         "rule": {"tourTypes": ["day"], "tempBands": ["warm"], "quantity": "3"}}
      ]}''');
    final list = PacklistGenerator(dup).generateList(
      const TripConfig(
        tourType: TourType.day,
        days: 1,
        tempBand: TempBand.warm,
      ),
    );
    expect(list.length, 1);
    expect(list.single.quantity, 5);
    expect(list.single.weightG, isNull);
  });

  test(
    'Sortierung: Kategorie-Reihenfolge, essential zuerst, dann alphabetisch',
    () {
      final list = generator.generateList(
        TripConfig(
          tourType: TourType.tent,
          days: 5,
          tempBand: TempBand.cold,
          options: TripOption.values.toSet(),
        ),
      );
      var lastRank = -1;
      TripItem? previous;
      for (final item in list) {
        final rank = repository.categories.indexOf(item.category);
        expect(rank, greaterThanOrEqualTo(lastRank));
        if (previous != null && rank == lastRank) {
          if (previous.essential == item.essential) {
            expect(
              previous.name.toLowerCase().compareTo(item.name.toLowerCase()),
              lessThan(0),
            );
          } else {
            expect(previous.essential, isTrue);
          }
        }
        lastRank = rank;
        previous = item;
      }
    },
  );

  test('unbekannter Mengen-Ausdruck wirft beim Laden', () {
    expect(
      () => ItemRepository.fromJsonString('''
        {"categories": ["K"], "items": [
          {"id": "a", "name": "A", "category": "K", "weightType": "base",
           "rule": {"tourTypes": ["day"], "tempBands": ["warm"], "quantity": "days-1"}}
        ]}'''),
      throwsFormatException,
    );
  });

  test('TripItem und TripConfig ueberstehen JSON-Rundreise', () {
    const item = TripItem(
      id: 'x',
      name: 'X',
      category: 'K',
      quantity: 2,
      weightG: 12,
      weightType: WeightType.worn,
      essential: true,
      note: 'n',
      status: ItemStatus.toBuy,
    );
    expect(TripItem.fromJson(item.toJson()).toJson(), item.toJson());
    final old = item.toJson()
      ..remove('status')
      ..['packed'] = true;
    expect(TripItem.fromJson(old).status, ItemStatus.packed);
    const config = TripConfig(
      tourType: TourType.hut,
      days: 4,
      tempBand: TempBand.cold,
      options: {TripOption.dog},
    );
    expect(TripConfig.fromJson(config.toJson()).toJson(), config.toJson());
  });
}
