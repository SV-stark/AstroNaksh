import 'package:jyotish/jyotish.dart' as jy;
import '../../data/models.dart';

class ProgenyService {
  /// Analyze prospects for children by delegating to the core jyotish library
  ProgenyAnalysis analyzeProgeny(CompleteChartData chartData) {
    final libraryService = jy.ProgenyService();
    final libResult = libraryService.analyzeProgeny(chartData.baseChart);

    final factors = <ProgenyFactor>[];

    // 1. 5th House Strength (normalized from 40 max to 100%)
    final fifthHousePct = (libResult.fifthHouseStrength.score / 40 * 100).round().clamp(0, 100);
    final List<String> fifthHousePlanets = libResult.fifthHouseStrength.planetsInHouse.map((p) => p.displayName).toList();
    final List<String> fifthHouseAspects = libResult.fifthHouseStrength.aspectsOnHouse.map((p) => p.displayName).toList();
    
    String fifthHouseDesc = '5th House score is ${libResult.fifthHouseStrength.score}/40.';
    if (fifthHousePlanets.isNotEmpty) {
      fifthHouseDesc += ' Occupied by: ${fifthHousePlanets.join(", ")}.';
    } else {
      fifthHouseDesc += ' Unoccupied.';
    }
    if (fifthHouseAspects.isNotEmpty) {
      fifthHouseDesc += ' Aspecting planets: ${fifthHouseAspects.join(", ")}.';
    }
    if (libResult.fifthHouseStrength.isAfflicted) {
      fifthHouseDesc += ' (Afflicted/Weak)';
    } else if (libResult.fifthHouseStrength.isStrong) {
      fifthHouseDesc += ' (Strong)';
    }

    factors.add(ProgenyFactor(
      name: '5th House',
      score: fifthHousePct,
      description: fifthHouseDesc,
    ));

    // 2. Jupiter Condition (normalized from 50 max to 100%)
    final jupiterPct = (libResult.jupiterCondition.score / 50 * 100).round().clamp(0, 100);
    String jupiterDesc = 'Jupiter resides in house ${libResult.jupiterCondition.house} (Score: ${libResult.jupiterCondition.score}/50).';
    if (libResult.jupiterCondition.isExalted) jupiterDesc += ' Exalted.';
    if (libResult.jupiterCondition.isOwnSign) jupiterDesc += ' In own sign.';
    if (libResult.jupiterCondition.isDebilitated) jupiterDesc += ' Debilitated.';
    if (libResult.jupiterCondition.isCombust) jupiterDesc += ' Combust (afflicted by Sun).';

    factors.add(ProgenyFactor(
      name: 'Jupiter (Karaka)',
      score: jupiterPct,
      description: jupiterDesc,
    ));

    // 3. Saptamsha D7 Chart (normalized from 30 max to 100%)
    final d7Pct = (libResult.d7Analysis.score / 30 * 100).round().clamp(0, 100);
    String d7Desc = 'Saptamsha (D7) divisional chart score is ${libResult.d7Analysis.score}/30.';
    if (libResult.d7Analysis.fifthLordD7 != null) {
      d7Desc += ' 5th Lord placement in D7: ${libResult.d7Analysis.fifthLordD7!.displayName}.';
    }
    if (libResult.d7Analysis.jupiterD7 != null) {
      d7Desc += ' Jupiter placement in D7: ${libResult.d7Analysis.jupiterD7!.displayName}.';
    }

    factors.add(ProgenyFactor(
      name: 'Saptamsha (D7)',
      score: d7Pct,
      description: d7Desc,
    ));

    // Compile prediction paragraph
    final buffer = StringBuffer();
    buffer.write('Your progeny analysis is evaluated using core Vedic astrological parameters, including the 5th House, Jupiter (the natural significator / Putrakaraka for children), and the D7 Saptamsha divisional chart.\n\n');
    buffer.write('Overall progeny strength is rated as **${libResult.strength.name}** (${libResult.strength.description}) with an overall score of ${libResult.score}/100.\n\n');

    if (libResult.score >= 75) {
      buffer.write('This signifies exceptionally favorable and auspicious prospects for children, family growth, and domestic happiness. ');
    } else if (libResult.score >= 60) {
      buffer.write('There are strong positive factors that support smooth family growth and healthy progeny. ');
    } else if (libResult.score >= 40) {
      buffer.write('The planetary influences are moderate, showing a balanced combination of favorable conditions and minor challenges or delays. ');
    } else {
      buffer.write('The planetary configurations present significant challenges, which could point to delays or difficulties. Traditional remedies and lifestyle choices are advised. ');
    }

    if (libResult.fifthHouseStrength.isStrong) {
      buffer.write('The 5th house is well fortified and supports progeny. ');
    } else {
      buffer.write('The 5th house shows some weakness or affliction, which might require patience or remedial actions. ');
    }

    if (libResult.jupiterCondition.isStrong) {
      buffer.write('Jupiter (the natural significator for children) is strong, well placed, and protective. ');
    } else {
      buffer.write('Jupiter needs strengthening as its current placement or dignity is less supportive. ');
    }

    final presentYogas = libResult.childYogas.where((y) => y.isPresent).map((y) => y.name).toList();
    if (presentYogas.isNotEmpty) {
      buffer.write('\n\n**Auspicious Yogas Present:** ${presentYogas.join(", ")}.');
      for (final yoga in libResult.childYogas) {
        if (yoga.isPresent) {
          buffer.write('\n• *${yoga.name}*: ${yoga.description}');
        }
      }
    }

    // Recommendations based on weaknesses
    final recommendations = <String>[];
    if (libResult.jupiterCondition.score < 30) {
      recommendations.add('Strengthen Jupiter (Guru) by chanting Jupiter mantras, donating yellow items on Thursdays, or supporting educational charity.');
    }
    if (libResult.fifthHouseStrength.isAfflicted || libResult.fifthHouseStrength.score < 20) {
      recommendations.add('Recite the Santan Gopal Mantra daily or perform a Santan Gopal Puja to address 5th house afflictions.');
    }
    if (libResult.d7Analysis.score < 15) {
      recommendations.add('Propitiate the lord of the 5th house in the D7 chart to mitigate obstacles in family planning.');
    }
    if (libResult.jupiterCondition.isCombust) {
      recommendations.add('Jupiter is combust; pray to the Sun God (Surya Dev) to balance the intensity and solar heat.');
    }
    if (recommendations.isEmpty) {
      recommendations.add('Progeny prospects are highly favorable. Continue maintaining a healthy, balanced lifestyle and positive mindset.');
    }

    return ProgenyAnalysis(
      factors: factors,
      overallScore: libResult.score,
      prospects: libResult.strength.name,
      prediction: buffer.toString(),
      recommendations: recommendations,
    );
  }
}

class ProgenyAnalysis {
  ProgenyAnalysis({
    required this.factors,
    required this.overallScore,
    required this.prospects,
    required this.prediction,
    required this.recommendations,
  });

  final List<ProgenyFactor> factors;
  final int overallScore;
  final String prospects;
  final String prediction;
  final List<String> recommendations;
}

class ProgenyFactor {
  ProgenyFactor({
    required this.name,
    required this.score,
    required this.description,
  });

  final String name;
  final int score;
  final String description;
}
