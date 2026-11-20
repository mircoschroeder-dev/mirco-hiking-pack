/// Auswerter fuer die Mengen-Ausdruecke aus items.json.
///
/// Erlaubt sind genau diese Formen (N, M: ganze Zahlen):
/// `N`, `days`, `days + N`, `days*N`, `ceil(days/N)`, `ceil(days/N) + M`,
/// `min(days, N)`, `min(ceil(days/N), M)`.
/// Alles andere wirft eine [FormatException].
class Quantity {
  Quantity._(this.source, this._evaluate);

  final String source;
  final int Function(int days) _evaluate;

  int evaluate(int days) => _evaluate(days);

  static final _number = RegExp(r'^\d+$');
  static final _daysPlus = RegExp(r'^days\+(\d+)$');
  static final _daysTimes = RegExp(r'^days\*(\d+)$');
  static final _ceil = RegExp(r'^ceil\(days/(\d+)\)$');
  static final _ceilPlus = RegExp(r'^ceil\(days/(\d+)\)\+(\d+)$');
  static final _minDays = RegExp(r'^min\(days,(\d+)\)$');
  static final _minCeil = RegExp(r'^min\(ceil\(days/(\d+)\),(\d+)\)$');

  factory Quantity.parse(String source) {
    final s = source.replaceAll(RegExp(r'\s'), '');

    if (_number.hasMatch(s)) {
      final n = int.parse(s);
      return Quantity._(source, (_) => n);
    }
    if (s == 'days') return Quantity._(source, (d) => d);

    int group(RegExpMatch m, int i) => int.parse(m.group(i)!);

    RegExpMatch? m;
    if ((m = _daysPlus.firstMatch(s)) != null) {
      final n = group(m!, 1);
      return Quantity._(source, (d) => d + n);
    }
    if ((m = _daysTimes.firstMatch(s)) != null) {
      final n = group(m!, 1);
      return Quantity._(source, (d) => d * n);
    }
    if ((m = _ceil.firstMatch(s)) != null) {
      final n = _divisor(group(m!, 1), source);
      return Quantity._(source, (d) => _ceilDiv(d, n));
    }
    if ((m = _ceilPlus.firstMatch(s)) != null) {
      final n = _divisor(group(m!, 1), source);
      final plus = group(m, 2);
      return Quantity._(source, (d) => _ceilDiv(d, n) + plus);
    }
    if ((m = _minDays.firstMatch(s)) != null) {
      final n = group(m!, 1);
      return Quantity._(source, (d) => d < n ? d : n);
    }
    if ((m = _minCeil.firstMatch(s)) != null) {
      final n = _divisor(group(m!, 1), source);
      final cap = group(m, 2);
      return Quantity._(source, (d) {
        final c = _ceilDiv(d, n);
        return c < cap ? c : cap;
      });
    }
    throw FormatException('Unbekannter Mengen-Ausdruck: "$source"');
  }

  static int _divisor(int n, String source) {
    if (n == 0) {
      throw FormatException(
        'Division durch null im Mengen-Ausdruck: "$source"',
      );
    }
    return n;
  }

  static int _ceilDiv(int a, int b) => (a + b - 1) ~/ b;
}
