import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class KahalaYogaDetector extends YogaDetector {
  @override
  String get id => 'kahala_yoga';

  @override
  String get name => 'Kahala Yoga';

  @override
  String get description =>
      'Formed when the lords of the 4th and 9th houses are in kendras from each other and the lord of the Lagna is strong. '
      'It indicates a noble, prosperous, and successful life.';

  @override
  List<Planet> get keyPlanets => [];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final lagnaSign = (chart.baseChart.houses.ascendant / 30).floor() % 12;
    
    Planet getLord(int house) {
      final sign = (lagnaSign + house - 1) % 12;
      return Rashi.values[sign].lord;
    }

    final l4 = getLord(4);
    final l9 = getLord(9);
    final l1 = getLord(1);

    final l4Info = chart.baseChart.planets[l4];
    final l9Info = chart.baseChart.planets[l9];
    final l1Info = chart.baseChart.planets[l1];

    if (l4Info == null || l9Info == null || l1Info == null) {
      return BhangaResult.inactive(name);
    }

    final diff = (l4Info.position.zodiacSignIndex - l9Info.position.zodiacSignIndex + 12) % 12;
    final isKendra = [0, 3, 6, 9].contains(diff);
    final isL1Strong = l1Info.dignity == PlanetaryDignity.exalted ||
        l1Info.dignity == PlanetaryDignity.ownSign;

    if (isKendra && isL1Strong) {
      return BhangaResult(
        name: name,
        description: description,
        isActive: true,
        strength: 80.0,
        status: 'Active',
        manifestationPeriod: 'Active during Dashas of 4th, 9th, or Lagna Lord',
        peakDashaLord: l1.displayName,
      );
    }

    return BhangaResult.inactive(name);
  }
}
