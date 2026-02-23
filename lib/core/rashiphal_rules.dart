/// Core rules engine for Rashiphal predictions
/// Maps astrological data (Sign, Nakshatra, Tithi) to human-readable predictions
class RashiphalRules {
  /// Get prediction for Moon Sign Transit (Chandra Gochar)
  /// [moonSign] 0=Aries, 11=Pisces
  /// [houseFromNatal] The house the transiting Moon is in relative to natal Moon
  /// [signName] The name of the sign the Moon is transiting (e.g., "Aries")
  static String getMoonSignPrediction(
    int moonSign,
    int houseFromNatal, {
    String signName = '',
  }) {
    final signRef = signName.isNotEmpty ? ' through $signName' : '';
    // Basic rules based on house position from Natal Moon (Chandrashtama etc.)
    switch (houseFromNatal) {
      case 1:
        return 'The Moon transiting$signRef is visiting your natal sign (1st house from natal Moon). You may feel more emotional and sensitive today. This transit heightens self-awareness — focus on self-care and personal well-being.';
      case 2:
        return 'Moon transiting$signRef occupies the 2nd house from your natal Moon, activating the house of wealth and speech. This suggests a focus on finances and family matters. Good for planning expenses, but avoid impulsive spending.';
      case 3:
        return 'Moon transiting$signRef in the 3rd house from your natal Moon energizes the house of courage and communication. Excellent day for short trips, writing, and starting new initiatives with confidence.';
      case 4:
        return 'Moon transiting$signRef in the 4th house from your natal Moon highlights domestic life and inner peace (Sukha Bhava). Spend time with family or improve your living space. Watch out for mood swings.';
      case 5:
        return 'Moon transiting$signRef in the 5th house from your natal Moon activates the house of creativity, romance, and intellect. A good day for hobbies, spending time with children, or speculative planning.';
      case 6:
        return 'Moon transiting$signRef in the 6th house from your natal Moon activates the house of service and health (Ari Bhava). Great for organizing, overcoming obstacles, and routine work, but avoid unnecessary conflict.';
      case 7:
        return 'Moon transiting$signRef in the 7th house from your natal Moon lights up partnerships and relationships (Kalatra Bhava). Collaboration flows well. Perfect for negotiations and social interactions.';
      case 8:
        return 'Moon transiting$signRef in the 8th house from your natal Moon triggers Chandrashtama — a classically cautious transit through the house of transformation. Avoid major decisions, risks, or arguments. Focus on research or introspection.';
      case 9:
        return 'Moon transiting$signRef in the 9th house from your natal Moon activates the house of fortune and higher learning (Dharma Bhava). Good for spiritual practices, long-distance travel, or seeking mentorship. Luck favors you.';
      case 10:
        return 'Moon transiting$signRef in the 10th house from your natal Moon highlights career and public image (Karma Bhava). Your efforts at work will be noticed. A highly productive day for professional goals.';
      case 11:
        return 'Moon transiting$signRef in the 11th house from your natal Moon activates the house of gains and aspirations (Labha Bhava). Excellent for networking, socializing, and fulfilling desires. Opportunities come easily.';
      case 12:
        return 'Moon transiting$signRef in the 12th house from your natal Moon activates the house of expenditure and liberation (Vyaya Bhava). Good for meditation, charity, or planning foreign travel. Conserve energy and avoid stress.';
      default:
        return 'Planetary energies are neutral today. Maintain a balanced approach to your daily activities.';
    }
  }

