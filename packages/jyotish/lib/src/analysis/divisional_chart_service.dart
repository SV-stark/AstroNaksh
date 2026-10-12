import '../exceptions/jyotish_exception.dart';
import 'package:jyotish/src/models/divisional_chart_type.dart';
import 'package:jyotish/src/models/planet.dart';
import 'package:jyotish/src/astronomy/planet_position.dart';
import 'package:jyotish/src/strength/relationship.dart';
import 'package:jyotish/src/models/vedic_chart.dart';
import 'package:jyotish/src/models/varga_configuration.dart';

/// Service for calculating Divisional Charts (Varga).
class DivisionalChartService {
  /// Upper bound on [_cache] entries.
  ///
  /// The cache is keyed on natal chart identity, so a long-lived process that
  /// computes charts for many births would otherwise grow it without bound.
  /// [_evictOldest] keeps only the most recently used entries once the bound is
  /// reached.
  static const int _maxCacheSize = 512;

  /// Cache for calculated divisional charts.
  /// Key: composite of natal chart identity + divisional type.
  final _cache = <String, VedicChart>{};

  /// Calculates a specific divisional chart from a base Rashi chart.
  VedicChart calculateDivisionalChart(
    VedicChart rashiChart,
    DivisionalChartType type, {
    VargaConfiguration? config,
  }) {
    if (type == DivisionalChartType.d1) {
      return rashiChart;
    }

    // Cache key includes natal chart time, location, ayanamsa mode and a checksum of planet positions
    // to avoid collisions in tests or when manually manipulating charts.
    final planetsHash = rashiChart.planets.values.fold(
      0,
      (hash, p) => hash ^ p.longitude.hashCode,
    );
    final configKey = config != null
        ? '_${config.horaMethod.name}_${config.drekkanaMethod.name}_${config.navamshaMethod.name}_${config.dashamshaMethod.name}'
        : '';
    final key = '${rashiChart.dateTime.millisecondsSinceEpoch}'
        '_${rashiChart.latitude}_${rashiChart.longitudeCoord}'
        '_${rashiChart.calculationFlags?.siderealMode.name ?? 'default'}' // enum identifier: stable cache key
        '_${rashiChart.ascendant.hashCode}'
        '_${planetsHash}_${type.name}$configKey';

    final cached = _cache.remove(key);
    if (cached != null) {
      // Re-insert so the insertion order tracks recency of use.
      _cache[key] = cached;
      return cached;
    }

    final computed = _computeDivisionalChart(rashiChart, type, config: config);
    _cache[key] = computed;
    _evictOldest();
    return computed;
  }

