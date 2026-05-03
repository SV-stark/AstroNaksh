import 'package:jyotish/jyotish.dart';

import '../../../data/models.dart';
import '../extensions/chart_logic_extensions.dart';
import 'yoga_detector.dart';

class DhanaYogaDetector implements YogaDetector {
  @override
  String get id => 'dhana_yoga';

  @override
  String get name => 'Dhana Yoga';

  @override
  String get description =>
      'Combinations indicating wealth and financial prosperity. '
      'Includes Vasumathi Yoga, Pushkala Yoga, and Akhanda Samrajya Yoga.';

  @override
  List<Planet> get keyPlanets => [Planet.jupiter, Planet.venus, Planet.mercury, Planet.moon];

  @override
  BhangaResult detect(CompleteChartData chart) {
    final results = <String>[];
    final lagnaSign = chart.getAscendantSign();
    final moonSign = chart.getPlanetSign('Moon');
    final upachayas = [2, 5, 9, 10]; // Houses 3, 6, 10, 11 (0-indexed)

    // 1. Vasumathi Yoga
    var vasumathiLagna = true;
    var vasumathiMoon = true;
    for (final b in ['Jupiter', 'Venus', 'Mercury']) {
      final pSign = chart.getPlanetSign(b);
      if (!upachayas.contains((pSign - lagnaSign + 12) % 12)) vasumathiLagna = false;
      if (!upachayas.contains((pSign - moonSign + 12) % 12)) vasumathiMoon = false;
    }
    if (vasumathiLagna || vasumathiMoon) {
      results.add('Vasumathi Yoga (Benefics in Upachayas)');
    }

    // 2. Pushkala Yoga
    final lagnaLord = chart.getHouseLord(1);
    final lagnaLordSign = chart.getPlanetSign(lagnaLord);
    if (chart.isExalted(lagnaLord, lagnaLordSign)) {
      if (chart.isOwnSign('Moon', moonSign) || chart.isExalted('Moon', moonSign)) {
        results.add('Pushkala Yoga (Strong Lagna Lord & Moon)');
      }
    }

    // 3. Akhanda Samrajya Yoga
    final jupSign = chart.getPlanetSign('Jupiter');
    if (chart.isOwnSign('Jupiter', jupSign) || chart.isExalted('Jupiter', jupSign)) {
      final lords = [chart.getHouseLord(2), chart.getHouseLord(9), chart.getHouseLord(11)];
      var conditionMet = false;
      for (final lord in lords) {
        final sign = chart.getPlanetSign(lord);
        if ([0, 3, 6, 9].contains((sign - moonSign + 12) % 12)) {
          conditionMet = true;
          break;
        }
      }
      if (conditionMet) results.add('Akhanda Samrajya Yoga (Unbroken Wealth)');
    }

    if (results.isEmpty) {
      return BhangaResult.inactive(name);
    }

    return BhangaResult(
      name: name,
      description: description,
      isActive: true,
      status: 'Active',
      strength: 75.0,
      cancellationReasons: results,
    );
  }
}
