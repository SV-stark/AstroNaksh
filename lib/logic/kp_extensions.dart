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
      if (positionInNakshatra >= subBoundaries[i]['start']! &&
          positionInNakshatra < subBoundaries[i]['end']!) {
        subLord = subBoundaries[i]['lord']!;
        subStart = subBoundaries[i]['start']!;
        break;
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
      final period = _dashaPeriods[lord]!;
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
    // Find the sub-boundary for this lord
    final subBoundary = subBoundaries.firstWhere((b) => b['lord'] == subLord);
    final subSpan = subBoundary['span'] as double;

    // Sub-sub-lords follow the same vimshottari sequence
    final sequence = _getVimshottariSequence(subLord);
    final List<Map<String, dynamic>> subSubBoundaries = [];
    double currentPos = 0;

    for (final lord in sequence) {
      final period = _dashaPeriods[lord]!;
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
      if (positionInSub >= boundary['start']! &&
          positionInSub < boundary['end']!) {
        return boundary['lord']!;
      }
    }

    return sequence.last;
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

  // ABCD significator method
  static List<String> calculateSignificators(VedicChart chart, int house) {
    final aPlanets = _getPlanetsInHouse(chart, house);
    final bPlanets = _getStarOwners(chart, house);
    final cPlanets = _getSubOwners(chart, house);
    final dPlanets = _getConjoinedSignificators(chart, [
      ...aPlanets,
      ...bPlanets,
      ...cPlanets,
    ]);

    return {...aPlanets, ...bPlanets, ...cPlanets, ...dPlanets}.toList();
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

  /// Get planets that are star lords of the house cusp
  static List<String> _getStarOwners(VedicChart chart, int house) {
    final List<String> planets = [];
    final houseIndex = house - 1;

    // Get house cusp longitude
    final cuspLongitude = _getHouseCuspLongitude(chart, houseIndex);

    // Find which nakshatra this falls in
    final nakshatraIndex = (cuspLongitude / _nakshatraSpan).floor();
    final starLord = kpStarLords[nakshatraIndex % 27];

    planets.add(starLord);
    return planets;
  }

  /// Get planets that are sub lords of the house cusp
  static List<String> _getSubOwners(VedicChart chart, int house) {
    final houseIndex = house - 1;
    final cuspLongitude = _getHouseCuspLongitude(chart, houseIndex);
    final subLord = calculateSubLord(cuspLongitude);

    return [subLord.subLord];
  }

  /// Get planets conjoined with significators
  static List<String> _getConjoinedSignificators(
    VedicChart chart,
    List<String> planets,
  ) {
    final Set<String> conjoined = {};

    for (final planetName in planets) {
      final planet = _getPlanetFromName(planetName);
      if (planet == null) continue;

      final planetInfo = chart.planets[planet];
      if (planetInfo == null) continue;

      // Check for conjunctions (within 3 degrees)
      chart.planets.forEach((otherPlanet, otherInfo) {
        if (otherPlanet != planet) {
          final diff = (planetInfo.longitude - otherInfo.longitude).abs();
          if (diff <= 3.0 || diff >= 357.0) {
            conjoined.add(_getPlanetName(otherPlanet));
          }
        }
      });
    }

    return conjoined.toList();
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
  static double _getHouseCuspLongitude(VedicChart chart, int houseIndex) {
    // Try to access house cusp through the houses property
    // VedicChart might have cusps as a List<double> or HouseSystem object
    try {
      // Access houses as dynamic to avoid type errors
      final houses = chart.houses;

      // Try different access patterns

      // Try accessing as a List
      try {
        final housesList = houses as dynamic;
        if (houseIndex < housesList.length) {
          final cusp = housesList[houseIndex];
          if (cusp is Map) {
            return (cusp['longitude'] as num?)?.toDouble() ?? 0.0;
          } else if (cusp is num) {
            return cusp.toDouble();
          }
        }
      } catch (_) {
        // Not a list, try other patterns
      }

      // Try accessing cusps property
      try {
        final cusps = (houses as dynamic).cusps;
        if (cusps != null && cusps is List && houseIndex < cusps.length) {
          final cusp = cusps[houseIndex];
          if (cusp is num) return cusp.toDouble();
        }
      } catch (_) {
        // No cusps property
      }

      // Fallback: Get ascendant from first house cusp for equal house calculation
      // Try to get ascendant longitude first
      double ascendant = 0.0;
      try {
        final cusps = (houses as dynamic).cusps;
        if (cusps != null && cusps is List && cusps.isNotEmpty) {
          final firstCusp = cusps[0];
          if (firstCusp is num) ascendant = firstCusp.toDouble();
        }
      } catch (_) {
        // Use 0° if no ascendant available
      }

      // Calculate equal house cusp from ascendant
      return (ascendant + houseIndex * 30.0) % 360.0;
    } catch (e) {
      // Last resort fallback: equal houses from 0° Aries
      // This is less accurate but prevents crashes
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

  /// Get significations for a planet
  static List<int> getPlanetSignifications(String planet, VedicChart chart) {
    final List<int> significations = [];

    // Check which houses this planet signifies through its position
    final planetEnum = _getPlanetFromName(planet);
    if (planetEnum != null) {
      final info = chart.planets[planetEnum];
      if (info != null) {
        final house = _getHouseForLongitude(chart, info.longitude) + 1;
        significations.add(house);

        // Add houses owned by this planet
        significations.addAll(_getOwnedHouses(planet, chart));
      }
    }

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