  /// Get prediction based on Nakshatra
  /// [nakshatraIndex] 0=Ashwini, 26=Revati
  /// [nakshatraName] The name of the Nakshatra for contextual reference
  static String getNakshatraPrediction(
    int nakshatraIndex, {
    String nakshatraName = '',
  }) {
    const predictions = [
      'Under the swift healing energy of Ashwini Nakshatra (ruled by Ketu, deity: Ashwini Kumaras), this is good for starting quick tasks, healing therapies, and medical treatments.',
      'Bharani Nakshatra (ruled by Venus, deity: Yama) governs today — favorable for creative works, resolving conflicts, and matters of transformation.',
      'Krittika Nakshatra (ruled by Sun, deity: Agni) brings fiery determination — excellent for competitive activities, cooking, and making firm decisions.',
      'Rohini Nakshatra (ruled by Moon, deity: Brahma) fosters growth — great for financial planning, planting seeds, agriculture, and creative arts.',
      'Mrigashira Nakshatra (ruled by Mars, deity: Soma) activates curiosity — good for travel, search, exploration, and communication.',
      'Ardra Nakshatra (ruled by Rahu, deity: Rudra) brings transformative energy — favorable for research and breaking old habits. Avoid sensitive conversations.',
      'Punarvasu Nakshatra (ruled by Jupiter, deity: Aditi) brings renewal — excellent for travel, family gatherings, homecoming, and starting repairs.',
      'Pushya Nakshatra (ruled by Saturn, deity: Brihaspati) is one of the most auspicious — highly favorable for spiritual activities, nourishment, and legal matters.',
      'Ashlesha Nakshatra (ruled by Mercury, deity: Naga) activates deep intuition — good for kundalini yoga and introspection. Avoid starting new business ventures.',
      'Magha Nakshatra (ruled by Ketu, deity: Pitris) connects to ancestry — favorable for ceremonies, honoring ancestors, and matters of authority.',
      'Purva Phalguni Nakshatra (ruled by Venus, deity: Bhaga) brings pleasure — good for romance, relaxation, entertainment, and artistic pursuits.',
      'Uttara Phalguni Nakshatra (ruled by Sun, deity: Aryaman) brings commitment — excellent for weddings, laying foundations, and long-term agreements.',
      'Hasta Nakshatra (ruled by Moon, deity: Savitar) brings dexterity — great for detailed work, writing, craftsmanship, and learning new skills.',
      'Chitra Nakshatra (ruled by Mars, deity: Vishwakarma) inspires creation — favorable for design, architecture, jewellery, and spiritual activities.',
      'Swati Nakshatra (ruled by Rahu, deity: Vayu) brings independence — good for trade, business deals, learning, and building connections.',
      'Vishakha Nakshatra (ruled by Jupiter, deity: Indra-Agni) fuels ambition — excellent for goal-setting, determined efforts, and competitive endeavors.',
      'Anuradha Nakshatra (ruled by Saturn, deity: Mitra) fosters devotion — favorable for friendship, group activities, and deepening bonds.',
      'Jyeshtha Nakshatra (ruled by Mercury, deity: Indra) empowers leadership — good for assuming authority, facing challenges, and protecting others.',
      'Mula Nakshatra (ruled by Ketu, deity: Nirriti) uncovers roots — favorable for investigation, getting to the root of problems, and gardening.',
      'Purva Ashadha Nakshatra (ruled by Venus, deity: Apas) brings invincibility — good for debates, conflict resolution, and water-related activities.',
      'Uttara Ashadha Nakshatra (ruled by Sun, deity: Vishve Devas) grants final victory — excellent for laying foundations, government work, and starting public works.',
      'Shravana Nakshatra (ruled by Moon, deity: Vishnu) enhances receptivity — good for listening, learning, counseling, and acquiring knowledge.',
      'Dhanishta Nakshatra (ruled by Mars, deity: Vasus) brings prosperity — favorable for music, wealth creation, real estate, and medical treatment.',
      'Shatabhisha Nakshatra (ruled by Rahu, deity: Varuna) activates healing — good for alternative medicine, technology, astronomy, and solving mysteries.',
      'Purva Bhadrapada Nakshatra (ruled by Jupiter, deity: Aja Ekapada) brings intensity — favorable for penance, spiritual elevation, and austerity. Be careful with money.',
      'Uttara Bhadrapada Nakshatra (ruled by Saturn, deity: Ahir Budhnya) brings depth — excellent for retirement planning, seclusion, meditation, and charity.',
      'Revati Nakshatra (ruled by Mercury, deity: Pushan) brings completion — good for finishing projects, weddings, artistic excellence, and safe travels.',
    ];
    return predictions[nakshatraIndex % 27];
  }

