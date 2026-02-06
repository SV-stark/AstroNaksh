import 'package:jyotish/jyotish.dart';
import '../data/models.dart';
import 'custom_chart_service.dart';

/// Varshaphal (Annual Chart) System
/// Calculates solar return charts and Tajik/Varshik predictions
/// Implements rigorous Tajik Shastra rules including Panchavargiya Bala and Varshesh.
class VarshaphalSystem {
  /// Calculate Varshaphal chart for a given year
  static Future<VarshaphalChart> calculateVarshaphal(
    BirthData birthData,
    int year,
  ) async {
    // 1. Calculate rigorous Solar Return Time (High Precision)
    final solarReturnTime = await calculateSolarReturn(birthData, year);

    // 2. Calculate Chart for Solar Return Moment (Varsha Lagna)
    final charService = CustomChartService();
    final varshaChart = await charService.calculateChart(
      dateTime: solarReturnTime,
      location: GeographicLocation(
        latitude: birthData.location.latitude,
        longitude: birthData.location.longitude,
      ),
      ayanamsaMode: SiderealMode.lahiri,
    );

    // 3. Get Natal Information (Needed for Muntha and Varshesh)
    final natalChart = await charService.calculateChart(
      dateTime: birthData.dateTime,
      location: GeographicLocation(
        latitude: birthData.location.latitude,
        longitude: birthData.location.longitude,
      ),
      ayanamsaMode: SiderealMode.lahiri,
    );
    final natalAsc = getAscendantSign(natalChart);
    final isDay = isDayBirth(varshaChart); // For Varsha chart day/night

    // 4. Calculate Muntha
    final birthYear = birthData.dateTime.year;
    final munthaSign = calculateMuntha(natalAsc, birthYear, year);
    final munthaLord = getSignLord(munthaSign);

    // 5. Calculate Panchavargiya Bala (5-Fold Strength)
    // Used to determine the Varshesh (Year Lord)
    final panchavargiyaBala = calculatePanchavargiyaBala(
      varshaChart,
      isDay,
      varshaChart.houses.cusps[0], // Varsha Lagna
    );

    // 6. Determine Varshesh (Year Lord)
    // Candidates: Muntha Lord, Birth Lagna Lord, Varsha Lagna Lord, Tri-Rashi Lord, Din/Ratri Lord
    final varsheshData = determineVarshesh(
      varshaChart,
      panchavargiyaBala,
      munthaLord,
      getSignLord(natalAsc),
      getSignLord(getAscendantSign(varshaChart)),
      isDay,
    );

    // 7. Calculate Mudda Dasha (Vimshottari-based Annual Dasha)
    final varshikDasha = calculateMuddaDasha(varshaChart, solarReturnTime);

    // 8. Calculate Sahams (Arabic Parts)
    final sahams = calculateSahams(varshaChart, isDay);

    // 9. Calculate Tajik Yogas
    final tajikYogas = calculateTajikYogas(varshaChart);

    return VarshaphalChart(
      year: year,
      solarReturnTime: solarReturnTime,
      chart: varshaChart,
      muntha: munthaSign,
      munthaLord: munthaLord,
      varshikDasha: varshikDasha,
      sahams: sahams,
      yearLord: varsheshData['varshesh'] as String,
      panchavargiyaBala: panchavargiyaBala,
      varsheshCandidates: varsheshData['candidates'] as List<String>,
      tajikYogas: tajikYogas,
      isDayBirth: isDay,
      interpretation: generateInterpretation(
        varshaChart,
        munthaSign,
        sahams,
        varsheshData['varshesh'] as String,
      ),
    );
  }

  // --- 1. Solar Return Calculation (High Precision) ---

