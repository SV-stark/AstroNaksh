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
    required this.karana,
    required this.vara,
    this.sunrise,
    this.sunset,
    this.moonrise,
    this.moonset,
  });
}

class PanchangService {
  final Jyotish _jyotish = Jyotish();
  PanchangaService? _panchangaService;

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
}
