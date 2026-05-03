import 'package:jyotish/jyotish.dart';

import '../data/life_prediction_models.dart';
import '../data/models.dart';
import 'bhava_bala.dart';
import 'shadbala.dart';

/// Life Prediction Service
/// Generates comprehensive life predictions based on Vedic astrology principles
class LifePredictionService {
  /// Generate complete life predictions for all aspects
  Future<LifePredictionsResult> generateLifePredictions(
    CompleteChartData chartData,
  ) async {
    // Get Shadbala for planetary strengths
    final shadbala = await ShadbalaCalculator.calculateShadbala(chartData);

    // Get Bhava Bala for house strengths
    final bhavaBala = await BhavaBala.calculateBhavaBala(chartData);

    // Generate predictions for each life aspect
    final aspects = <LifeAspectPrediction>[];

    for (final aspect in LifeAspect.values) {
      final prediction = _generateAspectPrediction(
        chartData,
        aspect,
        shadbala,
        bhavaBala,
      );
      aspects.add(prediction);
    }

    return LifePredictionsResult.fromAspects(aspects);
  }

  /// Generate prediction for a single life aspect
  LifeAspectPrediction _generateAspectPrediction(
    CompleteChartData chartData,
    LifeAspect aspect,
    Map<Planet, double> shadbala,
    Map<int, BhavaStrength> bhavaBala,
  ) {
    // Collect planetary influences
    final influences = <PlanetaryInfluence>[];
    double totalInfluenceScore = 0;
    var influenceCount = 0;

    // Analyze primary planets for this aspect
    for (final planet in aspect.primaryPlanets) {
      final influence = _analyzePlanetForAspect(
        chartData,
        planet,
        aspect,
        shadbala,
      );
      if (influence != null) {
        influences.add(influence);
        totalInfluenceScore += influence.isBenefic
            ? influence.strength
            : (100 - influence.strength);
        influenceCount++;
      }
    }

    // Analyze house lords for relevant houses
    for (final house in aspect.houses) {
      final houseLord = _getHouseLord(chartData, house);
      if (!aspect.primaryPlanets.contains(houseLord)) {
        final influence = _analyzePlanetForAspect(
          chartData,
          houseLord,
          aspect,
          shadbala,
          isHouseLord: true,
          houseNumber: house,
        );
        if (influence != null) {
          influences.add(influence);
          totalInfluenceScore += influence.isBenefic
              ? influence.strength
              : (100 - influence.strength);
          influenceCount++;
        }
      }
    }

    // Calculate house strengths for relevant houses
    double houseScore = 0;
    for (final house in aspect.houses) {
      final bhava = bhavaBala[house];
      if (bhava != null) {
        houseScore += bhava.totalStrength;
      }
    }
    houseScore = houseScore / aspect.houses.length;

    // Calculate final score (combining planetary and house influences)
    final rawScore = influenceCount > 0
        ? (totalInfluenceScore / influenceCount) * 0.6 + houseScore * 0.4
        : houseScore;

    // Clamp score to 40-95 range
    final score = rawScore.clamp(40.0, 95.0).round();

    // Generate prediction text
    final prediction = _generatePredictionText(
      chartData,
      aspect,
      influences,
      score,
      bhavaBala,
    );

    // Generate advice
    final advice = _generateAdvice(aspect, influences, score);

    return LifeAspectPrediction(
      aspectName: aspect.name,
      aspectDescription: aspect.description,
      iconName: aspect.icon,
      score: score,
      prediction: prediction,
      influences: influences,
      advice: advice,
      relevantHouses: aspect.houses,
    );
  }

