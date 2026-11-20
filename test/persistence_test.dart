import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:packliste_core/conditions.dart';
import 'package:packliste_core/item_repository.dart';
import 'package:packliste_core/models.dart';
import 'package:wanderrucksack/data/list_repository.dart';
import 'package:wanderrucksack/state/providers.dart';

void main() {
  final seed = File(
    'packages/packliste_core/assets/items.json',
  ).readAsStringSync();
  final seedEn = File(
    'packages/packliste_core/assets/items_en.json',
  ).readAsStringSync();
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('wanderrucksack_core'));
  tearDown(() => dir.deleteSync(recursive: true));

  const herbstRegen = ListConditions(
    length: TripLength.day,
    withTent: false,
    season: Season.autumn,
    weather: Weather.rainRisk,
  );
  const sommer = ListConditions(
    length: TripLength.day,
    withTent: false,
    season: Season.summer,
    weather: Weather.dry,
  );

  // Ein neuer Container auf derselben Datei entspricht einem App-Neustart.
  Future<ProviderContainer> start() async {
    final container = ProviderContainer(
      overrides: [
        itemRepositoryProvider.overrideWith(
          (ref) async =>
              ItemRepository.fromJsonString(seed, translations: seedEn),
        ),
        listRepositoryProvider.overrideWithValue(
          ListRepository(() async => dir),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(itemRepositoryProvider.future);
    await container.read(appDataProvider.future);
    return container;
  }

  TripItem item(ProviderContainer c, String id) =>
      c.read(currentListProvider)!.items.firstWhere((i) => i.id == id);

  test(
    'Stand einer Liste ueberlebt den Neustart, andere bleiben unberuehrt',
    () async {
      final first = await start();
      final notifier = first.read(currentListProvider.notifier);
      notifier.open(herbstRegen);
      await notifier.setStatus('karte', ItemStatus.toBuy);
      await notifier.setExtra(TripOption.photo, true);
      await notifier.togglePacked('regenjacke');

      final second = await start();
      second.read(currentListProvider.notifier).open(herbstRegen);
      expect(item(second, 'karte').status, ItemStatus.toBuy);
      expect(item(second, 'regenjacke').status, ItemStatus.packed);
      expect(second.read(currentListProvider)!.extras, {TripOption.photo});

      second.read(currentListProvider.notifier).open(sommer);
      expect(item(second, 'karte').status, ItemStatus.available);
      expect(second.read(currentListProvider)!.extras, isEmpty);
    },
  );

  test('Eigenes Gewicht gilt in vorhandenen und neuen Listen', () async {
    final first = await start();
    final notifier = first.read(currentListProvider.notifier);
    notifier.open(sommer);
    await notifier.togglePacked('karte'); // Sommerliste liegt damit vor.
    notifier.open(herbstRegen);
    await notifier.putItem(
      item(first, 'regenhuelle').copyWith(weightG: () => 300),
    );

    final second = await start();
    final reopened = second.read(currentListProvider.notifier);
    reopened.open(sommer);
    expect(item(second, 'regenhuelle').weightG, 300);
    reopened.open(
      const ListConditions(
        length: TripLength.short,
        withTent: true,
        season: Season.winter,
        weather: Weather.dry,
      ),
    );
    expect(item(second, 'regenhuelle').weightG, 300);
  });

  test('Liste neu aufbauen verwirft Aenderungen, Gewichte bleiben', () async {
    final first = await start();
    final notifier = first.read(currentListProvider.notifier);
    notifier.open(herbstRegen);
    await notifier.putItem(
      item(first, 'regenhuelle').copyWith(weightG: () => 300),
    );
    await notifier.setStatus('karte', ItemStatus.left);
    await notifier.rebuild();
    expect(item(first, 'karte').status, ItemStatus.available);
    expect(item(first, 'regenhuelle').weightG, 300);

    final second = await start();
    expect(second.read(appDataProvider).requireValue.lists, isEmpty);
  });

  test('Alter Speicherstand: Touren entfallen, Gewichte bleiben', () async {
    File('${dir.path}/wanderrucksack.json').writeAsStringSync(
      jsonEncode({
        'schemaVersion': 1,
        'tours': [
          {'id': 'x', 'name': 'Harz'},
        ],
        'customWeightsG': {'regenhuelle': 300},
      }),
    );
    final c = await start();
    final data = c.read(appDataProvider).requireValue;
    expect(data.lists, isEmpty);
    expect(data.customWeightsG, {'regenhuelle': 300});
    c.read(currentListProvider.notifier).open(herbstRegen);
    expect(item(c, 'regenhuelle').weightG, 300);
  });

  test('Kaputte Datei: leerer Start, Datei bleibt als Sicherung', () async {
    File('${dir.path}/wanderrucksack.json').writeAsStringSync('{kaputt');
    final c = await start();
    expect(c.read(appDataProvider).requireValue.lists, isEmpty);
    expect(File('${dir.path}/wanderrucksack.json.defekt').existsSync(), isTrue);
  });
}
