import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import '../yogas/yoga_detector.dart';

class GrahanDoshaDetector extends YogaDetector {
  @override
  String get id => 'grahan_dosha';

  @override
  String get name => 'Grahan Dosha';

  @override
  String get description =>
      'Formed when the Sun or Moon is conjunct with Rahu or Ketu. '
      'It can indicate confusion, low energy, or obstacles in personal growth.';

  @override
  List<Planet> get keyPlanets => [Planet.sun, Planet.moon, Planet.meanNode, Planet.ketu];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final sun = chart.baseChart.planets[Planet.sun];
    final moon = chart.baseChart.planets[Planet.moon];
    final rahu = chart.baseChart.rahu;
    final ketu = chart.baseChart.ketu;

    var isSunGrahan = false;
    var isMoonGrahan = false;

    if (sun != null) {
      if (sun.position.zodiacSignIndex == rahu.position.zodiacSignIndex ||
          sun.position.zodiacSignIndex == (ketu.longitude / 30).floor() % 12) {
        isSunGrahan = true;
      }
    }

    if (moon != null) {
      if (moon.position.zodiacSignIndex == rahu.position.zodiacSignIndex ||
          moon.position.zodiacSignIndex == (ketu.longitude / 30).floor() % 12) {
        isMoonGrahan = true;
      }
    }

    if (!isSunGrahan && !isMoonGrahan) return BhangaResult.inactive(name);

    final target = isSunGrahan && isMoonGrahan ? 'Sun and Moon' : (isSunGrahan ? 'Sun' : 'Moon');
    
    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      strength: 70.0,
      status: 'Active',
      cancellationReasons: ['$target is conjunct with Nodes'],
      manifestationPeriod: 'Intensified during Eclipses and Node Dashas',
      peakDashaLord: 'Rahu',
    );
  }
}
