import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class ParvataYogaDetector extends YogaDetector {
  @override
  String get id => 'parvata_yoga';

  @override
  String get name => 'Parvata Yoga';

  @override
  String get description =>
      'Formed when the lord of the Lagna is in a Kendra or Trikona, and either in its own sign or exalted. '
      'It indicates wealth, fame, and a position of authority.';

  @override
  List<Planet> get keyPlanets => [];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final lagnaSign = (chart.baseChart.houses.ascendant / 30).floor() % 12;
    final l1 = Rashi.values[lagnaSign].lord;
    final l1Info = chart.baseChart.planets[l1];

    if (l1Info == null) return BhangaResult.inactive(name);

    final house = l1Info.house;
    final isKendraOrTrikona = [1, 4, 7, 10, 5, 9].contains(house);
    final isStrong =
        l1Info.dignity == PlanetaryDignity.exalted ||
        l1Info.dignity == PlanetaryDignity.ownSign;

    if (isKendraOrTrikona && isStrong) {
      return BhangaResult(
        name: name,
        description: description,
        isActive: true,
        strength: 85.0,
        status: 'Strong',
        manifestationPeriod: 'Active during Lagna Lord Dasha',
        peakDashaLord: l1.displayName,
      );
    }

    return BhangaResult.inactive(name);
  }
}
