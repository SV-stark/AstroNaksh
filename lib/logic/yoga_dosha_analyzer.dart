import '../data/models.dart';

/// Yoga and Dosha Analyzer
/// Detects auspicious (Yoga) and inauspicious (Dosha) combinations.
class YogaDoshaAnalyzer {
  /// Analyze chart for common Yogas and Doshas
  /// Analyze chart for common Yogas and Doshas
  static YogaDoshaAnalysisResult analyze(CompleteChartData chart) {
    var yogas = _findYogas(chart);
    final doshas = _findDoshas(chart);

    // Score calculation
    double score = 50.0;
    for (var y in yogas) {
      score += (y.strength / 100.0) * 5;
    }
    for (var d in doshas) {
      score -= (d.strength / 100.0) * 5;
    }
    score = score.clamp(0.0, 100.0);

    return YogaDoshaAnalysisResult(
      yogas: yogas,
      doshas: doshas,
      overallScore: score,
      qualityLabel: _getQualityLabel(score),
      qualityDescription: _getQualityDescription(score),
    );
  }

  // --- Dosha Detection ---

  static List<BhangaResult> _findDoshas(CompleteChartData chart) {
    List<BhangaResult> results = [];

    // Basic Checks
    if (_hasKaalSarpDosha(chart)) {
      results.add(_checkKaalSarpBhanga(chart));
    }
    if (_hasMangalDosha(chart)) {
      results.add(_checkManglikBhanga(chart));
    }
    if (_hasPitraDosha(chart)) {
      results.add(_checkPitraDoshaBhanga(chart));
    }
    if (_hasKemadrumaDosha(chart)) {
      results.add(_checkKemadrumaBhanga(chart));
    }

    // Additional Dosha Checks (with bhanga logic)
    results.add(_checkGrahanDoshaBhanga(chart));
    results.add(_checkVishDoshaBhanga(chart));
    results.add(_checkAngarakDoshaBhanga(chart));
    results.add(_checkShrapitDoshaBhanga(chart));
    results.add(_checkDaridraDoshaBhanga(chart));

    // Advanced Checks (Text based conversion)
    List<String> textDoshas = [];
    _checkConjunctionDoshas(chart, textDoshas);
    _checkHousePlacementDoshas(chart, textDoshas);
    _checkStateStrengthDoshas(chart, textDoshas);
    _checkLifestyleKarmicDoshas(chart, textDoshas);
    _checkBirthTimeDoshas(chart, textDoshas);
    _checkCurseDoshas(chart, textDoshas);

    for (var d in textDoshas) {
      if (d.contains('Guru Chandal')) {
        results.add(_checkGuruChandalBhanga(chart));
      } else if (d.contains('Sakat Dosha')) {
        results.add(_checkSakatBhanga(chart));
      } else {
        // Check for generic weakening/cancellation if applicable, otherwise active
        results.add(
          BhangaResult(
            name: d.split('(').first.trim(),
            description: d,
            isActive: true,
            status: 'Active',
          ),
        );
      }
    }

    return results;
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

  static List<BhangaResult> _findYogas(CompleteChartData chart) {
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
    // 5. Raj Yoga (Kendra-Trikona lords)
    if (_hasRajYoga(chart)) {
      yogas.add('Parasari Raj Yoga (Kendra-Trikona Lord Combination)');
    }

    // 5b. Other Raja Yogas
    _checkRajaYogas(chart, yogas);

    // 6. Dhana Yoga (Wealth combinations)
    yogas.addAll(_findDhanaYogas(chart));

    // 7. Vipreet Raj Yoga (Lords of 6,8,12 in mutual exchanges)
    yogas.addAll(_findVipreetRajYogas(chart));

    // 7b. Specific Kala Sarpa Yogas
    yogas.addAll(_findKalaSarpaYogas(chart));

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

    // 27. 12 Bhavas Yogas
    _checkBhavaYogas(chart, yogas);

    // 28. Miscellaneous Yogas
    _checkMiscYogas(chart, yogas);

    return yogas.map((y) {
      String name = y.contains('(') ? y.split('(').first.trim() : y;
      return _checkYogaWeakening(chart, name, y);
    }).toList();
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
        bool hasCancellation = false;
        List<String> cancellationReasons = [];

        // Cancellation 1: Debilitation sign lord in kendra from Lagna/Moon
        if (_isPlanetInKendra(chart, debilSignLord)) {
          hasCancellation = true;
          cancellationReasons.add('lord of debilitation sign in Kendra');
        }

        // Cancellation 2: Exaltation sign lord in kendra
        if (_isPlanetInKendra(chart, exaltSignLord)) {
          hasCancellation = true;
          cancellationReasons.add('lord of exaltation sign in Kendra');
        }

        // Cancellation 3: Debilitated planet aspected by its debilitation sign lord
        if (_isAspecting(chart, debilSignLord, planet, [5, 7, 9]) ||
            _areConjunct(chart, debilSignLord, planet)) {
          hasCancellation = true;
          cancellationReasons.add('aspected by debilitation sign lord');
        }

        // Cancellation 4: Conjunction with exalted planet or planet in own sign
        for (var otherPlanet in [
          'Sun',
          'Moon',
          'Mars',
          'Mercury',
          'Jupiter',
          'Venus',
          'Saturn',
        ]) {
          if (otherPlanet == planet) continue;
          final otherSign = _getPlanetSign(chart, otherPlanet);
          if (_areConjunct(chart, planet, otherPlanet)) {
            if (_isExalted(otherPlanet, otherSign)) {
              hasCancellation = true;
              cancellationReasons.add('conjunct exalted $otherPlanet');
              break;
            }
            if (_isOwnSign(otherPlanet, otherSign)) {
              hasCancellation = true;
              cancellationReasons.add('conjunct $otherPlanet in own sign');
              break;
            }
          }
        }

        // Cancellation 5: Mutual exchange (Parivartana) with debilitation sign lord
        if (_areInMutualExchange(chart, planet, debilSignLord)) {
          hasCancellation = true;
          cancellationReasons.add('mutual exchange with debilitation lord');
        }

        // Cancellation 6: Retrograde debilitated planet
        if (_isRetrograde(chart, planet)) {
          hasCancellation = true;
          cancellationReasons.add('planet is retrograde');
        }

        // Cancellation 7: Exalted in Navamsha (D-9)
        final navamsa = chart.divisionalCharts['D-9'];
        if (navamsa != null) {
          final navamsaSign = navamsa.getPlanetSign(planet);
          if (_isExalted(planet, navamsaSign)) {
            hasCancellation = true;
            cancellationReasons.add('exalted in Navamsha (D-9)');
          }
        }

        // Cancellation 8: Lords of debilitation and exaltation signs in mutual Kendras
        if (_areInMutualKendras(chart, debilSignLord, exaltSignLord)) {
          hasCancellation = true;
          cancellationReasons.add(
            'debilitation and exaltation lords in mutual Kendras',
          );
        }

        if (hasCancellation) {
          final reasons = cancellationReasons.join(', ');
          yogas.add('Neecha Bhanga Raj Yoga ($planet - $reasons)');
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
      if (entry.key.toString().split('.').last.toLowerCase() ==
          planetName.toLowerCase()) {
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

    // Sula: Planets in 3 signs (Sankhya).
    // Akriti Sula: "Planets in kendras and panaparas (specific pattern)".

    // 54. Sringataka Yoga (Planets in Trikonas 1, 5, 9)
    if (planetHouses.values.every((h) => {1, 5, 9}.contains(h))) {
      yogas.add('Sringataka Yoga (Akriti - Planets in Trikonas)');
    }

    // 55. Hala Yoga (Planets in Trikonas to each other, e.g. 2,6,10 or 3,7,11)
    // Usually means all planets are in a set of trines.
    // Trikona sets: {1,5,9}, {2,6,10}, {3,7,11}, {4,8,12}
    List<Set<int>> trineSets = [
      {1, 5, 9},
      {2, 6, 10},
      {3, 7, 11},
      {4, 8, 12},
    ];
    for (var set in trineSets) {
      if (planetHouses.values.every((h) => set.contains(h))) {
        yogas.add('Hala Yoga (Akriti - Planets in mutual trines)');
      }
    }

    // 52. Sakata Yoga (Planets in Lagna & 7th)
    // User def: "Planets in Lagna & 7th (Driver, sickly)"
    // This overlaps with Vajra/Yava/Danda in some ways but specific to 1-7 axis only.
    if (planetHouses.values.every((h) => {1, 7}.contains(h))) {
      yogas.add('Sakata Yoga (Akriti - Planets in 1 & 7)');
    }

    // 53. Vihaga Yoga (Planets in 4th & 10th)
    if (planetHouses.values.every((h) => {4, 10}.contains(h))) {
      yogas.add('Vihaga Yoga (Akriti - Planets in 4 & 10)');
    }

    // 69. Chakra Yoga (Planets in odd houses 1, 3, 5, 7, 9, 11)
    if (planetHouses.values.every((h) => h % 2 != 0)) {
      yogas.add('Chakra Yoga (Planets in Odd Houses)');
    }

    // 70. Samudra Yoga (Planets in even houses 2, 4, 6, 8, 10, 12)
    if (planetHouses.values.every((h) => h % 2 == 0)) {
      yogas.add('Samudra Yoga (Planets in Even Houses)');
    }

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

    // 35. Gauri Yoga (Moon exalted in Kendra/Trikona, aspected by Jupiter)
    final moonS = _getPlanetSign(chart, 'Moon');
    if (_isExalted('Moon', moonS) &&
        (_isPlanetInKendra(chart, 'Moon') ||
            _isPlanetInTrikona(chart, 'Moon'))) {
      // Aspected by Jupiter (Conjunct or Opposition or 5th/9th from Jup)
      // Removed unused jupS
      if (_areConjunct(chart, 'Moon', 'Jupiter') ||
          _areOpposite(chart, 'Jupiter', 'Moon') ||
          _isAspecting(chart, 'Jupiter', 'Moon', [5, 9])) {
        yogas.add('Gauri Yoga (Exalted Moon aspected by Jupiter)');
      }
    }

    // 36. Bheri Yoga (9th lord strong, planets in 1, 2, 7, 12)
    final l9 = _getHouseLord(chart, 9);
    final l9Sign = _getPlanetSign(chart, l9);
    if (_isOwnSign(l9, l9Sign) || _isExalted(l9, l9Sign)) {
      // Check visible planets in 1, 2, 7, 12
      bool allInHouses = true;
      for (var p in _visiblePlanets) {
        final h = _getPlanetHouse(chart, p);
        if (![1, 2, 7, 12].contains(h)) {
          allInHouses = false;
          break;
        }
      }
      if (allInHouses) {
        yogas.add('Bheri Yoga (Strong 9th Lord, Planets in 1/2/7/12)');
      }
    }

    // 39. Akhanda Samrajya Yoga (2, 9, 11 lord in Kendra from Moon, Jupiter strong)
    // Jupiter strong implies Own/Exalted.
    // Lord of 2, 9, or 11 in Kendra from Moon.
    final jupSign = _getPlanetSign(chart, 'Jupiter');
    if (_isOwnSign('Jupiter', jupSign) || _isExalted('Jupiter', jupSign)) {
      final l2 = _getHouseLord(chart, 2);
      final l9_2 = _getHouseLord(chart, 9);
      final l11 = _getHouseLord(chart, 11);

      bool conditionMet = false;
      final moonSign = _getPlanetSign(chart, 'Moon');

      // Check l2
      int l2Sign = _getPlanetSign(chart, l2);
      int d2 = (l2Sign - moonSign + 12) % 12;
      if ([0, 3, 6, 9].contains(d2)) conditionMet = true;

      // Check l9
      int l9Sign2 = _getPlanetSign(chart, l9_2);
      int d9 = (l9Sign2 - moonSign + 12) % 12;
      if ([0, 3, 6, 9].contains(d9)) conditionMet = true;

      // Check l11
      int l11Sign = _getPlanetSign(chart, l11);
      int d11 = (l11Sign - moonSign + 12) % 12;
      if ([0, 3, 6, 9].contains(d11)) conditionMet = true;

      if (conditionMet) yogas.add('Akhanda Samrajya Yoga (Unbroken Wealth)');
    }

    // 38. Srinatha Yoga (7th exalted in 10th, 10th with 9th)
    final l7 = _getHouseLord(chart, 7);
    if (_getPlanetHouse(chart, l7) == 10 &&
        _isExalted(l7, _getPlanetSign(chart, l7))) {
      final l10 = _getHouseLord(chart, 10);
      final l9 = _getHouseLord(chart, 9);
      if (_areConjunct(chart, l9, l10)) {
        yogas.add(
          'Srinatha Yoga (Exalted 7th Lord in 10th + 9th/10th Connection)',
        );
      }
    }
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
    // Simplified: Lords in Kendra/Trikona

    // 43. Kalanidhi Yoga (Jupiter in 2/5 with Merc/Ven)
    final jupSign = _getPlanetSign(chart, 'Jupiter');
    final jupHouse = _getPlanetHouse(chart, 'Jupiter');
    if (jupHouse == 2 || jupHouse == 5) {
      final mercSign = _getPlanetSign(chart, 'Mercury');
      final venSign = _getPlanetSign(chart, 'Venus');
      if (jupSign == mercSign ||
          jupSign == venSign ||
          _areOpposite(chart, 'Jupiter', 'Mercury') ||
          _areOpposite(chart, 'Jupiter', 'Venus')) {
        // Associated usually means conjunct or aspected.
        yogas.add('Kalanidhi Yoga (Jupiter in 2/5 with Merc/Ven)');
      }
    }

    // 44. Brahma Yoga (Jup/Ven in Kendra to lords of 4/10/11)
    final l4 = _getHouseLord(chart, 4);
    final l10 = _getHouseLord(chart, 10);
    final l11 = _getHouseLord(chart, 11);

    // Check if Jup/Ven is in Kendra from Lagna (approximation for strength)
    // Detailed rule: Jup/Ven in Kendra from Lord of 4/10/11 is distinct.
    // Simplifying to: Jup/Ven in Kendra AND related to 4/10/11 lords
    if (_isPlanetInKendra(chart, 'Jupiter') ||
        _isPlanetInKendra(chart, 'Venus')) {
      // Logic for exact Brahma Yoga is complex (different from Jataka Parijata vs Phaladeepika)
      // Implementation: Jup in Kendra from 9th lord? No, user says "Jup/Ven in Kendra to lords of 4/10/11".
      // We'll skip complex relative Kendra check and use a strong placement proxy.
      // User description: "Spirituality, creation"
      // We will check if Jup/Ven are in Kendra and 4/10/11 lords are strong.
      final l4Sign = _getPlanetSign(chart, l4);
      final l10Sign = _getPlanetSign(chart, l10);
      final l11Sign = _getPlanetSign(chart, l11);

      bool l4Strong = _isPlanetInKendra(chart, l4) || _isExalted(l4, l4Sign);
      bool l10Strong =
          _isPlanetInKendra(chart, l10) || _isExalted(l10, l10Sign);
      bool l11Strong =
          _isPlanetInKendra(chart, l11) || _isExalted(l11, l11Sign);

      if (l4Strong && l10Strong && l11Strong) {
        yogas.add('Brahma Yoga (Strong benefic influence on 4/10/11)');
      }
    }

    // 45. Sharada Yoga (10th lord in 5th, Merc/Sun strong)
    if (_getPlanetHouse(chart, _getHouseLord(chart, 10)) == 5) {
      // Check Merc/Sun strength
      if (_isExalted('Sun', _getPlanetSign(chart, 'Sun')) ||
          _isOwnSign('Sun', _getPlanetSign(chart, 'Sun')) ||
          _isExalted('Mercury', _getPlanetSign(chart, 'Mercury'))) {
        yogas.add('Sharada Yoga (10th Lord in 5th, Strong Sun/Merc)');
      }
    }
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

  static void _checkBhavaYogas(CompleteChartData chart, List<String> yogas) {
    // 93. Chamara (1st) - Covered explicitly in main list, but adding here for completeness if missed
    final l1 = _getHouseLord(chart, 1);
    if (_isStrong(chart, l1)) yogas.add('Chamara Yoga (Strong Lagna Lord)');

    // 94. Dhenu (2nd)
    final l2 = _getHouseLord(chart, 2);
    if (_isStrong(chart, l2)) yogas.add('Dhenu Yoga (Strong 2nd Lord)');

    // 95. Shaurya (3rd)
    final l3 = _getHouseLord(chart, 3);
    if (_isStrong(chart, l3)) yogas.add('Shaurya Yoga (Strong 3rd Lord)');

    // 96. Jaladhi (4th)
    final l4 = _getHouseLord(chart, 4);
    if (_isStrong(chart, l4)) yogas.add('Jaladhi Yoga (Strong 4th Lord)');

    // 97. Chhatra (5th)
    final l5 = _getHouseLord(chart, 5);
    if (_isStrong(chart, l5)) yogas.add('Chhatra Yoga (Strong 5th Lord)');

    // 98. Astra (6th)
    final l6 = _getHouseLord(chart, 6);
    if (_isStrong(chart, l6)) yogas.add('Astra Yoga (Strong 6th Lord)');

    // 99. Kama (7th)
    final l7 = _getHouseLord(chart, 7);
    if (_isStrong(chart, l7)) yogas.add('Kama Yoga (Strong 7th Lord)');

    // 100. Asura (8th)
    final l8 = _getHouseLord(chart, 8);
    if (_isStrong(chart, l8)) yogas.add('Asura Yoga (Strong 8th Lord)');

    // 101. Bhagya (9th)
    final l9 = _getHouseLord(chart, 9);
    if (_isStrong(chart, l9)) yogas.add('Bhagya Yoga (Strong 9th Lord)');

    // 102. Khyati (10th) - duplicated name, but ok
    final l10 = _getHouseLord(chart, 10);
    if (_isStrong(chart, l10)) yogas.add('Khyati Yoga (Strong 10th Lord)');

    // 103. Suparijata (11th)
    final l11 = _getHouseLord(chart, 11);
    if (_isStrong(chart, l11)) yogas.add('Suparijata Yoga (Strong 11th Lord)');

    // 104. Musala (12th)
    final l12 = _getHouseLord(chart, 12);
    if (_isStrong(chart, l12)) yogas.add('Musala Yoga (Strong 12th Lord)');
  }

  static void _checkMiscYogas(CompleteChartData chart, List<String> yogas) {
    // 105. Simhasana Yoga (10th in Lagna)
    final l10 = _getHouseLord(chart, 10);
    if (_getPlanetHouse(chart, l10) == 1) {
      yogas.add('Simhasana Yoga (10th Lord in Lagna)');
    }

    // 110. Matsya Yoga
    // Benefics in 1/9, Malefics in 4/8, Benefics in 5
    // Simplified: Benefics in Lagna/9th
    final l1Planets = _getPlanetsInHouseFrom(
      chart,
      1,
      _getAscendantSign(chart),
    );
    final l9Planets = _getPlanetsInHouseFrom(
      chart,
      9,
      _getAscendantSign(chart),
    );
    if (l1Planets.any(_isBenefic) || l9Planets.any(_isBenefic)) {
      // Strict Matsya is hard, adding generic marker if partial match
      // yogas.add('Matsya Yoga (Mystic potential)');
    }

    // 112. Khadga Yoga (2nd in 9th, 9th in 2nd)
    final l2 = _getHouseLord(chart, 2);
    final l9 = _getHouseLord(chart, 9);
    if (_getPlanetHouse(chart, l2) == 9 && _getPlanetHouse(chart, l9) == 2) {
      yogas.add('Khadga Yoga (2nd-9th Exchange)');
    }

    // 115. Trimurthi Yoga (Benefics in 2, 9, 11)
    final p2 = _getPlanetsInHouseFrom(chart, 2, _getAscendantSign(chart));
    final p9 = _getPlanetsInHouseFrom(chart, 9, _getAscendantSign(chart));
    final p11 = _getPlanetsInHouseFrom(chart, 11, _getAscendantSign(chart));
    if (p2.any(_isBenefic) && p9.any(_isBenefic) && p11.any(_isBenefic)) {
      yogas.add('Trimurthi Yoga (Benefics in 2, 9, 11)');
    }

    // 147. Sanyasa Yoga (4+ planets in one house)
    for (int h = 1; h <= 12; h++) {
      final planets = _getPlanetsInHouseFrom(
        chart,
        h,
        _getAscendantSign(chart),
      );
      if (planets.length >= 4) {
        yogas.add('Sanyasa Yoga (4+ Planets in House $h)');
        break;
      }
    }
  }

  static bool _isStrong(CompleteChartData chart, String planet) {
    final sign = _getPlanetSign(chart, planet);
    return _isExalted(planet, sign) ||
        _isOwnSign(planet, sign) ||
        _isPlanetInKendra(chart, planet);
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

  // --- Kala Sarpa Specifics ---

  static List<String> _findKalaSarpaYogas(CompleteChartData chart) {
    List<String> yogas = [];
    if (!_hasKaalSarpDosha(chart)) return yogas;

    final rahuHouse = _getPlanetHouse(chart, 'Rahu');
    final ketuHouse = _getPlanetHouse(chart, 'Ketu');

    // 81-92: Named Kala Sarpa Yogas
    if (rahuHouse == 1 && ketuHouse == 7) yogas.add('Ananta Kala Sarpa Yoga');
    if (rahuHouse == 2 && ketuHouse == 8) yogas.add('Kulika Kala Sarpa Yoga');
    if (rahuHouse == 3 && ketuHouse == 9) yogas.add('Vasuki Kala Sarpa Yoga');
    if (rahuHouse == 4 && ketuHouse == 10) {
      yogas.add('Shankhapala Kala Sarpa Yoga');
    }
    if (rahuHouse == 5 && ketuHouse == 11) yogas.add('Padma Kala Sarpa Yoga');
    if (rahuHouse == 6 && ketuHouse == 12) {
      yogas.add('Mahapadma Kala Sarpa Yoga');
    }
    if (rahuHouse == 7 && ketuHouse == 1) yogas.add('Takshaka Kala Sarpa Yoga');
    if (rahuHouse == 8 && ketuHouse == 2) {
      yogas.add('Karkotaka Kala Sarpa Yoga');
    }
    if (rahuHouse == 9 && ketuHouse == 3) {
      yogas.add('Shankhachuda Kala Sarpa Yoga');
    }
    if (rahuHouse == 10 && ketuHouse == 4) yogas.add('Ghataka Kala Sarpa Yoga');
    if (rahuHouse == 11 && ketuHouse == 5) {
      yogas.add('Vishdhana Kala Sarpa Yoga');
    }
    if (rahuHouse == 12 && ketuHouse == 6) {
      yogas.add('Sheshnag Kala Sarpa Yoga');
    }

    return yogas;
  }

  // --- Raja Yogas ---

  static void _checkRajaYogas(CompleteChartData chart, List<String> yogas) {
    // 19. Dharma-Karmadhipati Yoga (9th & 10th Lords)
    // Covered by Raj Yoga generic check, but adding specific name if present
    final l9 = _getHouseLord(chart, 9);
    final l10 = _getHouseLord(chart, 10);
    if (_areConjunct(chart, l9, l10) || _areInMutualExchange(chart, l9, l10)) {
      yogas.add('Dharma-Karmadhipati Raja Yoga (9th & 10th Lord Connection)');
    }

    // 24/25. Mahabhagya Yoga (Day/Night + Odd/Even signs)
    // Skipping due to complexity of Day/Night calculation without Time of Birth context in simple form
    // We need IsDayBirth flag in chart data, assuming logic can be added later.

    // 27. Maharaj Yoga (Lagna & 5th exchange)
    final l1 = _getHouseLord(chart, 1);
    final l5 = _getHouseLord(chart, 5);
    if (_areInMutualExchange(chart, l1, l5) || _areConjunct(chart, l1, l5)) {
      yogas.add('Maharaj Yoga (Lagna & 5th Lord Connection)');
    }

    // 28. Samraj Yoga (Lagna & 9th exchange)
    if (_areInMutualExchange(chart, l1, l9) || _areConjunct(chart, l1, l9)) {
      yogas.add('Samraj Yoga (Lagna & 9th Lord Connection)');
    }

    // 29. Khyati Yoga (10th lord in own/exalted)
    final l10Sign = _getPlanetSign(chart, l10);
    if (_isOwnSign(l10, l10Sign) || _isExalted(l10, l10Sign)) {
      if (!yogas.any((y) => y.contains('Khyati'))) {
        yogas.add('Khyati Yoga (Good Fame - Strong 10th Lord)');
      }
    }

    // 30. Parijata Yoga
    // Lord of sign where Lagna Lord is placed...
    final l1Sign = _getPlanetSign(chart, l1);
    final dispositor = _getSignLord(l1Sign);
    // ...is in Kendra/Trikona
    if (_isPlanetInKendra(chart, dispositor) ||
        _isPlanetInTrikona(chart, dispositor)) {
      yogas.add('Parijata Yoga (Dispositor of Lagna Lord strong)');
    }
  }

  static bool _isPlanetInTrikona(CompleteChartData chart, String planet) {
    final pSign = _getPlanetSign(chart, planet);
    final lagnaSign = _getHouse(chart, 1);
    final diff = (pSign - lagnaSign + 12) % 12;
    return [0, 4, 8].contains(diff); // 1, 5, 9 houses (0-based indices)
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

  static void _checkBirthTimeDoshas(
    CompleteChartData chart,
    List<String> doshas,
  ) {
    // Helpers
    final moonLong = _getPlanetLongitude(chart, 'Moon');
    final sunLong = _getPlanetLongitude(chart, 'Sun');
    final tithiInfo = _calculateTithi(
      moonLong,
      sunLong,
    ); // returns {index, name, isShukla}
    final nakshatraIndex = _getNakshatraIndex(moonLong);
    final weekday = chart.birthData.dateTime.weekday; // 1=Mon, 7=Sun (ISO)

    // 1. Gandamoola Dosha
    // Nakshatras: Ashwini(0), Ashlesha(8), Magha(9), Jyeshtha(17), Moola(18), Revati(26)
    if ([0, 8, 9, 17, 18, 26].contains(nakshatraIndex)) {
      doshas.add('Gandamoola Dosha (Moon in Gandanta Nakshatra)');
    }

    // 2. Amavasya Dosha
    // Tithi 30 (Amavasya) or separation < 12 degrees
    double diff = (moonLong - sunLong);
    if (diff < 0) diff += 360;
    if (diff < 12.0) {
      doshas.add('Amavasya Dosha (Birth on New Moon)');
    }

    // 3. Krishna Chaturdashi Dosha
    // Waning 14th (Tithi 29). Range: 336-348 degrees (approx)
    // Tithi index 1-30. 29 is Krishna Chaturdashi.
    if (tithiInfo['index'] == 29) {
      doshas.add('Krishna Chaturdashi Dosha (Birth on 14th Waning Tithi)');
    }

    // 3. Special Combinations

    // Visha Kanya Dosha (Females only - simplified check, we assume female context or warn generally)
    // Common mappings:
    // Sunday (7) + 2nd Tithi + Ashlesha (8)
    // Tuesday (2) + 7th Tithi + Shatabhisha (23)
    // Saturday (6) + 12th Tithi + Krittika (2)
    // Note: ISO weekday 7=Sunday, 6=Saturday, 2=Tuesday.
    bool vishaKanya = false;
    int tithi = tithiInfo['index'];
    // Adjust Tithi to 1-15 scale? Usually texts say "2nd Tithi" (Dwitiya), implies of either Paksha generally
    // but often specific. Assuming specific Tithi number (1-30) logic:
    // "2nd Tithi" usually means 2 (Shukla) or 17 (Krishna). Let's assume generic Tithi number (1-15).
    int tithiDay = (tithi - 1) % 15 + 1;

    if (weekday == 7 && tithiDay == 2 && nakshatraIndex == 8) {
      vishaKanya = true;
    }
    if (weekday == 2 && tithiDay == 7 && nakshatraIndex == 23) {
      vishaKanya = true;
    }
    if (weekday == 6 && tithiDay == 12 && nakshatraIndex == 2) {
      vishaKanya = true;
    }

    if (vishaKanya) {
      doshas.add('Visha Kanya Dosha (Inauspicious Time Combination)');
    }

    // Punarphoo Dosha
    // Saturn-Moon Connection
    if (_areConjunct(chart, 'Saturn', 'Moon') ||
        _areOpposite(chart, 'Saturn', 'Moon') ||
        _isAspecting(chart, 'Saturn', 'Moon', [3, 7, 10])) {
      doshas.add('Punarphoo Dosha (Saturn-Moon Connection)');
    }
  }

  static void _checkCurseDoshas(CompleteChartData chart, List<String> doshas) {
    // 1. Matru Dosha (Mother's Curse)
    // Moon afflicted + 4th House afflicted
    if (_isAfflicted(chart, 'Moon') && _isHouseAfflicted(chart, 4)) {
      doshas.add('Matru Shaap (Mother\'s Curse - Afflicted Moon & 4th House)');
    }

    // 2. Bhatri Dosha (Brother's Curse)
    // Mars afflicted + 3rd House afflicted
    if (_isAfflicted(chart, 'Mars') && _isHouseAfflicted(chart, 3)) {
      doshas.add(
        'Bhatri Shaap (Brother\'s Curse - Afflicted Mars & 3rd House)',
      );
    }

    // 3. Brahma Dosha (Brahmin's Curse)
    // Jupiter afflicted by Saturn/Rahu/Mars
    if (_isAfflictedBy(chart, 'Jupiter', ['Saturn', 'Rahu', 'Mars'])) {
      doshas.add('Brahma Shaap (Curse of Knowledge - Afflicted Jupiter)');
    }

    // 4. Sarpa Dosha (Serpent's Curse)
    // 5th House occupied/aspected by Rahu/Ketu OR Mars/Saturn
    // Simplified: 5th house affliction by Malefics
    final p5 = _getPlanetsInHouseFrom(chart, 5, _getAscendantSign(chart));
    bool maleficIn5 = p5.any(
      (p) => ['Rahu', 'Ketu', 'Mars', 'Saturn'].contains(p),
    );
    // Check aspect on 5th?
    // For now, occupancy is a strong indicator.
    if (maleficIn5) {
      doshas.add('Sarpa Shaap (Serpent Curse - Afflicted 5th House)');
    }
  }

  // --- Bhanga (Cancellation) Rules ---

  static BhangaResult _checkManglikBhanga(CompleteChartData chart) {
    List<String> cancellations = [];

    // 1. Mars in Own Sign or Exaltation
    final marsSign = _getPlanetSign(chart, 'Mars');
    if (_isOwnSign('Mars', marsSign) || _isExalted('Mars', marsSign)) {
      cancellations.add('Mars is in own sign or exalted sign');
    }

    // 2. Aspect of Jupiter
    if (_isAspecting(chart, 'Jupiter', 'Mars', [5, 7, 9]) ||
        _areConjunct(chart, 'Jupiter', 'Mars')) {
      cancellations.add('Mars is aspected by or conjunct with Jupiter');
    }

    // 3. Venus in Kendra
    // Venus in 1, 4, 7, 10 from Lagna
    if (_isPlanetInKendra(chart, 'Venus')) {
      cancellations.add('Venus is in a Kendra house');
    }

    // 4. Mars in 2nd house with benefic aspect
    final marsHouse = _getPlanetHouse(chart, 'Mars');
    if (marsHouse == 2) {
      // Check for benefic aspect (Jup, Ven, Mer, Moon)
      // Simplified check
      if (_isAspecting(chart, 'Jupiter', 'Mars', [5, 7, 9]) ||
          _isAspecting(chart, 'Venus', 'Mars', [7])) {
        cancellations.add('Mars is in 2nd house with benefic aspect');
      }
    }

    // 5. Sign-specific cancellations per BPHS
    // Mars in Gemini/Virgo in 2nd house
    if (marsHouse == 2 && [2, 5].contains(marsSign)) {
      cancellations.add('Mars in Gemini/Virgo in 2nd house (BPHS)');
    }
    // Mars in Cancer/Capricorn in 7th house
    if (marsHouse == 7 && [3, 9].contains(marsSign)) {
      cancellations.add('Mars in Cancer/Capricorn in 7th house (BPHS)');
    }
    // Mars in Sagittarius/Pisces in 8th house
    if (marsHouse == 8 && [8, 11].contains(marsSign)) {
      cancellations.add('Mars in Sagittarius/Pisces in 8th house (BPHS)');
    }
    // Mars in Taurus/Libra in 12th house
    if (marsHouse == 12 && [1, 6].contains(marsSign)) {
      cancellations.add('Mars in Taurus/Libra in 12th house (BPHS)');
    }

    // 6. Ascendant-specific cancellations
    final lagnaSign = _getAscendantSign(chart);
    // Cancer/Leo ascendant - Mars is Yogakaraka
    if ([3, 4].contains(lagnaSign)) {
      cancellations.add('Cancer/Leo ascendant - Mars is Yogakaraka');
    }
    // Aquarius ascendant, Mars in 4th/8th
    if (lagnaSign == 10 && [4, 8].contains(marsHouse)) {
      cancellations.add('Aquarius ascendant with Mars in 4th/8th house');
    }

    // 7. Mars in movable sign (Aries, Cancer, Libra, Capricorn)
    if ([0, 3, 6, 9].contains(marsSign)) {
      cancellations.add('Mars in movable sign (Parashara)');
    }

    // 8. Weak/debilitated/combust Mars
    if (_isDebilitated('Mars', marsSign)) {
      cancellations.add('Mars is debilitated (weak dosha)');
    }
    if (_isCombust(chart, 'Mars')) {
      cancellations.add('Mars is combust (weak dosha)');
    }

    // 9. Saturn aspect or placement cancellation
    if (_isAspecting(chart, 'Saturn', 'Mars', [3, 7, 10]) ||
        _areConjunct(chart, 'Saturn', 'Mars')) {
      cancellations.add('Saturn aspects or conjoins Mars');
    }

    // Calculate status
    double strength = 100.0;
    if (cancellations.isNotEmpty) {
      // Strong cancellations (reduce to 0)
      if (cancellations.any((c) => c.contains('Yogakaraka')) ||
          cancellations.any((c) => c.contains('own sign or exalted')) ||
          (cancellations.length >= 3)) {
        strength = 0.0; // Fully cancelled
      } else if (cancellations.length >= 2 ||
          cancellations.any((c) => c.contains('Jupiter'))) {
        strength = 20.0; // Heavily reduced
      } else {
        strength = 50.0; // Partially reduced
      }
    }

    String status = 'Active';
    if (strength == 0.0) {
      status = 'Fully Cancelled';
    } else if (strength < 30.0) {
      status = 'Mostly Cancelled';
    } else if (strength < 100.0) {
      status = 'Partially Cancelled';
    }

    return BhangaResult(
      name: 'Manglik Dosha',
      description: 'Mars in sensitive houses affecting relationships',
      isActive: strength > 20,
      cancellationReasons: cancellations,
      strength: strength,
      status: status,
    );
  }

  static BhangaResult _checkKaalSarpBhanga(CompleteChartData chart) {
    List<String> cancellations = [];

    // 1. Planet with Rahu/Ketu (conjunction breaks the axis)
    // Check if any visible planet is conjunct Rahu or Ketu
    for (var p in _visiblePlanets) {
      if (_areConjunct(chart, p, 'Rahu') || _areConjunct(chart, p, 'Ketu')) {
        cancellations.add('Axis broken: $p is conjunct with Nodes');
      }
    }

    // 2. Degree-based check: Planet in same house as Rahu/Ketu but outside axis by degrees
    final rahuLong = _getPlanetLongitude(chart, 'Rahu');
    final ketuLong = _getPlanetLongitude(chart, 'Ketu');
    for (var p in _visiblePlanets) {
      final pLong = _getPlanetLongitude(chart, p);
      final rahuHouse = _getPlanetHouse(chart, 'Rahu');
      final ketuHouse = _getPlanetHouse(chart, 'Ketu');
      final pHouse = _getPlanetHouse(chart, p);

      // If planet is in same house as Rahu or Ketu
      if (pHouse == rahuHouse || pHouse == ketuHouse) {
        // Check if degrees place it outside the axis
        if (!_isBetween(pLong, rahuLong, ketuLong)) {
          cancellations.add('$p outside Rahu-Ketu axis by degrees');
        }
      }
    }

    // 3. Strong Lagna Lord
    final l1 = _getHouseLord(chart, 1);
    if (_isStrong(chart, l1)) {
      cancellations.add('Lagna Lord is strong');
    }

    // 4. Benefic Aspect on Nodes
    if (_isAspecting(chart, 'Jupiter', 'Rahu', [5, 7, 9]) ||
        _isAspecting(chart, 'Jupiter', 'Ketu', [5, 7, 9])) {
      cancellations.add('Jupiter aspects Rahu/Ketu');
    }

    // 5. Gaja Kesari Yoga present (strong cancellation)
    if (_hasGajakesariYoga(chart)) {
      final jupSign = _getPlanetSign(chart, 'Jupiter');
      // Only if Jupiter is not debilitated or combust
      if (!_isDebilitated('Jupiter', jupSign) &&
          !_isCombust(chart, 'Jupiter')) {
        cancellations.add('Gaja Kesari Yoga present (strong override)');
      }
    }

    // 6. Strong Raja Yogas present
    if (_hasRajYoga(chart)) {
      cancellations.add('Parasari Raj Yoga present');
    }

    // 7. Benefic planet in Kendra in exalted/own sign
    for (var benefic in ['Jupiter', 'Venus', 'Mercury']) {
      if (_isPlanetInKendra(chart, benefic)) {
        final bSign = _getPlanetSign(chart, benefic);
        if (_isExalted(benefic, bSign) || _isOwnSign(benefic, bSign)) {
          cancellations.add('$benefic exalted/own in Kendra');
          break;
        }
      }
    }

    // 8. Lagna not hemmed in Rahu-Ketu axis
    final lagnaLong = chart.baseChart.houses.cusps.isNotEmpty
        ? chart.baseChart.houses.cusps[0]
        : 0.0;
    if (!_isBetween(lagnaLong, rahuLong, ketuLong)) {
      cancellations.add('Lagna outside Rahu-Ketu axis');
    }

    double strength = 100.0;
    if (cancellations.isNotEmpty) {
      // Strong cancellations
      if (cancellations.any((c) => c.contains('Gaja Kesari')) ||
          cancellations.any((c) => c.contains('Axis broken')) ||
          cancellations.length >= 3) {
        strength = 0.0; // Fully cancelled
      } else if (cancellations.length >= 2) {
        strength = 30.0; // Heavily reduced
      } else {
        strength = 60.0; // Partially reduced
      }
    }

    return BhangaResult(
      name: 'Kaal Sarp Dosha',
      description: 'All planets hemmed between Rahu and Ketu',
      isActive: strength > 50,
      cancellationReasons: cancellations,
      strength: strength,
      status: strength == 0.0
          ? 'Fully Cancelled'
          : (strength < 50 ? 'Mostly Cancelled' : 'Active'),
    );
  }

  static BhangaResult _checkPitraDoshaBhanga(CompleteChartData chart) {
    List<String> cancellations = [];

    // 1. Jupiter influence
    // If Jupiter aspects the affliction (Sun/Moon/Nodes)
    bool jupAspect = false;
    for (var p in ['Sun', 'Moon', 'Rahu', 'Ketu']) {
      if (_isAspecting(chart, 'Jupiter', p, [5, 7, 9]) ||
          _areConjunct(chart, 'Jupiter', p)) {
        jupAspect = true;
      }
    }
    if (jupAspect) cancellations.add('Jupiter influence on afflicted planets');

    // 2. Strong 9th Lord
    final l9 = _getHouseLord(chart, 9);
    if (_isStrong(chart, l9)) cancellations.add('9th House Lord is strong');

    double strength = 100.0;
    if (cancellations.isNotEmpty) {
      strength -= (cancellations.length * 40).clamp(0, 100);
    }

    return BhangaResult(
      name: 'Pitra Dosha',
      description: 'Ancestral karmic debt indicators',
      isActive: strength > 40,
      cancellationReasons: cancellations,
      strength: strength,
      status: strength < 100
          ? (strength < 40 ? 'Fully Cancelled' : 'Partially Cancelled')
          : 'Active',
    );
  }

  static BhangaResult _checkKemadrumaBhanga(CompleteChartData chart) {
    List<String> cancellations = [];
    final moonSign = _getPlanetSign(chart, 'Moon');

    // 1. Planet in Kendra from Moon
    bool planetInKendraFromMoon = false;
    for (var p in _visiblePlanets) {
      if (p == 'Moon' || p == 'Sun') continue;
      final pSign = _getPlanetSign(chart, p);
      final dist = (pSign - moonSign + 12) % 12;
      if ([0, 3, 6, 9].contains(dist)) {
        planetInKendraFromMoon = true; // 1,4,7,10
      }
    }
    if (planetInKendraFromMoon) cancellations.add('Planet in Kendra from Moon');

    // 2. Planet in Kendra from Lagna
    bool planetInKendraFromLagna = false;
    for (var p in _visiblePlanets) {
      if (p == 'Moon' || p == 'Sun') continue;
      if (_isPlanetInKendra(chart, p)) planetInKendraFromLagna = true;
    }
    if (planetInKendraFromLagna) {
      cancellations.add('Planet in Kendra from Lagna');
    }

    // 3. Moon aspected by all planets (unlikely but rule)
    // 4. Moon in own/exalted sign
    if (_isOwnSign('Moon', moonSign) || _isExalted('Moon', moonSign)) {
      cancellations.add('Moon is in Own/Exalted sign');
    }

    double strength = 100.0;
    if (cancellations.isNotEmpty) strength = 0.0; // Usually fully cancelled

    return BhangaResult(
      name: 'Kemadruma Dosha',
      description: 'Lonely Moon without support',
      isActive: strength > 10,
      cancellationReasons: cancellations,
      strength: strength,
      status: strength < 10 ? 'Fully Cancelled' : 'Active',
    );
  }

  static BhangaResult _checkGuruChandalBhanga(CompleteChartData chart) {
    List<String> cancellations = [];
    final jupSign = _getPlanetSign(chart, 'Jupiter');

    if (_isOwnSign('Jupiter', jupSign) || _isExalted('Jupiter', jupSign)) {
      cancellations.add('Jupiter is strong in Own/Exalted sign');
    }

    // Benefic aspect (Ven, Mer)
    if (_isAspecting(chart, 'Venus', 'Jupiter', [7]) ||
        _isAspecting(chart, 'Mercury', 'Jupiter', [7])) {
      cancellations.add('Benefic aspect on Jupiter');
    }

    double strength = 100.0;
    if (cancellations.isNotEmpty) strength = 50.0;

    return BhangaResult(
      name: 'Guru Chandal Dosha',
      description: 'Jupiter afflicted by Nodes',
      isActive: strength > 30,
      cancellationReasons: cancellations,
      strength: strength,
      status: strength < 100 ? 'Partially Cancelled' : 'Active',
    );
  }

  static BhangaResult _checkSakatBhanga(CompleteChartData chart) {
    List<String> cancellations = [];

    // Moon in Kendra from Lagna
    if (_isPlanetInKendra(chart, 'Moon')) {
      cancellations.add('Moon is in Kendra from Lagna');
    }

    // Jupiter in Kendra from Lagna
    if (_isPlanetInKendra(chart, 'Jupiter')) {
      cancellations.add('Jupiter is in Kendra from Lagna');
    }

    double strength = 100.0;
    if (cancellations.isNotEmpty) strength = 0.0;

    return BhangaResult(
      name: 'Sakat Dosha',
      description: 'Moon in 6/8/12 from Jupiter',
      isActive: strength > 10,
      cancellationReasons: cancellations,
      strength: strength,
      status: strength < 10 ? 'Fully Cancelled' : 'Active',
    );
  }

  static BhangaResult _checkGrahanDoshaBhanga(CompleteChartData chart) {
    List<String> cancellations = [];

    // Check if Sun or Moon is with nodes
    bool sunWithNode =
        _areConjunct(chart, 'Sun', 'Rahu') ||
        _areConjunct(chart, 'Sun', 'Ketu');
    bool moonWithNode =
        _areConjunct(chart, 'Moon', 'Rahu') ||
        _areConjunct(chart, 'Moon', 'Ketu');

    if (!sunWithNode && !moonWithNode) {
      // No Grahan Dosha
      return BhangaResult(
        name: 'Grahan Dosha',
        description: 'Eclipse-related affliction',
        isActive: false,
        cancellationReasons: ['No Grahan Dosha present'],
        strength: 0.0,
        status: 'Not Present',
      );
    }

    // Jupiter aspect on afflicted luminary
    if (sunWithNode) {
      if (_isAspecting(chart, 'Jupiter', 'Sun', [5, 7, 9])) {
        cancellations.add('Jupiter aspects afflicted Sun');
      }
    }
    if (moonWithNode) {
      if (_isAspecting(chart, 'Jupiter', 'Moon', [5, 7, 9])) {
        cancellations.add('Jupiter aspects afflicted Moon');
      }
    }

    // Strong luminaries (own/exalted)
    if (sunWithNode) {
      final sunSign = _getPlanetSign(chart, 'Sun');
      if (_isOwnSign('Sun', sunSign) || _isExalted('Sun', sunSign)) {
        cancellations.add('Sun is strong (own/exalted)');
      }
    }
    if (moonWithNode) {
      final moonSign = _getPlanetSign(chart, 'Moon');
      if (_isOwnSign('Moon', moonSign) || _isExalted('Moon', moonSign)) {
        cancellations.add('Moon is strong (own/exalted)');
      }
    }

    // Nodes in friendly signs
    final rahuSign = _getPlanetSign(chart, 'Rahu');
    final ketuSign = _getPlanetSign(chart, 'Ketu');
    // Rahu friendly in Gemini, Virgo; Ketu friendly in Sagittarius, Pisces
    if ([2, 5].contains(rahuSign) || [8, 11].contains(ketuSign)) {
      cancellations.add('Nodes in friendly signs');
    }

    double strength = 100.0;
    if (cancellations.length >= 2) {
      strength = 0.0;
    } else if (cancellations.length == 1) {
      strength = 40.0;
    }

    return BhangaResult(
      name: 'Grahan Dosha',
      description: 'Eclipse-related affliction (Sun/Moon with nodes)',
      isActive: strength > 30,
      cancellationReasons: cancellations,
      strength: strength,
      status: strength == 0.0
          ? 'Fully Cancelled'
          : (strength < 50 ? 'Partially Cancelled' : 'Active'),
    );
  }

  static BhangaResult _checkVishDoshaBhanga(CompleteChartData chart) {
    List<String> cancellations = [];

    // Check if Saturn-Moon conjunction exists
    if (!_areConjunct(chart, 'Saturn', 'Moon')) {
      return BhangaResult(
        name: 'Vish/Punarphoo Dosha',
        description: 'Saturn-Moon conjunction',
        isActive: false,
        cancellationReasons: ['No Vish Dosha present'],
        strength: 0.0,
        status: 'Not Present',
      );
    }

    // Moon in own/exalted
    final moonSign = _getPlanetSign(chart, 'Moon');
    if (_isOwnSign('Moon', moonSign) || _isExalted('Moon', moonSign)) {
      cancellations.add('Moon is in own/exalted sign');
    }

    // Jupiter aspect
    if (_isAspecting(chart, 'Jupiter', 'Moon', [5, 7, 9]) ||
        _isAspecting(chart, 'Jupiter', 'Saturn', [5, 7, 9])) {
      cancellations.add('Jupiter aspects Moon or Saturn');
    }

    // Strong 4th house (Moon's natural house)
    final l4 = _getHouseLord(chart, 4);
    if (_isStrong(chart, l4)) {
      cancellations.add('4th house lord is strong');
    }

    double strength = 100.0;
    if (cancellations.length >= 2) {
      strength = 20.0;
    } else if (cancellations.length == 1) {
      strength = 60.0;
    }

    return BhangaResult(
      name: 'Vish/Punarphoo Dosha',
      description: 'Saturn-Moon conjunction causing emotional challenges',
      isActive: strength > 40,
      cancellationReasons: cancellations,
      strength: strength,
      status: strength < 40
          ? 'Mostly Cancelled'
          : (strength < 70 ? 'Partially Cancelled' : 'Active'),
    );
  }

  static BhangaResult _checkAngarakDoshaBhanga(CompleteChartData chart) {
    List<String> cancellations = [];

    // Check if Mars-Rahu conjunction exists
    if (!_areConjunct(chart, 'Mars', 'Rahu')) {
      return BhangaResult(
        name: 'Angarak Dosha',
        description: 'Mars-Rahu conjunction',
        isActive: false,
        cancellationReasons: ['No Angarak Dosha present'],
        strength: 0.0,
        status: 'Not Present',
      );
    }

    // Mars in own/exalted
    final marsSign = _getPlanetSign(chart, 'Mars');
    if (_isOwnSign('Mars', marsSign) || _isExalted('Mars', marsSign)) {
      cancellations.add('Mars is in own/exalted sign');
    }

    // Jupiter aspect
    if (_isAspecting(chart, 'Jupiter', 'Mars', [5, 7, 9]) ||
        _isAspecting(chart, 'Jupiter', 'Rahu', [5, 7, 9])) {
      cancellations.add('Jupiter aspects Mars or Rahu');
    }

    // Benefic in Lagna
    final lagnaSign = _getAscendantSign(chart);
    for (var benefic in ['Jupiter', 'Venus', 'Mercury']) {
      final bSign = _getPlanetSign(chart, benefic);
      if (bSign == lagnaSign) {
        cancellations.add('Benefic $benefic in Lagna');
        break;
      }
    }

    double strength = 100.0;
    if (cancellations.length >= 2) {
      strength = 10.0;
    } else if (cancellations.length == 1) {
      strength = 50.0;
    }

    return BhangaResult(
      name: 'Angarak Dosha',
      description: 'Mars-Rahu conjunction causing aggression',
      isActive: strength > 30,
      cancellationReasons: cancellations,
      strength: strength,
      status: strength < 30
          ? 'Mostly Cancelled'
          : (strength < 60 ? 'Partially Cancelled' : 'Active'),
    );
  }

  static BhangaResult _checkShrapitDoshaBhanga(CompleteChartData chart) {
    List<String> cancellations = [];

    // Check if Saturn-Rahu conjunction exists
    if (!_areConjunct(chart, 'Saturn', 'Rahu')) {
      return BhangaResult(
        name: 'Shrapit Dosha',
        description: 'Saturn-Rahu conjunction',
        isActive: false,
        cancellationReasons: ['No Shrapit Dosha present'],
        strength: 0.0,
        status: 'Not Present',
      );
    }

    // Jupiter aspect
    if (_isAspecting(chart, 'Jupiter', 'Saturn', [5, 7, 9]) ||
        _isAspecting(chart, 'Jupiter', 'Rahu', [5, 7, 9])) {
      cancellations.add('Jupiter aspects Saturn or Rahu');
    }

    // Saturn in own sign
    final saturnSign = _getPlanetSign(chart, 'Saturn');
    if (_isOwnSign('Saturn', saturnSign)) {
      cancellations.add('Saturn is in own sign');
    }

    // Strong 9th lord (dharma)
    final l9 = _getHouseLord(chart, 9);
    if (_isStrong(chart, l9)) {
      cancellations.add('9th house lord is strong');
    }

    double strength = 100.0;
    if (cancellations.length >= 2) {
      strength = 20.0;
    } else if (cancellations.length == 1) {
      strength = 60.0;
    }

    return BhangaResult(
      name: 'Shrapit Dosha',
      description: 'Saturn-Rahu conjunction indicating ancestral curses',
      isActive: strength > 40,
      cancellationReasons: cancellations,
      strength: strength,
      status: strength < 40
          ? 'Mostly Cancelled'
          : (strength < 70 ? 'Partially Cancelled' : 'Active'),
    );
  }

  static BhangaResult _checkDaridraDoshaBhanga(CompleteChartData chart) {
    List<String> cancellations = [];

    // Check if 11th lord is in dusthana (6, 8, 12)
    final l11 = _getHouseLord(chart, 11);
    final l11House = _getPlanetHouse(chart, l11);

    if (![6, 8, 12].contains(l11House)) {
      return BhangaResult(
        name: 'Daridra Dosha',
        description: '11th lord in dusthana',
        isActive: false,
        cancellationReasons: ['No Daridra Dosha present'],
        strength: 0.0,
        status: 'Not Present',
      );
    }

    // 11th lord in own sign
    final l11Sign = _getPlanetSign(chart, l11);
    if (_isOwnSign(l11, l11Sign)) {
      cancellations.add('11th lord is in own sign');
    }

    // Strong 2nd lord (wealth)
    final l2 = _getHouseLord(chart, 2);
    if (_isStrong(chart, l2)) {
      cancellations.add('2nd house lord is strong');
    }

    // Benefic aspects on 11th lord
    if (_isAspecting(chart, 'Jupiter', l11, [5, 7, 9]) ||
        _isAspecting(chart, 'Venus', l11, [7])) {
      cancellations.add('Benefic aspects 11th lord');
    }

    // Strong Dhana yogas present
    final l2Sign = _getPlanetSign(chart, l2);
    if (_isExalted(l2, l2Sign) || _isOwnSign(l2, l2Sign)) {
      cancellations.add('Strong 2nd lord (exalted/own)');
    }

    double strength = 100.0;
    if (cancellations.length >= 2) {
      strength = 10.0;
    } else if (cancellations.length == 1) {
      strength = 50.0;
    }

    return BhangaResult(
      name: 'Daridra Dosha',
      description: '11th lord in dusthana causing financial challenges',
      isActive: strength > 30,
      cancellationReasons: cancellations,
      strength: strength,
      status: strength < 30
          ? 'Mostly Cancelled'
          : (strength < 60 ? 'Partially Cancelled' : 'Active'),
    );
  }

  // Generic Weakening Check for Yogas
  static BhangaResult _checkYogaWeakening(
    CompleteChartData chart,
    String yogaName,
    String description,
  ) {
    List<String> weaknesses = [];
    double strength = 100.0;

    // Identify key planets based on yoga name
    List<String> keyPlanets = [];
    if (yogaName.contains('Gajakesari')) keyPlanets.addAll(['Jupiter', 'Moon']);
    if (yogaName.contains('Budhaditya')) keyPlanets.addAll(['Sun', 'Mercury']);
    if (yogaName.contains('Chandra Mangala')) {
      keyPlanets.addAll(['Moon', 'Mars']);
    }
    if (yogaName.contains('Ruchaka')) keyPlanets.add('Mars');
    if (yogaName.contains('Bhadra')) keyPlanets.add('Mercury');
    if (yogaName.contains('Hamsa')) keyPlanets.add('Jupiter');
    if (yogaName.contains('Malavya')) keyPlanets.add('Venus');
    if (yogaName.contains('Sasa')) keyPlanets.add('Saturn');

    // Check if key planets are weak
    for (var p in keyPlanets) {
      // Debilitated
      if (_isDebilitated(p, _getPlanetSign(chart, p)) &&
          !yogaName.contains('Neecha Bhanga')) {
        // Excluding Neecha Bhanga yoga itself from this check
        weaknesses.add('$p is Debilitated');
        strength -= 40;
      }
      // Combust
      if (_isCombust(chart, p)) {
        weaknesses.add('$p is Combust');
        strength -= 30;
      }
      // In Dusthana (6, 8, 12) - Context dependent, but generally weak for benefic yogas
      int house = _getPlanetHouse(chart, p);
      if ([6, 8, 12].contains(house) && !yogaName.contains('Vipreet')) {
        weaknesses.add('$p is in Dusthana house ($house)');
        strength -= 20;
      }
    }

    strength = strength.clamp(0.0, 100.0);
    String status = 'Active';
    if (strength < 40) {
      status = 'Weak';
    } else if (strength < 80) {
      status = 'Moderate';
    } else {
      status = 'Strong';
    }

    if (weaknesses.isNotEmpty) {
      // Append weakness info to status for display if needed, or just keep in cancellations list
    }

    return BhangaResult(
      name: yogaName,
      description: description,
      isActive: true, // Yogas are usually positive even if weak, unless broken
      cancellationReasons: weaknesses,
      strength: strength,
      status: status,
    );
  }

  // --- Logic Helpers ---

  static Map<String, dynamic> _calculateTithi(double moonLong, double sunLong) {
    double diff = moonLong - sunLong;
    if (diff < 0) diff += 360;
    int index = (diff / 12).floor() + 1; // 1-30
    return {
      'index': index,
      // 'isShukla': index <= 15
    };
  }

  static int _getNakshatraIndex(double longitude) {
    return (longitude / 13.33333333).floor();
  }

  static bool _isAfflicted(CompleteChartData chart, String planet) {
    // Afflicted if conjoined with nodes or Saturn/Mars, or combust, or debilitated
    if (_isCombust(chart, planet)) return true;
    // Conjunctions
    if (_areConjunct(chart, planet, 'Rahu') ||
        _areConjunct(chart, planet, 'Ketu') ||
        _areConjunct(chart, planet, 'Saturn')) {
      return true;
    }
    // Aspect by Saturn/Mars?
    if (_isAspecting(chart, 'Saturn', planet, [3, 7, 10])) return true;
    if (_isAspecting(chart, 'Mars', planet, [4, 7, 8])) return true;
    return false;
  }

  static bool _isAfflictedBy(
    CompleteChartData chart,
    String planet,
    List<String> malefics,
  ) {
    for (var m in malefics) {
      if (_areConjunct(chart, planet, m)) return true;
      // Aspects
      if (m == 'Saturn' && _isAspecting(chart, m, planet, [3, 7, 10])) {
        return true;
      }
      if (m == 'Mars' && _isAspecting(chart, m, planet, [4, 7, 8])) {
        return true;
      }
      if ((m == 'Rahu' || m == 'Ketu') && _areConjunct(chart, planet, m)) {
        return true;
      }
    }
    return false;
  }

  static bool _isHouseAfflicted(CompleteChartData chart, int house) {
    final lagna = _getAscendantSign(chart);
    final planets = _getPlanetsInHouseFrom(chart, house, lagna);
    bool maleficInHouse = planets.any(_isMalefic);
    // Aspect on house
    // Simplified: just occupancy for now to avoid complexity of computing aspect on empty space
    return maleficInHouse;
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

  static bool _isAspecting(
    CompleteChartData chart,
    String planet,
    String targetPlanet,
    List<int> aspects,
  ) {
    final pSign = _getPlanetSign(chart, planet);
    final tSign = _getPlanetSign(chart, targetPlanet);
    final dist = (tSign - pSign + 12) % 12 + 1;
    return aspects.contains(dist);
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

  static bool _isRetrograde(CompleteChartData chart, String planet) {
    // Rahu and Ketu are always retrograde by nature, Sun and Moon never retrograde
    if (['Sun', 'Moon', 'Rahu', 'Ketu'].contains(planet)) return false;

    for (var entry in chart.baseChart.planets.entries) {
      if (entry.key.toString().split('.').last.toLowerCase() ==
          planet.toLowerCase()) {
        return entry.value.isRetrograde;
      }
    }
    return false;
  }

  static String _getQualityLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Very Good';
    if (score >= 50) return 'Good';
    if (score >= 35) return 'Average';
    return 'Challenging';
  }

  static String _getQualityDescription(double score) {
    if (score >= 80) {
      return 'This is an excellent chart with strong positive combinations and minimal afflictions.';
    } else if (score >= 65) {
      return 'This is a very good chart with several beneficial yogas that support success.';
    } else if (score >= 50) {
      return 'This is a good chart with balanced energies and opportunities for growth.';
    } else if (score >= 35) {
      return 'This chart has average potential with both opportunities and challenges to navigate.';
    }
    return 'This chart has some challenges that require conscious effort and remedial measures.';
  }
}
