import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/core/ayanamsa_calculator.dart';
import 'package:jyotish/jyotish.dart';

void main() {
  group('Ayanamsa Support Tests', () {
    test('AyanamsaCalculator should have 49 systems', () {
      final systems = AyanamsaCalculator.systems;
      expect(systems.length, 49); // 48 SiderealModes + New KP
    });

    test('Default Ayanamsa should be New KP', () {
      expect(AyanamsaCalculator.defaultAyanamsa, equals('newKP'));
    });

    test('Should be able to get system by name', () {
      final system = AyanamsaCalculator.getSystem('raman');
      expect(system, isNotNull);
      expect(system!.name, equals('Raman'));
      expect(system.mode, equals(SiderealMode.raman));
    });

    test('Should be able to get New KP system', () {
      final system = AyanamsaCalculator.getSystem('newKP');
      expect(system, isNotNull);
      expect(system!.name, equals('newKP'));
      expect(system.description, equals('New KP'));
      expect(system.mode, isNull);
    });

    test('Old KP should be renamed', () {
      final system = AyanamsaCalculator.getSystem('krishnamurti');
      expect(system, isNotNull);
      expect(system!.description, equals('KP Old'));
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

    test('New KP Calculation should be accurate at J2000', () {
      // J2000 value is 23° 33' 03"
      final j2000 = DateTime.utc(2000, 1, 1, 12, 0, 0);
      final ayanamsa = AyanamsaCalculator.calculateNewKPAyanamsa(j2000);

      final expectedWithoutSeconds = 23 + (33 / 60);
      final expected = expectedWithoutSeconds + (3 / 3600);

      expect(ayanamsa, closeTo(expected, 0.0001));
    });
  });
}
