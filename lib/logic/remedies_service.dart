import 'package:jyotish/jyotish.dart';
import '../data/models.dart';

class RemediesService {
  static CompleteRemediesProfile generateRemediesProfile(VedicChart chart) {
    final ascendantDeg = chart.houses.ascendant;
    final ascSignIndex = (ascendantDeg / 30).floor() % 12;

    final lagnaLord = AstrologyConstants.getSignLord(ascSignIndex).displayName;
    final fifthSignIndex = (ascSignIndex + 4) % 12;
    final fifthLord = AstrologyConstants.getSignLord(fifthSignIndex).displayName;
    final ninthSignIndex = (ascSignIndex + 8) % 12;
    final ninthLord = AstrologyConstants.getSignLord(ninthSignIndex).displayName;

    final gemstones = <GemstoneRecommendation>[];

    // 1. Life Stone (Lagna Lord)
    gemstones.add(
      _buildGemstoneRecommendation(
        planet: lagnaLord,
        type: GemstoneType.life,
        ascSignIndex: ascSignIndex,
        chart: chart,
        benefits: 'Enhances physical health, vitality, status, self-confidence, and general immunity.',
      ),
    );

    // 2. Benefic / Punyam Stone (5th Lord)
    if (fifthLord != lagnaLord) {
      gemstones.add(
        _buildGemstoneRecommendation(
          planet: fifthLord,
          type: GemstoneType.benefic,
          ascSignIndex: ascSignIndex,
          chart: chart,
          benefits: 'Boosts intelligence, focus, creative talents, financial luck, and progeny prospects.',
        ),
      );
    }

    // 3. Bhagya / Fortune Stone (9th Lord)
    if (ninthLord != lagnaLord && ninthLord != fifthLord) {
      gemstones.add(
        _buildGemstoneRecommendation(
          planet: ninthLord,
          type: GemstoneType.bhagya,
          ascSignIndex: ascSignIndex,
          chart: chart,
          benefits: 'Attracts divine luck, higher education, spiritual growth, and career prosperity.',
        ),
      );
    }

    // Planetary Remedies for all 9 planets
    final planetaryRemedies = <PlanetaryRemedy>[];
    final planetsList = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Rahu', 'Ketu'];

    for (final planet in planetsList) {
      final remedy = _buildPlanetaryRemedy(planet, chart, ascSignIndex);
      if (remedy != null) {
        planetaryRemedies.add(remedy);
      }
    }

    // Primary Rudraksha based on Lagna Lord
    final primaryRudraksha = _getRudrakshaForPlanet(lagnaLord);

    final ascName = AstrologyConstants.getSignName(ascSignIndex);
    final guidanceNote =
        'For $ascName Ascendant, the primary functional benefics are $lagnaLord, $fifthLord, and $ninthLord. '
        'Gemstones should only be worn for functional benefic planets in favorable houses (1, 4, 5, 7, 9, 10, 11). '
        'For planets in dusthana houses (6, 8, 12), mantra chanting and charity are recommended instead of gemstones.';

    return CompleteRemediesProfile(
      gemstones: gemstones,
      planetaryRemedies: planetaryRemedies,
      primaryRudraksha: primaryRudraksha,
      overallGuidanceNote: guidanceNote,
    );
  }

  static GemstoneRecommendation _buildGemstoneRecommendation({
    required String planet,
    required GemstoneType type,
    required int ascSignIndex,
    required VedicChart chart,
    required String benefits,
  }) {
    final details = _gemstoneData[planet] ?? _gemstoneData['Sun']!;
    final isDusthana = _isPlanetInDusthana(planet, chart);
    final isMalefic = _isFunctionalMalefic(planet, ascSignIndex);

    final safeToWear = !isDusthana && !isMalefic;
    var caution = '';
    if (isDusthana) {
      caution = '$planet is placed in a Dusthana house (6, 8, or 12). Avoid wearing gemstones without consulting an expert; prefer Mantra chanting.';
    } else if (isMalefic) {
      caution = '$planet acts as a functional malefic for this Ascendant. Gemstone wearing is not advised.';
    }

    return GemstoneRecommendation(
      planet: planet,
      primaryGemstone: details['gemstone'] as String,
      substituteGemstones: details['substitutes'] as List<String>,
      type: type,
      metal: details['metal'] as String,
      finger: details['finger'] as String,
      dayToWear: details['day'] as String,
      weightRecommendation: details['weight'] as String,
      keyBenefits: benefits,
      isSafeToWear: safeToWear,
      cautionNote: caution,
    );
  }

