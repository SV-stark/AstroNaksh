import 'package:jyotish/jyotish.dart';

import '../data/life_prediction_models.dart';
import '../data/models.dart';
import 'ashtakavarga.dart';
import 'bhava_bala.dart';
import 'jaimini_service.dart';
import 'planetary_aspect_service.dart' as pa;
import 'shadbala.dart';
import 'yoga_dosha_analyzer.dart';

enum FunctionalStatus { benefic, malefic, neutral }

/// Mapping of which Yoga/Dosha names are relevant to each LifeAspect.
/// Yogas boost the score; Doshas reduce it.
const _aspectYogaMap = <LifeAspect, List<String>>{
  LifeAspect.career: [
    'Raj Yoga',
    'Amala Yoga',
    'Budhaditya Yoga',
    'Chamara Yoga',
    'Pancha Mahapurusha',
    'Adhi Yoga',
  ],
  LifeAspect.wealth: [
    'Dhana Yoga',
    'Lakshmi Yoga',
    'Chandra Mangala Yoga',
    'Gajakesari Yoga',
    'Adhi Yoga',
  ],
  LifeAspect.family: [
    'Gajakesari Yoga',
    'Adhi Yoga',
    'Parvata Yoga',
    'Amala Yoga',
  ],
  LifeAspect.romance: [
    'Gajakesari Yoga',
    'Chandra Mangala Yoga',
  ],
  LifeAspect.health: [
    'Amala Yoga',
    'Pancha Mahapurusha',
  ],
  LifeAspect.children: [
    'Kahala Yoga',
    'Gajakesari Yoga',
    'Saraswati Yoga',
  ],
  LifeAspect.education: [
    'Saraswati Yoga',
    'Budhaditya Yoga',
    'Chamara Yoga',
  ],
  LifeAspect.spirituality: [
    'Vipreet Raj Yoga',
    'Adhi Yoga',
    'Parvata Yoga',
    'Gajakesari Yoga',
  ],
};

const _aspectDoshaMap = <LifeAspect, List<String>>{
  LifeAspect.career: ['Daridra Dosha', 'Shrapit Dosha'],
  LifeAspect.wealth: ['Daridra Dosha', 'Kemadruma Dosha', 'Shrapit Dosha'],
  LifeAspect.family: ['Mangal Dosha', 'Kemadruma Dosha'],
  LifeAspect.romance: [
    'Mangal Dosha',
    'Kemadruma Dosha',
    'Kaal Sarp Dosha',
    'Shrapit Dosha',
  ],
  LifeAspect.health: [
    'Angarak Dosha',
    'Grahan Dosha',
    'Kaal Sarp Dosha',
    'Vish Dosha',
  ],
  LifeAspect.children: ['Pitra Dosha', 'Kaal Sarp Dosha', 'Guru Chandal Dosha'],
  LifeAspect.education: ['Kemadruma Dosha', 'Grahan Dosha'],
  LifeAspect.spirituality: [
    'Kaal Sarp Dosha',
    'Guru Chandal Dosha',
    'Pitra Dosha',
  ],
};

/// Planet significations per aspect — which Mahadasha/Antardasha lords
/// are activating for this life area right now.
const _aspectDashaLords = <LifeAspect, List<String>>{
  LifeAspect.career: ['Sun', 'Saturn', 'Mercury', 'Mars'],
  LifeAspect.wealth: ['Jupiter', 'Venus', 'Moon', 'Mercury'],
  LifeAspect.family: ['Moon', 'Venus', 'Mars', 'Mercury'],
  LifeAspect.romance: ['Venus', 'Mars', 'Jupiter', 'Moon'],
  LifeAspect.health: ['Sun', 'Mars', 'Saturn', 'Jupiter'],
  LifeAspect.children: ['Jupiter', 'Moon', 'Mercury', 'Sun'],
  LifeAspect.education: ['Mercury', 'Jupiter', 'Sun', 'Venus'],
  LifeAspect.spirituality: ['Jupiter', 'Ketu', 'Moon', 'Saturn'],
};

/// Upachaya houses — malefics here improve over time
const _upachayaHouses = {3, 6, 10, 11};

/// Natural malefics in Vedic astrology
const _naturalMalefics = {
  Planet.saturn,
  Planet.mars,
  Planet.meanNode,
  Planet.trueNode,
};

