import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/core/ayanamsa_calculator.dart';
import 'package:jyotish/jyotish.dart';

void main() {
  group('Ayanamsa Support Tests', () {
    test('AyanamsaCalculator should have 43 systems', () {
      final systems = AyanamsaCalculator.systems;
      expect(systems.length, 43); // Based on SiderealMode having 43 entries
    });

    test('Default Ayanamsa should be Lahiri', () {
      expect(AyanamsaCalculator.defaultAyanamsa, equalsIgnoringCase('lahiri'));
    });

    test('Should be able to get system by name', () {
      final system = AyanamsaCalculator.getSystem('raman');
      expect(system, isNotNull);
      expect(system!.name, equals('raman'));
      expect(system.mode, equals(SiderealMode.raman));
    });

    test('Should return null for invalid system', () {
      final system = AyanamsaCalculator.getSystem('invalid_system_name');
      expect(system, isNull);
    });

    test('SiderealMode names should act as keys', () {
      // Verify that we can resolve every mode from string
      for (var mode in SiderealMode.values) {
        final system = AyanamsaCalculator.getSystem(mode.name);
        expect(system, isNotNull, reason: 'Could not resolve ${mode.name}');
        expect(system!.mode, equals(mode));
      }
    });
  });
}
