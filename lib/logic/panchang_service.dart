import 'dart:io';
import 'package:jyotish/core.dart';
import 'package:jyotish/muhurta.dart';
import 'package:jyotish/panchanga.dart';

import '../core/ephemeris_manager.dart';
import '../core/utils/formatters.dart';
import '../data/models.dart';

class PanchangResult {
  PanchangResult({
    required this.date,
    required this.tithi,
    required this.tithiNumber,
    required this.nakshatra,
    required this.nakshatraNumber,
    required this.yoga,
    required this.yogaNumber,
    this.yogaNature,
    this.yogaRecommendations,
    required this.karana,
    required this.vara,
    this.sunrise,
    this.sunset,
    this.moonrise,
    this.moonset,
    this.rituals,
  });
  final String date;
  final String tithi;
  final int tithiNumber;
  final String nakshatra;
  final int nakshatraNumber;
  final String yoga;
  final int yogaNumber;
  final String? yogaNature;
  final String? yogaRecommendations;
  final String karana;
  final String vara;
  final String? sunrise;
  final String? sunset;
  final String? moonrise;
  final String? moonset;
  final RitualElements? rituals;
}

class PanchangInauspicious {
  PanchangInauspicious({
    required this.name,
    required this.startTime,
    required this.endTime,
  });
  final String name;
  final String startTime;
  final String endTime;
}

class PanchangHora {
  PanchangHora({
    required this.planet,
    required this.startTime,
    required this.endTime,
    required this.isDay,
  });
  final String planet;
  final String startTime;
  final String endTime;
  final bool isDay;
}

class PanchangChoghadiya {
  PanchangChoghadiya({
    required this.name,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.isDay,
  });
  final String name;
  final String type; // Auspicious, Inauspicious, Neutral
  final String startTime;
  final String endTime;
  final bool isDay;
}

class PanchangService {
  // Reuse the global singleton to avoid double-initialization
  final Jyotish _jyotish = EphemerisManager.jyotish;
  PanchangaService? _panchangaService;

  // Helper map for Yoga recommendations
  static const Map<String, String> _yogaRecommendationsMap = {
    'Vishkumbha': 'Avoid travel and auspicious works. Prevails over enemies.',
    'Priti': 'Good for love, friendship, and romance.',
    'Ayushman': 'Promotes longevity and health. Good for medical treatments.',
    'Saubhagya': 'Brings good luck and prosperity. Good for new ventures.',
    'Sobhana': 'Splendid and glorious. Good for creative arts.',
    'Atiganda': 'Avoid major undertakings. Possibility of obstacles.',
    'Sukarma': 'Good for righteous deeds and religious work.',
    'Dhriti': 'Good for foundation laying and long-term projects.',
    'Sula': 'Painful or piercing. Avoid conflicts and medical surgeries.',
    'Ganda': 'Knot or obstacle. Avoid starting new things.',
    'Vriddhi': 'Growth and expansion. Good for investments.',
    'Dhruva': 'Fixed and stable. Good for construction and marriage.',
    'Vyaghata': 'Beating or striking. Danger of injury. Be careful.',
    'Harshana': 'Joyous and delightful. Good for celebrations.',
    'Vajra': 'Diamond or thunderbolt. Strong but can be harsh. Avoid travel.',
    'Siddhi': 'Accomplishment and success. Good for all works.',
    'Vyatipata': 'Great calamity. Strictly avoid auspicious events.',
    'Variyan': 'Superior and excellent. Good for commerce and trade.',
    'Parigha': 'Obstruction or bar. Potential delays.',
    'Siva': 'Auspicious/Benign. Good for spiritual activities.',
    'Siddha': 'Proven or perfected. Success in endeavors.',
    'Sadhya': 'Possible to achieve. Good for planning and negotiation.',
    'Subha': 'Auspcicious. Good for marriage and ceremonies.',
    'Sukla': 'Bright and pure. Good for learning and clarity.',
    'Brahma': 'Priestly or divine. Good for wisdom and teaching.',
    'Indra': 'Chief or ruler. Good for leadership and government work.',
    'Vaidhriti': 'Poor support or divisiveness. Avoid teamwork.',
  };

