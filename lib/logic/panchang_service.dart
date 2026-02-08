import 'package:jyotish/jyotish.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';
import '../core/ephemeris_manager.dart';

class PanchangResult {
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
  });
}

class PanchangInauspicious {
  final String name;
  final String startTime;
  final String endTime;

  PanchangInauspicious({
    required this.name,
    required this.startTime,
    required this.endTime,
  });
}

class PanchangHora {
  final String planet;
  final String startTime;
  final String endTime;
  final bool isDay;

  PanchangHora({
    required this.planet,
    required this.startTime,
    required this.endTime,
    required this.isDay,
  });
}

class PanchangChoghadiya {
  final String name;
  final String type; // Auspicious, Inauspicious, Neutral
  final String startTime;
  final String endTime;
  final bool isDay;

  PanchangChoghadiya({
    required this.name,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.isDay,
  });
}

class PanchangService {
  final Jyotish _jyotish = Jyotish();
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

    // Calculate Rise/Set times
    final (sr, ss) = await _jyotish.getSunriseSunset(
      date: dateTime,
      location: geoLoc,
    );

    // Moonrise/set (using default rsmi flags from documentation)
    final mr = await _jyotish.getRiseSet(
      planet: Planet.moon,
      date: dateTime,
      location: geoLoc,
      rsmi: 1, // calcRise
    );
    final ms = await _jyotish.getRiseSet(
      planet: Planet.moon,
      date: dateTime,
      location: geoLoc,
      rsmi: 2, // calcSet
    );

    final moon = chart.getPlanet(Planet.moon)!;
    final timeFormat = DateFormat('HH:mm');

    return PanchangResult(
      date: DateFormat('dd MMMM yyyy, HH:mm').format(dateTime),
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
      sunrise: sr != null ? timeFormat.format(sr.toLocal()) : '--:--',
      sunset: ss != null ? timeFormat.format(ss.toLocal()) : '--:--',
      moonrise: mr != null ? timeFormat.format(mr.toLocal()) : '--:--',
      moonset: ms != null ? timeFormat.format(ms.toLocal()) : '--:--',
    );
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

    final (sr, ss) = await _jyotish.getSunriseSunset(
      date: date,
      location: geoLoc,
    );

    if (sr == null || ss == null) return [];

    final dynamic rawPeriods = _jyotish.getInauspiciousPeriods(
      date: date,
      sunrise: sr,
      sunset: ss,
    );

    final timeFormat = DateFormat('HH:mm');
    final results = <PanchangInauspicious>[];

    // Inspecting structure dynamically if it's not a Map.
    // Usually it has a 'periods' or 'all' list.
    try {
      final Iterable periods = rawPeriods is Map
          ? rawPeriods.entries
          : (rawPeriods.periods ?? []);
      for (final p in periods) {
        if (p is MapEntry) {
          results.add(
            PanchangInauspicious(
              name: p.key,
              startTime: timeFormat.format(p.value.start.toLocal()),
              endTime: timeFormat.format(p.value.end.toLocal()),
            ),
          );
        } else {
          results.add(
            PanchangInauspicious(
              name: p.name,
              startTime: timeFormat.format(p.start.toLocal()),
              endTime: timeFormat.format(p.end.toLocal()),
            ),
          );
        }
      }
    } catch (e) {
      // Log or handle
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

    final List<dynamic> rawHoras = await _jyotish.getHorasForDay(
      date: date,
      location: geoLoc,
    );

    final timeFormat = DateFormat('HH:mm');
    return rawHoras.map((h) {
      return PanchangHora(
        planet: h.planet.displayName,
        startTime: timeFormat.format(h.start.toLocal()),
        endTime: timeFormat.format(h.end.toLocal()),
        isDay: h.isDay,
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

    final (sr, ss) = await _jyotish.getSunriseSunset(
      date: date,
      location: geoLoc,
    );

    if (sr == null || ss == null) return [];

    final dynamic rawResult = _jyotish.getChoghadiya(
      date: date,
      sunrise: sr,
      sunset: ss,
    );

    // Choghadiya might be wrapped in a class. Let's try to find the list.
    final List<dynamic> choghadiyas = rawResult is List
        ? rawResult
        : (rawResult.periods ?? []);

    final timeFormat = DateFormat('HH:mm');
    return choghadiyas.map<PanchangChoghadiya>((c) {
      return PanchangChoghadiya(
        name: c.name,
        type: c.type.toString().split('.').last,
        startTime: timeFormat.format(c.start.toLocal()),
        endTime: timeFormat.format(c.end.toLocal()),
        isDay: c.isDay,
      );
    }).toList();
  }
}
