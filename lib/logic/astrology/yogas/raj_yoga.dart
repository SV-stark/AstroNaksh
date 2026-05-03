import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class RajYogaDetector extends YogaDetector {
  @override
  String get id => 'raj_yoga';

  @override
  String get name => 'Parasari Raj Yoga';

  @override
  String get description =>
      'Formed by the relationship between Kendra (angles) and Trikona (trines) lords. '
      'It represents a powerful combination of action and purpose, leading to success, authority, and status.';

  @override
  List<Planet> get keyPlanets => []; // Varies based on ascendant

  @override
  BhangaResult detect(CompleteChartData chart) {
    final lagnaSign = (chart.baseChart.houses.ascendant / 30).floor() % 12;

    // Kendra houses: 1, 4, 7, 10
    final kendraLords = <Planet>{};
    for (final house in [1, 4, 7, 10]) {
      final sign = (lagnaSign + house - 1) % 12;
      kendraLords.add(Rashi.values[sign].lord);
    }

    // Trikona houses: 1, 5, 9
    final trikonaLords = <Planet>{};
    for (final house in [1, 5, 9]) {
      final sign = (lagnaSign + house - 1) % 12;
      trikonaLords.add(Rashi.values[sign].lord);
    }

    final activeLords = <Planet>[];
    final reasons = <String>[];

    // Check for conjunction (same sign)
    for (final kl in kendraLords) {
      for (final tl in trikonaLords) {
        if (kl == tl) continue;

        final klInfo = chart.baseChart.planets[kl];
        final tlInfo = chart.baseChart.planets[tl];

        if (klInfo != null && tlInfo != null) {
          final klSign = (klInfo.position.longitude / 30).floor();
          final tlSign = (tlInfo.position.longitude / 30).floor();
          if (klSign == tlSign) {
            activeLords.addAll([kl, tl]);
            reasons.add(
                '${kl.displayName} (Kendra Lord) and ${tl.displayName} (Trikona Lord) are conjunct in ${Rashi.values[klSign].name}');
          }
        }
      }
    }

    if (activeLords.isEmpty) {
      return BhangaResult.inactive(name);
    }

    // Strength calculation
    var strength = 70.0;
    
    // Check if conjunction is in a good house
    final firstLord = activeLords.first;
    final house = chart.baseChart.planets[firstLord]?.house ?? 1;
    if ([1, 4, 5, 7, 9, 10].contains(house)) {
      strength += 20.0;
      reasons.add('Combination occurs in a powerful house (${house}th house)');
    }

    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      strength: strength.clamp(0, 100),
      status: strength >= 85 ? 'Powerful' : 'Active',
      cancellationReasons: reasons,
      manifestationPeriod: 'Active during the Dashas of the participating lords',
      peakDashaLord: activeLords.first.displayName,
    );
  }
}
