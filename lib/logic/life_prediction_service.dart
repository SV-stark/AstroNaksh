import 'package:jyotish/jyotish.dart';
import '../data/models.dart';
import '../data/life_prediction_models.dart';
import 'shadbala.dart';
import 'bhava_bala.dart';

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
    Map<String, double> shadbala,
    Map<int, BhavaStrength> bhavaBala,
  ) {
    // Collect planetary influences
    final influences = <PlanetaryInfluence>[];
    double totalInfluenceScore = 0;
    int influenceCount = 0;

    // Analyze primary planets for this aspect
    for (final planetName in aspect.primaryPlanets) {
      final influence = _analyzePlanetForAspect(
        chartData,
        planetName,
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
    double rawScore = influenceCount > 0
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
    String planetName,
    LifeAspect aspect,
    Map<String, double> shadbala, {
    bool isHouseLord = false,
    int? houseNumber,
  }) {
    // Find planet in chart
    final planet = _findPlanet(chartData, planetName);
    if (planet == null) return null;

    final sign = (planet.longitude / 30).floor();
    final house = _getHouseFromSign(chartData, sign);
    final signName = AstrologyConstants.signNames[sign];

    // Get planetary strength (normalized to 0-100)
    final rawStrength = shadbala[planetName] ?? 300;
    final strength = ((rawStrength / 600) * 100).clamp(0.0, 100.0);

    // Determine planetary status
    final status = _getPlanetaryStatus(planetName, sign);

    // Determine if benefic for this aspect
    final isBenefic = _isBeneficForAspect(
      chartData,
      planetName,
      aspect,
      sign,
      house,
      status,
    );

    // Build position description
    String position;
    if (isHouseLord && houseNumber != null) {
      position =
          '${_getOrdinal(houseNumber)} Lord $planetName in ${_getOrdinal(house)} House ($signName)';
    } else {
      position = '$planetName in ${_getOrdinal(house)} House ($signName)';
    }

    // Generate effect description
    final effect = _generateEffectDescription(
      planetName,
      aspect,
      status,
      isBenefic,
      house,
      isHouseLord,
      houseNumber,
    );

    return PlanetaryInfluence(
      planetName: planetName,
      position: position,
      status: status,
      strength: strength,
      effect: effect,
      isBenefic: isBenefic,
    );
  }

  /// Find planet in chart
  dynamic _findPlanet(CompleteChartData chartData, String planetName) {
    for (final entry in chartData.baseChart.planets.entries) {
      final planet = entry.value;
      final pName = entry.key.toString().split('.').last;
      if (pName == planetName ||
          pName.toLowerCase() == planetName.toLowerCase()) {
        return planet;
      }
    }
    return null;
  }

  /// Get house from sign based on ascendant
  int _getHouseFromSign(CompleteChartData chartData, int sign) {
    final ascSign = (chartData.baseChart.ascendant / 30).floor();
    return ((sign - ascSign + 12) % 12) + 1;
  }

  /// Get house lord
  String _getHouseLord(CompleteChartData chartData, int house) {
    final ascSign = (chartData.baseChart.ascendant / 30).floor();
    final houseSign = (ascSign + house - 1) % 12;
    return AstrologyConstants.getSignLord(houseSign);
  }

  /// Get planetary status (Exalted, Debilitated, Own Sign, etc.)
  String _getPlanetaryStatus(String planetName, int sign) {
    // Exaltation signs
    const exaltation = {
      'Sun': 0, // Aries
      'Moon': 1, // Taurus
      'Mars': 9, // Capricorn
      'Mercury': 5, // Virgo
      'Jupiter': 3, // Cancer
      'Venus': 11, // Pisces
      'Saturn': 6, // Libra
      'Rahu': 2, // Gemini
      'Ketu': 8, // Sagittarius
    };

    // Debilitation signs (opposite of exaltation)
    const debilitation = {
      'Sun': 6, // Libra
      'Moon': 7, // Scorpio
      'Mars': 3, // Cancer
      'Mercury': 11, // Pisces
      'Jupiter': 9, // Capricorn
      'Venus': 5, // Virgo
      'Saturn': 0, // Aries
      'Rahu': 8, // Sagittarius
      'Ketu': 2, // Gemini
    };

    // Own signs
    const ownSigns = {
      'Sun': [4], // Leo
      'Moon': [3], // Cancer
      'Mars': [0, 7], // Aries, Scorpio
      'Mercury': [2, 5], // Gemini, Virgo
      'Jupiter': [8, 11], // Sagittarius, Pisces
      'Venus': [1, 6], // Taurus, Libra
      'Saturn': [9, 10], // Capricorn, Aquarius
    };

    if (exaltation[planetName] == sign) {
      return 'Exalted';
    } else if (debilitation[planetName] == sign) {
      return 'Debilitated';
    } else if (ownSigns[planetName]?.contains(sign) ?? false) {
      return 'Own Sign';
    } else {
      // Check for friendly/enemy signs
      return _getFriendlyStatus(planetName, sign);
    }
  }

  /// Check if planet is in friendly, neutral, or enemy sign
  String _getFriendlyStatus(String planetName, int sign) {
    final signLord = AstrologyConstants.getSignLord(sign);

    // Planetary friendships
    const friends = {
      'Sun': ['Moon', 'Mars', 'Jupiter'],
      'Moon': ['Sun', 'Mercury'],
      'Mars': ['Sun', 'Moon', 'Jupiter'],
      'Mercury': ['Sun', 'Venus'],
      'Jupiter': ['Sun', 'Moon', 'Mars'],
      'Venus': ['Mercury', 'Saturn'],
      'Saturn': ['Mercury', 'Venus'],
    };

    const enemies = {
      'Sun': ['Venus', 'Saturn'],
      'Moon': [],
      'Mars': ['Mercury'],
      'Mercury': ['Moon'],
      'Jupiter': ['Mercury', 'Venus'],
      'Venus': ['Sun', 'Moon'],
      'Saturn': ['Sun', 'Moon', 'Mars'],
    };

    if (friends[planetName]?.contains(signLord) ?? false) {
      return 'Friendly Sign';
    } else if (enemies[planetName]?.contains(signLord) ?? false) {
      return 'Enemy Sign';
    }
    return 'Neutral Sign';
  }

  /// Determine if planet's influence is benefic for this aspect
  bool _isBeneficForAspect(
    CompleteChartData chartData,
    String planetName,
    LifeAspect aspect,
    int sign,
    int house,
    String status,
  ) {
    // Natural benefics
    const naturalBenefics = ['Jupiter', 'Venus', 'Mercury', 'Moon'];

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
      return naturalBenefics.contains(planetName) || status == 'Friendly Sign';
    }

    // Check if in kendra or trikona from relevant houses
    for (final aspectHouse in aspect.houses) {
      final distance = ((house - aspectHouse + 12) % 12) + 1;
      // Kendras (1, 4, 7, 10) and Trikonas (1, 5, 9) are good
      if ([1, 4, 5, 7, 9, 10].contains(distance)) {
        return naturalBenefics.contains(planetName);
      }
    }

    return naturalBenefics.contains(planetName);
  }

  /// Generate effect description
  String _generateEffectDescription(
    String planetName,
    LifeAspect aspect,
    String status,
    bool isBenefic,
    int house,
    bool isHouseLord,
    int? houseNumber,
  ) {
    final strengthWord = isBenefic ? 'supports' : 'challenges';
    final aspectArea = aspect.name.split(' ')[0].toLowerCase();

    String baseEffect;

    if (isHouseLord && houseNumber != null) {
      final houseSignificance = _getHouseSignificance(houseNumber);
      baseEffect =
          'Lord of $houseSignificance placed in ${_getOrdinal(house)} house';
    } else {
      baseEffect = '$planetName $strengthWord $aspectArea matters';
    }

    // Add status-specific details
    switch (status) {
      case 'Exalted':
        return '$baseEffect. $planetName is exalted, giving maximum strength and positive results.';
      case 'Debilitated':
        return '$baseEffect. $planetName is debilitated, indicating challenges that require effort to overcome.';
      case 'Own Sign':
        return '$baseEffect. $planetName is in its own sign, providing stability and good results.';
      case 'Friendly Sign':
        return '$baseEffect. $planetName is well-disposed in a friendly sign.';
      case 'Enemy Sign':
        return '$baseEffect. $planetName struggles in an inimical sign.';
      default:
        return '$baseEffect.';
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

    // Opening based on score
    if (score >= 80) {
      buffer.write(
        'Your chart shows excellent indications for ${aspect.name.toLowerCase()}. ',
      );
    } else if (score >= 65) {
      buffer.write(
        'The planetary positions indicate good potential for ${aspect.name.toLowerCase()}. ',
      );
    } else if (score >= 50) {
      buffer.write(
        'Mixed influences affect your ${aspect.name.toLowerCase()} with both opportunities and challenges. ',
      );
    } else {
      buffer.write(
        'Your chart indicates some challenges in ${aspect.name.toLowerCase()} that require focused attention. ',
      );
    }

    // House analysis
    buffer.write('\n\n');
    for (final house in aspect.houses) {
      final bhava = bhavaBala[house];
      if (bhava != null) {
        final strength = bhava.totalStrength;
        final houseDesc = _getHouseSignificance(house);
        if (strength >= 60) {
          buffer.write(
            'The ${_getOrdinal(house)} house ($houseDesc) is strong at ${strength.toStringAsFixed(0)}%, providing solid foundation. ',
          );
        } else if (strength >= 40) {
          buffer.write(
            'The ${_getOrdinal(house)} house ($houseDesc) has moderate strength at ${strength.toStringAsFixed(0)}%. ',
          );
        } else {
          buffer.write(
            'The ${_getOrdinal(house)} house ($houseDesc) is weak at ${strength.toStringAsFixed(0)}%, requiring remedial attention. ',
          );
        }
      }
    }

    // Key planetary influences
    final strongInfluences = influences.where((i) => i.strength >= 60).toList();
    final weakInfluences = influences.where((i) => i.strength < 40).toList();

    if (strongInfluences.isNotEmpty) {
      buffer.write('\n\n**Supportive Factors:** ');
      for (final influence in strongInfluences.take(2)) {
        buffer.write('${influence.planetName} (${influence.status}) ');
      }
      buffer.write('provide strength to this area of life.');
    }

    if (weakInfluences.isNotEmpty) {
      buffer.write('\n\n**Areas of Attention:** ');
      for (final influence in weakInfluences.take(2)) {
        buffer.write('${influence.planetName} (${influence.status}) ');
      }
      buffer.write('may need strengthening through remedies.');
    }

    return buffer.toString();
  }

  /// Generate advice
  String _generateAdvice(
    LifeAspect aspect,
    List<PlanetaryInfluence> influences,
    int score,
  ) {
    final weakPlanets = influences
        .where((i) => !i.isBenefic || i.strength < 50)
        .toList();

    if (weakPlanets.isEmpty || score >= 80) {
      switch (aspect) {
        case LifeAspect.career:
          return 'Continue leveraging your natural talents. Worship Sun on Sundays for sustained success.';
        case LifeAspect.wealth:
          return 'Your financial prospects are favorable. Maintain gratitude and donate regularly to sustain prosperity.';
        case LifeAspect.family:
          return 'Nurture family bonds with quality time. Worship Moon on Mondays for domestic harmony.';
        case LifeAspect.romance:
          return 'Your relationship sector is blessed. Honor Venus on Fridays through acts of love and beauty.';
        case LifeAspect.health:
          return 'Maintain your healthy routines. Sun Salutations at dawn enhance vitality.';
        case LifeAspect.children:
          return 'Creative and offspring matters flourish. Jupiter worship on Thursdays enhances blessings.';
        case LifeAspect.education:
          return 'Knowledge acquisition comes naturally. Honor Saraswati and study during Mercury Hours.';
        case LifeAspect.spirituality:
          return 'Your spiritual path is illuminated. Continue meditation practices and self-inquiry.';
      }
    }

    // Provide remedial suggestions for weak planets
    final buffer = StringBuffer();
    buffer.write('To enhance ${aspect.name.toLowerCase()}: ');

    for (final planet in weakPlanets.take(2)) {
      final remedy = _getRemedyForPlanet(planet.planetName);
      buffer.write(remedy);
      buffer.write(' ');
    }

    return buffer.toString();
  }

  /// Get remedy for a planet
  String _getRemedyForPlanet(String planetName) {
    const remedies = {
      'Sun':
          'Offer water to Sun at sunrise and recite Aditya Hridayam on Sundays.',
      'Moon':
          'Wear pearl or moonstone, and observe fast on Mondays. Honor mother.',
      'Mars':
          'Recite Hanuman Chalisa on Tuesdays. Wear red coral after consultation.',
      'Mercury':
          'Worship Lord Vishnu on Wednesdays. Donate to education causes.',
      'Jupiter':
          'Fast on Thursdays and worship Lord Vishnu. Donate yellow items.',
      'Venus':
          'Worship Goddess Lakshmi on Fridays. Wear diamond or white sapphire.',
      'Saturn':
          'Recite Shani Stotra on Saturdays. Serve the elderly and donate to workers.',
      'Rahu':
          'Donate to sweepers on Saturdays. Recite Rahu Mantra with sincerity.',
      'Ketu':
          'Worship Lord Ganesha. Practice meditation and develop detachment.',
    };
    return remedies[planetName] ??
        'Consult an astrologer for specific remedies.';
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
