import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class SaraswatiYogaDetector extends YogaDetector {
  @override
  String get id => 'saraswati_yoga';

  @override
  String get name => 'Saraswati Yoga';

  @override
  String get description =>
      'Formed when Jupiter, Venus, and Mercury are in Kendra, Trikona, or 2nd house, and Jupiter is strong. '
      'It grants excellence in education, arts, music, and wisdom.';

  @override
  List<Planet> get keyPlanets => [Planet.jupiter, Planet.venus, Planet.mercury];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final benefics = [Planet.jupiter, Planet.venus, Planet.mercury];
    final activePlanets = <Planet>[];
    final reasons = <String>[];

    for (final planet in benefics) {
      final info = chart.baseChart.planets[planet];
      if (info == null) continue;

      final house = info.house;
      if ([1, 2, 4, 5, 7, 9, 10].contains(house)) {
        activePlanets.add(planet);
        reasons.add('${planet.displayName} in ${house}th house');
      }
    }

    final jup = chart.baseChart.planets[Planet.jupiter];
    final isJupStrong =
        jup != null &&
        (jup.dignity == PlanetaryDignity.exalted ||
            jup.dignity == PlanetaryDignity.ownSign ||
            jup.dignity == PlanetaryDignity.greatFriend);

    if (activePlanets.length == 3 && isJupStrong) {
      const strength = 80.0;
      return BhangaResult(
        name: name,
        description: description,
        isActive: true,
        strength: strength,
        status: 'Strong',
        cancellationReasons: reasons,
        manifestationPeriod:
            'Active during Dashas of Mercury, Jupiter, or Venus',
        peakDashaLord: Planet.jupiter.displayName,
      );
    }

    return BhangaResult.inactive(name);
  }
}