/// ===================================================================
/// Life Prediction Service
/// Generates comprehensive life predictions using:
///   1. Shadbala (planetary strength)
///   2. Bhava Bala (house strength)
///   3. Ashtakavarga bindus per house
///   4. Vimshopak Bala (divisional chart strength)
///   5. Ishtaphala / Kashtaphala (net planetary fruit)
///   6. Yoga / Dosha analysis
///   7. Vimshottari Dasha current period
///   8. Planetary aspects (Graha Drishti)
///   9. Atmakaraka elevation
///  10. Upachaya house malefic rule
/// ===================================================================
class LifePredictionService {
  /// Generate complete life predictions for all aspects
  Future<LifePredictionsResult> generateLifePredictions(
    CompleteChartData chartData,
  ) async {
    // ── Gather all analytical inputs ──────────────────────────────────

    // 1. Shadbala
    final shadbala = await ShadbalaCalculator.calculateShadbala(chartData);

    // 2. Bhava Bala
    final bhavaBala = await BhavaBala.calculateBhavaBala(chartData);

    // 3. Ashtakavarga bindus per house sign (0-indexed sign → bindus 0-56)
    final avBindus = AshtakavargaSystem.calculateSarvashtakavarga(
      chartData.baseChart,
    );
    // Convert sign-indexed bindus to house-indexed bindus
    final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
    final houseAvBindus = <int, int>{};
    for (var h = 1; h <= 12; h++) {
      final houseSign = (ascSign + h - 1) % 12;
      houseAvBindus[h] = avBindus[houseSign] ?? 28;
    }

    // 4. Vimshopak Bala (0–20 scale per planet)
    final vimshopak = BhavaBala.calculateAllVimshopakBala(chartData);

    // 5. Ishtaphala / Kashtaphala (async — net fruit of each planet)
    final planetFruits = await BhavaBala.calculateAllPlanetFruits(chartData);

    // 6. Yoga / Dosha analysis
    final yogaDosha = YogaDoshaAnalyzer.analyze(chartData);

    // 7. Current Vimshottari Dasha (from chartData which already stores it)
    final currentDasha = chartData.getCurrentDashas(DateTime.now());
    final currentMahaDashaLord = currentDasha['mahadasha'] as String? ?? '';
    final currentAntarDashaLord = currentDasha['antardasha'] as String? ?? '';

    // 8. Planetary aspects
    final aspects = pa.PlanetaryAspectService.calculateAspects(
      chartData.baseChart,
    );

    // 9. Atmakaraka
    final jaimini = JaiminiAnalysisService();
    final atmakaraka = jaimini.getAtmakaraka(chartData);

    // ── Build prediction context ──────────────────────────────────────
    final ctx = _PredictionContext(
      shadbala: shadbala,
      bhavaBala: bhavaBala,
      houseAvBindus: houseAvBindus,
      vimshopak: vimshopak,
      planetFruits: planetFruits,
      yogaDosha: yogaDosha,
      currentMahaDashaLord: currentMahaDashaLord,
      currentAntarDashaLord: currentAntarDashaLord,
      aspects: aspects,
      atmakaraka: atmakaraka,
    );

    // ── Generate per-aspect predictions ──────────────────────────────
    final predictions = <LifeAspectPrediction>[];
    for (final aspect in LifeAspect.values) {
      predictions.add(
        _generateAspectPrediction(chartData, aspect, ctx),
      );
    }

    return LifePredictionsResult.fromAspects(predictions);
  }

  // ══════════════════════════════════════════════════════════════════
  // ASPECT PREDICTION
  // ══════════════════════════════════════════════════════════════════

