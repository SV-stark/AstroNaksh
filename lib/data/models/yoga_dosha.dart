class BhangaResult {
  final String name;
  final String description;
  final bool isActive;
  final List<String> cancellationReasons;
  final double strength; // 0-100 scale
  final String
  status; // 'Active', 'Partially Cancelled', 'Fully Cancelled', 'Strong', 'Moderate', 'Weak'
  final String
  manifestationPeriod; // e.g. "Mar 2025 – Nov 2027" or "Currently active"
  final String peakDashaLord; // e.g. "Jupiter MD → Venus AD"

  BhangaResult({
    required this.name,
    required this.description,
    required this.isActive,
    this.cancellationReasons = const [],
    this.strength = 100.0,
    required this.status,
    this.manifestationPeriod = '',
    this.peakDashaLord = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'isActive': isActive,
    'cancellationReasons': cancellationReasons,
    'strength': strength,
    'status': status,
    'manifestationPeriod': manifestationPeriod,
    'peakDashaLord': peakDashaLord,
  };
}

class YogaDoshaAnalysisResult {
  final List<BhangaResult> yogas;
  final List<BhangaResult> doshas;
  final double overallScore;
  final String qualityLabel;
  final String qualityDescription;

  YogaDoshaAnalysisResult({
    required this.yogas,
    required this.doshas,
    required this.overallScore,
    required this.qualityLabel,
    required this.qualityDescription,
  });
}
