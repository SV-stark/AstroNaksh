import 'package:jyotish/jyotish.dart';
import 'package:path_provider/path_provider.dart';

/// Service for calculating Vedic astrology charts with custom Ayanamsa.
/// Replicates logic from [VedicChartService] but allows configurable SiderealMode.
class CustomChartService {
  static EphemerisService? _sharedService;
  static bool _isInitialized = false;

  /// Gets the shared, initialized EphemerisService
  Future<EphemerisService> _getEphemerisService() async {
    if (_sharedService != null && _isInitialized) {
      return _sharedService!;
    }

    _sharedService = EphemerisService();

    // Get ephemeris path
    final directory = await getApplicationSupportDirectory();
    final ephemerisPath = '${directory.path}/ephe';

    // Initialize with the ephemeris path
    await _sharedService!.initialize(ephemerisPath: ephemerisPath);
    _isInitialized = true;

    return _sharedService!;
  }

  /// Calculates a complete Vedic astrology chart with specific Ayanamsa.
  ///
  /// [dateTime] - Birth date and time
  /// [location] - Birth location
  /// [ayanamsaMode] - The ayanamsa system to use
  /// [houseSystem] - House system to use (default: Whole Sign 'W')
  /// [includeOuterPlanets] - Include Uranus, Neptune, Pluto (default: false)
  Future<VedicChart> calculateChart({
    required DateTime dateTime,
    required GeographicLocation location,
    required SiderealMode ayanamsaMode,
    String houseSystem = 'W', // Whole Sign by default
    bool includeOuterPlanets = false,
  }) async {
    try {
      // Get initialized ephemeris service
      final ephemerisService = await _getEphemerisService();

      // Use selected ayanamsa
      final flags = CalculationFlags.sidereal(ayanamsaMode);

      // Calculate Ascendant and house cusps with the specific Ayanamsa
      final houses = await _calculateHouses(
        ephemerisService: ephemerisService,
        dateTime: dateTime,
        location: location,
        houseSystem: houseSystem,
        ayanamsaMode: ayanamsaMode,
      );

      // Get list of planets to calculate
      final planetsToCalculate = includeOuterPlanets
          ? Planet.majorPlanets
          : Planet.traditionalPlanets;

      // Calculate all planetary positions
      final planetPositions = <Planet, PlanetPosition>{};
      for (final planet in planetsToCalculate) {
        final position = await ephemerisService.calculatePlanetPosition(
          planet: planet,
          dateTime: dateTime,
          location: location,
          flags: flags,
        );
        planetPositions[planet] = position;
      }

      // Calculate Rahu (Mean Node)
      final rahuPosition = await ephemerisService.calculatePlanetPosition(
        planet: Planet.meanNode,
        dateTime: dateTime,
        location: location,
        flags: flags,
      );

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
  }) async {
    // Calculate houses (returns tropical positions)
    final houseData = await ephemerisService.calculateHouses(
      dateTime: dateTime,
      location: location,
      houseSystem: 'P', // Placidus system
    );

    // Get ayanamsa for sidereal correction
    final ayanamsa = await ephemerisService.getAyanamsa(
      dateTime: dateTime,
      mode: ayanamsaMode, // Use selected ayanamsa
    );

    // Convert tropical positions to sidereal
    final tropicalAscendant = houseData['ascmc']![0];
    final ascendant = (tropicalAscendant - ayanamsa + 360) % 360;

    final tropicalMidheaven = houseData['ascmc']![1];
    final midheaven = (tropicalMidheaven - ayanamsa + 360) % 360;

    // Convert house cusps to sidereal
    final tropicalCusps = houseData['cusps']!;
    final cusps = tropicalCusps
        .map((cusp) => (cusp - ayanamsa + 360) % 360)
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
