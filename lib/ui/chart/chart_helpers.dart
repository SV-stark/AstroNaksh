import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' as m;
import 'package:jyotish/core.dart';

import '../../core/chart_customization.dart';
import '../../core/constants.dart';
import '../../data/models.dart';

class ChartHelpers {
  /// Separation from the Sun, in degrees, within which a planet is combust.
  static const double combustionOrb = 14.0;

  /// Exaltation sign index per two-letter planet abbreviation.
  static const Map<String, int> exaltationTable = {
    'Su': 0, // Aries
    'Mo': 1, // Taurus
    'Me': 5, // Libra
    'Ve': 11, // Pisces
    'Ma': 9, // Capricorn
    'Ju': 3, // Cancer
    'Sa': 6, // Libra
  };

  /// Builds the sign -> planet labels map consumed by the chart painters.
  ///
  /// [options] carries the display toggles from Settings; when omitted the
  /// defaults apply. Formatting here is what makes "Show Degrees", "Show
  /// Retrograde", "Show Nakshatras", "Show Combust" and "Show Exalted/Debilitated"
  /// take effect instead of being write-only settings.
  static Map<int, List<String>> getPlanetsMap(
    VedicChart chart, [
    ChartCustomization? options,
  ]) {
    final settings = options ?? ChartCustomization();
    final map = <int, List<String>>{};
    final ascSign = getAscendantSignInt(chart);

    final sunEntry = chart.planets.entries.where((e) => e.key == Planet.sun);
    final sunLongitude = sunEntry.isEmpty
        ? null
        : sunEntry.first.value.longitude;

    void place(String label, double longitude, {required bool isRetrograde}) {
      final sign = ((longitude % 360) / 30).floor() + 1; // 1-12
      map
          .putIfAbsent(sign, () => [])
          .add(
            formatLabel(
              label: label,
              longitude: longitude,
              isRetrograde: isRetrograde,
              settings: settings,
              sunLongitude: sunLongitude,
            ),
          );
    }

    chart.planets.forEach((planet, info) {
      final planetName = planet.toString().split('.').last;
      place(
        AppConstants.getPlanetAbbreviation(planetName),
        info.longitude,
        isRetrograde: info.isRetrograde,
      );
    });

    // Rahu / Ketu are conventionally shown retrograde.
    place('Ra', chart.rahu.longitude, isRetrograde: true);
    place('Ke', chart.ketu.longitude, isRetrograde: true);

    map.putIfAbsent(ascSign, () => []).add('Asc');
    return map;
  }

  /// Renders one planet label honouring the toggles in [settings].
  static String formatLabel({
    required String label,
    required double longitude,
    required bool isRetrograde,
    required ChartCustomization settings,
    double? sunLongitude,
  }) {
    final normalized = longitude % 360;
    final buffer = StringBuffer(label);

    if (settings.showDegrees) {
      buffer.write(' ${_formatDegree(normalized % 30)}');
    }

    if (settings.showNakshatras) {
      final index = (normalized / 13.333333).floor().clamp(0, 26);
      final nakshatra = AppConstants.nakshatras[index];
      buffer.write(' ${nakshatra.substring(0, 3)}');
    }

    if (settings.showExaltedDebilitated) {
      final marker = _dignityMarker(label, normalized);
      if (marker != null) buffer.write(marker);
    }

    if (settings.showCombust && !isRetrograde) {
      if (sunLongitude != null && _isCombust(normalized, sunLongitude)) {
        buffer.write('*');
      }
    }

    if (settings.showRetrograde && isRetrograde) {
      buffer.write('(R)');
    }

    return buffer.toString();
  }

  static bool _isCombust(double longitude, double sunLongitude) {
    final separation = (longitude - sunLongitude).abs() % 360;
    final orb = separation > 180 ? 360 - separation : separation;
    return orb <= combustionOrb;
  }

  /// `'Ex'` for exalted, `'Deb'` for debilitated, otherwise `null`.
  static String? _dignityMarker(String label, double longitude) {
    final exaltation = exaltationTable[label];
    if (exaltation == null) return null;
    final signIndex = (longitude / 30).floor().clamp(0, 11);
    if (signIndex == exaltation) return 'Ex';
    if (signIndex == (exaltation + 6) % 12) return 'Deb';
    return null;
  }

  /// Degrees and arc-minutes within the sign, e.g. `5°30'`.
  static String _formatDegree(double degreeInSign) {
    final d = degreeInSign.floor();
    final m = ((degreeInSign - d) * 60).floor();
    // The arc-minute mark is required, otherwise `5°30` is ambiguous.
    return "$d\u00b0${m.toString().padLeft(2, '0')}'";
  }

  static Map<int, List<String>> getDivisionalPlanetsMap(
    DivisionalChartData chart,
  ) {
    final map = <int, List<String>>{};
    chart.positions.forEach((planetName, longitude) {
      final sign = (longitude / 30).floor() + 1; // 1-12

      var abbr = planetName.length > 2
          ? planetName.substring(0, 2)
          : planetName;
      if (planetName == 'Mars') abbr = 'Ma';
      if (planetName == 'Mercury') abbr = 'Me';
      if (planetName == 'Jupiter') abbr = 'Ju';
      if (planetName == 'Venus') abbr = 'Ve';
      if (planetName == 'Saturn') abbr = 'Sa';
      if (planetName == 'Rahu') abbr = 'Ra';
      if (planetName == 'Ketu') abbr = 'Ke';
      if (planetName == 'Sun') abbr = 'Su';
      if (planetName == 'Moon') abbr = 'Mo';

      map.putIfAbsent(sign, () => []).add(abbr);
    });
    // Ascendant
    if (chart.ascendantSign != null) {
      map.putIfAbsent(chart.ascendantSign!, () => []).add('Asc');
    }
    return map;
  }

