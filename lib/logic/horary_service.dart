import 'package:flutter/foundation.dart';
import 'package:jyotish/jyotish.dart';

import 'custom_chart_service.dart';

class HoraryService {
  final CustomChartService _chartService = CustomChartService();

  // Lords order for Vimshottari
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

  // Years for each lord in Vimshottari
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

  /// Main function to generate a Horary Chart
  Future<VedicChart> generateHoraryChart({
    required int seedNumber,
    required DateTime dateTime,
    required GeographicLocation location,
    String ayanamsaName = 'KP', // Default to KP
  }) async {
    if (seedNumber < 1 || seedNumber > 249) {
      throw Exception("Seed number must be between 1 and 249");
    }

    // 1. Get Target Ascendant Longitude from Seed Number
    final targetAscendant = _getAscendantForSeed(seedNumber);
    debugPrint(
      'Horary: Seed $seedNumber -> Target Ascendant: $targetAscendant',
    );

    // 2. Find "Fictional Time" that produces this Ascendant at the given location
    // We use the configured Ayanamsa (KP) for this matching.
    // For Horary, typically KP New (Krishnamurti VP291) is used.
    final ayanamsaMode = ayanamsaName == 'KP'
        ? SiderealMode.krishnamurtiVP291
        : SiderealMode.lahiri;

    // Perform search
    final fixedTime = await _findTimeForAscendant(
      targetAscendant: targetAscendant,
      approxTime: dateTime,
      location: location,
      ayanamsaMode: ayanamsaMode,
    );
    debugPrint('Horary: Fixed Time found: $fixedTime');

    // 3. Calculate Houses using Fixed Time
    // We use the CustomChartService to do the heavy lifting of house calculation
    final houseChart = await _chartService.calculateChart(
      dateTime: fixedTime,
      location: location,
      ayanamsaMode: ayanamsaMode,
      houseSystem: 'P', // Placidus for KP
    );

    // 4. Calculate Planets using Actual Time
    final planetChart = await _chartService.calculateChart(
      dateTime: dateTime,
      location: location,
      ayanamsaMode: ayanamsaMode,
    );

    // 5. Merge: Houses from houseChart, Planets from planetChart
    return VedicChart(
      dateTime: dateTime,
      location: planetChart.location,
      latitude: location.latitude,
      longitudeCoord: location.longitude,
      houses: houseChart.houses, // Use adjusted houses
      planets: planetChart.planets, // Use actual planets
      rahu: planetChart.rahu,
      ketu: planetChart.ketu,
    );
  }

  /// Binary/Newton search to find time T such that Ascendant(T) ~= Target
  Future<DateTime> _findTimeForAscendant({
    required double targetAscendant,
    required DateTime approxTime,
    required GeographicLocation location,
    required SiderealMode ayanamsaMode,
  }) async {
    // We want to find T such that Ascendant(T) = targetAscendant.
    // Ascendant moves ~360 degrees in ~24 hours (1440 mins).
    // Speed varies by sign (short/long ascension).

    DateTime currentTime = approxTime;

    // Increased max iterations for better convergence
    for (int i = 0; i < 30; i++) {
      // 1. Calculate Ascendant at current time T
      final chartT = await _chartService.calculateChart(
        dateTime: currentTime,
        location: location,
        ayanamsaMode: ayanamsaMode,
      );
      double currentAsc = chartT.houses.ascendant;

      // 2. Calculate Ascendant at T + delta (e.g. 1 minute) to find rate of change
      final deltaSeconds = 60;
      final chartTPlus = await _chartService.calculateChart(
        dateTime: currentTime.add(Duration(seconds: deltaSeconds)),
        location: location,
        ayanamsaMode: ayanamsaMode,
      );
      double nextAsc = chartTPlus.houses.ascendant;

      // Handle 360/0 crossing for rate calculation
      double ascDiff = nextAsc - currentAsc;
      if (ascDiff < -180) ascDiff += 360;
      if (ascDiff > 180) ascDiff -= 360;

      // Rate: Degrees per second
      double rate = ascDiff / deltaSeconds;

      if (rate.abs() < 1e-6) {
        // Avoiding division by zero if rate is suspiciously low
        rate = 1.0 / 240.0; // Fallback to approx 1 deg per 4 mins (240s)
      }

      // 3. Calculate Difference from Target
      double diff = targetAscendant - currentAsc;

      // Normalize diff to -180 to 180 (Shortest path)
      while (diff > 180) {
        diff -= 360;
      }
      while (diff < -180) {
        diff += 360;
      }

      // Check for convergence
      if (diff.abs() < 0.0001) {
        return currentTime;
      }

      // 4. Estimate time correction
      // diff (deg) / rate (deg/sec) = seconds needed
      double correctionSeconds = diff / rate;

      currentTime = currentTime.add(
        Duration(milliseconds: (correctionSeconds * 1000).round()),
      );
    }

    return currentTime;
  }

  /// Calculates the starting longitude (0-360) for a given KP number (1-249).
  /// Based on the standard division of the zodiac into 249 parts.
  double _getAscendantForSeed(int seed) {
    // We need to generate the table dynamically or check a lookup.
    // Dynamic generation is safer and cleaner than constants.

    int currentSeed = 1;
    double currentLongitude = 0.0;

    // Period total for proportion
    const int vimshottariTotal = 120;

    // Iterate 12 Signs
    // Actually, easier to iterate 27 Nakshatras
    // Each Nakshatra = 13deg 20min = 800 minutes

    for (int nakshatraIdx = 0; nakshatraIdx < 27; nakshatraIdx++) {
      String starLord = _getNakshatraLord(nakshatraIdx);
      // Find index of starLord in Vimshottari list to start sub-lords sequence
      int startIdx = vimshottariLords.indexOf(starLord);

      // Sub-lords cycle through all 9 planets starting from Star Lord
      for (int i = 0; i < 9; i++) {
        String subLord = vimshottariLords[(startIdx + i) % 9];

        // Calculate span of this sub
        // Span = (SubLordYears / 120) * NakshatraSpan(13.333 deg)
        double span =
            (periodYears[subLord]! / vimshottariTotal) * (13 + (20 / 60));

        // If this is the requested seed, return the MIDDLE of the sub (or start?)
        // Usually Horary Asc matches the *Start* of the arc, but strictly speaking
        // the seed represents the *span*.
        // Most software sets the Ascendant to the *Start* of the seed's region?
        // Or maybe the *exact center*?
        // "The Ascendant is set to the beginning of the sub-sub portion..." -> No,
        // seed 1 corresponds to 00 Aries 00. So Start of the region.
        if (currentSeed == seed) {
          // Return start longitude + small epsilon? Or just start.
          // To be safe, let's return the Start + 1 second to ensure it falls strictly inside.
          return currentLongitude + (1.0 / 3600.0);
        }

        currentLongitude += span;
        currentSeed++;
      }
    }

    return 0.0; // Fallback, shouldn't reach
  }

  String _getNakshatraLord(int index) {
    // 0: Ashwini (Ketu), 1: Bharani (Venus)...
    return vimshottariLords[index % 9];
  }
}
