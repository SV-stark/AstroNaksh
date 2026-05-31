import 'package:jyotish/jyotish.dart' hide CompoundRelationship;

import '../core/astro_utils.dart';
import '../data/life_prediction_models.dart';
import '../data/models.dart';
import 'ashtakavarga.dart';
import 'bhava_bala.dart';
import 'dasha_system.dart';
import 'divisional_charts.dart';
import 'jaimini_service.dart';
import 'planetary_aspect_service.dart' as pa;
import 'planetary_maitri_service.dart';
import 'shadbala.dart';
import 'transit_analysis.dart';
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
  LifeAspect.romance: ['Gajakesari Yoga', 'Chandra Mangala Yoga'],
  LifeAspect.health: ['Amala Yoga', 'Pancha Mahapurusha'],
  LifeAspect.children: ['Kahala Yoga', 'Gajakesari Yoga', 'Saraswati Yoga'],
  LifeAspect.education: ['Saraswati Yoga', 'Budhaditya Yoga', 'Chamara Yoga'],
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
///  11. Gochara (Transit) Overlay (NEW)
///  12. Vargas Divisional Cross-Verification (NEW)
///  13. Nakshatra core foundation (NEW)
///  14. Jaimini indicators (NEW)
/// ===================================================================
class LifePredictionService {
  /// Generate complete life predictions for all aspects
  Future<LifePredictionsResult> generateLifePredictions(
    CompleteChartData chartData,
  ) async {
    // ── Gather all analytical inputs ──────────────────────────────────

    // Fetch all independent asynchronous operations concurrently
    final results = await Future.wait([
      ShadbalaCalculator.calculateShadbala(chartData),
      BhavaBala.calculateBhavaBala(chartData),
      BhavaBala.calculateAllPlanetFruits(chartData),
      DashaSystem.getCurrentDashaFromChart(chartData.baseChart, DateTime.now()),
      TransitAnalysis()
          .calculateTransitChart(chartData, DateTime.now())
          .then<TransitChart?>((value) => value)
          .catchError((_) => null),
    ]);

    final shadbala = results[0] as Map<Planet, double>;
    final bhavaBala = results[1] as Map<int, BhavaStrength>;
    final planetFruits =
        results[2] as Map<Planet, ({double ishtaphala, double kashtaphala})>;
    final dashaDetails = results[3] as Map<String, dynamic>;
    final currentTransit = results[4] as TransitChart?;

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

    // 6. Yoga / Dosha analysis
    final yogaDosha = YogaDoshaAnalyzer.analyze(chartData);

    // Dasha details parsing
    final currentMahaDashaLord = dashaDetails['mahadasha'] as String? ?? '';
    final currentAntarDashaLord = dashaDetails['antardasha'] as String? ?? '';
    final currentPratyantarDashaLord =
        dashaDetails['pratyantardasha'] as String? ?? '';
    final mahaStart = dashaDetails['mahaStart'] as DateTime?;
    final mahaEnd = dashaDetails['mahaEnd'] as DateTime?;
    final antarStart = dashaDetails['antarStart'] as DateTime?;
    final antarEnd = dashaDetails['antarEnd'] as DateTime?;
    final pratyanStart = dashaDetails['pratyanStart'] as DateTime?;
    final pratyanEnd = dashaDetails['pratyanEnd'] as DateTime?;

    // 8. Planetary aspects
    final aspects = pa.PlanetaryAspectService.calculateAspects(
      chartData.baseChart,
    );

    // 9. Atmakaraka
    final jaimini = JaiminiAnalysisService();
    final atmakaraka = jaimini.getAtmakaraka(chartData);

    // 11. Divisional Charts (NEW)
    final divisionalCharts = DivisionalCharts.calculateAllCharts(
      chartData.baseChart,
    );

    // 12. Compound planetary relationships (NEW)
    final compoundRelationships =
        PlanetaryMaitriService.calculateCompoundRelationships(
          chartData.baseChart,
        );

    // 13. Moon Nakshatra (NEW)
    final moonPlanetInfo = chartData.baseChart.planets[Planet.moon];
    final moonNakshatra = moonPlanetInfo?.position.nakshatra ?? '';
    final moonNakshatraPada = moonPlanetInfo?.position.nakshatraPada ?? 1;
    final moonNakshatraIndex = moonPlanetInfo?.position.nakshatraIndex ?? 0;

    // ── Build prediction context ──────────────────────────────────────
    final ctx = _PredictionContext(
      baseChart: chartData.baseChart,
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
      currentTransit: currentTransit,
      divisionalCharts: divisionalCharts,
      compoundRelationships: compoundRelationships,
      currentPratyantarDashaLord: currentPratyantarDashaLord,
      mahaStart: mahaStart,
      mahaEnd: mahaEnd,
      antarStart: antarStart,
      antarEnd: antarEnd,
      pratyanStart: pratyanStart,
      pratyanEnd: pratyanEnd,
      moonNakshatra: moonNakshatra,
      moonNakshatraPada: moonNakshatraPada,
      moonNakshatraIndex: moonNakshatraIndex,
    );

    // ── Generate per-aspect predictions ──────────────────────────────
    final predictions = <LifeAspectPrediction>[];
    for (final aspect in LifeAspect.values) {
      predictions.add(_generateAspectPrediction(chartData, aspect, ctx));
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
  // SCORE CALCULATION (7-component formula)
  // ══════════════════════════════════════════════════════════════════

  int _calculateScore(
    CompleteChartData chartData,
    LifeAspect aspect,
    List<PlanetaryInfluence> influences,
    _PredictionContext ctx,
  ) {
    // ── Component A: Ishtaphala / Kashtaphala (25%) ───────────────────
    // Net planetary fruit — most holistic per-planet measure
    var ishtaTotal = 0.0;
    var kashtaTotal = 0.0;
    var fruitCount = 0;
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
    final baseScore = fruitCount > 0
        ? ((ishtaTotal - kashtaTotal + fruitCount * 60) /
                  (fruitCount * 120) *
                  100)
              .clamp(0, 100)
        : 50.0;

    // ── Component B: House Strength — Bhava Bala + Ashtakavarga (20%) ─
    var houseScoreTotal = 0.0;
    for (final house in aspect.houses) {
      final bhava = ctx.bhavaBala[house]?.totalStrength ?? 50.0;
      final bindus = ctx.houseAvBindus[house] ?? 28;
      // bindus: 0-56; 28 is average
      final avScore = (bindus / 56.0) * 100.0;
      houseScoreTotal += bhava * 0.5 + avScore * 0.5;
    }
    final houseScore = aspect.houses.isEmpty
        ? 50.0
        : houseScoreTotal / aspect.houses.length;

    // ── Component C: Vimshopak Bala (15%) ────────────────────────────
    var vimshopakTotal = 0.0;
    var vimshopakCount = 0;
    for (final planet in relevantPlanets) {
      final vb = ctx.vimshopak[planet];
      if (vb != null) {
        // VimshopakBala totalScore is 0–20
        vimshopakTotal += (vb.totalScore / 20.0) * 100.0;
        vimshopakCount++;
      }
    }
    final vimshopakScore = vimshopakCount > 0
        ? vimshopakTotal / vimshopakCount
        : 50.0;

    // ── Component D: Yoga / Dosha bonus/penalty (12%) ─────────────────
    final relevantYogas = _aspectYogaMap[aspect] ?? [];
    final relevantDoshas = _aspectDoshaMap[aspect] ?? [];

    var yogaBonus = 0.0;
    for (final yoga in ctx.yogaDosha.yogas) {
      if (yoga.isActive && relevantYogas.any(yoga.name.contains)) {
        yogaBonus += (yoga.strength / 100.0) * 12.0;
      }
    }
    var doshapenalty = 0.0;
    for (final dosha in ctx.yogaDosha.doshas) {
      if (dosha.isActive && relevantDoshas.any(dosha.name.contains)) {
        doshapenalty += (dosha.strength / 100.0) * 12.0;
      }
    }
    // Normalize yoga component to 0-100 range (50 = neutral)
    final yogaComponent = (50 + yogaBonus - doshapenalty).clamp(0.0, 100.0);

    // ── Component E: Dasha timing modifier (8%) ──────────────────────
    final dashaLords = _aspectDashaLords[aspect] ?? [];
    final mahaIsRelevant = dashaLords.contains(ctx.currentMahaDashaLord);
    final antarIsRelevant = dashaLords.contains(ctx.currentAntarDashaLord);

    // Check if current Dasha lord is benefic or malefic for this chart
    final dashaScore = (mahaIsRelevant && antarIsRelevant)
        ? 80.0
        : (mahaIsRelevant || antarIsRelevant)
        ? 65.0
        : 45.0;

    // ── Component F: Transit Overlay (NEW) (10%) ──────────────────────
    var transitScore = 50.0;
    if (ctx.currentTransit != null) {
      var scoreSum = 0.0;
      var count = 0;
      for (final planet in relevantPlanets) {
        final isFav = ctx.currentTransit!.gochara.isFavorable(planet);
        scoreSum += isFav ? 80.0 : 40.0;
        count++;
      }
      // Check Sade Sati (Saturn transit)
      if (ctx.currentTransit!.saturnTransit.isSadeSati) {
        final phase = ctx.currentTransit!.saturnTransit.sadeSatiPhase;
        if (phase == LocalSadeSatiPhase.peak) {
          scoreSum -= 15.0; // Peak sade sati is challenging
        } else {
          scoreSum -= 8.0;
        }
      }
      transitScore = count > 0 ? (scoreSum / count).clamp(0.0, 100.0) : 50.0;
    }

    // ── Component G: Divisional Chart (NEW) (10%) ───────────────────
    var divScore = 50.0;
    final vargaCode = switch (aspect) {
      LifeAspect.career => 'D-10',
      LifeAspect.wealth => 'D-2',
      LifeAspect.education => 'D-24',
      LifeAspect.romance => 'D-9',
      LifeAspect.children => 'D-7',
      LifeAspect.spirituality => 'D-20',
      _ => 'D-9',
    };
    final vargaChart = ctx.divisionalCharts[vargaCode];
    if (vargaChart != null) {
      var dignitySum = 0.0;
      var dignityCount = 0;
      for (final planet in relevantPlanets) {
        final planetName = planet.displayName;
        final signIdx = vargaChart.getPlanetSign(planetName);
        // Exaltation and debilitation signs
        final exaltInfo = AstroUtils.exaltations[planet];
        final debilInfo = AstroUtils.debilitations[planet];
        final ownSigns = AstroUtils.ownSigns[planet] ?? [];

        if (exaltInfo != null && exaltInfo.$1 == signIdx) {
          dignitySum += 90;
        } else if (debilInfo != null && debilInfo.$1 == signIdx) {
          // Check if Neecha Bhanga cancelled it
          final neechaBhangaResult = ctx.yogaDosha.yogas.firstWhere(
            (y) => y.name == 'Neecha Bhanga Raja Yoga',
            orElse: () => BhangaResult.inactive('Neecha Bhanga Raja Yoga'),
          );
          var hasNeecha = false;
          if (neechaBhangaResult.isActive) {
            for (final r in neechaBhangaResult.cancellationReasons) {
              if (r.contains(planet.displayName)) {
                hasNeecha = true;
                break;
              }
            }
          }
          dignitySum += hasNeecha ? 65 : 30; // Debilitated but mitigated
        } else if (ownSigns.contains(signIdx)) {
          dignitySum += 80;
        } else {
          dignitySum += 55; // Neutral / friendly sign average
        }
        dignityCount++;
      }
      divScore = dignityCount > 0 ? dignitySum / dignityCount : 50.0;
    }

    // ── Atmakaraka bonus ─────────────────────────────────────────────
    // If the Atmakaraka is in the relevant planet set, add 5 points
    final atmaBonus = relevantPlanets.contains(ctx.atmakaraka) ? 5.0 : 0.0;

    // ── Upachaya bonus for malefics ───────────────────────────────────
    // Natural malefics in Upachaya houses (3, 6, 10, 11) improve over time
    var upachayaBonus = 0.0;
    for (final planet in relevantPlanets) {
      if (_naturalMalefics.contains(planet)) {
        final planetInfo = chartData.baseChart.planets[planet];
        if (planetInfo != null && _upachayaHouses.contains(planetInfo.house)) {
          upachayaBonus += 3.0;
        }
      }
    }

    // ── Compound Relationship Modifier ─────────────────────────────
    var maitriModifier = 0.0;
    for (final planet in relevantPlanets) {
      final pInfo = chartData.baseChart.planets[planet];
      if (pInfo != null) {
        final houseLord = _getHouseLord(chartData, pInfo.house);
        if (houseLord != planet) {
          final relMap = ctx.compoundRelationships[planet];
          if (relMap != null) {
            final rel = relMap[houseLord];
            if (rel == CompoundRelationship.bestFriend) {
              maitriModifier += 5.0;
            } else if (rel == CompoundRelationship.friend) {
              maitriModifier += 2.5;
            } else if (rel == CompoundRelationship.enemy) {
              maitriModifier -= 4.0;
            }
          }
        }
      }
    }

    // ── Nakshatra Lord Condition Modifier ─────────────────────────────
    var nakshatraModifier = 0.0;
    if (aspect == LifeAspect.family ||
        aspect == LifeAspect.romance ||
        aspect == LifeAspect.health) {
      final moonLord = AstroUtils.vimshottariOrder[ctx.moonNakshatraIndex % 9];
      final vb = ctx.vimshopak[moonLord];
      final strength = vb != null ? (vb.totalScore / 20.0) * 100.0 : 50.0;
      if (strength < 40) {
        nakshatraModifier -=
            3.0; // Afflicted moon nakshatra lord hurts emotional stability
      }
    }

    // ── KP System Lord Refinement (NEW) ──────────────────────────────
    var kpModifier = 0.0;
    if (chartData.kpData.subLords.isNotEmpty) {
      final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
      final planetsList = chartData.baseChart.planets.keys.toList();
      final kpSubLords = <Planet, KPSubLord>{};
      for (
        var i = 0;
        i < planetsList.length && i < chartData.kpData.subLords.length;
        i++
      ) {
        kpSubLords[planetsList[i]] = chartData.kpData.subLords[i];
      }

      for (final planet in relevantPlanets) {
        final sub = kpSubLords[planet];
        if (sub != null) {
          // Check if Sub-Lord is functional benefic/malefic
          final subLordPlanet = _parsePlanetName(sub.subLord);
          if (subLordPlanet != null) {
            final func = _getFunctionalStatus(ascSign, subLordPlanet);
            if (func == FunctionalStatus.benefic) {
              kpModifier += 2.0; // Favorable sub-lord quality
            } else if (func == FunctionalStatus.malefic) {
              kpModifier -= 2.0; // Unfavorable sub-lord quality
            }
          }

          // Check if Star-Lord (Nakshatra Lord) is placed in a favorable house for this aspect
          final starLordPlanet = _parsePlanetName(sub.starLord);
          if (starLordPlanet != null) {
            final starInfo = chartData.baseChart.planets[starLordPlanet];
            if (starInfo != null && aspect.houses.contains(starInfo.house)) {
              kpModifier +=
                  3.0; // Nakshatra Lord placed in a key house for the aspect!
            }
          }
        }
      }
    }

    // ── Final weighted score ──────────────────────────────────────────
    final rawScore =
        baseScore * 0.25 +
        houseScore * 0.20 +
        vimshopakScore * 0.15 +
        yogaComponent * 0.12 +
        dashaScore * 0.08 +
        transitScore * 0.10 +
        divScore * 0.10 +
        atmaBonus +
        upachayaBonus +
        maitriModifier +
        nakshatraModifier +
        kpModifier;

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

    var status = planetInfo.dignity.english;
    if (status == 'Moola Trikona') status = 'Moolatrikona';
    final isRetrograde = planetInfo.isRetrograde;

    // A. Check Vargottama using native library APIs
    final vargottamaStatus = ctx.baseChart.getVargottamaStatus(planet);
    final isVargottama = vargottamaStatus != VargottamaStatus.none;

    if (isVargottama) {
      if (status == 'Debilitated') {
        status = 'Neecha-Vargottama';
      } else if (status != 'Exalted' && status != 'Moolatrikona') {
        status = 'Vargottama';
      }
    }

    // B. Check Deep Exaltation / Deep Debilitation using native library APIs
    final isDeepExalt = planetInfo.isDeepExalted(3.0);
    final isDeepDebil = planetInfo.isDeepDebilitated(3.0);
    if (isDeepExalt) {
      status = 'Deep Exaltation (Param Uchha)';
    } else if (isDeepDebil) {
      status = 'Deep Debilitation (Param Neecha)';
    }

    // C. Check Moolatrikona
    if (status != 'Exalted' &&
        status != 'Deep Exaltation (Param Uchha)' &&
        status != 'Vargottama' &&
        status != 'Neecha-Vargottama' &&
        planetInfo.dignity == PlanetaryDignity.moolaTrikona) {
      status = 'Moolatrikona';
    }

    // Check Neecha Bhanga Cancellation
    var hasNeecha = false;
    if (status == 'Debilitated' ||
        status == 'Deep Debilitation (Param Neecha)') {
      final neechaBhangaResult = ctx.yogaDosha.yogas.firstWhere(
        (y) => y.name == 'Neecha Bhanga Raja Yoga',
        orElse: () => BhangaResult.inactive('Neecha Bhanga Raja Yoga'),
      );
      if (neechaBhangaResult.isActive) {
        for (final r in neechaBhangaResult.cancellationReasons) {
          if (r.contains(planet.displayName)) {
            hasNeecha = true;
            status = status == 'Deep Debilitation (Param Neecha)'
                ? 'Deep Debilitation (Cancelled - Neecha Bhanga Raja Yoga Active)'
                : 'Debilitated (Cancelled - Neecha Bhanga Raja Yoga Active)';
            break;
          }
        }
      }
    }

    // E. Combustion Refined (Planet-specific limits)
    final sunInfo = chartData.baseChart.planets[Planet.sun];
    var isCombustRefined = planetInfo.isCombust;
    if (sunInfo != null &&
        planet != Planet.sun &&
        planet != Planet.meanNode &&
        planet != Planet.trueNode) {
      final diff = (longitude - sunInfo.longitude).abs();
      final distance = diff > 180.0 ? 360.0 - diff : diff;
      final limit = switch (planet) {
        Planet.moon => 12.0,
        Planet.mars => 17.0,
        Planet.mercury => isRetrograde ? 12.0 : 14.0,
        Planet.jupiter => 11.0,
        Planet.venus => isRetrograde ? 8.0 : 10.0,
        Planet.saturn => 15.0,
        _ => 15.0,
      };
      if (distance <= limit) {
        isCombustRefined = true;
      }
    }

    // F. Graha Yuddha (Planetary War loser)
    var isLoserInWar = false;
    final war = chartData.grahaYuddha;
    if (war != null) {
      final isParticipant = war.planet1 == planet || war.planet2 == planet;
      if (isParticipant) {
        final winnerStr = war.winnerId.toString().toLowerCase();
        final planetName = planet.toString().split('.').last.toLowerCase();
        final isWinner = winnerStr == planetName || war.winnerId == planet;
        if (!isWinner) {
          isLoserInWar = true;
          status = 'Defeated in Planetary War (Graha Yuddha)';
        }
      }
    }

    // G. Strength modification
    var finalStrength = vb != null
        ? (vb.totalScore / 20.0) * 100.0
        : ((ctx.shadbala[planet] ?? 300) / 600 * 100).clamp(0.0, 100.0);

    if (isVargottama) {
      finalStrength = (finalStrength + 8.0).clamp(0.0, 100.0);
    }
    if (isDeepExalt) {
      finalStrength = (finalStrength + 5.0).clamp(0.0, 100.0);
    }
    if (isDeepDebil) {
      finalStrength = (finalStrength - 5.0).clamp(0.0, 100.0);
    }
    if (isLoserInWar) {
      finalStrength = finalStrength * 0.5; // Defeat cuts strength by 50%
    }

    final ascSign = (chartData.baseChart.houses.ascendant / 30).floor() % 12;
    final functionalStatus = _getFunctionalStatus(ascSign, planet);

    // Upachaya rule: malefics in 3/6/10/11 are treated as benefic
    final isUpachaya =
        _naturalMalefics.contains(planet) && _upachayaHouses.contains(house);

    var isBenefic =
        isUpachaya ||
        hasNeecha ||
        _isBeneficForAspect(
          chartData,
          planet,
          aspect,
          sign,
          house,
          status,
          isCombust: isCombustRefined,
        );

    if (isLoserInWar || (isCombustRefined && !isRetrograde)) {
      isBenefic = false;
    }

    var position = '';
    if (isHouseLord && houseNumber != null) {
      position =
          '${_getOrdinal(houseNumber)} Lord ${planet.displayName} at $degreeStr $signName in ${_getOrdinal(house)} House';
    } else {
      position =
          '${planet.displayName} at $degreeStr $signName in ${_getOrdinal(house)} House';
    }
    if (isRetrograde) position += ' (Retrograde)';
    if (isCombustRefined) position += ' (Combust)';
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
      strength: finalStrength,
      isRetrograde: isRetrograde,
      isCombust: isCombustRefined,
      functionalStatus: functionalStatus,
      isUpachaya: isUpachaya,
    );

    return PlanetaryInfluence(
      planet: planet,
      position: position,
      status: status,
      strength: finalStrength,
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

    // ── Section 1b: Nakshatra Foundation ──────────────────────────────
    buffer.write('\n\n### Nakshatra Foundation\n');
    final moonLord = AstroUtils.vimshottariOrder[ctx.moonNakshatraIndex % 9];
    final moonLordVb = ctx.vimshopak[moonLord];
    final moonLordStrength = moonLordVb != null
        ? (moonLordVb.totalScore / 20.0) * 100.0
        : 50.0;
    final moonLordStatus =
        chartData.baseChart.planets[moonLord]?.dignity.english ?? 'Neutral';
    buffer.write(
      'Your emotional foundation is governed by the Moon placed in **${ctx.moonNakshatra}** Nakshatra (Pada ${ctx.moonNakshatraPada}). '
      'The Nakshatra lord is **${moonLord.displayName}**, which is currently placed in a **$moonLordStatus** state with a strength index of **${moonLordStrength.toStringAsFixed(0)}%**. ',
    );
    if (moonLordStrength >= 65) {
      buffer.write(
        'This strong Nakshatra lord placement gives your emotional core resilience, allowing you to navigate fluctuations with ease. ',
      );
    } else {
      buffer.write(
        'This delicate Nakshatra lord placement suggests that conscious emotional centering and mindfulness are highly beneficial. ',
      );
    }
    buffer.write('${_getNakshatraTraits(ctx.moonNakshatra, aspect)}\n\n');

    // ── Section 2: Bhava & Ashtakavarga Analysis ─────────────────────
    buffer.write('### Bhava (House) & Lordship Analysis\n');
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
        buffer.write(
          'delicate foundation that requires conscious strengthening. ',
        );
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
        var lordDignity = lordInfo.dignity.english;
        if (lordDignity == 'Moola Trikona') {
          lordDignity = 'Moolatrikona';
        }
        final isLordRetro = lordInfo.isRetrograde;
        final isLordCombust = lordInfo.isCombust;

        buffer.write(
          'Its lord, **${houseLord.displayName}**, is positioned in the **${_getOrdinal(lordHouse)} house** ($lordSignName). ',
        );

        if ([6, 8, 12].contains(lordHouse)) {
          buffer.write(
            'Because the house lord is placed in a Dusthana (difficult) house, it indicates that the benefits of the $house house may feel obstructed, delayed, or require spiritual transformation to manifest. ',
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
        } else if (lordDignity == 'Moolatrikona') {
          buffer.write(
            'The lord\'s Moolatrikona state grants it outstanding strength, natural alignment, and power to manifest positive results. ',
          );
        } else if (lordDignity == 'Debilitated') {
          // Check Neecha Bhanga
          final neechaBhangaResult = ctx.yogaDosha.yogas.firstWhere(
            (y) => y.name == 'Neecha Bhanga Raja Yoga',
            orElse: () => BhangaResult.inactive('Neecha Bhanga Raja Yoga'),
          );
          var hasNeecha = false;
          if (neechaBhangaResult.isActive) {
            for (final r in neechaBhangaResult.cancellationReasons) {
              if (r.contains(houseLord.displayName)) {
                hasNeecha = true;
                break;
              }
            }
          }
          if (hasNeecha) {
            buffer.write(
              'Although debilitated in Rashi, the active Neecha Bhanga cancellation mitigates this, converting weaknesses into eventual triumph. ',
            );
          } else {
            buffer.write(
              'The lord\'s Debilitated status indicates a lack of external power, suggesting that building inner resilience is essential. ',
            );
          }
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

    // ── Section 2b: Current Transit Snapshot (Gochara) ─────────────
    if (ctx.currentTransit != null) {
      buffer.write('### Current Transit Snapshot (Gochara)\n');
      final transit = ctx.currentTransit!;
      // Sade Sati
      if (transit.saturnTransit.isSadeSati) {
        final phase = transit.saturnTransit.sadeSatiPhase.name;
        buffer.write(
          '**Sade Sati Alert:** You are running the **$phase phase** of Sade Sati (Saturn\'s transit over natal Moon). '
          'This transit demands rigorous discipline, patience, and realistic expectations. ',
        );
        if (transit.saturnTransit.effects.isNotEmpty) {
          buffer.write('${transit.saturnTransit.effects.first} ');
        }
      } else {
        buffer.write(
          'Saturn is currently in House **${transit.saturnTransit.houseFromMoon}** from your natal Moon, ensuring a relatively stable pressure environment. ',
        );
      }

      // Jupiter Transit
      final jupHouse = transit.jupiterTransit.houseFromMoon;
      buffer.write(
        '**Jupiter Transit:** Jupiter is transiting your **${_getOrdinal(jupHouse)} house** from the Moon. ',
      );
      if (transit.jupiterTransit.isBenefic) {
        buffer.write(
          'This is highly favorable, casting a protective, expansive glance that brings opportunities and grace to your path. ',
        );
      } else {
        buffer.write(
          'This placement emphasizes internal growth, wisdom accumulation, and steady consolidation rather than outward expansion. ',
        );
      }

      // Rahu/Ketu transit
      final affectedNatal = transit.rahuKetuTransit.affectedNatalPlanets;
      if (affectedNatal.isNotEmpty) {
        buffer.write(
          '**Node Interventions:** Rahu/Ketu transits are actively touching your natal **${affectedNatal.join(', ')}**. '
          'This introduces sudden insights, shifts, or intense desires that require conscious moderation. ',
        );
      }

      // Favorable transits for aspect planets
      final transitFav = <String>[];
      final transitUnfav = <String>[];
      final relevantPlanetSet = {
        ...aspect.primaryPlanets,
        for (final h in aspect.houses) _getHouseLord(chartData, h),
      };
      for (final planet in relevantPlanetSet) {
        if (transit.gochara.isFavorable(planet)) {
          transitFav.add(planet.displayName);
        } else {
          transitUnfav.add(planet.displayName);
        }
      }
      if (transitFav.isNotEmpty) {
        buffer.write(
          '\nCurrently, transit positions are highly supportive for **${transitFav.join(', ')}**, magnifying your capability to take progressive action. ',
        );
      }
      if (transitUnfav.isNotEmpty) {
        buffer.write(
          'However, transits present minor friction for **${transitUnfav.join(', ')}**, indicating that patience is advised before making major decisions.',
        );
      }
      buffer.write('\n\n');
    }

    // ── Section 3: Key Astrological Influences ──────────────────────────
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
        .where((y) => y.isActive && relevantYogaNames.any(y.name.contains))
        .toList();
    final activeDoshas = ctx.yogaDosha.doshas
        .where((d) => d.isActive && relevantDoshaNames.any(d.name.contains))
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
              'Partial cancellation factors: ${dosha.cancellationReasons.join(', ')}. ',
            );
          }
          buffer.write('\n');
        }
        buffer.write('\n');
      }
    }

