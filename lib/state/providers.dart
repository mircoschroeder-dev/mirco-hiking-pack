import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:packliste_core/conditions.dart';
import 'package:packliste_core/generator.dart';
import 'package:packliste_core/item_repository.dart';
import 'package:packliste_core/models.dart';
import 'package:path_provider/path_provider.dart';

import '../data/list_repository.dart';
import '../data/pack_list.dart';
import '../texte.dart';

final itemRepositoryProvider = FutureProvider<ItemRepository>((ref) async {
  const folder = 'packages/packliste_core/assets';
  return ItemRepository.fromJsonString(
    await rootBundle.loadString('$folder/items.json'),
    translations: await rootBundle.loadString('$folder/items_en.json'),
    english: Texte.english,
  );
});

final listRepositoryProvider = Provider<ListRepository>(
  (ref) => ListRepository(getApplicationDocumentsDirectory),
);

/// Hinweis an den Nutzer zu Laden oder Speichern; null, wenn nichts anliegt.
final noticeProvider = NotifierProvider<NoticeNotifier, String?>(
  NoticeNotifier.new,
);

class NoticeNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String text) => state = text;

  void clear() => state = null;
}

final appDataProvider = AsyncNotifierProvider<AppDataNotifier, AppData>(
  AppDataNotifier.new,
);

class AppDataNotifier extends AsyncNotifier<AppData> {
  @override
  Future<AppData> build() async {
    final result = await ref.read(listRepositoryProvider).load();
    if (result.corrupted) {
      Future.microtask(() {
        ref.read(noticeProvider.notifier).show(Texte.dateiDefekt);
      });
    }
    return result.data;
  }

  AppData get _data => state.requireValue;

  Future<void> _store(AppData next) async {
    state = AsyncData(next);
    try {
      await ref.read(listRepositoryProvider).save(next);
    } catch (_) {
      ref.read(noticeProvider.notifier).show(Texte.speichernFehlgeschlagen);
    }
  }

  Future<void> putList(PackList list) => _store(
    _data.copyWith(lists: {..._data.lists, list.conditions.key: list}),
  );

  Future<void> removeList(String key) =>
      _store(_data.copyWith(lists: {..._data.lists}..remove(key)));

  /// Merkt sich ein eigenes Gewicht und traegt es in alle anderen Listen ein,
  /// denn es ist derselbe Gegenstand. Ohne eigenes Gewicht gilt [defaultG].
  Future<void> setCustomWeight(
    String itemId,
    int? weightG, {
    required int? defaultG,
    required String skipKey,
  }) {
    final weights = {..._data.customWeightsG};
    if (weightG == null) {
      weights.remove(itemId);
    } else {
      weights[itemId] = weightG;
    }
    final lists = {
      for (final MapEntry(:key, :value) in _data.lists.entries)
        key: key == skipKey
            ? value
            : value.copyWith(
                items: [
                  for (final i in value.items)
                    i.id == itemId
                        ? i.copyWith(weightG: () => weightG ?? defaultG)
                        : i,
                ],
              ),
    };
    return _store(_data.copyWith(lists: lists, customWeightsG: weights));
  }
}

String newId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

/// Die gerade geoeffnete Packliste. Jede Aenderung wird sofort gespeichert.
final currentListProvider = NotifierProvider<CurrentListNotifier, PackList?>(
  CurrentListNotifier.new,
);

class CurrentListNotifier extends Notifier<PackList?> {
  @override
  PackList? build() => null;

  ItemRepository get _repository =>
      ref.read(itemRepositoryProvider).requireValue;

  AppDataNotifier get _appData => ref.read(appDataProvider.notifier);

  PackList _fresh(ListConditions conditions) {
    final weights = ref.read(appDataProvider).requireValue.customWeightsG;
    return PackList(
      conditions: conditions,
      items: generateForConditions(_repository, conditions, weights),
    );
  }

  void open(ListConditions conditions) {
    final saved = ref.read(appDataProvider).requireValue.lists[conditions.key];
    // Namen und Kategorien folgen der aktuellen Sprache und Schreibweise.
    state = saved == null
        ? _fresh(conditions)
        : saved.copyWith(
            items: sortTripItems(
              saved.items.map(_repository.refresh),
              _repository.categories,
            ),
          );
  }

  Future<void> _apply(PackList next) {
    state = next;
    return _appData.putList(next);
  }

  Future<void> _setItems(List<TripItem> items) =>
      _apply(state!.copyWith(items: items));

  Future<void> setExtra(TripOption extra, bool enabled) => _apply(
    state!.copyWith(
      extras: enabled
          ? {...state!.extras, extra}
          : ({...state!.extras}..remove(extra)),
    ),
  );

  Future<void> togglePacked(String itemId) => _setItems([
    for (final i in state!.items) i.id == itemId ? i.togglePacked() : i,
  ]);

  Future<void> setStatus(String itemId, ItemStatus status) => _setItems([
    for (final i in state!.items)
      i.id == itemId ? i.copyWith(status: status) : i,
  ]);

  /// Nur Sichtbares; noch zu Kaufendes bleibt unberuehrt, es kann nicht
  /// eingepackt sein.
  Future<void> packAll() {
    final list = state!;
    final visible = visibleItems(
      list.items,
      list.extras,
      _repository,
    ).map((i) => i.id).toSet();
    return _setItems([
      for (final i in list.items)
        visible.contains(i.id) && i.status == ItemStatus.available
            ? i.copyWith(status: ItemStatus.packed)
            : i,
    ]);
  }

  Future<void> resetPacked() => _setItems([
    for (final i in state!.items)
      i.isPacked ? i.copyWith(status: ItemStatus.available) : i,
  ]);

  /// Verwirft alle Aenderungen an dieser Liste.
  Future<void> rebuild() {
    final conditions = state!.conditions;
    state = _fresh(conditions);
    return _appData.removeList(conditions.key);
  }

  /// Speichert einen neuen oder geaenderten Gegenstand. Ein geaendertes Gewicht
  /// eines Stammdaten-Gegenstands gilt auch fuer alle anderen Listen.
  Future<void> putItem(TripItem item) async {
    final items = state!.items;
    final index = items.indexWhere((i) => i.id == item.id);
    final weightChanged = index >= 0 && items[index].weightG != item.weightG;
    final saved = _setItems(
      sortTripItems([
        for (final i in items)
          if (i.id != item.id) i,
        item,
      ], _repository.categories),
    );
    final seed = _repository.byId(item.id);
    if (weightChanged && seed != null) {
      await _appData.setCustomWeight(
        item.id,
        item.weightG,
        defaultG: seed.defaultWeightG,
        skipKey: state!.conditions.key,
      );
    }
    await saved;
  }

  Future<void> removeItem(String itemId) => _setItems([
    for (final i in state!.items)
      if (i.id != itemId) i,
  ]);
}
