import 'dart:io';

import 'package:packliste_core/conditions.dart';
import 'package:packliste_core/generator.dart';
import 'package:packliste_core/item_repository.dart';
import 'package:packliste_core/models.dart';
import 'package:packliste_core/weights.dart';
import 'package:test/test.dart';

void main() {
  final repository = ItemRepository.fromJsonString(
    File('assets/items.json').readAsStringSync(),
  );
  final generator = PacklistGenerator(repository);

  List<TripItem> listFor(ListConditions c) =>
      generator.generateList(c.toTripConfig());

  const herbstRegen = ListConditions(
    length: TripLength.day,
    withTent: false,
    season: Season.autumn,
    weather: Weather.rainRisk,
  );

  test('Jahreszeit wird zur Temperatur', () {
    ListConditions of(Season s) => ListConditions(
      length: TripLength.day,
      withTent: false,
      season: s,
      weather: Weather.dry,
    );
    expect(of(Season.summer).tempBand, TempBand.warm);
    expect(of(Season.spring).tempBand, TempBand.mild);
    expect(of(Season.autumn).tempBand, TempBand.mild);
    expect(of(Season.winter).tempBand, TempBand.frost);
  });

  test('Dauer rechnet mit dem laengsten Fall', () {
    ListConditions of(TripLength l) => ListConditions(
      length: l,
      withTent: true,
      season: Season.summer,
      weather: Weather.dry,
    );
    expect(of(TripLength.day).days, 1);
    expect(of(TripLength.short).days, 3);
    expect(of(TripLength.week).days, 7);
    expect(of(TripLength.long).days, 21);
  });

  test('Tageswanderung hat nie ein Zelt, auch wenn es angegeben wird', () {
    const c = ListConditions(
      length: TripLength.day,
      withTent: true,
      season: Season.summer,
      weather: Weather.dry,
    );
    expect(c.tourType, TourType.day);
    expect(c.key, contains('noTent'));
  });

  test('Mit und ohne Zelt sind getrennte Listen', () {
    ListConditions of(bool tent) => ListConditions(
      length: TripLength.short,
      withTent: tent,
      season: Season.autumn,
      weather: Weather.dry,
    );
    expect(of(true).key, isNot(of(false).key));
    expect(listFor(of(true)).map((i) => i.id), contains('zelt'));
    expect(listFor(of(false)).map((i) => i.id), isNot(contains('zelt')));
    expect(listFor(of(false)).map((i) => i.id), contains('huettenschlafsack'));
  });

  test('Regengefahr bringt die Regenhose, trocken nicht', () {
    const trocken = ListConditions(
      length: TripLength.day,
      withTent: false,
      season: Season.autumn,
      weather: Weather.dry,
    );
    expect(listFor(herbstRegen).map((i) => i.id), contains('regenhose'));
    expect(listFor(trocken).map((i) => i.id), isNot(contains('regenhose')));
  });

  // Werte unabhaengig aus den Regeln in items.json nachgerechnet.
  test('Tageswanderung, Herbst, Regengefahr, ohne Extras', () {
    final visible = visibleItems(listFor(herbstRegen), const {}, repository);
    final summary = summarizeWeights(visible);
    expect(visible.length, 32);
    expect(formatKg(summary.packStartG), '5,8 kg');
  });

  test('Extra Foto blendet genau die sechs Foto-Gegenstaende ein', () {
    final all = listFor(herbstRegen);
    final ohne = visibleItems(all, const {}, repository);
    final mit = visibleItems(all, const {TripOption.photo}, repository);
    expect(mit.length - ohne.length, 6);
    expect(mit.map((i) => i.id), contains('kamera'));
    expect(ohne.map((i) => i.id), isNot(contains('kamera')));
  });

  test('Selbst hinzugefuegte Gegenstaende bleiben immer sichtbar', () {
    const eigen = TripItem(
      id: 'eigen_1',
      name: 'Fernglas',
      category: 'Sonstiges',
      quantity: 1,
      weightType: WeightType.base,
    );
    expect(visibleItems([eigen], const {}, repository), [eigen]);
  });

  test('Nur Extras anbieten, die in der Liste etwas aendern', () {
    final extras = availableExtras(listFor(herbstRegen), repository);
    expect(extras, containsAll({TripOption.photo, TripOption.dog}));
    // Kochen gibt es nur mit Zelt, Solarpanel nur mit Zelt ab 4 Tagen.
    expect(extras, isNot(contains(TripOption.cooking)));
    expect(extras, isNot(contains(TripOption.nopower)));
  });

  group('Proviant auf langen Touren', () {
    const lang = ListConditions(
      length: TripLength.long,
      withTent: false,
      season: Season.autumn,
      weather: Weather.dry,
    );
    int quantity(List<TripItem> list, String id) =>
        list.firstWhere((i) => i.id == id).quantity;

    test('Mitgetragen wird Proviant fuer 3 Tage', () {
      final list = generateForConditions(repository, lang);
      expect(quantity(list, 'verpflegung'), 3);
      expect(quantity(list, 'snacks'), 4);
      expect(quantity(list, 'hundefutter'), 3);
    });

    test('Alles andere rechnet weiter mit 21 Tagen', () {
      final list = generateForConditions(repository, lang);
      expect(quantity(list, 'powerbank'), 7);
    });

    // Werte unabhaengig aus den Regeln in items.json nachgerechnet.
    test('Gewicht ohne Zelt, Herbst, trocken, ohne Extras', () {
      final list = generateForConditions(repository, lang);
      final summary = summarizeWeights(
        visibleItems(list, const {}, repository),
      );
      expect(formatKg(summary.consumableG), '3,8 kg');
      expect(formatKg(summary.packStartG), '11,2 kg');
    });

    test('Kuerzere Dauer bleibt unveraendert', () {
      const woche = ListConditions(
        length: TripLength.week,
        withTent: false,
        season: Season.autumn,
        weather: Weather.dry,
      );
      expect(
        quantity(generateForConditions(repository, woche), 'verpflegung'),
        7,
      );
    });
  });

  test('Bedingungen ueberstehen Speichern und Laden', () {
    final copy = ListConditions.fromJson(herbstRegen.toJson());
    expect(copy.key, herbstRegen.key);
  });
}
