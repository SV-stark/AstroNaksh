import 'package:flutter/material.dart';
import 'package:jyotish/jyotish.dart';

import '../../core/ephemeris_manager.dart';
import '../../core/utils/formatters.dart';
import '../../data/models.dart';
import 'matching_models.dart';

/// Extensive Kundali Matching Service
/// Uses library's CompatibilityReport for core calculations
class MatchingService {
  /// Analyze compatibility extensively
  static MatchingReport analyzeCompatibility(
    CompleteChartData groom,
    CompleteChartData bride,
  ) {
    // Use library's core compatibility calculation
    final libraryReport = EphemerisManager.jyotish.calculateCompatibilityReport(
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
    final libraryGuna = libraryReport.gunaScores;
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
    final boyIsManglik = libraryReport.boyManglik;
    final girlIsManglik = libraryReport.girlManglik;
    final boyCancelled = libraryReport.boyManglikCancellations.isNotEmpty;
    final girlCancelled = libraryReport.girlManglikCancellations.isNotEmpty;

    var isMatch = false;
    var description = '';
    String? cancellationReason;

    if (!boyIsManglik && !girlIsManglik) {
      isMatch = true;
      description = 'Neither is Manglik. Good compatibility.';
    } else if (boyIsManglik && girlIsManglik) {
      isMatch = true;
      description = 'Both are Manglik. Dosha cancels out.';
      cancellationReason = 'Mutual cancellation: both partners are Manglik.';
    } else {
      // One is Manglik, one is not
      final isBoyManglikAndNotCancelled = boyIsManglik && !boyCancelled;
      final isGirlManglikAndNotCancelled = girlIsManglik && !girlCancelled;

      if (!isBoyManglikAndNotCancelled && !isGirlManglikAndNotCancelled) {
        // This means whoever was Manglik has cancellation reasons!
        isMatch = true;
        if (boyIsManglik) {
          description = 'Groom is Manglik (Cancelled). Compatible.';
          cancellationReason = libraryReport.boyManglikCancellations.join('. ');
        } else {
          description = 'Bride is Manglik (Cancelled). Compatible.';
          cancellationReason = libraryReport.girlManglikCancellations.join('. ');
        }
      } else {
        isMatch = false;
        final mPerson = boyIsManglik ? 'Groom' : 'Bride';
        description = '$mPerson is Manglik, while the other is not.';
        if (boyIsManglik && boyCancelled) {
          cancellationReason = 'Groom has partial cancellations: ${libraryReport.boyManglikCancellations.join('. ')}';
        } else if (girlIsManglik && girlCancelled) {
          cancellationReason = 'Bride has partial cancellations: ${libraryReport.girlManglikCancellations.join('. ')}';
        }
      }
    }

    final manglikMatch = ManglikMatchResult(
      isMatch: isMatch,
      description: description,
      maleManglik: boyIsManglik,
      femaleManglik: girlIsManglik,
      cancellationReason: cancellationReason,
    );

    // Build conclusion from library + extras
    String conclusion;
    Color color;

    final totalScore = libraryReport.totalScore;
    final criticalDosha =
        !manglikMatch.isMatch ||
        !_areExtrasGood(extraChecks) ||
        libraryReport.hasNadiDosha;

    if (totalScore >= 28) {
      if (!criticalDosha) {
        conclusion = 'Excellent Match (Uttam)';
        color = Colors.green;
      } else {
        conclusion = 'High Score, but Critical Dosha detected';
        color = Colors.orange;
      }
    } else if (totalScore >= 18) {
      if (!criticalDosha) {
        conclusion = 'Average Match (Madhyam)';
        color = Colors.yellow[700]!;
      } else {
        conclusion = 'Average Score with Critical Dosha';
        color = Colors.orange;
      }
    } else {
      conclusion = 'Not Recommended (Adham)';
      color = Colors.red;
    }

    // Convert DoshaSamyam from library
    final doshaSamyam = DoshaSamyamResult(
      maleScore: libraryReport.boyManglik ? 1.0 : 0.0,
      femaleScore: libraryReport.girlManglik ? 1.0 : 0.0,
      isGood: !libraryReport.hasNadiDosha && !libraryReport.hasBhakootDosha,
      description: libraryReport.analysis.join('. '),
    );

    return MatchingReport(
      ashtakootaScore: totalScore,
      kootaResults: allKootas,
      manglikMatch: manglikMatch,
      extraChecks: extraChecks,
      doshaSamyam: doshaSamyam,
      dashaSandhi: dashaSandhi,
      overallConclusion: conclusion,
      overallColor: color,
    );
  }

  static KootaResult _convertKoota(String name, num score, num maxScore) {
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

  static List<ExtraMatchingCheck> _calculateExtraChecks(int gNak, int bNak) {
    final checks = <ExtraMatchingCheck>[];

    // 1. Mahendra
    final distBG = (gNak - bNak + 27) % 27 + 1;
    final mahendra = [4, 7, 10, 13, 16, 19, 22, 25].contains(distBG);
    checks.add(
      ExtraMatchingCheck(
        name: 'Mahendra',
        isFavorable: mahendra,
        description: mahendra
            ? 'Promotes well-being & longevity'
            : 'Neutral/Unfavorable',
      ),
    );

    // 2. Stree Deergha
    final streeDeergha = distBG > 13;
    checks.add(
      ExtraMatchingCheck(
        name: 'Stree Deergha',
        isFavorable: streeDeergha,
        description: streeDeergha
            ? 'Good distance. Ensures prosperity.'
            : 'Short distance. Minor concern.',
      ),
    );

    // 3. Rajju Dosha
    int getRajjuGroup(int n) {
      if ([0, 8, 9, 17, 18, 26].contains(n)) return 0;
      if ([1, 7, 10, 16, 19, 25].contains(n)) return 1;
      if ([2, 6, 11, 15, 20, 24].contains(n)) return 2;
      if ([3, 5, 12, 14, 21, 23].contains(n)) return 3;
      if ([4, 13, 22].contains(n)) return 4;
      return -1;
    }

    final gRajju = getRajjuGroup(gNak);
    final bRajju = getRajjuGroup(bNak);
    final rajjuMatch = gRajju != bRajju;

    checks.add(
      ExtraMatchingCheck(
        name: 'Rajju Dosha',
        isFavorable: rajjuMatch,
        description: rajjuMatch
            ? 'Different Rajju. Good.'
            : 'Same Rajju. Avoid match.',
      ),
    );

    // 4. Vedha
    final pairs = [
      {0, 17},
      {1, 16},
      {2, 15},
      {3, 14},
      {5, 21},
      {6, 20},
      {7, 19},
      {8, 18},
      {9, 26},
      {10, 25},
      {11, 24},
      {12, 23},
      {4, 13},
      {4, 22},
      {13, 22},
    ];

    var vedha = false;
    for (final p in pairs) {
      if (p.contains(gNak) && p.contains(bNak)) {
        vedha = true;
        break;
      }
    }

    checks.add(
      ExtraMatchingCheck(
        name: 'Vedha (Obstruction)',
        isFavorable: !vedha,
        description: vedha ? 'Mutual obstruction detected.' : 'No obstruction.',
      ),
    );

    return checks;
  }

  static bool _areExtrasGood(List<ExtraMatchingCheck> extras) {
    final rajjuGood = extras
        .firstWhere(
          (e) => e.name == 'Rajju Dosha',
          orElse: () => const ExtraMatchingCheck(
            name: '',
            isFavorable: true,
            description: '',
          ),
        )
        .isFavorable;
    final vedhaGood = extras
        .firstWhere(
          (e) => e.name.contains('Vedha'),
          orElse: () => const ExtraMatchingCheck(
            name: '',
            isFavorable: true,
            description: '',
          ),
        )
        .isFavorable;
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
        maleCurrentDasha: 'Unknown',
        femaleCurrentDasha: 'Unknown',
        description: 'Could not calculate current Dasha for today.',
      );
    }

    final gMaha = gDasha['mahadasha'] as String;
    final bMaha = bDasha['mahadasha'] as String;

    var gSandhi = false;
    var bSandhi = false;

    final gEnd = gDasha['mahaEnd'] as DateTime;
    final bEnd = bDasha['mahaEnd'] as DateTime;

    final gDaysLeft = gEnd.difference(now).inDays;
    final bDaysLeft = bEnd.difference(now).inDays;

    if (gDaysLeft < 180 && gDaysLeft > 0) gSandhi = true;
    if (bDaysLeft < 180 && bDaysLeft > 0) bSandhi = true;

    var desc = 'No immediate Dasha transition.';
    if (gSandhi && bSandhi) {
      desc = 'Critical: Both at end of Mahadashas.';
    } else if (gSandhi) {
      desc = 'Groom ending Mahadasha ($gMaha) soon.';
    } else if (bSandhi) {
      desc = 'Bride ending Mahadasha ($bMaha) soon.';
    }

    return DashaSandhiResult(
      hasSandhi: gSandhi || bSandhi,
      maleCurrentDasha: '$gMaha (${AppFormatters.formatDate(gEnd)})',
      femaleCurrentDasha: '$bMaha (${AppFormatters.formatDate(bEnd)})',
      description: desc,
    );
  }
}
