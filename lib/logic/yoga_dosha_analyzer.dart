import '../data/models.dart';

/// Yoga and Dosha Analyzer
/// Detects auspicious (Yoga) and inauspicious (Dosha) combinations.
class YogaDoshaAnalyzer {
  /// Analyze chart for common Yogas and Doshas
  static Map<String, dynamic> analyze(CompleteChartData chart) {
    return {'yogas': _findYogas(chart), 'doshas': _findDoshas(chart)};
  }

  // --- Dosha Detection ---

  static List<String> _findDoshas(CompleteChartData chart) {
    List<String> doshas = [];

    // 1. Kaal Sarp Dosha
    // All planets between Rahu and Ketu
    if (_hasKaalSarpDosha(chart)) {
      doshas.add('Kaal Sarp Dosha');
    }

    // 2. Manglik Dosha (Kuja Dosha)
    // Mars in 1, 2, 4, 7, 8, 12 from Lagna, Moon, and Venus
    // Strict calculation often checks Lagna primarily
    if (_hasMangalDosha(chart)) {
      doshas.add('Manglik Dosha (Mars in sensitive house)');
    }

    // 3. Pitra Dosha
    // Sun/Moon afflicted by Rahu/Ketu or Saturn
    if (_hasPitraDosha(chart)) {
      doshas.add('Pitra Dosha');
    }

    // 4. Kemadruma Dosha
    // No planets on either side of Moon (2nd and 12th from Moon empty)
    if (_hasKemadrumaDosha(chart)) {
      doshas.add('Kemadruma Dosha (Lonely Moon)');
    }

    return doshas;
  }

  static bool _hasKaalSarpDosha(CompleteChartData chart) {
    // Get Rahu/Ketu longitudes
    final rahu = _getPlanetLongitude(chart, 'Rahu');
    final ketu = _getPlanetLongitude(chart, 'Ketu');

    // Check if all other 7 planets are within one side of the axis
    // Axis 1: Rahu to Ketu (approx 180 deg)
    // Axis 2: Ketu to Rahu

    bool side1 = true;
    bool side2 = true;

    for (var p in [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ]) {
      final long = _getPlanetLongitude(chart, p);
      if (!_isBetween(long, rahu, ketu)) side1 = false;
      if (!_isBetween(long, ketu, rahu)) side2 = false;
    }

    return side1 || side2;
  }

  static bool _hasMangalDosha(CompleteChartData chart) {
    // Mars in 1, 2, 4, 7, 8, 12 from Lagna, Moon, and Venus
    final marsSign = _getPlanetSign(chart, 'Mars');
    final lagnaSign = _getAscendantSign(chart);
    final moonSign = _getPlanetSign(chart, 'Moon');
    final venusSign = _getPlanetSign(chart, 'Venus');

    // Check from all three
    bool fromLagna = _isMarsInBadHouse(marsSign, lagnaSign);
    bool fromMoon = _isMarsInBadHouse(marsSign, moonSign);
    bool fromVenus = _isMarsInBadHouse(marsSign, venusSign);

    // Traditional: 2 out of 3 confirms Manglik
    int count = [fromLagna, fromMoon, fromVenus].where((x) => x).length;
    return count >= 2;
  }

  static bool _isMarsInBadHouse(int marsSign, int refSign) {
    int house = (marsSign - refSign + 12) % 12 + 1;
    return [1, 2, 4, 7, 8, 12].contains(house);
  }

  static bool _hasPitraDosha(CompleteChartData chart) {
    // Simple check: Sun or Moon conjoined with Rahu or Ketu
    final sunSign = _getPlanetSign(chart, 'Sun');
    final moonSign = _getPlanetSign(chart, 'Moon');
    final rahuSign = _getPlanetSign(chart, 'Rahu');
    final ketuSign = _getPlanetSign(chart, 'Ketu');

    return (sunSign == rahuSign ||
        sunSign == ketuSign ||
        moonSign == rahuSign ||
        moonSign == ketuSign);
  }

