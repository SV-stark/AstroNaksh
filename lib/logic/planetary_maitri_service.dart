import 'package:jyotish/core.dart';
import 'package:jyotish/strength.dart';
import '../core/ephemeris_manager.dart';

/// Planetary Maitri (Friendship) Analysis Service
/// Delegates to the jyotish library's [Jyotish.getPlanetaryRelationshipsMatrix]
/// for all data instead of manually looping through planets.
class PlanetaryMaitriService {
  static RelationshipType getNaturalRelationship(
    Planet planet1,
    Planet planet2,
  ) {
    if (planet1 == planet2) return RelationshipType.friend;
    return RelationshipCalculator.naturalRelationships[planet1]?[planet2] ??
        RelationshipType.neutral;
  }

  static Map<Planet, Map<Planet, RelationshipType>>
  calculateTemporaryRelationships(VedicChart chart) {
    final matrix = EphemerisManager.jyotish.getPlanetaryRelationshipsMatrix(
      chart,
    );
    final tempRelations = <Planet, Map<Planet, RelationshipType>>{};
    matrix.forEach((planet, row) {
      tempRelations[planet] = {};
      row.forEach((other, rel) {
        tempRelations[planet]![other] = rel.temporary;
      });
    });
    return tempRelations;
  }

  static Map<Planet, Map<Planet, CompoundRelationship>>
  calculateCompoundRelationships(VedicChart chart) {
    final matrix = EphemerisManager.jyotish.getPlanetaryRelationshipsMatrix(
      chart,
    );
    final compoundRelations = <Planet, Map<Planet, CompoundRelationship>>{};
    matrix.forEach((planet, row) {
      compoundRelations[planet] = {};
      row.forEach((other, rel) {
        compoundRelations[planet]![other] = _mapToCompoundRelationship(
          rel.compound,
        );
      });
    });
    return compoundRelations;
  }

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

  static PlanetaryMaitriData getAllMaitriData(VedicChart chart) {
    final matrix = EphemerisManager.jyotish.getPlanetaryRelationshipsMatrix(
      chart,
    );

    final natural = <Planet, Map<Planet, RelationshipType>>{};
    final temporary = <Planet, Map<Planet, RelationshipType>>{};
    final compound = <Planet, Map<Planet, CompoundRelationship>>{};

    matrix.forEach((planet, row) {
      natural[planet] = {};
      temporary[planet] = {};
      compound[planet] = {};
      row.forEach((other, rel) {
        natural[planet]![other] = rel.natural;
        temporary[planet]![other] = rel.temporary;
        compound[planet]![other] = _mapToCompoundRelationship(rel.compound);
      });
    });

    return PlanetaryMaitriData(
      natural: natural,
      temporary: temporary,
      compound: compound,
      chart: chart,
    );
  }

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
  PlanetaryMaitriData({
    required this.natural,
    required this.temporary,
    required this.compound,
    required this.chart,
  });
  final Map<Planet, Map<Planet, RelationshipType>> natural;
  final Map<Planet, Map<Planet, RelationshipType>> temporary;
  final Map<Planet, Map<Planet, CompoundRelationship>> compound;
  final VedicChart chart;
}
