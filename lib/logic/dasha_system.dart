import 'package:jyotish/jyotish.dart';

import '../core/ephemeris_manager.dart';
import '../data/models.dart';

/// Complete Dasha System Implementation
/// Includes Vimshottari, Yogini, and Chara Dasha
class DashaSystem {
  static Future<VimshottariDasha> calculateVimshottariDasha(
    VedicChart chart,
  ) async {
    try {
      final result = await EphemerisManager.jyotish.getVimshottariDasha(
        natalChart: chart,
        levels: 3,
      );

      return _mapToVimshottari(result);
    } catch (e) {
      return VimshottariDasha(
        birthLord: '--',
        balanceAtBirth: 0,
        mahadashas: [],
      );
    }
  }

  static VimshottariDasha _mapToVimshottari(DashaResult result) {
    if (result.allMahadashas.isEmpty) {
      return VimshottariDasha(
        birthLord: '--',
        balanceAtBirth: 0,
        mahadashas: [],
      );
    }
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

  static Future<YoginiDasha> calculateYoginiDasha(VedicChart chart) async {
    try {
      final result = await EphemerisManager.jyotish.getYoginiDasha(
        natalChart: chart,
        levels: 3,
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
    } catch (e) {
      return YoginiDasha(
        startYogini: '--',
        mahadashas: [],
      );
    }
  }

  static String _getYoginiPlanetLord(Planet? yoginiPlanet) {
    return yoginiPlanet?.displayName ?? '--';
  }

  static Future<CharaDasha> calculateCharaDasha(VedicChart chart) async {
    try {
      await EphemerisManager.ensureEphemerisData();
      final result = await EphemerisManager.jyotish.getCharaDasha(
        natalChart: chart,
        levels: 2,
      );
      return _mapToCharaDasha(result);
    } catch (e) {
      return CharaDasha(startSign: 0, periods: []);
    }
  }

  static Future<NarayanaDasha> calculateNarayanaDasha(VedicChart chart) async {
    try {
      await EphemerisManager.ensureEphemerisData();
      final result = await EphemerisManager.jyotish.getNarayanaDasha(
        chart: chart,
        levels: 2,
      );
      return _mapToNarayanaDasha(result);
    } catch (e) {
      return NarayanaDasha(startSign: 0, periods: []);
    }
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
          lord: AstrologyConstants.getSignLord(signIndex).displayName,
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
          lord: AstrologyConstants.getSignLord(signIndex).displayName,
          startDate: p.startDate,
          endDate: p.endDate,
          periodYears: p.durationYears,
        );
      }).toList(),
    );
  }

  static Future<AshtottariDasha> calculateAshtottariDasha(
    VedicChart chart,
  ) async {
    try {
      final result = await EphemerisManager.jyotish.getAshtottariDasha(
        natalChart: chart,
        forceCalculation: true,
      );
      return AshtottariDasha(
        birthNakshatra: result.birthNakshatra,
        balanceOfFirstDasha: result.balanceOfFirstDasha / 365.25,
        mahadashas: result.allMahadashas.map((p) {
          return AshtottariMahadasha(
            lord: p.lord!,
            lordName: p.lord?.displayName ?? p.lordName ?? '--',
            startDate: p.startDate,
            endDate: p.endDate,
            periodYears: p.durationYears,
          );
        }).toList(),
      );
    } catch (e) {
      return AshtottariDasha(
        birthNakshatra: '--',
        balanceOfFirstDasha: 0,
        mahadashas: [],
      );
    }
  }

  static Future<KalachakraDasha> calculateKalachakraDasha(
    VedicChart chart,
  ) async {
    try {
      final result = await EphemerisManager.jyotish.getKalachakraDasha(
        natalChart: chart,
      );
      return KalachakraDasha(
        birthNakshatra: result.birthNakshatra,
        mahadashas: result.allMahadashas.map((p) {
          return KalachakraMahadasha(
            rashi: p.rashi!,
            signName: p.rashi?.name ?? '',
            startDate: p.startDate,
            endDate: p.endDate,
            periodYears: p.durationYears,
          );
        }).toList(),
      );
    } catch (e) {
      return KalachakraDasha(
        birthNakshatra: '--',
        mahadashas: [],
      );
    }
  }

  static Future<Map<String, dynamic>> getCurrentDashaFromChart(
    VedicChart natalChart,
    DateTime date,
  ) async {
    try {
      final current = await EphemerisManager.jyotish.getVimshottariDasha(
        natalChart: natalChart,
        levels: 3,
      );

      for (final md in current.allMahadashas) {
        if (date.isBefore(md.startDate) || !date.isBefore(md.endDate)) continue;
        for (final ad in md.subPeriods) {
          if (date.isBefore(ad.startDate) || !date.isBefore(ad.endDate)) {
            continue;
          }
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
    } catch (e) {
      // Return empty if calculation fails
    }
    return {};
  }

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
