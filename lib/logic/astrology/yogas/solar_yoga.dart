import 'package:jyotish/jyotish.dart';

import '../../../data/models.dart';
import '../extensions/chart_logic_extensions.dart';
import 'yoga_detector.dart';

class SolarYogaDetector implements YogaDetector {
  @override
  String get id => 'solar_yoga';

  @override
  String get name => 'Solar Yogas';

  @override
  String get description =>
      'Yogas formed by planets in 2nd or 12th house from the Sun (Vesi, Vasi, and Ubhayachari). '
      'They indicate wealth, status, and various life comforts.';

  @override
  List<Planet> get keyPlanets => [Planet.sun];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final results = <String>[];
    final sunSign = chart.getPlanetSign('Sun');
    final secondFromSun = (sunSign + 1) % 12;
    final twelfthFromSun = (sunSign + 11) % 12;

    var hasVesi = false;
    var hasVasi = false;

    const visiblePlanets = [
      'Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn'
    ];

    for (final p in visiblePlanets) {
      if (p == 'Sun' || p == 'Moon' || p == 'Rahu' || p == 'Ketu') continue;
      final sign = chart.getPlanetSign(p);
      if (sign == secondFromSun) hasVesi = true;
      if (sign == twelfthFromSun) hasVasi = true;
    }

    if (hasVesi && hasVasi) {
      results.add('Ubhayachari Yoga (Planets in 2nd and 12th from Sun)');
    } else if (hasVesi) {
      results.add('Vesi Yoga (Planet in 2nd from Sun)');
    } else if (hasVasi) {
      results.add('Vasi Yoga (Planet in 12th from Sun)');
    }

    if (results.isEmpty) {
      return BhangaResult.inactive(name);
    }

    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      status: 'Active',
      strength: results.length == 1 ? 50.0 : 80.0,
      cancellationReasons: results,
    );
  }
}