  static bool _hasKemadrumaDosha(CompleteChartData chart) {
    final moonSign = _getPlanetSign(chart, 'Moon');
    final prevSign = (moonSign - 1 + 12) % 12;
    final nextSign = (moonSign + 1) % 12;

    // Check if any planet (except Sun, Rahu, Ketu) is in prev or next sign
    bool hasSupport = false;
    for (var p in ['Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn']) {
      final sign = _getPlanetSign(chart, p);
      if (sign == prevSign || sign == nextSign || sign == moonSign) {
        // Conjunction counts too often
        hasSupport = true;
        break;
      }
    }

    return !hasSupport;
  }

  // --- Yoga Detection ---

  static List<String> _findYogas(CompleteChartData chart) {
    List<String> yogas = [];

    // 1. Gajakesari Yoga
    if (_hasGajakesariYoga(chart)) {
      yogas.add('Gajakesari Yoga (Jupiter Kendra from Moon)');
    }

    // 2. Budhaditya Yoga
    if (_hasBudhadityaYoga(chart)) {
      yogas.add('Budhaditya Yoga (Sun-Mercury Conjunction)');
    }

    // 3. Chandra Mangala Yoga
    if (_hasChandraMangalaYoga(chart)) {
      yogas.add('Chandra Mangala Yoga');
    }

    // 5. Raj Yoga (Kendra-Trikona lords)
    if (_hasRajYoga(chart)) {
      yogas.add('Raj Yoga (Kendra-Trikona Lord Combination)');
    }

    // 6. Dhana Yoga (Wealth combinations)
    yogas.addAll(_findDhanaYogas(chart));

    // 7. Vipreet Raj Yoga (Lords of 6,8,12 in mutual exchanges)
    yogas.addAll(_findVipreetRajYogas(chart));

    // 8. Neecha Bhanga Raj Yoga (Debilitation cancellation)
    yogas.addAll(_findNeechaBhangaYogas(chart));

    // 9. Parivartana Yoga (Exchange of signs)
    yogas.addAll(_findParivartanaYogas(chart));

    // 10. Gaja Kesari variations
    if (_hasStrongGajakesariYoga(chart)) {
      yogas.add('Strong Gajakesari (Jupiter exalted/own in Kendra from Moon)');
    }

    // 11. Adhi Yoga (Benefics in 6,7,8 from Moon)
    if (_hasAdhiYoga(chart)) {
      yogas.add('Adhi Yoga (Benefics around Moon)');
    }

    // 12. Lakshmi Yoga (Venus with lord of 9th)
    if (_hasLakshmiYoga(chart)) {
      yogas.add('Lakshmi Yoga (Venus-9th lord combination)');
    }

    // 13. Saraswati Yoga (Jupiter, Venus, Mercury combination)
    if (_hasSaraswatiYoga(chart)) {
      yogas.add('Saraswati Yoga (Arts and Learning)');
    }

    // 14. Amala Yoga (Benefic in 10th from Lagna/Moon)
    if (_hasAmalaYoga(chart)) {
      yogas.add('Amala Yoga (Pure reputation)');
    }

    // 15. Parvata Yoga (Benefics in Kendras, no malefics)
    if (_hasParvataYoga(chart)) {
      yogas.add('Parvata Yoga (Elevated status)');
    }

    // 16. Kahala Yoga (4th and 9th lords in mutual kendras)
    if (_hasKahalaYoga(chart)) {
      yogas.add('Kahala Yoga (Stubborn valor)');
    }

    // 17. Chamara Yoga (Lagna lord exalted in kendra)
    if (_hasChamaraYoga(chart)) {
      yogas.add('Chamara Yoga (Royal attendants)');
    }

    // 18. Sankha Yoga (5th and 6th lords in mutual kendras)
    if (_hasSankhaYoga(chart)) {
      yogas.add('Sankha Yoga (Conch - wealth and fame)');
    }

    return yogas;
  }

