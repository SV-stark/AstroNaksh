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
      throw Exception("Seed number must be between 1 and 249");
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

    final houseChart = await EphemerisManager.jyotish.calculateVedicChart(
      dateTime: fixedTime,
      location: location,
      houseSystem: 'P',
      flags: CalculationFlags.kp(),
    );

    final planetChart = await EphemerisManager.jyotish.calculateVedicChart(
      dateTime: dateTime,
      location: location,
      houseSystem: 'P',
      flags: CalculationFlags.kp(),
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
    );
  }

  Future<DateTime> _findTimeForAscendant({
    required double targetAscendant,
    required DateTime approxTime,
    required GeographicLocation location,
    required SiderealMode ayanamsaMode,
  }) async {
    DateTime currentTime = approxTime;

    for (int i = 0; i < 30; i++) {
      final chartT = await EphemerisManager.jyotish.calculateVedicChart(
        dateTime: currentTime,
        location: location,
        houseSystem: 'P',
        flags: CalculationFlags(
          siderealMode: ayanamsaMode,
          nodeType: NodeType.meanNode,
        ),
      );
      double currentAsc = chartT.houses.ascendant;

      final deltaSeconds = 60;
      final chartTPlus = await EphemerisManager.jyotish.calculateVedicChart(
        dateTime: currentTime.add(Duration(seconds: deltaSeconds)),
        location: location,
        houseSystem: 'P',
        flags: CalculationFlags(
          siderealMode: ayanamsaMode,
          nodeType: NodeType.meanNode,
        ),
      );
      double nextAsc = chartTPlus.houses.ascendant;

      double ascDiff = nextAsc - currentAsc;
      if (ascDiff < -180) ascDiff += 360;
      if (ascDiff > 180) ascDiff -= 360;

      double rate = ascDiff / deltaSeconds;

      if (rate.abs() < 1e-6) {
        rate = 1.0 / 240.0;
      }

      double diff = targetAscendant - currentAsc;

      while (diff > 180) {
        diff -= 360;
      }
      while (diff < -180) {
        diff += 360;
      }

      if (diff.abs() < 0.0001) {
        return currentTime;
      }

      double correctionSeconds = diff / rate;

      currentTime = currentTime.add(
        Duration(milliseconds: (correctionSeconds * 1000).round()),
      );
    }

    return currentTime;
  }

  double _getAscendantForSeed(int seed) {
    int currentSeed = 1;
    double currentLongitude = 0.0;

    const int vimshottariTotal = 120;

    for (int nakshatraIdx = 0; nakshatraIdx < 27; nakshatraIdx++) {
      String starLord = _getNakshatraLord(nakshatraIdx);
      int startIdx = vimshottariLords.indexOf(starLord);

      for (int i = 0; i < 9; i++) {
        String subLord = vimshottariLords[(startIdx + i) % 9];

        double span =
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
