import 'package:flutter_test/flutter_test.dart';
import 'package:jyotish/jyotish.dart';

void main() {
  group('Migration Verification Tests', () {
    test('Minimal Library Test', () {
      print('Checking Planet.sun...');
      expect(Planet.sun, isNotNull);
      print('Planet.sun: ${Planet.sun}');
    });
  });
}
