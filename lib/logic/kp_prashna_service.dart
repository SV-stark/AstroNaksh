import 'package:jyotish/core.dart';
import 'package:jyotish/systems.dart';

import '../core/ephemeris_manager.dart';
import '../data/models.dart';
import 'horary_service.dart';

class KPPrashnaService {
  final HoraryService _horaryService = HoraryService();

  Future<KPPrashnaResult> analyzePrashna({
    required int seedNumber,
    required PrashnaCategory category,
    required DateTime dateTime,
    required GeographicLocation location,
  }) async {
    final chart = await _horaryService.generateHoraryChart(
      seedNumber: seedNumber,
      dateTime: dateTime,
      location: location,
      ayanamsaName: 'KP',
    );

    final nativeKPData = await EphemerisManager.jyotish.calculateKPData(chart);

    final houseConfig = _getCategoryHouseConfig(category);
    final primaryHouse = houseConfig['primary'] as int;
    final primaryHouses = houseConfig['primaryList'] as List<int>;
    final supportingHouses = houseConfig['supporting'] as List<int>;
    final negatingHouses = houseConfig['negating'] as List<int>;
    final title = houseConfig['title'] as String;

    // Get Cusp Sub-Lord for the primary query house (1 to 12)
    final primaryCuspInfo = nativeKPData.houseDivisions[primaryHouse];
    final cuspSubLord = primaryCuspInfo?.subLord.displayName ?? 'Ketu';

    // Find planet details for cusp sub-lord
    final subLordPlanetEnum = Planet.values.firstWhere(
      (p) => p.displayName.toLowerCase() == cuspSubLord.toLowerCase(),
      orElse: () => Planet.ketu,
    );

    final subLordPlanetInfo = nativeKPData.planetDivisions[subLordPlanetEnum];
    final starLord = subLordPlanetInfo?.starLord.displayName ?? 'Ketu';

    final subLordStarLordEnum = Planet.values.firstWhere(
      (p) => p.displayName.toLowerCase() == starLord.toLowerCase(),
      orElse: () => Planet.ketu,
    );

    // Gather signified houses
    final subLordSignified = _getSignifiedHousesForPlanetEnum(subLordPlanetEnum, nativeKPData);
    final starLordSignified = _getSignifiedHousesForPlanetEnum(subLordStarLordEnum, nativeKPData);

    // Evaluate verdict
    var favorableCount = 0;
    var negatingCount = 0;

    for (final h in starLordSignified) {
      if (primaryHouses.contains(h) || supportingHouses.contains(h)) {
        favorableCount += 2;
      } else if (negatingHouses.contains(h)) {
        negatingCount += 2;
      }
    }

    for (final h in subLordSignified) {
      if (primaryHouses.contains(h) || supportingHouses.contains(h)) {
        favorableCount += 1;
      } else if (negatingHouses.contains(h)) {
        negatingCount += 1;
      }
    }

    PrashnaVerdict verdict;
    double confidence;

    if (favorableCount > negatingCount && favorableCount >= 2) {
      verdict = PrashnaVerdict.promised;
      confidence = (80.0 + (favorableCount * 3.0)).clamp(75.0, 98.0);
    } else if (negatingCount > favorableCount) {
      verdict = PrashnaVerdict.denied;
      confidence = (75.0 + (negatingCount * 3.0)).clamp(70.0, 95.0);
    } else {
      verdict = PrashnaVerdict.conditional;
      confidence = 65.0;
    }

    final significatorBreakdown = <KPPrashnaHouseSignificator>[];

    for (final houseNum in [...primaryHouses, ...supportingHouses]) {
      final cuspInfo = nativeKPData.houseDivisions[houseNum];
      final sl = cuspInfo?.subLord.displayName ?? 'Ketu';
      final slEnum = Planet.values.firstWhere(
        (p) => p.displayName.toLowerCase() == sl.toLowerCase(),
        orElse: () => Planet.ketu,
      );
      final slInfo = nativeKPData.planetDivisions[slEnum];
      final stL = slInfo?.starLord.displayName ?? 'Ketu';
      final stLEnum = Planet.values.firstWhere(
        (p) => p.displayName.toLowerCase() == stL.toLowerCase(),
        orElse: () => Planet.ketu,
      );

      significatorBreakdown.add(
        KPPrashnaHouseSignificator(
          houseNumber: houseNum,
          houseName: 'House $houseNum Cusp',
          cuspSubLord: sl,
          subLordStarLord: stL,
          subLordSignifiedHouses: _getSignifiedHousesForPlanetEnum(slEnum, nativeKPData),
          starLordSignifiedHouses: _getSignifiedHousesForPlanetEnum(stLEnum, nativeKPData),
        ),
      );
    }

    final interpretation = _generateInterpretation(
      category: category,
      verdict: verdict,
      cuspSubLord: cuspSubLord,
      starLord: starLord,
      primaryHouses: primaryHouses,
      supportingHouses: supportingHouses,
      negatingHouses: negatingHouses,
    );

    final timingText = _generateTimingGuidance(
      verdict: verdict,
      starLord: starLord,
      cuspSubLord: cuspSubLord,
      favorableHouses: [...primaryHouses, ...supportingHouses],
    );

    return KPPrashnaResult(
      seedNumber: seedNumber,
      category: category,
      queryTitle: title,
      verdict: verdict,
      confidencePercentage: confidence,
      primaryHouses: primaryHouses,
      supportingHouses: supportingHouses,
      negatingHouses: negatingHouses,
      significatorBreakdown: significatorBreakdown,
      detailedInterpretation: interpretation,
      timingGuidance: timingText,
    );
  }

