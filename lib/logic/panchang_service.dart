import 'package:jyotish/jyotish.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';

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
  });
}

class PanchangService {
  final Jyotish _jyotish = Jyotish();

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

    final moon = chart.getPlanet(Planet.moon)!;

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
    );
  }
}