  /// Get Tithi based recommendation
  /// [tithi] 1-30
  static String getTithiRecommendation(int tithi) {
    // Grouping by Nanda, Bhadra, Jaya, Rikta, Purna categories
    final nanda = [1, 6, 11, 16, 21, 26]; // Pleasure, festivals
    final rikta = [4, 9, 14, 19, 24, 29]; // Empty hands - avoid new work
    final purna = [5, 10, 15, 20, 25, 30]; // Completeness, all auspicious

    if (rikta.contains(tithi)) {
      return 'Today is a Rikta (Empty) Tithi. Good for cleaning, decluttering, or aggressive actions. Avoid important new beginnings.';
    } else if (purna.contains(tithi)) {
      return 'Today is a Purna (Full) Tithi. Excellent for completing projects and starting all auspicious works.';
    } else if (nanda.contains(tithi)) {
      return 'Today is a Nanda (Joy) Tithi. Favorable for festivities, enjoyments, and social gatherings.';
    } else if (jayam.contains(tithi)) {
      // jayam is typically just jaya
      return 'Today is a Jaya (Victory) Tithi. Good for overcoming obstacles, winning debates, and competitive exams.';
    } else {
      // Bhadra
      return 'Today is a Bhadra (Good) Tithi. Favorable for health-related activities, wellness, and routine sustenance.';
    }
  }

  // Helper for Jaya/Jayam variable name clarity
  static List<int> get jayam => [3, 8, 13, 18, 23, 28];