  // --- Dhana Yogas (Wealth) ---
  static List<String> _findDhanaYogas(CompleteChartData chart) {
    List<String> yogas = [];

    // 2nd and 11th lords conjunction/exchange
    final secondLord = _getHouseLord(chart, 2);
    final eleventhLord = _getHouseLord(chart, 11);

    if (_areConjunct(chart, secondLord, eleventhLord)) {
      yogas.add('Dhana Yoga (2nd-11th lords conjunct - wealth accumulation)');
    }

    // 9th and 10th lords conjunction (fortune and career)
    final ninthLord = _getHouseLord(chart, 9);
    final tenthLord = _getHouseLord(chart, 10);

    if (_areConjunct(chart, ninthLord, tenthLord)) {
      yogas.add('Dhana Yoga (9th-10th lords conjunct - fortunate career)');
    }

    // 5th and 9th lords conjunction (intelligence and fortune)
    final fifthLord = _getHouseLord(chart, 5);

    if (_areConjunct(chart, fifthLord, ninthLord)) {
      yogas.add('Dhana Yoga (5th-9th lords conjunct - speculative gains)');
    }

    return yogas;
  }

  // --- Vipreet Raj Yogas (Adversity turned to advantage) ---
  static List<String> _findVipreetRajYogas(CompleteChartData chart) {
    List<String> yogas = [];

    final sixthLord = _getHouseLord(chart, 6);
    final eighthLord = _getHouseLord(chart, 8);
    final twelfthLord = _getHouseLord(chart, 12);

    // Harsha Yoga: 6th lord in 6th/8th/12th
    final sixthSign = _getPlanetSign(chart, sixthLord);
    if (_isInDusthaHouse(chart, sixthSign)) {
      yogas.add('Harsha Vipreet Raj Yoga (6th lord in dusthana)');
    }

    // Sarala Yoga: 8th lord in 6th/8th/12th
    final eighthSign = _getPlanetSign(chart, eighthLord);
    if (_isInDusthaHouse(chart, eighthSign)) {
      yogas.add('Sarala Vipreet Raj Yoga (8th lord in dusthana)');
    }

    // Vimala Yoga: 12th lord in 6th/8th/12th
    final twelfthSign = _getPlanetSign(chart, twelfthLord);
    if (_isInDusthaHouse(chart, twelfthSign)) {
      yogas.add('Vimala Vipreet Raj Yoga (12th lord in dusthana)');
    }

    return yogas;
  }

  // --- Neecha Bhanga Raj Yogas (Debilitation cancellation) ---
  static List<String> _findNeechaBhangaYogas(CompleteChartData chart) {
    List<String> yogas = [];

    for (var planet in [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ]) {
      final sign = _getPlanetSign(chart, planet);

      if (_isDebilitated(planet, sign)) {
        // Check if debilitation is cancelled
        final debilSignLord = _getSignLord(sign);
        final exaltSignLord = _getExaltationSignLord(planet);

        // Cancellation 1: Debilitation sign lord in kendra from Lagna/Moon
        if (_isPlanetInKendra(chart, debilSignLord)) {
          yogas.add(
            'Neecha Bhanga Raj Yoga ($planet - debilitation cancelled by lord in Kendra)',
          );
        }

        // Cancellation 2: Exaltation sign lord in kendra
        if (_isPlanetInKendra(chart, exaltSignLord)) {
          yogas.add(
            'Neecha Bhanga Raj Yoga ($planet - exaltation lord in Kendra)',
          );
        }
      }
    }

    return yogas;
  }

  // --- Parivartana Yogas (Mutual exchange) ---
  static List<String> _findParivartanaYogas(CompleteChartData chart) {
    List<String> yogas = [];

    // Check all house lord pairs for mutual exchange
    for (int h1 = 1; h1 <= 12; h1++) {
      for (int h2 = h1 + 1; h2 <= 12; h2++) {
        final lord1 = _getHouseLord(chart, h1);
        final lord2 = _getHouseLord(chart, h2);

        if (_areInMutualExchange(chart, lord1, lord2)) {
          // Maha (great): 1,4,7,10,5,9
          if (_isKendraOrTrikona(h1) && _isKendraOrTrikona(h2)) {
            yogas.add(
              'Maha Parivartana Yoga (${h1}th-${h2}th lords exchange - powerful)',
            );
          }
          // Kahala: mixed good/bad
          else if ((_isKendraOrTrikona(h1) && _isDusthana(h2)) ||
              (_isDusthana(h1) && _isKendraOrTrikona(h2))) {
            yogas.add('Kahala Parivartana Yoga (${h1}th-${h2}th lords)');
          }
        }
      }
    }

    return yogas;
  }

