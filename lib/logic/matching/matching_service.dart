import 'package:flutter/material.dart';
import 'package:jyotish/jyotish.dart';

import '../../data/models.dart';
import '../yoga_dosha_analyzer.dart';
import 'matching_models.dart';

/// Extensive Kundali Matching Service
class MatchingService {
  /// Analyze compatibility extensively
  static MatchingReport analyzeCompatibility(
    CompleteChartData groom,
    CompleteChartData bride,
  ) {
    // 1. Basic Positions
    final groomMoon = groom.baseChart.planets[Planet.moon]!;
    final brideMoon = bride.baseChart.planets[Planet.moon]!;

    final gRashi = (groomMoon.position.longitude / 30).floor();
    final bRashi = (brideMoon.position.longitude / 30).floor();
    final gNak = groomMoon.position.nakshatraIndex;
    final bNak = brideMoon.position.nakshatraIndex;

    // 2. Kuta Matching
    final varna = _calculateVarna(gRashi, bRashi);
    final vashya = _calculateVashya(gRashi, bRashi);
    final tara = _calculateTara(gNak, bNak);
    final yoni = _calculateYoni(gNak, bNak);
    final maitri = _calculateMaitri(gRashi, bRashi);
    final gana = _calculateGana(gNak, bNak);
    final bhakoot = _calculateBhakoot(gRashi, bRashi);
    final nadi = _calculateNadi(gNak, bNak);

    final allKootas = [varna, vashya, tara, yoni, maitri, gana, bhakoot, nadi];
    final totalScore = allKootas.fold(0.0, (sum, k) => sum + k.score);

    // 3. Manglik Matching
    final manglikMatch = _checkManglikCompatibility(groom, bride);

    // 4. Extra Checks (Mahendra, Vedha, etc.)
    final extraChecks = _calculateExtraChecks(gNak, bNak);

    // 5. Advanced Analysis (Dosha Samyam, Dasha Sandhi)
    final doshaSamyam = _calculateDoshaSamyam(groom, bride);
    final dashaSandhi = _checkDashaSandhi(groom, bride);

    // 6. Overall Conclusion
    String conclusion;
    Color color;

    final criticalDosha =
        !manglikMatch.isMatch ||
        !_areExtrasGood(extraChecks) ||
        !doshaSamyam.isGood; // Adding Dosha Samyam concern

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
        color = Colors.yellow[700]!; // Darker yellow for visibility
      } else {
        conclusion = "Average Score with Critical Dosha";
        color = Colors.orange;
      }
    } else {
      conclusion = "Not Recommended (Adham)";
      color = Colors.red;
    }

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

  // --- Koota Calculations ---

  static KootaResult _calculateVarna(int gRashi, int bRashi) {
    // 0=Brahmin (Water), 1=Kshatriya (Fire), 2=Vaishya (Earth), 3=Shudra (Air)
    // Brahmin: 3,7,11
    // Kshatriya: 0,4,8
    // Vaishya: 1,5,9
    // Shudra: 2,6,10

    int getVarna(int r) {
      if ([3, 7, 11].contains(r)) return 0;
      if ([0, 4, 8].contains(r)) return 1;
      if ([1, 5, 9].contains(r)) return 2;
      return 3;
    }

    final gV = getVarna(gRashi);
    final bV = getVarna(bRashi);

    final varnaNames = ['Brahmin', 'Kshatriya', 'Vaishya', 'Shudra'];
    final gName = varnaNames[gV];
    final bName = varnaNames[bV];

    // Rule: Groom grade <= Bride grade (Where 0 is highest) is OK
    // Or Groom index <= Bride index
    // Wait standard rule: Groom should be higher or same.
    // 0 (Brahmin) > 1 > 2 > 3.
    // So Groom(0) Bride(1) is Good. Groom(1) Bride(0) is Bad (0 points)
    // Indexes: gV <= bV -> OK.

    bool isMatch = gV <= bV;
    double score = isMatch ? 1.0 : 0.0;

    return KootaResult(
      name: 'Varna',
      score: score,
      maxScore: 1.0,
      description: isMatch
          ? 'Compatible work nature'
          : 'Incompatible work nature',
      detailedReason:
          'Groom is $gName, Bride is $bName. ${isMatch ? "Groom's spiritual grade is higher/equal." : "Bride has higher spiritual grade."}',
      color: isMatch ? Colors.green : Colors.red,
    );
  }

  static KootaResult _calculateVashya(int gRashi, int bRashi) {
    // 5 groups: Chatushpada(4-leg), Manava(Human), Jalchar(Water), Vanchar(Wild), Keeta(Insect)
    // Aries: 0 (Chatushpada)
    // Taurus: 0
    // Gemini: 1 (Manava)
    // Cancer: 2 (Jalchar)
    // Leo: 3 (Vanchar) - roughly check mapping standard
    // Virgo: 1
    // Libra: 1
    // Scorpio: 4 (Keeta)
    // Sag: 0 (First half human, but generally Manava-ish or Vanchar? Need standard table)
    // Cap: 2 (Jalchar/Chatushpada mix) -> usually Jalchar for Vashya? Or use direct friendship table.

    // Using standard lookup point table instead of groups for accuracy
    // 2.0, 1.0, 0.5, 0.0
    // Simplified logic using the existing map logic for now, tailored for description

    // Using mapping from ChartComparison logic but expanded explanations
    final Map<int, List<int>> controls = {
      0: [0, 4, 7],
      1: [1, 3, 6],
      2: [2, 5],
      3: [3, 7],
      4: [0, 4, 8],
      5: [1, 2, 5],
      6: [3, 6, 11],
      7: [3, 7],
      8: [4, 8, 11],
      9: [1, 5, 9, 10],
      10: [9, 10],
      11: [6, 8, 11],
    };

    double score = 0.0;
    String reason = "No natural control match.";

    if (gRashi == bRashi) {
      score = 2.0;
      reason = "Both are same sign. Mutual understanding.";
    } else if (controls[gRashi]?.contains(bRashi) ?? false) {
      score = 2.0;
      reason = "Groom's sign controls Bride's sign. Good harmony.";
    } else if (controls[bRashi]?.contains(gRashi) ?? false) {
      score =
          0.5; // Exceptions can make it 1 or 0.5 usually called "Eka Vashya"
      reason = "Bride's sign controls Groom's sign. Partial match.";
    } else {
      // Check mutual enemy groups (e.g. Lion vs Human)
      score = 0.0;
      reason = "Signs are not amenable to each other.";
    }

    Color color = Colors.red;
    if (score == 2.0) {
      color = Colors.green;
    } else if (score > 0) {
      color = Colors.orange;
    }

    return KootaResult(
      name: 'Vashya',
      score: score,
      maxScore: 2.0,
      description: 'Mutual attraction capability',
      detailedReason: reason,
      color: color,
    );
  }

  static KootaResult _calculateTara(int gNak, int bNak) {
    int distGB = (bNak - gNak + 27) % 27; // Groom to Bride
    int distBG = (gNak - bNak + 27) % 27; // Bride to Groom

    int remGB = distGB % 9;
    int remBG = distBG % 9;

    // Bad: 2(Vipat), 4(Pratyak), 6(Naidhana) - Indices 0-based?
    // User usually knows: 1=Janma, 2=Sampat, 3=Vipat, 4=Kshema, 5=Pratyak, 6=Sadhana, 7=Naidhana, 8=Mitra, 9=AtiMitra
    // If we iterate 1-based:
    // Bad in division by 9: 3, 5, 7.
    // Our logic uses 0-based distance. so 0->1st(Janma).
    // dist=0 => Janma(1). dist=2 => Vipat(3).
    // distIndices: 2, 4, 6 are BAD. (Representing 3rd, 5th, 7th stars)

    bool badGB = [2, 4, 6].contains(remGB);
    bool badBG = [2, 4, 6].contains(remBG);

    double score = 0;
    String reason = "";

    if (!badGB && !badBG) {
      score = 3.0;
      reason = "Both Tara scores are favorable.";
    } else if (badGB && badBG) {
      score = 0.0;
      reason = "Both Tara scores are unfavorable (Vipat/Pratyak/Naidhana).";
    } else {
      score = 1.5;
      reason = "One direction is favorable, one is unfavorable.";
    }

    return KootaResult(
      name: 'Tara',
      score: score,
      maxScore: 3.0,
      description: 'Destiny compatibility',
      detailedReason: reason,
      color: score == 3
          ? Colors.green
          : (score > 0 ? Colors.orange : Colors.red),
    );
  }

  static KootaResult _calculateYoni(int gNak, int bNak) {
    // 0-based nakshatra indices
    // 14 Yonis
    // Ashwa(Horse): 0(Ashwini), 23(Shatabhisha)
    // Gaja(Elephant): 1(Bharani), 26(Revati)
    // Mesha(Sheep): 2(Krittika), 7(Pushya)
    // Sarpa(Snake): 3(Rohini), 4(Mrigashira)
    // Swana(Dog): 5(Ardra), 18(Mula)
    // Marjala(Cat): 6(Punarvasu), 8(Ashlesha)
    // Mushaka(Rat): 9(Magha), 10(PurvaPhal)
    // Gau(Cow): 11(UttaraPhal), 25(UttaraBhadra)
    // Mahisha(Buffalo): 12(Hasta), 14(Swati)
    // Vyaghra(Tiger): 13(Chitra), 15(Vishakha)
    // Mriga(Deer): 16(Anuradha), 17(Jyeshtha)
    // Vanara(Monkey): 19(PurvaAsh), 21(Shravana)
    // Nakula(Mongoose): 20(UttaraAsh), 22(Abhijit handled?) - standard 27 usually excludes Abhijit for Yoni pairs or maps it. Assuming 27 system:
    // Wait, Abhijit is usually skipped in 27 scheme.
    // 20(UttaraAsh), 21(Shravana-Vanara)?
    // Let's use standard table.

    // Simplified lookups for animals
    final animals = [
      'Horse',
      'Elephant',
      'Sheep',
      'Snake',
      'Snake',
      'Dog',
      'Cat',
      'Sheep',
      'Cat',
      'Rat',
      'Rat',
      'Cow',
      'Buffalo',
      'Tiger',
      'Buffalo',
      'Tiger',
      'Deer',
      'Deer',
      'Dog',
      'Monkey',
      'Mongoose',
      'Monkey',
      'Lion',
      'Lion',
      'Horse',
      'Cow',
      'Elephant',
    ];
    // Note: indices 22-26 need verifying for 27 star system.
    // 0:Ashwini.. 26:Revati.
    // 20: U.Ash (Mongoose), 21: Shravana (Monkey), 22: Dhanishta (Lion), 23: Shatabhisha (Horse),
    // 24: P.Bhad (Lion), 25: U.Bhad (Cow), 26: Revati (Elephant)

    final gAnimal = animals[gNak % 27];
    final bAnimal = animals[bNak % 27];

    // Enemy Pairs
    final enemies = {
      'Horse': 'Buffalo',
      'Buffalo': 'Horse',
      'Elephant': 'Lion',
      'Lion': 'Elephant',
      'Sheep': 'Monkey',
      'Monkey': 'Sheep',
      'Snake': 'Mongoose',
      'Mongoose': 'Snake',
      'Dog': 'Deer',
      'Deer': 'Dog',
      'Cat': 'Rat',
      'Rat': 'Cat',
      'Cow': 'Tiger',
      'Tiger': 'Cow',
    };

    double score;
    String reason;

    if (gAnimal == bAnimal) {
      score = 4.0;
      reason = "Same animal ($gAnimal). Excellent compatibility.";
    } else if (enemies[gAnimal] == bAnimal) {
      score = 0.0;
      reason = "$gAnimal and $bAnimal are bitter enemies.";
    } else {
      // Neutral / Friendly
      score = 2.0; // Simplified average. Usually table has 3, 2, 1.
      reason = "$gAnimal and $bAnimal are neutral/friendly.";
    }

    return KootaResult(
      name: 'Yoni',
      score: score,
      maxScore: 4.0,
      description: 'Physical/Sexual compatibility',
      detailedReason: reason,
      color: score >= 3
          ? Colors.green
          : (score >= 2 ? Colors.orange : Colors.red),
    );
  }

  static KootaResult _calculateMaitri(int gRashi, int bRashi) {
    // Determine Lords
    final lords = [
      'Mars',
      'Venus',
      'Mercury',
      'Moon',
      'Sun',
      'Mercury',
      'Venus',
      'Mars',
      'Jupiter',
      'Saturn',
      'Saturn',
      'Jupiter',
    ];
    final gLord = lords[gRashi];
    final bLord = lords[bRashi];

    // Friendship Table (Natural)
    // Sun: Fr(Mon,Mar,Jup), Nu(Mer), En(Ven,Sat)
    // Mon: Fr(Sun,Mer), Nu(Mar,Jup,Ven,Sat), En(-)
    // Mar: Fr(Sun,Mon,Jup), Nu(Ven,Sat), En(Mer)
    // Mer: Fr(Sun,Ven), Nu(Mar,Jup,Sat), En(Mon)
    // Jup: Fr(Sun,Mon,Mar), Nu(Sat), En(Mer,Ven)
    // Ven: Fr(Mer,Sat), Nu(Mar,Jup), En(Sun,Mon)
    // Sat: Fr(Mer,Ven), Nu(Jup), En(Sun,Mon,Mar)

    // Reuse existing logic from PlanetaryMaitriService logic implicitly or custom map
    // Let's implement the standard matrix points
    // 5=Friend-Friend, 4=Friend-Neutral, 3=Neutral-Neutral, 1=Friend-Enemy, 0.5=Neutral-Enemy, 0=Enemy-Enemy

    // Quick Helper for relationships
    String getRel(String from, String to) {
      if (from == to) return 'F';
      switch (from) {
        case 'Sun':
          return ['Moon', 'Mars', 'Jupiter'].contains(to)
              ? 'F'
              : (['Venus', 'Saturn'].contains(to) ? 'E' : 'N');
        case 'Moon':
          return ['Sun', 'Mercury'].contains(to)
              ? 'F'
              : 'N'; // Moon has no enemies
        case 'Mars':
          return ['Sun', 'Moon', 'Jupiter'].contains(to)
              ? 'F'
              : (['Mercury'].contains(to) ? 'E' : 'N');
        case 'Mercury':
          return ['Sun', 'Venus'].contains(to)
              ? 'F'
              : (['Moon'].contains(to) ? 'E' : 'N');
        case 'Jupiter':
          return ['Sun', 'Moon', 'Mars'].contains(to)
              ? 'F'
              : (['Venus', 'Mercury'].contains(to) ? 'E' : 'N');
        case 'Venus':
          return ['Mercury', 'Saturn'].contains(to)
              ? 'F'
              : (['Sun', 'Moon'].contains(to) ? 'E' : 'N');
        case 'Saturn':
          return ['Mercury', 'Venus'].contains(to)
              ? 'F'
              : (['Sun', 'Moon', 'Mars'].contains(to) ? 'E' : 'N');
      }
      return 'N';
    }

    String r1 = getRel(gLord, bLord);
    String r2 = getRel(bLord, gLord);

    double score = 0;
    if (r1 == 'F' && r2 == 'F') {
      score = 5.0;
    } else if ((r1 == 'F' && r2 == 'N') || (r1 == 'N' && r2 == 'F')) {
      score = 4.0;
    } else if (r1 == 'N' && r2 == 'N') {
      score = 3.0;
    } else if ((r1 == 'F' && r2 == 'E') || (r1 == 'E' && r2 == 'F')) {
      score = 1.0; // Some say 0.5 or 1
    } else if ((r1 == 'N' && r2 == 'E') || (r1 == 'E' && r2 == 'N')) {
      score = 0.5;
    } else {
      score = 0.0; // Enemy-Enemy
    }

    return KootaResult(
      name: 'Graha Maitri',
      score: score,
      maxScore: 5.0,
      description: 'Psychological compatibility',
      detailedReason:
          "Groom's lord ($gLord) and Bride's lord ($bLord) relationship yields $score points.",
      color: score >= 4
          ? Colors.green
          : (score >= 3 ? Colors.yellow[700]! : Colors.red),
    );
  }

  static KootaResult _calculateGana(int gNak, int bNak) {
    // 0=Deva, 1=Manushya, 2=Rakshasa
    int getGana(int n) {
      final deva = [0, 4, 6, 7, 12, 14, 20, 21, 26];
      final manushya = [1, 3, 5, 10, 11, 13, 15, 17, 24];
      if (deva.contains(n)) return 0;
      if (manushya.contains(n)) return 1;
      return 2;
    }

    final gG = getGana(gNak);
    final bG = getGana(bNak);
    final names = ['Deva', 'Manushya', 'Rakshasa'];

    double score = 0;
    if (gG == bG) {
      score = 6.0;
    } else if ((gG == 0 && bG == 1) || (gG == 1 && bG == 0)) {
      score = 6.0; // Deva-Manushya is good secondary
    } else if (gG == 2 && bG == 0) {
      score = 1.0; // Rakshasa-Deva usually low
    } else if (gG == 2 && bG == 1) {
      score = 0.0; // Rakshasa-Manushya bad
    } else if (bG == 2 && gG != 2) {
      score =
          0.0; // If bride is Rakshasa and groom not, considered 0 often unless cancelled.
    }

    // Refine standard scoring
    // Same = 6
    // Deva - Manushya = 6 or 5
    // Deva - Rakshasa = 1
    // Manushya - Deva = 5 or 6
    // Manushya - Rakshasa = 0
    // Rakshasa - Deva = 0 (Preeti conflict)
    // Rakshasa - Manushya = 0

    // Strict logic implemented roughly above, normalizing

    Color color = Colors.green;
    if (score == 0) {
      color = Colors.red;
    } else if (score < 5) {
      color = Colors.orange;
    }

    return KootaResult(
      name: 'Gana',
      score: score,
      maxScore: 6.0,
      description: 'Family compatibility',
      detailedReason: "Groom is ${names[gG]}, Bride is ${names[bG]}.",
      color: color,
    );
  }

  static KootaResult _calculateBhakoot(int gRashi, int bRashi) {
    int dist = (bRashi - gRashi + 12) % 12; // Groom to Bride
    // 0=Same(1-1), 1=2nd, etc. (0-based) similar to count-1
    // 1-based distance:
    int d = dist + 1;

    // Pairs:
    // 1-1 (d=1): Good (7)
    // 1-7 (d=7): Good (7)
    // 3-11 (d=3 or d=11): Good (7)
    // 4-10 (d=4 or d=10): Good (7)

    // Bad:
    // 2-12 (d=2 or d=12): Bad (0)
    // 5-9 (d=5 or d=9): Bad (0)
    // 6-8 (d=6 or d=8): Bad (0)

    double score = 0;
    String dosha = "";

    if (d == 1) {
      score = 7;
    } else if (d == 7) {
      score = 7;
    } else if (d == 3 || d == 11) {
      score = 7;
    } else if (d == 4 || d == 10) {
      score = 7;
    } else if (d == 2 || d == 12) {
      dosha = "Dwi-Dwadasha (2-12)";
    } else if (d == 5 || d == 9) {
      dosha = "Nava-Pancham (5-9)";
    } else if (d == 6 || d == 8) {
      dosha = "Shadashtaka (6-8)";
    }

    // Exception Checks (Lords Friends)
    // If lords are same or friends, Bhakoot dosha is cancelled
    bool cancelled = false;
    if (score == 0) {
      final maitri = _calculateMaitri(gRashi, bRashi);
      if (maitri.score >= 4.0) {
        // Friendly or better
        score = 7;
        cancelled = true;
      }
    }

    return KootaResult(
      name: 'Bhakoot',
      score: score,
      maxScore: 7.0,
      description: 'Prosperity and Family welfare',
      detailedReason: score == 7
          ? (cancelled
                ? "Dosha ($dosha) cancelled due to planetary friendship."
                : "Favorable sign placement ($d-relative).")
          : "Inauspicious placement: $dosha. Causes instability.",
      color: score == 7 ? Colors.green : Colors.red,
    );
  }

  static KootaResult _calculateNadi(int gNak, int bNak) {
    // 0=Adi(Vata), 1=Madhya(Pitta), 2=Antya(Kapha)
    int getNadi(int n) {
      // 0, 8, 17, 26, etc pattern
      // Nakshatras 1..27 mapped to 1,2,3,3,2,1,1,2,3...
      // Indices 0..26
      // Nadi Sequence: Adi, Madhya, Antya, Antya, Madhya, Adi...
      final pattern = [0, 1, 2, 2, 1, 0];
      return pattern[n % 6];
    }

    final gN = getNadi(gNak);
    final bN = getNadi(bNak);
    final names = ['Adi (Vata)', 'Madhya (Pitta)', 'Antya (Kapha)'];

    double score = 8.0;
    if (gN == bN) {
      score = 0.0;
    }

    return KootaResult(
      name: 'Nadi',
      score: score,
      maxScore: 8.0,
      description: 'Genetic health compatibility',
      detailedReason: score == 0
          ? "Same Nadi (${names[gN]}) detected. Risk to progeny/health."
          : "Different Nadis (${names[gN]} - ${names[bN]}). Healthy match.",
      color: score == 0 ? Colors.red : Colors.green,
    );
  }

  // --- Manglik & Extras ---

  static ManglikMatchResult _checkManglikCompatibility(
    CompleteChartData g,
    CompleteChartData b,
  ) {
    // Reuse logic from YogaDoshaAnalyzer? Or re-implement
    // Assuming YogaDoshaAnalyzer is available and has _hasMangalDosha exposed or we implement similar
    // We already have YogaDoshaAnalyzer from import
    // Note: YogaDoshaAnalyzer.analyze returns result. It has private helpers logic but exposed as 'doshas'

    final gRes = YogaDoshaAnalyzer.analyze(g);
    final bRes = YogaDoshaAnalyzer.analyze(b);

    // Check if Mangal Dosha present in results
    // Check if Mangal Dosha present and ACTIVE
    bool gManglik = gRes.doshas.any(
      (d) => d.name.contains('Mangal') && d.isActive,
    );
    bool bManglik = bRes.doshas.any(
      (d) => d.name.contains('Mangal') && d.isActive,
    );

    bool match = false;
    String desc = "";

    if (gManglik && bManglik) {
      match = true;
      desc = "Both are Manglik. Dosha cancels out.";
    } else if (!gManglik && !bManglik) {
      match = true;
      desc = "Neither is Manglik. Good compatibility.";
    } else {
      // Mismatch Handling - Check Cross-Cancellation
      // If one is Manglik, check if other has Saturn/Rahu/Ketu in the same house
      CompleteChartData manglikChart = gManglik ? g : b;
      CompleteChartData otherChart = gManglik ? b : g;
      String manglikPerson = gManglik ? "Groom" : "Bride";
      String otherPerson = gManglik ? "Bride" : "Groom";

      // Where is Mars for the Manglik person?
      // We need to find which house Mars is in (1, 2, 4, 7, 8, 12)
      int marsHouse = _getPlanetHouse(manglikChart, 'Mars');

      // Does other person have strong malefics in that house?
      List<String> cancellers = ['Saturn', 'Rahu', 'Ketu'];
      bool cancelled = false;
      String cancellerName = '';

      for (var planet in cancellers) {
        if (_getPlanetHouse(otherChart, planet) == marsHouse) {
          cancelled = true;
          cancellerName = planet;
          break;
        }
      }

      if (cancelled) {
        match = true;
        desc =
            "$manglikPerson is Manglik (Mars in House $marsHouse), but $otherPerson's $cancellerName in the same house cancels the Dosha.";
      } else {
        match = false;
        desc =
            "$manglikPerson is Manglik, $otherPerson is not. Mismatch detected.";
      }
    }

    return ManglikMatchResult(
      isMatch: match,
      description: desc,
      maleManglik: gManglik,
      femaleManglik: bManglik,
    );
  }

  // --- Advanced Analysis ---

  static DoshaSamyamResult _calculateDoshaSamyam(
    CompleteChartData groom,
    CompleteChartData bride,
  ) {
    // Malefics: Mars, Saturn, Rahu, Ketu, Sun
    // Houses: 1, 2, 4, 7, 8, 12
    // Points: 1 per planet per house. Some systems weight them (e.g. 7th/8th heavier).
    // Simple 1-point system for now.

    const malefics = ['Mars', 'Saturn', 'Rahu', 'Ketu', 'Sun'];
    const sensitiveHouses = [1, 2, 4, 7, 8, 12];

    double calculatePoints(CompleteChartData chart) {
      double points = 0;
      for (var planet in malefics) {
        int house = _getPlanetHouse(chart, planet);
        if (sensitiveHouses.contains(house)) {
          points += 1.0;
        }
      }
      return points;
    }

    final gPoints = calculatePoints(groom);
    final bPoints = calculatePoints(bride);

    // Rule: Points should be similar.
    // If diff > 2, it's a concern.
    double diff = (gPoints - bPoints).abs();
    bool isGood = diff <= 2;

    return DoshaSamyamResult(
      maleScore: gPoints,
      femaleScore: bPoints,
      isGood: isGood,
      description: isGood
          ? "Malefic influence is balanced (Diff: $diff)."
          : "Significant difference in malefic influence ($diff).",
    );
  }

  static DashaSandhiResult _checkDashaSandhi(
    CompleteChartData groom,
    CompleteChartData bride,
  ) {
    // Requires Dasha information.
    // Assuming birth data allows calculating current dasha.
    // For now, if Dasha data isn't readily available in 'CompleteChartData' structure for *Current Time*,
    // we might need to compute it.
    // NOTE: 'CompleteChartData' has 'vimshottari' which is full list.
    // We need 'current date' to find active dasha.

    // Placeholder Logic until detailed Dasha date-checking is exposed or current date passed
    // We'll use a safe default: "No Sandhi detected" unless we can check.

    // If we assume we can check logic:
    // 1. Find Groom's current Mahadasha Lord
    // 2. Find Bride's current Mahadasha Lord
    // 3. Are they 2nd/7th lords (Marakas) of their respective charts?
    // Since we lack 'Current Date' context in 'analyzeCompatibility' args implicitly (unless added),
    // we will return a neutral result or ask to add 'currentDate'.
    // Let's assume 'now' for check.

    return const DashaSandhiResult(
      hasSandhi: false,
      maleCurrentDasha: "Unknown",
      femaleCurrentDasha: "Unknown",
      description: "Dasha Sandhi check requires current date context.",
    );
  }
  // --- Helpers for Detailed Checks ---

  static int _getAscendantSign(CompleteChartData chart) {
    if (chart.baseChart.houses.cusps.isNotEmpty) {
      return (chart.baseChart.houses.cusps[0] / 30).floor();
    }
    return 0;
  }

  static int _getPlanetSign(CompleteChartData chart, String planetName) {
    for (final entry in chart.baseChart.planets.entries) {
      if (entry.key.toString().split('.').last.toLowerCase() ==
          planetName.toLowerCase()) {
        return (entry.value.longitude / 30).floor();
      }
    }
    return 0;
  }

  static int _getPlanetHouse(CompleteChartData chart, String planetName) {
    final sign = _getPlanetSign(chart, planetName);
    final lagna = _getAscendantSign(chart);
    return (sign - lagna + 12) % 12 + 1;
  }

  static List<ExtraMatchingCheck> _calculateExtraChecks(int gNak, int bNak) {
    List<ExtraMatchingCheck> checks = [];

    // 1. Mahendra: Prosperity/Children
    // Count from Bride to Groom (Index 1-based logic, so bNak to gNak?)
    // Standard: Count from Bride's star to Groom's star.
    // Note: Nakshatra indices are 0-based (0..26)
    int distBG = (gNak - bNak + 27) % 27 + 1; // Distance Bride -> Groom
    bool mahendra = [4, 7, 10, 13, 16, 19, 22, 25].contains(distBG);
    checks.add(
      ExtraMatchingCheck(
        name: 'Mahendra',
        isFavorable: mahendra,
        description: mahendra
            ? 'Promotes well-being & longevity'
            : 'Neutral/Unfavorable',
      ),
    );

    // 2. Stree Deergha: Distance
    // Good if Groom's star is at least 13 away from Bride's
    // Some say > 7 is OK. > 13 is Good.
    bool streeDeergha = distBG > 13;
    checks.add(
      ExtraMatchingCheck(
        name: 'Stree Deergha',
        isFavorable: streeDeergha,
        description: streeDeergha
            ? 'Good distance ($distBG). Ensures prosperity.'
            : 'Distance ($distBG) is short. Minor concern.',
      ),
    );

    // 3. Rajju: Rope/Body Part (Critical for longevity of couple)
    // Groups:
    // Pad (Foot): Ashwini, Aslesha, Magha, Jyeshta, Moola, Revati
    // Uru (Thigh): Bharani, Pushya, PurvaPhal, Anuradha, PurvaAsh, UttaraBhadra
    // Nabhi (Navel/Waist): Krittika, Punarvasu, UttaraPhal, Vishakha, UttaraAsh, PurvaBhadra
    // Kanta (Neck): Rohini, Arudra, Hasta, Swati, Shravana, Satabhisha
    // Siro (Head): Mrigasira, Chitra, Dhanishta

    // Logic: Stars must NOT belong to the same Rajju.
    // 1-based mapping for better readability of groups
    // Ashwini(1)..Revati(27)
    // 0..26
    int getRajjuGroup(int n) {
      // 0, 8, 9, 17, 18, 26 => Pad (0)
      if ([0, 8, 9, 17, 18, 26].contains(n)) return 0;
      // 1, 7, 10, 16, 19, 25 => Uru (1)
      if ([1, 7, 10, 16, 19, 25].contains(n)) return 1;
      // 2, 6, 11, 15, 20, 24 => Nabhi (2)
      if ([2, 6, 11, 15, 20, 24].contains(n)) return 2;
      // 3, 5, 12, 14, 21, 23 => Kanta (3)
      if ([3, 5, 12, 14, 21, 23].contains(n)) return 3;
      // 4, 13, 22 => Siro (4) - wait, missing 2 stars?
      // Siro usually has Mrigasira(5), Chitra(14), Dhanishta(23) in 1-based
      // Indices: 4, 13, 22. Correct.
      if ([4, 13, 22].contains(n)) return 4;
      return -1;
    }

    int gRajju = getRajjuGroup(gNak);
    int bRajju = getRajjuGroup(bNak);
    bool rajjuMatch = gRajju != bRajju;

    // Specific danger descriptions
    List<String> rajjuDescs = [
      'Wandering',
      'Loss of property',
      'Loss of offspring',
      'Death (Critical)',
      'Husband danger',
    ];
    String badRajju = (gRajju != -1 && !rajjuMatch) ? rajjuDescs[gRajju] : '';

    checks.add(
      ExtraMatchingCheck(
        name: 'Rajju Dosha',
        isFavorable: rajjuMatch,
        description: rajjuMatch
            ? 'Different Rajju. Good.'
            : 'Same Rajju ($badRajju). Avoid match.',
      ),
    );

    // 4. Vedha: Obstruction (Juxtaposition)
    // Forbidden Pairs:
    // Ashwini-Jyeshta, Bharani-Anuradha, Krittika-Visakha, Rohini-Swati, Arudra-Sravana
    // Punarvasu-Uttarashada, Pushya-Purvashada, Aslesha-Moola, Magha-Revati, P.Phalguni-U.Bhadra
    // U.Phalguni-P.Bhadra, Hasta-Satabhisha, Mrigasira-Chitra-Dhanishta (Trinity)
    // Let's implement pairs.
    bool vedha = false;
    // Map of Mutually obstructionist pairs
    // Using 0-based indices
    final pairs = [
      {0, 17}, // Ashwini(0) - Jyeshta(17)
      {1, 16}, // Bharani(1) - Anuradha(16)
      {2, 15}, // Krittika(2) - Visakha(15)
      {3, 14}, // Rohini(3) - Swati(14)
      {5, 21}, // Arudra(5) - Sravana(21)
      {6, 20}, // Punarvasu(6) - U.Ash(20)
      {7, 19}, // Pushya(7) - P.Ash(19)
      {8, 18}, // Aslesha(8) - Moola(18)
      {9, 26}, // Magha(9) - Revati(26)
      {10, 25}, // P.Phal(10) - U.Bhad(25)
      {11, 24}, // U.Phal(11) - P.Bhad(24)
      {12, 23}, // Hasta(12) - Satabhisha(23)
      {4, 13},
      {4, 22},
      {13, 22}, // Mrigasira(4), Chitra(13), Dhanishta(22) - Mutual
    ];

    for (var p in pairs) {
      if (p.contains(gNak) && p.contains(bNak)) {
        vedha = true; // Found obstruction
        break;
      }
    }

    checks.add(
      ExtraMatchingCheck(
        name: 'Vedha (Obstruction)',
        isFavorable: !vedha,
        description: vedha
            ? 'Mutual obstruction detected (Forbidden pair).'
            : 'No obstruction.',
      ),
    );

    return checks;
  }

  static bool _areExtrasGood(List<ExtraMatchingCheck> extras) {
    // Critical Checks: Rajju and Vedha must be favorable
    bool rajjuGood = extras
        .firstWhere((e) => e.name == 'Rajju Dosha')
        .isFavorable;
    bool vedhaGood = extras
        .firstWhere((e) => e.name.contains('Vedha'))
        .isFavorable;

    return rajjuGood && vedhaGood;
  }
}
