import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';
import 'yoga_detector.dart';

class VipreetRajYogaDetector extends YogaDetector {
  @override
  String get id => 'vipreet_raj_yoga';

  @override
  String get name => 'Vipreet Raj Yoga';

  @override
  String get description =>
      'Formed when the lords of the 6th, 8th, or 12th houses are placed in another Dusthana (6th, 8th, or 12th) house. '
      'It represents the principle of "adversity turned to advantage," where challenges ultimately lead to success.';

  @override
  List<Planet> get keyPlanets => []; // Varies

  @override
  BhangaResult detect(CompleteChartData chart) {
    final lagnaSign = (chart.baseChart.houses.ascendant / 30).floor() % 12;

    Planet getLord(int house) {
      final sign = (lagnaSign + house - 1) % 12;
      return Rashi.values[sign].lord;
    }

    final dusthanaLords = {
      6: getLord(6),
      8: getLord(8),
      12: getLord(12),
    };

    final results = <String>[];
    final reasons = <String>[];
    var maxStrength = 0.0;

    final yogaNames = {
      6: 'Harsha Yoga',
      8: 'Sarala Yoga',
      12: 'Vimala Yoga',
    };

    for (final entry in dusthanaLords.entries) {
      final houseNum = entry.key;
      final lord = entry.value;
      final info = chart.baseChart.planets[lord];
      
      if (info == null) continue;

      final lordInHouse = info.house;
      if ([6, 8, 12].contains(lordInHouse)) {
        final yogaName = yogaNames[houseNum]!;
        results.add(yogaName);
        
        var strength = 60.0;
        if (lordInHouse == houseNum) {
          strength += 20.0; // Lord in own house
          reasons.add('$yogaName: Lord of $houseNum is in its own house');
        } else {
          reasons.add('$yogaName: Lord of $houseNum is in the ${lordInHouse}th house');
        }
        
        if (strength > maxStrength) maxStrength = strength;
      }
    }

    if (results.isEmpty) {
      return BhangaResult.inactive(name);
    }

    return BhangaResult(
      name: results.length == 1 ? results.first : name,
      description: description,
      isActive: true,
      strength: maxStrength,
      status: maxStrength >= 75 ? 'Strong' : 'Active',
      cancellationReasons: reasons,
      manifestationPeriod: 'Active during the Dasha of the involved Dusthana lord',
      peakDashaLord: 'Dusthana Lord',
    );
  }
}
