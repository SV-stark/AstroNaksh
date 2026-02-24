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
      levels: 3, // Enable Antar and Pratyantar
    );

    return YoginiDasha(
      startYogini: result.allMahadashas.first.lordName ?? '--',
      mahadashas: result.allMahadashas
          .map(
            (m) => YoginiMahadasha(
              name: m.lordName ?? m.lord?.displayName ?? '--',
              lord: _getYoginiPlanetLord(m.lord),
              startDate: m.startDate,
              endDate: m.endDate,
              periodYears: m.durationYears,
              antardashas: m.subPeriods
                  .map(
                    (a) => YoginiAntardasha(
                      name: a.lordName ?? a.lord?.displayName ?? '--',
                      lord: _getYoginiPlanetLord(a.lord),
                      startDate: a.startDate,
                      endDate: a.endDate,
                      pratyantardashas: a.subPeriods
                          .map(
                            (p) => YoginiPratyantardasha(
                              name: p.lordName ?? p.lord?.displayName ?? '--',
                              lord: _getYoginiPlanetLord(p.lord),
                              startDate: p.startDate,
                              endDate: p.endDate,
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

  static String _getYoginiPlanetLord(Planet? yoginiPlanet) {
    return yoginiPlanet?.displayName ?? '--';
  }

  /// Calculate Chara Dasha (Jaimini System) using native library
  static Future<CharaDasha> calculateCharaDasha(VedicChart chart) async {
    _service ??= DashaService();
    // Library returns CharaDashaResult
    final result = _service!.calculateCharaDasha(chart, levels: 2);
    return _mapToCharaDasha(result);
  }

  /// Calculate Narayana Dasha (Jaimini System)
  static Future<NarayanaDasha> calculateNarayanaDasha(VedicChart chart) async {
    _service ??= DashaService();
    // Library returns NarayanaDashaResult
    final result = _service!.getNarayanaDasha(chart, levels: 2);
    return _mapToNarayanaDasha(result);
  }

  static CharaDasha _mapToCharaDasha(DashaResult result) {
    return CharaDasha(
      startSign:
          result.allMahadashas.isNotEmpty &&
              result.allMahadashas.first.rashi != null
          ? result.allMahadashas.first.rashi!.number
          : 0,
      periods: result.allMahadashas.map((p) {
        final signIndex = p.rashi?.number ?? 0;
        return CharaDashaPeriod(
          sign: signIndex,
          signName: p.rashi?.name ?? '',
          lord: AstrologyConstants.getSignLord(signIndex),
          startDate: p.startDate,
          endDate: p.endDate,
          periodYears: p.durationYears,
        );
      }).toList(),
    );
  }

  static NarayanaDasha _mapToNarayanaDasha(DashaResult result) {
    return NarayanaDasha(
      startSign:
          result.allMahadashas.isNotEmpty &&
              result.allMahadashas.first.rashi != null
          ? result.allMahadashas.first.rashi!.number
          : 0,
      periods: result.allMahadashas.map((p) {
        final signIndex = p.rashi?.number ?? 0;
        return NarayanaDashaPeriod(
          sign: signIndex,
          signName: p.rashi?.name ?? '',
          lord: AstrologyConstants.getSignLord(signIndex),
          startDate: p.startDate,
          endDate: p.endDate,
          periodYears: p.durationYears,
        );
      }).toList(),
    );
  }

  /// Get current running dasha for a date (Vimshottari).
  /// Delegates to the jyotish library's [DashaService] via the cached service
  /// so we avoid reimplementing the nested-period search manually.
  static Map<String, dynamic> getCurrentDashaFromChart(
    VedicChart natalChart,
    DateTime date,
  ) {
    _service ??= DashaService();
    // Library returns the active DashaPeriod directly
    final current = _service!.calculateVimshottariDasha(
      moonLongitude: natalChart.getPlanet(Planet.moon)?.longitude ?? 0,
      birthDateTime: natalChart.dateTime,
      levels: 3,
    );

    // Walk the result to find the active period at [date]
    for (final md in current.allMahadashas) {
      if (date.isBefore(md.startDate) || !date.isBefore(md.endDate)) continue;
      for (final ad in md.subPeriods) {
        if (date.isBefore(ad.startDate) || !date.isBefore(ad.endDate)) continue;
        for (final pd in ad.subPeriods) {
          if (date.isBefore(pd.startDate) || !date.isBefore(pd.endDate)) {
            continue;
          }
          return {
            'mahadasha': md.lord?.displayName ?? '--',
            'antardasha': ad.lord?.displayName ?? '--',
            'pratyantardasha': pd.lord?.displayName ?? '--',
            'mahaStart': md.startDate,
            'mahaEnd': md.endDate,
            'antarStart': ad.startDate,
            'antarEnd': ad.endDate,
            'pratyanStart': pd.startDate,
            'pratyanEnd': pd.endDate,
          };
        }
      }
    }
    return {};
  }

  /// Get current running dasha from pre-computed [VimshottariDasha] model.
  /// Use [getCurrentDashaFromChart] when you have a live [VedicChart] instead.
  static Map<String, dynamic> getCurrentDasha(
    VimshottariDasha dasha,
    DateTime date,
  ) {
    for (final mahadasha in dasha.mahadashas) {
      if (date.isBefore(mahadasha.startDate) ||
          !date.isBefore(mahadasha.endDate)) {
        continue;
      }
      for (final antardasha in mahadasha.antardashas) {
        if (date.isBefore(antardasha.startDate) ||
            !date.isBefore(antardasha.endDate)) {
          continue;
        }
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
    return {};
  }
}
