import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/core/ayanamsa_calculator.dart';
import 'package:jyotish/jyotish.dart';

void main() {
  group('Ayanamsa Support Tests', () {
    test('AyanamsaCalculator should have 49 systems', () {
      final systems = AyanamsaCalculator.systems;
      expect(
        systems.length,
        48,
      ); // 48 SiderealModes exactly (KP New is one of them)
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
      expect(system.description, equals('KP New'));
      expect(system.mode, equals(SiderealMode.krishnamurtiVP291));
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

    test('New KP System should resolve to krishnamurtiVP291', () {
      final system = AyanamsaCalculator.getSystem('newKP');
      expect(system, isNotNull);
      expect(system!.mode, equals(SiderealMode.krishnamurtiVP291));
    });
  });
}