    // ── Section 4b: Divisional Chart Verification (Vargas) ───────────
    final vargaCode = switch (aspect) {
      LifeAspect.career => 'D-10',
      LifeAspect.wealth => 'D-2',
      LifeAspect.education => 'D-24',
      LifeAspect.romance => 'D-9',
      LifeAspect.children => 'D-7',
      LifeAspect.spirituality => 'D-20',
      _ => 'D-9',
    };
    final vargaChart = ctx.divisionalCharts[vargaCode];
    if (vargaChart != null) {
      buffer.write('### Divisional Chart Verification ($vargaCode)\n');
      buffer.write(
        'For highly professional depth, we cross-verify the Rashi placements against the **$vargaCode (${vargaChart.name}) divisional chart**, which specifically governs **${vargaChart.description}**. ',
      );

      for (final planet in aspect.primaryPlanets) {
        final rashiPlanetInfo = chartData.baseChart.planets[planet];
        var rashiDignity = rashiPlanetInfo?.dignity.english ?? 'Neutral';
        if (rashiDignity == 'Moola Trikona') rashiDignity = 'Moolatrikona';
        final signIdx = vargaChart.getPlanetSign(planet.displayName);
        final signName = AstroUtils.getSignName(signIdx);

        // Exaltation, debilitation, own sign
        final exaltInfo = AstroUtils.exaltations[planet];
        final debilInfo = AstroUtils.debilitations[planet];
        final ownSigns = AstroUtils.ownSigns[planet] ?? [];

        var vargaDignity = 'Neutral';
        if (exaltInfo != null && exaltInfo.$1 == signIdx) {
          vargaDignity = 'Exalted';
        } else if (debilInfo != null && debilInfo.$1 == signIdx) {
          vargaDignity = 'Debilitated';
        } else if (ownSigns.contains(signIdx)) {
          vargaDignity = 'Own Sign';
        }

        buffer.write(
          '\n- **${planet.displayName}** is placed in **$signName** in the $vargaCode chart ($vargaDignity). ',
        );
        if (rashiDignity == 'Debilitated' && vargaDignity == 'Exalted') {
          buffer.write(
            '**Neecha Bhanga / Neecha-Vargottama:** While structurally weak in Rashi, its exalted state in the divisional chart represents extraordinary *hidden strength* that emerges with time and persistence. ',
          );
        } else if (rashiDignity == 'Exalted' && vargaDignity == 'Debilitated') {
          buffer.write(
            '**Hidden Weakness:** While externally promising, its debilitation in the divisional chart suggests internal friction or challenges that require deeper introspection. ',
          );
        } else if (vargaDignity == 'Exalted' || vargaDignity == 'Own Sign') {
          buffer.write(
            'This highly dignified placement confirms that the potential of this planet is completely integrated and supported at a subconscious level. ',
          );
        }
      }
      buffer.write('\n\n');
    }