  List<int> _getSignifiedHousesForPlanetEnum(Planet planet, KPCalculations nativeKPData) {
    final sigs = nativeKPData.planetSignificators[planet];
    if (sigs != null && sigs.allSignificators.isNotEmpty) {
      final houses = sigs.allSignificators.toList()..sort();
      return houses;
    }
    return [1];
  }

  Map<String, dynamic> _getCategoryHouseConfig(PrashnaCategory category) {
    switch (category) {
      case PrashnaCategory.career:
        return {
          'title': 'Job & Career Inquiry',
          'primary': 10,
          'primaryList': [10, 6],
          'supporting': [2, 11],
          'negating': [1, 5, 9],
        };
      case PrashnaCategory.marriage:
        return {
          'title': 'Marriage & Union Inquiry',
          'primary': 7,
          'primaryList': [7],
          'supporting': [2, 11],
          'negating': [1, 6, 10, 12],
        };
      case PrashnaCategory.health:
        return {
          'title': 'Health Recovery & Illness Inquiry',
          'primary': 1,
          'primaryList': [1, 11],
          'supporting': [5],
          'negating': [6, 8, 12],
        };
      case PrashnaCategory.property:
        return {
          'title': 'Property & Real Estate Inquiry',
          'primary': 4,
          'primaryList': [4],
          'supporting': [11, 12],
          'negating': [3, 10],
        };
      case PrashnaCategory.finance:
        return {
          'title': 'Wealth & Financial Growth Inquiry',
          'primary': 2,
          'primaryList': [2, 11],
          'supporting': [6],
          'negating': [5, 8, 12],
        };
      case PrashnaCategory.education:
        return {
          'title': 'Higher Education & Examination Inquiry',
          'primary': 4,
          'primaryList': [4, 9],
          'supporting': [11],
          'negating': [3, 8],
        };
      case PrashnaCategory.travel:
        return {
          'title': 'Foreign Travel & Relocation Inquiry',
          'primary': 9,
          'primaryList': [9, 12],
          'supporting': [3],
          'negating': [2, 11],
        };
      case PrashnaCategory.litigation:
        return {
          'title': 'Court Case & Dispute Victory Inquiry',
          'primary': 6,
          'primaryList': [6, 11],
          'supporting': [1],
          'negating': [5, 12],
        };
    }
  }

  String _generateInterpretation({
    required PrashnaCategory category,
    required PrashnaVerdict verdict,
    required String cuspSubLord,
    required String starLord,
    required List<int> primaryHouses,
    required List<int> supportingHouses,
    required List<int> negatingHouses,
  }) {
    final housesStr = [...primaryHouses, ...supportingHouses].join(', ');
    final negStr = negatingHouses.join(', ');

    if (verdict == PrashnaVerdict.promised) {
      return 'The event is strongly PROMISED under KP principles. The Cusp Sub-Lord ($cuspSubLord) '
          'and its Star Lord ($starLord) directly connect to houses ($housesStr), which represent '
          'the core fulfillment houses for this query. Expect positive results without major hindrance.';
    } else if (verdict == PrashnaVerdict.conditional) {
      return 'The event is CONDITIONAL / DELAYED. The Cusp Sub-Lord ($cuspSubLord) signifies both positive '
          'houses ($housesStr) and conflicting houses ($negStr). Fulfillment will require extra patience, '
          'negotiation, or specific planetary timing.';
    } else {
      return 'The event is UNFAVORABLE / DENIED at this time. The Cusp Sub-Lord ($cuspSubLord) through its '
          'Star Lord ($starLord) predominantly connects to negating houses ($negStr), which obstruct '
          'the desired outcome.';
    }
  }

  String _generateTimingGuidance({
    required PrashnaVerdict verdict,
    required String starLord,
    required String cuspSubLord,
    required List<int> favorableHouses,
  }) {
    if (verdict == PrashnaVerdict.denied) {
      return 'No immediate favorable period indicated. Re-query after significant planetary transits.';
    }
    final favStr = favorableHouses.join(', ');
    return 'Fulfillment is expected during the joint period (Mahadasha / Antardasha / Sookshma) '
        'of planets signifying houses ($favStr), particularly when transiting Moon or Sun activates '
        'the star of $starLord or $cuspSubLord.';
  }
}
