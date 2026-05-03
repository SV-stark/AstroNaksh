import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class ChamaraYogaDetector extends YogaDetector {
  @override
  String get id => 'chamara_yoga';

  @override
  String get name => 'Chamara Yoga';

  @override
  String get description =>
      'Formed when the Lagna lord is exalted and placed in a Kendra, '
      'while being aspected by Jupiter. '
      'It indicates a person with great wealth, noble character, and royal status.';

  @override
  List<Planet> get keyPlanets => [Planet.jupiter];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final lagnaSign = (chart.baseChart.houses.ascendant / 30).floor() % 12;
    final l1 = Rashi.values[lagnaSign].lord;
    final l1Info = chart.baseChart.planets[l1];

    if (l1Info == null) return BhangaResult.inactive(name);

    final isExalted = l1Info.dignity == PlanetaryDignity.exalted;
    final isKendra = [1, 4, 7, 10].contains(l1Info.house);

    if (!isExalted || !isKendra) return BhangaResult.inactive(name);

    // Simplification: Check if Jupiter aspects the Lagna lord or is conjunct
    // In a full implementation, we'd use AspectService
    final jupiter = chart.baseChart.planets[Planet.jupiter];
    var hasJupiterInteraction = false;
    if (jupiter != null) {
      if (jupiter.house == l1Info.house) {
        hasJupiterInteraction = true;
      } else {
        // Jupiter's aspects: 5th, 7th, 9th
        final dist = (l1Info.house - jupiter.house + 12) % 12 + 1;
        if ([5, 7, 9].contains(dist)) {
          hasJupiterInteraction = true;
        }
      }
    }

    if (!hasJupiterInteraction) return BhangaResult.inactive(name);

    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      strength: 90.0,
      status: 'Strong',
      cancellationReasons: ['Lagna Lord ${l1.displayName} is exalted in Kendra and aspected by Jupiter'],
      manifestationPeriod: 'Generally lifelong, intensified during Lagna Lord or Jupiter Dasha',
      peakDashaLord: l1.displayName,
    );
  }
}
