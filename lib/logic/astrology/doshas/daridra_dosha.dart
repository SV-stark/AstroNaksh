import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import '../yogas/yoga_detector.dart';

class DaridraDoshaDetector extends YogaDetector {
  @override
  String get id => 'daridra_dosha';

  @override
  String get name => 'Daridra Dosha';

  @override
  String get description =>
      'Formed when the lord of the 11th house is placed in the 6th, 8th, or 12th house. '
      'It can indicate financial struggles or difficulties in accumulating wealth.';

  @override
  List<Planet> get keyPlanets => [];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final lagnaSign = (chart.baseChart.houses.ascendant / 30).floor() % 12;
    final l11 = Rashi.values[(lagnaSign + 10) % 12].lord;
    final l11Info = chart.baseChart.planets[l11];

    if (l11Info == null) return BhangaResult.inactive(name);

    final isDaridra = [6, 8, 12].contains(l11Info.house);

    if (!isDaridra) return BhangaResult.inactive(name);

    // Check for cancellation: Strong Lagna lord or Jupiter aspect
    final l1 = Rashi.values[lagnaSign].lord;
    final l1Info = chart.baseChart.planets[l1];
    final isCancelled = l1Info != null && (l1Info.dignity == PlanetaryDignity.exalted || l1Info.dignity == PlanetaryDignity.ownSign);
    
    final strength = isCancelled ? 25.0 : 65.0;

    return BhangaResult(
      name: name,
      description: description,
      isActive: !isCancelled,
      strength: strength,
      status: isCancelled ? 'Cancelled' : 'Active',
      cancellationReasons: isCancelled ? ['Strong Lagna Lord mitigates financial struggles'] : ['11th Lord in ${l11Info.house}th house'],
      manifestationPeriod: 'Felt during 11th Lord Dasha',
      peakDashaLord: l11.displayName,
    );
  }
}
