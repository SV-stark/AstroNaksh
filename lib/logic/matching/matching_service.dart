import 'package:flutter/material.dart';
import 'package:jyotish/jyotish.dart';
import 'package:intl/intl.dart';

import '../../data/models.dart';
import 'matching_models.dart';

/// Extensive Kundali Matching Service
/// Uses library's CompatibilityService for core calculations
class MatchingService {
  static final CompatibilityService _compatibilityService = CompatibilityService();

  /// Analyze compatibility extensively
  static MatchingReport analyzeCompatibility(
    CompleteChartData groom,
    CompleteChartData bride,
  ) {
    // Use library's core compatibility calculation
    final libraryResult = _compatibilityService.calculateCompatibility(
      groom.baseChart,
      bride.baseChart,
    );

    // Get basic info
    final groomMoon = groom.baseChart.planets[Planet.moon]!;
    final brideMoon = bride.baseChart.planets[Planet.moon]!;
    final gNak = groomMoon.position.nakshatraIndex;
    final bNak = brideMoon.position.nakshatraIndex;

    // Get additional checks not in library
    final extraChecks = _calculateExtraChecks(gNak, bNak);
    final dashaSandhi = _checkDashaSandhi(groom, bride);

    // Convert library's GunaScores to our KootaResult format
    final libraryGuna = libraryResult.gunaScores;
    final allKootas = <KootaResult>[
      _convertKoota('Varna', libraryGuna.varna, 1),
      _convertKoota('Vashya', libraryGuna.vashya, 2),
      _convertKoota('Tara', libraryGuna.tara, 3),
      _convertKoota('Yoni', libraryGuna.yoni, 4),
      _convertKoota('Graha Maitri', libraryGuna.grahaMaitri, 5),
      _convertKoota('Gana', libraryGuna.gana, 6),
      _convertKoota('Bhakoot', libraryGuna.bhakoot, 7),
      _convertKoota('Nadi', libraryGuna.nadi, 8),
    ];

    // Convert library's Manglik/Dosha results
    final manglikMatch = _convertManglikMatch(
      libraryResult.doshaCheck,
      groom,
      bride,
    );

    // Build conclusion from library + extras
    String conclusion;
    Color color;

    final totalScore = libraryResult.totalScore;
    final criticalDosha = !manglikMatch.isMatch ||
        !_areExtrasGood(extraChecks) ||
        libraryResult.doshaCheck.hasNadiDosha;

    if (totalScore >= 28) {
      if (!criticalDosha) {
        conclusion = "Excellent Match (Uttam)";
        color = Colors.green;
      } else {
        conclusion = "High Score, but Critical Dosha detected";
        color = Colors.orange;
      }
    } else if (totalScore >= 18) {
      if (!criticalDosha) {
        conclusion = "Average Match (Madhyam)";
        color = Colors.yellow[700]!;
      } else {
        conclusion = "Average Score with Critical Dosha";
        color = Colors.orange;
      }
    } else {
      conclusion = "Not Recommended (Adham)";
      color = Colors.red;
    }

    // Convert DoshaSamyam from library
    final doshaSamyam = DoshaSamyamResult(
      maleScore: libraryResult.doshaCheck.hasManglikDosha ? 1.0 : 0.0,
      femaleScore: libraryResult.doshaCheck.hasNadiDosha ? 1.0 : 0.0,
      isGood: !libraryResult.doshaCheck.hasNadiDosha,
      description: libraryResult.analysis.join('. '),
    );

    return MatchingReport(
      ashtakootaScore: totalScore.toDouble(),
      kootaResults: allKootas,
      manglikMatch: manglikMatch,
      extraChecks: extraChecks,
      doshaSamyam: doshaSamyam,
      dashaSandhi: dashaSandhi,
      overallConclusion: conclusion,
      overallColor: color,
    );
  }

  static KootaResult _convertKoota(String name, int score, int maxScore) {
    Color color;
    String description;
    if (score >= maxScore * 0.75) {
      color = Colors.green;
      description = 'Favorable';
    } else if (score >= maxScore * 0.5) {
      color = Colors.orange;
      description = 'Moderate';
    } else {
      color = Colors.red;
      description = 'Unfavorable';
    }

    return KootaResult(
      name: name,
      score: score.toDouble(),
      maxScore: maxScore.toDouble(),
      description: description,
      detailedReason: '$name score: $score/$maxScore',
      color: color,
    );
  }

  static ManglikMatchResult _convertManglikMatch(
    DoshaCheck doshaCheck,
    CompleteChartData groom,
    CompleteChartData bride,
  ) {
    final manglikBoy = _compatibilityService.checkManglikDosha(groom.baseChart);
    final manglikGirl = _compatibilityService.checkManglikDosha(bride.baseChart);

    bool match = false;
    String desc = '';

    if (manglikBoy.isManglik && manglikGirl.isManglik) {
      match = true;
      desc = "Both are Manglik. Dosha cancels out.";
    } else if (!manglikBoy.isManglik && !manglikGirl.isManglik) {
      match = true;
      desc = "Neither is Manglik. Good compatibility.";
    } else {
      match = false;
      String mPerson = manglikBoy.isManglik ? "Groom" : "Bride";
      desc = "$mPerson is Manglik, while the other is not.";
    }

    return ManglikMatchResult(
      isMatch: match,
      description: desc,
      maleManglik: manglikBoy.isManglik,
      femaleManglik: manglikGirl.isManglik,
    );
  }

