import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import '../yogas/yoga_detector.dart';

class MangalDoshaDetector extends YogaDetector {
  @override
  String get id => 'mangal_dosha';

  @override
  String get name => 'Mangal Dosha (Manglik)';

  @override
  String get description =>
      'Occurs when Mars is placed in the 1st, 2nd, 4th, 7th, 8th, or 12th house from the Lagna, Moon, or Venus. '
      'It can indicate intensity in relationships and potential marital friction.';

  @override
  List<Planet> get keyPlanets => [Planet.mars];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final mars = chart.baseChart.planets[Planet.mars];
    if (mars == null) return BhangaResult.inactive(name);

    final badHouses = [1, 2, 4, 7, 8, 12];
    
    // Check from Lagna
    final lagnaSign = (chart.baseChart.houses.ascendant / 30).floor() % 12;
    final houseFromLagna = (mars.position.zodiacSignIndex - lagnaSign + 12) % 12 + 1;
    final fromLagna = badHouses.contains(houseFromLagna);

    // Check from Moon
    final moon = chart.baseChart.planets[Planet.moon];
    final fromMoon = moon != null && badHouses.contains((mars.position.zodiacSignIndex - moon.position.zodiacSignIndex + 12) % 12 + 1);

    // Check from Venus
    final venus = chart.baseChart.planets[Planet.venus];
    final fromVenus = venus != null && badHouses.contains((mars.position.zodiacSignIndex - venus.position.zodiacSignIndex + 12) % 12 + 1);

    final count = [fromLagna, fromMoon, fromVenus].where((x) => x).length;
    
    if (count < 2) {
      return BhangaResult.inactive(name);
    }

    final reasons = <String>[];
    if (fromLagna) reasons.add('Mars in ${houseFromLagna}th house from Lagna');
    if (fromMoon) reasons.add('Mars in bad house from Moon');
    if (fromVenus) reasons.add('Mars in bad house from Venus');

    // Check for cancellations
    final cancellations = <String>[];
    if (mars.dignity == PlanetaryDignity.exalted || mars.dignity == PlanetaryDignity.ownSign) {
      cancellations.add('Mars is strong (${mars.dignity.name})');
    }
    if (mars.position.zodiacSignIndex == Rashi.cancer.number) {
      // Cancellation for Cancer
    }

    final isCancelled = cancellations.isNotEmpty;
    var strength = (count * 30.0).clamp(0.0, 100.0);
    if (isCancelled) strength -= 30;

    return BhangaResult(
      name: name,
      description: description,
      isActive: strength > 40,
      strength: strength.clamp(0, 100),
      status: isCancelled ? 'Partial / Cancelled' : 'Active',
      cancellationReasons: isCancelled ? cancellations : reasons,
      manifestationPeriod: 'Active during Mars Dasha',
      peakDashaLord: 'Mars',
    );
  }
}
