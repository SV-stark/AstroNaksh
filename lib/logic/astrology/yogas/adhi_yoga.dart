import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class AdhiYogaDetector extends YogaDetector {
  @override
  String get id => 'adhi_yoga';

  @override
  String get name => 'Adhi Yoga';

  @override
  String get description =>
      'Formed when benefic planets (Jupiter, Venus, Mercury) are situated in the 6th, 7th, or 8th houses from the Moon. '
      'It grants leadership, status, victory over enemies, and lasting prosperity.';

  @override
  List<Planet> get keyPlanets => [
    Planet.jupiter,
    Planet.venus,
    Planet.mercury,
    Planet.moon,
  ];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final moon = chart.baseChart.planets[Planet.moon];
    if (moon == null) return BhangaResult.inactive(name);

    final moonSign = moon.position.zodiacSignIndex;
    final targetHouses = [6, 7, 8];
    final activePlanets = <Planet>[];
    final reasons = <String>[];

    final benefics = [Planet.jupiter, Planet.venus, Planet.mercury];
    for (final planet in benefics) {
      final info = chart.baseChart.planets[planet];
      if (info == null) continue;

      final houseFromMoon =
          (info.position.zodiacSignIndex - moonSign + 12) % 12 + 1;
      if (targetHouses.contains(houseFromMoon)) {
        activePlanets.add(planet);
        reasons.add(
          '${planet.displayName} in the ${houseFromMoon}th house from Moon',
        );
      }
    }

    if (activePlanets.isEmpty) {
      return BhangaResult.inactive(name);
    }

    final strength = activePlanets.length * 30.0;

    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      strength: strength.clamp(0, 100),
      status: strength >= 80 ? 'Powerful' : 'Active',
      cancellationReasons: reasons,
      manifestationPeriod:
          'Active during the Dashas of the participating benefics',
      peakDashaLord: activePlanets.first.displayName,
    );
  }
}
