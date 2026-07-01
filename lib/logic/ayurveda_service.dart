import 'package:jyotish/jyotish.dart';
import '../data/models/chart_data.dart';

class DoshaScores {
  final double vata;
  final double pitta;
  final double kapha;

  const DoshaScores({
    required this.vata,
    required this.pitta,
    required this.kapha,
  });
}

class AyurvedicProfile {
  final DoshaScores scores;
  final double vataPercentage;
  final double pittaPercentage;
  final double kaphaPercentage;
  final String dominantDosha;
  final String description;
  final List<String> dietaryRecommendations;
  final List<String> lifestyleRecommendations;
  final List<String> recommendedHerbs;
  final List<String> avoidedFoods;

  const AyurvedicProfile({
    required this.scores,
    required this.vataPercentage,
    required this.pittaPercentage,
    required this.kaphaPercentage,
    required this.dominantDosha,
    required this.description,
    required this.dietaryRecommendations,
    required this.lifestyleRecommendations,
    required this.recommendedHerbs,
    required this.avoidedFoods,
  });
}

class AyurvedaService {
  AyurvedicProfile calculateAyurvedicProfile(CompleteChartData chartData) {
    final chart = chartData.baseChart;

    double vata = 0;
    double pitta = 0;
    double kapha = 0;

    // Helper to get sign index (0-11)
    int getSignIndex(double longitude) => (longitude / 30).floor() % 12;

    // Element-based points:
    // Fire (Aries, Leo, Sagittarius) -> Pitta
    // Earth (Taurus, Virgo, Capricorn) -> Kapha (with Virgo & Capricorn having Vata influences)
    // Air (Gemini, Libra, Aquarius) -> Vata
    // Water (Cancer, Scorpio, Pisces) -> Kapha
    void addElementPoints(int signIndex, double weight) {
      switch (signIndex) {
        case 0: // Aries (Fire)
        case 4: // Leo (Fire)
        case 8: // Sagittarius (Fire)
          pitta += weight;
          break;
        case 1: // Taurus (Earth)
          kapha += weight;
          break;
        case 5: // Virgo (Earth + Vata influence)
          kapha += weight * 0.6;
          vata += weight * 0.4;
          break;
        case 9: // Capricorn (Earth + Vata influence)
          kapha += weight * 0.6;
          vata += weight * 0.4;
          break;
        case 2: // Gemini (Air)
        case 6: // Libra (Air)
        case 10: // Aquarius (Air)
          vata += weight;
          break;
        case 3: // Cancer (Water)
        case 7: // Scorpio (Water)
        case 11: // Pisces (Water)
          kapha += weight;
          break;
      }
    }

    // 1. Lagna (Ascendant) - represents physical body/frame (weight = 4)
    final lagnaSign = getSignIndex(chart.houses.ascendant);
    addElementPoints(lagnaSign, 4.0);

    // 2. Moon - mind, body fluids, Kapha constitution (weight = 3)
    final moon = chart.planets[Planet.moon];
    if (moon != null) {
      final moonSign = getSignIndex(moon.longitude);
      addElementPoints(moonSign, 3.0);
      kapha += 1.5; // Natural Kapha
    }

    // 3. Sun - vital energy, digestion, Agni (weight = 3)
    final sun = chart.planets[Planet.sun];
    if (sun != null) {
      final sunSign = getSignIndex(sun.longitude);
      addElementPoints(sunSign, 3.0);
      pitta += 1.5; // Natural Pitta
    }

    // 4. Other planets (weight = 1.0 each)
    for (final entry in chart.planets.entries) {
      final planet = entry.key;
      final info = entry.value;

      if (planet == Planet.sun || planet == Planet.moon) continue;

      final signIndex = getSignIndex(info.longitude);
      addElementPoints(signIndex, 1.0);

      // Natural elemental/dosha weights of the planets
      switch (planet) {
        case Planet.mars:
          pitta += 1.0;
          break;
        case Planet.mercury:
          // Mercury is tridoshic, but dry/airy (Vata) by default
          vata += 0.6;
          pitta += 0.2;
          kapha += 0.2;
          break;
        case Planet.jupiter:
          kapha += 1.0;
          break;
        case Planet.venus:
          kapha += 0.7;
          vata += 0.3;
          break;
        case Planet.saturn:
          vata += 1.0;
          break;
        default:
          break;
      }
    }

    // 5. Rahu & Ketu (weight = 0.5 each for elements, plus natural dosha values)
    final rahuSign = getSignIndex(chart.rahu.longitude);
    addElementPoints(rahuSign, 0.5);
    vata += 0.75; // Rahu behaves like Saturn (Vata)

    final ketuSign = (chart.ketu.longitude / 30).floor() % 12;
    addElementPoints(ketuSign, 0.5);
    pitta += 0.75; // Ketu behaves like Mars (Pitta)

    final total = vata + pitta + kapha;
    if (total == 0) {
      return const AyurvedicProfile(
        scores: DoshaScores(vata: 1.0, pitta: 1.0, kapha: 1.0),
        vataPercentage: 33.3,
        pittaPercentage: 33.3,
        kaphaPercentage: 33.3,
        dominantDosha: 'Tridoshic',
        description: 'Perfect balance of all three doshas (Sama).',
        dietaryRecommendations: [],
        lifestyleRecommendations: [],
        recommendedHerbs: [],
        avoidedFoods: [],
      );
    }

    final vataPct = (vata / total) * 100;
    final pittaPct = (pitta / total) * 100;
    final kaphaPct = (kapha / total) * 100;

    String dominant;
    String description;
    List<String> dietary;
    List<String> lifestyle;
    List<String> herbs;
    List<String> avoided;

    // Check for Tridoshic and Dual constitutions
    final diffVP = (vataPct - pittaPct).abs();
    final diffPK = (pittaPct - kaphaPct).abs();
    final diffKV = (kaphaPct - vataPct).abs();

    if (diffVP < 5 && diffPK < 5 && diffKV < 5) {
      dominant = 'Tridoshic (Sama)';
      description = 'All three doshas—Vata, Pitta, and Kapha—are in near-equal proportion. This is a rare and highly balanced constitution, indicating robust health, resilience, and adaptability. Maintaining this balance requires a moderate, seasonal lifestyle.';
      dietary = [
        'Eat a fresh, diverse diet containing all six tastes (sweet, sour, salty, bitter, pungent, astringent) in moderation.',
        'Adjust your diet according to seasonal changes (cooling foods in summer, warming in winter).',
        'Favor whole foods, organic grains, fresh vegetables, and light proteins.',
        'Drink warm or room-temperature water; avoid ice-cold beverages.',
      ];
      lifestyle = [
        'Establish a consistent, moderate routine for sleep, exercise, and work.',
        'Practice a variety of physical activities (mild cardio, strength, yoga).',
        'Engage in regular meditation or breathing exercises (Pranayama) to maintain mental clarity.',
        'Perform light body oiling (Abhyanga) seasonally.',
      ];
      herbs = ['Triphala (for digestive balance)', 'Amalaki (for overall rejuvenation)', 'Tulsi (for immunity)'];
      avoided = [
        'Avoid extreme eating habits, such as overeating or fasting excessively.',
        'Limit highly processed, chemically preserved, or stale foods.',
        'Avoid excessive consumption of any single taste (e.g., too much spicy or too much sweet).',
      ];
    } else {
      final sorted = [
        MapEntry('Vata', vataPct),
        MapEntry('Pitta', pittaPct),
        MapEntry('Kapha', kaphaPct),
      ]..sort((a, b) => b.value.compareTo(a.value));

      final first = sorted[0].key;
      final second = sorted[1].key;

      if (sorted[0].value - sorted[1].value < 8.0) {
        // Dual-dosha constitution
        dominant = '$first-$second';
        if (dominant == 'Vata-Pitta' || dominant == 'Pitta-Vata') {
          dominant = 'Vata-Pitta';
          description = 'A combination of the Air/Ether (Vata) and Fire (Pitta) elements. You possess the creativity, quick intellect, and enthusiasm of Vata combined with the focus, drive, and digestion of Pitta. You may fluctuate between feeling chilled/light and hot/irritable, requiring grounding and cooling practices.';
          dietary = [
            'Favor warm, moist, grounding foods that are cooling in thermal nature (e.g., sweet fruits, cooked rice, oats, mung dhal).',
            'Incorporate sweet, bitter, and astringent tastes.',
            'Maintain regular meal times to soothe Vata while satisfying Pitta\'s strong appetite.',
            'Use cooling spices like fennel, coriander, cardamom, and coconut oil.',
          ];
          lifestyle = [
            'Maintain a regular but relaxed routine to keep Vata in check without stressing Pitta.',
            'Engage in grounding, non-competitive exercises (hatha yoga, walking in nature, swimming).',
            'Massage the body with coconut oil in summer (cooling) and sesame oil in winter (grounding).',
            'Set aside time for daily meditation and deep relaxation to soothe the nervous system.',
          ];
          herbs = ['Shatavari (cooling and nourishing)', 'Ashwagandha (grounding and strengthening)', 'Fennel seed tea'];
          avoided = [
            'Avoid highly spicy, dry, fried, and carbonated foods.',
            'Limit caffeine, alcohol, and tobacco, which aggravate both Vata and Pitta.',
            'Avoid eating when rushed, angry, or anxious.',
          ];
        } else if (dominant == 'Pitta-Kapha' || dominant == 'Kapha-Pitta') {
          dominant = 'Pitta-Kapha';
          description = 'A combination of the Fire (Pitta) and Water/Earth (Kapha) elements. You have the leadership, clarity, and energy of Pitta coupled with the physical strength, stability, and calm demeanor of Kapha. You generally have a strong constitution but can accumulate heat or congestion if out of balance.';
          dietary = [
            'Favor light, warm, and moderately spiced foods (e.g., cooked vegetables, quinoa, lentils).',
            'Emphasize bitter, astringent, and mildly pungent tastes.',
            'Include plenty of green leafy vegetables and low-sugar fruits (apples, berries).',
            'Use small amounts of ghee or olive oil; avoid heavy, greasy oils.',
          ];
          lifestyle = [
            'Engage in moderately intense, structured physical activity daily (jogging, active yoga, cycling).',
            'Avoid daytime napping, especially after meals.',
            'Practice dry massage (Udvartana) or use light oils like sunflower oil for massage.',
            'Keep your living space clean, dry, and well-ventilated.',
          ];
          herbs = ['Guduchi (clearing and immunity-boosting)', 'Turmeric (anti-inflammatory)', 'Triphala'];
          avoided = [
            'Avoid extremely oily, heavy, fried, and salty foods.',
            'Limit heavy dairy products (cheese, ice cream) and refined sugars.',
            'Avoid excessive chili, fermented foods, and vinegar.',
          ];
        } else {
          dominant = 'Kapha-Vata';
          description = 'A combination of the Water/Earth (Kapha) and Air/Ether (Vata) elements. This is a contrast of qualities (heavy/stable Kapha vs. light/mobile Vata). You are stable and patient, yet possess a quick, creative mind. Your primary challenge is keeping warm, as both Vata and Kapha are cold doshas.';
          dietary = [
            'Favor warm, cooked, light, and easily digestible meals (e.g., hot soups, warm spiced grains).',
            'Emphasize warm spices like ginger, black pepper, cinnamon, and cumin to stimulate digestion.',
            'Include sweet, pungent, and slightly sour tastes.',
            'Drink warm herbal teas throughout the day.',
          ];
          lifestyle = [
            'Keep yourself warm, especially in cold, damp, or windy weather.',
            'Engage in active, warming exercises (Vinyasa yoga, brisk walking, dance).',
            'Perform warm oil massage (Abhyanga) using warm sesame or mustard oil.',
            'Maintain a regular schedule while introducing healthy stimulation and variety.',
          ];
          herbs = ['Ginger (warming and digestive)', 'Tulsi (respiratory and immune support)', 'Pippali'];
          avoided = [
            'Avoid cold, frozen, raw, and dry foods (like salads, crackers, iced drinks).',
            'Limit heavy, sticky, sweet foods and excessive dairy.',
            'Avoid exposure to cold drafts and damp environments.',
          ];
        }
      } else {
        // Single dominant dosha
        dominant = first;
        if (dominant == 'Vata') {
          description = 'A constitution dominated by the Air and Ether elements. You are likely creative, enthusiastic, energetic, and thin-framed, with a quick mind. When out of balance, you may experience anxiety, dry skin, constipation, fatigue, insomnia, and irregular digestion. You need warmth, moisture, and a solid routine.';
          dietary = [
            'Eat warm, cooked, moist, and grounding meals (soups, stews, casseroles, well-cooked grains).',
            'Incorporate healthy fats like ghee, sesame oil, and olive oil.',
            'Emphasize sweet, sour, and salty tastes to ground Vata.',
            'Use warming spices like ginger, cumin, cardamom, cinnamon, and asafoetida (hing).',
          ];
          lifestyle = [
            'Establish a regular daily routine for sleeping, waking, eating, and exercising.',
            'Perform a daily self-massage (Abhyanga) using warm sesame oil.',
            'Choose grounding, gentle exercises (restorative yoga, walking, Qi Gong).',
            'Stay warm and protect yourself from cold, dry, windy weather.',
          ];
          herbs = ['Ashwagandha (strengthens nervous system)', 'Haritaki (aids elimination)', 'Ginger (stokes digestive fire)'];
          avoided = [
            'Avoid raw vegetables, cold salads, dry crackers, and ice-cold drinks.',
            'Limit bitter, pungent, and astringent tastes.',
            'Avoid fasting, skipping meals, and over-exercising.',
          ];
        } else if (dominant == 'Pitta') {
          description = 'A constitution dominated by the Fire and Water elements. You are likely focused, ambitious, intelligent, and medium-framed, with a strong digestion and body temperature. When out of balance, you may experience irritability, anger, inflammation, skin rashes, acid reflux, and loose stools. You need cooling, calming, and moderation.';
          dietary = [
            'Eat cooling, refreshing, and moderately substantial foods (fresh sweet fruits, cucumbers, leafy greens, coconut).',
            'Emphasize sweet, bitter, and astringent tastes to pacify Pitta.',
            'Use cooling spices like coriander, fennel, mint, and cilantro.',
            'Drink plenty of room-temperature water, coconut water, or cooling herbal teas.',
          ];
          lifestyle = [
            'Avoid heat and direct exposure to the midday sun.',
            'Engage in cooling, non-competitive physical activities (swimming, walking in moonlight, gentle yoga).',
            'Keep your mind calm; practice mindfulness, patience, and work-life balance.',
            'Use cooling oils like coconut or sunflower oil for self-massage.',
          ];
          herbs = ['Amalaki (cools and detoxifies)', 'Shatavari (nourishing and cooling)', 'Neem (clears excess heat)'];
          avoided = [
            'Avoid hot, spicy, pungent, sour, and salty foods (chilis, garlic, onions, vinegar, fermented foods).',
            'Limit fried, greasy, oily, and highly processed foods.',
            'Avoid overworking, skipping meals, and excessive competitiveness.',
          ];
        } else {
          description = 'A constitution dominated by the Earth and Water elements. You are likely calm, loving, strong-framed, loyal, and steady, with excellent stamina. When out of balance, you may experience sluggishness, weight gain, congestion, lethargy, attachment, and slow digestion. You need warmth, dryness, activity, and stimulation.';
          dietary = [
            'Eat light, warm, dry, and spicy foods (quinoa, millets, beans, steamed vegetables).',
            'Emphasize pungent, bitter, and astringent tastes to balance Kapha.',
            'Incorporate plenty of heating spices like black pepper, ginger, cayenne, mustard seeds, and turmeric.',
            'Drink hot water or warm ginger tea throughout the day.',
          ];
          lifestyle = [
            'Engage in vigorous daily exercise (running, hiking, dynamic yoga, strength training).',
            'Wake up early (before 6:00 AM) and avoid sleeping during the day.',
            'Seek variety, new challenges, and mental stimulation in your life.',
            'Perform dry skin brushing (Garshana) or massage with light warming oils like mustard oil.',
          ];
          herbs = ['Trikatu (ginger, black pepper, long pepper)', 'Bibhitaki (cleanses Kapha)', 'Tulsi (warms and decongests)'];
          avoided = [
            'Avoid cold, heavy, sweet, sour, salty, and oily foods (refined sugar, dairy products, cold desserts).',
            'Limit deep-fried foods, red meat, and excess salt.',
            'Avoid sedentary behavior, oversleeping, and lethargic routines.',
          ];
        }
      }
    }

    return AyurvedicProfile(
      scores: DoshaScores(vata: vata, pitta: pitta, kapha: kapha),
      vataPercentage: vataPct,
      pittaPercentage: pittaPct,
      kaphaPercentage: kaphaPct,
      dominantDosha: dominant,
      description: description,
      dietaryRecommendations: dietary,
      lifestyleRecommendations: lifestyle,
      recommendedHerbs: herbs,
      avoidedFoods: avoided,
    );
  }
}
