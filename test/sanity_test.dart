import 'package:flutter_test/flutter_test.dart';
import 'package:jyotish/jyotish.dart';

void main() {
  test('AstroNaksh Core Models & Constants Sanity', () {
    expect(Planet.traditionalPlanets.length, equals(7));
    expect(Rashi.values.length, equals(12));
    expect(Paksha.values.length, equals(2));
  });
}