  static int getAscendantSignInt(VedicChart chart) {
    final index = AstrologyConstants.signNames.indexOf(chart.ascendantSign);
    if (index != -1) {
      return index + 1;
    }
    return 1; // Default Aries
  }

  static String getAscendantSign(VedicChart chart) {
    return chart.ascendantSign;
  }

  static String formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  static String getSignName(int signNumber) {
    final signs = [
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
    if (signNumber >= 1 && signNumber <= 12) {
      return signs[signNumber - 1];
    }
    return 'Unknown';
  }

  static TableRow buildRahuKetuTableRow({
    required String name,
    required double longitude,
    required VedicChart chart,
    required List<String> nakshatras,
    required BuildContext context,
  }) {
    // Sign (1-12)
    final signIndex = (longitude / 30).floor();
    final signName = getSignName(signIndex + 1);

    // Degrees within sign
    final degInSign = longitude % 30;
    final degrees = degInSign.floor();
    final minutes = ((degInSign - degrees) * 60).floor();
    final seconds = (((degInSign - degrees) * 60 - minutes) * 60).round();
    final degStr =
        '${degrees.toString().padLeft(2, '0')}°${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';

    // Nakshatra (each is 13°20' = 13.333...)
    final nakshatraIndex = (longitude / 13.333333).floor() % 27;
    final nakshatraName = nakshatras[nakshatraIndex];

    // Pada (4 padas per nakshatra, each 3°20' = 3.333...)
    final padaInNakshatra = ((longitude % 13.333333) / 3.333333).floor() + 1;

    // House (approximate based on sign difference from ascendant)
    final ascSign = getAscendantSignInt(chart);
    final house = ((signIndex + 1) - ascSign + 12) % 12 + 1;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(name),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(signName),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(degStr),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(nakshatraName),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('$padaInNakshatra'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('$house'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(''), // Rahu/Ketu are never retrograde
        ),
      ],
    );
  }

  static Widget buildPlanetPositionsTable({
    required CompleteChartData data,
    required BuildContext context,
  }) {
    final planets = data.baseChart.planets;
    const nakshatras = AppConstants.nakshatras;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planet Positions',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(0.6),
                5: FlexColumnWidth(0.6),
                6: FlexColumnWidth(0.8),
              },
              children: [
                const TableRow(
                  children: [
                    Text(
                      'Planet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Sign', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'Degrees',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Nakshatra',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Pada', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'House',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const TableRow(
                  children: [
                    SizedBox(height: 8),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                  ],
                ),
                // Divider Row
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: FluentTheme.of(
                          context,
                        ).resources.dividerStrokeColorDefault,
                      ),
                    ),
                  ),
                  children: List.filled(7, const SizedBox(height: 4)),
                ),
                const TableRow(
                  children: [
                    SizedBox(height: 8),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                  ],
                ),
                ...planets.entries.map((entry) {
                  final planetName = entry.key.toString().split('.').last;
                  final info = entry.value;
                  final longitude = info.longitude;

                  // Sign (1-12)
                  final signIndex = (longitude / 30).floor();
                  final signName = getSignName(signIndex + 1);

                  // Degrees within sign
                  final degInSign = longitude % 30;
                  final degrees = degInSign.floor();
                  final minutes = ((degInSign - degrees) * 60).floor();
                  final seconds = (((degInSign - degrees) * 60 - minutes) * 60)
                      .round();
                  final degStr =
                      '${degrees.toString().padLeft(2, '0')}°${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';

                  // Nakshatra
                  final nakshatraIndex = (longitude / 13.333333).floor() % 27;
                  final nakshatraName = nakshatras[nakshatraIndex];

                  // Pada
                  final padaInNakshatra =
                      ((longitude % 13.333333) / 3.333333).floor() + 1;

                  // House
                  final ascSign = getAscendantSignInt(data.baseChart);
                  final house = ((signIndex + 1) - ascSign + 12) % 12 + 1;

                  // Status (retrograde / combustion / etc)
                  var status = '';
                  if (info.isRetrograde) {
                    status += 'Retrograde';
                  }

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(planetName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(signName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(degStr),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(nakshatraName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('$padaInNakshatra'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('$house'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: info.isRetrograde
                                ? m.Colors.orange
                                : m.Colors.green,
                            fontWeight: info.isRetrograde
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                // Add Rahu
                buildRahuKetuTableRow(
                  name: 'Rahu',
                  longitude: data.baseChart.rahu.longitude,
                  chart: data.baseChart,
                  nakshatras: nakshatras,
                  context: context,
                ),
                // Add Ketu
                buildRahuKetuTableRow(
                  name: 'Ketu',
                  longitude: data.baseChart.ketu.longitude,
                  chart: data.baseChart,
                  nakshatras: nakshatras,
                  context: context,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
