import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class ChandraMangalaYogaDetector extends YogaDetector {
  @override
  String get id => 'chandra_mangala_yoga';

  @override
  String get name => 'Chandra Mangala Yoga';

  @override
  String get description =>
      'Formed when the Moon and Mars are in conjunction (same sign). '
      'It creates a energetic personality, financial gains, and strong willpower, '
      'though it can also indicate some impulsiveness.';

  @override
  List<Planet> get keyPlanets => [Planet.moon, Planet.mars];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final moon = chart.baseChart.planets[Planet.moon];
    final mars = chart.baseChart.planets[Planet.mars];

    if (moon == null || mars == null) {
      return BhangaResult.inactive(name);
    }

    if (moon.position.zodiacSignIndex != mars.position.zodiacSignIndex) {
      return BhangaResult.inactive(name);
    }

    // Strength calculation
    var strength = 60.0;
    final reasons = <String>[];

    if (mars.dignity == PlanetaryDignity.exalted ||
        mars.dignity == PlanetaryDignity.ownSign) {
      strength += 30.0;
      reasons.add('Mars is strong (Exalted/Own Sign)');
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
      manifestationPeriod: 'Active during Moon/Mars Dasha',
      peakDashaLord: 'Mars',
    );
  }
}