  // --- Additional Specific Yogas ---

  static bool _hasStrongGajakesariYoga(CompleteChartData chart) {
    final moonSign = _getPlanetSign(chart, 'Moon');
    final jupiterSign = _getPlanetSign(chart, 'Jupiter');

    final isKendra = [0, 3, 6, 9].contains((jupiterSign - moonSign + 12) % 12);

    // Jupiter should be strong (exalted or own sign)
    final jupiterStrong =
        _isExalted('Jupiter', jupiterSign) ||
        _isOwnSign('Jupiter', jupiterSign);

    return isKendra && jupiterStrong;
  }

  static bool _hasAdhiYoga(CompleteChartData chart) {
    final moonSign = _getPlanetSign(chart, 'Moon');

    // Houses 6,7,8 from Moon
    final house6 = (moonSign + 5) % 12;
    final house7 = (moonSign + 6) % 12;
    final house8 = (moonSign + 7) % 12;

    int beneficCount = 0;
    for (var planet in ['Jupiter', 'Venus', 'Mercury']) {
      final pSign = _getPlanetSign(chart, planet);
      if ([house6, house7, house8].contains(pSign)) beneficCount++;
    }

    return beneficCount >= 2; // At least 2 benefics
  }

  static bool _hasLakshmiYoga(CompleteChartData chart) {
    final venusSign = _getPlanetSign(chart, 'Venus');
    final ninthLord = _getHouseLord(chart, 9);
    final ninthLordSign = _getPlanetSign(chart, ninthLord);

    return venusSign == ninthLordSign && _isOwnSign('Venus', venusSign);
  }

  static bool _hasSaraswatiYoga(CompleteChartData chart) {
    final jupiterSign = _getPlanetSign(chart, 'Jupiter');
    final venusSign = _getPlanetSign(chart, 'Venus');
    final mercurySign = _getPlanetSign(chart, 'Mercury');

    // All three in kendras, trikonas, or 2nd house
    final goodHouses = [0, 1, 3, 4, 6, 8, 9]; // Houses 1,2,4,5,7,9,10

    return goodHouses.contains((jupiterSign) % 12) &&
        goodHouses.contains((venusSign) % 12) &&
        goodHouses.contains((mercurySign) % 12);
  }

  static bool _hasAmalaYoga(CompleteChartData chart) {
    // Benefic in 10th house from Lagna
    final tenthSign = _getHouse(chart, 10);

    for (var planet in ['Jupiter', 'Venus', 'Mercury']) {
      final pSign = _getPlanetSign(chart, planet);
      if (pSign == tenthSign) return true;
    }

    return false;
  }

  static bool _hasParvataYoga(CompleteChartData chart) {
    // Benefics in all kendras, no malefics in kendras
    int beneficsInKendra = 0;

    for (int kendra in [1, 4, 7, 10]) {
      final kendraSign = _getHouse(chart, kendra);

      for (var malefic in ['Mars', 'Saturn', 'Sun']) {
        if (_getPlanetSign(chart, malefic) == kendraSign) return false;
      }

      for (var benefic in ['Jupiter', 'Venus', 'Mercury']) {
        if (_getPlanetSign(chart, benefic) == kendraSign) beneficsInKendra++;
      }
    }

    return beneficsInKendra >= 2;
  }

  static bool _hasKahalaYoga(CompleteChartData chart) {
    final fourthLord = _getHouseLord(chart, 4);
    final ninthLord = _getHouseLord(chart, 9);

    return _areInMutualKendras(chart, fourthLord, ninthLord);
  }

  static bool _hasChamaraYoga(CompleteChartData chart) {
    final lagnaLord = _getHouseLord(chart, 1);
    final lagnaLordSign = _getPlanetSign(chart, lagnaLord);

    return _isExalted(lagnaLord, lagnaLordSign) &&
        _isPlanetInKendra(chart, lagnaLord);
  }

  static bool _hasSankhaYoga(CompleteChartData chart) {
    final fifthLord = _getHouseLord(chart, 5);
    final sixthLord = _getHouseLord(chart, 6);

    return _areInMutualKendras(chart, fifthLord, sixthLord);
  }

  // --- Helper Methods for Extended Yogas ---

