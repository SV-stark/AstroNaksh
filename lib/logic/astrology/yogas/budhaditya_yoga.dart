import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class BudhadityaYogaDetector extends YogaDetector {
  @override
  String get id => 'budhaditya_yoga';

  @override
  String get name => 'Budhaditya Yoga';

  @override
  String get description =>
      'Formed when the Sun and Mercury are in the same sign. '
      'It grants sharp intelligence, analytical skills, and professional success.';

  @override
  List<Planet> get keyPlanets => [Planet.sun, Planet.mercury];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final sun = chart.baseChart.planets[Planet.sun];
    final mercury = chart.baseChart.planets[Planet.mercury];

    if (sun == null || mercury == null) {
      return BhangaResult.inactive(name);
    }

    if (sun.position.zodiacSignIndex != mercury.position.zodiacSignIndex) {
      return BhangaResult.inactive(name);
    }

    // Strength calculation
    var strength = 50.0;
    final reasons = <String>[];

    // Check combustion (Mercury shouldn't be too close to Sun)
    final distance = (sun.longitude - mercury.longitude).abs();
    if (distance < 3.0) {
      strength -= 20.0;
      reasons.add('Mercury is deeply combust (within 3 degrees of Sun)');
    } else if (distance < 12.0) {
      strength += 10.0;
      reasons.add('Mercury is well-placed and not deeply combust');
    }

    if (mercury.dignity == PlanetaryDignity.exalted ||
        mercury.dignity == PlanetaryDignity.ownSign) {
      strength += 30.0;
      reasons.add('Mercury is strong (Exalted/Own Sign)');
    }

    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      strength: strength.clamp(0, 100),
      status: strength >= 70 ? 'Strong' : 'Active',
      cancellationReasons: reasons,
      manifestationPeriod: 'Active during Sun/Mercury Dasha',
      peakDashaLord: 'Mercury',
    );
  }
}
