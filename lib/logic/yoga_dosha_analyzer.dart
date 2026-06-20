import 'package:jyotish/jyotish.dart';

import '../data/models.dart';

/// Yoga and Dosha Analyzer.
/// Delegates detection to the jyotish library's [YogaService] and
/// [DoshaService], then maps results to the app's [BhangaResult] model.
class YogaDoshaAnalyzer {
  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Analyse [chart] for auspicious Yogas and inauspicious Doshas.
  static YogaDoshaAnalysisResult analyze(
    CompleteChartData chart, {
    DateTime? referenceDate,
  }) {
    final yogas = _findYogas(chart);
    final doshas = _findDoshas(chart);

    // Score starts at neutral 50; each active yoga adds up to +5 and each
    // active dosha subtracts up to -5, scaled by the item's strength.
    var score = 50.0;
    for (final y in yogas) {
      if (y.isActive) score += (y.strength / 100.0) * 5;
    }
    for (final d in doshas) {
      if (d.isActive) score -= (d.strength / 100.0) * 5;
    }
    score = score.clamp(0.0, 100.0);

    return YogaDoshaAnalysisResult(
      yogas: yogas,
      doshas: doshas,
      overallScore: score,
      qualityLabel: _getQualityLabel(score),
      qualityDescription: _getQualityDescription(score),
    );
  }

  // ---------------------------------------------------------------------------
  // Yoga detection
  // ---------------------------------------------------------------------------

  static List<BhangaResult> _findYogas(CompleteChartData chart) {
    List<NatalYoga> natalYogas;
    try {
      natalYogas = const YogaService().detectNatalYogas(chart.baseChart);
    } catch (_) {
      natalYogas = const [];
    }

    // Only return yogas that are actually present in the chart.
    return natalYogas
        .where((y) => y.isPresent)
        .map(_natalYogaToBhanga)
        .toList();
  }

  /// Maps a [NatalYoga] (jyotish library) → [BhangaResult] (app model).
  static BhangaResult _natalYogaToBhanga(NatalYoga yoga) {
    final description = [
      if (yoga.description.isNotEmpty) yoga.description,
      if (yoga.benefits.isNotEmpty) yoga.benefits,
    ].join('\n\n');

    return BhangaResult(
      name: yoga.name,
      description: description,
      isActive: yoga.isPresent,
      // explanation describes *why* the yoga is present in this specific chart.
      cancellationReasons: yoga.explanation.isNotEmpty
          ? [yoga.explanation]
          : const [],
      strength: 80.0,
      status: yoga.isPresent ? 'Active' : 'Inactive',
      manifestationPeriod: '',
      peakDashaLord: '',
    );
  }

  // ---------------------------------------------------------------------------
  // Dosha detection
  // ---------------------------------------------------------------------------

  static List<BhangaResult> _findDoshas(CompleteChartData chart) {
    FullDoshaReport report;
    try {
      report = const DoshaService().calculateFullDoshaReport(chart.baseChart);
    } catch (_) {
      return const [];
    }

    return [
      _kalaSarpaToBhanga(report.kalaSarpa),
      _manglikToBhanga(report.manglik),
      _pitruToBhanga(report.pitru),
      _guruChandalaToBhanga(report.guruChandala),
      _gandaMoolaToBhanga(report.gandaMoola),
      _kalathraToBhanga(report.kalathra),
      _conjunctionDoshaToBhanga(report.ghata),
      _conjunctionDoshaToBhanga(report.shrapit),
    ];
  }

  // --- Individual dosha converters ---

  static BhangaResult _kalaSarpaToBhanga(KalaSarpaDoshaResult d) {
    return BhangaResult(
      name: d.hasDosha && d.type.isNotEmpty
          ? '${d.type} Kaal Sarp Dosha'
          : 'Kaal Sarp Dosha',
      description: d.description.isNotEmpty
          ? d.description
          : 'All planets are hemmed between Rahu and Ketu.',
      isActive: d.hasDosha,
      cancellationReasons: const [],
      strength: d.hasDosha ? 80.0 : 0.0,
      status: d.hasDosha ? 'Active' : 'Inactive',
    );
  }

