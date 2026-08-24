import 'package:jyotish/jyotish.dart';

import '../core/chart_customization.dart';
import '../core/ephemeris_manager.dart';
import '../data/models.dart';
import 'custom_chart_service.dart';

/// Varshaphal (Annual Chart) System
/// Calculates solar return charts and Tajik/Varshik predictions
/// Implements rigorous Tajik Shastra rules including Panchavargiya Bala and Varshesh.
class VarshaphalSystem {
  /// Calculate Varshaphal chart for a given year
  static Future<VarshaphalChart> calculateVarshaphal(
    BirthData birthData,
    int year, {
    ChartCustomization? chartCustomization,
  }) async {
    final chartSettings = chartCustomization ?? ChartCustomization();

    await EphemerisManager.ensureEphemerisData();
    final varshapalService = EphemerisManager.jyotish.systems.varshapal;
    final tajakaService = EphemerisManager.jyotish.systems.tajaka;

    final location = GeographicLocation(
      latitude: birthData.location.latitude,
      longitude: birthData.location.longitude,
      timezone: birthData.timezone.isNotEmpty ? birthData.timezone : null,
    );

    final activeFlags = CalculationFlags(
      siderealMode: SiderealMode.lahiri,
      nodeType: chartSettings.useTrueNode
          ? NodeType.trueNode
          : NodeType.meanNode,
      useTopocentric: chartSettings.useTopocentric,
      calculateSpeed: chartSettings.calculateSpeed,
    );

    // 1. Calculate rigorous Solar Return Time (High Precision)
    final solarReturnTime = await varshapalService.calculateSolarReturn(
      birthDateTime: birthData.dateTime,
      targetYear: year,
      location: location,
      flags: activeFlags,
    );

    // 2. Calculate Chart for Solar Return Moment (Varsha Lagna)
    final charService = CustomChartService();
    final varshaChart = await charService.calculateChart(
      dateTime: solarReturnTime,
      location: location,
      ayanamsaMode: SiderealMode.lahiri,
      useTrueNode: chartSettings.useTrueNode,
      useTopocentric: chartSettings.useTopocentric,
      calculateSpeed: chartSettings.calculateSpeed,
    );

    // 3. Get Natal Information (Needed for Muntha and Varshesh)
    final natalChart = await charService.calculateChart(
      dateTime: birthData.dateTime,
      location: location,
      ayanamsaMode: SiderealMode.lahiri,
      useTrueNode: chartSettings.useTrueNode,
      useTopocentric: chartSettings.useTopocentric,
      calculateSpeed: chartSettings.calculateSpeed,
    );

    // 4. Calculate Muntha and Tajaka enhancements
    final age = calculateExactAge(birthData.dateTime, solarReturnTime);
    final tajakaEnhancement = tajakaService.calculateTajakaEnhancements(
      natalChart: natalChart,
      annualChart: varshaChart,
      age: age,
    );

    final munthaSign = tajakaEnhancement.munthaSign.number;
    final munthaLord = tajakaEnhancement.munthaLord.displayName;

    // 5. Calculate Panchavargiya Bala (5-Fold Strength)
    final panchavargiyaBala = <String, PanchavargiyaStrength>{};
    final balaMap = <Planet, PanchavargiyaBalaResult>{};
    for (final planet in Planet.traditionalPlanets) {
      final res = varshapalService.calculatePanchavargiyaBala(
        planet,
        varshaChart,
      );
      balaMap[planet] = res;
      panchavargiyaBala[planet.displayName] = PanchavargiyaStrength(
        kshetra: res.kshetraBala,
        uchcha: res.ucchaBala,
        hadda: res.haddaBala,
        drekkana: res.drekkanaBala,
        navamsa: res.navamsaBala,
      );
    }

    // 6. Determine Varshesh (Year Lord)
    final varsheshPlanet = varshapalService.determineVarshesh(
      natalChart: natalChart,
      annualChart: varshaChart,
      balaMap: balaMap,
      varshaDateTime: solarReturnTime,
      birthDateTime: birthData.dateTime,
    );
    final yearLord = varsheshPlanet.displayName;

    // Format candidate list for UI
    final natalAsc = getAscendantSign(natalChart);
    final birthLagnaLord = getSignLord(natalAsc);
    final varshaLagnaLord = getSignLord(getAscendantSign(varshaChart));
    final sunHouse = varshaChart.getPlanet(Planet.sun)?.house ?? 1;
    final isDay = sunHouse >= 7 && sunHouse <= 12;
    final dinRatriLord = isDay ? 'Sun' : 'Moon';
    final triRashiLord = varshapalService
        .getTrirashiLord(Rashi.fromLongitude(varshaChart.ascendant), isDay)
        .displayName;

    final candidatesMap = <String, String>{
      'Muntha Lord': munthaLord,
      'Birth Lagna Lord': birthLagnaLord,
      'Varsha Lagna Lord': varshaLagnaLord,
      'Tri-Rashi Lord': triRashiLord,
      'Din-Ratri Lord': dinRatriLord,
    };

    final varsheshCandidates = <String>[];
    candidatesMap.forEach((role, planetName) {
      final pEnum = getPlanetFromString(planetName);
      final h = varshaChart.getPlanet(pEnum)?.house;
      final aspectsLagna = h != null && [1, 3, 4, 5, 7, 9, 10, 11].contains(h);
      final strength = panchavargiyaBala[planetName]?.total ?? 0;
      varsheshCandidates.add(
        '$role ($planetName): ${strength.toStringAsFixed(1)} ${aspectsLagna ? "[Aspects]" : "[No Aspect]"}',
      );
    });

    // 7. Calculate Mudda Dasha (Vimshottari-based Annual Dasha)
    final muddaPeriods = await varshapalService.calculateMuddaDasha(
      birthDateTime: birthData.dateTime,
      varshaDateTime: solarReturnTime,
      annualChart: varshaChart,
      location: location,
      flags: activeFlags,
    );

    final varshikDasha = <VarshikDashaPeriod>[];
    for (final period in muddaPeriods) {
      final planetName = period.lord.displayName;
      final duration = period.duration.inMinutes / 1440.0;
      final prediction = getMuddaPrediction(planetName, varshaChart);
      varshikDasha.add(
        VarshikDashaPeriod(
          planet: planetName,
          startDate: period.startDate,
          endDate: period.endDate,
          durationDays: duration,
          prediction: prediction['main'],
          keyThemes: prediction['themes'],
          cautions: prediction['cautions'],
          favorableScore: prediction['score'],
        ),
      );
    }

    // 8. Calculate Sahams (Arabic Parts)
    final sahams = <String, SahamPoint>{};
    tajakaEnhancement.sahams.forEach((key, long) {
      var name = '$key Saham';
      var interpretation = '';
      var fullKey = key;
      if (key == 'Punya') {
        fullKey = 'Punya (Fortune)';
        interpretation = 'Wealth, success, and fulfillment of desires.';
      } else if (key == 'Vidya') {
        fullKey = 'Vidya (Education)';
        interpretation = 'Education, learning, and intellectual pursuits.';
      } else if (key == 'Yasas') {
        fullKey = 'Yasha (Fame)';
        name = 'Yasha Saham';
        interpretation = 'Fame, reputation, and public recognition.';
      } else if (key == 'Karma') {
        fullKey = 'Karma (Career)';
        interpretation = 'Career, profession, and life purpose.';
      } else if (key == 'Putra') {
        fullKey = 'Putra (Children)';
        interpretation = 'Children, creativity, and progeny matters.';
      } else if (key == 'Vivaha') {
        fullKey = 'Vivaha (Marriage)';
        interpretation = 'Marriage and partnership matters.';
      } else {
        interpretation = 'Significance of $key in annual chart.';
      }
      sahams[fullKey] = SahamPoint(
        name: name,
        longitude: long,
        interpretation: interpretation,
      );
    });

    if (!sahams.containsKey('Raja (Authority)')) {
      final saturn = getPlanetLongitude(varshaChart, Planet.saturn);
      final sun = getPlanetLongitude(varshaChart, Planet.sun);
      final asc = varshaChart.houses.cusps[0];
      var rajaLong = isDay ? (asc + saturn - sun) : (asc + sun - saturn);
      rajaLong = (rajaLong + 360) % 360;
      sahams['Raja (Authority)'] = SahamPoint(
        name: 'Raja Saham',
        longitude: rajaLong,
        interpretation: 'Authority, government favor, and power.',
      );
    }
    if (!sahams.containsKey('Mitra (Friends)')) {
      final mercury = getPlanetLongitude(varshaChart, Planet.mercury);
      final moon = getPlanetLongitude(varshaChart, Planet.moon);
      final asc = varshaChart.houses.cusps[0];
      var mitraLong = isDay ? (asc + mercury - moon) : (asc + moon - mercury);
      mitraLong = (mitraLong + 360) % 360;
      sahams['Mitra (Friends)'] = SahamPoint(
        name: 'Mitra Saham',
        longitude: mitraLong,
        interpretation: 'Friendships, alliances, and social connections.',
      );
    }

    // 9. Tajik Yogas
    final tajikYogas = tajakaEnhancement.yogas
        .map((y) => y.interpretation)
        .toList();
    if (tajikYogas.isEmpty) {
      tajikYogas.add('No major Tajik Yogas active');
    }

    return VarshaphalChart(
      year: year,
      solarReturnTime: solarReturnTime,
      chart: varshaChart,
      muntha: munthaSign,
      munthaLord: munthaLord,
      varshikDasha: varshikDasha,
      sahams: sahams,
      yearLord: yearLord,
      panchavargiyaBala: panchavargiyaBala,
      varsheshCandidates: varsheshCandidates,
      tajikYogas: tajikYogas,
      isDayBirth: isDay,
      interpretation: generateInterpretation(
        varshaChart,
        munthaSign,
        sahams,
        yearLord,
      ),
    );
  }

