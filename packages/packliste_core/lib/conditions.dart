import 'generator.dart';
import 'item_repository.dart';
import 'models.dart';

enum TripLength { day, short, week, long }

enum Season { spring, summer, autumn, winter }

enum Weather { dry, rainRisk }

/// Extras blenden ihre Gegenstaende nur ein oder aus. Sie erzeugen keine
/// eigene Liste.
const allExtras = {
  TripOption.photo,
  TripOption.cooking,
  TripOption.dog,
  TripOption.nopower,
};

/// Die Bedingungen einer Packliste. Jede Kombination ist genau eine Liste.
class ListConditions {
  const ListConditions({
    required this.length,
    required bool withTent,
    required this.season,
    required this.weather,
  }) : withTent = length != TripLength.day && withTent;

  final TripLength length;
  final bool withTent;
  final Season season;
  final Weather weather;

  String get key =>
      '${length.name}_${withTent ? 'tent' : 'noTent'}_${season.name}_${weather.name}';

  /// Bei einem Zeitraum zaehlt der laengste Fall, damit nichts fehlt.
  int get days => switch (length) {
    TripLength.day => 1,
    TripLength.short => 3,
    TripLength.week => 7,
    TripLength.long => 21,
  };

  TourType get tourType => length == TripLength.day
      ? TourType.day
      : (withTent ? TourType.tent : TourType.hut);

  TempBand get tempBand => switch (season) {
    Season.summer => TempBand.warm,
    Season.spring || Season.autumn => TempBand.mild,
    Season.winter => TempBand.frost,
  };

  /// Enthaelt alle Extras: Ihre Gegenstaende liegen immer in der Liste und
  /// behalten so ihren Stand, wenn man ein Extra aus- und wieder einschaltet.
  TripConfig toTripConfig([Map<String, int> customWeightsG = const {}]) =>
      TripConfig(
        tourType: tourType,
        days: days,
        tempBand: tempBand,
        options: {
          ...allExtras,
          if (weather == Weather.rainRisk) TripOption.rain,
        },
        customWeightsG: customWeightsG,
      );

  Map<String, dynamic> toJson() => {
    'length': length.name,
    'withTent': withTent,
    'season': season.name,
    'weather': weather.name,
  };

  factory ListConditions.fromJson(Map<String, dynamic> json) => ListConditions(
    length: TripLength.values.byName(json['length'] as String),
    withTent: json['withTent'] as bool,
    season: Season.values.byName(json['season'] as String),
    weather: Weather.values.byName(json['weather'] as String),
  );
}

/// Auf langen Touren wird unterwegs eingekauft: Mitgetragen wird Proviant
/// fuer diese Anzahl Tage, nicht fuer die ganze Tour.
const longTripProvisionDays = 3;
const _provisionIds = {'verpflegung', 'snacks', 'hundefutter'};

List<TripItem> generateForConditions(
  ItemRepository repository,
  ListConditions conditions, [
  Map<String, int> customWeightsG = const {},
]) {
  final items = PacklistGenerator(
    repository,
  ).generateList(conditions.toTripConfig(customWeightsG));
  if (conditions.length != TripLength.long) return items;
  return [
    for (final item in items)
      _provisionIds.contains(item.id)
          ? item.copyWith(
              quantity: repository
                  .byId(item.id)!
                  .rule
                  .quantity
                  .evaluate(longTripProvisionDays),
            )
          : item,
  ];
}

Set<TripOption> _requiredExtras(TripItem item, ItemRepository repository) {
  final seed = repository.byId(item.id);
  if (seed == null) return const {};
  return seed.rule.requiresOptions.where(allExtras.contains).toSet();
}

/// Selbst hinzugefuegte Gegenstaende sind immer sichtbar.
List<TripItem> visibleItems(
  Iterable<TripItem> items,
  Set<TripOption> extras,
  ItemRepository repository,
) => items
    .where((i) => _requiredExtras(i, repository).every(extras.contains))
    .toList();

/// Nur Extras, die in dieser Liste wirklich etwas aendern.
Set<TripOption> availableExtras(
  Iterable<TripItem> items,
  ItemRepository repository,
) => {for (final i in items) ..._requiredExtras(i, repository)};
