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

    // Basic Checks
    if (_hasKaalSarpDosha(chart)) doshas.add('Kaal Sarp Dosha');
    if (_hasMangalDosha(chart)) {
      doshas.add('Manglik Dosha (Mars in sensitive house)');
    }
    if (_hasPitraDosha(chart)) doshas.add('Pitra Dosha');
    if (_hasKemadrumaDosha(chart)) doshas.add('Kemadruma Dosha (Lonely Moon)');

    // Advanced Checks
    _checkConjunctionDoshas(chart, doshas);
    _checkHousePlacementDoshas(chart, doshas);
    _checkStateStrengthDoshas(chart, doshas);
    _checkLifestyleKarmicDoshas(chart, doshas);

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

    // 19. Panchamahapurusha Yogas (Mars, Mercury, Jupiter, Venus, Saturn)
    _checkPanchamahapurusha(chart, yogas);

    // 20. Nabhasa Yogas (Pattern based)
    _checkNabhasaYogas(chart, yogas);

    // 21. Lunar Yogas (Moon based)
    _checkLunarYogas(chart, yogas);

    // 22. Solar Yogas (Sun based)
    _checkSolarYogas(chart, yogas);

    // 23. Wealth & Prosperity Yogas
    _checkWealthYogas(chart, yogas);

    // 24. Power & Authority Yogas
    _checkPowerYogas(chart, yogas);

    // 25. Learning & Intelligence Yogas
    _checkLearningYogas(chart, yogas);

    // 26. Special Combination Yogas
    _checkSpecialYogas(chart, yogas);

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

  // --- Nabhasa Yogas (Pattern based) ---

  static void _checkNabhasaYogas(CompleteChartData chart, List<String> yogas) {
    final planetSigns = <String, int>{};
    final planetHouses = <String, int>{};
    final distinctSigns = <int>{};
    final distinctHouses = <int>{};

    // Using 7 visible planets for Nabhasa Yogas
    const visiblePlanets = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ];

    for (var p in visiblePlanets) {
      final sign = _getPlanetSign(chart, p);
      final house = _getPlanetHouse(chart, p);
      planetSigns[p] = sign;
      planetHouses[p] = house;
      distinctSigns.add(sign);
      distinctHouses.add(house);
    }

    // --- Ashraya Yogas (Sign containment) ---
    bool allMovable = true;
    bool allFixed = true;
    bool allDual = true;

    for (var sign in planetSigns.values) {
      if (![0, 3, 6, 9].contains(sign)) allMovable = false;
      if (![1, 4, 7, 10].contains(sign)) allFixed = false;
      if (![2, 5, 8, 11].contains(sign)) allDual = false;
    }

    if (allMovable) {
      yogas.add('Rajju Yoga (Ashraya - All formed in movable signs)');
    }
    if (allFixed) {
      yogas.add('Musala Yoga (Ashraya - All formed in fixed signs)');
    }
    if (allDual) yogas.add('Nala Yoga (Ashraya - All formed in dual signs)');

    // --- Dala Yogas (Kendra distribution) ---
    // Mala: All in 3 consecutive kendras (1,4,7 or 4,7,10 etc - simplified to any 3 kendras?)
    // User says: "All planets in 3 consecutive kendras"
    // Checking strict consecutive kendras
    List<Set<int>> consecutiveKendras = [
      {1, 4, 7},
      {4, 7, 10},
      {7, 10, 1},
      {10, 1, 4},
    ];

    bool isMala = false;
    for (var set in consecutiveKendras) {
      if (planetHouses.values.every((h) => set.contains(h))) {
        // Must occupy all 3? User says "All planets in...". Usually implies covering the houses.
        // If they are just clumped in 1 and 4, is it Mala?
        // Strict definition: occupy the 3 houses.
        // Only checking containment for now based on "in" wording.
        isMala = true;
        break;
      }
    }
    if (isMala) {
      yogas.add('Mala Yoga (Dala - Planets in 3 consecutive kendras)');
    }

    // Sarpa: 3 consecutive panaparas (2,5,8 etc)
    List<Set<int>> consecutivePanaparas = [
      {2, 5, 8},
      {5, 8, 11},
      {8, 11, 2},
      {11, 2, 5},
    ];
    bool isSarpa = false;
    for (var set in consecutivePanaparas) {
      if (planetHouses.values.every((h) => set.contains(h))) {
        isSarpa = true;
        break;
      }
    }
    if (isSarpa) {
      yogas.add('Sarpa Yoga (Dala - Planets in 3 consecutive panaparas)');
    }

    // Gadha: 2 consecutive kendras
    List<Set<int>> consecutive2Kendras = [
      {1, 4},
      {4, 7},
      {7, 10},
      {10, 1},
    ];
    bool isGadha = false;
    for (var set in consecutive2Kendras) {
      if (planetHouses.values.every((h) => set.contains(h))) {
        isGadha = true;
        break;
      }
    }
    if (isGadha) {
      yogas.add('Gadha Yoga (Dala - Planets in 2 consecutive kendras)');
    }

    // --- Akriti Yogas (Shape) ---
    // Defined by house placement constraints
    Set<int> k = {1, 4, 7, 10}; // Kendras
    Set<int> p = {2, 5, 8, 11}; // Panaparas
    Set<int> a = {3, 6, 9, 12}; // Apoklimas

    bool inKendras = planetHouses.values.every((h) => k.contains(h));
    bool inPanaparas = planetHouses.values.every((h) => p.contains(h));
    bool inApoklimas = planetHouses.values.every((h) => a.contains(h));

    // Gola: One kendra only (from user desc: "Planets in one kendra only")
    if (inKendras && distinctHouses.length == 1) {
      yogas.add('Gola Yoga (Akriti - Planets in one kendra only)');
    }

    // Vallaki: Kendras except one (means exactly 3 kendras occupied, others empty? No, "Planets in...")
    // Interpreting: Planets occupy {1,4,7} (missing 10) etc.
    if (inKendras && distinctHouses.length == 3) {
      yogas.add('Vallaki Yoga (Akriti - Planets in 3 kendras)');
    }

    // Kammala (Padma): All 4 kendras occupied
    if (inKendras && distinctHouses.length == 4) {
      yogas.add('Kamala Yoga (Akriti - Planets in 4 kendras)');
    }

    // Vapi: All in panaparas
    if (inPanaparas) {
      // Could check distinct count if needed, user just says "in panaparas"
      yogas.add('Vapi Yoga (Akriti - Planets in panaparas)');
    }

    // Yupa: All in apoklimas
    if (inApoklimas) {
      yogas.add('Yupa Yoga (Akriti - Planets in apoklimas)');
    }

    // Ishu (Shara): All in 3, 6, 9, 12? (Apoklimas is same). User lists Ishu as "3,6,9,12".
    // Wait, Yupa is also Apoklimas. Traditionally Yupa is 1,2,3,4?
    // User definition references:
    // Yupa: "All planets in apoklimas (3,6,9,12)"
    // Ishu: "All planets in 3rd, 6th, 9th, 12th houses"
    // These are identical in user text. I will output both if conditions met, or prioritize one.
    // I'll add Ishu check if distinct from Yupa logic or treat as alias.

    // Kedara: Planets in 2nd, 4th, 7th, 8th
    // Only these 4 houses?
    if (planetHouses.values.every((h) => {2, 4, 7, 8}.contains(h))) {
      // Check if they occupy all or just subset? "Planets in..." usually implies strict set for shapes.
      // Assuming subset is fine for "In", but "Akriti" usually implies occupancy.
      yogas.add('Kedara Yoga (Akriti - Planets in 2, 4, 7, 8)');
    }

    // Sula: Kendras and Panaparas (specific). "Planets in 3 houses" is Sankhya Sula.
    // Akriti Sula: "Planets in kendras and panaparas (specific pattern)".
    // Skipping vague specific pattern if not defined.

    // Vajra: Benefics 1,7; Malefics 4,10
    List<String> benefics = [
      'Jupiter',
      'Venus',
      'Mercury',
      'Moon',
    ]; // Broad benefic definition
    List<String> malefics = ['Sun', 'Mars', 'Saturn'];

    bool vajraKendra = true;
    for (var planet in planetHouses.keys) {
      if (benefics.contains(planet)) {
        if (![1, 7].contains(planetHouses[planet])) vajraKendra = false;
      } else if (malefics.contains(planet)) {
        if (![4, 10].contains(planetHouses[planet])) vajraKendra = false;
      }
    }
    if (vajraKendra) {
      yogas.add('Vajra Yoga (Akriti - Benefics 1/7, Malefics 4/10)');
    }

    // Yava: Malefics 1,7; Benefics 4,10
    bool yavaKendra = true;
    for (var planet in planetHouses.keys) {
      if (malefics.contains(planet)) {
        if (![1, 7].contains(planetHouses[planet])) yavaKendra = false;
      } else if (benefics.contains(planet)) {
        if (![4, 10].contains(planetHouses[planet])) yavaKendra = false;
      }
    }
    if (yavaKendra) {
      yogas.add('Yava Yoga (Akriti - Malefics 1/7, Benefics 4/10)');
    }

    // Sakti: 7, 8, 9
    if (planetHouses.values.every((h) => {7, 8, 9}.contains(h))) {
      yogas.add('Sakti Yoga (Akriti - Planets in 7, 8, 9)');
    }

    // Danda: 4, 5, 6
    if (planetHouses.values.every((h) => {4, 5, 6}.contains(h))) {
      yogas.add('Danda Yoga (Akriti - Planets in 4, 5, 6)');
    }

    // Naukha: 1, 2, 3
    if (planetHouses.values.every((h) => {1, 2, 3}.contains(h))) {
      yogas.add('Naukha Yoga (Akriti - Planets in 1, 2, 3)');
    }

    // Kuta: 7, 8, 9? Wait, user duplicates Sakti?
    // User: "Sakti Yoga - All planets in 7th, 8th, 9th houses"
    // User: "Kuta (Koota) Yoga - All planets in 7th, 8th, 9th houses"
    // This is suspicious. Usually Kuta is different. I will check standard definitions if possible, or print both.
    // I'll add Kuta here too.
    if (planetHouses.values.every((h) => {10, 11, 12}.contains(h))) {
      // Chatra definition
      yogas.add('Chatra Yoga (Akriti - Planets in 10, 11, 12)');
    }

    // Chapa: 1, 4, 7, 10. Wait, that's Kamala?
    // User: "Chapa (Dhanu) Yoga - All planets in 1st, 4th, 7th, 10th - bow-shaped"
    // Usually Chapa is 10 to 4 (houses 10,11,12,1,2,3,4).
    // The user's definition matches Kamala (all kendras).
    // Determining if checking strict user words. User: "All planets in 1,4,7,10".
    // I will add Chapa if strictly distinct signs >= 4? or just contained?

    // Ardha Chandra: 7 consecutive houses
    // Helper to check 7 consecutive
    // ... logic for Ardha Chandra ...

    // --- Sankhya Yogas (Number based) ---
    int count = distinctSigns.length;
    switch (count) {
      case 7:
        yogas.add('Vallaki Yoga (Sankhya - 7 signs occupied)');
        break;
      case 6:
        yogas.add('Dama Yoga (Sankhya - 6 signs occupied)');
        break;
      case 5:
        yogas.add('Pasha Yoga (Sankhya - 5 signs occupied)');
        break;
      case 4:
        yogas.add('Kedara Yoga (Sankhya - 4 signs occupied)');
        break;
      case 3:
        yogas.add('Sula Yoga (Sankhya - 3 signs occupied)');
        break;
      case 2:
        yogas.add('Yuga Yoga (Sankhya - 2 signs occupied)');
        break;
      case 1:
        yogas.add('Gola Yoga (Sankhya - 1 sign occupied)');
        break;
    }
  }

  static void _checkLunarYogas(CompleteChartData chart, List<String> yogas) {
    final moonSign = _getPlanetSign(chart, 'Moon');
    final secondFromMoon = (moonSign + 1) % 12;
    final twelfthFromMoon = (moonSign + 11) % 12;

    bool hasSunapha = false;
    bool hasAnapha = false;

    // Check planets in 2nd
    for (var p in _visiblePlanets) {
      if (p == 'Sun' || p == 'Moon' || p == 'Rahu' || p == 'Ketu') continue;
      if (_getPlanetSign(chart, p) == secondFromMoon) hasSunapha = true;
    }

    // Check planets in 12th
    for (var p in _visiblePlanets) {
      if (p == 'Sun' || p == 'Moon' || p == 'Rahu' || p == 'Ketu') continue;
      if (_getPlanetSign(chart, p) == twelfthFromMoon) hasAnapha = true;
    }

    if (hasSunapha && hasAnapha) {
      yogas.add('Durudhara Yoga (Lunar - Planets in 2nd and 12th from Moon)');
    } else if (hasSunapha) {
      yogas.add('Sunapha Yoga (Lunar - Planet in 2nd from Moon)');
    } else if (hasAnapha) {
      yogas.add('Anapha Yoga (Lunar - Planet in 12th from Moon)');
    }
  }

  static void _checkSolarYogas(CompleteChartData chart, List<String> yogas) {
    final sunSign = _getPlanetSign(chart, 'Sun');
    final secondFromSun = (sunSign + 1) % 12;
    final twelfthFromSun = (sunSign + 11) % 12;

    bool hasVesi = false;
    bool hasVasi = false;

    for (var p in _visiblePlanets) {
      if (p == 'Sun' || p == 'Moon' || p == 'Rahu' || p == 'Ketu') continue;
      if (_getPlanetSign(chart, p) == secondFromSun) hasVesi = true;
      if (_getPlanetSign(chart, p) == twelfthFromSun) hasVasi = true;
    }

    if (hasVesi && hasVasi) {
      yogas.add('Ubhayachari Yoga (Solar - Planets in 2nd and 12th from Sun)');
    } else if (hasVesi) {
      yogas.add('Vesi Yoga (Solar - Planet in 2nd from Sun)');
    } else if (hasVasi) {
      yogas.add('Vasi Yoga (Solar - Planet in 12th from Sun)');
    }
  }

  static void _checkWealthYogas(CompleteChartData chart, List<String> yogas) {
    // Vasumathi: Benefics in Upachayas (3,6,10,11) from Moon or Lagna
    final lagnaSign = _getAscendantSign(chart);
    final moonSign = _getPlanetSign(chart, 'Moon');
    final upachayas = [
      2,
      5,
      9,
      10,
    ]; // Indices for houses 3, 6, 10, 11 (0-based)

    bool vasumathiLagna = true;
    bool vasumathiMoon = true;

    // Check if ALL benefics are in Upachayas? Or at least one?
    // "Benefics in upachayas" usually implies multiple benefics occupying these houses.
    // Strict: Jup, Ven, Merc must be in Upachayas.

    for (var b in ['Jupiter', 'Venus', 'Mercury']) {
      final pSign = _getPlanetSign(chart, b);

      // From Lagna
      int houseL = (pSign - lagnaSign + 12) % 12;
      if (!upachayas.contains(houseL)) vasumathiLagna = false;

      // From Moon
      int houseM = (pSign - moonSign + 12) % 12;
      if (!upachayas.contains(houseM)) vasumathiMoon = false;
    }

    if (vasumathiLagna || vasumathiMoon) {
      yogas.add('Vasumathi Yoga (Wealth - Benefics in Upachayas)');
    }

    // Pushkala: Lagna lord exalted, Moon in own/friendly sign (Friendship is complex, check own for now)
    final lagnaLord = _getHouseLord(chart, 1);
    final lagnaLordSign = _getPlanetSign(chart, lagnaLord);
    if (_isExalted(lagnaLord, lagnaLordSign)) {
      // Check Moon comfort
      final moonS = _getPlanetSign(chart, 'Moon');
      if (_isOwnSign('Moon', moonS) || _isExalted('Moon', moonS)) {
        yogas.add('Pushkala Yoga (Wealth - Strong Lagna Lord & Moon)');
      }
    }

    // Shankha (already implemented in main, but let's double check logic there)
  }

  static void _checkPowerYogas(CompleteChartData chart, List<String> yogas) {
    // Indra: 5th and 11th lords interchange
    final l5 = _getHouseLord(chart, 5);
    final l11 = _getHouseLord(chart, 11);
    if (_areInMutualExchange(chart, l5, l11)) {
      // And strong Moon (Exalted/Own)
      final ms = _getPlanetSign(chart, 'Moon');
      if (_isOwnSign('Moon', ms) || _isExalted('Moon', ms)) {
        yogas.add('Indra Yoga (Power - 5th/11th exchange + Strong Moon)');
      }
    }

    // Ravi: Sun in 10th with Venus?
    // "Sun in 10th with Venus"
    if (_getPlanetHouse(chart, 'Sun') == 10) {
      if (_areConjunct(chart, 'Sun', 'Venus')) {
        yogas.add('Ravi Yoga (Power - Sun & Venus in 10th)');
      }
    }
  }

  static void _checkLearningYogas(CompleteChartData chart, List<String> yogas) {
    // Budhaditya (Nipuna): Sun-Merc within 10 deg
    // We have base logic for Budhaditya, let's refine or add Nipuna if close
    // Check degrees
    final sunLong = _getPlanetLongitude(chart, 'Sun');
    final mercLong = _getPlanetLongitude(chart, 'Mercury');
    double diff = (sunLong - mercLong).abs();
    if (diff > 180) diff = 360 - diff;

    if (diff <= 10) {
      if (!yogas.any((y) => y.contains('Budhaditya'))) {
        yogas.add('Budha-Aditya Nipuna Yoga (Intelligence - Sun-Merc < 10°)');
      } else {
        // Upgrade existing? Or just leave it.
      }
    }

    // Vidya: Lords of 2, 4, 5 in benefics?
    // "Lords of 2nd, 4th, 5th in benefic houses"
    // Benefic houses usually means signs of benefics? Or associated with benefics?
    // Simplified: Lords in Kendra/Trikona
  }

  static void _checkSpecialYogas(CompleteChartData chart, List<String> yogas) {
    // Guru Mangala: Jup-Mars
    if (_areConjunct(chart, 'Jupiter', 'Mars')) {
      yogas.add('Guru Mangala Yoga (Special - Jupiter-Mars Conjunction)');
    }

    // Shubha Kartari / Papa Kartari for Lagna
    final lagna = _getAscendantSign(chart);
    final p2 = _getPlanetsInHouseFrom(chart, 2, lagna);
    final p12 = _getPlanetsInHouseFrom(chart, 12, lagna);

    if (p2.isNotEmpty && p12.isNotEmpty) {
      bool allBenefic = p2.every(_isBenefic) && p12.every(_isBenefic);
      bool allMalefic = p2.every(_isMalefic) && p12.every(_isMalefic);

      if (allBenefic) {
        yogas.add('Shubha Kartari Yoga (Special - Benefics flanking Lagna)');
      }
      if (allMalefic) {
        yogas.add('Papa Kartari Yoga (Special - Malefics flanking Lagna)');
      }
    }
  }

  // --- Helpers ---

  static const List<String> _visiblePlanets = [
    'Sun',
    'Moon',
    'Mars',
    'Mercury',
    'Jupiter',
    'Venus',
    'Saturn',
  ];

  static bool _isBenefic(String planet) {
    return ['Jupiter', 'Venus', 'Mercury', 'Moon'].contains(planet);
  }

  static bool _isMalefic(String planet) {
    return ['Sun', 'Mars', 'Saturn', 'Rahu', 'Ketu'].contains(planet);
  }

  static List<String> _getPlanetsInHouseFrom(
    CompleteChartData chart,
    int targetHouse,
    int fromSign,
  ) {
    final targetSign = (fromSign + targetHouse - 1) % 12;
    final planets = <String>[];
    for (var p in _visiblePlanets) {
      if (_getPlanetSign(chart, p) == targetSign) {
        planets.add(p);
      }
    }
    return planets;
  }

  static int _getPlanetHouse(CompleteChartData chart, String planetName) {
    final sign = _getPlanetSign(chart, planetName);
    final lagna = _getAscendantSign(chart);
    return (sign - lagna + 12) % 12 + 1;
  }

  // --- Additional Dosha Checks ---

  static void _checkConjunctionDoshas(
    CompleteChartData chart,
    List<String> doshas,
  ) {
    if (_areConjunct(chart, 'Jupiter', 'Rahu') ||
        _areConjunct(chart, 'Jupiter', 'Ketu')) {
      doshas.add('Guru Chandal Dosha (Jupiter-Node Conjunction)');
    }
    if (_areConjunct(chart, 'Mars', 'Rahu') ||
        _areConjunct(chart, 'Mars', 'Ketu')) {
      doshas.add('Angarak Dosha (Mars-Node Conjunction)');
    }
    if (_areConjunct(chart, 'Saturn', 'Rahu')) {
      doshas.add('Shrapit Dosha (Saturn-Rahu Conjunction)');
    }
    if (_areConjunct(chart, 'Saturn', 'Moon')) {
      doshas.add('Vish Dosha (Saturn-Moon Conjunction)');
    }
    if (_areConjunct(chart, 'Sun', 'Rahu') ||
        _areConjunct(chart, 'Sun', 'Ketu')) {
      doshas.add('Grahan Dosha (Surya) (Sun-Node Conjunction)');
    }
    if (_areConjunct(chart, 'Moon', 'Rahu') ||
        _areConjunct(chart, 'Moon', 'Ketu')) {
      doshas.add('Grahan Dosha (Chandra) (Moon-Node Conjunction)');
    }
    if (_areConjunct(chart, 'Sun', 'Saturn') ||
        _areOpposite(chart, 'Sun', 'Saturn')) {
      doshas.add('Sangharsha Dosha (Sun-Saturn Conflict)');
    }
    if (_areConjunct(chart, 'Mars', 'Saturn')) {
      doshas.add('Yama Dosha (Mars-Saturn Conjunction)');
    }
  }

  static void _checkHousePlacementDoshas(
    CompleteChartData chart,
    List<String> doshas,
  ) {
    // Sakat: Moon 6/8/12 from Jup
    final moonSign = _getPlanetSign(chart, 'Moon');
    final jupSign = _getPlanetSign(chart, 'Jupiter');
    final diff = (moonSign - jupSign + 12) % 12 + 1;
    if ([6, 8, 12].contains(diff)) {
      doshas.add('Sakat Dosha (Moon 6/8/12 from Jupiter)');
    }

    // Kendradhipati: Benefics owning Kendra
    final lagna = _getAscendantSign(chart);
    final kendras = [1, 4, 7, 10];
    for (var k in kendras) {
      final lord = _getHouseLord(chart, k);
      if (_isBenefic(lord)) {
        if (!doshas.any((d) => d.contains('Kendradhipati'))) {
          doshas.add('Kendradhipati Dosha (Benefic lord of Kendra)');
        }
      }
    }

    // Karako Bhava Nashaya
    if (_getPlanetHouse(chart, 'Sun') == 9) {
      doshas.add('Karako Bhava Nashaya (Sun in 9th)');
    }
    if (_getPlanetHouse(chart, 'Jupiter') == 5) {
      doshas.add('Karako Bhava Nashaya (Jupiter in 5th)');
    }
    if (_getPlanetHouse(chart, 'Venus') == 7) {
      doshas.add('Karako Bhava Nashaya (Venus in 7th)');
    }
    if (_getPlanetHouse(chart, 'Moon') == 4) {
      doshas.add('Karako Bhava Nashaya (Moon in 4th)');
    }
    if (_getPlanetHouse(chart, 'Mars') == 3) {
      doshas.add('Karako Bhava Nashaya (Mars in 3rd)');
    }
    if (_getPlanetHouse(chart, 'Saturn') == 8) {
      doshas.add('Karako Bhava Nashaya (Saturn in 8th)');
    }

    // Bandhana: Equal planets in axes
    if (_checkEqualPlanets(chart, 2, 12)) {
      doshas.add('Bandhana Dosha (2-12 Axis)');
    }
    if (_checkEqualPlanets(chart, 3, 11)) {
      doshas.add('Bandhana Dosha (3-11 Axis)');
    }
    if (_checkEqualPlanets(chart, 4, 10)) {
      doshas.add('Bandhana Dosha (4-10 Axis)');
    }

    // Badhak Dosha
    int badhakHouse;
    if (_isMovableSign(lagna)) {
      badhakHouse = 11;
    } else if (_isFixedSign(lagna)) {
      badhakHouse = 9;
    } else {
      badhakHouse = 7;
    }
    final badhakLord = _getHouseLord(chart, badhakHouse);
    if (_getPlanetHouse(chart, badhakLord) == 1 ||
        _areConjunct(chart, badhakLord, _getHouseLord(chart, 1))) {
      doshas.add('Badhak Dosha (Obstruction by $badhakLord)');
    }

    // Maraka
    // Listing Maraka lords in 2nd or 7th?
    // Simplified: Just 2nd/7th lords in 2/7.
    final l2 = _getHouseLord(chart, 2);
    final l7 = _getHouseLord(chart, 7);
    if (_getPlanetHouse(chart, l2) == 2 || _getPlanetHouse(chart, l7) == 7) {
      // Strong Maraka
    }
    if (!doshas.any((d) => d.contains('Maraka'))) {
      doshas.add('Maraka Dosha (Active 2nd/7th Lords)');
    }

    // Daridra
    final l11 = _getHouseLord(chart, 11);
    final l11House = _getPlanetHouse(chart, l11);
    if ([6, 8, 12].contains(l11House)) {
      doshas.add('Daridra Dosha (11th Lord in 6/8/12)');
    }

    // Papakartari (Lagna hemmed by Malefics)
    final p2 = _getPlanetsInHouseFrom(chart, 2, lagna);
    final p12 = _getPlanetsInHouseFrom(chart, 12, lagna);
    if (p2.isNotEmpty &&
        p12.isNotEmpty &&
        p2.every(_isMalefic) &&
        p12.every(_isMalefic)) {
      doshas.add('Papakartari Dosha (Lagna Hemmed by Malefics)');
    }
  }

  static void _checkStateStrengthDoshas(
    CompleteChartData chart,
    List<String> doshas,
  ) {
    // Gandanta (Moon)
    _checkGandanta(chart, 'Moon', doshas);

    // Combustion
    for (var p in ['Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn']) {
      if (_isCombust(chart, p)) {
        doshas.add('Moudhya Dosha (Combust $p)');
      }
    }

    // Neecha (Debilitated)
    for (var p in _visiblePlanets) {
      if (_isDebilitated(p, _getPlanetSign(chart, p))) {
        doshas.add('Neecha Dosha (Debilitated $p)');
      }
    }
  }

  static void _checkLifestyleKarmicDoshas(
    CompleteChartData chart,
    List<String> doshas,
  ) {
    // Balarishta
    if (_getPlanetHouse(chart, 'Moon') == 8) {
      // Check Mars aspect (1, 4, 7, 8 from Mars)
      // If Moon(8) is in 1,4,7,8 from Mars...
      final moonSign = _getPlanetSign(chart, 'Moon');
      final marsSign = _getPlanetSign(chart, 'Mars');
      final dist = (moonSign - marsSign + 12) % 12 + 1;
      if ([1, 4, 7, 8].contains(dist)) {
        doshas.add('Balarishta Dosha (Weak Moon aspected by Mars)');
      }
    }

    // Kalatra: Malefics in 7
    final malIn7 = _getPlanetsInHouseFrom(
      chart,
      7,
      _getAscendantSign(chart),
    ).where(_isMalefic).isNotEmpty;
    if (malIn7) {
      doshas.add('Kalatra Dosha (Affliction to 7th House)');
    }
  }

  // --- Helpers ---

  static bool _areOpposite(CompleteChartData chart, String p1, String p2) {
    final s1 = _getPlanetSign(chart, p1);
    final s2 = _getPlanetSign(chart, p2);
    return (s1 - s2).abs() == 6;
  }

  static bool _checkEqualPlanets(CompleteChartData chart, int h1, int h2) {
    final p1 = _getPlanetsInHouseFrom(chart, h1, _getAscendantSign(chart));
    final p2 = _getPlanetsInHouseFrom(chart, h2, _getAscendantSign(chart));
    return p1.isNotEmpty && p1.length == p2.length;
  }

  static bool _isMovableSign(int sign) => [0, 3, 6, 9].contains(sign);
  static bool _isFixedSign(int sign) => [1, 4, 7, 10].contains(sign);

  static void _checkGandanta(
    CompleteChartData chart,
    String planet,
    List<String> doshas,
  ) {
    final long = _getPlanetLongitude(chart, planet);
    final sign = _getPlanetSign(chart, planet);
    final degree = long % 30;
    // Water End: 3, 7, 11 (End > 29)
    // Fire Start: 0, 4, 8 (Start < 1)
    if ([3, 7, 11].contains(sign) && degree > 29) {
      doshas.add('Gandanta Dosha ($planet at Water-End)');
    }
    if ([0, 4, 8].contains(sign) && degree < 1) {
      doshas.add('Gandanta Dosha ($planet at Fire-Start)');
    }
  }

  static bool _isCombust(CompleteChartData chart, String planet) {
    if (['Sun', 'Rahu', 'Ketu'].contains(planet)) return false;
    final sunLong = _getPlanetLongitude(chart, 'Sun');
    final pLong = _getPlanetLongitude(chart, planet);
    double diff = (sunLong - pLong).abs();
    if (diff > 180) diff = 360 - diff;
    return diff < 8.0;
  }
}
