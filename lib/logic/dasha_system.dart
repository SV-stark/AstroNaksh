import 'package:jyotish/jyotish.dart';
import '../data/models.dart';

/// Complete Dasha System Implementation
/// Includes Vimshottari, Yogini, and Chara Dasha
class DashaSystem {
  static DashaService? _service;

  /// Calculate Vimshottari Dasha for a birth chart
  /// Returns the complete Dasha tree (Mahadasha, Antardasha, Pratyantardasha)
  static VimshottariDasha calculateVimshottariDasha(VedicChart chart) {
    _service ??= DashaService();

    // Calculate 3 levels (Maha, Antar, Pratyantar)
    final result = _service!.calculateVimshottariDasha(
      moonLongitude: chart.getPlanet(Planet.moon)?.longitude ?? 0,
      birthDateTime: chart.dateTime,
      levels: 3,
    );

    return _mapToVimshottari(result);
  }

  static VimshottariDasha _mapToVimshottari(DashaResult result) {
    return VimshottariDasha(
      birthLord: result.allMahadashas.first.lord?.displayName ?? '--',
      balanceAtBirth: result.balanceOfFirstDasha / 365.25,
      mahadashas: result.allMahadashas
          .map(
            (m) => Mahadasha(
              lord: m.lord?.displayName ?? '--',
              startDate: m.startDate,
              endDate: m.endDate,
              periodYears: m.durationYears,
              antardashas: m.subPeriods
                  .map(
                    (a) => Antardasha(
                      lord: a.lord?.displayName ?? '--',
                      startDate: a.startDate,
                      endDate: a.endDate,
                      periodYears: a.durationYears,
                      pratyantardashas: a.subPeriods
                          .map(
                            (p) => Pratyantardasha(
                              mahadashaLord: m.lord?.displayName ?? '--',
                              antardashaLord: a.lord?.displayName ?? '--',
                              lord: p.lord?.displayName ?? '--',
                              startDate: p.startDate,
                              endDate: p.endDate,
                              periodYears: p.durationYears,
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }

  /// Calculate Yogini Dasha
  /// 36-year cycle with 8 yoginis
  static YoginiDasha calculateYoginiDasha(VedicChart chart) {
    _service ??= DashaService();

    final result = _service!.calculateYoginiDasha(
      moonLongitude: chart.getPlanet(Planet.moon)?.longitude ?? 0,
      birthDateTime: chart.dateTime,
      levels: 1, // local model only supports Mahadashas for Yogini
    );

    return YoginiDasha(
      startYogini: result.allMahadashas.first.lord?.displayName ?? '--',
      mahadashas: result.allMahadashas
          .map(
            (m) => YoginiMahadasha(
              name: m.lord?.displayName ?? '--',
              lord: _getYoginiPlanetLord(m.lord),
              startDate: m.startDate,
              endDate: m.endDate,
              periodYears: m.durationYears,
            ),
          )
          .toList(),
    );
  }

  static String _getYoginiPlanetLord(Planet? yoginiPlanet) {
    return yoginiPlanet?.displayName ?? '--';
  }

  /// Convert years to Duration (preserves fractional days as hours)
  static Duration _yearsToDuration(double years) {
    final totalDays = years * 365.25;
    final wholeDays = totalDays.floor();
    final fractionalHours = ((totalDays - wholeDays) * 24).round();
    return Duration(days: wholeDays, hours: fractionalHours);
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
          signName: AstrologyConstants.getSignName(signIndex),
          lord: AstrologyConstants.getSignLord(signIndex),
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
    final signLord = AstrologyConstants.getSignLord(sign);

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

  /// Get sign lord
  static String getSignLord(int sign) => AstrologyConstants.getSignLord(sign);

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
