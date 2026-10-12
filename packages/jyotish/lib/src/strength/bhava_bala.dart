/// Represents Bhava Bala (house strength) result.
class BhavaBalaResult {
  const BhavaBalaResult({
    required this.houseNumber,
    required this.strength,
    required this.category,
    this.lordStrength = 0,
    this.placementStrength = 0,
    this.aspectStrength = 0,
    this.digBala = 0,
  });

  /// House number (1-12)
  final int houseNumber;

  /// Total strength value
  final double strength;

  /// Strength category
  final BhavaStrengthCategory category;

  /// Components of Bhava Bala
  final double lordStrength;
  final double placementStrength;
  final double aspectStrength;
  final double digBala;

  @override
  String toString() {
    return 'House $houseNumber: ${strength.toStringAsFixed(1)} (${category.name})';
  }
}

/// Bhava strength categories
enum BhavaStrengthCategory {
  veryStrong('Very Strong', 480, double.infinity),
  strong('Strong', 420, 480),
  moderate('Moderate', 360, 420),
  weak('Weak', 300, 360),
  veryWeak('Very Weak', 0, 300);

  const BhavaStrengthCategory(this.name, this.minStrength, this.maxStrength);
  final String name;
  final double minStrength;
  final double maxStrength;
}
