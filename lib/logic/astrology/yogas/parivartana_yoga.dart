import 'package:jyotish/jyotish.dart';

import '../../../data/models.dart';
import '../extensions/chart_logic_extensions.dart';
import 'yoga_detector.dart';

class ParivartanaYogaDetector implements YogaDetector {
  @override
  String get id => 'parivartana_yoga';

  @override
  String get name => 'Parivartana Yoga';

  @override
  String get description =>
      'Mutual exchange of signs between two planetary lords. '
      'Can be Maha (Auspicious), Dainya (Inauspicious), or Kahala (Mixed) depending on the houses involved.';

  @override
  List<Planet> get keyPlanets => Planet.traditionalPlanets;

  @override
  BhangaResult detect(CompleteChartData chart) {
    final results = <String>[];

    // Check all house lord pairs for mutual exchange
    for (var h1 = 1; h1 <= 12; h1++) {
      for (var h2 = h1 + 1; h2 <= 12; h2++) {
        final lord1 = chart.getHouseLord(h1);
        final lord2 = chart.getHouseLord(h2);

        if (chart.areInMutualExchange(lord1, lord2)) {
          // Maha (great): 1,4,7,10,5,9
          if (chart.isKendraOrTrikona(h1) && chart.isKendraOrTrikona(h2)) {
            results.add(
              'Maha Parivartana Yoga (${h1}th-${h2}th lords exchange)',
            );
          }
          // Dainya (misery): exchange with 6, 8, 12
          else if (chart.isDusthana(h1) || chart.isDusthana(h2)) {
            results.add('Dainya Parivartana Yoga (${h1}th-${h2}th lords)');
          }
          // Kahala: mixed good/bad (usually covers the rest)
          else {
            results.add('Kahala Parivartana Yoga (${h1}th-${h2}th lords)');
          }
        }
      }
    }

    if (results.isEmpty) {
      return BhangaResult.inactive(name);
    }

    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      status: 'Active',
      strength: 80.0,
      cancellationReasons: results,
    );
  }
}