  /// Drops least-recently-used entries until the cache is back within bound.
  void _evictOldest() {
    while (_cache.length > _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  VedicChart _computeDivisionalChart(
    VedicChart rashiChart,
    DivisionalChartType type, {
    VargaConfiguration? config,
  }) {
    if (type.requiredAyanamsa != null) {
      final chartAyanamsa = rashiChart.calculationFlags?.siderealMode;
      if (chartAyanamsa != type.requiredAyanamsa) {
        throw AyanamsaMismatchException(
          'D${type.divisions} requires ${type.requiredAyanamsa!.label} ayanamsa. '
          'Chart was calculated with ${chartAyanamsa?.label ?? "unknown"}. '
          'Pass CalculationFlags(siderealMode: SiderealMode.${type.requiredAyanamsa!.name})'
          ' when calculating the root chart.',
        );
      }
    }

    if (type == DivisionalChartType.d1) {
      return rashiChart;
    }

    // Calculate D-Chart Ascendant
    final newAscendantDegree = _calculateVargaLongitude(
      rashiChart.ascendant,
      type,
      config: config,
    );

    // Create new House System (Whole Sign based on D-Ascendant)
    final dHouses = _createWholeSignHouses(newAscendantDegree);

    // First pass: Calculate positions and houses
    final tempInfos = <Planet, VedicPlanetInfo>{};
    final planetHouseMap = <Planet, int>{};

    for (final entry in rashiChart.planets.entries) {
      final planet = entry.key;
      final newInfo = _calculatePlanetVarga(
        originalInfo: entry.value,
        type: type,
        dHouses: dHouses,
        planetHouseMap: null,
        config: config,
      );
      tempInfos[planet] = newInfo;
      planetHouseMap[planet] = newInfo.house;
    }

    // Handle Rahu/Ketu special
    final rahuInfoTemp = _calculatePlanetVarga(
      originalInfo: rashiChart.rahu,
      type: type,
      dHouses: dHouses,
      planetHouseMap: null,
      config: config,
    );
    planetHouseMap[rahuInfoTemp.position.planet] = rahuInfoTemp.house;

    // Ketu's varga placement must come from Ketu's own NATAL longitude
    // (Rahu + 180) run through the varga mapping — NOT from the already
    // projected Rahu. For evenly divided vargas the two agree, because a
    // 180-degree rotation always maps to six varga signs; but the uneven
    // Trimsamsa (D30) and D249 do not commute with that rotation, so deriving
    // Ketu from the mapped Rahu puts Ketu in the wrong varga sign.
    final natalKetuLongitude = (rashiChart.rahu.longitude + 180.0) % 360.0;
    final ketuInfoTemp = _calculatePlanetVarga(
      originalInfo: VedicPlanetInfo(
        position: PlanetPosition(
          planet: Planet.ketu,
          dateTime: rashiChart.rahu.position.dateTime,
          longitude: natalKetuLongitude,
          latitude: -rashiChart.rahu.position.latitude,
          distance: rashiChart.rahu.position.distance,
          longitudeSpeed: rashiChart.rahu.position.longitudeSpeed,
          latitudeSpeed: -rashiChart.rahu.position.latitudeSpeed,
          distanceSpeed: rashiChart.rahu.position.distanceSpeed,
          isRetrograde: true,
        ),
        house: dHouses.getHouseForLongitude(natalKetuLongitude),
        dignity: PlanetaryDignity.neutralSign,
      ),
      type: type,
      dHouses: dHouses,
      planetHouseMap: null,
      config: config,
    );
    planetHouseMap[Planet.ketu] = ketuInfoTemp.house;

    // Second pass: Calculate dignity
    final finalPlanets = <Planet, VedicPlanetInfo>{};
    for (final entry in tempInfos.entries) {
      final planet = entry.key;
      final info = entry.value;

      final dignity = _calculateDignityForVarga(
        planet,
        info.longitude,
        planetHouseMap,
        info.house,
      );

      finalPlanets[planet] = VedicPlanetInfo(
        position: info.position,
        house: info.house,
        dignity: dignity,
        isCombust: info.isCombust,
        exaltationDegree: info.exaltationDegree,
        debilitationDegree: info.debilitationDegree,
        positionInSign: info.positionInSign,
        subSpan: info.subSpan,
      );
    }

    final rahuDignity = _calculateDignityForVarga(
      rahuInfoTemp.position.planet,
      rahuInfoTemp.longitude,
      planetHouseMap,
      rahuInfoTemp.house,
    );

    final finalRahu = VedicPlanetInfo(
      position: rahuInfoTemp.position,
      house: rahuInfoTemp.house,
      dignity: rahuDignity,
      isCombust: rahuInfoTemp.isCombust,
      exaltationDegree: rahuInfoTemp.exaltationDegree,
      debilitationDegree: rahuInfoTemp.debilitationDegree,
      positionInSign: rahuInfoTemp.positionInSign,
      subSpan: rahuInfoTemp.subSpan,
    );

    // `KetuPosition` derives Ketu from a Rahu position, so to pin Ketu at its
    // own varga longitude we hand it a Rahu proxy exactly 180 degrees behind.
    // Every other field comes from the mapped Rahu, so Ketu's date, speed and
    // distance are unchanged from before.
    final ketuRahuProxy = PlanetPosition(
      planet: rahuInfoTemp.position.planet,
      dateTime: rahuInfoTemp.position.dateTime,
      longitude: (ketuInfoTemp.longitude + 180.0) % 360.0,
      latitude: rahuInfoTemp.position.latitude,
      distance: rahuInfoTemp.position.distance,
      longitudeSpeed: rahuInfoTemp.position.longitudeSpeed,
      latitudeSpeed: rahuInfoTemp.position.latitudeSpeed,
      distanceSpeed: rahuInfoTemp.position.distanceSpeed,
    );
    final finalKetu = KetuPosition(rahuPosition: ketuRahuProxy);

    return VedicChart(
      dateTime: rashiChart.dateTime,
      location: rashiChart.location,
      latitude: rashiChart.latitude,
      longitudeCoord: rashiChart.longitudeCoord,
      altitude: rashiChart.altitude,
      houses: dHouses,
      planets: finalPlanets,
      rahu: finalRahu,
      ketu: finalKetu,
      calculationFlags: rashiChart.calculationFlags,
    );
  }

  VedicPlanetInfo _calculatePlanetVarga({
    required VedicPlanetInfo originalInfo,
    required DivisionalChartType type,
    required HouseSystem dHouses,
    Map<Planet, int>? planetHouseMap,
    VargaConfiguration? config,
  }) {
    double newLongitude;
    double? vPositionInSign;
    double? vSubSpan;

    if (type == DivisionalChartType.d249) {
      // Snapping to 30-degree sign boundaries for D249
      final normalizedLong = _adjustJunctionBoundary(originalInfo.longitude, 1);
      final signIndex = (normalizedLong / 30).floor();
      final degreeInSign = normalizedLong % 30;
      final isOdd = (signIndex + 1) % 2 != 0;
      final details = _calculateD249Details(signIndex, degreeInSign, isOdd);
      newLongitude = details.longitude;
      vPositionInSign = details.posInSub;
      vSubSpan = details.span;
    } else {
      newLongitude = _calculateVargaLongitude(
        originalInfo.longitude,
        type,
        config: config,
      );
      vPositionInSign = newLongitude % 30;
    }

    final newPosition = PlanetPosition(
      planet: originalInfo.position.planet,
      dateTime: originalInfo.position.dateTime,
      longitude: newLongitude,
      latitude: originalInfo.position.latitude,
      distance: originalInfo.position.distance,
      longitudeSpeed: originalInfo.position.longitudeSpeed,
      latitudeSpeed: originalInfo.position.latitudeSpeed,
      distanceSpeed: originalInfo.position.distanceSpeed,
    );

    final house = dHouses.getHouseForLongitude(newLongitude);

    // Calculate dignity in the D-Chart context
    final dignity = planetHouseMap != null
        ? _calculateDignityForVarga(
            originalInfo.position.planet,
            newLongitude,
            planetHouseMap,
            house,
          )
        : PlanetaryDignity.neutralSign;

    return VedicPlanetInfo(
      position: newPosition,
      house: house,
      dignity: dignity,
      isCombust: false,
      positionInSign: vPositionInSign,
      subSpan: vSubSpan,
    );
  }

  /// Calculates planetary dignity in a divisional chart.
  PlanetaryDignity _calculateDignityForVarga(
    Planet planet,
    double longitude,
    Map<Planet, int> planetHouseMap,
    int planetHouse,
  ) {
    final signIndex = (longitude / 30).floor() % 12;

    // Exaltation and debilitation
    final exaltationSign = _getExaltationSign(planet);
    final debilitationSign = _getDebilitationSign(planet);

    if (exaltationSign != null && signIndex == exaltationSign) {
      return PlanetaryDignity.exalted;
    }

    if (debilitationSign != null && signIndex == debilitationSign) {
      return PlanetaryDignity.debilitated;
    }

    // Moola Trikona (must be checked BEFORE own signs because MT signs overlap)
    final moolaTrikona = _getMoolaTrikona(planet);
    if (moolaTrikona != null && signIndex == moolaTrikona) {
      return PlanetaryDignity.moolaTrikona;
    }

    // Own signs
    final ownSigns = _getOwnSigns(planet);
    if (ownSigns.contains(signIndex)) {
      return PlanetaryDignity.ownSign;
    }

    // Friend/enemy/neutral based on sign lord
    final signLord = _getSignLord(signIndex);
    if (signLord != null) {
      return _calculateFriendshipDignity(
        planet,
        signLord,
        planetHouseMap,
        planetHouse,
      );
    }

    return PlanetaryDignity.neutralSign;
  }

  /// Calculates friendship-based dignity.
  PlanetaryDignity _calculateFriendshipDignity(
    Planet planet,
    Planet signLord,
    Map<Planet, int> planetHouseMap,
    int planetHouse,
  ) {
    final natural = RelationshipCalculator.naturalRelationships[planet]
            ?[signLord] ??
        RelationshipType.neutral;

    final signLordHouse = planetHouseMap[signLord];
    final temporary = signLordHouse != null
        ? RelationshipCalculator.calculateTemporary(planetHouse, signLordHouse)
        : RelationshipType.neutral;

    final compound = RelationshipCalculator.calculateCompound(
      natural,
      temporary,
    );

    return switch (compound) {
      RelationshipType.greatFriend => PlanetaryDignity.greatFriend,
      RelationshipType.friend => PlanetaryDignity.friendSign,
      RelationshipType.neutral => PlanetaryDignity.neutralSign,
      RelationshipType.enemy => PlanetaryDignity.enemySign,
      RelationshipType.greatEnemy => PlanetaryDignity.greatEnemy,
    };
  }

  /// Gets exaltation sign for a planet.
  int? _getExaltationSign(Planet planet) {
    const exaltations = {
      Planet.sun: 0, // Aries
      Planet.moon: 1, // Taurus
      Planet.mercury: 5, // Virgo
      Planet.venus: 11, // Pisces
      Planet.mars: 9, // Capricorn
      Planet.jupiter: 3, // Cancer
      Planet.saturn: 6, // Libra
    };
    return exaltations[planet];
  }

  /// Gets debilitation sign for a planet.
  int? _getDebilitationSign(Planet planet) {
    const debilitations = {
      Planet.sun: 6, // Libra
      Planet.moon: 7, // Scorpio
      Planet.mercury: 11, // Pisces
      Planet.venus: 5, // Virgo
      Planet.mars: 3, // Cancer
      Planet.jupiter: 9, // Capricorn
      Planet.saturn: 0, // Aries
    };
    return debilitations[planet];
  }

  /// Gets own signs for a planet.
  List<int> _getOwnSigns(Planet planet) {
    const ownSigns = {
      Planet.sun: [4], // Leo
      Planet.moon: [3], // Cancer
      Planet.mercury: [2, 5], // Gemini, Virgo
      Planet.venus: [1, 6], // Taurus, Libra
      Planet.mars: [0, 7], // Aries, Scorpio
      Planet.jupiter: [8, 11], // Sagittarius, Pisces
      Planet.saturn: [9, 10], // Capricorn, Aquarius
    };
    return ownSigns[planet] ?? [];
  }

  /// Gets Moola Trikona sign for a planet.
  int? _getMoolaTrikona(Planet planet) {
    const moolaTrikona = {
      Planet.sun: 4, // Leo
      Planet.moon: 1, // Taurus
      Planet.mercury: 5, // Virgo
      Planet.venus: 6, // Libra
      Planet.mars: 0, // Aries
      Planet.jupiter: 8, // Sagittarius
      Planet.saturn: 10, // Aquarius
    };
    return moolaTrikona[planet];
  }

  /// Gets the lord of a zodiac sign.
  Planet? _getSignLord(int signIndex) {
    const signLords = {
      0: Planet.mars, // Aries
      1: Planet.venus, // Taurus
      2: Planet.mercury, // Gemini
      3: Planet.moon, // Cancer
      4: Planet.sun, // Leo
      5: Planet.mercury, // Virgo
      6: Planet.venus, // Libra
      7: Planet.mars, // Scorpio
      8: Planet.jupiter, // Sagittarius
      9: Planet.saturn, // Capricorn
      10: Planet.saturn, // Aquarius
      11: Planet.jupiter, // Pisces
    };
    return signLords[signIndex];
  }

  HouseSystem _createWholeSignHouses(double ascendantLongitude) {
    final ascSignIndex = (ascendantLongitude / 30).floor();

    final cusps = List<double>.generate(12, (i) {
      return ((ascSignIndex + i) % 12) * 30.0;
    });

    final mc = (ascendantLongitude + 270) % 360;

    return HouseSystem(
      system: 'Whole Sign (Varga)',
      cusps: cusps,
      ascendant: ascendantLongitude,
      midheaven: mc,
    );
  }

  /// Calculates the absolute longitude (0-360) of a point in a divisional chart.
  double calculateVargaLongitude(
    double longitude,
    DivisionalChartType type, {
    VargaConfiguration? config,
  }) =>
      _calculateVargaLongitude(longitude, type, config: config);

  /// Internal: Calculates the absolute longitude (0-360) of a point in a divisional chart.
  double _calculateVargaLongitude(
    double longitude,
    DivisionalChartType type, {
    VargaConfiguration? config,
  }) {
    final parts = type.divisions;

    // Apply double-precision junction guardrail to avoid floating-point boundary issues
    final normalized = _adjustJunctionBoundary(longitude, parts);

    // 1. Get current sign and position in sign
    final signIndex = (normalized / 30).floor(); // 0-11
    final degreeInSign = normalized % 30;

    // 2. Determine the "Varga Sign Index" (0-11)
    final vargaSignIndex = _getVargaSign(
      signIndex,
      degreeInSign,
      type,
      config: config,
    );

    // 3. Determine degrees in the new sign
    // For D30 (Trimsamsa), spans are unequal so degrees are scaled proportionally across 30°.
    final double degreesInNewSign;
    if (type == DivisionalChartType.d30) {
      degreesInNewSign = _calculateD30DegreeInSign(signIndex, degreeInSign);
    } else {
      degreesInNewSign = (degreeInSign * parts) % 30;
    }

    // Apply guardrail to degrees in new sign too
    var finalDegrees = degreesInNewSign;
    if (finalDegrees < 1e-11) finalDegrees = 0.0;
    if ((finalDegrees - 30.0).abs() < 1e-11) finalDegrees = 0.0;

    return ((vargaSignIndex * 30) + finalDegrees) % 360.0;
  }

  /// Adjusts longitude near division boundaries to prevent floating-point inaccuracies
  /// from triggering incorrect division/sign floor transitions.
  double _adjustJunctionBoundary(double longitude, int divisions) {
    var normalized = longitude % 360.0;
    if (normalized < 0) normalized += 360.0;

    final divisionSpan = 30.0 / divisions;
    final closestIndex = (normalized / divisionSpan).round();
    final closestBoundary = closestIndex * divisionSpan;

    if ((normalized - closestBoundary).abs() < 1e-11) {
      return closestBoundary % 360.0;
    }
    return normalized;
  }

  int _getVargaSign(
    int signIndex,
    double degreeInSign,
    DivisionalChartType type, {
    VargaConfiguration? config,
  }) {
    final activeConfig = config ?? const VargaConfiguration();
    final sign = signIndex + 1; // 1-12
    final isOdd = sign % 2 != 0;
    final isMoveable = [1, 4, 7, 10].contains(sign);
    final isFixed = [2, 5, 8, 11].contains(sign);
    // final isDual = [3, 6, 9, 12].contains(sign);

    final element = (sign - 1) % 4; // 0=Fire, 1=Earth, 2=Air, 3=Water

    switch (type) {
      case DivisionalChartType.d1:
        return signIndex;

      case DivisionalChartType.d2: // Hora
        switch (activeConfig.horaMethod) {
          case HoraMethod.parashara:
            if (isOdd) {
              return (degreeInSign < 15) ? 4 : 3; // Index 4=Leo, 3=Can
            } else {
              return (degreeInSign < 15) ? 3 : 4;
            }
          case HoraMethod.labhaMandooka:
            if (isOdd) {
              return (degreeInSign < 15) ? signIndex : (signIndex + 10) % 12;
            } else {
              return (degreeInSign < 15)
                  ? (signIndex + 1) % 12
                  : (signIndex + 11) % 12;
            }
          case HoraMethod.kura:
            if (isOdd) {
              return (degreeInSign < 15) ? 3 : 4; // opposite of parashara
            } else {
              return (degreeInSign < 15) ? 4 : 3;
            }
          case HoraMethod.kashinatha:
            return (2 * signIndex + (degreeInSign < 15 ? 0 : 1)) % 12;
        }

      case DivisionalChartType.d3: // Drekkana
        final part = (degreeInSign / 10).floor(); // 0, 1, 2
        switch (activeConfig.drekkanaMethod) {
          case DrekkanaMethod.parashara:
            if (part == 0) return signIndex;
            if (part == 1) return (signIndex + 4) % 12;
            return (signIndex + 8) % 12;
          case DrekkanaMethod.jagannatha:
            final startMap = {
              0: 0, // Fire -> Aries
              1: 9, // Earth -> Capricorn
              2: 6, // Air -> Libra
              3: 3, // Water -> Cancer
            };
            return (startMap[element]! + part) % 12;
          case DrekkanaMethod.somanatha:
            if (isOdd) {
              if (part == 0) return signIndex;
              if (part == 1) return (signIndex + 4) % 12;
              return (signIndex + 8) % 12;
            } else {
              if (part == 0) return (signIndex + 8) % 12;
              if (part == 1) return (signIndex + 4) % 12;
              return signIndex;
            }
          case DrekkanaMethod.parivritti:
            return (3 * signIndex + part) % 12;
        }

      case DivisionalChartType.d4: // Chaturthamsa
        final part = (degreeInSign / (30 / 4)).floor(); // 0-3
        // 1: Same, 2: 4th, 3: 7th, 4: 10th (Kendra count) => Not exactly?
        // Rule:
        // 1st part: Same sign
        // 2nd part: 4th from sign
        // 3rd part: 7th from sign
        // 4th part: 10th from sign
        final offset = part * 3;
        return (signIndex + offset) % 12;

      case DivisionalChartType.d5: // Panchamsa
        // D5 rules (BPHS Ch. 6, Sloka 8):
        // 5 divisions of 6° each.
        // For odd signs (Aries, Gemini, Leo, Libra, Sagittarius, Aquarius):
        //   Aries (0), Aquarius (10), Sagittarius (8), Gemini (2), Libra (6)
        // For even signs (Taurus, Cancer, Virgo, Scorpio, Capricorn, Pisces):
        //   Taurus (1), Virgo (5), Pisces (11), Capricorn (9), Scorpio (7)
        final part = (degreeInSign / (30 / 5)).floor().clamp(0, 4);
        if (isOdd) {
          const oddSigns = [0, 10, 8, 2, 6];
          return oddSigns[part];
        } else {
          const evenSigns = [1, 5, 11, 9, 7];
          return evenSigns[part];
        }

      case DivisionalChartType.d6: // Shashthamsa
        // D6 rules:
        // For odd signs: Start from Aries (0)
        // For even signs: Start from Libra (6)
        final part = (degreeInSign / (30 / 6)).floor(); // 0-5
        if (isOdd) {
          return (0 + part) % 12;
        } else {
          return (6 + part) % 12;
        }

      case DivisionalChartType.d7: // Saptamsa
        final part = (degreeInSign / (30 / 7)).floor(); // 0-6
        if (isOdd) {
          // Start from same sign
          return (signIndex + part) % 12;
        } else {
          // Start from 7th sign
          return (signIndex + 6 + part) % 12;
        }

      case DivisionalChartType.d8: // Ashtamsa
        // D8 rules:
        // For movable signs (Aries, Cancer, Libra, Capricorn): Start from Aries
        // For fixed signs (Taurus, Leo, Scorpio, Aquarius): Start from Leo
        // For dual signs (Gemini, Virgo, Sagittarius, Pisces): Start from Sagittarius
        final part = (degreeInSign / (30 / 8)).floor(); // 0-7
        if (isMoveable) {
          return (0 + part) % 12;
        } else if (isFixed) {
          return (4 + part) % 12;
        } else {
          // Dual signs
          return (8 + part) % 12;
        }

      case DivisionalChartType.d9: // Navamsa
        final part = (degreeInSign / (30 / 9)).floor(); // 0-8
        switch (activeConfig.navamshaMethod) {
          case NavamshaMethod.parashara:
            final startMap = {
              0: 0, // Fire -> Aries
              1: 9, // Earth -> Cap
              2: 6, // Air -> Libra
              3: 3, // Water -> Can
            };
            final startSignIndex = startMap[element]!;
            return (startSignIndex + part) % 12;
          case NavamshaMethod.krishnaMishra:
            if (isOdd) {
              return (signIndex + part) % 12;
            } else {
              return (signIndex + 9 - part) % 12;
            }
          case NavamshaMethod.somanatha:
            if (isOdd) {
              return (0 + part) % 12;
            } else {
              return (11 - part) % 12;
            }
          case NavamshaMethod.nadamsa:
            final startSign = isMoveable
                ? signIndex
                : isFixed
                    ? (signIndex + 8) % 12
                    : (signIndex + 4) % 12;
            return (startSign + part) % 12;
        }

      case DivisionalChartType.d10: // Dasamsa
        final part = (degreeInSign / (30 / 10)).floor(); // 0-9
        switch (activeConfig.dashamshaMethod) {
          case DashamshaMethod.parashara:
            if (isOdd) {
              return (signIndex + part) % 12;
            } else {
              return (signIndex + 8 + part) % 12;
            }
          case DashamshaMethod.behari:
            if (isOdd) {
              return (signIndex + 8 + part) % 12;
            } else {
              return (signIndex + part) % 12;
            }
        }

      case DivisionalChartType.d11: // Rudramsa
        // D11 rules:
        // For movable signs: Start from Aries
        // For fixed signs: Start from Leo
        // For dual signs: Start from Sagittarius
        final part = (degreeInSign / (30 / 11)).floor(); // 0-10
        if (isMoveable) {
          return (0 + part) % 12;
        } else if (isFixed) {
          return (4 + part) % 12;
        } else {
          // Dual signs
          return (8 + part) % 12;
        }

      case DivisionalChartType.d12: // Dwadasamsa
        final part = (degreeInSign / (30 / 12)).floor(); // 0-11
        // Starts from same sign
        return (signIndex + part) % 12;

      case DivisionalChartType.d16: // Shodasamsa
        final part = (degreeInSign / (30 / 16)).floor(); // 0-15
        if (isMoveable) {
          // Start Aries
          return (0 + part) % 12;
        } else if (isFixed) {
          // Start Leo
          return (4 + part) % 12;
        } else {
          // Start Sag
          return (8 + part) % 12;
        }

      case DivisionalChartType.d20: // Vimsamsa
        final part = (degreeInSign / (30 / 20)).floor(); // 0-19
        if (isMoveable) {
          // Start Aries
          return (0 + part) % 12;
        } else if (isFixed) {
          // Start Sag (Note: D16 was Leo/Sag, D20 is Sag/Leo? Verify!)
          // Standard: Moveable->Aries, Fixed->Sagittarius, Dual->Leo
          return (8 + part) % 12;
        } else {
          // Start Leo
          return (4 + part) % 12;
        }

      case DivisionalChartType.d24: // Chaturvimshamsha
        final part = (degreeInSign / (30 / 24)).floor(); // 0-23
        if (isOdd) {
          // Start Leo
          return (4 + part) % 12;
        } else {
          // Start Cancer
          return (3 + part) % 12;
        }

      case DivisionalChartType.d27: // Saptavimsamsa
        final part = (degreeInSign / (30 / 27)).floor(); // 0-26
        // Like Navamsa starts: Fire->Aries, Earth->Cancer, Air->Libra, Water->Cap
        // Wait, standard D27:
        // Fire signs: Start Aries
        // Earth signs: Start Cancer
        // Air signs: Start Libra
        // Water signs: Start Capricorn
        // This is 1, 4, 7, 10
        final startMap = {
          0: 0, // Fire -> Aries
          1: 3, // Earth -> Cancer
          2: 6, // Air -> Libra
          3: 9, // Water -> Cap
        };
        return (startMap[element]! + part) % 12;

      case DivisionalChartType.d30:
        return _calculateD30Sign(signIndex, degreeInSign);

      case DivisionalChartType.d40: // Khavedamsa
        final part = (degreeInSign / (30 / 40)).floor();
        if (isOdd) {
          // Start Aries
          return (0 + part) % 12;
        } else {
          // Start Libra
          return (6 + part) % 12;
        }

      case DivisionalChartType.d45: // Akshavedamsa
        final part = (degreeInSign / (30 / 45)).floor();
        if (isMoveable) {
          // Start Aries
          return (0 + part) % 12;
        } else if (isFixed) {
          // Start Leo
          return (4 + part) % 12;
        } else {
          // Start Sagittarius
          return (8 + part) % 12;
        }

      case DivisionalChartType.d60: // Shashtiamsa (60 divisions)
        // Traditional D60 calculation (Shashtiamsa)
        // Each sign is divided into 60 parts of 0.5 each
        //
        // Per BPHS Ch.6 v.33: take the degrees traversed within the sign,
        // double them, divide by 12, add 1 to the remainder, and count that far
        // forward from the natal sign itself. This holds for odd AND even signs
        // alike: for even signs only the 60 Shashtiamsa NAMES run in reverse
        // order, the sign POSITION does not.
        final part = (degreeInSign / (30 / 60)).floor(); // 0-59

        // `part` runs 0-59, so `% 12` wraps the count back into the zodiac.
        return (signIndex + part) % 12;

      case DivisionalChartType.d150: // Nadi Amsa
        // D150: 150th division for micro-level analysis
        // Rules:
        // For odd signs: Count forward from Aries
        // For even signs: Count backward from Pisces
        final part = (degreeInSign / (30 / 150)).floor(); // 0-149
        if (isOdd) {
          // Count forward from Aries for odd signs
          return (0 + part) % 12;
        } else {
          // Count backward from Pisces for even signs
          return (11 - part) % 12;
        }

      case DivisionalChartType.d249: // 249 Subdivisions (KP Micro-Analysis)
        // D249 uses Vimshottari Dasha proportions, NOT equal divisions
        // Each of the 249 subdivisions is proportional to dasha years (total 120 years)
        // The sequence repeats: Ketu(7), Venus(20), Sun(6), Moon(10), Mars(7),
        //                        Rahu(18), Jupiter(16), Saturn(19), Mercury(17)
        return _calculateD249Sign(signIndex, degreeInSign, isOdd);
    }
  }

  ({double longitude, double posInSub, double span}) _calculateD249Details(
    int signIndex,
    double degreeInSign,
    bool isOdd,
  ) {
    final dashaData = [
      (planet: Planet.ketu, years: 7, degrees: 1.75),
      (planet: Planet.venus, years: 20, degrees: 5.0),
      (planet: Planet.sun, years: 6, degrees: 1.5),
      (planet: Planet.moon, years: 10, degrees: 2.5),
      (planet: Planet.mars, years: 7, degrees: 1.75),
      (planet: Planet.meanNode, years: 18, degrees: 4.5),
      (planet: Planet.jupiter, years: 16, degrees: 4.0),
      (planet: Planet.saturn, years: 19, degrees: 4.75),
      (planet: Planet.mercury, years: 17, degrees: 4.25),
    ];

    var cumulativeDegrees = 0.0;
    final startSign = isOdd ? signIndex : (signIndex + 8) % 12;

    for (var cycle = 0; cycle < 27; cycle++) {
      for (var i = 0; i < 9; i++) {
        final span = dashaData[i].degrees;
        // Subtract epsilon 1e-11 to prevent boundary errors
        if (degreeInSign < cumulativeDegrees + span - 1e-11) {
          final subIndex = cycle * 9 + i;
          final posPercent = (degreeInSign - cumulativeDegrees) / span;
          final vargaSignIndex = (startSign + subIndex) % 12;
          final degreesInSign = posPercent * 30.0;
          return (
            longitude: (vargaSignIndex * 30.0) + degreesInSign,
            posInSub: degreesInSign,
            span: span,
          );
        }
        cumulativeDegrees += span;
      }
    }

    for (var i = 0; i < 6; i++) {
      final span = dashaData[i].degrees;
      // Subtract epsilon 1e-11 to prevent boundary errors
      if (degreeInSign < cumulativeDegrees + span - 1e-11) {
        final subIndex = 243 + i;
        final posPercent = (degreeInSign - cumulativeDegrees) / span;
        final vargaSignIndex = (startSign + subIndex) % 12;
        final degreesInSign = posPercent * 30.0;
        return (
          longitude: (vargaSignIndex * 30.0) + degreesInSign,
          posInSub: degreesInSign,
          span: span,
        );
      }
      cumulativeDegrees += span;
    }

    return (longitude: (startSign * 30.0), posInSub: 0.0, span: 1.75);
  }

  int _calculateD249Sign(int signIndex, double degreeInSign, bool isOdd) {
    return _calculateD249Details(signIndex, degreeInSign, isOdd).longitude ~/
        30;
  }

  int _calculateD30Sign(int signIndex, double degree) {
    // Trimsamsa (D-30)
    // Note: This implements the standard BPHS Trimsamsa rules where degrees are
    // unevenly mapped to 5 specific signs (ruled by Mars, Saturn, Jupiter, Mercury, Venus).
    // The Sun and Moon do not rule any Trimsamsa regions.
    final sign = signIndex + 1;
    final isOdd = sign % 2 != 0;

    // Aries=0, Taurus=1, Gemini=2, Cancer=3, Leo=4, Virgo=5...
    // Mars=0,7; Sat=9,10; Jup=8,11; Merc=2,5; Ven=1,6

    if (isOdd) {
      // 0-5: Mars (Aries)
      if (degree < 5 - 1e-11) return 0;
      // 5-10: Saturn (Aquarius)
      if (degree < 10 - 1e-11) return 10;
      // 10-18: Jupiter (Sagittarius)
      if (degree < 18 - 1e-11) return 8;
      // 18-25: Mercury (Gemini)
      if (degree < 25 - 1e-11) return 2;
      // 25-30: Venus (Libra)
      return 6;
    } else {
      // 0-5: Venus (Taurus)
      if (degree < 5 - 1e-11) return 1;
      // 5-12: Mercury (Virgo)
      if (degree < 12 - 1e-11) return 5;
      // 12-20: Jupiter (Pisces)
      if (degree < 20 - 1e-11) return 11;
      // 20-25: Saturn (Capricorn)
      if (degree < 25 - 1e-11) return 9;
      // 25-30: Mars (Scorpio)
      return 7;
    }
  }

  double _calculateD30DegreeInSign(int signIndex, double degree) {
    final sign = signIndex + 1;
    final isOdd = sign % 2 != 0;

    double spanStart;
    double spanWidth;

    if (isOdd) {
      if (degree < 5 - 1e-11) {
        spanStart = 0.0;
        spanWidth = 5.0;
      } else if (degree < 10 - 1e-11) {
        spanStart = 5.0;
        spanWidth = 5.0;
      } else if (degree < 18 - 1e-11) {
        spanStart = 10.0;
        spanWidth = 8.0;
      } else if (degree < 25 - 1e-11) {
        spanStart = 18.0;
        spanWidth = 7.0;
      } else {
        spanStart = 25.0;
        spanWidth = 5.0;
      }
    } else {
      if (degree < 5 - 1e-11) {
        spanStart = 0.0;
        spanWidth = 5.0;
      } else if (degree < 12 - 1e-11) {
        spanStart = 5.0;
        spanWidth = 7.0;
      } else if (degree < 20 - 1e-11) {
        spanStart = 12.0;
        spanWidth = 8.0;
      } else if (degree < 25 - 1e-11) {
        spanStart = 20.0;
        spanWidth = 5.0;
      } else {
        spanStart = 25.0;
        spanWidth = 5.0;
      }
    }

    final ratio = ((degree - spanStart) / spanWidth).clamp(0.0, 1.0);
    return ratio * 30.0;
  }
}
