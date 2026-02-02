import 'package:jyotish/jyotish.dart';
import '../data/models.dart';

/// Complete Dasha System Implementation
/// Includes Vimshottari, Yogini, and Chara Dasha
class DashaSystem {
  // Vimshottari Dasha periods (in years)
  static const Map<String, double> _vimshottariPeriods = {
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

  // Vimshottari sequence
  static const List<String> _vimshottariSequence = [
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

  // Nakshatra lords for 27 nakshatras
  static const List<String> _nakshatraLords = [
    'Ketu',
    'Venus',
    'Sun',
    'Moon',
    'Mars',
    'Rahu',
    'Jupiter',
    'Saturn',
    'Mercury',
    'Ketu',
    'Venus',
    'Sun',
    'Moon',
    'Mars',
    'Rahu',
    'Jupiter',
    'Saturn',
    'Mercury',
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

  /// Calculate Vimshottari Dasha for a birth chart
  /// Returns the complete Dasha tree (Mahadasha, Antardasha, Pratyantardasha)
  static VimshottariDasha calculateVimshottariDasha(VedicChart chart) {
    // Find Moon's position
    Planet? moonPlanet;
    double moonLongitude = 0;

    for (final entry in chart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        moonPlanet = entry.key;
        moonLongitude = entry.value.longitude;
        break;
      }
    }

    if (moonPlanet == null) {
      throw Exception('Moon position not found in chart');
    }

    // Calculate which nakshatra Moon is in (exact span = 360°/27)
    const double nakshatraSpan = 360.0 / 27.0;
    final nakshatraIndex = (moonLongitude / nakshatraSpan).floor();
    final nakshatraLord = _nakshatraLords[nakshatraIndex];
    final positionInNakshatra = moonLongitude % nakshatraSpan;

    // Calculate balance of dasha at birth
    final remainingNakshatra = nakshatraSpan - positionInNakshatra;
    final dashaPeriod = _vimshottariPeriods[nakshatraLord]!;
    final balanceAtBirth = (remainingNakshatra / nakshatraSpan) * dashaPeriod;

    // Calculate start date
    final birthDate = chart.dateTime;
    final firstDashaStart = birthDate;

    // Build complete Dasha sequence
    final mahadashas = <Mahadasha>[];
    var currentDate = firstDashaStart;
    var currentLordIndex = _vimshottariSequence.indexOf(nakshatraLord);

    // Calculate 9 mahadashas (full cycle = 120 years)
    for (int i = 0; i < 9; i++) {
      final lord = _vimshottariSequence[(currentLordIndex + i) % 9];
      double period;

      if (i == 0) {
        // First dasha has balance remaining
        period = balanceAtBirth;
      } else {
        period = _vimshottariPeriods[lord]!;
      }

      final endDate = currentDate.add(_yearsToDuration(period));

      mahadashas.add(
        Mahadasha(
          lord: lord,
          startDate: currentDate,
          endDate: endDate,
          periodYears: period,
          antardashas: _calculateAntardashas(lord, currentDate, endDate),
        ),
      );

      currentDate = endDate;
    }

    return VimshottariDasha(
      birthLord: nakshatraLord,
      balanceAtBirth: balanceAtBirth,
      mahadashas: mahadashas,
    );
  }

  /// Calculate Antardashas within a Mahadasha
  static List<Antardasha> _calculateAntardashas(
    String mahadashaLord,
    DateTime start,
    DateTime end,
  ) {
    final antardashas = <Antardasha>[];
    final mahadashaPeriod = end.difference(start).inDays / 365.25;

    var currentDate = start;
    final startIndex = _vimshottariSequence.indexOf(mahadashaLord);

    for (int i = 0; i < 9; i++) {
      final antarLord = _vimshottariSequence[(startIndex + i) % 9];
      final antarPeriod =
          (mahadashaPeriod * _vimshottariPeriods[antarLord]!) / 120;

      final antarEnd = currentDate.add(_yearsToDuration(antarPeriod));

      antardashas.add(
        Antardasha(
          lord: antarLord,
          startDate: currentDate,
          endDate: antarEnd,
          periodYears: antarPeriod,
          pratyantardashas: _calculatePratyantardashas(
            mahadashaLord,
            antarLord,
            currentDate,
            antarEnd,
          ),
        ),
      );

      currentDate = antarEnd;
    }

    return antardashas;
  }

  /// Calculate Pratyantardashas within an Antardasha
  static List<Pratyantardasha> _calculatePratyantardashas(
    String mahadashaLord,
    String antardashaLord,
    DateTime start,
    DateTime end,
  ) {
    final pratyantardashas = <Pratyantardasha>[];
    final antarPeriod = end.difference(start).inDays / 365.25;

    var currentDate = start;
    final startIndex = _vimshottariSequence.indexOf(antardashaLord);

    for (int i = 0; i < 9; i++) {
      final pratyanLord = _vimshottariSequence[(startIndex + i) % 9];
      final pratyanPeriod =
          (antarPeriod * _vimshottariPeriods[pratyanLord]!) / 120;

      final pratyanEnd = currentDate.add(_yearsToDuration(pratyanPeriod));

      pratyantardashas.add(
        Pratyantardasha(
          mahadashaLord: mahadashaLord,
          antardashaLord: antardashaLord,
          lord: pratyanLord,
          startDate: currentDate,
          endDate: pratyanEnd,
          periodYears: pratyanPeriod,
        ),
      );

      currentDate = pratyanEnd;
    }

    return pratyantardashas;
  }

  /// Convert years to Duration (preserves fractional days as hours)
  static Duration _yearsToDuration(double years) {
    final totalDays = years * 365.25;
    final wholeDays = totalDays.floor();
    final fractionalHours = ((totalDays - wholeDays) * 24).round();
    return Duration(days: wholeDays, hours: fractionalHours);
  }

  /// Calculate Yogini Dasha
  /// 36-year cycle with 8 yoginis - calculates multiple cycles for full lifetime
  static YoginiDasha calculateYoginiDasha(VedicChart chart) {
    const yoginiNames = [
      'Mangala',
      'Pingala',
      'Dhanya',
      'Bhramari',
      'Bhadrika',
      'Ulka',
      'Siddha',
      'Sankata',
    ];

    const yoginiPeriods = [1, 2, 3, 4, 5, 6, 7, 8]; // years
    const yoginiLords = [
      'Moon',
      'Sun',
      'Jupiter',
      'Mars',
      'Mercury',
      'Saturn',
      'Venus',
      'Rahu',
    ];

    // Yogini cycle = 36 years; calculate 4 cycles (144 years coverage)
    const numCyclesForLifetime = 4;

    // Determine starting yogini based on Moon's nakshatra
    final moonNakshatra = _getMoonNakshatra(chart);
    final startIndex = (moonNakshatra % 8);

    // Calculate balance at birth (similar to Vimshottari)
    double moonLongitude = 0;
    for (final entry in chart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        moonLongitude = entry.value.longitude;
        break;
      }
    }
    const double nakshatraSpan = 360.0 / 27.0;
    final positionInNakshatra = moonLongitude % nakshatraSpan;
    final remainingNakshatra = nakshatraSpan - positionInNakshatra;
    final proportionRemaining = remainingNakshatra / nakshatraSpan;
    final firstYoginiPeriod = yoginiPeriods[startIndex].toDouble();
    final balanceAtBirth = proportionRemaining * firstYoginiPeriod;

    final mahadashas = <YoginiMahadasha>[];
    var currentDate = chart.dateTime;

    // First yogini with balance
    var currentYoginiIndex = startIndex;
    var firstPeriod = balanceAtBirth;
    var endDate = currentDate.add(_yearsToDuration(firstPeriod));
    mahadashas.add(
      YoginiMahadasha(
        name: yoginiNames[currentYoginiIndex],
        lord: yoginiLords[currentYoginiIndex],
        startDate: currentDate,
        endDate: endDate,
        periodYears: firstPeriod,
      ),
    );
    currentDate = endDate;
    currentYoginiIndex = (currentYoginiIndex + 1) % 8;

    // Calculate remaining yoginis for multiple cycles
    final totalYoginis = numCyclesForLifetime * 8 - 1; // -1 for first partial
    for (int i = 0; i < totalYoginis; i++) {
      final period = yoginiPeriods[currentYoginiIndex].toDouble();
      endDate = currentDate.add(_yearsToDuration(period));

      mahadashas.add(
        YoginiMahadasha(
          name: yoginiNames[currentYoginiIndex],
          lord: yoginiLords[currentYoginiIndex],
          startDate: currentDate,
          endDate: endDate,
          periodYears: period,
        ),
      );

      currentDate = endDate;
      currentYoginiIndex = (currentYoginiIndex + 1) % 8;
    }

    return YoginiDasha(
      startYogini: yoginiNames[startIndex],
      mahadashas: mahadashas,
    );
  }

  /// Calculate Chara Dasha (Jaimini System)
  /// Sign-based dasha system
  static CharaDasha calculateCharaDasha(VedicChart chart) {
    // Determine starting sign based on lagna and its nature
    final ascendantSign = _getAscendantSign(chart);
    final isOdd = ascendantSign % 2 == 0; // 0-indexed

    // Order: Odd signs go forward, even signs go backward
    final dashaOrder = isOdd
        ? [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] // Aries to Pisces
        : [11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]; // Pisces to Aries

    // Find starting position
    final startIndex = dashaOrder.indexOf(ascendantSign);

    final periods = <CharaDashaPeriod>[];
    var currentDate = chart.dateTime;

    for (int i = 0; i < 12; i++) {
      final signIndex = dashaOrder[(startIndex + i) % 12];
      final period = _calculateCharaPeriod(chart, signIndex);
      final endDate = currentDate.add(_yearsToDuration(period));

      periods.add(
        CharaDashaPeriod(
          sign: signIndex,
          signName: _getSignName(signIndex),
          lord: _getSignLord(signIndex),
          startDate: currentDate,
          endDate: endDate,
          periodYears: period,
        ),
      );

      currentDate = endDate;
    }

    return CharaDasha(startSign: ascendantSign, periods: periods);
  }

  /// Calculate Chara Dasha period for a sign using Jaimini rules
  /// Period = distance from sign to its lord's position (or to Aquarius/Leo)
  static double _calculateCharaPeriod(VedicChart chart, int sign) {
    // Get the lord of this sign
    final signLord = _getSignLord(sign);

    // Find the sign where the lord is placed
    int lordSign = sign; // Default to same sign
    for (final entry in chart.planets.entries) {
      final planetName = entry.key.toString().split('.').last;
      if (planetName.toLowerCase() == signLord.toLowerCase()) {
        lordSign = (entry.value.longitude / 30).floor();
        break;
      }
    }

    // Calculate period based on Jaimini rules:
    // - Count from sign to lord's position
    // - If sign is odd (Aries, Gemini, Leo...), count forward
    // - If sign is even (Taurus, Cancer, Virgo...), count backward
    int distance;
    if (sign % 2 == 0) {
      // Odd sign (0-indexed even): count forward
      distance = ((lordSign - sign + 12) % 12) + 1;
    } else {
      // Even sign (0-indexed odd): count backward
      distance = ((sign - lordSign + 12) % 12) + 1;
    }

    // Special rule: if lord is in same sign, use the alternate calculation
    // Count to Aquarius for odd signs, Leo for even signs
    if (distance == 1 && lordSign == sign) {
      if (sign % 2 == 0) {
        // Count to Aquarius (sign 10)
        distance = ((10 - sign + 12) % 12) + 1;
      } else {
        // Count to Leo (sign 4)
        distance = ((sign - 4 + 12) % 12) + 1;
      }
    }

    // Period in years (max 12)
    return distance.toDouble().clamp(1.0, 12.0);
  }

  /// Get Moon's nakshatra index
  static int _getMoonNakshatra(VedicChart chart) {
    for (final entry in chart.planets.entries) {
      if (entry.key.toString().toLowerCase().contains('moon')) {
        return (entry.value.longitude / (360.0 / 27.0)).floor();
      }
    }
    return 0;
  }

  /// Get ascendant sign
  static int _getAscendantSign(VedicChart chart) {
    try {
      final houses = chart.houses;
      // Fixed: Use cusps list directly
      if (houses.cusps.isNotEmpty) {
        final long = houses.cusps[0];
        return (long / 30).floor();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get sign name
  static String _getSignName(int sign) {
    const names = [
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
    return names[sign % 12];
  }

  /// Get sign lord
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

  /// Get current running dasha for a date
  static Map<String, dynamic> getCurrentDasha(
    VimshottariDasha dasha,
    DateTime date,
  ) {
    for (final mahadasha in dasha.mahadashas) {
      // Use inclusive start date: date >= startDate AND date < endDate
      if (!date.isBefore(mahadasha.startDate) &&
          date.isBefore(mahadasha.endDate)) {
        for (final antardasha in mahadasha.antardashas) {
          if (!date.isBefore(antardasha.startDate) &&
              date.isBefore(antardasha.endDate)) {
            for (final pratyantardasha in antardasha.pratyantardashas) {
              if (!date.isBefore(pratyantardasha.startDate) &&
                  date.isBefore(pratyantardasha.endDate)) {
                return {
                  'mahadasha': mahadasha.lord,
                  'antardasha': antardasha.lord,
                  'pratyantardasha': pratyantardasha.lord,
                  'mahaStart': mahadasha.startDate,
                  'mahaEnd': mahadasha.endDate,
                  'antarStart': antardasha.startDate,
                  'antarEnd': antardasha.endDate,
                  'pratyanStart': pratyantardasha.startDate,
                  'pratyanEnd': pratyantardasha.endDate,
                };
              }
            }
          }
        }
      }
    }

    return {};
  }
}
