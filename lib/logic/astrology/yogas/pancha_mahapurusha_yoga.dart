import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class PanchaMahapurushaYogaDetector extends YogaDetector {
  @override
  String get id => 'pancha_mahapurusha_yoga';

  @override
  String get name => 'Pancha Mahapurusha Yoga';

  @override
  String get description =>
      'Formed when Mars (Ruchaka), Mercury (Bhadra), Jupiter (Hamsa), Venus (Malavya), or Saturn (Sasa) '
      'is in its own sign or exalted and in a Kendra from the Lagna.';

  @override
  List<Planet> get keyPlanets =>
      [Planet.mars, Planet.mercury, Planet.jupiter, Planet.venus, Planet.saturn];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final planets = {
      Planet.mars: 'Ruchaka Yoga',
      Planet.mercury: 'Bhadra Yoga',
      Planet.jupiter: 'Hamsa Yoga',
      Planet.venus: 'Malavya Yoga',
      Planet.saturn: 'Sasa Yoga',
    };

    final activePlanets = <Planet>[];
    final results = <String>[];
    final reasons = <String>[];

    for (final entry in planets.entries) {
      final planet = entry.key;
      final yogaName = entry.value;
      final info = chart.baseChart.planets[planet];

      if (info == null) continue;

      final isStrong = info.dignity == PlanetaryDignity.exalted ||
          info.dignity == PlanetaryDignity.ownSign;
      final isKendra = [1, 4, 7, 10].contains(info.house);

      if (isStrong && isKendra) {
        activePlanets.add(planet);
        results.add(yogaName);
        reasons.add(
            '$yogaName: ${planet.displayName} is in its ${info.dignity == PlanetaryDignity.exalted ? "Exaltation" : "Own"} sign in a Kendra (${info.house}th house)');
      }
    }

    if (activePlanets.isEmpty) {
      return BhangaResult.inactive(name);
    }

    final strength = 70.0 + (activePlanets.length * 5);

    return BhangaResult(
      name: activePlanets.length == 1 ? results.first : name,
      description: description,
      isActive: true,
      strength: strength.clamp(0, 100),
      status: strength >= 80 ? 'Strong' : 'Active',
      cancellationReasons: reasons,
      manifestationPeriod: 'Active during the Dashas of the participating Mahapurusha planets',
      peakDashaLord: activePlanets.first.displayName,
    );
  }
}
