import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import '../yogas/yoga_detector.dart';

class VishDoshaDetector extends YogaDetector {
  @override
  String get id => 'vish_dosha';

  @override
  String get name => 'Vish Dosha';

  @override
  String get description =>
      'Formed by the conjunction of Saturn and the Moon. '
      'It can indicate mental stress, emotional burdens, or obstacles in career.';

  @override
  List<Planet> get keyPlanets => [Planet.saturn, Planet.moon];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final saturn = chart.baseChart.planets[Planet.saturn];
    final moon = chart.baseChart.planets[Planet.moon];

    if (saturn == null || moon == null) return BhangaResult.inactive(name);

    if (saturn.position.zodiacSignIndex != moon.position.zodiacSignIndex) {
      return BhangaResult.inactive(name);
    }

    // Check for cancellation: Benefic aspect or placement in good house
    final isCancelled = moon.house == 4 || moon.house == 9 || moon.house == 11;
    
    final strength = isCancelled ? 30.0 : 70.0;

    return BhangaResult(
      name: name,
      description: description,
      isActive: !isCancelled,
      strength: strength,
      status: isCancelled ? 'Cancelled / Weak' : 'Active',
      cancellationReasons: isCancelled ? ['Moon is in a strong house (${moon.house})'] : ['Moon and Saturn are in conjunction'],
      manifestationPeriod: 'Active during Moon and Saturn Dashas',
      peakDashaLord: 'Saturn',
    );
  }
}