    // ── Section 4c: Jaimini Indicators ───────────────────────────────
    buffer.write('### Jaimini Professional-Grade Indicators\n');
    final jaiminiService = JaiminiAnalysisService();
    final jaiminiAnalysis = jaiminiService.getJaiminiAnalysis(chartData);

    // Karakamsa
    final karakamsaSign = jaiminiAnalysis.karakamsa.karakamsaSign.name;
    buffer.write(
      'By Jaimini principles, your **Atmakaraka (${jaiminiAnalysis.atmakaraka.displayName})** is placed in **$karakamsaSign** in the Navamsa chart, establishing **$karakamsaSign** as your **Karakamsha Lagna**. ',
    );
    if (aspect == LifeAspect.career) {
      buffer.write(
        'The Karakamsha sign indicates that your soul\'s true calling and professional growth are highly aligned with the qualities of $karakamsaSign, prompting you to seek purpose and leadership. ',
      );
      buffer.write(
        'Your **Arudha Lagna (AL)** falls in **${jaiminiAnalysis.arudhaLagna.sign.name}** (House ${jaiminiAnalysis.arudhaLagna.houseFromLagna} from Lagna), representing your public standing, status, and how the external world perceives your accomplishments. ',
      );
    } else if (aspect == LifeAspect.romance) {
      buffer.write(
        'Your **Upapada Lagna (UL)** (spouse indicator) falls in **${jaiminiAnalysis.upapada.sign.name}** (House ${jaiminiAnalysis.upapada.houseFromLagna} from Lagna). This reveals key information about your life partner\'s family background, values, and the general quality of your marital bond. ',
      );
    }

