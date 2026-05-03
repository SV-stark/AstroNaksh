import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import '../yogas/yoga_detector.dart';

class KaalSarpDoshaDetector extends YogaDetector {
  @override
  String get id => 'kaal_sarp_dosha';

  @override
  String get name => 'Kaal Sarp Dosha';

  @override
  String get description =>
      'Formed when all seven visible planets are hemmed between Rahu and Ketu. '
      'It can indicate delays, struggles, and sudden ups and downs in life.';

  @override
  List<Planet> get keyPlanets => [Planet.meanNode, Planet.ketu];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final rahu = chart.baseChart.rahu;
    final ketu = chart.baseChart.ketu;

    final rahuLong = rahu.longitude;
    final ketuLong = ketu.longitude;

    bool isBetween(double long, double start, double end) {
      if (start <= end) {
        return long >= start && long <= end;
      } else {
        return long >= start || long <= end;
      }
    }

    var side1 = true;
    var side2 = true;

    final visiblePlanets = [
      Planet.sun,
      Planet.moon,
      Planet.mars,
      Planet.mercury,
      Planet.jupiter,
      Planet.venus,
      Planet.saturn,
    ];

    for (final p in visiblePlanets) {
      final pInfo = chart.baseChart.planets[p];
      if (pInfo == null) continue;
      final long = pInfo.position.longitude;
      if (!isBetween(long, rahuLong, ketuLong)) side1 = false;
      if (!isBetween(long, ketuLong, rahuLong)) side2 = false;
    }

    final isPresent = side1 || side2;
    if (!isPresent) return BhangaResult.inactive(name);

    // Check for cancellations (Bhangas)
    final cancellations = <String>[];
    
    // 1. Planet conjunct Nodes (Axis broken)
    for (final p in visiblePlanets) {
      final pInfo = chart.baseChart.planets[p];
      if (pInfo == null) continue;
      final pSign = (pInfo.position.longitude / 30).floor();
      final rahuSign = (rahu.longitude / 30).floor();
      final ketuSign = (ketu.longitude / 30).floor();
      
      if (pSign == rahuSign || pSign == ketuSign) {
        cancellations.add('Axis broken: ${p.displayName} is conjunct with Nodes');
      }
    }

    // 2. Strong Lagna Lord
    final lagnaSign = (chart.baseChart.houses.ascendant / 30).floor() % 12;
    final lagnaLord = Rashi.values[lagnaSign].lord;
    final l1Info = chart.baseChart.planets[lagnaLord];
    if (l1Info != null && (l1Info.dignity == PlanetaryDignity.exalted || l1Info.dignity == PlanetaryDignity.ownSign)) {
      cancellations.add('Lagna Lord is strong (${l1Info.dignity.name})');
    }

    final isCancelled = cancellations.isNotEmpty;
    final strength = isCancelled ? 20.0 : 80.0;

    return BhangaResult(
      name: name,
      description: description,
      isActive: !isCancelled,
      strength: strength,
      status: isCancelled ? 'Cancelled' : 'Active',
      cancellationReasons: cancellations,
      manifestationPeriod: 'Generally lifelong, intensified during Rahu/Ketu Dashas',
      peakDashaLord: 'Rahu',
    );
  }
}
