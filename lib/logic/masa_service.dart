import 'package:jyotish/jyotish.dart';
import '../../data/models.dart';
import '../core/ephemeris_manager.dart';

class MasaService {
  /// Get current Hindu lunar month (Masa)
  Future<HinduMasa> getCurrentMasa(DateTime date, Location location) async {
    await EphemerisManager.ensureEphemerisData();
    
    // Calculate moon's position
    final locationGeo = GeographicLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      altitude: 0,
    );
    
    final chart = await EphemerisManager.jyotish.calculateVedicChart(
      dateTime: date,
      location: locationGeo,
    );
    
    final moon = chart.planets[Planet.moon];
    if (moon == null) {
      return HinduMasa(
        masaName: 'Unknown',
        purnimanta: 'Unknown',
        amanta: 'Unknown',
        month: 0,
        year: 0,
      );
    }
    
    final sun = chart.planets[Planet.sun];
    final sunLongitude = sun?.position.longitude ?? 0;
    final moonLongitude = moon.position.longitude;
    
    // Calculate which masa (month) based on sun/moon positions
    final masaIndex = ((moonLongitude - sunLongitude + 360) % 360) ~/ 30;
    final masaName = _getMasaName(masaIndex);
    final year = _getVikramYear(date);
    
    // Calculate both purnimanta and amanta
    final purnimanta = ((masaIndex + 1) % 12) + 1;
    final amanta = (masaIndex % 12) + 1;
    
    return HinduMasa(
      masaName: masaName,
      purnimanta: _getMonthName(purnimanta),
      amanta: _getMonthName(amanta),
      month: masaIndex + 1,
      year: year,
      moonPhase: _getMoonPhase(moonLongitude, sunLongitude),
    );
  }

  String _getMasaName(int index) {
    const masas = [
      'Chaitra', 'Vaishakha', 'Jyeshtha', 'Ashadha',
      'Shravana', 'Bhadrapada', 'Ashwin', 'Kartika',
      'Margashirsha', 'Pausha', 'Magha', 'Phalguna'
    ];
    return index >= 0 && index < 12 ? masas[index] : 'Unknown';
  }

  String _getMonthName(int index) {
    const months = [
      'Chaitra', 'Vaishakha', 'Jyeshtha', 'Ashadha',
      'Shravana', 'Bhadrapada', 'Ashwin', 'Kartika',
      'Margashirsha', 'Pausha', 'Magha', 'Phalguna'
    ];
    return index >= 1 && index <= 12 ? months[index - 1] : 'Unknown';
  }

  int _getVikramYear(DateTime date) {
    // Vikram Samvat is about 56.7 years ahead of Gregorian
    final year = date.year + 56;
    if (date.month < 3 || (date.month == 3 && date.day < 14)) {
      return year - 1;
    }
    return year;
  }

  String _getMoonPhase(double moonLong, double sunLong) {
    final phase = (moonLong - sunLong + 360) % 360;
    
    if (phase < 15) return 'Shukla Pratipada';
    if (phase < 30) return 'Shukla Dwitiya';
    if (phase < 45) return 'Shukla Tritiya';
    if (phase < 60) return 'Shukla Chaturthi';
    if (phase < 75) return 'Shukla Panchami';
    if (phase < 90) return 'Shukla Shashthi';
    if (phase < 105) return 'Shukla Saptami';
    if (phase < 120) return 'Shukla Ashtami';
    if (phase < 135) return 'Shukla Navami';
    if (phase < 150) return 'Shukla Dashami';
    if (phase < 165) return 'Shukla Ekadashi';
    if (phase < 180) return 'Shukla Dwadashi';
    if (phase < 195) return 'Shukla Trayodashi';
    if (phase < 210) return 'Shukla Chaturdashi';
    if (phase < 225) return 'Poornima';
    if (phase < 240) return 'Krishna Pratipada';
    if (phase < 255) return 'Krishna Dwitiya';
    if (phase < 270) return 'Krishna Tritiya';
    if (phase < 285) return 'Krishna Chaturthi';
    if (phase < 300) return 'Krishna Panchami';
    if (phase < 315) return 'Krishna Shashthi';
    if (phase < 330) return 'Krishna Saptami';
    if (phase < 345) return 'Krishna Ashtami';
    return 'Amavasya';
  }
}

class HinduMasa {
  final String masaName;
  final String purnimanta;
  final String amanta;
  final int month;
  final int year;
  final String moonPhase;

  HinduMasa({
    required this.masaName,
    required this.purnimanta,
    required this.amanta,
    required this.month,
    required this.year,
    required this.moonPhase,
  });
}
