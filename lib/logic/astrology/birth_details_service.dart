import 'package:jyotish/jyotish.dart';
import '../../core/ayanamsa_calculator.dart';
import '../../core/ephemeris_manager.dart';
import '../../core/utils/formatters.dart';
import '../../data/models.dart';
import 'avakahada_service.dart';

/// Detailed information model for the Birth Details screen
class BirthDetailsReport {
  BirthDetailsReport({
    required this.mainDetails,
    required this.avakahadaChakra,
    required this.panchangDetails,
    required this.additionalInfo,
  });

  final Map<String, String> mainDetails;
  final Map<String, String> avakahadaChakra;
  final Map<String, String> panchangDetails;
  final Map<String, String> additionalInfo;
}

class BirthDetailsService {
  static Future<BirthDetailsReport> generateReport(
    CompleteChartData data, {
    String? ayanamsaSystemId,
  }) async {
    final chart = data.baseChart;
    final birthData = data.birthData;
    final moon = chart.planets[Planet.moon]!;
    final moonRashiIndex = (moon.longitude / 30.0).floor();
    final moonNakIndex = moon.position.nakshatraIndex;
    final ascendantIndex = (chart.houses.cusps[0] / 30.0).floor();

    // Calculate Sunrise/Sunset
    final (sunrise, sunset) = await EphemerisManager.jyotish.getSunriseSunset(
      date: birthData.dateTime,
      location: GeographicLocation(
        latitude: birthData.location.latitude,
        longitude: birthData.location.longitude,
      ),
    );

    // Calculate Ishtakala (Time since sunrise)
    var ishtakala = '--';
    if (sunrise != null) {
      final diff = birthData.dateTime.difference(sunrise);
      final totalMinutes = diff.inMinutes;
      final ghatis = (totalMinutes * 2.5 / 60).floor();
      final palas = ((totalMinutes * 2.5) % 60).floor();
      final vipalas = (totalMinutes * 2.5 * 60 % 60).floor();
      ishtakala =
          '${ghatis.toString().padLeft(3, '0')}-${palas.toString().padLeft(2, '0')}-${vipalas.toString().padLeft(2, '0')}';
    }

    // Calculate LMT (Local Mean Time)
    // LMT = GMT + (Longitude / 15)
    final lonHours = birthData.location.longitude / 15.0;
    final gmt = birthData.dateTime.toUtc();
    final lmt = gmt.add(Duration(minutes: (lonHours * 60).round()));

    // LMT Correction (Correction from standard timezone)
    final tzHours = double.tryParse(birthData.timezone) ?? 5.5;
    final lmtCorrectionMinutes =
        (birthData.location.longitude - (tzHours * 15.0)) * 4.0;
    final lmtCorrection =
        '${lmtCorrectionMinutes.abs().floor().toString().padLeft(2, '0')} : ${((lmtCorrectionMinutes.abs() % 1) * 60).round().toString().padLeft(2, '0')}';

    // Julian Day
    final julianDay = EphemerisManager.service.dateTimeToJulianDay(
      birthData.dateTime,
      timezoneId: birthData.timezone,
    );

    // Get Ayanamsa info from library
    final selectedAyanamsaSystemId = ayanamsaSystemId ?? 'lahiri';
    final ayanamsaValue = await AyanamsaCalculator.calculate(
      selectedAyanamsaSystemId,
      birthData.dateTime,
    );
    final system = AyanamsaCalculator.getSystem(selectedAyanamsaSystemId);
    final ayanamsaName = system?.name ?? 'Lahiri';

    // Calculate Panchanga
    final geoLoc = GeographicLocation(
      latitude: birthData.location.latitude,
      longitude: birthData.location.longitude,
    );
    final panchanga = await EphemerisManager.jyotish.calculatePanchanga(
      dateTime: birthData.dateTime,
      location: geoLoc,
    );

    return BirthDetailsReport(
      mainDetails: {
        'Name': birthData.name,
        'Gender': 'Male', // Defaulting for now
        'Date of Birth': AppFormatters.formatDate(birthData.dateTime),
        'Time of Birth': AppFormatters.formatTime(birthData.dateTime),
        'Day of Birth': _getWeekdayName(birthData.dateTime.weekday),
        'Place of Birth': birthData.place,
        'Time Zone': birthData.timezone,
        'Latitude': _formatDegrees(birthData.location.latitude, isLat: true),
        'Longitude': _formatDegrees(birthData.location.longitude, isLat: false),
        'Ishtakala': ishtakala,
        'LMT Correction':
            '${lmtCorrectionMinutes < 0 ? "-" : "+"}$lmtCorrection',
        'Local Mean Time': AppFormatters.formatTime(lmt),
        'Time of Birth (GMT)': AppFormatters.formatTime(gmt),
      },
      avakahadaChakra: {
        'Paya (Nakshatra)': AvakahadaService.getPaya(
          chart.houses.getHouseForLongitude(moon.longitude),
        ),
        'Varna': AvakahadaService.getVarna(moonRashiIndex),
        'Yoni': AvakahadaService.getYoni(moonNakIndex),
        'Gana': AvakahadaService.getGana(moonNakIndex),
        'Vasya': AvakahadaService.getVashya(moonRashiIndex),
        'Nadi': AvakahadaService.getNadi(moonNakIndex),
        'Dasha Balance':
            data.dashaData.vimshottari.mahadashas.first.lord, // Simplified
        'Lagna (Ascendant)': Rashi.fromIndex(ascendantIndex).name,
        'Lagna Lord': Rashi.fromIndex(ascendantIndex).lord.displayName,
        'Rashi (Moon Sign)': moon.zodiacSign,
        'Rashi Lord': Rashi.fromIndex(moonRashiIndex).lord.displayName,
        'Nakshatra-Pada':
            '${moon.nakshatra}-${(moon.longitude % (360 / 27) / (360 / 27 / 4)).floor() + 1}',
        'Nakshatra Lord': _getNakshatraLord(moonNakIndex),
      },
      panchangDetails: {
        'Tithi':
            '${panchanga.tithi.paksha == Paksha.shukla ? 'Shukla' : 'Krishna'} ${panchanga.tithi.name}',
        'Hindu Day': panchanga.vara.name,
        'Paksha': panchanga.tithi.paksha == Paksha.shukla
            ? 'Shukla'
            : 'Krishna',
        'Yoga': panchanga.yoga.name,
        'Karana': panchanga.karana.name,
        'Sunrise': sunrise != null
            ? AppFormatters.formatTime(sunrise.toLocal())
            : '--:--',
        'Sunset': sunset != null
            ? AppFormatters.formatTime(sunset.toLocal())
            : '--:--',
      },
      additionalInfo: {
        'Julian Day': julianDay.toStringAsFixed(6),
        'Sun Sign (Vedic)': chart.planets[Planet.sun]!.zodiacSign,
        'Sun Sign (Western)': await _getWesternSunSign(birthData.dateTime),
        'Ayanamsa': _formatDMS(ayanamsaValue),
        'Ayanamsa Name': ayanamsaName,
        'Obliquity': '23° 26\' 22"', // Approx standard
        'Sidereal Time': '--', // Would need library access
      },
    );
  }