  static String _getHouseLord(CompleteChartData chart, int house) {
    final houseSign = _getHouse(chart, house);
    return _getSignLord(houseSign);
  }

  static int _getHouse(CompleteChartData chart, int house) {
    try {
      final cuspLong = chart.baseChart.houses.cusps[house - 1];
      return (cuspLong / 30).floor();
    } catch (e) {
      return (house - 1) % 12;
    }
  }

  static bool _areConjunct(
    CompleteChartData chart,
    String planet1,
    String planet2,
  ) {
    return _getPlanetSign(chart, planet1) == _getPlanetSign(chart, planet2);
  }

  static bool _areInMutualExchange(
    CompleteChartData chart,
    String planet1,
    String planet2,
  ) {
    final p1Sign = _getPlanetSign(chart, planet1);
    final p2Sign = _getPlanetSign(chart, planet2);

    return _getSignLord(p1Sign) == planet2 && _getSignLord(p2Sign) == planet1;
  }

  static bool _areInMutualKendras(
    CompleteChartData chart,
    String planet1,
    String planet2,
  ) {
    final p1Sign = _getPlanetSign(chart, planet1);
    final p2Sign = _getPlanetSign(chart, planet2);

    final diff = (p2Sign - p1Sign + 12) % 12;
    return [0, 3, 6, 9].contains(diff);
  }

  static bool _isPlanetInKendra(CompleteChartData chart, String planet) {
    final pSign = _getPlanetSign(chart, planet);
    final lagnaSign = _getHouse(chart, 1);

    final diff = (pSign - lagnaSign + 12) % 12;
    return [0, 3, 6, 9].contains(diff);
  }

  static bool _isInDusthaHouse(CompleteChartData chart, int sign) {
    for (int house in [6, 8, 12]) {
      if (_getHouse(chart, house) == sign) return true;
    }
    return false;
  }

  static bool _isKendraOrTrikona(int house) {
    return [1, 4, 5, 7, 9, 10].contains(house);
  }

  static bool _isDusthana(int house) {
    return [6, 8, 12].contains(house);
  }

  static bool _isDebilitated(String planet, int sign) {
    const debilitations = {
      'Sun': 6,
      'Moon': 7,
      'Mars': 3,
      'Mercury': 11,
      'Jupiter': 9,
      'Venus': 5,
      'Saturn': 0,
    };
    return debilitations[planet] == sign;
  }

  static bool _isExalted(String planet, int sign) {
    const exaltations = {
      'Sun': 0,
      'Moon': 1,
      'Mars': 9,
      'Mercury': 5,
      'Jupiter': 3,
      'Venus': 11,
      'Saturn': 6,
    };
    return exaltations[planet] == sign;
  }

  static bool _isOwnSign(String planet, int sign) {
    return _getSignLord(sign) == planet;
  }

  static String _getExaltationSignLord(String planet) {
    const exaltations = {
      'Sun': 0, // Aries -> Mars
      'Moon': 1, // Taurus -> Venus
      'Mars': 9, // Capricorn -> Saturn
      'Mercury': 5, // Virgo -> Mercury
      'Jupiter': 3, // Cancer -> Moon
      'Venus': 11, // Pisces -> Jupiter
      'Saturn': 6, // Libra -> Venus
    };

    return _getSignLord(exaltations[planet] ?? 0);
  }

  static bool _hasGajakesariYoga(CompleteChartData chart) {
    final moonSign = _getPlanetSign(chart, 'Moon');
    final jupSign = _getPlanetSign(chart, 'Jupiter');

    int houseFromMoon = (jupSign - moonSign + 12) % 12 + 1;
    return [1, 4, 7, 10].contains(houseFromMoon);
  }

  static bool _hasBudhadityaYoga(CompleteChartData chart) {
    final sunSign = _getPlanetSign(chart, 'Sun');
    final mercSign = _getPlanetSign(chart, 'Mercury');
    return sunSign == mercSign;
  }

  static bool _hasChandraMangalaYoga(CompleteChartData chart) {
    final moonSign = _getPlanetSign(chart, 'Moon');
    final marsSign = _getPlanetSign(chart, 'Mars');
    return moonSign == marsSign;
  }

