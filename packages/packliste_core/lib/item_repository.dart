import 'dart:convert';

import 'models.dart';

/// Haelt die Stammdaten aus items.json, auf Wunsch mit englischen Namen aus
/// items_en.json. Das Einlesen der Dateien ist Sache des Aufrufers, damit das
/// Package ohne Flutter auskommt.
class ItemRepository {
  ItemRepository._(
    this.categories,
    this.items,
    this._knownNames,
    this._categoryAliases,
  ) : _byId = {for (final i in items) i.id: i};

  final List<String> categories;
  final List<Item> items;
  final Map<String, Item> _byId;

  /// Alle Standardnamen je Gegenstand, in jeder Sprache und Schreibweise.
  final Map<String, Set<String>> _knownNames;

  /// Jede bekannte Schreibweise einer Kategorie auf die aktuelle.
  final Map<String, String> _categoryAliases;

  Item? byId(String id) => _byId[id];

  /// Wirft eine [FormatException] bei unbekannten Ausdruecken, Enum-Werten,
  /// Kategorien oder einer unvollstaendigen Uebersetzung.
  ///
  /// [translations] ist der Inhalt von items_en.json. Mit [english] werden
  /// dessen Namen verwendet, sonst die deutschen.
  factory ItemRepository.fromJsonString(
    String source, {
    String? translations,
    bool english = false,
  }) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    var categories = (json['categories'] as List).cast<String>();
    var items = (json['items'] as List)
        .map((e) => Item.fromJson(e as Map<String, dynamic>))
        .toList();
    for (final item in items) {
      if (!categories.contains(item.category)) {
        throw FormatException(
          'Unbekannte Kategorie bei "${item.id}": "${item.category}"',
        );
      }
    }

    final knownNames = {
      for (final i in items) i.id: {i.name, _ascii(i.name), ...i.formerNames},
    };
    final categoryNames = {
      for (final c in categories) c: {c, _ascii(c)},
    };

    if (translations != null) {
      final en = jsonDecode(translations) as Map<String, dynamic>;
      final enCategories = (en['categories'] as Map<String, dynamic>)
          .cast<String, String>();
      final enItems = (en['items'] as Map<String, dynamic>)
          .cast<String, String>();
      for (final c in categories) {
        if (!enCategories.containsKey(c)) {
          throw FormatException('Keine Uebersetzung fuer Kategorie "$c"');
        }
        categoryNames[c]!.add(enCategories[c]!);
      }
      for (final i in items) {
        if (!enItems.containsKey(i.id)) {
          throw FormatException('Keine Uebersetzung fuer "${i.id}"');
        }
        knownNames[i.id]!.add(enItems[i.id]!);
      }
      if (english) {
        items = [
          for (final i in items)
            i.withText(
              name: enItems[i.id]!,
              category: enCategories[i.category]!,
            ),
        ];
        final germanCategories = categories;
        categories = [for (final c in categories) enCategories[c]!];
        for (var k = 0; k < germanCategories.length; k++) {
          categoryNames[categories[k]] = categoryNames.remove(
            germanCategories[k],
          )!;
        }
      }
    }

    return ItemRepository._(categories, items, knownNames, {
      for (final MapEntry(key: current, value: names) in categoryNames.entries)
        for (final name in names) name: current,
    });
  }

  /// Zieht Kategorie und unveraenderten Standardnamen eines gespeicherten
  /// Gegenstands auf die aktuelle Sprache und Schreibweise nach. Ein vom
  /// Nutzer geaenderter Name bleibt erhalten.
  TripItem refresh(TripItem item) {
    final seed = byId(item.id);
    if (seed == null) {
      final category = _categoryAliases[item.category];
      return category == null ? item : item.copyWith(category: category);
    }
    final known = _knownNames[item.id]!.contains(item.name);
    return item.copyWith(
      name: known ? seed.name : null,
      category: seed.category,
    );
  }
}

String _ascii(String text) => text
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('Ä', 'Ae')
    .replaceAll('Ö', 'Oe')
    .replaceAll('Ü', 'Ue')
    .replaceAll('ß', 'ss');
