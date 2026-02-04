class AppConstants {
  static const List<String> nakshatras = [
    'Ashwini',
    'Bharani',
    'Krittika',
    'Rohini',
    'Mrigashira',
    'Ardra',
    'Punarvasu',
    'Pushya',
    'Ashlesha',
    'Magha',
    'Purva Phalguni',
    'Uttara Phalguni',
    'Hasta',
    'Chitra',
    'Swati',
    'Vishakha',
    'Anuradha',
    'Jyeshtha',
    'Mula',
    'Purva Ashadha',
    'Uttara Ashadha',
    'Shravana',
    'Dhanishta',
    'Shatabhisha',
    'Purva Bhadrapada',
    'Uttara Bhadrapada',
    'Revati',
  ];

  static String getPlanetAbbreviation(String planetName) {
    switch (planetName.toLowerCase()) {
      case 'sun':
        return 'Su';
      case 'moon':
        return 'Mo';
      case 'mars':
        return 'Ma';
      case 'mercury':
        return 'Me';
      case 'jupiter':
        return 'Ju';
      case 'venus':
        return 'Ve';
      case 'saturn':
        return 'Sa';
      case 'rahu':
        return 'Ra';
      case 'ketu':
        return 'Ke';
      case 'uranus':
        return 'Ur';
      case 'neptune':
        return 'Ne';
      case 'pluto':
        return 'Pl';
      default:
        return planetName.length > 2 ? planetName.substring(0, 2) : planetName;
    }
  }

  static const List<String> signs = [
    "Aries",
    "Taurus",
    "Gemini",
    "Cancer",
    "Leo",
    "Virgo",
    "Libra",
    "Scorpio",
    "Sagittarius",
    "Capricorn",
    "Aquarius",
    "Pisces",
  ];
}
