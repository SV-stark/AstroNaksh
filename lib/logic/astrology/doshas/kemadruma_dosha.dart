import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import '../yogas/yoga_detector.dart';

class KemadrumaDoshaDetector extends YogaDetector {
  @override
  String get id => 'kemadruma_dosha';

  @override
  String get name => 'Kemadruma Dosha';

  @override
  String get description =>
      'Occurs when there are no planets (excluding Rahu/Ketu) in the 2nd or 12th house from the Moon, '
      'and no planets are in the Kendras from the Moon. '
      'It can indicate isolation, lack of support, or financial instability.';

  @override
  List<Planet> get keyPlanets => [Planet.moon];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final moon = chart.baseChart.planets[Planet.moon];
    if (moon == null) return BhangaResult.inactive(name);

    final moonSign = moon.position.zodiacSignIndex;
    final visiblePlanets = [
      Planet.sun,
      Planet.mars,
      Planet.mercury,
      Planet.jupiter,
      Planet.venus,
      Planet.saturn,
    ];

    var hasPlanetsInAdjacent = false;
    var hasPlanetsInKendras = false;

    for (final p in visiblePlanets) {
      final pInfo = chart.baseChart.planets[p];
      if (pInfo == null) continue;
      
      final diff = (pInfo.position.zodiacSignIndex - moonSign + 12) % 12 + 1;
      if (diff == 2 || diff == 12) hasPlanetsInAdjacent = true;
      if ([1, 4, 7, 10].contains(diff) && p != Planet.moon) hasPlanetsInKendras = true;
    }

    if (hasPlanetsInAdjacent) return BhangaResult.inactive(name);

    final isCancelled = hasPlanetsInKendras;
    final strength = isCancelled ? 20.0 : 80.0;

    return BhangaResult(
      name: name,
      description: description,
      isActive: !isCancelled,
      strength: strength,
      status: isCancelled ? 'Cancelled' : 'Active',
      cancellationReasons: isCancelled ? ['Planets are present in Kendras from Moon'] : ['No planets in 2nd or 12th from Moon'],
      manifestationPeriod: 'Felt during Moon Dasha',
      peakDashaLord: 'Moon',
    );
  }
}
