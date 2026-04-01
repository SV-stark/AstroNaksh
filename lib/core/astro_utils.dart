import 'package:jyotish/jyotish.dart';

/// Centralized astrology constants and utilities.
/// Single source of truth for planetary data to eliminate duplication
/// across the codebase (DP1, DP2, DP3, DP4, DP5, DP7).
class AstroUtils {
  AstroUtils._();

  /// Sign names in order (Aries = 0 through Pisces = 11).
  static const signNames = [
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

  /// Nakshatra names in order (Ashwini = 0 through Revati = 26).
  static const nakshatraNames = [
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

  /// Degrees per zodiac sign.
  static const degreesPerSign = 30.0;

  /// Degrees per nakshatra.
  static const degreesPerNakshatra = 360.0 / 27;

  /// Number of houses/signs/nakshatras.
  static const houseCount = 12;
  static const signCount = 12;
  static const nakshatraCount = 27;

  /// Sign lord mapping (0-indexed: Aries=0 → Mars, etc.).
  static const _signLords = [
    Planet.mars, // Aries
    Planet.venus, // Taurus
    Planet.mercury, // Gemini
    Planet.moon, // Cancer
    Planet.sun, // Leo
    Planet.mercury, // Virgo
    Planet.venus, // Libra
    Planet.mars, // Scorpio
    Planet.jupiter, // Sagittarius
    Planet.saturn, // Capricorn
    Planet.saturn, // Aquarius
    Planet.jupiter, // Pisces
  ];

  /// Get the lord of a sign (0 = Aries, 11 = Pisces).
  static Planet getSignLord(int signIndex) {
    final idx = signIndex % signCount;
    return _signLords[idx < 0 ? idx + signCount : idx];
  }

  /// Get sign name by index (0 = Aries, 11 = Pisces).
  static String getSignName(int signIndex) {
    final idx = signIndex % signCount;
    return signNames[idx < 0 ? idx + signCount : idx];
  }

  /// Get nakshatra name by index (0 = Ashwini, 26 = Revati).
  static String getNakshatraName(int nakshatraIndex) {
    final idx = nakshatraIndex % nakshatraCount;
    return nakshatraNames[idx < 0 ? idx + nakshatraCount : idx];
  }

  /// Get sign index from longitude.
  static int longitudeToSignIndex(double longitude) {
    return ((longitude % 360) / degreesPerSign).floor() % signCount;
  }

  /// Get nakshatra index from longitude.
  static int longitudeToNakshatraIndex(double longitude) {
    return ((longitude % 360) / degreesPerNakshatra).floor() % nakshatraCount;
  }

  /// Get ordinal suffix for a number (1st, 2nd, 3rd, etc.).
  static String ordinal(int n) {
    if (n <= 0) return '$n';
    final suffixes = ['th', 'st', 'nd', 'rd'];
    final mod100 = n % 100;
    final suffix = (mod100 >= 11 && mod100 <= 13)
        ? 'th'
        : suffixes[n % 10 < 4 ? n % 10 : 0];
    return '$n$suffix';
  }

  /// Natural benefic planets.
  static const naturalBenefics = {
    Planet.jupiter,
    Planet.venus,
    Planet.moon,
    Planet.mercury,
  };

  /// Natural malefic planets.
  static const naturalMalefics = {
    Planet.saturn,
    Planet.mars,
    Planet.sun,
    Planet.meanNode, // Rahu
    Planet.trueNode, // Also Rahu
  };

  /// Check if a planet is naturally benefic.
  static bool isNaturalBenefic(Planet planet) =>
      naturalBenefics.contains(planet);

  /// Check if a planet is naturally malefic.
  static bool isNaturalMalefic(Planet planet) =>
      naturalMalefics.contains(planet);

  /// Vimshottari dasha periods in years.
  static const vimshottariPeriods = {
    Planet.sun: 6,
    Planet.moon: 10,
    Planet.mars: 7,
    Planet.meanNode: 18,
    Planet.jupiter: 16,
    Planet.saturn: 19,
    Planet.mercury: 17,
    Planet.ketu: 7,
    Planet.venus: 20,
  };

  /// Vimshottari dasha lord order (by nakshatra lord sequence).
  static const vimshottariOrder = [
    Planet.ketu,
    Planet.venus,
    Planet.sun,
    Planet.moon,
    Planet.mars,
    Planet.meanNode,
    Planet.jupiter,
    Planet.saturn,
    Planet.mercury,
  ];

  /// Exaltation sign and degree for each planet.
  static const exaltations = {
    Planet.sun: (4, 10.0), // Aries, 10°
    Planet.moon: (1, 3.0), // Taurus, 3°
    Planet.mars: (9, 28.0), // Capricorn, 28°
    Planet.mercury: (5, 15.0), // Virgo, 15°
    Planet.jupiter: (3, 5.0), // Cancer, 5°
    Planet.venus: (11, 27.0), // Pisces, 27°
    Planet.saturn: (6, 20.0), // Libra, 20°
  };

  /// Debilitation sign and degree for each planet.
  static const debilitations = {
    Planet.sun: (6, 10.0), // Libra, 10°
    Planet.moon: (7, 3.0), // Scorpio, 3°
    Planet.mars: (3, 28.0), // Cancer, 28°
    Planet.mercury: (11, 15.0), // Pisces, 15°
    Planet.jupiter: (9, 5.0), // Capricorn, 5°
    Planet.venus: (5, 27.0), // Virgo, 27°
    Planet.saturn: (0, 20.0), // Aries, 20°
  };

  /// Own signs for each planet.
  static const ownSigns = {
    Planet.sun: [4], // Leo
    Planet.moon: [3], // Cancer
    Planet.mars: [0, 7], // Aries, Scorpio
    Planet.mercury: [2, 5], // Gemini, Virgo
    Planet.jupiter: [8, 11], // Sagittarius, Pisces
    Planet.venus: [1, 6], // Taurus, Libra
    Planet.saturn: [9, 10], // Capricorn, Aquarius
  };

  /// Moola trikona signs for each planet.
  static const moolaTrikona = {
    Planet.sun: [4], // Leo
    Planet.moon: [3], // Cancer
    Planet.mars: [0], // Aries
    Planet.mercury: [5], // Virgo
    Planet.jupiter: [8], // Sagittarius
    Planet.venus: [6], // Libra
    Planet.saturn: [9], // Capricorn
  };

  /// Natural planetary friendship matrix.
  /// Returns: 1 = friend, 0 = neutral, -1 = enemy.
  static const _friendshipMatrix = {
    Planet.sun: {
      Planet.sun: 0,
      Planet.moon: 1,
      Planet.mars: 1,
      Planet.mercury: 1,
      Planet.jupiter: 1,
      Planet.venus: -1,
      Planet.saturn: -1,
    },
    Planet.moon: {
      Planet.sun: 1,
      Planet.moon: 0,
      Planet.mars: 1,
      Planet.mercury: 1,
      Planet.jupiter: 1,
      Planet.venus: 1,
      Planet.saturn: -1,
    },
    Planet.mars: {
      Planet.sun: 1,
      Planet.moon: 1,
      Planet.mars: 0,
      Planet.mercury: 1,
      Planet.jupiter: 1,
      Planet.venus: -1,
      Planet.saturn: -1,
    },
    Planet.mercury: {
      Planet.sun: 1,
      Planet.moon: 1,
      Planet.mars: 1,
      Planet.mercury: 0,
      Planet.jupiter: 1,
      Planet.venus: 1,
      Planet.saturn: -1,
    },
    Planet.jupiter: {
      Planet.sun: 1,
      Planet.moon: 1,
      Planet.mars: 1,
      Planet.mercury: 1,
      Planet.jupiter: 0,
      Planet.venus: -1,
      Planet.saturn: -1,
    },
    Planet.venus: {
      Planet.sun: -1,
      Planet.moon: 1,
      Planet.mars: -1,
      Planet.mercury: 1,
      Planet.jupiter: -1,
      Planet.venus: 0,
      Planet.saturn: 1,
    },
    Planet.saturn: {
      Planet.sun: -1,
      Planet.moon: -1,
      Planet.mars: -1,
      Planet.mercury: 1,
      Planet.jupiter: -1,
      Planet.venus: 1,
      Planet.saturn: 0,
    },
  };

  /// Get natural friendship between two planets.
  /// Returns: 1 = friend, 0 = neutral, -1 = enemy.
  static int getPlanetFriendship(Planet planet1, Planet planet2) {
    if (planet1 == planet2) return 0;
    return _friendshipMatrix[planet1]?[planet2] ?? 0;
  }
}
