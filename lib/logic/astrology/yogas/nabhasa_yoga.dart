import 'package:jyotish/jyotish.dart';

import '../../../data/models.dart';
import '../extensions/chart_logic_extensions.dart';
import 'yoga_detector.dart';

class NabhasaYogaDetector implements YogaDetector {
  @override
  String get id => 'nabhasa_yoga';

  @override
  String get name => 'Nabhasa Yogas';

  @override
  String get description =>
      'Yogas based on the general distribution of all planets across the signs and houses. '
      'Includes Ashraya Yogas (Rajju, Musala, Nala) and Dala Yogas (Mala, Sarpa).';

  @override
  List<Planet> get keyPlanets => Planet.traditionalPlanets;

  @override
  BhangaResult detect(CompleteChartData chart) {
    final results = <String>[];
    final planetSigns = <String, int>{};
    final planetHouses = <String, int>{};

    const visiblePlanets = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ];

    for (final p in visiblePlanets) {
      planetSigns[p] = chart.getPlanetSign(p);
      planetHouses[p] = chart.getPlanetHouse(p);
    }

    // --- Ashraya Yogas (Sign containment) ---
    var allMovable = true;
    var allFixed = true;
    var allDual = true;

    for (final sign in planetSigns.values) {
      if (![0, 3, 6, 9].contains(sign)) allMovable = false;
      if (![1, 4, 7, 10].contains(sign)) allFixed = false;
      if (![2, 5, 8, 11].contains(sign)) allDual = false;
    }

    if (allMovable) results.add('Rajju Yoga (All planets in movable signs)');
    if (allFixed) results.add('Musala Yoga (All planets in fixed signs)');
    if (allDual) results.add('Nala Yoga (All planets in dual signs)');

    // --- Dala Yogas (Kendra distribution) ---
    final consecutiveKendras = [
      {1, 4, 7},
      {4, 7, 10},
      {7, 10, 1},
      {10, 1, 4},
    ];

    for (final set in consecutiveKendras) {
      if (planetHouses.values.every(set.contains)) {
        results.add('Mala Yoga (Planets in 3 consecutive kendras)');
        break;
      }
    }

    final consecutivePanaparas = [
      {2, 5, 8},
      {5, 8, 11},
      {8, 11, 2},
      {11, 2, 5},
    ];
    for (final set in consecutivePanaparas) {
      if (planetHouses.values.every(set.contains)) {
        results.add('Sarpa Yoga (Planets in 3 consecutive panaparas)');
        break;
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
      strength: 70.0,
      cancellationReasons: results,
    );
  }
}