  static void _checkPanchamahapurusha(
    CompleteChartData chart,
    List<String> yogas,
  ) {
    final lagnaSign = _getAscendantSign(chart);

    // Pairs: Planet Name, Yoga Name, Own Signs, Exaltation Sign
    final checks = [
      {
        'planet': 'Mars',
        'yoga': 'Ruchaka Yoga',
        'own': [0, 7],
        'exalt': 9,
      }, // Aries(0), Scorpio(7), Cap(9)
      {
        'planet': 'Mercury',
        'yoga': 'Bhadra Yoga',
        'own': [2, 5],
        'exalt': 5,
      }, // Gem(2), Vir(5)
      {
        'planet': 'Jupiter',
        'yoga': 'Hamsa Yoga',
        'own': [8, 11],
        'exalt': 3,
      }, // Sag(8), Pis(11), Can(3)
      {
        'planet': 'Venus',
        'yoga': 'Malavya Yoga',
        'own': [1, 6],
        'exalt': 11,
      }, // Tau(1), Lib(6), Pis(11)
      {
        'planet': 'Saturn',
        'yoga': 'Sasa Yoga',
        'own': [9, 10],
        'exalt': 6,
      }, // Cap(9), Aqu(10), Lib(6)
    ];

    for (var check in checks) {
      final pSign = _getPlanetSign(chart, check['planet'] as String);
      final own = check['own'] as List<int>;
      final exalt = check['exalt'] as int;

      // Check if planet is in Own Sign or Exaltation
      bool strong = own.contains(pSign) || pSign == exalt;

      if (strong) {
        // Check if in Kendra from Lagna
        int house = (pSign - lagnaSign + 12) % 12 + 1;
        if ([1, 4, 7, 10].contains(house)) {
          yogas.add(check['yoga'] as String);
        }
      }
    }
  }

  static bool _hasRajYoga(CompleteChartData chart) {
    // Raj Yoga: Conjunction between Kendra and Trikona lords
    final lagnaSign = _getAscendantSign(chart);

    // Kendra houses: 1, 4, 7, 10
    final kendraLords = <String>{};
    for (var house in [1, 4, 7, 10]) {
      int sign = (lagnaSign + house - 1) % 12;
      kendraLords.add(_getSignLord(sign));
    }

    // Trikona houses: 1, 5, 9
    final trikonaLords = <String>{};
    for (var house in [1, 5, 9]) {
      int sign = (lagnaSign + house - 1) % 12;
      trikonaLords.add(_getSignLord(sign));
    }

    // Check for conjunction
    for (var kl in kendraLords) {
      for (var tl in trikonaLords) {
        if (kl == tl) continue;

        int klSign = _getPlanetSign(chart, kl);
        int tlSign = _getPlanetSign(chart, tl);

        if (klSign == tlSign) return true;
      }
    }

    return false;
  }

  static String _getSignLord(int sign) {
    const lords = [
      'Mars',
      'Venus',
      'Mercury',
      'Moon',
      'Sun',
      'Mercury',
      'Venus',
      'Mars',
      'Jupiter',
      'Saturn',
      'Saturn',
      'Jupiter',
    ];
    return lords[sign % 12];
  }

  // --- Helpers ---

  static double _getPlanetLongitude(
    CompleteChartData chart,
    String planetName,
  ) {
    for (final entry in chart.baseChart.planets.entries) {
      if (entry.key.toString().split('.').last == planetName) {
        return entry.value.longitude;
      }
    }
    return 0.0;
  }

  static int _getPlanetSign(CompleteChartData chart, String planetName) {
    return (_getPlanetLongitude(chart, planetName) / 30).floor();
  }

  static int _getAscendantSign(CompleteChartData chart) {
    if (chart.baseChart.houses.cusps.isNotEmpty) {
      return (chart.baseChart.houses.cusps[0] / 30).floor();
    }
    return 0;
  }

  static bool _isBetween(double target, double start, double end) {
    final t = normalize(target);
    final s = normalize(start);
    final e = normalize(end);

    if (s < e) return t >= s && t <= e;
    return t >= s || t <= e;
  }

  static double normalize(double angle) {
    return (angle % 360 + 360) % 360;
  }
}