  /// Get simple Muhurta timings (Abhijit etc)
  /// Returns a list of strings describing favorable times
  /// Get simple Muhurta timings (Abhijit etc)
  /// Returns a list of strings describing favorable times
  /// [sunrise] and [sunset] are required for accurate Rahu Kaalam and Abhijit
  static List<String> getMuhurtaTimings(
    DateTime date, {
    bool isAbhijit = true,
    DateTime? sunrise,
    DateTime? sunset,
  }) {
    final timings = <String>[];
    String timeFormat(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    // Abhijit Muhurta
    // 8th Muhurta of the day (out of 15). Roughly mid-day.
    // Exact: Midpoint of Sunrise-Sunset. Span is (Sunset-Sunrise)/15.
    if (isAbhijit && sunrise != null && sunset != null) {
      final dayDuration = sunset.difference(sunrise);
      final muhurtaDuration = dayDuration ~/ 15;

      // Abhijit is the 8th muhurta (index 7 if 0-based)
      // Actually spans 24 mins before and after Local Noon (approx)
      // Standard definition: The 8th muhurta.
      final start = sunrise.add(muhurtaDuration * 7);
      final end = start.add(muhurtaDuration);

      timings.add(
        'Abhijit Muhurta: ${timeFormat(start)} - ${timeFormat(end)} (Excellent for most activities)',
      );
    } else if (isAbhijit) {
      // Fallback if no sunrise/set provided
      final midDay = DateTime(date.year, date.month, date.day, 12, 0);
      final start = midDay.subtract(const Duration(minutes: 24));
      final end = midDay.add(const Duration(minutes: 24));
      timings.add(
        'Abhijit Muhurta: ${timeFormat(start)} - ${timeFormat(end)} (Approximate)',
      );
    }

    // Rahu Kaalam Calculation
    // Day is divided into 8 equal parts.
    // Rahu Kaalam periods:
    // Mon: 2nd, Tue: 7th, Wed: 5th, Thu: 6th, Fri: 4th, Sat: 3rd, Sun: 8th
    if (sunrise != null && sunset != null) {
      final dayDuration = sunset.difference(sunrise);
      final partDuration = dayDuration ~/ 8;

      int partIndex; // 1-based index (1 to 8)
      switch (date.weekday) {
        case 1:
          partIndex = 2;
          break; // Mon
        case 2:
          partIndex = 7;
          break; // Tue
        case 3:
          partIndex = 5;
          break; // Wed
        case 4:
          partIndex = 6;
          break; // Thu
        case 5:
          partIndex = 4;
          break; // Fri
        case 6:
          partIndex = 3;
          break; // Sat
        case 7:
          partIndex = 8;
          break; // Sun
        default:
          partIndex = 1;
      }

      final start = sunrise.add(partDuration * (partIndex - 1));
      final end = start.add(partDuration);

      timings.add(
        'Rahu Kalam (Avoid): ${timeFormat(start)} - ${timeFormat(end)}',
      );
    } else {
      // Fallback to static map if no sunrise/set
      final weekday = date.weekday; // 1=Mon, 7=Sun
      String rahuKal = '';
      switch (weekday) {
        case 1:
          rahuKal = '07:30 - 09:00';
          break;
        case 2:
          rahuKal = '15:00 - 16:30';
          break;
        case 3:
          rahuKal = '12:00 - 13:30';
          break;
        case 4:
          rahuKal = '13:30 - 15:00';
          break;
        case 5:
          rahuKal = '10:30 - 12:00';
          break;
        case 6:
          rahuKal = '09:00 - 10:30';
          break;
        case 7:
          rahuKal = '16:30 - 18:00';
          break;
      }
      timings.add('Rahu Kalam (Avoid): $rahuKal (Approximate)');
    }

    return timings;
  }

  /// Get Tarabala category (1-9)
  /// [birthNakshatra] 1-27
  /// [dailyNakshatra] 1-27
  static int getTarabalaCategory(int birthNakshatra, int dailyNakshatra) {
    // Count from birth to daily (inclusive)
    int count = (dailyNakshatra - birthNakshatra + 27) % 27 + 1;
    int tarabala = count % 9;
    return tarabala == 0 ? 9 : tarabala;
  }

  /// Get score for Tarabala category
  /// Returns points (0-30)
  static int getTarabalaScore(int category) {
    switch (category) {
      case 2: // Sampat
      case 4: // Kshema
      case 6: // Sadhana
      case 8: // Mitra
      case 9: // Param Mitra
        return 30;
      case 1: // Janma (Mixed/Body stress)
        return 10;
      case 3: // Vipat
      case 5: // Pratyak
      case 7: // Naidhana
      default:
        return 0;
    }
  }

  /// Get Murti (Form of the Moon) based on Transit Sign relative to Natal Moon Sign
  /// [natalSign] 0-11
  /// [transitSign] 0-11
  static String getMurti(int natalSign, int transitSign) {
    // Murti is calculated by position from natal Moon
    // 1st, 6th, 11th - Gold (Swarna)
    // 2nd, 5th, 9th - Silver (Rajat)
    // 3rd, 7th, 10th - Copper (Tamra)
    // 4th, 8th, 12th - Iron (Loha)
    int houseFromMoon = ((transitSign - natalSign + 12) % 12) + 1;

    if ([1, 6, 11].contains(houseFromMoon)) return 'Gold';
    if ([2, 5, 9].contains(houseFromMoon)) return 'Silver';
    if ([3, 7, 10].contains(houseFromMoon)) return 'Copper';
    return 'Iron';
  }

  /// Get points for Murti (0-20)
  static int getMurtiScore(String murti) {
    switch (murti) {
      case 'Gold':
        return 20;
      case 'Silver':
        return 20;
      case 'Copper':
        return 10;
      case 'Iron':
      default:
        return 0;
    }
  }

  /// Check if the Nithya Yoga is considered malefic (Vyatipata or Vaidhriti)
  /// [yogaNumber] 1-27
  static bool isMaleficYoga(int yogaNumber) {
    // Vyatipata is 17th, Vaidhriti is 27th
    return yogaNumber == 17 || yogaNumber == 27;
  }
}
