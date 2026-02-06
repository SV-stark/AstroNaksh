/// Core rules engine for Rashiphal predictions
/// Maps astrological data (Sign, Nakshatra, Tithi) to human-readable predictions
class RashiphalRules {
  /// Get prediction for Moon Sign Transit (Chandra Gochar)
  /// [moonSign] 0=Aries, 11=Pisces
  /// [houseFromNatal] The house the transiting Moon is in relative to natal Moon
  static String getMoonSignPrediction(int moonSign, int houseFromNatal) {
    // Basic rules based on house position from Natal Moon (Chandrashtama etc.)
    switch (houseFromNatal) {
      case 1:
        return 'The Moon is visiting your natal sign. You may feel more emotional and sensitive today. Focus on self-care and personal well-being.';
      case 2:
        return 'Moon in the 2nd house suggests a focus on finances and family. Good for planning expenses, but avoid impulsive spending.';
      case 3:
        return 'Moon in the 3rd house brings energy and courage. Excellent day for communication, short trips, and starting new initiatives.';
      case 4:
        return 'Moon in the 4th house highlights home and inner peace. Spend time with family or improve your living space. Watch out for mood swings.';
      case 5:
        return 'Moon in the 5th house enhances creativity and romance. A good day for hobbies, spending time with children, or speculative planning.';
      case 6:
        return 'Moon in the 6th house indicates routine work and health. Great for organizing and service, but avoid conflict with opponents.';
      case 7:
        return 'Moon in the 7th house focuses on relationships and partnerships. Collaboration flows well today. Perfect for social interactions.';
      case 8:
        return 'Moon in the 8th house (Chandrashtama) calls for caution. Avoid major decisions, risks, or arguments. Focus on research or introspection.';
      case 9:
        return 'Moon in the 9th house brings luck and higher learning. Good for spiritual practices, long-distance travel, or seeking mentorship.';
      case 10:
        return 'Moon in the 10th house highlights career and public image. Your efforts at work will be noticed. A productive day for professional goals.';
      case 11:
        return 'Moon in the 11th house is excellent for gains and networking. Socializing brings benefits. Your desires are more easily fulfilled.';
      case 12:
        return 'Moon in the 12th house suggests rest and withdrawal. Good for meditation, expenses on charity, or planning foreign travel. Avoid stress.';
      default:
        return 'Planetary energies are neutral today. Maintain a balanced approach to your daily activities.';
    }
  }

  /// Get prediction based on Nakshatra
  /// [nakshatraIndex] 0=Ashwini, 26=Revati
  static String getNakshatraPrediction(int nakshatraIndex) {
    const predictions = [
      'Good for starting quick tasks and healing therapies.', // Ashwini
      'Favorable for creative works and resolving conflicts.', // Bharani
      'Excellent for competitive activities and making firm decisions.', // Krittika
      'Great for planting seeds, financial planning, and creative arts.', // Rohini
      'Good for travel, search, and communication.', // Mrigashira
      'Favorable for research and breaking old habits. Avoid sensitive talks.', // Ardra
      'Excellent for travel, family gatherings, and starting repairs.', // Punarvasu
      'Highly auspicious for spiritual activities and legal matters.', // Pushya
      'Good for kundalini yoga and introspection. Avoid starting new business.', // Ashlesha
      'Favorable for ceremonies and honoring ancestors.', // Magha
      'Good for romance, relaxation, and artistic pursuits.', // Purva Phalguni
      'Excellent for weddings, foundations, and long-term agreements.', // Uttara Phalguni
      'Great for detailed work, writing, and learning crafts.', // Hasta
      'Favorable for design, architecture, and spiritual activities.', // Chitra
      'Good for trade, business deals, and learning.', // Swati
      'Excellent for goal-setting and determined efforts.', // Vishakha
      'Favorable for friendship, group activities, and relaxation.', // Anuradha
      'Good for assuming authority and facing challenges.', // Jyeshtha
      'Favorable for getting to the root of problems and gardening.', // Mula
      'Good for debates, conflict resolution, and water-related activities.', // Purva Ashadha
      'Excellent for laying foundations and starting public works.', // Uttara Ashadha
      'Good for listening, learning, and counseling.', // Shravana
      'Favorable for music, wealth creation, and medical treatment.', // Dhanishta
      'Good for healing, technology, and solving mysteries.', // Shatabhisha
      'Favorable for penance and spiritual elevation. Careful with money.', // Purva Bhadrapada
      'Excellent for retirement planning, seclusion, and charity.', // Uttara Bhadrapada
      'Good for completions, weddings, and artistic excellence.', // Revati
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
  static List<String> getMuhurtaTimings(
    DateTime date, {
    bool isAbhijit = true,
  }) {
    // Ideally this requires sunrise/sunset. approximated here.
    // Abhijit is typically mid-day.
    final timings = <String>[];
    if (isAbhijit) {
      final midDay = DateTime(date.year, date.month, date.day, 12, 0);
      final start = midDay.subtract(const Duration(minutes: 24));
      final end = midDay.add(
        const Duration(minutes: 24),
      ); // 11:36 - 12:24 roughly

      // Formatting
      String formatTime(DateTime d) =>
          '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      timings.add(
        'Abhijit Muhurta: ${formatTime(start)} - ${formatTime(end)} (Excellent for most activities)',
      );
    }

    // Rahu Kaalam (Rough approximation based on weekday)
    // Mon: 7:30-9, Tue: 3-4:30, Wed: 12-1:30, Thu: 1:30-3, Fri: 10:30-12, Sat: 9-10:30, Sun: 4:30-6
    // Using simple static map for now as placeholder for full calc
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
    timings.add('Rahu Kalam (Avoid): $rahuKal');

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
