import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class LakshmiYogaDetector extends YogaDetector {
  @override
  String get id => 'lakshmi_yoga';

  @override
  String get name => 'Lakshmi Yoga';

  @override
  String get description =>
      'Formed when the 9th lord and Venus are strong and placed in favorable houses. '
      'It brings wealth, prosperity, grace, and all-round happiness.';

  @override
  List<Planet> get keyPlanets => [Planet.venus];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final lagnaSign = (chart.baseChart.houses.ascendant / 30).floor() % 12;
    final ninthSign = (lagnaSign + 9 - 1) % 12;
    final ninthLord = Rashi.values[ninthSign].lord;

    final venus = chart.baseChart.planets[Planet.venus];
    final lord = chart.baseChart.planets[ninthLord];

    if (venus == null || lord == null) return BhangaResult.inactive(name);

    final isSameSign =
        venus.position.zodiacSignIndex == lord.position.zodiacSignIndex;
    final isVenusStrong =
        venus.dignity == PlanetaryDignity.exalted ||
        venus.dignity == PlanetaryDignity.ownSign;
    final isLordStrong =
        lord.dignity == PlanetaryDignity.exalted ||
        lord.dignity == PlanetaryDignity.ownSign;

    if (isSameSign && isVenusStrong && isLordStrong) {
      return BhangaResult(
        name: name,
        description: description,
        isActive: true,
        strength: 90.0,
        status: 'Powerful',
        manifestationPeriod: 'Active during Venus or 9th Lord Dashas',
        peakDashaLord: 'Venus',
      );
    }

    return BhangaResult.inactive(name);
  }
}