  // --- 1. Solar Return Calculation (High Precision) ---

  static Future<DateTime> calculateSolarReturn(
    BirthData birthData,
    int year,
  ) async {
    await EphemerisManager.ensureEphemerisData();
    final varshapalService = EphemerisManager.jyotish.systems.varshapal;
    final location = GeographicLocation(
      latitude: birthData.location.latitude,
      longitude: birthData.location.longitude,
      timezone: birthData.timezone.isNotEmpty ? birthData.timezone : null,
    );
    const activeFlags = CalculationFlags(
      siderealMode: SiderealMode.lahiri,
      nodeType: NodeType.meanNode,
    );
    return varshapalService.calculateSolarReturn(
      birthDateTime: birthData.dateTime,
      targetYear: year,
      location: location,
      flags: activeFlags,
    );
  }

  static int calculateExactAge(
    DateTime birthDateTime,
    DateTime targetDateTime,
  ) {
    var age = targetDateTime.year - birthDateTime.year;
    if (targetDateTime.month < birthDateTime.month ||
        (targetDateTime.month == birthDateTime.month &&
            (targetDateTime.day < birthDateTime.day ||
                (targetDateTime.day == birthDateTime.day &&
                    (targetDateTime.hour < birthDateTime.hour ||
                        (targetDateTime.hour == birthDateTime.hour &&
                            targetDateTime.minute < birthDateTime.minute)))))) {
      age--;
    }
    return age < 0 ? 0 : age;
  }

