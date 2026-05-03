import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import '../yogas/yoga_detector.dart';

class PitraDoshaDetector extends YogaDetector {
  @override
  String get id => 'pitra_dosha';

  @override
  String get name => 'Pitra Dosha';

  @override
  String get description =>
      'Formed when the Sun or Jupiter is conjunct with Rahu or Ketu, or when the 9th lord is in the 6th, 8th, or 12th house. '
      'It can indicate karmic debts related to ancestors and challenges in personal progress.';

  @override
  List<Planet> get keyPlanets => [Planet.sun, Planet.jupiter, Planet.meanNode, Planet.ketu];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final sun = chart.baseChart.planets[Planet.sun];
    final jupiter = chart.baseChart.planets[Planet.jupiter];
    final rahu = chart.baseChart.rahu;
    final ketu = chart.baseChart.ketu;

    final nodeSigns = [rahu.position.zodiacSignIndex, (ketu.longitude / 30).floor() % 12];
    
    final isSunNode = sun != null && nodeSigns.contains(sun.position.zodiacSignIndex);
    final isJupiterNode = jupiter != null && nodeSigns.contains(jupiter.position.zodiacSignIndex);

    final lagnaSign = (chart.baseChart.houses.ascendant / 30).floor() % 12;
    final l9 = Rashi.values[(lagnaSign + 8) % 12].lord;
    final l9Info = chart.baseChart.planets[l9];
    final isL9Bad = l9Info != null && [6, 8, 12].contains(l9Info.house);

    if (!isSunNode && !isJupiterNode && !isL9Bad) return BhangaResult.inactive(name);

    final reasons = <String>[];
    if (isSunNode) reasons.add('Sun conjunct with Nodes');
    if (isJupiterNode) reasons.add('Jupiter conjunct with Nodes');
    if (isL9Bad) reasons.add('9th Lord in bad house');

    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      strength: 70.0,
      status: 'Active',
      cancellationReasons: reasons,
      manifestationPeriod: 'Active during Sun, Jupiter, or Rahu Dashas',
      peakDashaLord: 'Rahu',
    );
  }
}