  LifeAspectPrediction _generateAspectPrediction(
    CompleteChartData chartData,
    LifeAspect aspect,
    _PredictionContext ctx,
  ) {
    // ── 1. Planetary influences ───────────────────────────────────────
    final influences = <PlanetaryInfluence>[];

    for (final planet in aspect.primaryPlanets) {
      final inf = _analyzePlanetForAspect(chartData, planet, aspect, ctx);
      if (inf != null) influences.add(inf);
    }

    for (final house in aspect.houses) {
      final houseLord = _getHouseLord(chartData, house);
      if (!aspect.primaryPlanets.contains(houseLord)) {
        final inf = _analyzePlanetForAspect(
          chartData,
          houseLord,
          aspect,
          ctx,
          isHouseLord: true,
          houseNumber: house,
        );
        if (inf != null) influences.add(inf);
      }
    }

    // ── 2. Score calculation ──────────────────────────────────────────
    final score = _calculateScore(chartData, aspect, influences, ctx);

    // ── 3. Prediction text ────────────────────────────────────────────
    final prediction = _generatePredictionText(
      chartData,
      aspect,
      influences,
      score,
      ctx,
    );

    // ── 4. Advice ────────────────────────────────────────────────────
    final advice = _generateAdvice(aspect, influences, score, ctx);

    return LifeAspectPrediction(
      aspectName: aspect.name,
      aspectDescription: aspect.description,
      iconName: aspect.icon,
      score: score,
      prediction: prediction,
      influences: influences,
      advice: advice,
      relevantHouses: aspect.houses,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // SCORE CALCULATION (5-component formula)
  // ══════════════════════════════════════════════════════════════════

  int _calculateScore(
    CompleteChartData chartData,
    LifeAspect aspect,
    List<PlanetaryInfluence> influences,
    _PredictionContext ctx,
  ) {
    // ── Component A: Ishtaphala / Kashtaphala (30%) ───────────────────
    // Net planetary fruit — most holistic per-planet measure
    double ishtaTotal = 0;
    double kashtaTotal = 0;
    int fruitCount = 0;
    final relevantPlanets = {
      ...aspect.primaryPlanets,
      for (final h in aspect.houses) _getHouseLord(chartData, h),
    };
    for (final planet in relevantPlanets) {
      final fruits = ctx.planetFruits[planet];
      if (fruits != null) {
        ishtaTotal += fruits.ishtaphala;
        kashtaTotal += fruits.kashtaphala;
        fruitCount++;
      }
    }
    final double baseScore = fruitCount > 0
        ? ((ishtaTotal - kashtaTotal + fruitCount * 60) /
                (fruitCount * 120) *
                100)
            .clamp(0, 100)
        : 50;

    // ── Component B: House Strength — Bhava Bala + Ashtakavarga (25%) ─
    double houseScoreTotal = 0;
    for (final house in aspect.houses) {
      final bhava = ctx.bhavaBala[house]?.totalStrength ?? 50.0;
      final bindus = ctx.houseAvBindus[house] ?? 28;
      // bindus: 0-56; 28 is average
      final avScore = (bindus / 56.0) * 100.0;
      houseScoreTotal += bhava * 0.5 + avScore * 0.5;
    }
    final double houseScore =
        aspect.houses.isEmpty ? 50 : houseScoreTotal / aspect.houses.length;

    // ── Component C: Vimshopak Bala (20%) ────────────────────────────
    double vimshopakTotal = 0;
    int vimshopakCount = 0;
    for (final planet in relevantPlanets) {
      final vb = ctx.vimshopak[planet];
      if (vb != null) {
        // VimshopakBala totalScore is 0–20
        vimshopakTotal += (vb.totalScore / 20.0) * 100.0;
        vimshopakCount++;
      }
    }
    final double vimshopakScore =
        vimshopakCount > 0 ? vimshopakTotal / vimshopakCount : 50;

    // ── Component D: Yoga / Dosha bonus/penalty (15%) ─────────────────
    final relevantYogas = _aspectYogaMap[aspect] ?? [];
    final relevantDoshas = _aspectDoshaMap[aspect] ?? [];

    double yogaBonus = 0;
    for (final yoga in ctx.yogaDosha.yogas) {
      if (yoga.isActive && relevantYogas.any((r) => yoga.name.contains(r))) {
        yogaBonus += (yoga.strength / 100.0) * 12.0;
      }
    }
    double doshapenalty = 0;
    for (final dosha in ctx.yogaDosha.doshas) {
      if (dosha.isActive && relevantDoshas.any((r) => dosha.name.contains(r))) {
        doshapenalty += (dosha.strength / 100.0) * 12.0;
      }
    }
    // Normalize yoga component to 0-100 range (50 = neutral)
    final double yogaComponent = (50 + yogaBonus - doshapenalty).clamp(0, 100);

    // ── Component E: Dasha timing modifier (10%) ──────────────────────
    final dashaLords = _aspectDashaLords[aspect] ?? [];
    final mahaIsRelevant = dashaLords.contains(ctx.currentMahaDashaLord);
    final antarIsRelevant = dashaLords.contains(ctx.currentAntarDashaLord);

    // Check if current Dasha lord is benefic or malefic for this chart
    final double dashaScore;
    if (mahaIsRelevant && antarIsRelevant) {
      // Both lords are significators — strong activation
      dashaScore = 80;
    } else if (mahaIsRelevant || antarIsRelevant) {
      dashaScore = 65;
    } else {
      dashaScore = 45; // Neutral — other areas are more activated
    }

    // ── Atmakaraka bonus ─────────────────────────────────────────────
    // If the Atmakaraka is in the relevant planet set, add 5 points
    final double atmaBonus =
        relevantPlanets.contains(ctx.atmakaraka) ? 5.0 : 0.0;

    // ── Upachaya bonus for malefics ───────────────────────────────────
    // Natural malefics in Upachaya houses (3, 6, 10, 11) improve over time
    double upachayaBonus = 0;
    for (final planet in relevantPlanets) {
      if (_naturalMalefics.contains(planet)) {
        final planetInfo = chartData.baseChart.planets[planet];
        if (planetInfo != null &&
            _upachayaHouses.contains(planetInfo.house)) {
          upachayaBonus += 3.0;
        }
      }
    }

    // ── Final weighted score ──────────────────────────────────────────
    final double rawScore = baseScore * 0.30 +
        houseScore * 0.25 +
        vimshopakScore * 0.20 +
        yogaComponent * 0.15 +
        dashaScore * 0.10 +
        atmaBonus +
        upachayaBonus;

    return rawScore.clamp(30.0, 98.0).round();
  }

  // ══════════════════════════════════════════════════════════════════
  // PLANETARY INFLUENCE ANALYSIS
  // ══════════════════════════════════════════════════════════════════

  PlanetaryInfluence? _analyzePlanetForAspect(
    CompleteChartData chartData,
    Planet planet,
    LifeAspect aspect,
    _PredictionContext ctx, {
    bool isHouseLord = false,
    int? houseNumber,
  }) {
    final planetInfo = chartData.baseChart.planets[planet];
    if (planetInfo == null) return null;

    final longitude = planetInfo.longitude;
    final sign = planetInfo.position.zodiacSignIndex;
    final house = planetInfo.house;
    final signName = AstrologyConstants.getSignName(sign);

    final degreeInSign = longitude % 30;
    final degrees = degreeInSign.floor();
    final minutes = ((degreeInSign - degrees) * 60).floor();
    final degreeStr = "$degrees°${minutes.toString().padLeft(2, '0')}'";

    // Use Vimshopak Bala as primary strength indicator (more holistic)
    final vb = ctx.vimshopak[planet];
    final strength = vb != null
        ? (vb.totalScore / 20.0) * 100.0
        : ((ctx.shadbala[planet] ?? 300) / 600 * 100).clamp(0.0, 100.0);

    final status = planetInfo.dignity.name;
    final isRetrograde = planetInfo.isRetrograde;
    final isCombust = planetInfo.isCombust;

    final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
    final functionalStatus = _getFunctionalStatus(ascSign, planet);

    // Upachaya rule: malefics in 3/6/10/11 are treated as benefic
    final isUpachaya = _naturalMalefics.contains(planet) &&
        _upachayaHouses.contains(house);

    final isBenefic = isUpachaya ||
        _isBeneficForAspect(
          chartData,
          planet,
          aspect,
          sign,
          house,
          status,
          isCombust: isCombust,
        );

    var position = '';
    if (isHouseLord && houseNumber != null) {
      position =
          '${_getOrdinal(houseNumber)} Lord ${planet.displayName} at $degreeStr $signName in ${_getOrdinal(house)} House';
    } else {
      position =
          '${planet.displayName} at $degreeStr $signName in ${_getOrdinal(house)} House';
    }
    if (isRetrograde) position += ' (Retrograde)';
    if (isCombust) position += ' (Combust)';
    if (isUpachaya) position += ' [Upachaya — improves over time]';

    final effect = _generateEffectDescription(
      planet,
      aspect,
      status,
      isBenefic,
      house,
      isHouseLord,
      houseNumber,
      signName: signName,
      degreeStr: degreeStr,
      strength: strength,
      isRetrograde: isRetrograde,
      isCombust: isCombust,
      functionalStatus: functionalStatus,
      isUpachaya: isUpachaya,
    );

    return PlanetaryInfluence(
      planet: planet,
      position: position,
      status: status,
      strength: strength,
      effect: effect,
      isBenefic: isBenefic,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PREDICTION TEXT GENERATION
  // ══════════════════════════════════════════════════════════════════

  String _generatePredictionText(
    CompleteChartData chartData,
    LifeAspect aspect,
    List<PlanetaryInfluence> influences,
    int score,
    _PredictionContext ctx,
  ) {
    final buffer = StringBuffer();
    final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
    final ascSignName = AstrologyConstants.getSignName(ascSign);

    // ── Section 1: Cosmic Overview ────────────────────────────────────
    buffer.write('### Cosmic Overview & Analysis\n');
    buffer.write(
      'For your **$ascSignName Ascendant (Lagna)**, the astrological indicators governing **${aspect.name}** are analyzed. ',
    );

    if (score >= 80) {
      buffer.write(
        'Your birth chart indicates exceptional strength in this sphere, rated at an **Excellent** overall index of **$score%**. '
        'This represents highly favorable alignment of planetary forces, providing native ease, abundance, and structural support. ',
      );
    } else if (score >= 65) {
      buffer.write(
        'The alignments indicate a **Favorable** and stable pattern, rated at **$score%**. '
        'Consistent effort will bring growth and rewarding results in this domain. ',
      );
    } else if (score >= 50) {
      buffer.write(
        'Your chart exhibits **Mixed** influences, rated at **$score%**. '
        'While there are active sources of strength, certain planetary frictions or placement challenges require awareness and focus. ',
      );
    } else {
      buffer.write(
        'This area presents **Challenging** indications, rated at **$score%**. '
        'Planetary blockages, debilitations, or unfavorable placements demand caution. Focused discipline, inner growth, and remedial support are recommended. ',
      );
    }

    // ── Section 2: Bhava & Ashtakavarga Analysis ─────────────────────
    buffer.write('\n\n### Bhava (House) & Lordship Analysis\n');
    for (final house in aspect.houses) {
      final bhava = ctx.bhavaBala[house];
      final bhavaStrength = bhava?.totalStrength ?? 50.0;
      final bindus = ctx.houseAvBindus[house] ?? 28;
      final houseDesc = _getHouseSignificance(house);
      final houseLord = _getHouseLord(chartData, house);
      final lordInfo = chartData.baseChart.planets[houseLord];

      buffer.write('**The ${_getOrdinal(house)} House ($houseDesc):** ');
      buffer.write(
        'Bhava Bala of **${bhavaStrength.toStringAsFixed(0)}%**, representing a ',
      );
      if (bhavaStrength >= 60) {
        buffer.write('highly robust foundation. ');
      } else if (bhavaStrength >= 40) {
        buffer.write('moderately stable foundation. ');
      } else {
        buffer.write('delicate foundation that requires conscious strengthening. ');
      }

      // Ashtakavarga bindus
      final avLabel = bindus >= 30
          ? 'strong ($bindus/56 bindus)'
          : bindus >= 25
              ? 'average ($bindus/56 bindus)'
              : 'weak ($bindus/56 bindus — remedial attention advised)';
      buffer.write('Ashtakavarga score is **$avLabel**. ');

      if (lordInfo != null) {
        final lordSignIdx = lordInfo.position.zodiacSignIndex;
        final lordSignName = AstrologyConstants.getSignName(lordSignIdx);
        final lordHouse = _getHouseFromSign(chartData, lordSignIdx);
        final lordDignity = lordInfo.dignity.name;
        final isLordRetro = lordInfo.isRetrograde;
        final isLordCombust = lordInfo.isCombust;

        buffer.write(
          'Its lord, **${houseLord.displayName}**, is positioned in the **${_getOrdinal(lordHouse)} house** ($lordSignName). ',
        );

        if ([6, 8, 12].contains(lordHouse)) {
          buffer.write(
            'Because the house lord is placed in a Dusthana (difficult) house, it indicates that the benefits of the ${house}th house may feel obstructed, delayed, or require spiritual transformation to manifest. ',
          );
        } else if ([1, 4, 7, 10, 5, 9].contains(lordHouse)) {
          buffer.write(
            'Since the house lord resides in an auspicious Kendra or Trikona house, it channels highly positive, progressive energy, ensuring this house\'s indications are well-supported. ',
          );
        }

        if (lordDignity == 'Exalted') {
          buffer.write(
            'The lord\'s Exalted state further magnifies its capacity to deliver extraordinary outcomes. ',
          );
        } else if (lordDignity == 'Debilitated') {
          buffer.write(
            'The lord\'s Debilitated status indicates a lack of external power, suggesting that building inner resilience is essential. ',
          );
        } else if (lordDignity == 'Own Sign') {
          buffer.write(
            'Placed in its own sign, the lord remains highly stable and self-sufficient. ',
          );
        }

        if (isLordRetro) {
          buffer.write(
            'Being Retrograde, the lord\'s influence is introspective, requiring internal reflection before external success. ',
          );
        }
        if (isLordCombust) {
          buffer.write(
            'Since it is Combust, the lord\'s outer expression is weakened, bringing hidden vulnerabilities. ',
          );
        }
      }
      buffer.write('\n\n');
    }

    // ── Section 3: Key Planetary Influences ──────────────────────────
    buffer.write('### Key Astrological Influences\n');
    final benefics = influences.where((i) => i.isBenefic).toList();
    final malefics = influences.where((i) => !i.isBenefic).toList();

    if (benefics.isNotEmpty) {
      buffer.write('**Positive Assets:**\n');
      for (final inf in benefics) {
        buffer.write('- **${inf.position}**: ${inf.effect}\n');
      }
      buffer.write('\n');
    }

    if (malefics.isNotEmpty) {
      buffer.write('**Areas needing Awareness:**\n');
      for (final inf in malefics) {
        buffer.write('- **${inf.position}**: ${inf.effect}\n');
      }
      buffer.write('\n');
    }

    // ── Section 4: Active Yogas & Doshas ─────────────────────────────
    final relevantYogaNames = _aspectYogaMap[aspect] ?? [];
    final relevantDoshaNames = _aspectDoshaMap[aspect] ?? [];

    final activeYogas = ctx.yogaDosha.yogas
        .where(
          (y) =>
              y.isActive &&
              relevantYogaNames.any((r) => y.name.contains(r)),
        )
        .toList();
    final activeDoshas = ctx.yogaDosha.doshas
        .where(
          (d) =>
              d.isActive &&
              relevantDoshaNames.any((r) => d.name.contains(r)),
        )
        .toList();

    if (activeYogas.isNotEmpty || activeDoshas.isNotEmpty) {
      buffer.write('### Yogas & Doshas Affecting This Area\n');

      if (activeYogas.isNotEmpty) {
        buffer.write('**Active Yogas (Auspicious Formations):**\n');
        for (final yoga in activeYogas) {
          final strengthLabel = yoga.strength >= 80
              ? 'Strong'
              : yoga.strength >= 50
                  ? 'Moderate'
                  : 'Mild';
          buffer.write(
            '- **${yoga.name}** ($strengthLabel, ${yoga.strength.toStringAsFixed(0)}% strength): ${yoga.description} ',
          );
          if (yoga.manifestationPeriod.isNotEmpty) {
            buffer.write('Peak manifestation: ${yoga.manifestationPeriod}. ');
          }
          buffer.write('\n');
        }
        buffer.write('\n');
      }

      if (activeDoshas.isNotEmpty) {
        buffer.write('**Active Doshas (Areas of Caution):**\n');
        for (final dosha in activeDoshas) {
          buffer.write(
            '- **${dosha.name}** (${dosha.strength.toStringAsFixed(0)}% intensity): ${dosha.description} ',
          );
          if (dosha.cancellationReasons.isNotEmpty) {
            buffer.write(
              'Partial cancellation factors: ${dosha.cancellationReasons.join(", ")}. ',
            );
          }
          buffer.write('\n');
        }
        buffer.write('\n');
      }
    }

    // ── Section 5: Current Dasha Timing ──────────────────────────────
    if (ctx.currentMahaDashaLord.isNotEmpty) {
      buffer.write('### Current Dasha Period & Timing\n');
      final dashaLords = _aspectDashaLords[aspect] ?? [];
      final mahaActive = dashaLords.contains(ctx.currentMahaDashaLord);
      final antarActive = dashaLords.contains(ctx.currentAntarDashaLord);

      buffer.write(
        'You are currently running the **${ctx.currentMahaDashaLord} Mahadasha** ',
      );
      if (ctx.currentAntarDashaLord.isNotEmpty) {
        buffer.write('/ **${ctx.currentAntarDashaLord} Antardasha**. ');
      } else {
        buffer.write('. ');
      }

      if (mahaActive && antarActive) {
        buffer.write(
          'Both your Mahadasha and Antardasha lords are primary significators for **${aspect.name}** — this is a **highly activated period** for this life area. '
          'Events, decisions, and results related to ${aspect.name.toLowerCase()} are likely to be prominent and consequential now. ',
        );
      } else if (mahaActive) {
        buffer.write(
          'Your Mahadasha lord (${ctx.currentMahaDashaLord}) is a key significator for **${aspect.name}**, making this a **moderately activated period** for this area. ',
        );
      } else if (antarActive) {
        buffer.write(
          'Your Antardasha lord (${ctx.currentAntarDashaLord}) is a significator for **${aspect.name}**, providing **secondary activation** for this life area currently. ',
        );
      } else {
        buffer.write(
          'The current Dasha period (${ctx.currentMahaDashaLord}/${ctx.currentAntarDashaLord}) is not a primary activator for **${aspect.name}** at this time. Other life areas may be more prominent during this period. ',
        );
      }
      buffer.write('\n\n');
    }

    // ── Section 6: Planetary Aspects on Relevant Houses ──────────────
    final significantAspects = _getSignificantAspects(
      chartData,
      aspect,
      ctx.aspects,
    );
    if (significantAspects.isNotEmpty) {
      buffer.write('### Significant Planetary Aspects\n');
      for (final a in significantAspects) {
        final aspector = a.aspectingPlanet.displayName;
        final aspected = a.aspectedPlanet.displayName;
        final typeLabel = _aspectTypeLabel(a.type);
        final orbStr = a.orb.toStringAsFixed(1);
        buffer.write(
          '- **$aspector** forms a $typeLabel with **$aspected** (orb: $orbStr°) — ${_aspectInterpretation(a, aspect)}\n',
        );
      }
      buffer.write('\n');
    }

    // ── Atmakaraka note ───────────────────────────────────────────────
    final relevantPlanetSet = {
      ...aspect.primaryPlanets,
      for (final h in aspect.houses) _getHouseLord(chartData, h),
    };
    if (relevantPlanetSet.contains(ctx.atmakaraka)) {
      buffer.write(
        '**Note:** **${ctx.atmakaraka.displayName}** is your **Atmakaraka** (soul significator by Jaimini), '
        'giving it elevated karmic importance in all matters related to **${aspect.name}**. '
        'Events in this area often carry deep soul-level lessons and transformations.\n\n',
      );
    }

    return buffer.toString();
  }

  // ══════════════════════════════════════════════════════════════════
  // ADVICE GENERATION
  // ══════════════════════════════════════════════════════════════════

  String _generateAdvice(
    LifeAspect aspect,
    List<PlanetaryInfluence> influences,
    int score,
    _PredictionContext ctx,
  ) {
    final buffer = StringBuffer();

    // 1. Aspect-specific primary guidance
    switch (aspect) {
      case LifeAspect.career:
        buffer.write(
          'To elevate your career: focus on establishing long-term professional discipline and leveraging your 10th house strengths. ',
        );
      case LifeAspect.wealth:
        buffer.write(
          'To cultivate financial abundance: maintain rigorous budget habits, prioritize asset accumulation, and work with Jupiter and Venus cycles. ',
        );
      case LifeAspect.family:
        buffer.write(
          'To nourish family harmony: practice empathetic communication, create a calm domestic routine, and honor the 4th house Moon energy. ',
        );
      case LifeAspect.romance:
        buffer.write(
          'To harmonize relationships: foster mutual respect, transparency, and balance of power. Work with your 7th house and Venus placement consciously. ',
        );
      case LifeAspect.health:
        buffer.write(
          'To maximize vitality: implement daily physical activity, proper diet aligned with your Ascendant sign, and rhythmic sleep cycles. ',
        );
      case LifeAspect.children:
        buffer.write(
          'To support creative growth and children: encourage playfulness, intellect, and constructive guidance. Honor Jupiter as the karaka of children. ',
        );
      case LifeAspect.education:
        buffer.write(
          'To enhance wisdom: cultivate continuous study, analytical training, and respect for mentors. Work with Mercury and Jupiter cycles. ',
        );
      case LifeAspect.spirituality:
        buffer.write(
          'To deepen spiritual connection: dedicate time for daily introspection, meditation, and self-inquiry. Honor your 9th and 12th house energies. ',
        );
    }

    // 2. Dasha-specific timing advice
    if (ctx.currentMahaDashaLord.isNotEmpty) {
      final dashaLords = _aspectDashaLords[aspect] ?? [];
      if (dashaLords.contains(ctx.currentMahaDashaLord)) {
        buffer.write(
          '\n\n**Timing Advice (${ctx.currentMahaDashaLord} Dasha):** '
          'The current Mahadasha lord is actively triggering this area. '
          'This is an optimal window to take concrete action — results will come more readily now than in non-activating periods. '
          'Focus on the highest-priority steps in the next 1–2 years. ',
        );
      } else {
        buffer.write(
          '\n\n**Timing Advice:** '
          'The current ${ctx.currentMahaDashaLord} Mahadasha is not a primary activator for ${aspect.name.toLowerCase()}. '
          'Focus on groundwork and preparation; the right Dasha activation will amplify results when it arrives. ',
        );
      }
    }

    // 3. Weak/Malefic planetary remedies
    final weakInfluences = influences
        .where((i) => !i.isBenefic || i.strength < 50)
        .toList();
    if (weakInfluences.isNotEmpty) {
      buffer.write('\n\n**Remedial Measures (Upayas):** ');
      for (final influence in weakInfluences.take(2)) {
        buffer.write(
          'For **${influence.planetName}** (${influence.status}, ${influence.position.split('in ').last}): ',
        );
        buffer.write(_getRemedyForPlanet(influence.planet));
        buffer.write(' ');
      }
    } else if (influences.isNotEmpty) {
      final topPlanet = influences.first;
      buffer.write(
        '\n\nYour **${topPlanet.planetName}** is exceptionally well-placed. '
        'You can further amplify its positive vibration: ',
      );
      buffer.write(_getRemedyForPlanet(topPlanet.planet));
    }

    // 4. Active dosha remedies
    final relevantDoshaNames = _aspectDoshaMap[aspect] ?? [];
    final activeDoshas = ctx.yogaDosha.doshas
        .where(
          (d) =>
              d.isActive &&
              relevantDoshaNames.any((r) => d.name.contains(r)),
        )
        .take(1)
        .toList();
    if (activeDoshas.isNotEmpty) {
      buffer.write(
        '\n\n**Dosha Remedy (${activeDoshas.first.name}):** '
        '${_getDoshaRemedy(activeDoshas.first.name)}',
      );
    }

    return buffer.toString();
  }

  // ══════════════════════════════════════════════════════════════════
  // ASPECT HELPERS
  // ══════════════════════════════════════════════════════════════════

  List<pa.PlanetaryAspect> _getSignificantAspects(
    CompleteChartData chartData,
    LifeAspect aspect,
    List<pa.PlanetaryAspect> allAspects,
  ) {
    // Get the house lords of relevant houses — aspects TO these planets are
    // significant for this life area
    final relevantPlanets = <Planet>{
      ...aspect.primaryPlanets,
      for (final h in aspect.houses) _getHouseLord(chartData, h),
    };

    // Filter: aspected planet must be relevant; orb < 8°; avoid duplicates
    final seen = <String>{};
    return allAspects.where((a) {
      if (!relevantPlanets.contains(a.aspectedPlanet)) return false;
      if (a.orb > 8) return false;
      final key = '${a.aspectingPlanet}-${a.aspectedPlanet}-${a.type}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).take(4).toList();
  }

  String _aspectTypeLabel(pa.AspectType type) {
    switch (type) {
      case pa.AspectType.conjunction:
        return 'conjunction (☌)';
      case pa.AspectType.opposition:
        return 'opposition (☍)';
      case pa.AspectType.trine:
        return 'trine (△)';
      case pa.AspectType.square:
        return 'square (□)';
      case pa.AspectType.sextile:
        return 'sextile (⚹)';
    }
  }

  String _aspectInterpretation(pa.PlanetaryAspect a, LifeAspect lifeAspect) {
    final isBeneficAspect =
        a.type == pa.AspectType.trine || a.type == pa.AspectType.sextile;
    final isChallengingAspect =
        a.type == pa.AspectType.square || a.type == pa.AspectType.opposition;
    final aspectorName = a.aspectingPlanet.displayName;
    final aspectedName = a.aspectedPlanet.displayName;

    if (isBeneficAspect) {
      return '$aspectorName\'s harmonious influence on $aspectedName supports ${lifeAspect.name.toLowerCase()} with constructive energy.';
    } else if (isChallengingAspect) {
      return '$aspectorName\'s challenging aspect on $aspectedName introduces friction or pressure in ${lifeAspect.name.toLowerCase()} — conscious management is needed.';
    } else {
      // conjunction
      return '$aspectorName conjunct $aspectedName merges their energies — the combined effect depends on both planets\' dignity and functional status.';
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // EFFECT DESCRIPTION
  // ══════════════════════════════════════════════════════════════════

  String _generateEffectDescription(
    Planet planet,
    LifeAspect aspect,
    String status,
    bool isBenefic,
    int house,
    bool isHouseLord,
    int? houseNumber, {
    String signName = '',
    String degreeStr = '',
    double strength = 50,
    bool isRetrograde = false,
    bool isCombust = false,
    FunctionalStatus functionalStatus = FunctionalStatus.neutral,
    bool isUpachaya = false,
  }) {
    final buffer = StringBuffer();
    final planetName = planet.displayName;
    final aspectArea = aspect.name.toLowerCase();

    if (isHouseLord && houseNumber != null) {
      final significance = _getHouseSignificance(houseNumber);
      buffer.write('As the Lord of the ${houseNumber}th house ($significance), ');
    } else {
      buffer.write('As a primary planetary significator of $aspectArea, ');
    }

    final functionalLabel = switch (functionalStatus) {
      FunctionalStatus.benefic => 'highly supportive functional benefic',
      FunctionalStatus.malefic => 'challenging functional malefic',
      FunctionalStatus.neutral => 'neutral planetary force',
    };
    buffer.write('$planetName acts as a $functionalLabel for your Ascendant. ');

    buffer.write(
      'It is positioned at $degreeStr in $signName in the ${_getOrdinal(house)} house',
    );
    switch (status) {
      case 'Exalted':
        buffer.write(
          ' in an Exalted state, providing outstanding strength and highly auspicious energy for these matters.',
        );
      case 'Own Sign':
        buffer.write(
          ' in its own sign, granting excellent stability, natural confidence, and smooth operations.',
        );
      case 'Friendly Sign':
        buffer.write(
          ' in a friendly sign, enabling a comfortable and supportive expression of its positive vibrations.',
        );
      case 'Enemy Sign':
        buffer.write(
          ' in an enemy sign, causing friction, resistance, and requiring self-discipline to channel constructively.',
        );
      case 'Debilitated':
        buffer.write(
          ' in a debilitated state, pointing to structural weaknesses, energy blocks, or lessons that demand persistent discipline.',
        );
      default:
        buffer.write(' in a neutral state.');
    }

    if (isUpachaya) {
      buffer.write(
        ' As a natural malefic placed in an Upachaya house ($house), its energy improves progressively over time — results strengthen with age and persistent effort.',
      );
    }

    if (isRetrograde) {
      buffer.write(
        ' Being Retrograde (Rx), its energy is turned inward, prompting self-reflection, potential delays, or a karmic re-examination.',
      );
    }
    if (isCombust) {
      buffer.write(
        ' Because it is Combust (too close to the Sun), its external capabilities are obscured, indicating hidden trials or self-limitations.',
      );
    }

    buffer.write(' Vimshopak/Shadbala strength is ${strength.toStringAsFixed(0)}% (');
    if (strength >= 70) {
      buffer.write('exceptionally strong).');
    } else if (strength >= 40) {
      buffer.write('moderately stable).');
    } else {
      buffer.write('delicate, needing conscious reinforcement).');
    }

    return buffer.toString();
  }

  // ══════════════════════════════════════════════════════════════════
  // CHART HELPERS
  // ══════════════════════════════════════════════════════════════════

  int _getHouseFromSign(CompleteChartData chartData, int sign) {
    final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
    return ((sign - ascSign + 12) % 12) + 1;
  }

  Planet _getHouseLord(CompleteChartData chartData, int house) {
    final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
    final houseSign = (ascSign + house - 1) % 12;
    return AstrologyConstants.getSignLord(houseSign);
  }

  FunctionalStatus _getFunctionalStatus(int ascendant, Planet planet) {
    switch (ascendant) {
      case 0: // Aries
        if ([Planet.sun, Planet.moon, Planet.mars, Planet.jupiter]
            .contains(planet)) { return FunctionalStatus.benefic; }
        if ([Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 1: // Taurus
        if ([Planet.sun, Planet.mercury, Planet.venus, Planet.saturn]
            .contains(planet)) { return FunctionalStatus.benefic; }
        if ([Planet.moon, Planet.mars, Planet.jupiter].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 2: // Gemini
        if ([Planet.mercury, Planet.venus].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([Planet.sun, Planet.mars, Planet.jupiter].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 3: // Cancer
        if ([Planet.moon, Planet.mars, Planet.jupiter].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 4: // Leo
        if ([Planet.sun, Planet.mars, Planet.jupiter].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([Planet.moon, Planet.mercury, Planet.venus, Planet.saturn]
            .contains(planet)) { return FunctionalStatus.malefic; }
      case 5: // Virgo
        if ([Planet.mercury, Planet.venus].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([Planet.sun, Planet.moon, Planet.mars, Planet.jupiter]
            .contains(planet)) { return FunctionalStatus.malefic; }
      case 6: // Libra
        if ([Planet.moon, Planet.mercury, Planet.venus, Planet.saturn]
            .contains(planet)) { return FunctionalStatus.benefic; }
        if ([Planet.sun, Planet.mars, Planet.jupiter].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 7: // Scorpio
        if ([Planet.sun, Planet.moon, Planet.mars, Planet.jupiter]
            .contains(planet)) { return FunctionalStatus.benefic; }
        if ([Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 8: // Sagittarius
        if ([Planet.sun, Planet.mars, Planet.jupiter].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([Planet.moon, Planet.mercury, Planet.venus, Planet.saturn]
            .contains(planet)) { return FunctionalStatus.malefic; }
      case 9: // Capricorn
        if ([Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([Planet.sun, Planet.moon, Planet.mars, Planet.jupiter]
            .contains(planet)) { return FunctionalStatus.malefic; }
      case 10: // Aquarius
        if ([Planet.sun, Planet.venus, Planet.saturn].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([Planet.moon, Planet.mars, Planet.jupiter].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 11: // Pisces
        if ([Planet.moon, Planet.mars, Planet.jupiter].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([Planet.sun, Planet.mercury, Planet.venus, Planet.saturn]
            .contains(planet)) { return FunctionalStatus.malefic; }
    }
    return FunctionalStatus.neutral;
  }

  bool _isBeneficForAspect(
    CompleteChartData chartData,
    Planet planet,
    LifeAspect aspect,
    int sign,
    int house,
    String status, {
    bool isCombust = false,
  }) {
    if (isCombust) return false;

    final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
    final functional = _getFunctionalStatus(ascSign, planet);

    if (status == 'Exalted' || status == 'Own Sign') {
      return functional != FunctionalStatus.malefic ||
          ![6, 8, 12].contains(house);
    }

    if (status == 'Debilitated') return false;

    if (functional == FunctionalStatus.benefic) return true;
    if (functional == FunctionalStatus.malefic) return false;

    const naturalBenefics = [
      Planet.jupiter,
      Planet.venus,
      Planet.mercury,
      Planet.moon,
    ];

    if (aspect.houses.contains(house)) {
      return naturalBenefics.contains(planet) || status == 'Friendly Sign';
    }

    return naturalBenefics.contains(planet);
  }

  String _getHouseSignificance(int house) {
    const significances = {
      1: 'Self & Personality',
      2: 'Wealth & Speech',
      3: 'Siblings & Courage',
      4: 'Home & Mother',
      5: 'Children & Intelligence',
      6: 'Enemies & Health',
      7: 'Marriage & Partnerships',
      8: 'Longevity & Transformation',
      9: 'Fortune & Dharma',
      10: 'Career & Status',
      11: 'Gains & Aspirations',
      12: 'Liberation & Losses',
    };
    return significances[house] ?? 'House $house';
  }

  String _getRemedyForPlanet(Planet planet) {
    const remedies = {
      Planet.sun:
          'Offer water to Sun at sunrise and recite Aditya Hridayam on Sundays.',
      Planet.moon:
          'Wear pearl or moonstone, and observe fast on Mondays. Honor your mother figure.',
      Planet.mars:
          'Recite Hanuman Chalisa on Tuesdays. Wear red coral after consultation.',
      Planet.mercury:
          'Worship Lord Vishnu on Wednesdays. Donate to education and literacy causes.',
      Planet.jupiter:
          'Fast on Thursdays and worship Lord Vishnu/Guru. Donate yellow items and food.',
      Planet.venus:
          'Worship Goddess Lakshmi on Fridays. Wear diamond or white sapphire after consultation.',
      Planet.saturn:
          'Recite Shani Stotra on Saturdays. Serve the elderly and donate to workers.',
      Planet.meanNode:
          'Donate to sweepers on Saturdays. Recite Rahu Mantra with sincere intent.',
      Planet.trueNode:
          'Worship Lord Ganesha and recite Ketu Mantra. Practice detachment.',
    };
    return remedies[planet] ?? 'Consult a Vedic astrologer for specific remedies.';
  }

  String _getDoshaRemedy(String doshaName) {
    if (doshaName.contains('Mangal')) {
      return 'Perform Mangal Shanti puja. Recite Hanuman Chalisa on Tuesdays. '
          'Wearing red coral (after expert consultation) or donating lentils on Tuesdays helps reduce Mangal Dosha intensity.';
    }
    if (doshaName.contains('Kaal Sarp')) {
      return 'Perform Kaal Sarp Dosha Shanti puja at Tryambakeshwar or Ujjain. '
          'Recite Mahamrityunjaya Mantra 108 times daily. Fast on Naag Panchami.';
    }
    if (doshaName.contains('Guru Chandal')) {
      return 'Worship Lord Vishnu and Guru (Jupiter). Donate yellow cloth and turmeric on Thursdays. '
          'Avoid disrespecting teachers and spiritual leaders.';
    }
    if (doshaName.contains('Pitra')) {
      return 'Perform Pitru Tarpan during Pitru Paksha. Offer food and water to ancestors. '
          'Donate to Brahmins and feed crows on Saturdays.';
    }
    if (doshaName.contains('Angarak')) {
      return 'Recite Hanuman Chalisa and Mangal Stotra on Tuesdays. '
          'Donate red lentils and copper items. Avoid aggression and conflicts.';
    }
    if (doshaName.contains('Kemadruma')) {
      return 'Worship the Moon (Chandra). Wear pearl after consultation. '
          'Fast on Mondays and recite Chandra mantra 108 times.';
    }
    if (doshaName.contains('Daridra')) {
      return 'Worship Goddess Lakshmi on Fridays. Donate to the needy. '
          'Recite Shri Sukta and maintain cleanliness in all dealings.';
    }
    if (doshaName.contains('Shrapit')) {
      return 'Perform Saturn shanti puja. Donate black sesame on Saturdays. '
          'Recite Shani Stotra and serve the elderly and underprivileged.';
    }
    if (doshaName.contains('Grahan')) {
      return 'Recite Mahamrityunjaya Mantra 108 times daily. '
          'Donate on eclipse days. Worship Lord Shiva and perform Rahu/Ketu shanti.';
    }
    if (doshaName.contains('Vish')) {
      return 'Worship Lord Shiva with milk and bilva leaves. '
          'Recite Maha Mrityunjaya Mantra. Avoid impure food and environments.';
    }
    return 'Consult a qualified Vedic astrologer for targeted dosha remedies.';
  }

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}

// ══════════════════════════════════════════════════════════════════
// PREDICTION CONTEXT — bundles all pre-computed analytics
// ══════════════════════════════════════════════════════════════════

class _PredictionContext {
  _PredictionContext({
    required this.shadbala,
    required this.bhavaBala,
    required this.houseAvBindus,
    required this.vimshopak,
    required this.planetFruits,
    required this.yogaDosha,
    required this.currentMahaDashaLord,
    required this.currentAntarDashaLord,
    required this.aspects,
    required this.atmakaraka,
  });

  final Map<Planet, double> shadbala;
  final Map<int, BhavaStrength> bhavaBala;
  final Map<int, int> houseAvBindus;
  final Map<Planet, VimshopakBala> vimshopak;
  final Map<Planet, ({double ishtaphala, double kashtaphala})> planetFruits;
  final YogaDoshaAnalysisResult yogaDosha;
  final String currentMahaDashaLord;
  final String currentAntarDashaLord;
  final List<pa.PlanetaryAspect> aspects; // ignore: library_private_types_in_public_api
  final Planet atmakaraka;
}
