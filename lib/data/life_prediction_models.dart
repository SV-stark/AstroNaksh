// ignore_for_file: avoid_slow_async_io, unawaited_futures, deprecated_member_use, sort_constructors_first, implementation_imports
// Life Predictions Data Models
// Models for life aspect predictions based on Vedic astrology

import 'package:jyotish/jyotish.dart';

/// Represents a planet's influence on a life aspect
class PlanetaryInfluence {
  // Positive or negative influence

  const PlanetaryInfluence({
    required this.planet,
    required this.position,
    required this.status,
    required this.strength,
    required this.effect,
    required this.isBenefic,
  });

  final Planet planet;
  String get planetName => planet.displayName;
  final String position; // e.g., "Sun in 10th House in Leo"
  final String status; // "Exalted", "Own Sign", "Debilitated", "Neutral"
  final double strength; // Shadbala strength (normalized 0-100)
  final String effect; // How it affects this aspect
  final bool isBenefic;
}

/// Represents a life aspect category (family, career, health, etc.)
class LifeAspectPrediction {
  // Houses that govern this aspect

  const LifeAspectPrediction({
    required this.aspectName,
    required this.aspectDescription,
    required this.iconName,
    required this.score,
    required this.prediction,
    required this.influences,
    required this.advice,
    required this.relevantHouses,
  });
  final String aspectName; // e.g., "Career", "Family", "Health"
  final String
      aspectDescription; // Brief description of what this aspect covers
  final String iconName; // FluentIcon name
  final int score; // 40-95 range
  final String prediction; // Detailed prediction text
  final List<PlanetaryInfluence> influences; // Planets affecting this aspect
  final String advice; // Remedial/enhancement suggestions
  final List<int> relevantHouses;

  /// Get color for this score
  String get scoreLabel {
    if (score >= 86) return 'Excellent';
    if (score >= 71) return 'Good';
    if (score >= 56) return 'Average';
    return 'Challenging';
  }
}

/// Complete life predictions result
class LifePredictionsResult {
  const LifePredictionsResult({
    required this.aspects,
    required this.overallScore,
    required this.overallSummary,
    required this.generatedAt,
  });

  /// Calculate overall score from aspect scores
  factory LifePredictionsResult.fromAspects(
    List<LifeAspectPrediction> aspects,
  ) {
    final avgScore = aspects.isEmpty
        ? 65
        : (aspects.map((a) => a.score).reduce((a, b) => a + b) / aspects.length)
            .round();

    // Identify strongest and weakest aspects for the summary
    final sortedAspects = List<LifeAspectPrediction>.from(aspects)
      ..sort((a, b) => b.score.compareTo(a.score));
    final strongest = sortedAspects.isNotEmpty ? sortedAspects.first : null;
    final weakest = sortedAspects.length > 1 ? sortedAspects.last : null;

    // Find key planetary highlights
    var planetaryNote = '';
    if (strongest != null && strongest.influences.isNotEmpty) {
      final topInfluence = strongest.influences.first;
      planetaryNote =
          ' ${topInfluence.planetName} (${topInfluence.status}) in your chart particularly strengthens ${strongest.aspectName.toLowerCase()}.';
    }

    String summary;
    if (avgScore >= 80) {
      summary =
          'Your birth chart shows strong positive influences across most life areas. '
          'The planetary alignments favor success, happiness and spiritual growth.$planetaryNote';
    } else if (avgScore >= 65) {
      summary =
          'Your chart indicates a balanced life path with good opportunities. '
          'Some areas may require extra attention but overall prospects are favorable.$planetaryNote';
      if (weakest != null && weakest.score < 55) {
        summary +=
            ' ${weakest.aspectName} (score: ${weakest.score}) may need focused remedial action.';
      }
    } else {
      summary =
          'Your chart shows mixed influences requiring focused effort in key areas. '
          'With awareness and right actions, challenges can be transformed into growth.$planetaryNote';
    }

    return LifePredictionsResult(
      aspects: aspects,
      overallScore: avgScore,
      overallSummary: summary,
      generatedAt: DateTime.now(),
    );
  }
  final List<LifeAspectPrediction> aspects;
  final int overallScore;
  final String overallSummary;
  final DateTime generatedAt;
}

/// Life aspect definitions with astrological significations
enum LifeAspect {
  career(
    name: 'Career & Profession',
    description: 'Professional life, career growth, and public recognition',
    icon: 'work',
    houses: [10, 6, 2],
    primaryPlanets: [Planet.sun, Planet.saturn, Planet.mercury],
  ),
  wealth(
    name: 'Wealth & Finance',
    description: 'Financial prosperity, assets, and material abundance',
    icon: 'money',
    houses: [2, 11, 5, 9],
    primaryPlanets: [Planet.venus, Planet.jupiter, Planet.moon],
  ),
  family(
    name: 'Family & Home',
    description: 'Family relationships, domestic harmony, and property',
    icon: 'home',
    houses: [4, 2],
    primaryPlanets: [Planet.moon, Planet.venus, Planet.mars],
  ),
  romance(
    name: 'Romance & Marriage',
    description: 'Love life, partnerships, and marital happiness',
    icon: 'heart',
    houses: [7, 5],
    primaryPlanets: [Planet.venus, Planet.mars, Planet.jupiter],
  ),
  health(
    name: 'Health & Vitality',
    description: 'Physical health, energy levels, and longevity',
    icon: 'health',
    houses: [1, 6, 8],
    primaryPlanets: [Planet.sun, Planet.mars, Planet.saturn],
  ),
  children(
    name: 'Children & Creativity',
    description: 'Offspring, creative expression, and intelligence',
    icon: 'child',
    houses: [5, 9],
    primaryPlanets: [Planet.jupiter, Planet.moon, Planet.mercury],
  ),
  education(
    name: 'Education & Wisdom',
    description: 'Learning, knowledge acquisition, and intellectual growth',
    icon: 'education',
    houses: [4, 5, 9],
    primaryPlanets: [Planet.mercury, Planet.jupiter, Planet.sun],
  ),
  spirituality(
    name: 'Spirituality',
    description: 'Spiritual growth, enlightenment, and inner peace',
    icon: 'peace',
    houses: [9, 12, 5],
    primaryPlanets: [Planet.jupiter, Planet.meanNode, Planet.sun],
  );

  final String name;
  final String description;
  final String icon;
  final List<int> houses;
  final List<Planet> primaryPlanets;

  const LifeAspect({
    required this.name,
    required this.description,
    required this.icon,
    required this.houses,
    required this.primaryPlanets,
  });
}