  /// Analyze a planet's influence on a life aspect
  PlanetaryInfluence? _analyzePlanetForAspect(
    CompleteChartData chartData,
    Planet planet,
    LifeAspect aspect,
    Map<Planet, double> shadbala, {
    bool isHouseLord = false,
    int? houseNumber,
  }) {
    // Find planet in chart
    final planetInfo = chartData.baseChart.planets[planet];
    if (planetInfo == null) return null;

    final longitude = planetInfo.longitude;
    final sign = planetInfo.position.zodiacSignIndex;
    final house = planetInfo.house;
    final signName = AstrologyConstants.getSignName(sign);

    // Calculate degree within sign
    final degreeInSign = longitude % 30;
    final degrees = degreeInSign.floor();
    final minutes = ((degreeInSign - degrees) * 60).floor();
    final degreeStr = '$degrees°${minutes.toString().padLeft(2, '0')}\'';

    // Get planetary strength (normalized to 0-100)
    final rawStrength = shadbala[planet] ?? 300;
    final strength = ((rawStrength / 600) * 100).clamp(0.0, 100.0);

    // Determine planetary status
    final status = planetInfo.dignity.name;

    // Determine if benefic for this aspect
    final isBenefic = _isBeneficForAspect(
      chartData,
      planet,
      aspect,
      sign,
      house,
      status,
    );

    // Build position description with degrees
    String position;
    if (isHouseLord && houseNumber != null) {
      position =
          '${_getOrdinal(houseNumber)} Lord ${planet.displayName} at $degreeStr $signName in ${_getOrdinal(house)} House';
    } else {
      position =
          '${planet.displayName} at $degreeStr $signName in ${_getOrdinal(house)} House';
    }

    // Generate effect description
    final effect = _generateEffectDescription(
      planet,
      aspect,
      status,
      isBenefic,
      house,
      isHouseLord,
      houseNumber,
      signName: signName,
      degreeStr: degreeStr,
      strength: strength,
    );

    return PlanetaryInfluence(
      planet: planet,
      position: position,
      status: status,
      strength: strength,
      effect: effect,
      isBenefic: isBenefic,
    );
  }

  /// Get house from sign based on ascendant
  int _getHouseFromSign(CompleteChartData chartData, int sign) {
    final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
    return ((sign - ascSign + 12) % 12) + 1;
  }

  /// Get house lord
  Planet _getHouseLord(CompleteChartData chartData, int house) {
    final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
    final houseSign = (ascSign + house - 1) % 12;
    return AstrologyConstants.getSignLord(houseSign);
  }

  /// Determine if planet's influence is benefic for this aspect
  bool _isBeneficForAspect(
    CompleteChartData chartData,
    Planet planet,
    LifeAspect aspect,
    int sign,
    int house,
    String status,
  ) {
    // Natural benefics
    final naturalBenefics = [
      Planet.jupiter,
      Planet.venus,
      Planet.mercury,
      Planet.moon
    ];

    // If exalted or in own sign, generally benefic
    if (status == 'Exalted' || status == 'Own Sign') {
      return true;
    }

    // If debilitated, generally malefic for the aspect
    if (status == 'Debilitated') {
      return false;
    }

    // Check if planet is placed in relevant houses (good placement)
    if (aspect.houses.contains(house)) {
      return naturalBenefics.contains(planet) || status == 'Friendly Sign';
    }

    // Check if in kendra or trikona from relevant houses
    for (final aspectHouse in aspect.houses) {
      final distance = ((house - aspectHouse + 12) % 12) + 1;
      // Kendras (1, 4, 7, 10) and Trikonas (1, 5, 9) are good
      if ([1, 4, 5, 7, 9, 10].contains(distance)) {
        return naturalBenefics.contains(planet);
      }
    }

    return naturalBenefics.contains(planet);
  }

  /// Generate effect description
  String _generateEffectDescription(
    Planet planet,
    LifeAspect aspect,
    String status,
    bool isBenefic,
    int house,
    bool isHouseLord,
    int? houseNumber, {
    String signName = '',
    String degreeStr = '',
    double strength = 50,
  }) {
    final strengthWord = isBenefic ? 'supports' : 'challenges';
    final aspectArea = aspect.name.split(' ')[0].toLowerCase();
    final strengthLabel =
        strength >= 70 ? 'strong' : (strength >= 40 ? 'moderate' : 'weak');
    final signRef = signName.isNotEmpty ? ' in $signName' : '';
    final degRef = degreeStr.isNotEmpty ? ' at $degreeStr' : '';

    String baseEffect;

    if (isHouseLord && houseNumber != null) {
      final houseSignificance = _getHouseSignificance(houseNumber);
      baseEffect =
          'Lord of $houseSignificance placed$degRef$signRef in ${_getOrdinal(house)} house (Shadbala: $strengthLabel, ${strength.toStringAsFixed(0)}%)';
    } else {
      baseEffect =
          '${planet.displayName}$degRef$signRef $strengthWord $aspectArea matters (Shadbala: $strengthLabel, ${strength.toStringAsFixed(0)}%)';
    }

    // Add status-specific details
    switch (status) {
      case 'Exalted':
        return '$baseEffect. Being exalted$signRef, ${planet.displayName} delivers maximum strength and highly positive results for this area.';
      case 'Debilitated':
        return '$baseEffect. ${planet.displayName} is debilitated$signRef, indicating challenges that require persistent effort and remedial measures to overcome.';
      case 'Own Sign':
        return '$baseEffect. ${planet.displayName} is in its own sign ($signName), providing stability, confidence, and naturally good results.';
      case 'Friendly Sign':
        return '$baseEffect. ${planet.displayName} is well-disposed in a friendly sign ($signName), enabling comfortable expression of its qualities.';
      case 'Enemy Sign':
        return '$baseEffect. ${planet.displayName} struggles in an inimical sign ($signName), facing resistance in expressing its natural qualities.';
      default:
        return '$baseEffect. ${planet.displayName} is in a neutral disposition.';
    }
  }

