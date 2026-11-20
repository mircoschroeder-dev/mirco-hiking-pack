import 'quantity.dart';

enum TourType { day, hut, tent }

enum TempBand { warm, mild, cold, frost }

enum TripOption { rain, photo, cooking, dog, nopower }

enum WeightType { base, consumable, worn }

enum ItemStatus { available, toBuy, packed, left }

T _enumByName<T extends Enum>(List<T> values, Object? name, String field) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  throw FormatException('Unbekannter Wert fuer $field: "$name"');
}

List<T> _enumList<T extends Enum>(List<T> values, Object? raw, String field) =>
    ((raw ?? const []) as List)
        .map((e) => _enumByName(values, e, field))
        .toList();

class Rule {
  const Rule({
    required this.tourTypes,
    required this.tempBands,
    required this.quantity,
    this.requiresOptions = const [],
    this.minDays,
    this.maxDays,
  });

  final List<TourType> tourTypes;
  final List<TempBand> tempBands;
  final List<TripOption> requiresOptions;
  final int? minDays;
  final int? maxDays;
  final Quantity quantity;

  factory Rule.fromJson(Map<String, dynamic> json) => Rule(
    tourTypes: _enumList(TourType.values, json['tourTypes'], 'tourTypes'),
    tempBands: _enumList(TempBand.values, json['tempBands'], 'tempBands'),
    requiresOptions: _enumList(
      TripOption.values,
      json['requiresOptions'],
      'requiresOptions',
    ),
    minDays: json['minDays'] as int?,
    maxDays: json['maxDays'] as int?,
    quantity: Quantity.parse(json['quantity'] as String),
  );

  bool matches(TripConfig config) =>
      tourTypes.contains(config.tourType) &&
      tempBands.contains(config.tempBand) &&
      (minDays == null || config.days >= minDays!) &&
      (maxDays == null || config.days <= maxDays!) &&
      requiresOptions.every(config.options.contains);
}

class Item {
  const Item({
    required this.id,
    required this.name,
    required this.category,
    required this.weightType,
    required this.rule,
    this.defaultWeightG,
    this.perDay = false,
    this.perDayFactorG,
    this.essential = false,
    this.searchQuery,
    this.formerNames = const [],
  });

  final String id;
  final String name;
  final String category;

  /// Fruehere Standardnamen, damit gespeicherte Listen nachgezogen werden.
  final List<String> formerNames;
  final int? defaultWeightG;
  final WeightType weightType;
  final bool perDay;
  final int? perDayFactorG;
  final bool essential;
  final String? searchQuery;
  final Rule rule;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    defaultWeightG: json['defaultWeightG'] as int?,
    weightType: _enumByName(
      WeightType.values,
      json['weightType'],
      'weightType',
    ),
    perDay: json['perDay'] as bool? ?? false,
    perDayFactorG: json['perDayFactorG'] as int?,
    essential: json['essential'] as bool? ?? false,
    searchQuery: json['searchQuery'] as String?,
    formerNames: ((json['formerNames'] ?? const []) as List).cast<String>(),
    rule: Rule.fromJson(json['rule'] as Map<String, dynamic>),
  );

  Item withText({required String name, required String category}) => Item(
    id: id,
    name: name,
    category: category,
    formerNames: formerNames,
    defaultWeightG: defaultWeightG,
    weightType: weightType,
    perDay: perDay,
    perDayFactorG: perDayFactorG,
    essential: essential,
    searchQuery: searchQuery,
    rule: rule,
  );
}

class TripConfig {
  const TripConfig({
    required this.tourType,
    required this.days,
    required this.tempBand,
    this.options = const {},
    this.customWeightsG = const {},
  });

  final TourType tourType;
  final int days;
  final TempBand tempBand;
  final Set<TripOption> options;

  /// Eigene Gewichte des Nutzers je Gegenstands-ID.
  final Map<String, int> customWeightsG;

  Map<String, dynamic> toJson() => {
    'tourType': tourType.name,
    'days': days,
    'tempBand': tempBand.name,
    'options': options.map((o) => o.name).toList(),
  };

  factory TripConfig.fromJson(Map<String, dynamic> json) => TripConfig(
    tourType: _enumByName(TourType.values, json['tourType'], 'tourType'),
    days: json['days'] as int,
    tempBand: _enumByName(TempBand.values, json['tempBand'], 'tempBand'),
    options: _enumList(TripOption.values, json['options'], 'options').toSet(),
  );
}

/// Eine Zeile der Packliste. [weightG] ist das Gewicht eines einzelnen Stuecks.
class TripItem {
  const TripItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.weightType,
    this.weightG,
    this.essential = false,
    this.note = '',
    this.status = ItemStatus.available,
  });

  final String id;
  final String name;
  final String category;
  final int quantity;
  final WeightType weightType;
  final int? weightG;
  final bool essential;
  final String note;
  final ItemStatus status;

  int get totalWeightG => quantity * (weightG ?? 0);

  bool get hasWeight => weightG != null && weightG != 0;

  bool get isPacked => status == ItemStatus.packed;

  /// Nicht mitgenommen: zaehlt weder beim Gewicht noch beim Packfortschritt.
  bool get isLeft => status == ItemStatus.left;

  /// Abhaken. Etwas Ausgepacktes ist danach vorhanden, auch wenn es vorher
  /// noch gekauft werden musste.
  TripItem togglePacked() => isLeft
      ? this
      : copyWith(status: isPacked ? ItemStatus.available : ItemStatus.packed);

  TripItem copyWith({
    String? name,
    String? category,
    int? quantity,
    WeightType? weightType,
    int? Function()? weightG,
    String? note,
    ItemStatus? status,
  }) => TripItem(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    quantity: quantity ?? this.quantity,
    weightType: weightType ?? this.weightType,
    weightG: weightG != null ? weightG() : this.weightG,
    essential: essential,
    note: note ?? this.note,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'quantity': quantity,
    'weightType': weightType.name,
    'weightG': weightG,
    'essential': essential,
    'note': note,
    'status': status.name,
  };

  factory TripItem.fromJson(Map<String, dynamic> json) => TripItem(
    id: json['id'] as String,
    name: json['name'] as String,
    category: json['category'] as String,
    quantity: json['quantity'] as int,
    weightType: _enumByName(
      WeightType.values,
      json['weightType'],
      'weightType',
    ),
    weightG: json['weightG'] as int?,
    essential: json['essential'] as bool? ?? false,
    note: json['note'] as String? ?? '',
    // Aeltere Speicherstaende kennen nur das Feld `packed`.
    status: json['status'] != null
        ? _enumByName(ItemStatus.values, json['status'], 'status')
        : (json['packed'] == true ? ItemStatus.packed : ItemStatus.available),
  );
}

class WeightSummary {
  const WeightSummary({
    required this.baseG,
    required this.consumableG,
    required this.wornG,
    required this.itemsWithoutWeight,
  });

  final int baseG;
  final int consumableG;
  final int wornG;
  final int itemsWithoutWeight;

  /// Rucksack beim Start: Basis + Verbrauch. Getragenes zaehlt nicht mit.
  int get packStartG => baseG + consumableG;
}
