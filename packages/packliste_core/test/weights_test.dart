import 'dart:io';

import 'package:packliste_core/generator.dart';
import 'package:packliste_core/item_repository.dart';
import 'package:packliste_core/models.dart';
import 'package:packliste_core/weights.dart';
import 'package:test/test.dart';

void main() {
  final generator = PacklistGenerator(
    ItemRepository.fromJsonString(File('assets/items.json').readAsStringSync()),
  );

  void expectCase(
    TripConfig config, {
    required int positions,
    required String base,
    required String consumable,
    required String start,
  }) {
    final list = generator.generateList(config);
    final summary = summarizeWeights(list);
    expect(list.length, positions, reason: 'Positionen');
    expect(formatKg(summary.baseG), base, reason: 'Basis');
    expect(formatKg(summary.consumableG), consumable, reason: 'Verbrauch');
    expect(formatKg(summary.packStartG), start, reason: 'Rucksack beim Start');
  }

  group('Referenzfaelle aus dem Auftrag', () {
    test('day, 1 Tag, warm, keine Optionen', () {
      expectCase(
        const TripConfig(
          tourType: TourType.day,
          days: 1,
          tempBand: TempBand.warm,
        ),
        positions: 30,
        base: '2,6 kg',
        consumable: '2,5 kg',
        start: '5,1 kg',
      );
    });

    test('hut, 3 Tage, mild, keine Optionen', () {
      expectCase(
        const TripConfig(
          tourType: TourType.hut,
          days: 3,
          tempBand: TempBand.mild,
        ),
        positions: 43,
        base: '5,6 kg',
        consumable: '3,8 kg',
        start: '9,4 kg',
      );
    });

    test('tent, 5 Tage, cold, rain+cooking', () {
      expectCase(
        const TripConfig(
          tourType: TourType.tent,
          days: 5,
          tempBand: TempBand.cold,
          options: {TripOption.rain, TripOption.cooking},
        ),
        positions: 52,
        base: '11,3 kg',
        consumable: '5,3 kg',
        start: '16,6 kg',
      );
    });

    // Die Tabelle im Auftrag nennt hier "alle Optionen", ihre Zahlen gehen aber
    // nur ohne `dog` auf (siehe FORTSCHRITT.md). Die Erwartungswerte sind
    // unveraendert aus der Tabelle uebernommen.
    test('tent, 21 Tage, frost, alle Optionen ausser dog', () {
      expectCase(
        const TripConfig(
          tourType: TourType.tent,
          days: 21,
          tempBand: TempBand.frost,
          options: {
            TripOption.rain,
            TripOption.photo,
            TripOption.cooking,
            TripOption.nopower,
          },
        ),
        positions: 59,
        base: '16,1 kg',
        consumable: '16,7 kg',
        start: '32,8 kg',
      );
    });
  });

  // Nachgerechnet aus den Regeln in items.json, nicht aus der Auftrags-Tabelle.
  test('tent, 21 Tage, frost, wirklich alle Optionen (mit dog)', () {
    expectCase(
      TripConfig(
        tourType: TourType.tent,
        days: 21,
        tempBand: TempBand.frost,
        options: TripOption.values.toSet(),
      ),
      positions: 63,
      base: '16,4 kg',
      consumable: '25,1 kg',
      start: '41,5 kg',
    );
  });

  test('Getragenes zaehlt nicht zum Rucksack', () {
    const items = [
      TripItem(
        id: 'a',
        name: 'a',
        category: 'c',
        quantity: 2,
        weightG: 100,
        weightType: WeightType.base,
      ),
      TripItem(
        id: 'b',
        name: 'b',
        category: 'c',
        quantity: 1,
        weightG: 50,
        weightType: WeightType.consumable,
      ),
      TripItem(
        id: 'c',
        name: 'c',
        category: 'c',
        quantity: 1,
        weightG: 1000,
        weightType: WeightType.worn,
      ),
    ];
    final summary = summarizeWeights(items);
    expect(summary.baseG, 200);
    expect(summary.consumableG, 50);
    expect(summary.wornG, 1000);
    expect(summary.packStartG, 250);
    expect(summary.itemsWithoutWeight, 0);
  });

  test('Nicht Mitgenommenes zaehlt nirgends, zu Kaufendes schon', () {
    const items = [
      TripItem(
        id: 'a',
        name: 'a',
        category: 'c',
        quantity: 1,
        weightG: 100,
        weightType: WeightType.base,
        status: ItemStatus.left,
      ),
      TripItem(
        id: 'b',
        name: 'b',
        category: 'c',
        quantity: 1,
        weightType: WeightType.base,
        status: ItemStatus.left,
      ),
      TripItem(
        id: 'c',
        name: 'c',
        category: 'c',
        quantity: 1,
        weightG: 40,
        weightType: WeightType.base,
        status: ItemStatus.toBuy,
      ),
    ];
    final summary = summarizeWeights(items);
    expect(summary.baseG, 40);
    expect(summary.itemsWithoutWeight, 0);
  });

  test('Abhaken: Gekauftes ist nach dem Auspacken vorhanden', () {
    const item = TripItem(
      id: 'a',
      name: 'a',
      category: 'c',
      quantity: 1,
      weightType: WeightType.base,
      status: ItemStatus.toBuy,
    );
    final packed = item.togglePacked();
    expect(packed.status, ItemStatus.packed);
    expect(packed.togglePacked().status, ItemStatus.available);
    final left = item.copyWith(status: ItemStatus.left);
    expect(left.togglePacked().status, ItemStatus.left);
  });

  test('Gegenstaende ohne Gewicht zaehlen 0 g und werden ausgewiesen', () {
    const items = [
      TripItem(
        id: 'a',
        name: 'a',
        category: 'c',
        quantity: 3,
        weightType: WeightType.base,
      ),
      TripItem(
        id: 'b',
        name: 'b',
        category: 'c',
        quantity: 1,
        weightG: 10,
        weightType: WeightType.base,
      ),
    ];
    final summary = summarizeWeights(items);
    expect(summary.baseG, 10);
    expect(summary.itemsWithoutWeight, 1);
  });
}
