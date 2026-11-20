import 'models.dart';

WeightSummary summarizeWeights(Iterable<TripItem> items) {
  var base = 0, consumable = 0, worn = 0, withoutWeight = 0;
  for (final item in items) {
    if (item.isLeft) continue;
    switch (item.weightType) {
      case WeightType.base:
        base += item.totalWeightG;
      case WeightType.consumable:
        consumable += item.totalWeightG;
      case WeightType.worn:
        worn += item.totalWeightG;
    }
    if (!item.hasWeight) withoutWeight++;
  }
  return WeightSummary(
    baseG: base,
    consumableG: consumable,
    wornG: worn,
    itemsWithoutWeight: withoutWeight,
  );
}

/// Gramm als Kilogramm-Text mit einer Nachkommastelle, z. B. "2,6 kg".
String formatKg(int grams, {String decimalSeparator = ','}) =>
    '${(grams / 1000).toStringAsFixed(1).replaceAll('.', decimalSeparator)} kg';