  static PlanetaryRemedy? _buildPlanetaryRemedy(
    String planet,
    VedicChart chart,
    int ascSignIndex,
  ) {
    final isDusthana = _isPlanetInDusthana(planet, chart);
    final isMalefic = _isFunctionalMalefic(planet, ascSignIndex);
    final data = _remedyData[planet];

    if (data == null) return null;

    var affliction = 'Standard planetary balance remedy.';
    if (isDusthana) {
      affliction = 'Placed in 6th, 8th, or 12th House (Dusthana affliction).';
    } else if (isMalefic) {
      affliction = 'Acts as a functional malefic for this Ascendant.';
    }

    return PlanetaryRemedy(
      planet: planet,
      afflictionReason: affliction,
      beejMantra: data['mantra'] as String,
      mantraRecitationCount: data['count'] as int,
      rudrakshaMukhi: data['rudraksha'] as String,
      fastingDay: data['fasting'] as String,
      charityItems: data['charity'] as String,
      deityToWorship: data['deity'] as String,
      favorableDirection: data['direction'] as String,
      favorableColor: data['color'] as String,
    );
  }

  static bool _isPlanetInDusthana(String planet, VedicChart chart) {
    double pLongitude = 0;
    chart.planets.forEach((p, info) {
      if (p.displayName.toLowerCase() == planet.toLowerCase()) {
        pLongitude = info.longitude;
      }
    });

    final ascendantDeg = chart.houses.ascendant;

    // House calculation
    var houseIndex = 1 + ((pLongitude - ascendantDeg + 360) % 360 / 30).floor();
    if (houseIndex > 12) houseIndex -= 12;

    return houseIndex == 6 || houseIndex == 8 || houseIndex == 12;
  }

  static bool _isFunctionalMalefic(String planet, int ascSignIndex) {
    const maleficMap = {
      0: ['Mercury', 'Saturn', 'Venus'],
      1: ['Jupiter', 'Venus', 'Mars'],
      2: ['Mars', 'Jupiter', 'Sun'],
      3: ['Mercury', 'Saturn', 'Venus'],
      4: ['Mercury', 'Venus', 'Saturn'],
      5: ['Mars', 'Jupiter', 'Moon'],
      6: ['Sun', 'Jupiter', 'Mars'],
      7: ['Mercury', 'Venus'],
      8: ['Venus', 'Saturn'],
      9: ['Mars', 'Jupiter'],
      10: ['Moon', 'Mars', 'Jupiter'],
      11: ['Sun', 'Mercury', 'Venus', 'Saturn'],
    };

    final list = maleficMap[ascSignIndex] ?? [];
    return list.contains(planet);
  }

  static String _getRudrakshaForPlanet(String planet) {
    final map = {
      'Sun': '12-Mukhi (Surya Rudraksha) - Enhances leadership, health & authority',
      'Moon': '2-Mukhi (Chandra Rudraksha) - Promotes emotional stability & peace',
      'Mars': '3-Mukhi (Agni/Mangal Rudraksha) - Boosts courage, energy & blood vitality',
      'Mercury': '4-Mukhi (Brahma/Budh Rudraksha) - Enhances intellect, speech & memory',
      'Jupiter': '5-Mukhi (Guru/Shiva Rudraksha) - Universal bead for wisdom & health',
      'Venus': '6-Mukhi (Kartikeya/Shukra Rudraksha) - Grants artistic skill, beauty & charm',
      'Saturn': '7-Mukhi (Mahalakshmi/Shani Rudraksha) - Overcomes financial obstacles & delays',
      'Rahu': '8-Mukhi (Ganesha/Rahu Rudraksha) - Removes sudden hurdles & confusion',
      'Ketu': '9-Mukhi (Durga/Ketu Rudraksha) - Enhances intuition, protection & liberation',
    };
    return map[planet] ?? '5-Mukhi Rudraksha';
  }

