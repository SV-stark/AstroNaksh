/// Service to calculate Avakahada Chakra details (Varna, Gana, Yoni, Nadi, etc.)
class AvakahadaService {
  /// Get Varna based on Moon Rashi index (0-11)
  static String getVarna(int rashiIndex) {
    if ([3, 7, 11].contains(rashiIndex)) return 'Brahmin';
    if ([0, 4, 8].contains(rashiIndex)) return 'Kshatriya';
    if ([1, 5, 9].contains(rashiIndex)) return 'Vaishya';
    return 'Shudra';
  }

  /// Get Vashya based on Moon Rashi index (0-11)
  static String getVashya(int rashiIndex) {
    if ([0, 4, 8].contains(rashiIndex)) return 'Chatushpada (Quadruped)';
    if ([1, 2, 5, 6, 10].contains(rashiIndex)) return 'Nara (Human)';
    if ([3, 7, 11].contains(rashiIndex)) return 'Jalachara (Water-born)';
    return 'Keeta (Insect)';
  }

  /// Get Gana based on Moon Nakshatra index (0-26)
  static String getGana(int nakshatraIndex) {
    const deva = [0, 4, 6, 7, 12, 14, 20, 21, 26];
    const manushya = [1, 3, 5, 10, 11, 13, 15, 17, 24];

    if (deva.contains(nakshatraIndex)) return 'Deva (Divine)';
    if (manushya.contains(nakshatraIndex)) return 'Manushya (Human)';
    return 'Rakshasa (Demon)';
  }

  /// Get Yoni based on Moon Nakshatra index (0-26)
  static String getYoni(int nakshatraIndex) {
    const yoniMap = {
      0: 'Ashwa (Horse)',
      23: 'Ashwa (Horse)',
      1: 'Gaja (Elephant)',
      3: 'Gaja (Elephant)',
      2: 'Mesha (Sheep)',
      9: 'Mesha (Sheep)',
      4: 'Sarpa (Serpent)',
      5: 'Sarpa (Serpent)',
      6: 'Shwan (Dog)',
      18: 'Shwan (Dog)',
      7: 'Marjara (Cat)',
      8: 'Marjara (Cat)',
      10: 'Mooshaka (Rat)',
      11: 'Mooshaka (Rat)',
      12: 'Gau (Cow)',
      25: 'Gau (Cow)',
      13: 'Mahisha (Buffalo)',
      20: 'Mahisha (Buffalo)',
      14: 'Vyaghr (Tiger)',
      15: 'Vyaghr (Tiger)',
      16: 'Mrig (Deer)',
      17: 'Mrig (Deer)',
      19: 'Vanar (Monkey)',
      21: 'Vanar (Monkey)',
      22: 'Nakul (Mongoose)',
      24: 'Simha (Lion)',
      26: 'Simha (Lion)',
    };
    return yoniMap[nakshatraIndex] ?? 'Unknown';
  }

  /// Get Nadi based on Moon Nakshatra index (0-26)
  static String getNadi(int nakshatraIndex) {
    final remainder = nakshatraIndex % 3;
    switch (remainder) {
      case 0:
        return 'Adi (Beginning)';
      case 1:
        return 'Madhya (Middle)';
      case 2:
        return 'Antya (End)';
      default:
        return 'Unknown';
    }
  }

  /// Get Paya (Foot) based on Moon house position relative to Lagna (1-12)
  static String getPaya(int moonHouse) {
    if ([1, 6, 11].contains(moonHouse)) return 'Sona (Gold)';
    if ([2, 5, 9].contains(moonHouse)) return 'Chandi (Silver)';
    if ([3, 7, 10].contains(moonHouse)) return 'Tamba (Copper)';
    return 'Loha (Iron)';
  }

  /// Get Nakshatra-based Paya (Alternative)
  static String getNakshatraPaya(int nakshatraIndex) {
    final idx = nakshatraIndex + 1;
    if ([1, 9, 10, 18, 19, 27].contains(idx)) return 'Silver';
    if ([2, 8, 11, 17, 20, 26].contains(idx)) return 'Gold';
    if ([3, 7, 12, 16, 21, 25].contains(idx)) return 'Copper';
    return 'Iron';
  }
}
