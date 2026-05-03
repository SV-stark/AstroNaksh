import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import '../yogas/yoga_detector.dart';

class GuruChandalDoshaDetector extends YogaDetector {
  @override
  String get id => 'guru_chandal_dosha';

  @override
  String get name => 'Guru Chandal Dosha';

  @override
  String get description =>
      'Formed when Jupiter is conjunct with Rahu or Ketu. '
      'It can indicate challenges with tradition, belief systems, or morality.';

  @override
  List<Planet> get keyPlanets => [Planet.jupiter, Planet.meanNode, Planet.ketu];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final jupiter = chart.baseChart.planets[Planet.jupiter];
    final rahu = chart.baseChart.rahu;
    final ketu = chart.baseChart.ketu;

    if (jupiter == null) return BhangaResult.inactive(name);

    final isConjunctRahu = jupiter.position.zodiacSignIndex == rahu.position.zodiacSignIndex;
    final isConjunctKetu = jupiter.position.zodiacSignIndex == (ketu.longitude / 30).floor() % 12;

    if (!isConjunctRahu && !isConjunctKetu) return BhangaResult.inactive(name);

    final nodeName = isConjunctRahu ? 'Rahu' : 'Ketu';
    
    // Check for cancellation: Strong Jupiter (Own sign or Exalted)
    final isCancelled = jupiter.dignity == PlanetaryDignity.exalted || jupiter.dignity == PlanetaryDignity.ownSign;
    
    final strength = isCancelled ? 25.0 : 75.0;

    return BhangaResult(
      name: name,
      description: description,
      isActive: !isCancelled,
      strength: strength,
      status: isCancelled ? 'Cancelled / Mild' : 'Active',
      cancellationReasons: isCancelled ? ['Jupiter is strong (${jupiter.dignity.name}), mitigating the dosha'] : ['Jupiter is conjunct with $nodeName'],
      manifestationPeriod: 'Active during Jupiter and $nodeName Dashas',
      peakDashaLord: 'Jupiter',
    );
  }
}