  static const Map<String, Map<String, dynamic>> _gemstoneData = {
    'Sun': {
      'gemstone': 'Ruby (Manik)',
      'substitutes': ['Red Garnet', 'Star Ruby', 'Red Spinel'],
      'metal': 'Gold or Copper',
      'finger': 'Ring Finger (Right Hand)',
      'day': 'Sunday morning during Shukla Paksha',
      'weight': '3 to 5 Ratti',
    },
    'Moon': {
      'gemstone': 'Natural Pearl (Moti)',
      'substitutes': ['Moonstone', 'White Coral'],
      'metal': 'Silver',
      'finger': 'Little Finger (Right Hand)',
      'day': 'Monday morning during Shukla Paksha',
      'weight': '4 to 6 Ratti',
    },
    'Mars': {
      'gemstone': 'Red Coral (Moonga)',
      'substitutes': ['Red Carnelian'],
      'metal': 'Copper or Gold',
      'finger': 'Ring Finger (Right Hand)',
      'day': 'Tuesday morning during Shukla Paksha',
      'weight': '6 to 9 Ratti',
    },
    'Mercury': {
      'gemstone': 'Emerald (Panna)',
      'substitutes': ['Peridot', 'Green Tourmaline'],
      'metal': 'Gold or Brass',
      'finger': 'Little Finger (Right Hand)',
      'day': 'Wednesday morning during Shukla Paksha',
      'weight': '3 to 6 Ratti',
    },
    'Jupiter': {
      'gemstone': 'Yellow Sapphire (Pukhraj)',
      'substitutes': ['Yellow Topaz', 'Citrine (Sunela)'],
      'metal': 'Gold or Yellow Brass',
      'finger': 'Index Finger (Right Hand)',
      'day': 'Thursday morning during Shukla Paksha',
      'weight': '4 to 7 Ratti',
    },
    'Venus': {
      'gemstone': 'Diamond (Heera)',
      'substitutes': ['White Sapphire', 'Opal', 'Zircon'],
      'metal': 'Platinum, White Gold or Silver',
      'finger': 'Middle or Little Finger (Right Hand)',
      'day': 'Friday morning during Shukla Paksha',
      'weight': '0.5 to 1.5 Carats (Diamond) or 6-8 Ratti (Opal)',
    },
    'Saturn': {
      'gemstone': 'Blue Sapphire (Neelam)',
      'substitutes': ['Amethyst (Jamuniya)', 'Blue Topaz'],
      'metal': 'Iron, Panchdhatu or Silver',
      'finger': 'Middle Finger (Right Hand)',
      'day': 'Saturday evening',
      'weight': '4 to 7 Ratti',
    },
    'Rahu': {
      'gemstone': 'Hessonite Garnet (Gomed)',
      'substitutes': ['Spessartite Garnet'],
      'metal': 'Silver or Panchdhatu',
      'finger': 'Middle Finger (Right Hand)',
      'day': 'Saturday evening',
      'weight': '5 to 8 Ratti',
    },
    'Ketu': {
      'gemstone': "Cat's Eye (Lehsuniya)",
      'substitutes': ['Turquoise', 'Tiger Eye'],
      'metal': 'Panchdhatu or Silver',
      'finger': 'Ring Finger (Right Hand)',
      'day': 'Tuesday or Thursday evening',
      'weight': '4 to 7 Ratti',
    },
  };