  static List<ExtraMatchingCheck> _calculateExtraChecks(int gNak, int bNak) {
    List<ExtraMatchingCheck> checks = [];

    // 1. Mahendra
    int distBG = (gNak - bNak + 27) % 27 + 1;
    bool mahendra = [4, 7, 10, 13, 16, 19, 22, 25].contains(distBG);
    checks.add(ExtraMatchingCheck(
      name: 'Mahendra',
      isFavorable: mahendra,
      description: mahendra ? 'Promotes well-being & longevity' : 'Neutral/Unfavorable',
    ));

    // 2. Stree Deergha
    bool streeDeergha = distBG > 13;
    checks.add(ExtraMatchingCheck(
      name: 'Stree Deergha',
      isFavorable: streeDeergha,
      description: streeDeergha ? 'Good distance. Ensures prosperity.' : 'Short distance. Minor concern.',
    ));

    // 3. Rajju Dosha
    int getRajjuGroup(int n) {
      if ([0, 8, 9, 17, 18, 26].contains(n)) return 0;
      if ([1, 7, 10, 16, 19, 25].contains(n)) return 1;
      if ([2, 6, 11, 15, 20, 24].contains(n)) return 2;
      if ([3, 5, 12, 14, 21, 23].contains(n)) return 3;
      if ([4, 13, 22].contains(n)) return 4;
      return -1;
    }

    int gRajju = getRajjuGroup(gNak);
    int bRajju = getRajjuGroup(bNak);
    bool rajjuMatch = gRajju != bRajju;

    checks.add(ExtraMatchingCheck(
      name: 'Rajju Dosha',
      isFavorable: rajjuMatch,
      description: rajjuMatch ? 'Different Rajju. Good.' : 'Same Rajju. Avoid match.',
    ));

    // 4. Vedha
    final pairs = [
      {0, 17}, {1, 16}, {2, 15}, {3, 14}, {5, 21}, {6, 20},
      {7, 19}, {8, 18}, {9, 26}, {10, 25}, {11, 24}, {12, 23},
      {4, 13}, {4, 22}, {13, 22},
    ];

    bool vedha = false;
    for (var p in pairs) {
      if (p.contains(gNak) && p.contains(bNak)) {
        vedha = true;
        break;
      }
    }

    checks.add(ExtraMatchingCheck(
      name: 'Vedha (Obstruction)',
      isFavorable: !vedha,
      description: vedha ? 'Mutual obstruction detected.' : 'No obstruction.',
    ));

    return checks;
  }

  static bool _areExtrasGood(List<ExtraMatchingCheck> extras) {
    bool rajjuGood = extras.firstWhere((e) => e.name == 'Rajju Dosha', orElse: () => ExtraMatchingCheck(name: '', isFavorable: true, description: '')).isFavorable;
    bool vedhaGood = extras.firstWhere((e) => e.name.contains('Vedha'), orElse: () => ExtraMatchingCheck(name: '', isFavorable: true, description: '')).isFavorable;
    return rajjuGood && vedhaGood;
  }

  static DashaSandhiResult _checkDashaSandhi(
    CompleteChartData groom,
    CompleteChartData bride,
  ) {
    final now = DateTime.now();
    final gDasha = groom.getCurrentDashas(now);
    final bDasha = bride.getCurrentDashas(now);

    if (gDasha.isEmpty || bDasha.isEmpty) {
      return const DashaSandhiResult(
        hasSandhi: false,
        maleCurrentDasha: "Unknown",
        femaleCurrentDasha: "Unknown",
        description: "Could not calculate current Dasha for today.",
      );
    }

    final gMaha = gDasha['mahadasha'] as String;
    final bMaha = bDasha['mahadasha'] as String;

    bool gSandhi = false;
    bool bSandhi = false;

    final gEnd = gDasha['mahaEnd'] as DateTime;
    final bEnd = bDasha['mahaEnd'] as DateTime;

    final gDaysLeft = gEnd.difference(now).inDays;
    final bDaysLeft = bEnd.difference(now).inDays;

    if (gDaysLeft < 180 && gDaysLeft > 0) gSandhi = true;
    if (bDaysLeft < 180 && bDaysLeft > 0) bSandhi = true;

    String desc = "No immediate Dasha transition.";
    if (gSandhi && bSandhi) {
      desc = "Critical: Both at end of Mahadashas.";
    } else if (gSandhi) {
      desc = "Groom ending Mahadasha ($gMaha) soon.";
    } else if (bSandhi) {
      desc = "Bride ending Mahadasha ($bMaha) soon.";
    }

    return DashaSandhiResult(
      hasSandhi: gSandhi || bSandhi,
      maleCurrentDasha: "$gMaha (${DateFormat('MMM yyyy').format(gEnd)})",
      femaleCurrentDasha: "$bMaha (${DateFormat('MMM yyyy').format(bEnd)})",
      description: desc,
    );
  }
}