  static String _getWeekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  static String _formatDegrees(double value, {required bool isLat}) {
    final absVal = value.abs();
    final deg = absVal.floor();
    final min = ((absVal - deg) * 60).floor();
    final suffix = isLat ? (value >= 0 ? 'N' : 'S') : (value >= 0 ? 'E' : 'W');
    return '$deg : $min : $suffix';
  }

  static String _formatDMS(double degrees) {
    final deg = degrees.floor();
    final min = ((degrees - deg) * 60).floor();
    return '${deg.toString().padLeft(3, '0')}-${min.toString().padLeft(2, '0')}-${((degrees - deg) * 60 - min).round().toString().padLeft(2, '0')}';
  }

  static String _getNakshatraLord(int index) {
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

  static Future<String> _getWesternSunSign(DateTime date) async {
    try {
      final sunPos = await EphemerisManager.service.calculatePlanetPosition(
        planet: Planet.sun,
        dateTime: date,
        location: GeographicLocation(latitude: 0.0, longitude: 0.0),
        flags: CalculationFlags.traditionalist(),
      );

      final ayanamsa = await EphemerisManager.service.getAyanamsa(
        dateTime: date,
        mode: SiderealMode.lahiri,
      );

      final tropicalSunLongitude = (sunPos.longitude + ayanamsa) % 360;
      final signIndex = (tropicalSunLongitude / 30.0).floor();

      const westernSigns = [
        'Aries',
        'Taurus',
        'Gemini',
        'Cancer',
        'Leo',
        'Virgo',
        'Libra',
        'Scorpio',
        'Sagittarius',
        'Capricorn',
        'Aquarius',
        'Pisces',
      ];

      return westernSigns[signIndex.clamp(0, 11)];
    } catch (_) {
      final day = date.day;
      final month = date.month;
      if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
        return 'Aries';
      }
      if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
        return 'Taurus';
      }
      if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
        return 'Gemini';
      }
      if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
        return 'Cancer';
      }
      if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
        return 'Leo';
      }
      if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
        return 'Virgo';
      }
      if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
        return 'Libra';
      }
      if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
        return 'Scorpio';
      }
      if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
        return 'Sagittarius';
      }
      if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
        return 'Capricorn';
      }
      if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
        return 'Aquarius';
      }
      return 'Pisces';
    }
  }
}