  static const Map<String, Map<String, dynamic>> _remedyData = {
    'Sun': {
      'mantra': 'Om Hram Hreem Hroum Sah Suryaya Namah',
      'count': 7000,
      'rudraksha': '12-Mukhi Rudraksha',
      'fasting': 'Sunday',
      'charity': 'Wheat, Jaggery, Copper utensils, Red Flowers',
      'deity': 'Lord Surya / Gayatri Mata',
      'direction': 'East',
      'color': 'Ruby Red / Gold',
    },
    'Moon': {
      'mantra': 'Om Shram Shreem Shroum Sah Chandraya Namah',
      'count': 11000,
      'rudraksha': '2-Mukhi Rudraksha',
      'fasting': 'Monday',
      'charity': 'Rice, Milk, White Cloth, Silver, Sugar',
      'deity': 'Lord Shiva / Parvati Devi',
      'direction': 'North-West',
      'color': 'Pearl White / Silver',
    },
    'Mars': {
      'mantra': 'Om Kram Kreem Kroum Sah Bhaumaya Namah',
      'count': 10000,
      'rudraksha': '3-Mukhi Rudraksha',
      'fasting': 'Tuesday',
      'charity': 'Red Masoor Dal, Jaggery, Red Cloth, Copper',
      'deity': 'Lord Hanuman / Lord Kartikeya',
      'direction': 'South',
      'color': 'Crimson Red',
    },
    'Mercury': {
      'mantra': 'Om Bram Breem Broum Sah Budhaya Namah',
      'count': 9000,
      'rudraksha': '4-Mukhi Rudraksha',
      'fasting': 'Wednesday',
      'charity': 'Green Moong Dal, Green Clothes, Spinach, Brass',
      'deity': 'Lord Vishnu / Lord Ganesha',
      'direction': 'North',
      'color': 'Emerald Green',
    },
    'Jupiter': {
      'mantra': 'Om Gram Greem Groum Sah Gurave Namah',
      'count': 19000,
      'rudraksha': '5-Mukhi Rudraksha',
      'fasting': 'Thursday',
      'charity': 'Chana Dal, Turmeric, Yellow Clothes, Gold, Religious Books',
      'deity': 'Lord Dakshinamurthy / Lord Dattatreya',
      'direction': 'North-East',
      'color': 'Yellow / Bright Amber',
    },
    'Venus': {
      'mantra': 'Om Dram Dreem Droum Sah Shukraya Namah',
      'count': 16000,
      'rudraksha': '6-Mukhi Rudraksha',
      'fasting': 'Friday',
      'charity': 'White Clothes, Ghee, Sugar, Camphor, Perfumes',
      'deity': 'Maha Lakshmi / Annapurna Devi',
      'direction': 'South-East',
      'color': 'Pure White / Pastel Shades',
    },
    'Saturn': {
      'mantra': 'Om Pram Preem Proum Sah Shanaishcharaya Namah',
      'count': 23000,
      'rudraksha': '7-Mukhi Rudraksha',
      'fasting': 'Saturday',
      'charity': 'Black Sesame (Til), Mustard Oil, Black Urad, Iron, Black Blanket',
      'deity': 'Lord Shani / Lord Hanuman / Rudra',
      'direction': 'West',
      'color': 'Dark Blue / Black',
    },
    'Rahu': {
      'mantra': 'Om Bhram Bhreem Bhroum Sah Rahave Namah',
      'count': 18000,
      'rudraksha': '8-Mukhi Rudraksha',
      'fasting': 'Saturday',
      'charity': 'Lead, Coconut, Mustard seeds, Blue clothes, Blankets for needy',
      'deity': 'Goddess Durga / Lord Bhairava',
      'direction': 'South-West',
      'color': 'Smokey Grey / Electric Blue',
    },
    'Ketu': {
      'mantra': 'Om Stram Streem Stroum Sah Ketave Namah',
      'count': 17000,
      'rudraksha': '9-Mukhi Rudraksha',
      'fasting': 'Tuesday',
      'charity': 'Multi-colored Blanket, Sesame, Bananas, Feeding street dogs',
      'deity': 'Lord Ganesha / Lord Narasimha',
      'direction': 'North-East',
      'color': 'Multi-color / Brown / Turquoise',
    },
  };
}
