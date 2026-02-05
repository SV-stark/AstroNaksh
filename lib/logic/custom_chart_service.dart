import 'package:jyotish/jyotish.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import '../core/ephemeris_manager.dart';
import '../core/ayanamsa_calculator.dart';

/// Service for calculating Vedic astrology charts with custom Ayanamsa.
/// Replicates logic from [VedicChartService] but allows configurable SiderealMode.
class CustomChartService {
  /// Gets the shared, initialized EphemerisService
  Future<EphemerisService> _getEphemerisService() async {
    // Ensure manager is initialized
    await EphemerisManager.ensureEphemerisData();
    return EphemerisManager.service;
  }

  /// Calculates a complete Vedic astrology chart with specific Ayanamsa.
  Future<VedicChart> calculateChart({
    required DateTime dateTime,
    required GeographicLocation location,
    required SiderealMode ayanamsaMode,
    double? overrideAyanamsa,
    String? timezone,
    String houseSystem = 'W', // Whole Sign by default
    bool includeOuterPlanets = false,
  }) async {
    try {
      // Get initialized ephemeris service
      final ephemerisService = await _getEphemerisService();

      // Convert time to UTC based on location timezone
      DateTime utcDateTime = dateTime;
      if (timezone != null && timezone.isNotEmpty) {
        try {
          final locationTz = tz.getLocation(timezone);
          // Create TZDateTime using the input components
          final tzDateTime = tz.TZDateTime(
            locationTz,
            dateTime.year,
            dateTime.month,
            dateTime.day,
            dateTime.hour,
            dateTime.minute,
            dateTime.second,
          );
          utcDateTime = tzDateTime.toUtc();
        } catch (e) {
          debugPrint('Error converting timezone: $e');
          // Fallback: use input as is, possibly wrong if not UTC
        }
      }

      // Determine flags and ayanamsa to use
      CalculationFlags flags;

      if (overrideAyanamsa != null) {
        // Use Tropical for initial calculation, then manually adjust
        flags = CalculationFlags.defaultFlags();
      } else {
        // Use standard engine calculation
        flags = CalculationFlags.sidereal(ayanamsaMode);
      }

      // Calculate Ascendant and house cusps
      final houses = await _calculateHouses(
        ephemerisService: ephemerisService,
        dateTime: utcDateTime,
        location: location,
        houseSystem: houseSystem,
        ayanamsaMode: ayanamsaMode,
        overrideAyanamsa: overrideAyanamsa,
      );

      // Get list of planets to calculate
      final planetsToCalculate = includeOuterPlanets
          ? Planet.majorPlanets
          : Planet.traditionalPlanets;

      // Calculate all planetary positions
      final planetPositions = <Planet, PlanetPosition>{};
      for (final planet in planetsToCalculate) {
        var position = await ephemerisService.calculatePlanetPosition(
          planet: planet,
          dateTime: utcDateTime,
          location: location,
          flags: flags,
        );

        // If overriding, we need to subtract ayanamsa from the tropical position obtained
        if (overrideAyanamsa != null) {
          final correctedLongitude = AyanamsaCalculator.tropicalToSidereal(
            position.longitude,
            overrideAyanamsa,
          );

          // Reconstruct with corrected longitude
          // Derived fields like zodiacSign and nakshatra are getters in PlanetPosition
          // so they will be automatically recalculated based on the new longitude!
          position = PlanetPosition(
            planet: position.planet,
            dateTime: position.dateTime,
            longitude: correctedLongitude,
            latitude: position.latitude,
            distance: position.distance,
            longitudeSpeed: position.longitudeSpeed,
            latitudeSpeed: position.latitudeSpeed,
            distanceSpeed: position.distanceSpeed,
            isCombust: position.isCombust,
          );
        }

        planetPositions[planet] = position;
      }

      // Calculate Rahu (Mean Node)
      var rahuPosition = await ephemerisService.calculatePlanetPosition(
        planet: Planet.meanNode,
        dateTime: utcDateTime,
        location: location,
        flags: flags,
      );

      if (overrideAyanamsa != null) {
        final correctedLongitude = AyanamsaCalculator.tropicalToSidereal(
          rahuPosition.longitude,
          overrideAyanamsa,
        );
        rahuPosition = PlanetPosition(
          planet: rahuPosition.planet,
          dateTime: rahuPosition.dateTime,
          longitude: correctedLongitude,
          latitude: rahuPosition.latitude,
          distance: rahuPosition.distance,
          longitudeSpeed: rahuPosition.longitudeSpeed,
          latitudeSpeed: rahuPosition.latitudeSpeed,
          distanceSpeed: rahuPosition.distanceSpeed,
          isCombust: rahuPosition.isCombust,
        );
      }

      // Create Ketu position (180° opposite to Rahu)
      final ketu = KetuPosition(rahuPosition: rahuPosition);

      // Calculate Sun position for combustion checks
      final sunPosition = planetPositions[Planet.sun]!;

      // Create Vedic planet info for each planet
      final vedicPlanets = <Planet, VedicPlanetInfo>{};
      for (final entry in planetPositions.entries) {
        final planet = entry.key;
        final position = entry.value;

        final house = houses.getHouseForLongitude(position.longitude);
        final dignity = _calculateDignity(planet, position.longitude);
        final isCombust = PlanetPosition.calculateCombustion(
          planet,
          position.longitude,
          sunPosition.longitude,
        );

        vedicPlanets[planet] = VedicPlanetInfo(
          position: position,
          house: house,
          dignity: dignity,
          isCombust: isCombust,
          exaltationDegree: _getExaltationDegree(planet),
          debilitationDegree: _getDebilitationDegree(planet),
        );
      }

      // Create Vedic info for Rahu
      final rahuHouse = houses.getHouseForLongitude(rahuPosition.longitude);
      final rahuDignity = _calculateDignity(
        Planet.meanNode,
        rahuPosition.longitude,
      );
      final rahuInfo = VedicPlanetInfo(
        position: rahuPosition,
        house: rahuHouse,
        dignity: rahuDignity,
        isCombust: false, // Rahu/Ketu are never combust
      );

      return VedicChart(
        dateTime: dateTime,
        location:
            '${location.latitude.toStringAsFixed(4)}°N, ${location.longitude.toStringAsFixed(4)}°E',
        latitude: location.latitude,
        longitudeCoord: location.longitude,
        houses: houses,
        planets: vedicPlanets,
        rahu: rahuInfo,
        ketu: ketu,
      );
    } catch (e) {
      throw JyotishException(
        'Failed to calculate Vedic chart: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Calculates house cusps using Swiss Ephemeris.
  Future<HouseSystem> _calculateHouses({
    required EphemerisService ephemerisService,
    required DateTime dateTime,
    required GeographicLocation location,
    required String houseSystem,
    required SiderealMode ayanamsaMode,
    double? overrideAyanamsa,
  }) async {
    // Get ayanamsa for sidereal correction first
    double ayanamsa;
    if (overrideAyanamsa != null) {
      ayanamsa = overrideAyanamsa;
    } else {
      ayanamsa = await ephemerisService.getAyanamsa(
        dateTime: dateTime,
        mode: ayanamsaMode, // Use selected ayanamsa
      );
    }

    // Calculate houses (returns tropical positions)
    final houseData = await ephemerisService.calculateHouses(
      dateTime: dateTime,
      location: location,
      houseSystem: 'P', // Placidus system
    );

    // Convert tropical positions to sidereal using the ayanamsa calculator
    // for consistency with planet calculations
    final tropicalAscendant = houseData['ascmc']![0];
    final ascendant = AyanamsaCalculator.tropicalToSidereal(
      tropicalAscendant,
      ayanamsa,
    );

    final tropicalMidheaven = houseData['ascmc']![1];
    final midheaven = AyanamsaCalculator.tropicalToSidereal(
      tropicalMidheaven,
      ayanamsa,
    );

    // Convert house cusps to sidereal
    final tropicalCusps = houseData['cusps']!;
    final cusps = tropicalCusps
        .map((cusp) => AyanamsaCalculator.tropicalToSidereal(cusp, ayanamsa))
        .toList();

    return HouseSystem(
      system: 'Placidus',
      cusps: cusps,
      ascendant: ascendant,
      midheaven: midheaven,
    );
  }

  /// Calculates planetary dignity based on sign placement.
  PlanetaryDignity _calculateDignity(Planet planet, double longitude) {
    final signIndex = (longitude / 30).floor() % 12;

    // Exaltation and debilitation degrees
    final exaltationMap = _getExaltationSign(planet);
    final debilitationMap = _getDebilitationSign(planet);

    if (exaltationMap != null && signIndex == exaltationMap) {
      return PlanetaryDignity.exalted;
    }

    if (debilitationMap != null && signIndex == debilitationMap) {
      return PlanetaryDignity.debilitated;
    }

    // Own signs
    final ownSigns = _getOwnSigns(planet);
    if (ownSigns.contains(signIndex)) {
      return PlanetaryDignity.ownSign;
    }

    // Moola Trikona
    final moolaTrikona = _getMoolaTrikona(planet);
    if (moolaTrikona != null && signIndex == moolaTrikona) {
      return PlanetaryDignity.moolaTrikona;
    }

    return PlanetaryDignity.neutralSign;
  }

  /// Gets exaltation sign index for a planet.
  int? _getExaltationSign(Planet planet) {
    const exaltations = {
      Planet.sun: 0, // Aries
      Planet.moon: 1, // Taurus
      Planet.mercury: 5, // Virgo
      Planet.venus: 11, // Pisces
      Planet.mars: 9, // Capricorn
      Planet.jupiter: 3, // Cancer
      Planet.saturn: 6, // Libra
      Planet.meanNode: 2, // Gemini (Rahu)
    };
    return exaltations[planet];
  }

  /// Gets debilitation sign index for a planet.
  int? _getDebilitationSign(Planet planet) {
    const debilitations = {
      Planet.sun: 6, // Libra
      Planet.moon: 7, // Scorpio
      Planet.mercury: 11, // Pisces
      Planet.venus: 5, // Virgo
      Planet.mars: 3, // Cancer
      Planet.jupiter: 9, // Capricorn
      Planet.saturn: 0, // Aries
      Planet.meanNode: 8, // Sagittarius (Rahu)
    };
    return debilitations[planet];
  }

  /// Gets exaltation degree for a planet.
  double? _getExaltationDegree(Planet planet) {
    const degrees = {
      Planet.sun: 10.0,
      Planet.moon: 33.0,
      Planet.mercury: 165.0,
      Planet.venus: 357.0,
      Planet.mars: 298.0,
      Planet.jupiter: 95.0,
      Planet.saturn: 200.0,
    };
    return degrees[planet];
  }

  /// Gets debilitation degree for a planet.
  double? _getDebilitationDegree(Planet planet) {
    const degrees = {
      Planet.sun: 190.0,
      Planet.moon: 213.0,
      Planet.mercury: 345.0,
      Planet.venus: 165.0,
      Planet.mars: 118.0,
      Planet.jupiter: 278.0,
      Planet.saturn: 20.0,
    };
    return degrees[planet];
  }

  /// Gets own signs for a planet.
  List<int> _getOwnSigns(Planet planet) {
    const ownSigns = {
      Planet.sun: [4],
      Planet.moon: [3],
      Planet.mercury: [2, 5],
      Planet.venus: [1, 6],
      Planet.mars: [0, 7],
      Planet.jupiter: [8, 11],
      Planet.saturn: [9, 10],
    };
    return ownSigns[planet] ?? [];
  }

  /// Gets Moola Trikona sign for a planet.
  int? _getMoolaTrikona(Planet planet) {
    const moolaTrikona = {
      Planet.sun: 4,
      Planet.moon: 1,
      Planet.mercury: 5,
      Planet.venus: 6,
      Planet.mars: 0,
      Planet.jupiter: 8,
      Planet.saturn: 10,
    };
    return moolaTrikona[planet];
  }
}
