import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class SakatYogaDetector extends YogaDetector {
  @override
  String get id => 'sakat_yoga';

  @override
  String get name => 'Sakat Yoga';

  @override
  String get description =>
      'Formed when Jupiter is in the 6th, 8th, or 12th house from the Moon. '
      'It can indicate fluctuations in fortune, like the "rolling of a cart" (Sakat).';

  @override
  List<Planet> get keyPlanets => [Planet.jupiter, Planet.moon];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final moon = chart.baseChart.planets[Planet.moon];
    final jupiter = chart.baseChart.planets[Planet.jupiter];

    if (moon == null || jupiter == null) return BhangaResult.inactive(name);

    final houseFromMoon =
        (jupiter.position.zodiacSignIndex -
                moon.position.zodiacSignIndex +
                12) %
            12 +
        1;
    final isSakat = [6, 8, 12].contains(houseFromMoon);

    if (!isSakat) return BhangaResult.inactive(name);

    // Check for cancellation: Moon in Kendra from Lagna
    final isCancelled = [1, 4, 7, 10].contains(moon.house);

    final strength = isCancelled ? 30.0 : 70.0;

    return BhangaResult(
      name: name,
      description: description,
      isActive: !isCancelled,
      strength: strength,
      status: isCancelled ? 'Cancelled / Weak' : 'Active',
      cancellationReasons: isCancelled
          ? ['Moon is in Kendra from Lagna, cancelling Sakat Yoga']
          : ['Jupiter is in ${houseFromMoon}th from Moon'],
      manifestationPeriod: 'Felt during Jupiter and Moon Dashas',
      peakDashaLord: 'Jupiter',
    );
  }
}
