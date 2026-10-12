import 'package:jyotish/src/models/planet.dart';

/// Enumeration of the 12 Rashi (Zodiac Signs).
enum Rashi {
  aries('Aries', 'Mesha', 0),
  taurus('Taurus', 'Vrishabha', 1),
  gemini('Gemini', 'Mithuna', 2),
  cancer('Cancer', 'Karka', 3),
  leo('Leo', 'Simha', 4),
  virgo('Virgo', 'Kanya', 5),
  libra('Libra', 'Tula', 6),
  scorpio('Scorpio', 'Vrishchika', 7),
  sagittarius('Sagittarius', 'Dhanu', 8),
  capricorn('Capricorn', 'Makara', 9),
  aquarius('Aquarius', 'Kumbha', 10),
  pisces('Pisces', 'Meena', 11);

  const Rashi(this.label, this.sanskritName, this.number);

  /// Human-readable English name of the sign, for display only.
  ///
  /// Deliberately **not** called `name`: that would shadow the enum's own
  /// `name` getter, so `Rashi.aries.name` would return 'Aries' instead of the
  /// identifier 'aries'.  Use the identifier for persistence and matching.
  final String label;

  /// Sanskrit name of the sign
  final String sanskritName;

  /// 0-indexed position (Aries=0, Pisces=11)
  final int number;

  /// Returns the Rashi for a given longitude (0-360).
  static Rashi fromLongitude(double longitude) {
    final norm = (longitude % 360.0 + 360.0) % 360.0;
    final idx = (norm / 30).floor() % 12;
    return Rashi.values[idx];
  }

  /// Returns the Rashi for a given index (0-11).
  static Rashi fromIndex(int index) {
    return Rashi.values[(index % 12 + 12) % 12];
  }

  /// Whether this is an odd sign (Aries, Gemini, etc.)
  bool get isOdd => (number + 1) % 2 != 0;

  /// Whether this is an even sign (Taurus, Cancer, etc.)
  bool get isEven => !isOdd;

  /// Returns the traditional ruling planet (lord) of this sign.
  ///
  /// Traditional sign-lords per Parashara:
  /// - Aries, Scorpio  Mars
  /// - Taurus, Libra  Venus
  /// - Gemini, Virgo  Mercury
  /// - Cancer  Moon
  /// - Leo  Sun
  /// - Sagittarius, Pisces  Jupiter
  /// - Capricorn, Aquarius  Saturn
  Planet get lord => switch (this) {
        Rashi.aries || Rashi.scorpio => Planet.mars,
        Rashi.taurus || Rashi.libra => Planet.venus,
        Rashi.gemini || Rashi.virgo => Planet.mercury,
        Rashi.cancer => Planet.moon,
        Rashi.leo => Planet.sun,
        Rashi.sagittarius || Rashi.pisces => Planet.jupiter,
        Rashi.capricorn || Rashi.aquarius => Planet.saturn,
      };

  @override
  String toString() => label;
}
