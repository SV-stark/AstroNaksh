import 'package:jyotish/jyotish.dart';

/// Planetary Maitri (Friendship) Analysis Service
/// Calculates Natural, Temporary, and Compound relationships between planets.
/// Delegates to the jyotish library's [RelationshipCalculator] for all data.
class PlanetaryMaitriService {
  /// Get natural relationship between two planets.
  /// Uses [RelationshipCalculator.naturalRelationships] from the library.
  static RelationshipType getNaturalRelationship(
    Planet planet1,
    Planet planet2,
  ) {
    if (planet1 == planet2) return RelationshipType.friend;
    return RelationshipCalculator.naturalRelationships[planet1]?[planet2] ??
        RelationshipType.neutral;
  }

  /// Calculate temporary (Tatkalika) relationships based on chart positions.
  /// Uses [RelationshipCalculator.calculateTemporary] from the library.
  static Map<Planet, Map<Planet, RelationshipType>>
  calculateTemporaryRelationships(VedicChart chart) {
    final Map<Planet, Map<Planet, RelationshipType>> tempRelations = {};
    final planets = chart.planets.keys.toList();

    for (final planet1 in planets) {
      tempRelations[planet1] = {};
      // Use .zodiacSignIndex instead of (longitude / 30).floor()
      final sign1 = chart.planets[planet1]!.position.zodiacSignIndex;

      for (final planet2 in planets) {
        if (planet1 == planet2) continue;
        final sign2 = chart.planets[planet2]!.position.zodiacSignIndex;
        tempRelations[planet1]![planet2] =
            RelationshipCalculator.calculateTemporary(sign1, sign2);
      }
    }

    return tempRelations;
  }

  /// Calculate compound (Panchadha) relationships.
  /// Uses [RelationshipCalculator.calculateCompound] from the library.
  static Map<Planet, Map<Planet, CompoundRelationship>>
  calculateCompoundRelationships(VedicChart chart) {
    final tempRelations = calculateTemporaryRelationships(chart);
    final Map<Planet, Map<Planet, CompoundRelationship>> compoundRelations = {};
    final planets = chart.planets.keys.toList();

    for (final planet1 in planets) {
      compoundRelations[planet1] = {};

      for (final planet2 in planets) {
        if (planet1 == planet2) continue;

        final natural = getNaturalRelationship(planet1, planet2);
        final temporary =
            tempRelations[planet1]?[planet2] ?? RelationshipType.neutral;

        final libraryCompound = RelationshipCalculator.calculateCompound(
          natural,
          temporary,
        );
        compoundRelations[planet1]![planet2] = _mapToCompoundRelationship(
          libraryCompound,
        );
      }
    }

    return compoundRelations;
  }

  /// Maps the library's 5-value [RelationshipType] to the local 4-value
  /// [CompoundRelationship] for UI display.
  static CompoundRelationship _mapToCompoundRelationship(
    RelationshipType type,
  ) {
    switch (type) {
      case RelationshipType.greatFriend:
        return CompoundRelationship.bestFriend;
      case RelationshipType.friend:
        return CompoundRelationship.friend;
      case RelationshipType.neutral:
        return CompoundRelationship.neutral;
      case RelationshipType.enemy:
      case RelationshipType.greatEnemy:
        return CompoundRelationship.enemy;
    }
  }

  /// Get all maitri data for a chart.
  static PlanetaryMaitriData getAllMaitriData(VedicChart chart) {
    return PlanetaryMaitriData(
      natural: RelationshipCalculator.naturalRelationships,
      temporary: calculateTemporaryRelationships(chart),
      compound: calculateCompoundRelationships(chart),
      chart: chart,
    );
  }

  /// Get relationship description.
  static String getRelationshipDescription(RelationshipType type) {
    switch (type) {
      case RelationshipType.greatFriend:
        return 'Great Friend (Adhi Mitr)';
      case RelationshipType.friend:
        return 'Friend (Mitr)';
      case RelationshipType.neutral:
        return 'Neutral (Sama)';
      case RelationshipType.enemy:
        return 'Enemy (Satru)';
      case RelationshipType.greatEnemy:
        return 'Great Enemy (Adhi Satru)';
    }
  }

  /// Get compound relationship description.
  static String getCompoundRelationshipDescription(CompoundRelationship type) {
    switch (type) {
      case CompoundRelationship.bestFriend:
        return 'Best Friend (Adhi Mitr)';
      case CompoundRelationship.friend:
        return 'Friend (Mitr)';
      case CompoundRelationship.neutral:
        return 'Neutral (Sama)';
      case CompoundRelationship.enemy:
        return 'Enemy (Satru)';
    }
  }
}

/// Compound relationship types for UI display (simplified from library's 5-value enum).
enum CompoundRelationship {
  bestFriend, // Great Friend (Adhi Mitr)
  friend, // Friend (Mitr)
  neutral, // Neutral (Sama)
  enemy, // Enemy or Great Enemy
}

/// Complete maitri data for a chart.
class PlanetaryMaitriData {
  final Map<Planet, Map<Planet, RelationshipType>> natural;
  final Map<Planet, Map<Planet, RelationshipType>> temporary;
  final Map<Planet, Map<Planet, CompoundRelationship>> compound;
  final VedicChart chart;

  PlanetaryMaitriData({
    required this.natural,
    required this.temporary,
    required this.compound,
    required this.chart,
  });
}
