import 'package:jyotish/core.dart';
import '../../../data/models/chart_data.dart';

extension ChartLogicExtensions on CompleteChartData {
  /// Get planet by name string (legacy support)
  Planet? planetFromName(String name) {
    try {
      return Planet.values.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      // Legacy name mappings
      if (name == 'Node' || name == 'Rahu') return Planet.meanNode;
      return null;
    }
  }

  double getPlanetLongitude(String planetName) {
    if (planetName == 'Rahu') return baseChart.rahu.longitude;
    if (planetName == 'Ketu') return baseChart.ketu.longitude;
    final p = planetFromName(planetName);
    if (p != null) {
      return baseChart.planets[p]?.longitude ?? 0.0;
    }
    return 0.0;
  }

  int getPlanetSign(String planetName) {
    if (planetName == 'Rahu') {
      return baseChart.rahu.position.zodiacSignIndex;
    }
    if (planetName == 'Ketu') {
      return (baseChart.ketu.longitude / 30).floor() % 12;
    }
    final p = planetFromName(planetName);
    if (p != null) {
      return baseChart.planets[p]?.position.zodiacSignIndex ?? 0;
    }
    return 0;
  }

  int getPlanetHouse(String planetName) {
    final sign = getPlanetSign(planetName);
    final lagna = getAscendantSign();
    return (sign - lagna + 12) % 12 + 1;
  }

  int getAscendantSign() {
    if (baseChart.houses.cusps.isNotEmpty) {
      return (baseChart.houses.cusps[0] / 30).floor();
    }
    return 0;
  }

  int getSignLord(int signIndex) {
    final lords = [
      Planet.mars, // Aries
      Planet.venus, // Taurus
      Planet.mercury, // Gemini
      Planet.moon, // Cancer
      Planet.sun, // Leo
      Planet.mercury, // Virgo
      Planet.venus, // Libra
      Planet.mars, // Scorpio
      Planet.jupiter, // Sagittarius
      Planet.saturn, // Capricorn
      Planet.saturn, // Aquarius
      Planet.jupiter, // Pisces
    ];
    return lords[signIndex % 12].index;
  }

  String getHouseLord(int house) {
    final lagna = getAscendantSign();
    final houseSign = (lagna + house - 1) % 12;
    final lordIndex = getSignLord(houseSign);
    return Planet.values[lordIndex].name;
  }

  bool isExalted(String planet, int sign) {
    final exalts = {
      'Sun': 0, // Aries
      'Moon': 1, // Taurus
      'Mars': 9, // Capricorn
      'Mercury': 5, // Virgo
      'Jupiter': 3, // Cancer
      'Venus': 11, // Pisces
      'Saturn': 6, // Libra
      'Rahu': 2, // Gemini (common view)
      'Ketu': 8, // Sagittarius
    };
    return exalts[planet] == sign;
  }

  bool isDebilitated(String planet, int sign) {
    final debils = {
      'Sun': 6, // Libra
      'Moon': 7, // Scorpio
      'Mars': 3, // Cancer
      'Mercury': 11, // Pisces
      'Jupiter': 9, // Capricorn
      'Venus': 5, // Virgo
      'Saturn': 0, // Aries
      'Rahu': 8, // Sagittarius
      'Ketu': 2, // Gemini
    };
    return debils[planet] == sign;
  }

  bool isOwnSign(String planet, int sign) {
    final p = planetFromName(planet);
    if (p == null) return false;
    final lordOfSign = getSignLord(sign);
    return p.index == lordOfSign;
  }

  bool areConjunct(String p1, String p2) {
    return getPlanetSign(p1) == getPlanetSign(p2);
  }

  bool areOpposite(String p1, String p2) {
    final s1 = getPlanetSign(p1);
    final s2 = getPlanetSign(p2);
    return (s1 - s2).abs() == 6;
  }

  bool isAspecting(String planet, String targetPlanet, List<int> aspects) {
    final pSign = getPlanetSign(planet);
    final tSign = getPlanetSign(targetPlanet);
    final dist = (tSign - pSign + 12) % 12 + 1;
    return aspects.contains(dist);
  }

  bool isPlanetInKendra(String planet) {
    final house = getPlanetHouse(planet);
    return [1, 4, 7, 10].contains(house);
  }

  bool isPlanetInTrikona(String planet) {
    final house = getPlanetHouse(planet);
    return [1, 5, 9].contains(house);
  }

  bool areInMutualExchange(String p1, String p2) {
    final s1 = getPlanetSign(p1);
    final s2 = getPlanetSign(p2);
    return getSignLord(s1) == planetFromName(p2)?.index &&
        getSignLord(s2) == planetFromName(p1)?.index;
  }

  bool isDusthana(int house) => [6, 8, 12].contains(house);

  bool isKendraOrTrikona(int house) => [1, 4, 5, 7, 9, 10].contains(house);

  String getExaltationSignLord(String planet) {
    final exalts = {
      'Sun': 0,
      'Moon': 1,
      'Mars': 9,
      'Mercury': 5,
      'Jupiter': 3,
      'Venus': 11,
      'Saturn': 6,
    };
    final sign = exalts[planet];
    if (sign == null) return '';
    final lordIndex = getSignLord(sign);
    return Planet.values[lordIndex].name;
  }

  bool areInMutualKendras(String p1, String p2) {
    final s1 = getPlanetSign(p1);
    final s2 = getPlanetSign(p2);
    final dist = (s2 - s1 + 12) % 12 + 1;
    return [1, 4, 7, 10].contains(dist);
  }
}