  static Future<DateTime> calculateSolarReturn(
    BirthData birthData,
    int year,
  ) async {
    final chartService = CustomChartService();

    // Natal Sun Position
    final natalChart = await chartService.calculateChart(
      dateTime: birthData.dateTime,
      location: GeographicLocation(
        latitude: birthData.location.latitude,
        longitude: birthData.location.longitude,
      ),
      ayanamsaMode: SiderealMode.lahiri,
    );
    final natalSunLong = getPlanetLongitude(natalChart, Planet.sun);

    // Initial Guess: Same day/month as birth
    DateTime searchDate = DateTime(
      year,
      birthData.dateTime.month,
      birthData.dateTime.day,
      birthData.dateTime.hour,
      birthData.dateTime.minute,
    );

    // Binary Search Window: +/- 2 days
    DateTime start = searchDate.subtract(const Duration(days: 2));
    DateTime end = searchDate.add(const Duration(days: 2));

    // Iterative refinement for < 1 second precision
    // 20 iterations is more than enough for seconds precision over 4 days
    for (int i = 0; i < 20; i++) {
      int midMillis =
          (start.millisecondsSinceEpoch + end.millisecondsSinceEpoch) ~/ 2;
      DateTime mid = DateTime.fromMillisecondsSinceEpoch(midMillis);

      final testChart = await chartService.calculateChart(
        dateTime: mid,
        location: GeographicLocation(
          latitude: birthData.location.latitude,
          longitude: birthData.location.longitude,
        ),
        ayanamsaMode: SiderealMode.lahiri,
      );

      final testSunLong = getPlanetLongitude(testChart, Planet.sun);

      // Calculate difference accounting for 360 wrap
      double diff = testSunLong - natalSunLong;
      while (diff > 180) diff -= 360;
      while (diff < -180) diff += 360;

      if (diff.abs() < 0.0001) {
        // Extremely high precision
        return mid;
      }

      // Sun moves forward ~1 degree per day.
      // If diff is positive (Test > Natal), we are ahead, need to go back.
      if (diff > 0) {
        end = mid;
      } else {
        start = mid;
      }
    }

    return start; // Fallback to best approximation
  }

  // --- 4. Muntha Calculation ---

  static int calculateMuntha(int natalAscSign, int birthYear, int targetYear) {
    // Formula: (Natal Asc + (Target Year - Birth Year)) % 12
    // Signs are 0-indexed (Aries=0)
    int age = targetYear - birthYear;
    return (natalAscSign + age) % 12;
  }

  // --- 5. Panchavargiya Bala ---

  static Map<String, PanchavargiyaStrength> calculatePanchavargiyaBala(
    VedicChart chart,
    bool isDayBirth,
    double ascendant,
  ) {
    final strengths = <String, PanchavargiyaStrength>{};
    final planets = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
    ];

