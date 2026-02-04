import 'package:jyotish/jyotish.dart';
import '../data/models.dart';

/// KP Extensions - Complete 249 Subdivision Tables with Vimshottari Proportions
/// Based on unequal divisions according to dasha periods
class KPExtensions {
  // Vimshottari Dasha periods (in years)
  static const Map<String, double> _dashaPeriods = {
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

  static const double _totalDashaYears = 120;
  static const double _nakshatraSpan = 360.0 / 27.0; // Exact nakshatra span
  // unused: static const double _subSpan = 1.4814814815; // 13.333° / 9

  // 27 Nakshatras with their Star Lords
  static const List<String> kpStarLords = [
    'Ketu',
    'Venus',
    'Sun',
    'Moon',
    'Mars',
    'Rahu',
    'Jupiter',
    'Saturn',
    'Mercury',
    'Ketu',
    'Venus',
    'Sun',
    'Moon',
    'Mars',
    'Rahu',
    'Jupiter',
    'Saturn',
    'Mercury',
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

  // Nakshatra names for reference
  static const List<String> nakshatraNames = [
    'Ashwini',
    'Bharani',
    'Krittika',
    'Rohini',
    'Mrigashira',
    'Ardra',
    'Punarvasu',
    'Pushya',
    'Ashlesha',
    'Magha',
    'Purva Phalguni',
    'Uttara Phalguni',
    'Hasta',
    'Chitra',
    'Swati',
    'Vishakha',
    'Anuradha',
    'Jyeshtha',
    'Mula',
    'Purva Ashadha',
    'Uttara Ashadha',
    'Shravana',
    'Dhanishta',
    'Shatabhisha',
    'Purva Bhadrapada',
    'Uttara Bhadrapada',
    'Revati',
  ];

  // Complete 249 Sub-Lords Table
  static const List<List<String>> kpSubLords = [
    [
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
    ],
    [
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
    ],
    [
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
    ],
    [
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
    ],
    [
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
    ],
    [
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
    ],
    [
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
    ],
    [
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
    ],
    [
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
    ],
    [
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
    ],
    [
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
    ],
    [
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
    ],
    [
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
    ],
    [
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
    ],
    [
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
    ],
    [
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
    ],
    [
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
    ],
    [
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
    ],
    [
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
    ],
    [
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
    ],
    [
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
    ],
    [
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
    ],
    [
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
    ],
    [
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
    ],
    [
      'Jupiter',
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
    ],
    [
      'Saturn',
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
    ],
    [
      'Mercury',
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
    ],
  ];

  /// Calculate sub-lord using actual unequal vimshottari proportions
  static KPSubLord calculateSubLord(double longitude) {
    final normalizedLong = longitude % 360;
    final nakshatraIndex = (normalizedLong / _nakshatraSpan).floor();
    final nakshatraStart = nakshatraIndex * _nakshatraSpan;
    final positionInNakshatra = normalizedLong - nakshatraStart;

    final starLord = kpStarLords[nakshatraIndex];
    final subLordsInNakshatra = kpSubLords[nakshatraIndex];

    // Calculate unequal sub-divisions based on vimshottari proportions
    final subBoundaries = _calculateSubBoundaries(subLordsInNakshatra);

    String subLord = 'Unknown';
    double subStart = 0;

    for (int i = 0; i < subBoundaries.length; i++) {
      final boundary = subBoundaries[i];
      final start = boundary['start'] as double?;
      final end = boundary['end'] as double?;
      final lord = boundary['lord'] as String?;

      if (start != null && end != null && lord != null) {
        if (positionInNakshatra >= start && positionInNakshatra < end) {
          subLord = lord;
          subStart = start;
          break;
        }
      }
    }

    // Calculate sub-sub-lord within the sub-lord division
    final positionInSub = positionInNakshatra - subStart;
    final subSubLord = _calculateSubSubLord(
      subLord,
      positionInSub,
      subBoundaries,
    );

    return KPSubLord(
      starLord: starLord,
      subLord: subLord,
      subSubLord: subSubLord,
      nakshatraIndex: nakshatraIndex,
      nakshatraName: nakshatraNames[nakshatraIndex],
    );
  }

  /// Calculate unequal sub-boundaries based on vimshottari proportions
  static List<Map<String, dynamic>> _calculateSubBoundaries(
    List<String> subLords,
  ) {
    final List<Map<String, dynamic>> boundaries = [];
    double currentPosition = 0;

    for (final lord in subLords) {
      final period = _dashaPeriods[lord];
      if (period == null) {
        // Skip invalid lords to prevent crashes
        continue;
      }

      final span = (period / _totalDashaYears) * _nakshatraSpan;

      boundaries.add({
        'lord': lord,
        'start': currentPosition,
        'end': currentPosition + span,
        'span': span,
      });

      currentPosition += span;
    }

    return boundaries;
  }

  /// Calculate sub-sub-lord within a sub-division
  static String _calculateSubSubLord(
    String subLord,
    double positionInSub,
    List<Map<String, dynamic>> subBoundaries,
  ) {
    if (subLord == 'Unknown') return 'Unknown';

    try {
      // Find the sub-boundary for this lord
      final subBoundary = subBoundaries.firstWhere(
        (b) => b['lord'] == subLord,
        orElse: () => {},
      );

      if (subBoundary.isEmpty) return 'Unknown';

      final subSpan = subBoundary['span'] as double?;
      if (subSpan == null) return 'Unknown';

      // Sub-sub-lords follow the same vimshottari sequence
      final sequence = _getVimshottariSequence(subLord);
      final List<Map<String, dynamic>> subSubBoundaries = [];
      double currentPos = 0;

      for (final lord in sequence) {
        final period = _dashaPeriods[lord];
        if (period == null) continue;

        final span = (period / _totalDashaYears) * subSpan;

        subSubBoundaries.add({
          'lord': lord,
          'start': currentPos,
          'end': currentPos + span,
        });

        currentPos += span;
      }

      // Find which sub-sub-lord contains the position
      for (final boundary in subSubBoundaries) {
        final start = boundary['start'] as double?;
        final end = boundary['end'] as double?;
        final lord = boundary['lord'] as String?;

        if (start != null && end != null && lord != null) {
          if (positionInSub >= start && positionInSub < end) {
            return lord;
          }
        }
      }

      return sequence.isNotEmpty ? sequence.last : 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get vimshottari sequence starting from a specific planet
  static List<String> _getVimshottariSequence(String startPlanet) {
    const fullSequence = [
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

    final startIndex = fullSequence.indexOf(startPlanet);
    if (startIndex == -1) return fullSequence;

    return [
      ...fullSequence.sublist(startIndex),
      ...fullSequence.sublist(0, startIndex),
    ];
  }

  // ABCD significator method (Standard KP 4-Fold)
  static Map<String, List<String>> calculateSignificators(
    VedicChart chart,
    int house,
  ) {
    // 1. Find Occupants of the house
    final occupants = _getPlanetsInHouse(chart, house);

    // 2. Find Lord of the house (Sign Lord of Cusp)
    final houseIndex = house - 1;
    final cuspLong = _getHouseCuspLongitude(chart, houseIndex);
    final signIndex = (cuspLong / 30).floor();
    final houseLord = _getSignLord(signIndex);

    // Level A: Planets in the Star of an Occupant
    final levelA = <String>[];
    for (var occupant in occupants) {
      levelA.addAll(_getPlanetsByStarLord(chart, occupant));
    }

    // Level B: Occupants themselves
    final levelB = occupants;

    // Level C: Planets in the Star of the House Lord
    // Note: If House Lord is in the star of an occupant, it is already strong,
    // but here we look for OTHER planets whose star lord is this House Lord.
    final levelC = _getPlanetsByStarLord(chart, houseLord);

    // Level D: House Lord itself
    final levelD = [houseLord];

    return {
      'A': levelA.toSet().toList(),
      'B': levelB.toSet().toList(),
      'C': levelC.toSet().toList(),
      'D': levelD.toSet().toList(),
    };
  }

  /// Get planets whose star lord is the given planet
  static List<String> _getPlanetsByStarLord(VedicChart chart, String lordName) {
    List<String> planets = [];
    for (final entry in chart.planets.entries) {
      final pName = _getPlanetName(entry.key);
      final subLord = calculateSubLord(entry.value.longitude);

      if (subLord.starLord == lordName) {
        planets.add(pName);
      }
    }
    return planets;
  }

  /// Get all planets physically located in a house
  static List<String> _getPlanetsInHouse(VedicChart chart, int house) {
    final List<String> planets = [];
    final houseIndex = house - 1;

    chart.planets.forEach((planet, info) {
      final planetHouse = _getHouseForLongitude(chart, info.longitude);
      if (planetHouse == houseIndex) {
        planets.add(_getPlanetName(planet));
      }
    });

    return planets;
  }

  /// Get house number for a given longitude
  static int _getHouseForLongitude(VedicChart chart, double longitude) {
    // Get ascendant degree from first house cusp
    final ascendant = _getHouseCuspLongitude(chart, 0);

    // Calculate which house this longitude falls in
    final relativeDegree = (longitude - ascendant + 360) % 360;
    final houseNumber = (relativeDegree / 30).floor();

    return houseNumber;
  }

  /// Get house cusp longitude - safely access house cusps
  /// Falls back to equal houses from ascendant if cusps unavailable
  /// Get house cusp longitude - safely access house cusps
  /// Falls back to equal houses from ascendant if cusps unavailable
  static double _getHouseCuspLongitude(VedicChart chart, int houseIndex) {
    try {
      // Access houses via dynamic to handle different library versions or potential types
      final housesDynamic = chart.houses as dynamic;

      // Check if it has cusps property (HouseSystem)
      try {
        final cusps = housesDynamic.cusps;
        if (cusps is List && houseIndex < cusps.length) {
          final cusp = cusps[houseIndex];
          if (cusp is num) return cusp.toDouble();
        }
      } catch (_) {}

      // Check if it IS a List directly (backward compatibility)
      if (housesDynamic is List && houseIndex < housesDynamic.length) {
        final cusp = housesDynamic[houseIndex];
        if (cusp is num) return cusp.toDouble();
        if (cusp is Map) {
          final val = cusp['longitude'];
          if (val is num) return val.toDouble();
        }
      }

      // Fallback: Equal House System from Ascendant
      double ascendant = 0.0;

      // Try to get ascendant from cusps[0]
      try {
        final cusps = housesDynamic.cusps;
        if (cusps is List && cusps.isNotEmpty) {
          final first = cusps[0];
          if (first is num) ascendant = first.toDouble();
        }
      } catch (_) {}

      // Try to get ascendant from list[0]
      if (ascendant == 0.0 &&
          housesDynamic is List &&
          housesDynamic.isNotEmpty) {
        final first = housesDynamic[0];
        if (first is num)
          ascendant = first.toDouble();
        else if (first is Map) {
          final val = first['longitude'];
          if (val is num) ascendant = val.toDouble();
        }
      }

      return (ascendant + houseIndex * 30.0) % 360.0;
    } catch (e) {
      return houseIndex * 30.0;
    }
  }

  /// Get planet name from enum
  static String _getPlanetName(Planet planet) {
    return planet.toString().split('.').last;
  }

  /// Get planet enum from name
  static Planet? _getPlanetFromName(String name) {
    try {
      return Planet.values.firstWhere(
        (p) => p.toString().split('.').last.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate ruling planets at a given time
  static List<String> calculateRulingPlanets(
    VedicChart chart,
    DateTime dateTime,
  ) {
    final List<String> rulingPlanets = [];

    // 1. Lagna (Ascendant) Star Lord
    final ascendant = _getHouseCuspLongitude(chart, 0);
    final ascNakshatra = (ascendant / _nakshatraSpan).floor();
    rulingPlanets.add(kpStarLords[ascNakshatra % 27]);

    // 2. Lagna Sign Lord
    final ascSign = (ascendant / 30).floor();
    rulingPlanets.add(_getSignLord(ascSign));

    // 3. Moon Star Lord - find moon planet safely
    Planet? moonPlanet;
    try {
      moonPlanet = Planet.values.firstWhere(
        (p) => p.toString().toLowerCase().contains('moon'),
      );
    } catch (e) {
      // Moon not found in enum
    }

    if (moonPlanet != null) {
      final moonInfo = chart.planets[moonPlanet];
      if (moonInfo != null) {
        final moonNakshatra = (moonInfo.longitude / _nakshatraSpan).floor();
        rulingPlanets.add(kpStarLords[moonNakshatra % 27]);

        // 4. Moon Sign Lord
        final moonSign = (moonInfo.longitude / 30).floor();
        rulingPlanets.add(_getSignLord(moonSign));
      }
    }

    // 5. Day Lord
    rulingPlanets.add(_getDayLord(dateTime.weekday));

    return rulingPlanets.toSet().toList(); // Remove duplicates
  }

  /// Get sign lord for a zodiac sign (0-11)
  static String _getSignLord(int sign) {
    const signLords = [
      'Mars',
      'Venus',
      'Mercury',
      'Moon',
      'Sun',
      'Mercury',
      'Venus',
      'Mars',
      'Jupiter',
      'Saturn',
      'Saturn',
      'Jupiter',
    ];
    return signLords[sign % 12];
  }

  /// Get day lord (1=Monday, 7=Sunday)
  static String _getDayLord(int weekday) {
    const dayLords = [
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Sun',
    ];
    // weekday: 1=Monday, 7=Sunday
    final index = (weekday - 1) % 7;
    return dayLords[index];
  }

  /// Get significations (houses) for a planet using ABCD logic
  static List<int> getPlanetSignifications(String planet, VedicChart chart) {
    final significations = <int>[];
    final planetEnum = _getPlanetFromName(planet);
    if (planetEnum == null) return [];

    final planetInfo = chart.planets[planetEnum];
    if (planetInfo == null) return [];

    // 0. Get star lord of the planet
    final planetSub = calculateSubLord(planetInfo.longitude);
    final starLord = planetSub.starLord;

    final starLordEnum = _getPlanetFromName(starLord);
    VedicPlanetInfo? starLordInfo;
    if (starLordEnum != null) {
      starLordInfo = chart.planets[starLordEnum];
    }

    // Level A: Houses occupied by the star lord
    if (starLordInfo != null) {
      significations.add(
        _getHouseForLongitude(chart, starLordInfo.longitude) + 1,
      );
    }

    // Level B: Houses occupied by the planet itself
    significations.add(_getHouseForLongitude(chart, planetInfo.longitude) + 1);

    // Level C: Houses owned by the star lord
    significations.addAll(_getOwnedHouses(starLord, chart));

    // Level D: Houses owned by the planet itself
    significations.addAll(_getOwnedHouses(planet, chart));

    return significations.toSet().toList();
  }

  /// Get houses owned by a planet
  static List<int> _getOwnedHouses(String planet, VedicChart chart) {
    final List<int> ownedHouses = [];

    final ascendant = _getHouseCuspLongitude(chart, 0);
    final ascSign = (ascendant / 30).floor();

    // For each sign, check if this planet is the lord
    for (int sign = 0; sign < 12; sign++) {
      if (_getSignLord(sign) == planet) {
        // Calculate which house this sign represents
        final house = ((sign - ascSign + 12) % 12) + 1;
        ownedHouses.add(house);
      }
    }

    return ownedHouses;
  }

  /// Get full significator table for all planets
  static Map<String, Map<String, dynamic>> getFullSignificatorTable(
    VedicChart chart,
  ) {
    final Map<String, Map<String, dynamic>> table = {};

    for (final planet in Planet.values) {
      final planetName = _getPlanetName(planet);
      final info = chart.planets[planet];

      if (info != null) {
        final subLord = calculateSubLord(info.longitude);

        table[planetName] = {
          'position': info.longitude,
          'house': _getHouseForLongitude(chart, info.longitude) + 1,
          'starLord': subLord.starLord,
          'subLord': subLord.subLord,
          'subSubLord': subLord.subSubLord,
          'nakshatra': subLord.nakshatraName,
          'significations': getPlanetSignifications(planetName, chart),
        };
      }
    }

    return table;
  }
}
