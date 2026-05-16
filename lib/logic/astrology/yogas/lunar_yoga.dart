import 'package:jyotish/jyotish.dart';

import '../../../data/models.dart';
import '../extensions/chart_logic_extensions.dart';
import 'yoga_detector.dart';

class LunarYogaDetector implements YogaDetector {
  @override
  String get id => 'lunar_yoga';

  @override
  String get name => 'Lunar Yogas';

  @override
  String get description =>
      'Yogas formed based on planets relative to the Moon (Sunapha, Anapha, Durudhara, and Gauri). '
      'They represent various emotional and material strengths.';

  @override
  List<Planet> get keyPlanets => [Planet.moon];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final results = <String>[];
    final moonSign = chart.getPlanetSign('Moon');
    final secondFromMoon = (moonSign + 1) % 12;
    final twelfthFromMoon = (moonSign + 11) % 12;

    var hasSunapha = false;
    var hasAnapha = false;

    const visiblePlanets = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ];

    for (final p in visiblePlanets) {
      if (p == 'Sun' || p == 'Moon' || p == 'Rahu' || p == 'Ketu') continue;
      final sign = chart.getPlanetSign(p);
      if (sign == secondFromMoon) hasSunapha = true;
      if (sign == twelfthFromMoon) hasAnapha = true;
    }

    if (hasSunapha && hasAnapha) {
      results.add('Durudhara Yoga (Planets in 2nd and 12th from Moon)');
    } else if (hasSunapha) {
      results.add('Sunapha Yoga (Planet in 2nd from Moon)');
    } else if (hasAnapha) {
      results.add('Anapha Yoga (Planet in 12th from Moon)');
    }

    // Gauri Yoga (Moon exalted in Kendra/Trikona, aspected by Jupiter)
    if (chart.isExalted('Moon', moonSign) &&
        (chart.isPlanetInKendra('Moon') || chart.isPlanetInTrikona('Moon'))) {
      if (chart.areConjunct('Moon', 'Jupiter') ||
          chart.areOpposite('Jupiter', 'Moon') ||
          chart.isAspecting('Jupiter', 'Moon', [5, 9])) {
        results.add('Gauri Yoga (Exalted Moon aspected by Jupiter)');
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
      strength: results.length == 1 ? 50.0 : 85.0,
      cancellationReasons: results,
    );
  }
}