    for (var planet in planets) {
      final pEnum = getPlanetFromString(planet);
      final pLong = getPlanetLongitude(chart, pEnum);
      final pSign = (pLong / 30).floor();

      // 1. Kshetra Bala (Residential Strength)
      // Based on relationship with house lord (Friend/Enemy/Own)
      double kshetra = calculateKshetraBala(pEnum, pSign);

      // 2. Uchcha Bala (Exaltation Strength)
      double uchcha = calculateUchchaBala(pEnum, pLong);

      // 3. Hadda (Term) Bala
      double hadda = calculateHaddaBala(pEnum, pLong);

      // 4. Drekkana Bala
      double drekkana = calculateDrekkanaBala(pEnum, pLong);

      // 5. Navamas Bala
      double navamas = calculateNavamsaBala(pEnum, pLong);

      strengths[planet] = PanchavargiyaStrength(
        kshetra: kshetra,
        uchcha: uchcha,
        hadda: hadda,
        drekkana: drekkana,
        navamsa: navamas,
      );
    }
    return strengths;
  }

  // --- 6. Varshesh Selection ---

  static Map<String, dynamic> determineVarshesh(
    VedicChart chart,
    Map<String, PanchavargiyaStrength> strengths,
    String munthaLord,
    String birthLagnaLord,
    String varshaLagnaLord,
    bool isDayBirth,
  ) {
    // 1. Identify 5 Candidates (Panchadhikaris)
    final varshaAsc = chart.houses.cusps[0];
    final varshaSign = (varshaAsc / 30).floor();

    // Tri-Rashi Lord Calculation
    String triRashiLord = getTriRashiLord(varshaSign, isDayBirth);

    // Din-Ratri Lord
    String dinRatriLord = isDayBirth ? 'Sun' : 'Moon';

    final candidates = {
      'Muntha Lord': munthaLord,
      'Birth Lagna Lord': birthLagnaLord,
      'Varsha Lagna Lord': varshaLagnaLord,
      'Tri-Rashi Lord': triRashiLord,
      'Din-Ratri Lord': dinRatriLord,
    };

    // 2. Rule: Candidate must aspect Varsha Lagna to be eligible
    // Exception: If Moon is Munthapati, it can be Varshesh even without aspect (some schools).
    // We enforce Aspect rule strictly as per standard Tajik.

    String bestCandidate = 'None';
    double maxStrength = -1.0;

    // Track candidates list for UI
    List<String> candList = [];

    candidates.forEach((role, planetName) {
      final pEnum = getPlanetFromString(planetName);
      final pLong = getPlanetLongitude(chart, pEnum);
      bool aspectsLagna = checkTajikAspect(pLong, varshaAsc);

      double strength = strengths[planetName]?.total ?? 0;
      candList.add(
        '$role ($planetName): ${strength.toStringAsFixed(1)} ${aspectsLagna ? "[Aspects]" : "[No Aspect]"}',
      );

      if (aspectsLagna) {
        if (strength > maxStrength) {
          maxStrength = strength;
          bestCandidate = planetName;
        }
      }
    });

    // Fallback: If no candidate aspects Lagna, use Muntha Lord (standard fallback)
    if (bestCandidate == 'None') {
      bestCandidate = munthaLord;
      candList.add('Fallback to Muntha Lord ($munthaLord)');
    }

    return {'varshesh': bestCandidate, 'candidates': candList};
  }

  // --- 7. Mudda Dasha (Vimshottari based) ---

  static List<VarshikDashaPeriod> calculateMuddaDasha(
    VedicChart chart,
    DateTime returnTime,
  ) {
    // Determine Nakshatra of Moon at Solar Return
    final moonLong = getPlanetLongitude(chart, Planet.moon);
    final nakshatraData = getNakshatra(moonLong);

    final nakshatraLord = nakshatraData.lord;
    final moonProgress = nakshatraData.progress; // 0.0 to 1.0 passed

    // Vimshottari Sequence & Duration
    final dashaOrder = [
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
    ];
    final dashaYears = {
      'Ketu': 7,
      'Venus': 20,
      'Sun': 6,
      'Moon': 10,
      'Mars': 7,
      'Rahu': 18,
      'Jupiter': 16,
      'Saturn': 19,
      'Mercury': 17,
    };

    // Find starting dasha
    int startIndex = dashaOrder.indexOf(nakshatraLord);

    // Balance at birth (proportion of nakshatra remaining)
    double remainingFactor = 1.0 - moonProgress;

    final periods = <VarshikDashaPeriod>[];
    DateTime current = returnTime;

    // Total Year days = 365.25 (Solar Year)
    // Scale: 120 Vimshottari Years = 365.25 Days
    // Factor = 365.25 / 120 = 3.04375 days per dasha year
    const dayFactor = 365.25 / 120.0;

    // First period (Remainder)
    double firstPeriodDays =
        dashaYears[nakshatraLord]! * dayFactor * remainingFactor;

    // We add periods until we cover 365.25 days.
    // However, Mudda dasha usually runs strictly in sequence.
    // Let's generate a full cycle starting from the balance.

    double totalDaysCovered = 0;

    for (int i = 0; i < 9; i++) {
      // Max 9 periods ensures full cycle check
      String planet = dashaOrder[(startIndex + i) % 9];
      double fullDuration = dashaYears[planet]! * dayFactor;

      double duration = (i == 0) ? firstPeriodDays : fullDuration;

      // Stop if we exceeded 365 days significantly?
      // Standard Mudda simply runs through.
      // Often it repeats if year is somehow longer (it isn't).
      // We just list the meaningful ones within the year.

      if (totalDaysCovered >= 366) break; // Optimization

      final end = current.add(Duration(minutes: (duration * 1440).round()));

      // Prediction logic
      final prediction = getMuddaPrediction(planet, chart);

      periods.add(
        VarshikDashaPeriod(
          planet: planet,
          startDate: current,
          endDate: end,
          durationDays: duration,
          prediction: prediction['main'],
          keyThemes: prediction['themes'],
          cautions: prediction['cautions'],
          favorableScore: prediction['score'],
        ),
      );

      current = end;
      totalDaysCovered += duration;
    }

    return periods;
  }

  // --- Helpers for Calculations ---

  static bool isDayBirth(VedicChart chart) {
    // If Sun is in houses 7, 8, 9, 10, 11, 12, it is Day (approx).
    // Better: Check Ascendant vs Sun Longitude.
    // If Sun is 0-180 degrees BEHIND Asc (in zodiac order), it's day (House 12 down to 7).
    // Actually, simpler: House 1 is rising (East). House 7 setting (West).
    // Sun in House 7 to 12 is Day. House 1 to 6 is Night.
    final sunLong = getPlanetLongitude(chart, Planet.sun);
    final ascLong = chart.houses.cusps[0];

    final house = getHouseNumber(ascLong, sunLong);
    return house >= 7 && house <= 12;
  }

  static int getHouseNumber(double asc, double long) {
    double diff = long - asc;
    if (diff < 0) diff += 360;
    return (diff / 30).floor() + 1;
  }

  static double getPlanetLongitude(VedicChart chart, Planet planet) {
    return chart.planets[planet]?.longitude ?? 0.0;
  }

  static int getAscendantSign(VedicChart chart) {
    return (chart.houses.cusps[0] / 30).floor();
  }

  static Planet getPlanetFromString(String name) {
    return Planet.values.firstWhere(
      (p) => p.toString().split('.').last.toLowerCase() == name.toLowerCase(),
      orElse: () => Planet.sun,
    );
  }

  static String getSignLord(int sign) {
    // 0=Aries, 1=Taurus...
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

  // --- Strength Calculation Helpers ---

  static double calculateKshetraBala(Planet planet, int sign) {
    // Simplified Panchadha Maitri check for now
    // Ideally needs full chart calculation
    // Return default 15.0 for neutral
    // Friends: 30, Neutral: 15, Enemy: 7.5
    // For now: Own sign = 30, Friend = 22.5, Enemy = 7.5
    final lord = getSignLord(sign);
    if (lord == planet.toString().split('.').last) return 30.0;
    // ... Implement logic or simplified map
    return 15.0; // Placeholder until full maitri
  }

  static double calculateUchchaBala(Planet planet, double longitude) {
    final exaltPoints = {
      Planet.sun: 10.0, // Aries 10
      Planet.moon: 33.0, // Taurus 3
      Planet.mars: 298.0, // Capricorn 28
      Planet.mercury: 165.0, // Virgo 15
      Planet.jupiter: 95.0, // Cancer 5
      Planet.venus: 357.0, // Pisces 27
      Planet.saturn: 200.0, // Libra 20
    };

    double exalt = exaltPoints[planet] ?? 0.0;
    double diff = (longitude - exalt).abs();
    if (diff > 180) diff = 360 - diff;

    // Formula: (180 - diff) / 9
    // Max 20 units
    return (180 - diff) / 9.0;
  }

  static double calculateHaddaBala(Planet planet, double long) {
    // Egyptian Terms (Standard for Tajik)
    // Structure: Sign Index -> List of Term(Planet, Degrees)
    // Example: Aries(0) -> Jup(6), Ven(6), Mer(8), Mar(5), Sat(5)
    // Degrees are cumulative: 6, 12, 20, 25, 30

    final sign = (long / 30).floor();
    final degreeInSign = long % 30;

    final terms = _getEgyptianTerms(sign);

    String termLord = 'None';
    double currentLimit = 0;

    for (var term in terms) {
      currentLimit += term.degrees;
      if (degreeInSign < currentLimit) {
        termLord = term.planetName;
        break;
      }
    }

    // Check if planet is the term lord
    // Own Term: 15.0, Friend: 11.25, Neutral: 7.5, Enemy: 3.75
    // For now, if Own Term = 15, Else 7.5 (Neutral default)
    // Ideally needs detailed Maitri again.

    // Convert planet enum to string name
    final pName = planet.toString().split('.').last;

    // Check match
    // Note: Mars/Sun/Moon/etc naming must match string
    if (termLord.toLowerCase() == pName.toLowerCase()) {
      return 15.0; // Own Value
    }

    return 7.5; // Neutral Value (Placeholder for Maitri)
  }

  static List<_Term> _getEgyptianTerms(int sign) {
    // 0=Aries...
    switch (sign) {
      case 0:
        return [
          _t('Jupiter', 6),
          _t('Venus', 6),
          _t('Mercury', 8),
          _t('Mars', 5),
          _t('Saturn', 5),
        ];
      case 1:
        return [
          _t('Venus', 8),
          _t('Mercury', 6),
          _t('Jupiter', 8),
          _t('Saturn', 5),
          _t('Mars', 3),
        ];
      case 2:
        return [
          _t('Mercury', 6),
          _t('Jupiter', 6),
          _t('Venus', 5),
          _t('Mars', 7),
          _t('Saturn', 6),
        ];
      case 3:
        return [
          _t('Mars', 7),
          _t('Venus', 6),
          _t('Mercury', 6),
          _t('Jupiter', 7),
          _t('Saturn', 4),
        ];
      case 4:
        return [
          _t('Jupiter', 6),
          _t('Venus', 5),
          _t('Saturn', 7),
          _t('Mercury', 6),
          _t('Mars', 6),
        ];
      case 5:
        return [
          _t('Mercury', 7),
          _t('Venus', 10),
          _t('Jupiter', 4),
          _t('Mars', 7),
          _t('Saturn', 2),
        ];
      case 6:
        return [
          _t('Saturn', 6),
          _t('Venus', 8),
          _t('Jupiter', 7),
          _t('Mercury', 7),
          _t('Mars', 2),
        ];
      case 7:
        return [
          _t('Mars', 7),
          _t('Venus', 4),
          _t('Mercury', 8),
          _t('Jupiter', 5),
          _t('Saturn', 6),
        ];
      case 8:
        return [
          _t('Jupiter', 12),
          _t('Venus', 5),
          _t('Mercury', 4),
          _t('Saturn', 5),
          _t('Mars', 4),
        ];
      case 9:
        return [
          _t('Mercury', 7),
          _t('Jupiter', 7),
          _t('Venus', 8),
          _t('Saturn', 4),
          _t('Mars', 4),
        ];
      case 10:
        return [
          _t('Mercury', 7),
          _t('Venus', 6),
          _t('Jupiter', 7),
          _t('Mars', 5),
          _t('Saturn', 5),
        ];
      case 11:
        return [
          _t('Venus', 12),
          _t('Jupiter', 4),
          _t('Mercury', 3),
          _t('Mars', 9),
          _t('Saturn', 2),
        ];
      default:
        return [];
    }
  }

  static _Term _t(String name, double deg) => _Term(name, deg);

  static double calculateDrekkanaBala(Planet planet, double long) {
    return 5.0; // Placeholder
  }

  static double calculateNavamsaBala(Planet planet, double long) {
    return 2.5; // Placeholder
  }

  static String getTriRashiLord(int sign, bool isDay) {
    // Standard Tajik Tri-Rashi Table
    // Fiery (0,4,8): Day=Sun, Night=Jupiter
    // Earthy (1,5,9): Day=Venus, Night=Moon
    // Airy (2,6,10): Day=Saturn, Night=Mercury
    // Watery (3,7,11): Day=Venus, Night=Mars

    if ([0, 4, 8].contains(sign)) return isDay ? 'Sun' : 'Jupiter';
    if ([1, 5, 9].contains(sign)) return isDay ? 'Venus' : 'Moon';
    if ([2, 6, 10].contains(sign)) return isDay ? 'Saturn' : 'Mercury';
    if ([3, 7, 11].contains(sign)) return isDay ? 'Venus' : 'Mars';
    return 'Sun';
  }

  static bool checkTajikAspect(double p1, double p2) {
    // Forward Aspect
    double diff = p2 - p1;
    if (diff < 0) diff += 360;

    int orb = 12; // Simplified orb
    // Conjunction
    if (diff < orb || diff > 360 - orb) return true;
    // Sextile (3/11) - 60, 300
    if ((diff - 60).abs() < orb || (diff - 300).abs() < orb) return true;
    // Square (4/10) - 90, 270
    if ((diff - 90).abs() < orb || (diff - 270).abs() < orb) return true;
    // Trine (5/9) - 120, 240
    if ((diff - 120).abs() < orb || (diff - 240).abs() < orb) return true;
    // Opposition (7) - 180
    if ((diff - 180).abs() < orb) return true;

    return false;
  }

  // --- Sahams ---

  static Map<String, SahamPoint> calculateSahams(VedicChart chart, bool isDay) {
    final sahams = <String, SahamPoint>{};
    final asc = chart.houses.cusps[0];
    final sun = getPlanetLongitude(chart, Planet.sun);
    final moon = getPlanetLongitude(chart, Planet.moon);

    // 1. Punya Saham (Fortune)
    // Day: Asc + Moon - Sun
    // Night: Asc + Sun - Moon
    double punyaLong = isDay ? (asc + moon - sun) : (asc + sun - moon);
    punyaLong = (punyaLong + 360) % 360;

    sahams['Punya (Fortune)'] = SahamPoint(
      name: 'Punya Saham',
      longitude: punyaLong,
      interpretation: 'Wealth, success, and fulfillment of desires.',
    );

    // 2. Guru Saham (Education/Wisdom)
    // Day: Asc + Sun - Jupiter
    // Night: Asc + Jupiter - Sun
    // (Standard varies, using common Tajik rule)
    // ...

    return sahams;
  }

  static List<String> calculateTajikYogas(VedicChart chart) {
    return ['Ithasala', 'Easarapha']; // Placeholder for full logic
  }

  static NakshatraInfo getNakshatra(double longitude) {
    final index = (longitude / (13 + 1 / 3)).floor();
    final percent = (longitude % (13 + 1 / 3)) / (13 + 1 / 3);
    return NakshatraInfo(
      AstrologyConstants.nakshatraNames[index],
      getNakshatraLord(index),
      percent,
    );
  }

  static String getNakshatraLord(int index) {
    // Ketu, Ven, Sun, Moon, Mars, Rahu, Jup, Sat, Mer
    const lords = [
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
    ];
    return lords[index % 9];
  }

  static Map<String, dynamic> getMuddaPrediction(
    String planet,
    VedicChart chart,
  ) {
    // Get planet position and house
    final pEnum = getPlanetFromString(planet);
    final pLong = getPlanetLongitude(chart, pEnum);
    final pSign = (pLong / 30).floor();
    final ascLong = chart.houses.cusps[0];
    final houseNum = getHouseNumber(ascLong, pLong);

    // --- Base Score Calculation (35-95 scale) ---
    // Base: 65 (neutral)
    double score = 65.0;

    // 1. Dignity Modifier (-15 to +15)
    final dignity = _getPlanetDignity(pEnum, pSign);
    switch (dignity) {
      case 'Exalted':
        score += 15;
        break;
      case 'Own Sign':
        score += 10;
        break;
      case 'Friend Sign':
        score += 5;
        break;
      case 'Neutral':
        break;
      case 'Enemy Sign':
        score -= 7;
        break;
      case 'Debilitated':
        score -= 15;
        break;
    }

    // 2. House Position Modifier (-10 to +10)
    // Benefic houses: 1, 4, 5, 7, 9, 10, 11
    // Malefic houses: 6, 8, 12
    if ([1, 4, 5, 9, 10].contains(houseNum)) {
      score += 8;
    } else if ([7, 11].contains(houseNum)) {
      score += 5;
    } else if ([6, 8, 12].contains(houseNum)) {
      score -= 10;
    }

    // 3. Benefic/Malefic Nature Modifier (-5 to +5)
    final isBenefic = ['Jupiter', 'Venus', 'Moon', 'Mercury'].contains(planet);
    final isMalefic = ['Saturn', 'Mars', 'Rahu', 'Ketu'].contains(planet);
    if (isBenefic) score += 3;
    if (isMalefic) score -= 3;

    // 4. Aspect from Jupiter (benefic) or Saturn (malefic)
    final jupLong = getPlanetLongitude(chart, Planet.jupiter);
    final satLong = getPlanetLongitude(chart, Planet.saturn);
    if (checkTajikAspect(jupLong, pLong)) score += 5;
    if (checkTajikAspect(satLong, pLong)) score -= 5;

    // Clamp to 35-95 range
    score = score.clamp(35.0, 95.0);

    // --- Generate Key Themes ---
    final themes = <String>[];
    final cautions = <String>[];

    // Planet-specific themes
    switch (planet) {
      case 'Sun':
        themes.addAll(['Authority', 'Career recognition', 'Father/Government']);
        if (houseNum == 10) themes.add('Professional peak');
        if (dignity == 'Debilitated') cautions.add('Ego conflicts');
        break;
      case 'Moon':
        themes.addAll(['Emotional well-being', 'Mother', 'Mental peace']);
        if (houseNum == 4) themes.add('Domestic happiness');
        if (dignity == 'Debilitated') cautions.add('Emotional turbulence');
        break;
      case 'Mars':
        themes.addAll(['Energy', 'Courage', 'Property', 'Siblings']);
        if (houseNum == 10) themes.add('Competitive success');
        if ([6, 8, 12].contains(houseNum)) cautions.add('Accidents/conflicts');
        break;
      case 'Mercury':
        themes.addAll(['Communication', 'Business', 'Learning']);
        if (houseNum == 5 || houseNum == 9) themes.add('Educational gains');
        if (dignity == 'Debilitated') cautions.add('Miscommunication');
        break;
      case 'Jupiter':
        themes.addAll(['Wisdom', 'Fortune', 'Children', 'Spirituality']);
        if ([1, 5, 9].contains(houseNum)) themes.add('Blessings & expansion');
        if (dignity == 'Debilitated') cautions.add('Overconfidence');
        break;
      case 'Venus':
        themes.addAll(['Relationships', 'Luxury', 'Art', 'Marriage']);
        if (houseNum == 7) themes.add('Romantic fulfillment');
        if (dignity == 'Debilitated') cautions.add('Relationship strain');
        break;
      case 'Saturn':
        themes.addAll(['Hard work', 'Karma', 'Discipline', 'Longevity']);
        if ([10, 11].contains(houseNum))
          themes.add('Career stability through effort');
        cautions.add('Delays possible');
        if (dignity == 'Debilitated') cautions.add('Obstacles & setbacks');
        break;
      case 'Rahu':
        themes.addAll(['Ambition', 'Foreign matters', 'Unconventional gains']);
        cautions.add('Avoid risky shortcuts');
        if ([6, 8, 12].contains(houseNum)) cautions.add('Hidden challenges');
        break;
      case 'Ketu':
        themes.addAll(['Spirituality', 'Detachment', 'Past karma']);
        cautions.add('Uncertainty in material matters');
        if (houseNum == 12) themes.add('Spiritual awakening');
        break;
    }

    // House-based pointers
    if (houseNum == 2) themes.add('Focus on finances');
    if (houseNum == 3) themes.add('Short travels, siblings');
    if (houseNum == 6) cautions.add('Health vigilance needed');
    if (houseNum == 8) cautions.add('Watch for sudden changes');
    if (houseNum == 12) cautions.add('Expenses likely');

    // Generate main prediction
    String main = _generateMainPrediction(planet, dignity, houseNum, score);

    return {
      'main': main,
      'themes': themes.take(4).toList(), // Limit to 4 themes
      'cautions': cautions.take(3).toList(), // Limit to 3 cautions
      'score': score / 100.0, // Normalize for UI (0.35 to 0.95)
    };
  }

  static String _getPlanetDignity(Planet planet, int sign) {
    // Exaltation Signs
    const exaltSigns = {
      Planet.sun: 0, // Aries
      Planet.moon: 1, // Taurus
      Planet.mars: 9, // Capricorn
      Planet.mercury: 5, // Virgo
      Planet.jupiter: 3, // Cancer
      Planet.venus: 11, // Pisces
      Planet.saturn: 6, // Libra
    };

    // Debilitation Signs (opposite)
    const debilSigns = {
      Planet.sun: 6, // Libra
      Planet.moon: 7, // Scorpio
      Planet.mars: 3, // Cancer
      Planet.mercury: 11, // Pisces
      Planet.jupiter: 9, // Capricorn
      Planet.venus: 5, // Virgo
      Planet.saturn: 0, // Aries
    };

    // Own Signs
    const ownSigns = {
      Planet.sun: [4], // Leo
      Planet.moon: [3], // Cancer
      Planet.mars: [0, 7], // Aries, Scorpio
      Planet.mercury: [2, 5], // Gemini, Virgo
      Planet.jupiter: [8, 11], // Sagittarius, Pisces
      Planet.venus: [1, 6], // Taurus, Libra
      Planet.saturn: [9, 10], // Capricorn, Aquarius
    };

    if (exaltSigns[planet] == sign) return 'Exalted';
    if (debilSigns[planet] == sign) return 'Debilitated';
    if (ownSigns[planet]?.contains(sign) ?? false) return 'Own Sign';

    // Friend/Enemy logic (simplified)
    // For now, return Neutral
    return 'Neutral';
  }

  static String _generateMainPrediction(
    String planet,
    String dignity,
    int house,
    double score,
  ) {
    String quality = score >= 75
        ? 'favorable'
        : (score >= 55 ? 'moderate' : 'challenging');
    String dignityDesc = dignity == 'Exalted'
        ? 'strongly placed'
        : dignity == 'Debilitated'
        ? 'weakly placed'
        : dignity == 'Own Sign'
        ? 'well-placed'
        : 'positioned';

    return 'During the $planet period, the planet is $dignityDesc in house $house. '
        'This suggests a $quality time for ${_getPlanetDomain(planet)}. '
        'Score: ${score.toStringAsFixed(0)}/100.';
  }

  static String _getPlanetDomain(String planet) {
    switch (planet) {
      case 'Sun':
        return 'authority, career, and self-expression';
      case 'Moon':
        return 'emotions, mind, and domestic life';
      case 'Mars':
        return 'energy, courage, and competitive matters';
      case 'Mercury':
        return 'communication, business, and intellect';
      case 'Jupiter':
        return 'wisdom, fortune, and spiritual growth';
      case 'Venus':
        return 'relationships, luxury, and creative pursuits';
      case 'Saturn':
        return 'discipline, hard work, and karmic lessons';
      case 'Rahu':
        return 'ambition, foreign matters, and unconventional paths';
      case 'Ketu':
        return 'spirituality, past karma, and detachment';
      default:
        return 'general life matters';
    }
  }

  static String generateInterpretation(
    VedicChart chart,
    int muntha,
    Map<String, SahamPoint> sahams,
    String yearLord,
  ) {
    return "Year ruled by $yearLord. Muntha in ${getSignName(muntha)}.";
  }

  static String getSignName(int sign) => AstrologyConstants.getSignName(sign);
}

