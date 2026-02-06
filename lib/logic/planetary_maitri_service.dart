import 'package:jyotish/jyotish.dart' hide RelationshipType;

/// Planetary Maitri (Friendship) Analysis Service
/// Calculates Natural, Temporary, and Compound relationships between planets
class PlanetaryMaitriService {
  /// Natural (Naisargika) Friendship Table - Permanent relationships
  static final Map<Planet, Map<Planet, RelationshipType>> _naturalFriendship = {
    Planet.sun: {
      Planet.moon: RelationshipType.friend,
      Planet.mars: RelationshipType.friend,
      Planet.jupiter: RelationshipType.friend,
      Planet.mercury: RelationshipType.neutral,
      Planet.venus: RelationshipType.enemy,
      Planet.saturn: RelationshipType.enemy,
    },
    Planet.moon: {
      Planet.sun: RelationshipType.friend,
      Planet.mercury: RelationshipType.friend,
      Planet.mars: RelationshipType.neutral,
      Planet.jupiter: RelationshipType.neutral,
      Planet.venus: RelationshipType.neutral,
      Planet.saturn: RelationshipType.neutral,
    },
    Planet.mars: {
      Planet.sun: RelationshipType.friend,
      Planet.moon: RelationshipType.friend,
      Planet.jupiter: RelationshipType.friend,
      Planet.venus: RelationshipType.neutral,
      Planet.saturn: RelationshipType.neutral,
      Planet.mercury: RelationshipType.enemy,
    },
    Planet.mercury: {
      Planet.sun: RelationshipType.friend,
      Planet.venus: RelationshipType.friend,
      Planet.moon: RelationshipType.enemy,
      Planet.mars: RelationshipType.neutral,
      Planet.jupiter: RelationshipType.neutral,
      Planet.saturn: RelationshipType.neutral,
    },
    Planet.jupiter: {
      Planet.sun: RelationshipType.friend,
      Planet.moon: RelationshipType.friend,
      Planet.mars: RelationshipType.friend,
      Planet.saturn: RelationshipType.neutral,
      Planet.mercury: RelationshipType.enemy,
      Planet.venus: RelationshipType.enemy,
    },
    Planet.venus: {
      Planet.mercury: RelationshipType.friend,
      Planet.saturn: RelationshipType.friend,
      Planet.mars: RelationshipType.neutral,
      Planet.jupiter: RelationshipType.neutral,
      Planet.sun: RelationshipType.enemy,
      Planet.moon: RelationshipType.enemy,
    },
    Planet.saturn: {
      Planet.mercury: RelationshipType.friend,
      Planet.venus: RelationshipType.friend,
      Planet.jupiter: RelationshipType.neutral,
      Planet.sun: RelationshipType.enemy,
      Planet.moon: RelationshipType.enemy,
      Planet.mars: RelationshipType.enemy,
    },
  };

  /// Get natural relationship between two planets
  static RelationshipType getNaturalRelationship(
    Planet planet1,
    Planet planet2,
  ) {
    if (planet1 == planet2)
      return RelationshipType.friend; // Same planet is friend
    return _naturalFriendship[planet1]?[planet2] ?? RelationshipType.neutral;
  }

  /// Calculate temporary (Tatkalika) relationships based on chart positions
  /// Planets in 2nd, 3rd, 4th, 10th, 11th, 12th houses from each other are temporary friends
  /// Planets in 1st, 5th, 6th, 7th, 8th, 9th houses from each other are temporary enemies
  static Map<Planet, Map<Planet, RelationshipType>>
  calculateTemporaryRelationships(VedicChart chart) {
    final Map<Planet, Map<Planet, RelationshipType>> tempRelations = {};
    final planets = chart.planets.keys.toList();

    for (final planet1 in planets) {
      tempRelations[planet1] = {};
      final pos1 = chart.planets[planet1]!;
      final house1 = (pos1.position.longitude / 30).floor() + 1;

      for (final planet2 in planets) {
        if (planet1 == planet2) continue;

        final pos2 = chart.planets[planet2]!;
        final house2 = (pos2.position.longitude / 30).floor() + 1;

        // Calculate house distance from planet1 to planet2
        int distance = (house2 - house1 + 12) % 12;
        if (distance == 0) distance = 12;

        // Temporary friends: 2, 3, 4, 10, 11, 12
        // Temporary enemies: 1, 5, 6, 7, 8, 9
        if ([2, 3, 4, 10, 11, 12].contains(distance)) {
          tempRelations[planet1]![planet2] = RelationshipType.friend;
        } else {
          tempRelations[planet1]![planet2] = RelationshipType.enemy;
        }
      }
    }

    return tempRelations;
  }

  /// Calculate compound (Panchadha) relationships
  /// Combines natural and temporary relationships:
  /// - Natural Friend + Temporary Friend = Best Friend (Adhi Mitr)
  /// - Natural Friend + Temporary Enemy = Friend (Mitr)
  /// - Natural Neutral + Temporary Friend = Friend (Mitr)
  /// - Natural Neutral + Temporary Enemy = Neutral (Sama)
  /// - Natural Enemy + Temporary Friend = Neutral (Sama)
  /// - Natural Enemy + Temporary Enemy = Enemy (Satru)
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

        compoundRelations[planet1]![planet2] = _getCompoundRelationship(
          natural,
          temporary,
        );
      }
    }

    return compoundRelations;
  }

  /// Get compound relationship from natural and temporary
  static CompoundRelationship _getCompoundRelationship(
    RelationshipType natural,
    RelationshipType temporary,
  ) {
    if (natural == RelationshipType.friend &&
        temporary == RelationshipType.friend) {
      return CompoundRelationship.bestFriend;
    } else if ((natural == RelationshipType.friend &&
            temporary == RelationshipType.enemy) ||
        (natural == RelationshipType.neutral &&
            temporary == RelationshipType.friend)) {
      return CompoundRelationship.friend;
    } else if ((natural == RelationshipType.neutral &&
            temporary == RelationshipType.enemy) ||
        (natural == RelationshipType.enemy &&
            temporary == RelationshipType.friend)) {
      return CompoundRelationship.neutral;
    } else {
      return CompoundRelationship.enemy;
    }
  }

  /// Get all maitri data for a chart
  static PlanetaryMaitriData getAllMaitriData(VedicChart chart) {
    return PlanetaryMaitriData(
      natural: _naturalFriendship,
      temporary: calculateTemporaryRelationships(chart),
      compound: calculateCompoundRelationships(chart),
      chart: chart,
    );
  }

  /// Get relationship description
  static String getRelationshipDescription(RelationshipType type) {
    switch (type) {
      case RelationshipType.friend:
        return 'Friend (Mitr)';
      case RelationshipType.neutral:
        return 'Neutral (Sama)';
      case RelationshipType.enemy:
        return 'Enemy (Satru)';
    }
  }

  /// Get compound relationship description
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

/// Types of planetary relationships
enum RelationshipType { friend, neutral, enemy }

/// Compound relationship types (Panchadha Maitri)
enum CompoundRelationship {
  bestFriend, // Adhi Mitr
  friend, // Mitr
  neutral, // Sama
  enemy, // Satru
}

/// Complete maitri data for a chart
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
