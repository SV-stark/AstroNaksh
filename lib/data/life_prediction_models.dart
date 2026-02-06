/// Life Predictions Data Models
/// Models for life aspect predictions based on Vedic astrology

/// Represents a planet's influence on a life aspect
class PlanetaryInfluence {
  final String planetName;
  final String position; // e.g., "Sun in 10th House in Leo"
  final String status; // "Exalted", "Own Sign", "Debilitated", "Neutral"
  final double strength; // Shadbala strength (normalized 0-100)
  final String effect; // How it affects this aspect
  final bool isBenefic; // Positive or negative influence

  const PlanetaryInfluence({
    required this.planetName,
    required this.position,
    required this.status,
    required this.strength,
    required this.effect,
    required this.isBenefic,
  });
}

/// Represents a life aspect category (family, career, health, etc.)
class LifeAspectPrediction {
  final String aspectName; // e.g., "Career", "Family", "Health"
  final String aspectDescription; // Brief description of what this aspect covers
  final String iconName; // FluentIcon name
  final int score; // 40-95 range
  final String prediction; // Detailed prediction text
  final List<PlanetaryInfluence> influences; // Planets affecting this aspect
  final String advice; // Remedial/enhancement suggestions
  final List<int> relevantHouses; // Houses that govern this aspect

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
  final List<LifeAspectPrediction> aspects;
  final int overallScore;
  final String overallSummary;
  final DateTime generatedAt;

  const LifePredictionsResult({
    required this.aspects,
    required this.overallScore,
    required this.overallSummary,
    required this.generatedAt,
  });

  /// Calculate overall score from aspect scores
  factory LifePredictionsResult.fromAspects(List<LifeAspectPrediction> aspects) {
    final avgScore = aspects.isEmpty
        ? 65
        : (aspects.map((a) => a.score).reduce((a, b) => a + b) / aspects.length)
            .round();

    String summary;
    if (avgScore >= 80) {
      summary =
          'Your birth chart shows strong positive influences across most life areas. '
          'The planetary alignments favor success, happiness and spiritual growth.';
    } else if (avgScore >= 65) {
      summary =
          'Your chart indicates a balanced life path with good opportunities. '
          'Some areas may require extra attention but overall prospects are favorable.';
    } else {
      summary =
          'Your chart shows mixed influences requiring focused effort in key areas. '
          'With awareness and right actions, challenges can be transformed into growth.';
    }

    return LifePredictionsResult(
      aspects: aspects,
      overallScore: avgScore,
      overallSummary: summary,
      generatedAt: DateTime.now(),
    );
  }
}

/// Life aspect definitions with astrological significations
enum LifeAspect {
  career(
    name: 'Career & Profession',
    description: 'Professional life, career growth, and public recognition',
    icon: 'work',
    houses: [10, 6, 2],
    primaryPlanets: ['Sun', 'Saturn', 'Mercury'],
  ),
  wealth(
    name: 'Wealth & Finance',
    description: 'Financial prosperity, assets, and material abundance',
    icon: 'money',
    houses: [2, 11, 5, 9],
    primaryPlanets: ['Venus', 'Jupiter', 'Moon'],
  ),
  family(
    name: 'Family & Home',
    description: 'Family relationships, domestic harmony, and property',
    icon: 'home',
    houses: [4, 2],
    primaryPlanets: ['Moon', 'Venus', 'Mars'],
  ),
  romance(
    name: 'Romance & Marriage',
    description: 'Love life, partnerships, and marital happiness',
    icon: 'heart',
    houses: [7, 5],
    primaryPlanets: ['Venus', 'Mars', 'Jupiter'],
  ),
  health(
    name: 'Health & Vitality',
    description: 'Physical health, energy levels, and longevity',
    icon: 'health',
    houses: [1, 6, 8],
    primaryPlanets: ['Sun', 'Mars', 'Saturn'],
  ),
  children(
    name: 'Children & Creativity',
    description: 'Offspring, creative expression, and intelligence',
    icon: 'child',
    houses: [5, 9],
    primaryPlanets: ['Jupiter', 'Moon', 'Mercury'],
  ),
  education(
    name: 'Education & Wisdom',
    description: 'Learning, knowledge acquisition, and intellectual growth',
    icon: 'education',
    houses: [4, 5, 9],
    primaryPlanets: ['Mercury', 'Jupiter', 'Sun'],
  ),
  spirituality(
    name: 'Spirituality',
    description: 'Spiritual growth, enlightenment, and inner peace',
    icon: 'peace',
    houses: [9, 12, 5],
    primaryPlanets: ['Jupiter', 'Ketu', 'Sun'],
  );

  final String name;
  final String description;
  final String icon;
  final List<int> houses;
  final List<String> primaryPlanets;

  const LifeAspect({
    required this.name,
    required this.description,
    required this.icon,
    required this.houses,
    required this.primaryPlanets,
  });
}
