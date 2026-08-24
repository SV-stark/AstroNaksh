import 'package:flutter/foundation.dart';

class BhangaResult {
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

  factory BhangaResult.fromJson(Map<String, dynamic> json) {
    return BhangaResult(
      name: json['name'] as String,
      description: json['description'] as String,
      isActive: json['isActive'] as bool,
      cancellationReasons:
          (json['cancellationReasons'] as List<dynamic>?)?.cast<String>() ??
          const [],
      strength: (json['strength'] as num?)?.toDouble() ?? 100.0,
      status: json['status'] as String,
      manifestationPeriod: json['manifestationPeriod'] as String? ?? '',
      peakDashaLord: json['peakDashaLord'] as String? ?? '',
    );
  }

  factory BhangaResult.inactive(String name) {
    return BhangaResult(
      name: name,
      description: '',
      isActive: false,
      status: 'Inactive',
      strength: 0,
    );
  }

  final String name;
  final String description;
  final bool isActive;
  final List<String> cancellationReasons;
  final double strength;
  final String status;
  final String manifestationPeriod;
  final String peakDashaLord;

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BhangaResult &&
        other.name == name &&
        other.description == description &&
        other.status == status &&
        other.isActive == isActive &&
        other.strength == strength &&
        other.manifestationPeriod == manifestationPeriod &&
        other.peakDashaLord == peakDashaLord &&
        listEquals(other.cancellationReasons, cancellationReasons);
  }

  @override
  int get hashCode => Object.hash(
        name,
        description,
        status,
        isActive,
        strength,
        manifestationPeriod,
        peakDashaLord,
        Object.hashAll(cancellationReasons),
      );
}

class YogaDoshaAnalysisResult {
  YogaDoshaAnalysisResult({
    required this.yogas,
    required this.doshas,
    required this.overallScore,
    required this.qualityLabel,
    required this.qualityDescription,
  });

  factory YogaDoshaAnalysisResult.fromJson(Map<String, dynamic> json) {
    return YogaDoshaAnalysisResult(
      yogas: (json['yogas'] as List)
          .map((e) => BhangaResult.fromJson(e))
          .toList(),
      doshas: (json['doshas'] as List)
          .map((e) => BhangaResult.fromJson(e))
          .toList(),
      overallScore: (json['overallScore'] as num).toDouble(),
      qualityLabel: json['qualityLabel'] as String,
      qualityDescription: json['qualityDescription'] as String,
    );
  }
  final List<BhangaResult> yogas;
  final List<BhangaResult> doshas;
  final double overallScore;
  final String qualityLabel;
  final String qualityDescription;

  Map<String, dynamic> toJson() => {
    'yogas': yogas.map((e) => e.toJson()).toList(),
    'doshas': doshas.map((e) => e.toJson()).toList(),
    'overallScore': overallScore,
    'qualityLabel': qualityLabel,
    'qualityDescription': qualityDescription,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YogaDoshaAnalysisResult &&
        other.overallScore == overallScore &&
        other.qualityLabel == qualityLabel &&
        other.qualityDescription == qualityDescription &&
        listEquals(other.yogas, yogas) &&
        listEquals(other.doshas, doshas);
  }

  @override
  int get hashCode => Object.hash(
    overallScore,
    qualityLabel,
    qualityDescription,
    Object.hashAll(yogas),
    Object.hashAll(doshas),
  );
}
