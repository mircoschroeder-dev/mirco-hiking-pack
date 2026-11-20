import 'package:packliste_core/quantity.dart';
import 'package:test/test.dart';

void main() {
  int eval(String expression, int days) =>
      Quantity.parse(expression).evaluate(days);

  test('1', () => expect(eval('1', 7), 1));
  test('2', () => expect(eval('2', 7), 2));
  test('3', () => expect(eval('3', 7), 3));

  test('days', () {
    expect(eval('days', 1), 1);
    expect(eval('days', 21), 21);
  });

  test('days + 1', () {
    expect(eval('days + 1', 1), 2);
    expect(eval('days + 1', 21), 22);
  });

  test('days*2', () {
    expect(eval('days*2', 1), 2);
    expect(eval('days*2', 21), 42);
  });

  test('ceil(days/2)', () {
    expect(eval('ceil(days/2)', 1), 1);
    expect(eval('ceil(days/2)', 2), 1);
    expect(eval('ceil(days/2)', 3), 2);
    expect(eval('ceil(days/2)', 21), 11);
  });

  test('ceil(days/3)', () {
    expect(eval('ceil(days/3)', 1), 1);
    expect(eval('ceil(days/3)', 3), 1);
    expect(eval('ceil(days/3)', 4), 2);
    expect(eval('ceil(days/3)', 21), 7);
  });

  test('ceil(days/4)', () {
    expect(eval('ceil(days/4)', 1), 1);
    expect(eval('ceil(days/4)', 4), 1);
    expect(eval('ceil(days/4)', 5), 2);
    expect(eval('ceil(days/4)', 21), 6);
  });

  test('min(days, 4)', () {
    expect(eval('min(days, 4)', 1), 1);
    expect(eval('min(days, 4)', 4), 4);
    expect(eval('min(days, 4)', 21), 4);
  });

  test('min(ceil(days/2), 3)', () {
    expect(eval('min(ceil(days/2), 3)', 1), 1);
    expect(eval('min(ceil(days/2), 3)', 5), 3);
    expect(eval('min(ceil(days/2), 3)', 21), 3);
  });

  test('ceil(days/2) + 1', () {
    expect(eval('ceil(days/2) + 1', 1), 2);
    expect(eval('ceil(days/2) + 1', 4), 3);
    expect(eval('ceil(days/2) + 1', 21), 12);
  });

  test('unbekannte Ausdruecke werfen statt 1 anzunehmen', () {
    for (final bad in [
      '',
      'x',
      'days - 1',
      'days/2',
      'floor(days/2)',
      'max(days, 2)',
      'days*days',
      'ceil(days/0)',
      'min(ceil(days/0), 3)',
    ]) {
      expect(() => Quantity.parse(bad), throwsFormatException, reason: bad);
    }
  });
}