  static BhangaResult _manglikToBhanga(ManglikDoshaResult d) {
    final affectedHousesNote = d.housesAffected.isNotEmpty
        ? 'Mars is placed in house(s): ${d.housesAffected.join(", ")}.'
        : '';
    final description = [
      'Mars placed in houses 1, 2, 4, 7, 8, or 12 causes Manglik Dosha.',
      if (affectedHousesNote.isNotEmpty) affectedHousesNote,
    ].join(' ');

    final isActive = d.isManglik || d.severity == 'Cancelled';
    final status = d.isManglik
        ? (d.severity.isNotEmpty ? d.severity : 'Active')
        : (d.severity == 'Cancelled' ? 'Cancelled' : 'Inactive');

    return BhangaResult(
      name: 'Manglik Dosha',
      description: description,
      isActive: isActive,
      cancellationReasons: d.remedies,
      strength: d.isManglik ? 80.0 : 0.0,
      status: status,
    );
  }

  static BhangaResult _pitruToBhanga(PitruDoshaResult d) {
    return BhangaResult(
      name: 'Pitru Dosha',
      description:
          'Pitru Dosha arises when Sun or Moon is afflicted by Rahu, Ketu, '
          'or Saturn, indicating ancestral karmic debt.',
      isActive: d.hasDosha,
      cancellationReasons: [...d.factorsMatched, ...d.remedies],
      strength: d.hasDosha ? 80.0 : 0.0,
      status: d.hasDosha ? 'Active' : 'Inactive',
    );
  }

  static BhangaResult _guruChandalaToBhanga(GuruChandalaDoshaResult d) {
    // Dosha is mitigated when Jupiter is stronger than the shadow planet.
    final isMitigated = d.hasDosha && d.jupiterIsStronger;
    return BhangaResult(
      name: 'Guru Chandala Dosha',
      description: d.description.isNotEmpty
          ? d.description
          : 'Jupiter conjoined with Rahu or Ketu causes Guru Chandala Dosha.',
      isActive: d.hasDosha,
      cancellationReasons: isMitigated
          ? ['Jupiter is stronger than the node; dosha is mitigated.']
          : const [],
      strength: d.hasDosha ? (isMitigated ? 40.0 : 80.0) : 0.0,
      status: d.hasDosha ? (isMitigated ? 'Mitigated' : 'Active') : 'Inactive',
    );
  }

  static BhangaResult _gandaMoolaToBhanga(GandaMoolaDoshaResult d) {
    return BhangaResult(
      name: 'Ganda Moola Dosha',
      description: d.description.isNotEmpty
          ? d.description
          : 'Birth in a Ganda Moola nakshatra causes this dosha.',
      isActive: d.hasDosha,
      cancellationReasons: d.hasDosha && d.nakshatra.isNotEmpty
          ? [d.nakshatra]
          : const [],
      strength: d.hasDosha ? 80.0 : 0.0,
      status: d.hasDosha ? 'Active' : 'Inactive',
    );
  }

  static BhangaResult _kalathraToBhanga(KalathraDoshaResult d) {
    return BhangaResult(
      name: 'Kalathra Dosha',
      description: d.description.isNotEmpty
          ? d.description
          : 'Natural malefics afflict the 7th house or its lord, causing '
                'difficulties in relationships and marriage.',
      isActive: d.hasDosha,
      cancellationReasons: const [],
      strength: d.hasDosha ? 80.0 : 0.0,
      status: d.hasDosha ? 'Active' : 'Inactive',
    );
  }

  static BhangaResult _conjunctionDoshaToBhanga(ConjunctionDoshaResult d) {
    return BhangaResult(
      name: d.name.isNotEmpty ? d.name : 'Conjunction Dosha',
      description: d.description.isNotEmpty
          ? d.description
          : 'A malefic planetary conjunction causes this dosha.',
      isActive: d.hasDosha,
      cancellationReasons: const [],
      strength: d.hasDosha ? 80.0 : 0.0,
      status: d.hasDosha ? 'Active' : 'Inactive',
    );
  }

  // ---------------------------------------------------------------------------
  // Quality helpers
  // ---------------------------------------------------------------------------

  static String _getQualityLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Very Good';
    if (score >= 50) return 'Good';
    if (score >= 35) return 'Average';
    return 'Challenging';
  }

  static String _getQualityDescription(double score) {
    if (score >= 80) {
      return 'This is an excellent chart with strong positive combinations '
          'and minimal afflictions.';
    } else if (score >= 65) {
      return 'This is a very good chart with several beneficial yogas that '
          'support success.';
    } else if (score >= 50) {
      return 'This is a good chart with balanced energies and opportunities '
          'for growth.';
    } else if (score >= 35) {
      return 'This chart has average potential with both opportunities and '
          'challenges to navigate.';
    }
    return 'This chart has some challenges that require conscious effort and '
        'remedial measures.';
  }
}
