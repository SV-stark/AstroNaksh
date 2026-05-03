import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class GajakesariYogaDetector extends YogaDetector {
  @override
  String get id => 'gajakesari_yoga';

  @override
  String get name => 'Gajakesari Yoga';

  @override
  String get description =>
      'Occurs when Jupiter is in a Kendra (1st, 4th, 7th, or 10th house) from the Moon. '
      'It brings wealth, intelligence, and lasting fame.';

  @override
  List<Planet> get keyPlanets => [Planet.jupiter, Planet.moon];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final moon = chart.baseChart.planets[Planet.moon];
    final jupiter = chart.baseChart.planets[Planet.jupiter];

    if (moon == null || jupiter == null) {
      return BhangaResult.inactive(name);
    }

    final moonSign = moon.position.zodiacSignIndex;
    final jupiterSign = jupiter.position.zodiacSignIndex;

    // Kendra check (1, 4, 7, 10 signs away)
    final distance = (jupiterSign - moonSign + 12) % 12 + 1;
    final isKendra = [1, 4, 7, 10].contains(distance);

    if (!isKendra) {
      return BhangaResult.inactive(name);
    }

    // Strength calculation
    var strength = 60.0;
    final reasons = <String>[];

    if (jupiter.dignity == PlanetaryDignity.exalted) {
      strength += 40.0;
      reasons.add('Jupiter is exalted');
    } else if (jupiter.dignity == PlanetaryDignity.ownSign) {
      strength += 20.0;
      reasons.add('Jupiter is in its own sign');
    }

    if (moon.dignity == PlanetaryDignity.exalted) {
      strength += 10.0;
      reasons.add('Moon is exalted');
    }

    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      strength: strength.clamp(0, 100),
      status: strength >= 80 ? 'Strong' : 'Active',
      cancellationReasons: reasons,
      manifestationPeriod: 'Active during Jupiter/Moon Dasha',
      peakDashaLord: 'Jupiter',
    );
  }
}