  // --- 4. Muntha Calculation ---

  static int calculateMuntha(
    int natalAscSign,
    int birthYear,
    int targetYear, [
    int? exactAge,
  ]) {
    // Formula: (Natal Asc + completed age) % 12
    final age = exactAge ?? (targetYear - birthYear);
    return (natalAscSign + age) % 12;
  }

  // Panchavargiya Bala, Varshesh selection, and Mudda Dasha are calculated natively via VarshapalService.

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
    var diff = long - asc;
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

  static String getSignLord(int sign) =>
      AstrologyConstants.getSignLord(sign).displayName;

  // Ancient strength calculation helpers (Kshetra, Hadda, Drekkana, Navamsa) removed as they are now natively calculated in VarshapalService.

  static String getTriRashiLord(int sign, bool isDay) {
    final varshapalService = EphemerisManager.jyotish.systems.varshapal;
    return varshapalService
        .getTrirashiLord(Rashi.values[sign % 12], isDay)
        .displayName;
  }

  static bool checkTajikAspect(double p1, double p2) {
    // Forward Aspect
    var diff = p2 - p1;
    if (diff < 0) diff += 360;

    const orb = 12; // Simplified orb
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
    var punyaLong = isDay ? (asc + moon - sun) : (asc + sun - moon);
    punyaLong = (punyaLong + 360) % 360;

    sahams['Punya (Fortune)'] = SahamPoint(
      name: 'Punya Saham',
      longitude: punyaLong,
      interpretation: 'Wealth, success, and fulfillment of desires.',
    );

    final jupiter = getPlanetLongitude(chart, Planet.jupiter);
    final mars = getPlanetLongitude(chart, Planet.mars);
    final saturn = getPlanetLongitude(chart, Planet.saturn);
    final mercury = getPlanetLongitude(chart, Planet.mercury);

    // 2. Vidya Saham (Education/Knowledge)
    // Day: Asc + Sun - Jupiter
    // Night: Asc + Jupiter - Sun
    var vidyaLong = isDay ? (asc + sun - jupiter) : (asc + jupiter - sun);
    vidyaLong = (vidyaLong + 360) % 360;
    sahams['Vidya (Education)'] = SahamPoint(
      name: 'Vidya Saham',
      longitude: vidyaLong,
      interpretation: 'Education, learning, and intellectual pursuits.',
    );

    // 3. Yasha Saham (Fame/Success)
    // Day: Asc + Jupiter - Sun
    // Night: Asc + Sun - Jupiter
    var yashaLong = isDay ? (asc + jupiter - sun) : (asc + sun - jupiter);
    yashaLong = (yashaLong + 360) % 360;
    sahams['Yasha (Fame)'] = SahamPoint(
      name: 'Yasha Saham',
      longitude: yashaLong,
      interpretation: 'Fame, reputation, and public recognition.',
    );

    // 4. Raja Saham (Authority/Power)
    // Day: Asc + Saturn - Sun
    // Night: Asc + Sun - Saturn
    var rajaLong = isDay ? (asc + saturn - sun) : (asc + sun - saturn);
    rajaLong = (rajaLong + 360) % 360;
    sahams['Raja (Authority)'] = SahamPoint(
      name: 'Raja Saham',
      longitude: rajaLong,
      interpretation: 'Authority, government favor, and power.',
    );

    // 5. Putra Saham (Children)
    // Day: Asc + Jupiter - Moon
    // Night: Asc + Moon - Jupiter
    var putraLong = isDay ? (asc + jupiter - moon) : (asc + moon - jupiter);
    putraLong = (putraLong + 360) % 360;
    sahams['Putra (Children)'] = SahamPoint(
      name: 'Putra Saham',
      longitude: putraLong,
      interpretation: 'Children, creativity, and progeny matters.',
    );

    // 6. Mitra Saham (Friends)
    // Day: Asc + Mercury - Moon
    // Night: Asc + Moon - Mercury
    var mitraLong = isDay ? (asc + mercury - moon) : (asc + moon - mercury);
    mitraLong = (mitraLong + 360) % 360;
    sahams['Mitra (Friends)'] = SahamPoint(
      name: 'Mitra Saham',
      longitude: mitraLong,
      interpretation: 'Friendships, alliances, and social connections.',
    );

    // 7. Karma Saham (Career)
    // Day: Asc + Mars - Sun
    // Night: Asc + Sun - Mars
    var karmaLong = isDay ? (asc + mars - sun) : (asc + sun - mars);
    karmaLong = (karmaLong + 360) % 360;
    sahams['Karma (Career)'] = SahamPoint(
      name: 'Karma Saham',
      longitude: karmaLong,
      interpretation: 'Career, profession, and life purpose.',
    );

    return sahams;
  }