    // Argala
    final houseArgalas = <String>[];
    for (final house in aspect.houses) {
      final list = jaiminiAnalysis.argalas[house] ?? [];
      final active = list
          .where((a) => !a.isObstructed && a.type != ArgalaType.virodha)
          .toList();
      if (active.isNotEmpty) {
        for (final arg in active) {
          final planetsStr = arg.causingPlanets
              .map((p) => p.displayName)
              .join(', ');
          houseArgalas.add(
            'benefic intervention from House ${arg.sourceHouse} via $planetsStr on your ${house}th house',
          );
        }
      }
    }
    if (houseArgalas.isNotEmpty) {
      buffer.write(
        'Furthermore, we detect **Argala (planetary interventions)**: ${houseArgalas.join('; ')}. This acts as secondary support or catalyst, helping you overcome obstacles in this aspect of life.',
      );
    } else {
      buffer.write(
        'No major unobstructed Argalas are active, meaning your progress in this area is primarily driven by direct planetary placements and personal effort.',
      );
    }
    buffer.write('\n\n');

    // ── Section 5: Enhanced Vimshottari Dasha Timing ─────────────────
    if (ctx.currentMahaDashaLord.isNotEmpty) {
      buffer.write('### Current Dasha Period & Timing\n');
      final dashaLords = _aspectDashaLords[aspect] ?? [];
      final mahaActive = dashaLords.contains(ctx.currentMahaDashaLord);
      final antarActive = dashaLords.contains(ctx.currentAntarDashaLord);
      final pratyanActive = dashaLords.contains(ctx.currentPratyantarDashaLord);

      final mahaRange = ctx.mahaStart != null && ctx.mahaEnd != null
          ? '(${ctx.mahaStart!.year} to ${ctx.mahaEnd!.year})'
          : '';
      final antarRange = ctx.antarStart != null && ctx.antarEnd != null
          ? '(${ctx.antarStart!.day}/${ctx.antarStart!.month}/${ctx.antarStart!.year} to ${ctx.antarEnd!.day}/${ctx.antarEnd!.month}/${ctx.antarEnd!.year})'
          : '';
      final pratyanRange = ctx.pratyanStart != null && ctx.pratyanEnd != null
          ? '(${ctx.pratyanStart!.day}/${ctx.pratyanStart!.month}/${ctx.pratyanStart!.year} to ${ctx.pratyanEnd!.day}/${ctx.pratyanEnd!.month}/${ctx.pratyanEnd!.year})'
          : '';

      buffer.write(
        'You are currently running the **${ctx.currentMahaDashaLord} Mahadasha** $mahaRange '
        '→ **${ctx.currentAntarDashaLord} Antardasha** $antarRange ',
      );
      if (ctx.currentPratyantarDashaLord.isNotEmpty) {
        buffer.write(
          '→ **${ctx.currentPratyantarDashaLord} Pratyantardasha** $pratyanRange. ',
        );
      } else {
        buffer.write('. ');
      }

      if (mahaActive && antarActive && pratyanActive) {
        buffer.write(
          '**Triple Activation Alert:** Your Mahadasha, Antardasha, and Pratyantardasha lords are all key significators for **${aspect.name}**! '
          'This is a highly rare and intensely activated window. Major events, breakthroughs, and rapid developments are highly likely now. Take decisive action.',
        );
      } else if (mahaActive && antarActive) {
        buffer.write(
          'Both your Mahadasha and Antardasha lords are primary significators for **${aspect.name}** — this is a **highly activated period** for this life area. '
          'Events, decisions, and results related to ${aspect.name.toLowerCase()} are prominent and highly supported now. ',
        );
      } else if (mahaActive || antarActive) {
        buffer.write(
          'Your Dasha cycle provides **secondary activation** for **${aspect.name}**. '
          'While progress will be steady, it is a great time to establish solid foundations and make deliberate moves.',
        );
      } else {
        buffer.write(
          'The current Dasha period is not a primary activator for **${aspect.name}** at this time. '
          'This indicates a relatively quiet, reflective period for these matters, allowing you to focus energy on other activated spheres of your life.',
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

    // 3. Gochara (Transit) specific advice
    if (ctx.currentTransit != null) {
      if (ctx.currentTransit!.saturnTransit.isSadeSati) {
        buffer.write(
          '\n\n**Transit Guidance (Sade Sati):** During this active Sade Sati period, prioritize slow, methodical planning and health routines. Avoid rash decisions and impulsive financial commitments. ',
        );
      }
      buffer.write(
        '\n\n**Transit Action Window:** Leverage currently supportive planetary transits by initiating important dialogues and long-term projects while Gochara forces are aligned. ',
      );
    }

    // 4. Nakshatra lord remedies
    final moonLord = AstroUtils.vimshottariOrder[ctx.moonNakshatraIndex % 9];
    buffer.write(
      '\n\n**Nakshatra Lord Remedy (${moonLord.displayName}):** To strengthen your birth Moon Nakshatra foundation (${ctx.moonNakshatra}), '
      'consider performing remedies for its ruler: ${_getRemedyForPlanet(moonLord)} ',
    );

    // 5. Weak/Malefic planetary remedies
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

    // 6. Active dosha remedies
    final relevantDoshaNames = _aspectDoshaMap[aspect] ?? [];
    final activeDoshas = ctx.yogaDosha.doshas
        .where((d) => d.isActive && relevantDoshaNames.any(d.name.contains))
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

  List<pa.PlanetaryAspect> _getSignSignificantAspects(
    CompleteChartData chartData,
    LifeAspect aspect,
    List<pa.PlanetaryAspect> allAspects,
  ) {
    final relevantPlanets = <Planet>{
      ...aspect.primaryPlanets,
      for (final h in aspect.houses) _getHouseLord(chartData, h),
    };

    final seen = <String>{};
    return allAspects
        .where((a) {
          if (!relevantPlanets.contains(a.aspectedPlanet)) return false;
          if (a.orb > 8) return false;
          final key = '${a.aspectingPlanet}-${a.aspectedPlanet}-${a.type}';
          if (seen.contains(key)) return false;
          seen.add(key);
          return true;
        })
        .take(4)
        .toList();
  }

  List<pa.PlanetaryAspect> _getSignificantAspects(
    CompleteChartData chartData,
    LifeAspect aspect,
    List<pa.PlanetaryAspect> allAspects,
  ) {
    return _getSignSignificantAspects(chartData, aspect, allAspects);
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
      buffer.write(
        'As the Lord of the ${houseNumber}th house ($significance), ',
      );
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
    if (status.contains('Debilitated (Cancelled') ||
        status.contains('Deep Debilitation (Cancelled')) {
      buffer.write(
        ' in a Debilitated state that is beautifully cancelled via Neecha Bhanga Raja Yoga, transforming its weak potential into grand success.',
      );
    } else {
      switch (status) {
        case 'Exalted':
          buffer.write(
            ' in an Exalted state, providing outstanding strength and highly auspicious energy for these matters.',
          );
        case 'Deep Exaltation (Param Uchha)':
          buffer.write(
            ' in a state of Deep Exaltation (Param Uchha), representing the absolute zenith of its strength and delivering highly auspicious, peak manifestation power.',
          );
        case 'Moolatrikona':
          buffer.write(
            ' in its Moolatrikona sign, granting exceptionally high strength, natural alignment, and very auspicious energy.',
          );
        case 'Vargottama':
          buffer.write(
            ' in a Vargottama state (placed in the same sign in both Rashi and Navamsa charts), confirming highly integrated, stable, and auspicious flow of energy.',
          );
        case 'Neecha-Vargottama':
          buffer.write(
            ' in a Neecha-Vargottama state (debilitated in both Rashi and Navamsa), which cancels standard debilitation distress and represents a powerful hidden resilience that yields success through persistence.',
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
        case 'Deep Debilitation (Param Neecha)':
          buffer.write(
            ' in a state of Deep Debilitation (Param Neecha), marking its lowest point of strength and presenting significant structural vulnerability or intense lessons that demand awareness.',
          );
        case 'Defeated in Planetary War (Graha Yuddha)':
          buffer.write(
            ' defeated in a Planetary War (Graha Yuddha) by being within 1° of its competitor. This severely drains its energy, indicating deep inner conflicts or critical setbacks in these matters.',
          );
        default:
          buffer.write(' in a neutral state.');
      }
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

    buffer.write(
      ' Vimshopak/Shadbala strength is ${strength.toStringAsFixed(0)}% (',
    );
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
        if ([
          Planet.sun,
          Planet.moon,
          Planet.mars,
          Planet.jupiter,
        ].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 1: // Taurus
        if ([
          Planet.sun,
          Planet.mercury,
          Planet.venus,
          Planet.saturn,
        ].contains(planet)) {
          return FunctionalStatus.benefic;
        }
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
        if ([
          Planet.moon,
          Planet.mercury,
          Planet.venus,
          Planet.saturn,
        ].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 5: // Virgo
        if ([Planet.mercury, Planet.venus].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([
          Planet.sun,
          Planet.moon,
          Planet.mars,
          Planet.jupiter,
        ].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 6: // Libra
        if ([
          Planet.moon,
          Planet.mercury,
          Planet.venus,
          Planet.saturn,
        ].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([Planet.sun, Planet.mars, Planet.jupiter].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 7: // Scorpio
        if ([
          Planet.sun,
          Planet.moon,
          Planet.mars,
          Planet.jupiter,
        ].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 8: // Sagittarius
        if ([Planet.sun, Planet.mars, Planet.jupiter].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([
          Planet.moon,
          Planet.mercury,
          Planet.venus,
          Planet.saturn,
        ].contains(planet)) {
          return FunctionalStatus.malefic;
        }
      case 9: // Capricorn
        if ([Planet.mercury, Planet.venus, Planet.saturn].contains(planet)) {
          return FunctionalStatus.benefic;
        }
        if ([
          Planet.sun,
          Planet.moon,
          Planet.mars,
          Planet.jupiter,
        ].contains(planet)) {
          return FunctionalStatus.malefic;
        }
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
        if ([
          Planet.sun,
          Planet.mercury,
          Planet.venus,
          Planet.saturn,
        ].contains(planet)) {
          return FunctionalStatus.malefic;
        }
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

    if (status == 'Exalted' ||
        status == 'Deep Exaltation (Param Uchha)' ||
        status == 'Moolatrikona' ||
        status == 'Vargottama' ||
        status == 'Neecha-Vargottama' ||
        status == 'Own Sign') {
      return functional != FunctionalStatus.malefic ||
          ![6, 8, 12].contains(house);
    }

    if (status == 'Debilitated' || status == 'Deep Debilitation (Param Neecha)')
      return false;

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
    return remedies[planet] ??
        'Consult a Vedic astrologer for specific remedies.';
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

  String _getNakshatraTraits(String nakshatra, LifeAspect aspect) {
    switch (aspect) {
      case LifeAspect.career:
        return 'Under the influence of $nakshatra Nakshatra, your professional life is anchored by instinctual drive and focus. You approach tasks with natural dedication and aim for long-term mastery rather than immediate returns.';
      case LifeAspect.wealth:
        return 'With Moon in $nakshatra Nakshatra, your financial instincts are deeply tied to emotional stability. You thrive by securing stable assets and establishing steady, low-risk income channels.';
      case LifeAspect.family:
        return 'The foundation of $nakshatra Nakshatra infuses your domestic sphere with nurturing, protective instincts. Family harmony is your primary emotional anchor, and you seek to create a secure sanctuary.';
      case LifeAspect.romance:
        return '$nakshatra Nakshatra shapes your relational desires with deep devotion and loyalty. You seek strong emotional synchronization and a spiritual bond with your partner.';
      case LifeAspect.health:
        return 'In the realm of vitality, $nakshatra Nakshatra governs your psychosomatic balance. Emotional peace is highly critical to your physical well-being, as stress quickly translates into physical exhaustion.';
      case LifeAspect.children:
        return 'Regarding family legacy and creative expressions, $nakshatra Nakshatra promotes a nurturing, guide-like approach. You instill strong traditional values and moral guidance in younger generations.';
      case LifeAspect.education:
        return 'Your pursuit of knowledge under $nakshatra Nakshatra is characterized by intuitive comprehension and memory. You excel in subjects that offer deep philosophical or structural meaning.';
      case LifeAspect.spirituality:
        return 'Under $nakshatra Nakshatra, your soul has a strong affinity for higher wisdom, meditation, and self-inquiry. You seek liberation and have a natural capability to detach from material desires.';
    }
  }

  Planet? _parsePlanetName(String name) {
    final cleanName = name.toLowerCase().replaceAll(' ', '');
    for (final p in Planet.traditionalPlanets) {
      if (p.displayName.toLowerCase().replaceAll(' ', '') == cleanName) {
        return p;
      }
    }
    if (cleanName.contains('rahu') ||
        cleanName.contains('node') ||
        cleanName.contains('mean')) {
      return Planet.meanNode;
    }
    if (cleanName.contains('ketu')) {
      return Planet.meanNode;
    }
    return null;
  }
}

// ══════════════════════════════════════════════════════════════════
// PREDICTION CONTEXT — bundles all pre-computed analytics
// ══════════════════════════════════════════════════════════════════

class _PredictionContext {
  _PredictionContext({
    required this.baseChart,
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
    required this.currentTransit,
    required this.divisionalCharts,
    required this.compoundRelationships,
    required this.currentPratyantarDashaLord,
    this.mahaStart,
    this.mahaEnd,
    this.antarStart,
    this.antarEnd,
    this.pratyanStart,
    this.pratyanEnd,
    required this.moonNakshatra,
    required this.moonNakshatraPada,
    required this.moonNakshatraIndex,
  });

  final VedicChart baseChart;
  final Map<Planet, double> shadbala;
  final Map<int, BhavaStrength> bhavaBala;
  final Map<int, int> houseAvBindus;
  final Map<Planet, VimshopakBala> vimshopak;
  final Map<Planet, ({double ishtaphala, double kashtaphala})> planetFruits;
  final YogaDoshaAnalysisResult yogaDosha;
  final String currentMahaDashaLord;
  final String currentAntarDashaLord;
  final List<pa.PlanetaryAspect>
  aspects; // ignore: library_private_types_in_public_api
  final Planet atmakaraka;

  // New fields
  final TransitChart? currentTransit;
  final Map<String, DivisionalChartData> divisionalCharts;
  final Map<Planet, Map<Planet, CompoundRelationship>> compoundRelationships;
  final String currentPratyantarDashaLord;
  final DateTime? mahaStart;
  final DateTime? mahaEnd;
  final DateTime? antarStart;
  final DateTime? antarEnd;
  final DateTime? pratyanStart;
  final DateTime? pratyanEnd;
  final String moonNakshatra;
  final int moonNakshatraPada;
  final int moonNakshatraIndex;
}
