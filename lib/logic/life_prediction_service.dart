import 'package:jyotish/jyotish.dart';

import '../data/life_prediction_models.dart';
import '../data/models.dart';
import 'bhava_bala.dart';
import 'shadbala.dart';

enum FunctionalStatus { benefic, malefic, neutral }

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
    final isRetrograde = planetInfo.isRetrograde;
    final isCombust = planetInfo.isCombust;

    final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
    final functionalStatus = _getFunctionalStatus(ascSign, planet);

    // Determine if benefic for this aspect
    final isBenefic = _isBeneficForAspect(
      chartData,
      planet,
      aspect,
      sign,
      house,
      status,
      isCombust: isCombust,
    );

    // Build position description with degrees
    var position = '';
    if (isHouseLord && houseNumber != null) {
      position =
          '${_getOrdinal(houseNumber)} Lord ${planet.displayName} at $degreeStr $signName in ${_getOrdinal(house)} House';
    } else {
      position =
          '${planet.displayName} at $degreeStr $signName in ${_getOrdinal(house)} House';
    }

    if (isRetrograde) position += ' (Retrograde)';
    if (isCombust) position += ' (Combust)';

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
      isRetrograde: isRetrograde,
      isCombust: isCombust,
      functionalStatus: functionalStatus,
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

  /// Get functional relationship status based on Lagna
  FunctionalStatus _getFunctionalStatus(int ascendant, Planet planet) {
    switch (ascendant) {
      case 0: // Aries
        if ([Planet.sun, Planet.moon, Planet.mars, Planet.jupiter].contains(planet)) return FunctionalStatus.benefic;
        if ([Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) return FunctionalStatus.malefic;
        break;
      case 1: // Taurus
        if ([Planet.sun, Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) return FunctionalStatus.benefic;
        if ([Planet.moon, Planet.mars, Planet.jupiter].contains(planet)) return FunctionalStatus.malefic;
        break;
      case 2: // Gemini
        if ([Planet.mercury, Planet.venus].contains(planet)) return FunctionalStatus.benefic;
        if ([Planet.sun, Planet.mars, Planet.jupiter].contains(planet)) return FunctionalStatus.malefic;
        break;
      case 3: // Cancer
        if ([Planet.moon, Planet.mars, Planet.jupiter].contains(planet)) return FunctionalStatus.benefic;
        if ([Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) return FunctionalStatus.malefic;
        break;
      case 4: // Leo
        if ([Planet.sun, Planet.mars, Planet.jupiter].contains(planet)) return FunctionalStatus.benefic;
        if ([Planet.moon, Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) return FunctionalStatus.malefic;
        break;
      case 5: // Virgo
        if ([Planet.mercury, Planet.venus].contains(planet)) return FunctionalStatus.benefic;
        if ([Planet.sun, Planet.moon, Planet.mars, Planet.jupiter].contains(planet)) return FunctionalStatus.malefic;
        break;
      case 6: // Libra
        if ([Planet.moon, Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) return FunctionalStatus.benefic;
        if ([Planet.sun, Planet.mars, Planet.jupiter].contains(planet)) return FunctionalStatus.malefic;
        break;
      case 7: // Scorpio
        if ([Planet.sun, Planet.moon, Planet.mars, Planet.jupiter].contains(planet)) return FunctionalStatus.benefic;
        if ([Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) return FunctionalStatus.malefic;
        break;
      case 8: // Sagittarius
        if ([Planet.sun, Planet.mars, Planet.jupiter].contains(planet)) return FunctionalStatus.benefic;
        if ([Planet.moon, Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) return FunctionalStatus.malefic;
        break;
      case 9: // Capricorn
        if ([Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) return FunctionalStatus.benefic;
        if ([Planet.sun, Planet.moon, Planet.mars, Planet.jupiter].contains(planet)) return FunctionalStatus.malefic;
        break;
      case 10: // Aquarius
        if ([Planet.sun, Planet.venus, Planet.saturn].contains(planet)) return FunctionalStatus.benefic;
        if ([Planet.moon, Planet.mars, Planet.jupiter].contains(planet)) return FunctionalStatus.malefic;
        break;
      case 11: // Pisces
        if ([Planet.moon, Planet.mars, Planet.jupiter].contains(planet)) return FunctionalStatus.benefic;
        if ([Planet.sun, Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) return FunctionalStatus.malefic;
        break;
    }
    return FunctionalStatus.neutral;
  }

  /// Determine if planet's influence is benefic for this aspect
  bool _isBeneficForAspect(
    CompleteChartData chartData,
    Planet planet,
    LifeAspect aspect,
    int sign,
    int house,
    String status, {
    bool isCombust = false,
  }) {
    if (isCombust) return false; // Combustion burns out the planet's positive externals

    final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
    final functional = _getFunctionalStatus(ascSign, planet);

    // Exalted and own sign generally support well unless they are functional malefics placed in Dusthanas
    if (status == 'Exalted' || status == 'Own Sign') {
      return functional != FunctionalStatus.malefic || ![6, 8, 12].contains(house);
    }

    // Debilitated status indicates challenges
    if (status == 'Debilitated') {
      return false;
    }

    // Functional status has high weight
    if (functional == FunctionalStatus.benefic) return true;
    if (functional == FunctionalStatus.malefic) return false;

    // Fallback to natural benefics
    final naturalBenefics = [
      Planet.jupiter,
      Planet.venus,
      Planet.mercury,
      Planet.moon,
    ];

    if (aspect.houses.contains(house)) {
      return naturalBenefics.contains(planet) || status == 'Friendly Sign';
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
    bool isRetrograde = false,
    bool isCombust = false,
    FunctionalStatus functionalStatus = FunctionalStatus.neutral,
  }) {
    final buffer = StringBuffer();
    final planetName = planet.displayName;
    final aspectArea = aspect.name.toLowerCase();

    // 1. Lordship or general influence
    if (isHouseLord && houseNumber != null) {
      final significance = _getHouseSignificance(houseNumber);
      buffer.write('As the Lord of the ${houseNumber}th house ($significance), ');
    } else {
      buffer.write('As a primary planetary significator of $aspectArea, ');
    }

    // 2. Functional status
    final functionalLabel = switch (functionalStatus) {
      FunctionalStatus.benefic => 'highly supportive functional benefic',
      FunctionalStatus.malefic => 'challenging functional malefic',
      FunctionalStatus.neutral => 'neutral planetary force',
    };
    buffer.write('$planetName acts as a $functionalLabel for your Ascendant. ');

    // 3. Placement, degrees, and dignity
    buffer.write('It is positioned at $degreeStr in $signName in the ${_getOrdinal(house)} house');
    switch (status) {
      case 'Exalted':
        buffer.write(' in an Exalted state, providing outstanding strength and highly auspicious energy for these matters.');
        break;
      case 'Own Sign':
        buffer.write(' in its own sign, granting excellent stability, natural confidence, and smooth operations.');
        break;
      case 'Friendly Sign':
        buffer.write(' in a friendly sign, enabling a comfortable and supportive expression of its positive vibrations.');
        break;
      case 'Enemy Sign':
        buffer.write(' in an enemy sign, causing friction, resistance, and requiring self-discipline to channel constructively.');
        break;
      case 'Debilitated':
        buffer.write(' in a debilitated state, pointing to structural weaknesses, energy blocks, or lessons that demand persistent discipline.');
        break;
      default:
        buffer.write(' in a neutral state.');
    }

    // 4. Retrograde or combustion modifiers
    if (isRetrograde) {
      buffer.write(' Being Retrograde (Rx), its energy is turned inward, prompting self-reflection, potential delays, or a karmic re-examination.');
    }
    if (isCombust) {
      buffer.write(' Because it is Combust (too close to the Sun), its external capabilities are obscured, indicating hidden trials or self-limitations.');
    }

    // 5. Normalized strength
    buffer.write(' Shadbala strength is ${strength.toStringAsFixed(0)}% (');
    if (strength >= 70) {
      buffer.write('exceptionally strong).');
    } else if (strength >= 40) {
      buffer.write('moderately stable).');
    } else {
      buffer.write('delicate, needing conscious reinforcement).');
    }

    return buffer.toString();
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
    final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
    final ascSignName = AstrologyConstants.getSignName(ascSign);

    // 1. Executive Synthesis
    buffer.write('### Cosmic Overview & Analysis\n');
    buffer.write(
      'For your **$ascSignName Ascendant (Lagna)**, the astrological indicators governing **${aspect.name}** are analyzed. '
    );

    if (score >= 80) {
      buffer.write(
        'Your birth chart indicates exceptional strength in this sphere, rated at an **Excellent** overall index of **$score%**. '
        'This represents highly favorable alignment of planetary forces, providing native ease, abundance, and structural support for these matters. '
      );
    } else if (score >= 65) {
      buffer.write(
        'The alignments indicate a **Favorable** and stable pattern, rated at **$score%**. '
        'This shows stable support with constructive opportunities, where consistent effort will bring growth and rewarding results. '
      );
    } else if (score >= 50) {
      buffer.write(
        'Your chart exhibits **Mixed** influences, rated at **$score%**. '
        'While there are active sources of strength, certain planetary frictions, debilitations, or placement challenges create obstacles that require awareness and focus. '
      );
    } else {
      buffer.write(
        'This area presents **Challenging** indications, rated at **$score%**. '
        'Planetary blockages, debilitations, or unfavorable placements demand caution. Focused discipline, inner growth, and remedial support are recommended. '
      );
    }

    // 2. House Lord Placement
    buffer.write('\n\n### Bhava (House) & Lordship Analysis\n');
    for (final house in aspect.houses) {
      final bhava = bhavaBala[house];
      final strength = bhava?.totalStrength ?? 50.0;
      final houseDesc = _getHouseSignificance(house);
      final houseLord = _getHouseLord(chartData, house);
      final lordInfo = chartData.baseChart.planets[houseLord];

      buffer.write('**The ${_getOrdinal(house)} House ($houseDesc):** ');
      buffer.write(
        'This house has a Bhava Bala of **${strength.toStringAsFixed(0)}%**, representing a '
      );
      if (strength >= 60) {
        buffer.write('highly robust foundation. ');
      } else if (strength >= 40) {
        buffer.write('moderately stable foundation. ');
      } else {
        buffer.write('delicate foundation that requires conscious strengthening. ');
      }

      if (lordInfo != null) {
        final lordSignIdx = lordInfo.position.zodiacSignIndex;
        final lordSignName = AstrologyConstants.getSignName(lordSignIdx);
        final lordHouse = _getHouseFromSign(chartData, lordSignIdx);
        final lordDignity = lordInfo.dignity.name;
        final isLordRetro = lordInfo.isRetrograde;
        final isLordCombust = lordInfo.isCombust;

        buffer.write(
          'Its lord, **${houseLord.displayName}**, is positioned in the **${_getOrdinal(lordHouse)} house** ($lordSignName). '
        );

        if ([6, 8, 12].contains(lordHouse)) {
          buffer.write(
            'Because the house lord is placed in a Dusthana (difficult) house, it indicates that the benefits of the ${house}th house may feel obstructed, delayed, or require spiritual transformation to manifest. '
          );
        } else if ([1, 4, 7, 10, 5, 9].contains(lordHouse)) {
          buffer.write(
            'Since the house lord resides in an auspicious Kendra or Trikona house, it channels highly positive, progressive energy, ensuring that this house\'s indications are well-supported. '
          );
        }

        if (lordDignity == 'Exalted') {
          buffer.write('The lord\'s Exalted state further magnifies its capacity to deliver extraordinary outcomes. ');
        } else if (lordDignity == 'Debilitated') {
          buffer.write('The lord\'s Debilitated status indicates a lack of external power, suggesting that you must build inner resilience to overcome related challenges. ');
        } else if (lordDignity == 'Own Sign') {
          buffer.write('Placed in its own sign, the lord remains highly stable and self-sufficient. ');
        }

        if (isLordRetro) {
          buffer.write('Being Retrograde, the lord\'s influence is introspective, requiring internal reflection before external success. ');
        }
        if (isLordCombust) {
          buffer.write('Since it is Combust, the lord\'s outer expression is weakened, bringing hidden vulnerabilities. ');
        }
      }
      buffer.write('\n\n');
    }

    // 3. Synthesis of Key Influences
    buffer.write('### Key Astrological Influences\n');
    final beneficInfluences = influences.where((i) => i.isBenefic).toList();
    final maleficInfluences = influences.where((i) => !i.isBenefic).toList();

    if (beneficInfluences.isNotEmpty) {
      buffer.write('**Positive Assets:**\n');
      for (final influence in beneficInfluences) {
        buffer.write('- **${influence.position}**: ${influence.effect}\n');
      }
      buffer.write('\n');
    }

    if (maleficInfluences.isNotEmpty) {
      buffer.write('**Areas needing Awareness:**\n');
      for (final influence in maleficInfluences) {
        buffer.write('- **${influence.position}**: ${influence.effect}\n');
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
    final buffer = StringBuffer();

    // 1. Overall guidance based on aspect type
    switch (aspect) {
      case LifeAspect.career:
        buffer.write('To elevate your career: focus on establishing long-term professional discipline. ');
        break;
      case LifeAspect.wealth:
        buffer.write('To cultivate financial abundance: maintain rigorous budget habits and prioritize asset accumulation. ');
        break;
      case LifeAspect.family:
        buffer.write('To nourish family harmony: practice empathetic communication and create a calm domestic routine. ');
        break;
      case LifeAspect.romance:
        buffer.write('To harmonize relationships: foster mutual respect, transparency, and balance of power. ');
        break;
      case LifeAspect.health:
        buffer.write('To maximize vitality: implement daily physical activity, proper diet, and rhythmic sleep cycles. ');
        break;
      case LifeAspect.children:
        buffer.write('To support creative growth and children: encourage playfulness, intellect, and constructive guidance. ');
        break;
      case LifeAspect.education:
        buffer.write('To enhance wisdom: cultivate continuous study, analytical training, and respect for mentors. ');
        break;
      case LifeAspect.spirituality:
        buffer.write('To deepen spiritual connection: dedicate time for daily introspection, meditation, and self-inquiry. ');
        break;
    }

    // 2. Weak/Malefic planetary remedies
    final weakInfluences = influences.where((i) => !i.isBenefic || i.strength < 50).toList();
    if (weakInfluences.isNotEmpty) {
      buffer.write('\n\n**Remedial Measures (Upayas):** ');
      for (final influence in weakInfluences.take(2)) {
        buffer.write(
          'For **${influence.planetName}** (${influence.status}, currently placed in the ${influence.position.split('in ').last}): '
        );
        buffer.write(_getRemedyForPlanet(influence.planet));
        buffer.write(' ');
      }
    } else {
      // If everything is extremely strong, give a positive booster remedy
      final topPlanet = influences.isNotEmpty ? influences.first : null;
      if (topPlanet != null) {
        buffer.write('\n\nYour **${topPlanet.planetName}** is exceptionally well-placed. You can further amplify its positive vibration: ');
        buffer.write(_getRemedyForPlanet(topPlanet.planet));
      }
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
