import 'package:flutter/foundation.dart';
import 'package:jyotish/jyotish.dart';

import '../core/ephemeris_manager.dart';

class HoraryService {
  static const List<String> vimshottariLords = [
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

  static const Map<String, int> periodYears = {
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

  Future<VedicChart> generateHoraryChart({
    required int seedNumber,
    required DateTime dateTime,
    required GeographicLocation location,
    String ayanamsaName = 'KP',
  }) async {
    if (seedNumber < 1 || seedNumber > 249) {
      throw Exception('Seed number must be between 1 and 249');
    }

    final targetAscendant = _getAscendantForSeed(seedNumber);
    debugPrint(
      'Horary: Seed $seedNumber -> Target Ascendant: $targetAscendant',
    );

    final ayanamsaMode = ayanamsaName == 'KP'
        ? SiderealMode.krishnamurtiVP291
        : SiderealMode.lahiri;

    final fixedTime = await _findTimeForAscendant(
      targetAscendant: targetAscendant,
      approxTime: dateTime,
      location: location,
      ayanamsaMode: ayanamsaMode,
    );
    debugPrint('Horary: Fixed Time found: $fixedTime');

    final kpFlags = CalculationFlags.kp();

    final houseChart = await EphemerisManager.jyotish.calculateVedicChart(
      dateTime: fixedTime,
      location: location,
      houseSystem: 'P',
      flags: kpFlags,
    );

    final planetChart = await EphemerisManager.jyotish.calculateVedicChart(
      dateTime: dateTime,
      location: location,
      houseSystem: 'P',
      flags: kpFlags,
    );

    return VedicChart(
      dateTime: dateTime,
      location: planetChart.location,
      latitude: location.latitude,
      longitudeCoord: location.longitude,
      houses: houseChart.houses,
      planets: planetChart.planets,
      rahu: planetChart.rahu,
      ketu: planetChart.ketu,
      calculationFlags: houseChart.calculationFlags,
    );
  }

  Future<DateTime> _findTimeForAscendant({
    required double targetAscendant,
    required DateTime approxTime,
    required GeographicLocation location,
    required SiderealMode ayanamsaMode,
  }) async {
    var currentTime = approxTime;

    for (var i = 0; i < 30; i++) {
      final chartT = await EphemerisManager.jyotish.calculateVedicChart(
        dateTime: currentTime,
        location: location,
        houseSystem: 'P',
        flags: ayanamsaMode == SiderealMode.krishnamurtiVP291
            ? CalculationFlags.kp()
            : CalculationFlags(
                siderealMode: ayanamsaMode,
                nodeType: NodeType.meanNode,
              ),
      );
      final currentAsc = chartT.houses.ascendant;

      const deltaSeconds = 60;
      final chartTPlus = await EphemerisManager.jyotish.calculateVedicChart(
        dateTime: currentTime.add(const Duration(seconds: deltaSeconds)),
        location: location,
        houseSystem: 'P',
        flags: ayanamsaMode == SiderealMode.krishnamurtiVP291
            ? CalculationFlags.kp()
            : CalculationFlags(
                siderealMode: ayanamsaMode,
                nodeType: NodeType.meanNode,
              ),
      );
      final nextAsc = chartTPlus.houses.ascendant;

      var ascDiff = nextAsc - currentAsc;
      if (ascDiff < -180) ascDiff += 360;
      if (ascDiff > 180) ascDiff -= 360;

      var rate = ascDiff / deltaSeconds;

      if (rate.abs() < 1e-6) {
        rate = 1.0 / 240.0;
      }

      var diff = targetAscendant - currentAsc;

      while (diff > 180) {
        diff -= 360;
      }
      while (diff < -180) {
        diff += 360;
      }

      if (diff.abs() < 0.0001) {
        return currentTime;
      }

      final correctionSeconds = diff / rate;

      currentTime = currentTime.add(
        Duration(milliseconds: (correctionSeconds * 1000).round()),
      );
    }

    return currentTime;
  }

  double _getAscendantForSeed(int seed) {
    var currentSeed = 1;
    var currentLongitude = 0.0;

    const vimshottariTotal = 120;

    for (var nakshatraIdx = 0; nakshatraIdx < 27; nakshatraIdx++) {
      final starLord = _getNakshatraLord(nakshatraIdx);
      final startIdx = vimshottariLords.indexOf(starLord);

      for (var i = 0; i < 9; i++) {
        final subLord = vimshottariLords[(startIdx + i) % 9];

        final span =
            (periodYears[subLord]! / vimshottariTotal) * (13 + (20 / 60));

        if (currentSeed == seed) {
          return currentLongitude + (1.0 / 3600.0);
        }

        currentLongitude += span;
        currentSeed++;
      }
    }

    return 0.0;
  }

  String _getNakshatraLord(int index) {
    return vimshottariLords[index % 9];
  }
}
