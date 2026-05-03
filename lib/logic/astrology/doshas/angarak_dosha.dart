import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import '../yogas/yoga_detector.dart';

class AngarakDoshaDetector extends YogaDetector {
  @override
  String get id => 'angarak_dosha';

  @override
  String get name => 'Angarak Dosha';

  @override
  String get description =>
      'Formed when Mars is conjunct with Rahu or Ketu. '
      'It can indicate aggression, volatility, or excessive heat/inflammation.';

  @override
  List<Planet> get keyPlanets => [Planet.mars, Planet.meanNode, Planet.ketu];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final mars = chart.baseChart.planets[Planet.mars];
    final rahu = chart.baseChart.rahu;
    final ketu = chart.baseChart.ketu;

    if (mars == null) return BhangaResult.inactive(name);

    final isRahu = mars.position.zodiacSignIndex == rahu.position.zodiacSignIndex;
    final isKetu = mars.position.zodiacSignIndex == (ketu.longitude / 30).floor() % 12;

    if (!isRahu && !isKetu) return BhangaResult.inactive(name);

    final node = isRahu ? 'Rahu' : 'Ketu';
    
    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      strength: 75.0,
      status: 'Active',
      cancellationReasons: ['Mars is conjunct with $node'],
      manifestationPeriod: 'Active during Mars and $node Dashas',
      peakDashaLord: 'Mars',
    );
  }
}