  static List<String> calculateTajikYogas({
    required VedicChart annualChart,
    VedicChart? natalChart,
    int age = 0,
    String? lagnaLord,
    String? munthaLord,
    String? yearLord,
  }) {
    final tajakaService = EphemerisManager.jyotish.systems.tajaka;
    final enhancements = tajakaService.calculateTajakaEnhancements(
      natalChart: natalChart ?? annualChart,
      annualChart: annualChart,
      age: age,
    );
    final yogas = enhancements.yogas.map((y) => y.interpretation).toList();
    if (yogas.isEmpty) {
      yogas.add('No major Tajik Yogas active');
    }
    return yogas;
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
    var score = 65.0;

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
        if ([10, 11].contains(houseNum)) {
          themes.add('Career stability through effort');
        }
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
    final main = _generateMainPrediction(planet, dignity, houseNum, score);

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

    // Friend / Enemy relationship lookup
    final signLord = getSignLord(sign);
    final signLordPlanet = getPlanetFromString(signLord);
    const naturalFriends = {
      Planet.sun: [Planet.moon, Planet.mars, Planet.jupiter],
      Planet.moon: [Planet.sun, Planet.mercury],
      Planet.mars: [Planet.sun, Planet.moon, Planet.jupiter],
      Planet.mercury: [Planet.sun, Planet.venus],
      Planet.jupiter: [Planet.sun, Planet.moon, Planet.mars],
      Planet.venus: [Planet.mercury, Planet.saturn],
      Planet.saturn: [Planet.mercury, Planet.venus],
    };
    const naturalEnemies = {
      Planet.sun: [Planet.venus, Planet.saturn],
      Planet.moon: <Planet>[],
      Planet.mars: [Planet.mercury],
      Planet.mercury: [Planet.moon],
      Planet.jupiter: [Planet.mercury, Planet.venus],
      Planet.venus: [Planet.sun, Planet.moon],
      Planet.saturn: [Planet.sun, Planet.moon, Planet.mars],
    };

    if (naturalFriends[planet]?.contains(signLordPlanet) ?? false) return 'Friend Sign';
    if (naturalEnemies[planet]?.contains(signLordPlanet) ?? false) return 'Enemy Sign';
    return 'Neutral';
  }

