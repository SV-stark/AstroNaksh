import '../data/models.dart';
import 'astrology/doshas/angarak_dosha.dart';
import 'astrology/doshas/daridra_dosha.dart';
import 'astrology/doshas/grahan_dosha.dart';
import 'astrology/doshas/guru_chandal_dosha.dart';
import 'astrology/doshas/kaal_sarp_dosha.dart';
import 'astrology/doshas/kemadruma_dosha.dart';
import 'astrology/doshas/mangal_dosha.dart';
import 'astrology/doshas/pitra_dosha.dart';
import 'astrology/doshas/shrapit_dosha.dart';
import 'astrology/doshas/vish_dosha.dart';
import 'astrology/yogas/adhi_yoga.dart';
import 'astrology/yogas/amala_yoga.dart';
import 'astrology/yogas/budhaditya_yoga.dart';
import 'astrology/yogas/chamara_yoga.dart';
import 'astrology/yogas/chandra_mangala_yoga.dart';
import 'astrology/yogas/dhana_yoga.dart';
import 'astrology/yogas/gajakesari_yoga.dart';
import 'astrology/yogas/kahala_yoga.dart';
import 'astrology/yogas/lakshmi_yoga.dart';
import 'astrology/yogas/lunar_yoga.dart';
import 'astrology/yogas/nabhasa_yoga.dart';
import 'astrology/yogas/neecha_bhanga_yoga.dart';
import 'astrology/yogas/pancha_mahapurusha_yoga.dart';
import 'astrology/yogas/parivartana_yoga.dart';
import 'astrology/yogas/parvata_yoga.dart';
import 'astrology/yogas/raj_yoga.dart';
import 'astrology/yogas/sakat_yoga.dart';
import 'astrology/yogas/saraswati_yoga.dart';
import 'astrology/yogas/solar_yoga.dart';
import 'astrology/yogas/vipreet_raj_yoga.dart';
import 'astrology/yogas/yoga_detector.dart';

/// Yoga and Dosha Analyzer
/// Detects auspicious (Yoga) and inauspicious (Dosha) combinations.
class YogaDoshaAnalyzer {
  /// Registry of yoga detectors for modular logic
  static final List<YogaDetector> _yogaDetectors = [
    GajakesariYogaDetector(),
    BudhadityaYogaDetector(),
    ChandraMangalaYogaDetector(),
    RajYogaDetector(),
    DhanaYogaDetector(),
    VipreetRajYogaDetector(),
    PanchaMahapurushaYogaDetector(),
    AdhiYogaDetector(),
    LakshmiYogaDetector(),
    SaraswatiYogaDetector(),
    AmalaYogaDetector(),
    ParvataYogaDetector(),
    KahalaYogaDetector(),
    ChamaraYogaDetector(),
    SakatYogaDetector(),
    NeechaBhangaYogaDetector(),
    ParivartanaYogaDetector(),
    LunarYogaDetector(),
    SolarYogaDetector(),
    NabhasaYogaDetector(),
  ];

  /// Registry of dosha detectors for modular logic
  static final List<YogaDetector> _doshaDetectors = [
    KaalSarpDoshaDetector(),
    MangalDoshaDetector(),
    GuruChandalDoshaDetector(),
    VishDoshaDetector(),
    KemadrumaDoshaDetector(),
    GrahanDoshaDetector(),
    AngarakDoshaDetector(),
    ShrapitDoshaDetector(),
    DaridraDoshaDetector(),
    PitraDoshaDetector(),
  ];

  /// Analyze chart for common Yogas and Doshas
  static YogaDoshaAnalysisResult analyze(
    CompleteChartData chart, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final yogas = _findYogas(chart, now);
    final doshas = _findDoshas(chart, now);

    // Score calculation (only active items affect score)
    var score = 50.0;
    for (final y in yogas) {
      if (y.isActive) {
        score += (y.strength / 100.0) * 5;
      }
    }
    for (final d in doshas) {
      if (d.isActive) {
        score -= (d.strength / 100.0) * 5;
      }
    }
    score = score.clamp(0.0, 100.0);

    return YogaDoshaAnalysisResult(
      yogas: yogas,
      doshas: doshas,
      overallScore: score,
      qualityLabel: YogaDoshaAnalyzer._getQualityLabel(score),
      qualityDescription: YogaDoshaAnalyzer._getQualityDescription(score),
    );
  }

  // --- Dosha Detection ---

  static List<BhangaResult> _findDoshas(CompleteChartData chart, DateTime now) {
    // New Modular Detectors
    return _doshaDetectors.map((d) => d.detect(chart)).toList();
  }

  // --- Yoga Detection ---

  static List<BhangaResult> _findYogas(CompleteChartData chart, DateTime now) {
    return _yogaDetectors
        .map((d) => d.detect(chart))
        .where((r) => r.isActive)
        .toList();
  }

  // --- Helpers ---

  static String _getQualityLabel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Very Good';
    if (score >= 50) return 'Good';
    if (score >= 35) return 'Average';
    return 'Challenging';
  }

  static String _getQualityDescription(double score) {
    if (score >= 80) {
      return 'This is an excellent chart with strong positive combinations and minimal afflictions.';
    } else if (score >= 65) {
      return 'This is a very good chart with several beneficial yogas that support success.';
    } else if (score >= 50) {
      return 'This is a good chart with balanced energies and opportunities for growth.';
    } else if (score >= 35) {
      return 'This chart has average potential with both opportunities and challenges to navigate.';
    }
    return 'This chart has some challenges that require conscious effort and remedial measures.';
  }
}