  /// Get house significance
  String _getHouseSignificance(int house) {
    const significances = {
      1: 'Self & Personality',
      2: 'Wealth & Speech',
      3: 'Siblings & Courage',
      4: 'Home & Mother',
      5: 'Children & Intelligence',
      6: 'Enemies & Health',
      7: 'Marriage & Partnerships',
      8: 'Longevity & Transformation',
      9: 'Fortune & Dharma',
      10: 'Career & Status',
      11: 'Gains & Aspirations',
      12: 'Liberation & Losses',
    };
    return significances[house] ?? 'House $house';
  }

  /// Generate detailed prediction text
  String _generatePredictionText(
    CompleteChartData chartData,
    LifeAspect aspect,
    List<PlanetaryInfluence> influences,
    int score,
    Map<int, BhavaStrength> bhavaBala,
  ) {
    final buffer = StringBuffer();

    // Opening with chart-specific planetary reference
    final beneficInfluences = influences.where((i) => i.isBenefic).toList();
    final maleficInfluences = influences.where((i) => !i.isBenefic).toList();

    if (score >= 80) {
      buffer.write(
        'Your chart shows excellent indications for ${aspect.name.toLowerCase()}. ',
      );
      if (beneficInfluences.isNotEmpty) {
        final topPlanet = beneficInfluences.first;
        buffer.write(
          'This is primarily driven by ${topPlanet.position} (${topPlanet.status}, Shadbala: ${topPlanet.strength.toStringAsFixed(0)}%). ',
        );
      }
    } else if (score >= 65) {
      buffer.write(
        'The planetary positions indicate good potential for ${aspect.name.toLowerCase()}. ',
      );
      if (beneficInfluences.isNotEmpty) {
        final topPlanet = beneficInfluences.first;
        buffer.write(
          '${topPlanet.planetName} positioned ${topPlanet.position.replaceFirst(topPlanet.planetName, '').trim()} provides a favorable foundation. ',
        );
      }
    } else if (score >= 50) {
      buffer.write(
        'Mixed influences affect your ${aspect.name.toLowerCase()}, with both opportunities and challenges. ',
      );
      if (maleficInfluences.isNotEmpty) {
        buffer.write(
          '${maleficInfluences.first.planetName} (${maleficInfluences.first.status}) at its current position creates some friction. ',
        );
      }
    } else {
      buffer.write(
        'Your chart indicates some challenges in ${aspect.name.toLowerCase()} that require focused attention. ',
      );
      if (maleficInfluences.isNotEmpty) {
        final troublePlanet = maleficInfluences.first;
        buffer.write(
          '${troublePlanet.planetName} is ${troublePlanet.status.toLowerCase()} at ${troublePlanet.position.replaceFirst(troublePlanet.planetName, '').trim()}, weakening support for this area. ',
        );
      }
    }

    // House analysis with planetary details
    buffer.write('\n\n');
    for (final house in aspect.houses) {
      final bhava = bhavaBala[house];
      if (bhava != null) {
        final strength = bhava.totalStrength;
        final houseDesc = _getHouseSignificance(house);
        final houseLord = _getHouseLord(chartData, house);
        final lordInfo = chartData.baseChart.planets[houseLord];
        var lordPosition = '';
        if (lordInfo != null) {
          final lordSignIdx = lordInfo.position.zodiacSignIndex;
          final lordHouse = _getHouseFromSign(chartData, lordSignIdx);
          lordPosition =
              ' Its lord ${houseLord.displayName} is placed in the ${_getOrdinal(lordHouse)} house (${AstrologyConstants.getSignName(lordSignIdx)}).';
        }
        if (strength >= 60) {
          buffer.write(
            'The ${_getOrdinal(house)} house ($houseDesc) is strong at ${strength.toStringAsFixed(0)}%, providing a solid foundation.$lordPosition ',
          );
        } else if (strength >= 40) {
          buffer.write(
            'The ${_getOrdinal(house)} house ($houseDesc) has moderate strength at ${strength.toStringAsFixed(0)}%.$lordPosition ',
          );
        } else {
          buffer.write(
            'The ${_getOrdinal(house)} house ($houseDesc) is weak at ${strength.toStringAsFixed(0)}%, requiring remedial attention.$lordPosition ',
          );
        }
      }
    }

    // Key planetary influences — detailed
    final strongInfluences = influences.where((i) => i.strength >= 60).toList();
    final weakInfluences = influences.where((i) => i.strength < 40).toList();

    if (strongInfluences.isNotEmpty) {
      buffer.write('\n\n**Supportive Factors:** ');
      for (final influence in strongInfluences.take(3)) {
        buffer.write(
          '${influence.position} [${influence.status}, Shadbala: ${influence.strength.toStringAsFixed(0)}%]. ',
        );
      }
    }

    if (weakInfluences.isNotEmpty) {
      buffer.write('\n\n**Areas of Attention:** ');
      for (final influence in weakInfluences.take(3)) {
        buffer.write(
          '${influence.position} [${influence.status}, Shadbala: ${influence.strength.toStringAsFixed(0)}%] needs strengthening. ',
        );
      }
    }

    return buffer.toString();
  }

