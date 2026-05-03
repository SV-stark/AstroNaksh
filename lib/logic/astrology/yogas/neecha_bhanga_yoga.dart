import 'package:jyotish/jyotish.dart';

import '../../../data/models.dart';
import '../extensions/chart_logic_extensions.dart';
import 'yoga_detector.dart';

class NeechaBhangaYogaDetector implements YogaDetector {
  @override
  String get id => 'neecha_bhanga_yoga';

  @override
  String get name => 'Neecha Bhanga Raja Yoga';

  @override
  String get description =>
      'Formed when the debilitation of a planet is cancelled by specific planetary placements. '
      'It transforms a weak planet into a source of great power and success.';

  @override
  List<Planet> get keyPlanets => Planet.traditionalPlanets;

  @override
  BhangaResult detect(CompleteChartData chart) {
    final results = <String>[];
    
    final planets = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ];

    for (final planet in planets) {
      final sign = chart.getPlanetSign(planet);
      if (chart.isDebilitated(planet, sign)) {
        final cancellationReasons = _getCancellationReasons(chart, planet, sign);
        if (cancellationReasons.isNotEmpty) {
          results.add('Neecha Bhanga Raja Yoga ($planet: ${cancellationReasons.join(", ")})');
        }
      }
    }

    if (results.isEmpty) {
      return BhangaResult.inactive(name);
    }

    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      status: 'Active',
      strength: 90.0,
      cancellationReasons: results,
    );
  }

  List<String> _getCancellationReasons(CompleteChartData chart, String planet, int sign) {
    final reasons = <String>[];
    final debilSignLordIndex = chart.getSignLord(sign);
    final debilSignLord = Planet.values[debilSignLordIndex].name;
    final exaltSignLord = chart.getExaltationSignLord(planet);

    // 1. Lord of debilitation sign in Kendra from Lagna/Moon
    if (chart.isPlanetInKendra(debilSignLord)) {
      reasons.add('lord of debilitation sign in Kendra');
    }

    // 2. Lord of exaltation sign in Kendra
    if (exaltSignLord.isNotEmpty && chart.isPlanetInKendra(exaltSignLord)) {
      reasons.add('lord of exaltation sign in Kendra');
    }

    // 3. Debilitated planet aspected by its debilitation sign lord
    if (chart.isAspecting(debilSignLord, planet, [5, 7, 9]) ||
        chart.areConjunct(debilSignLord, planet)) {
      reasons.add('aspected by/conjunct with debilitation sign lord');
    }

    // 4. Conjunction with exalted planet or planet in own sign
    final otherPlanets = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ];

    for (final other in otherPlanets) {
      if (other == planet) continue;
      if (chart.areConjunct(planet, other)) {
        final otherSign = chart.getPlanetSign(other);
        if (chart.isExalted(other, otherSign)) {
          reasons.add('conjunct exalted $other');
          break;
        }
        if (chart.isOwnSign(other, otherSign)) {
          reasons.add('conjunct $other in own sign');
          break;
        }
      }
    }

    return reasons;
  }
}
