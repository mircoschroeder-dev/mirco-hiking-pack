import 'item_repository.dart';
import 'models.dart';

class PacklistGenerator {
  const PacklistGenerator(this.repository);

  final ItemRepository repository;

  List<TripItem> generateList(TripConfig config) {
    final byId = <String, TripItem>{};
    for (final item in repository.items) {
      if (!item.rule.matches(config)) continue;
      final quantity = item.rule.quantity.evaluate(config.days);
      final existing = byId[item.id];
      if (existing != null && existing.quantity >= quantity) continue;
      byId[item.id] = TripItem(
        id: item.id,
        name: item.name,
        category: item.category,
        quantity: quantity,
        weightType: item.weightType,
        weightG: config.customWeightsG[item.id] ?? item.defaultWeightG,
        essential: item.essential,
      );
    }
    return sortTripItems(byId.values, repository.categories);
  }
}

/// Nach Kategorie-Reihenfolge; je Kategorie essential zuerst, dann alphabetisch.
/// Kategorien ausserhalb von [categories] stehen am Ende.
List<TripItem> sortTripItems(
  Iterable<TripItem> items,
  List<String> categories,
) {
  int rank(TripItem item) {
    final i = categories.indexOf(item.category);
    return i < 0 ? categories.length : i;
  }

  return items.toList()..sort((a, b) {
    final byCategory = rank(a).compareTo(rank(b));
    if (byCategory != 0) return byCategory;
    if (a.essential != b.essential) return a.essential ? -1 : 1;
    return _sortKey(a.name).compareTo(_sortKey(b.name));
  });
}

String _sortKey(String name) => name
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss');