  /// Generate advice
  String _generateAdvice(
    LifeAspect aspect,
    List<PlanetaryInfluence> influences,
    int score,
  ) {
    final weakPlanets =
        influences.where((i) => !i.isBenefic || i.strength < 50).toList();

    if (weakPlanets.isEmpty || score >= 80) {
      // For strong charts, still reference key planet
      final topPlanet = influences.isNotEmpty ? influences.first : null;
      final planetRef = topPlanet != null
          ? ' Your ${topPlanet.planetName} (${topPlanet.status} at ${topPlanet.position.replaceFirst(topPlanet.planetName, '').trim()}) is your strongest ally here.'
          : '';
      switch (aspect) {
        case LifeAspect.career:
          return 'Continue leveraging your natural talents. Worship Sun on Sundays for sustained success.$planetRef';
        case LifeAspect.wealth:
          return 'Your financial prospects are favorable. Maintain gratitude and donate regularly to sustain prosperity.$planetRef';
        case LifeAspect.family:
          return 'Nurture family bonds with quality time. Worship Moon on Mondays for domestic harmony.$planetRef';
        case LifeAspect.romance:
          return 'Your relationship sector is blessed. Honor Venus on Fridays through acts of love and beauty.$planetRef';
        case LifeAspect.health:
          return 'Maintain your healthy routines. Sun Salutations at dawn enhance vitality.$planetRef';
        case LifeAspect.children:
          return 'Creative and offspring matters flourish. Jupiter worship on Thursdays enhances blessings.$planetRef';
        case LifeAspect.education:
          return 'Knowledge acquisition comes naturally. Honor Saraswati and study during Mercury Hours.$planetRef';
        case LifeAspect.spirituality:
          return 'Your spiritual path is illuminated. Continue meditation practices and self-inquiry.$planetRef';
      }
    }

    // Provide remedial suggestions for weak planets with position references
    final buffer = StringBuffer();
    buffer.write('To enhance ${aspect.name.toLowerCase()}: ');

    for (final planet in weakPlanets.take(2)) {
      buffer.write(
        '${planet.planetName} (${planet.status}, currently ${planet.position.replaceFirst(planet.planetName, '').trim()}) needs strengthening — ',
      );
      final remedy = _getRemedyForPlanet(planet.planet);
      buffer.write(remedy);
      buffer.write(' ');
    }

    return buffer.toString();
  }

  /// Get remedy for a planet
  String _getRemedyForPlanet(Planet planet) {
    const remedies = {
      Planet.sun:
          'Offer water to Sun at sunrise and recite Aditya Hridayam on Sundays.',
      Planet.moon:
          'Wear pearl or moonstone, and observe fast on Mondays. Honor mother.',
      Planet.mars:
          'Recite Hanuman Chalisa on Tuesdays. Wear red coral after consultation.',
      Planet.mercury:
          'Worship Lord Vishnu on Wednesdays. Donate to education causes.',
      Planet.jupiter:
          'Fast on Thursdays and worship Lord Vishnu. Donate yellow items.',
      Planet.venus:
          'Worship Goddess Lakshmi on Fridays. Wear diamond or white sapphire.',
      Planet.saturn:
          'Recite Shani Stotra on Saturdays. Serve the elderly and donate to workers.',
      Planet.meanNode:
          'Donate to sweepers on Saturdays. Recite Rahu Mantra with sincerity.',
      Planet.trueNode:
          'Donate to sweepers on Saturdays. Recite Rahu Mantra with sincerity.',
    };
    return remedies[planet] ?? 'Consult an astrologer for specific remedies.';
  }

  /// Get ordinal suffix
  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}
