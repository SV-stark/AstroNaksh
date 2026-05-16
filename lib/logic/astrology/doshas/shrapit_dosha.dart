import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import '../yogas/yoga_detector.dart';

class ShrapitDoshaDetector extends YogaDetector {
  @override
  String get id => 'shrapit_dosha';

  @override
  String get name => 'Shrapit Dosha';

  @override
  String get description =>
      'Formed when Saturn and Rahu are conjunct in the same sign. '
      'It can indicate delays, hardships, and a sense of being "cursed" or restricted.';

  @override
  List<Planet> get keyPlanets => [Planet.saturn, Planet.meanNode];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final saturn = chart.baseChart.planets[Planet.saturn];
    final rahu = chart.baseChart.rahu;

    if (saturn == null) return BhangaResult.inactive(name);

    if (saturn.position.zodiacSignIndex != rahu.position.zodiacSignIndex) {
      return BhangaResult.inactive(name);
    }

    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      strength: 80.0,
      status: 'Active',
      cancellationReasons: ['Saturn and Rahu are in conjunction'],
      manifestationPeriod:
          'Generally lifelong, intensified during Saturn or Rahu Dashas',
      peakDashaLord: 'Saturn',
    );
  }
}
