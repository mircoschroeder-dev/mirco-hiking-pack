import 'package:packliste_core/conditions.dart';
import 'package:packliste_core/models.dart';

/// Die Packliste zu einer Kombination von Bedingungen. [items] enthaelt auch
/// die Gegenstaende ausgeschalteter Extras; sie werden nur nicht angezeigt.
class PackList {
  const PackList({
    required this.conditions,
    required this.items,
    this.extras = const {},
  });

  final ListConditions conditions;
  final Set<TripOption> extras;
  final List<TripItem> items;

  PackList copyWith({Set<TripOption>? extras, List<TripItem>? items}) =>
      PackList(
        conditions: conditions,
        extras: extras ?? this.extras,
        items: items ?? this.items,
      );

  Map<String, dynamic> toJson() => {
    'conditions': conditions.toJson(),
    'extras': extras.map((e) => e.name).toList(),
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory PackList.fromJson(Map<String, dynamic> json) => PackList(
    conditions: ListConditions.fromJson(
      json['conditions'] as Map<String, dynamic>,
    ),
    extras: (json['extras'] as List)
        .map((e) => TripOption.values.byName(e as String))
        .toSet(),
    items: (json['items'] as List)
        .map((e) => TripItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// Alles, was dauerhaft gespeichert wird.
class AppData {
  const AppData({this.lists = const {}, this.customWeightsG = const {}});

  /// Je Bedingungs-Kombination ([ListConditions.key]) eine Liste.
  final Map<String, PackList> lists;
  final Map<String, int> customWeightsG;

  AppData copyWith({
    Map<String, PackList>? lists,
    Map<String, int>? customWeightsG,
  }) => AppData(
    lists: lists ?? this.lists,
    customWeightsG: customWeightsG ?? this.customWeightsG,
  );

  Map<String, dynamic> toJson() => {
    'schemaVersion': 2,
    'lists': lists.values.map((l) => l.toJson()).toList(),
    'customWeightsG': customWeightsG,
  };

  /// Staende der frueheren Version enthalten `tours` statt `lists`. Die Touren
  /// entfallen bewusst, die eigenen Gewichte bleiben.
  factory AppData.fromJson(Map<String, dynamic> json) {
    final lists = ((json['lists'] ?? const []) as List).map(
      (e) => PackList.fromJson(e as Map<String, dynamic>),
    );
    return AppData(
      lists: {for (final l in lists) l.conditions.key: l},
      customWeightsG: (json['customWeightsG'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as int),
      ),
    );
  }
}