  static String _generateMainPrediction(
    String planet,
    String dignity,
    int house,
    double score,
  ) {
    final quality = score >= 75
        ? 'favorable'
        : (score >= 55 ? 'moderate' : 'challenging');
    final dignityDesc = dignity == 'Exalted'
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
    return 'Year ruled by $yearLord. Muntha in ${getSignName(muntha)}.';
  }

  static String getSignName(int sign) => AstrologyConstants.getSignName(sign);
}

class NakshatraInfo {
  NakshatraInfo(this.name, this.lord, this.progress);
  final String name;
  final String lord;
  final double progress;
}

/// Varshaphal Chart data
class VarshaphalChart {
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
}

class VarshikDashaPeriod {
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
  final String planet;
  final DateTime startDate;
  final DateTime endDate;
  final double durationDays;
  final String prediction;
  final List<String> keyThemes;
  final List<String> cautions;
  final double favorableScore;
}

class SahamPoint {
  SahamPoint({
    required this.name,
    required this.longitude,
    required this.interpretation,
  });
  final String name;
  final double longitude;
  final String interpretation;

  int get sign => (longitude / 30).floor();
  double get degreeInSign => longitude % 30;
}

class PanchavargiyaStrength {
  PanchavargiyaStrength({
    required this.kshetra,
    required this.uchcha,
    required this.hadda,
    required this.drekkana,
    required this.navamsa,
  });
  final double kshetra;
  final double uchcha;
  final double hadda;
  final double drekkana;
  final double navamsa;

  double get total => kshetra + uchcha + hadda + drekkana + navamsa;
}