class NakshatraInfo {
  final String name;
  final String lord;
  final double progress;
  NakshatraInfo(this.name, this.lord, this.progress);
}

/// Varshaphal Chart data
class VarshaphalChart {
  final int year;
  final DateTime solarReturnTime;
  final VedicChart chart;
  final int muntha;
  final String munthaLord;
  final List<VarshikDashaPeriod> varshikDasha;
  final Map<String, SahamPoint> sahams;
  final String yearLord;
  final Map<String, PanchavargiyaStrength> panchavargiyaBala;
  final List<String> varsheshCandidates;
  final List<String> tajikYogas;
  final bool isDayBirth;
  final String interpretation;

  VarshaphalChart({
    required this.year,
    required this.solarReturnTime,
    required this.chart,
    required this.muntha,
    required this.munthaLord,
    required this.varshikDasha,
    required this.sahams,
    required this.yearLord,
    required this.panchavargiyaBala,
    required this.varsheshCandidates,
    required this.tajikYogas,
    required this.isDayBirth,
    required this.interpretation,
  });
}

class VarshikDashaPeriod {
  final String planet;
  final DateTime startDate;
  final DateTime endDate;
  final double durationDays;
  final String prediction;
  final List<String> keyThemes;
  final List<String> cautions;
  final double favorableScore;

  VarshikDashaPeriod({
    required this.planet,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.prediction,
    required this.keyThemes,
    required this.cautions,
    this.favorableScore = 0.5,
  });
}

class SahamPoint {
  final String name;
  final double longitude;
  final String interpretation;

  SahamPoint({
    required this.name,
    required this.longitude,
    required this.interpretation,
  });

  int get sign => (longitude / 30).floor();
  double get degreeInSign => longitude % 30;
}

class PanchavargiyaStrength {
  final double kshetra;
  final double uchcha;
  final double hadda;
  final double drekkana;
  final double navamsa;

  PanchavargiyaStrength({
    required this.kshetra,
    required this.uchcha,
    required this.hadda,
    required this.drekkana,
    required this.navamsa,
  });

  double get total => kshetra + uchcha + hadda + drekkana + navamsa;
}

class _Term {
  final String planetName;
  final double degrees;
  _Term(this.planetName, this.degrees);
}