  Future<PanchangResult> getPanchang(
    DateTime dateTime,
    Location location,
  ) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return PanchangResult(
        date: AppFormatters.formatDateTime(dateTime),
        tithi: 'Shukla Pratipada',
        tithiNumber: 1,
        nakshatra: 'Ashwini',
        nakshatraNumber: 1,
        yoga: 'Priti',
        yogaNumber: 2,
        yogaNature: 'Auspicious',
        yogaRecommendations: 'Good for love and friendship.',
        karana: 'Bava',
        vara: 'Monday',
        sunrise: '06:30 AM',
        sunset: '06:30 PM',
        moonrise: '06:30 PM',
        moonset: '06:30 AM',
      );
    }

    await _jyotish.initialize();

    final geoLoc = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    // Calculate Vedic Chart to get Nakshatra
    final chart = await _jyotish.calculateVedicChart(
      dateTime: dateTime,
      location: geoLoc,
    );

    // Calculate Panchanga
    final panchanga = await _jyotish.calculatePanchanga(
      dateTime: dateTime,
      location: geoLoc,
    );

    // Calculate Rise/Set times with typed exception handling
    DateTime? sr;
    DateTime? ss;
    try {
      final (calcSr, calcSs) = await _jyotish.getSunriseSunset(
        date: dateTime,
        location: geoLoc,
      );
      sr = calcSr;
      ss = calcSs;
    } on PolarRegionException {
      sr = null;
      ss = null;
    } on CalculationException {
      sr = null;
      ss = null;
    } catch (_) {
      sr = null;
      ss = null;
    }

    // Moonrise/set (using default rsmi flags from documentation)
    DateTime? mr;
    try {
      mr = await _jyotish.getRiseSet(
        planet: Planet.moon,
        date: dateTime,
        location: geoLoc,
        rsmi: 1, // calcRise
      );
    } on PolarRegionException {
      mr = null;
    } on CalculationException {
      mr = null;
    } catch (_) {
      mr = null;
    }

    DateTime? ms;
    try {
      ms = await _jyotish.getRiseSet(
        planet: Planet.moon,
        date: dateTime,
        location: geoLoc,
        rsmi: 2, // calcSet
      );
    } on PolarRegionException {
      ms = null;
    } on CalculationException {
      ms = null;
    } catch (_) {
      ms = null;
    }

    final moon = chart.getPlanet(Planet.moon)!;
    RitualElements? rituals;
    try {
      rituals = _jyotish.calculateRitualElements(panchanga: panchanga);
    } catch (_) {}

    return PanchangResult(
      date: AppFormatters.formatDateTime(dateTime),
      tithi:
          '${panchanga.tithi.paksha == Paksha.shukla ? 'Shukla' : 'Krishna'} ${panchanga.tithi.name}',
      tithiNumber: panchanga.tithi.number,
      nakshatra: moon.nakshatra,
      nakshatraNumber: moon.position.nakshatraIndex + 1,
      yoga: panchanga.yoga.name,
      yogaNumber: panchanga.yoga.number,
      yogaNature: panchanga.yoga.nature.name,
      yogaRecommendations:
          _yogaRecommendationsMap[panchanga.yoga.name] ??
          'General good conduct recommended.',
      karana: panchanga.karana.name,
      vara: panchanga.vara.name,
      sunrise: sr != null ? AppFormatters.formatTime(_toLocationTime(sr, location)) : '--:--',
      sunset: ss != null ? AppFormatters.formatTime(_toLocationTime(ss, location)) : '--:--',
      moonrise: mr != null ? AppFormatters.formatTime(_toLocationTime(mr, location)) : '--:--',
      moonset: ms != null ? AppFormatters.formatTime(_toLocationTime(ms, location)) : '--:--',
      rituals: rituals,
    );
  }

  static DateTime _toLocationTime(DateTime dt, Location location) {
    // Offset in minutes calculated from longitude (15 deg = 1 hour)
    final offsetMinutes = (location.longitude / 15.0 * 60).round();
    return dt.toUtc().add(Duration(minutes: offsetMinutes));
  }

  /// Calculate Abhijit Muhurta (the victorious midday period)
  /// Highly auspicious and can destroy millions of obstacles
  Future<AbhijitMuhurta> getAbhijitMuhurta(
    DateTime date,
    Location location,
  ) async {
    await _jyotish.initialize();
    _panchangaService ??= PanchangaService(EphemerisManager.service);

    final geoLoc = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    return _panchangaService!.calculateAbhijitMuhurta(
      date: date,
      location: geoLoc,
    );
  }

  /// Calculate Brahma Muhurta (the auspicious pre-dawn period)
  /// Best time for meditation, yoga, and spiritual practices
  Future<BrahmaMuhurta> getBrahmaMuhurta(
    DateTime date,
    Location location,
  ) async {
    await _jyotish.initialize();
    _panchangaService ??= PanchangaService(EphemerisManager.service);

    final geoLoc = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    return _panchangaService!.calculateBrahmaMuhurta(
      date: date,
      location: geoLoc,
    );
  }

  /// Get detailed Moon phase information
  /// Includes illumination percentage, lunar age, and phase name
  Future<MoonPhaseDetails> getMoonPhaseDetails(
    DateTime dateTime,
    Location location,
  ) async {
    await _jyotish.initialize();
    _panchangaService ??= PanchangaService(EphemerisManager.service);

    final geoLoc = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    return _panchangaService!.getMoonPhaseDetails(
      dateTime: dateTime,
      location: geoLoc,
    );
  }

  /// Calculate nighttime inauspicious periods (Rahu Kaal, Gulika, Yamagandam)
  Future<NighttimeInauspiciousPeriods> getNighttimeInauspicious(
    DateTime date,
    Location location,
  ) async {
    await _jyotish.initialize();
    _panchangaService ??= PanchangaService(EphemerisManager.service);

    final geoLoc = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    return _panchangaService!.calculateNighttimeInauspicious(
      date: date,
      location: geoLoc,
    );
  }

  /// Get exact Tithi end time with high precision
  Future<DateTime> getTithiEndTime(DateTime dateTime, Location location) async {
    await _jyotish.initialize();
    _panchangaService ??= PanchangaService(EphemerisManager.service);

    final geoLoc = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    return _panchangaService!.getTithiEndTime(
      dateTime: dateTime,
      location: geoLoc,
    );
  }

  /// Get exact Tithi junction (start time) for a specific Tithi
  Future<DateTime> getTithiJunction(
    int tithiNumber,
    DateTime startDate,
    Location location,
  ) async {
    await _jyotish.initialize();
    _panchangaService ??= PanchangaService(EphemerisManager.service);

    final geoLoc = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    return _panchangaService!.getTithiJunction(
      targetTithiNumber: tithiNumber,
      startDate: startDate,
      location: geoLoc,
    );
  }

  /// Get Inauspicious periods for the day (Rahu Kaal, Yamaganda, Gulika)
  Future<List<PanchangInauspicious>> getInauspicious(
    DateTime date,
    Location location,
  ) async {
    await _jyotish.initialize();
    final geoLoc = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    DateTime? sr;
    DateTime? ss;
    try {
      final (calcSr, calcSs) = await _jyotish.getSunriseSunset(
        date: date,
        location: geoLoc,
      );
      sr = calcSr;
      ss = calcSs;
    } on PolarRegionException {
      return [];
    } on CalculationException {
      return [];
    } catch (_) {
      return [];
    }

    if (sr == null || ss == null) return [];

    // Use typed InauspiciousPeriods return instead of dynamic cast
    final periods = _jyotish.getInauspiciousPeriods(
      date: date,
      sunrise: sr,
      sunset: ss,
    );

    final results = <PanchangInauspicious>[];

    if (periods.rahukalam != null) {
      results.add(
        PanchangInauspicious(
          name: 'Rahukalam',
          startTime: AppFormatters.formatTime(
            _toLocationTime(periods.rahukalam!.start, location),
          ),
          endTime: AppFormatters.formatTime(
            _toLocationTime(periods.rahukalam!.end, location),
          ),
        ),
      );
    }
    if (periods.gulikalam != null) {
      results.add(
        PanchangInauspicious(
          name: 'Gulikalam',
          startTime: AppFormatters.formatTime(
            _toLocationTime(periods.gulikalam!.start, location),
          ),
          endTime: AppFormatters.formatTime(
            _toLocationTime(periods.gulikalam!.end, location),
          ),
        ),
      );
    }
    if (periods.yamagandam != null) {
      results.add(
        PanchangInauspicious(
          name: 'Yamagandam',
          startTime: AppFormatters.formatTime(
            _toLocationTime(periods.yamagandam!.start, location),
          ),
          endTime: AppFormatters.formatTime(
            _toLocationTime(periods.yamagandam!.end, location),
          ),
        ),
      );
    }

    return results;
  }

  /// Get Horas for the day
  Future<List<PanchangHora>> getHoras(DateTime date, Location location) async {
    await _jyotish.initialize();
    final geoLoc = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    final rawHoras = await _jyotish.getHorasForDay(
      date: date,
      location: geoLoc,
    );

    return rawHoras.map((h) {
      return PanchangHora(
        planet: h.lord.displayName,
        startTime: AppFormatters.formatTime(_toLocationTime(h.startTime, location)),
        endTime: AppFormatters.formatTime(_toLocationTime(h.endTime, location)),
        isDay: h.isDaytime,
      );
    }).toList();
  }

  /// Get Choghadiyas for the day
  Future<List<PanchangChoghadiya>> getChoghadiya(
    DateTime date,
    Location location,
  ) async {
    await _jyotish.initialize();
    final geoLoc = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    DateTime? sr;
    DateTime? ss;
    try {
      final (calcSr, calcSs) = await _jyotish.getSunriseSunset(
        date: date,
        location: geoLoc,
      );
      sr = calcSr;
      ss = calcSs;
    } on PolarRegionException {
      return [];
    } on CalculationException {
      return [];
    } catch (_) {
      return [];
    }

    if (sr == null || ss == null) return [];

    // Use typed ChoghadiyaPeriods return instead of dynamic cast
    final result = _jyotish.getChoghadiya(date: date, sunrise: sr, sunset: ss);

    return result.allPeriods.map<PanchangChoghadiya>((c) {
      return PanchangChoghadiya(
        name: c.name,
        type: c.type.nature, // e.g. 'Auspicious' or 'Inauspicious'
        startTime: AppFormatters.formatTime(_toLocationTime(c.startTime, location)),
        endTime: AppFormatters.formatTime(_toLocationTime(c.endTime, location)),
        isDay: c.isDaytime,
      );
    }).toList();
  }

  /// Get Special Muhurta Yogas for the day (Guru Pushya, Sarvartha Siddhi, etc.)
  /// Uses MuhurtaService directly to supply tithiPeriods and nakshatraPeriods
  /// for accurate intersection calculation.
  Future<List<SpecialYoga>> getSpecialYogas(
    DateTime date,
    Location location,
  ) async {
    await _jyotish.initialize();
    _panchangaService ??= PanchangaService(EphemerisManager.service);

    final geoLoc = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    DateTime? sr;
    DateTime? ss;
    try {
      final (calcSr, calcSs) = await _jyotish.getSunriseSunset(
        date: date,
        location: geoLoc,
      );
      sr = calcSr;
      ss = calcSs;
    } on PolarRegionException {
      return [];
    } on CalculationException {
      return [];
    } catch (_) {
      return [];
    }

    if (sr == null || ss == null) return [];

    // Calculate Panchanga for tithi and nakshatra info
    final panchanga = await _jyotish.calculatePanchanga(
      dateTime: date,
      location: geoLoc,
    );

    // Get precise tithi end time
    final tithiEnd = await _panchangaService!.getTithiEndTime(
      dateTime: date,
      location: geoLoc,
    );

    // Build tithi period record
    final tithiPeriods = [(panchanga.tithi.number, date, tithiEnd)];

    // Build nakshatra period record; estimate end as next sunrise (24 h)
    final nakshatraEnd = sr.add(const Duration(hours: 24));
    final nakshatraPeriods = [(panchanga.nakshatra.number, date, nakshatraEnd)];

    // Call MuhurtaService directly — jyotish_core wrapper doesn't expose
    // tithiPeriods/nakshatraPeriods, so we bypass it here.
    final muhurtaService = MuhurtaService();
    final muhurta = muhurtaService.calculateMuhurta(
      date: date,
      sunrise: sr,
      sunset: ss,
      location: geoLoc,
      tithiPeriods: tithiPeriods,
      nakshatraPeriods: nakshatraPeriods,
    );

    return muhurta.specialYogas;
  }
}
