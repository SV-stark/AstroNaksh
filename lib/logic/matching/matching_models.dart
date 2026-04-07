import 'package:flutter/material.dart';

/// Result of a single Koota (compatibility factor) check
class KootaResult {
  // UI color (Green=Good, Red=Bad)

  const KootaResult({
    required this.name,
    required this.score,
    required this.maxScore,
    required this.description,
    required this.detailedReason,
    this.color = Colors.grey,
  });
  final String name; // e.g., "Varna"
  final double score; // e.g., 1.0
  final double maxScore; // e.g., 1.0
  final String description; // Short description
  final String detailedReason; // Specific reason for the score
  final Color color;

  bool get isPerfect => score == maxScore;
  bool get isZero => score == 0;
}

/// Result of Manglik Dosha matching
class ManglikMatchResult {
  // If mismatch is cancelled

  const ManglikMatchResult({
    required this.isMatch,
    required this.description,
    required this.maleManglik,
    required this.femaleManglik,
    this.cancellationReason,
  });
  final bool isMatch; // True if compatible (e.g., both Manglik or both Non)
  final String description; // "Both are Manglik", "One Manglik (Cancelled)"
  final bool maleManglik;
  final bool femaleManglik;
  final String? cancellationReason;
}

/// Additional Dosha/Yoga checks for matching
class ExtraMatchingCheck {
  const ExtraMatchingCheck({
    required this.name,
    required this.isFavorable,
    required this.description,
  });
  final String name; // e.g., "Mahendra Koota"
  final bool isFavorable;
  final String description;
}

/// Result of Dosha Samyam (Malefic Scoring)
class DoshaSamyamResult {
  const DoshaSamyamResult({
    required this.maleScore,
    required this.femaleScore,
    required this.isGood,
    required this.description,
  });
  final double maleScore;
  final double femaleScore;
  final bool isGood; // True if scores are balanced
  final String description;
}

/// Result of Dasha Sandhi (Timing Compatibility)
class DashaSandhiResult {
  const DashaSandhiResult({
    required this.hasSandhi,
    required this.maleCurrentDasha,
    required this.femaleCurrentDasha,
    required this.description,
  });
  final bool hasSandhi; // True if bad timing exists
  final String maleCurrentDasha;
  final String femaleCurrentDasha;
  final String description;
}

/// Complete extensive matching report
class MatchingReport {
  const MatchingReport({
    required this.ashtakootaScore,
    required this.kootaResults,
    required this.manglikMatch,
    this.extraChecks = const [],
    this.doshaSamyam,
    this.dashaSandhi,
    required this.overallConclusion,
    required this.overallColor,
  });
  final double ashtakootaScore; // Out of 36
  final List<KootaResult> kootaResults;
  final ManglikMatchResult manglikMatch;
  final List<ExtraMatchingCheck> extraChecks;
  final DoshaSamyamResult? doshaSamyam;
  final DashaSandhiResult? dashaSandhi;
  final String overallConclusion;
  final Color overallColor;
}
