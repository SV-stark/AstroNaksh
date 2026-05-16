import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class AmalaYogaDetector extends YogaDetector {
  @override
  String get id => 'amala_yoga';

  @override
  String get name => 'Amala Yoga';

  @override
  String get description =>
      'Formed when a benefic planet is situated in the 10th house from either the Lagna or the Moon. '
      'It indicates a spotless reputation, professional success, and virtuous conduct.';

  @override
  List<Planet> get keyPlanets => [
    Planet.jupiter,
    Planet.venus,
    Planet.mercury,
    Planet.moon,
  ];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final benefics = [Planet.jupiter, Planet.venus, Planet.mercury];
    final activePlanets = <Planet>[];
    final reasons = <String>[];

    // Check from Lagna (10th house)
    for (final planet in benefics) {
      final info = chart.baseChart.planets[planet];
      if (info != null && info.house == 10) {
        activePlanets.add(planet);
        reasons.add('${planet.displayName} in the 10th house from Lagna');
      }
    }

    // Check from Moon (10th house)
    final moon = chart.baseChart.planets[Planet.moon];
    if (moon != null) {
      final moonSign = moon.position.zodiacSignIndex;
      for (final planet in benefics) {
        final info = chart.baseChart.planets[planet];
        if (info == null) continue;
        final houseFromMoon =
            (info.position.zodiacSignIndex - moonSign + 12) % 12 + 1;
        if (houseFromMoon == 10) {
          if (!activePlanets.contains(planet)) {
            activePlanets.add(planet);
            reasons.add('${planet.displayName} in the 10th house from Moon');
          }
        }
      }
    }

    if (activePlanets.isEmpty) {
      return BhangaResult.inactive(name);
    }

    final strength = 60.0 + (activePlanets.length * 10);

    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      strength: strength.clamp(0, 100),
      status: strength >= 80 ? 'Strong' : 'Active',
      cancellationReasons: reasons,
      manifestationPeriod:
          'Active during the Dasha of the participating benefic in 10th',
      peakDashaLord: activePlanets.first.displayName,
    );
  }
}
