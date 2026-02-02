import 'package:jyotish/jyotish.dart';
import '../data/models.dart';

/// Complete Divisional Charts (Varga) Calculation System
/// Calculates planetary positions for all 16 major divisional charts
class DivisionalCharts {
  /// Calculate all 16 divisional charts for a given rasi chart
  /// Returns a map of chart codes to DivisionalChartData objects
  static Map<String, DivisionalChartData> calculateAllCharts(VedicChart chart) {
    return {
      'D-1': _calculateDivision(chart, 1, (s, d) => s), // Rasi
      'D-2': _calculateHora(chart),
      'D-3': _calculateDivision(chart, 3, _drekkanaRule),
      'D-4': _calculateChaturthamsa(chart),
      'D-7': _calculateSaptamsa(chart),
      'D-9': _calculateNavamsa(chart),
      'D-10': _calculateDasamsa(chart),
      'D-12': _calculateDivision(
        chart,
        12,
        (s, d) => (s + (d / 2.5).floor()) % 12,
      ),
      'D-16': _calculateShodasamsa(chart),
      'D-20': _calculateVimsamsa(chart),
      'D-24': _calculateChaturvimsamsa(chart),
      'D-27': _calculateBhamsa(chart),
      'D-30': _calculateTrimsamsa(chart),
      'D-40': _calculateKhavedamsa(chart),
      'D-45': _calculateAkshavedamsa(chart),
      'D-60': _calculateShashtiamsa(chart),
    };
  }

  /// Drekkana calculation: each sign divided into 3 parts of 10° each
  static int _drekkanaRule(int sign, double degree) {
    final drekkana = (degree / 10).floor();
    return (sign + drekkana) % 12;
  }

  /// D-2: Hora Chart - Division for wealth
  static DivisionalChartData _calculateHora(VedicChart chart) {
    final positions = <String, double>{};

    chart.planets.forEach((planet, info) {
      final sign = (info.longitude / 30).floor();
      final degree = info.longitude % 30;
      final isOdd = sign % 2 == 0; // 0-indexed
      final inFirstHalf = degree < 15;

      // Odd signs: First half -> Leo (4), Second half -> Cancer (3)
      // Even signs: First half -> Cancer (3), Second half -> Leo (4)
      int newSign;
      if (isOdd) {
        newSign = inFirstHalf ? 4 : 3;
      } else {
        newSign = inFirstHalf ? 3 : 4;
      }

      final planetName = planet.toString().split('.').last;
      positions[planetName] = newSign * 30 + (degree * 2) % 30;
    });

    return DivisionalChartData(
      code: 'D-2',
      name: 'Hora',
      description: 'Wealth',
      positions: positions,
    );
  }

  /// D-4: Chaturthamsa Chart - Division for fortune and property
  static DivisionalChartData _calculateChaturthamsa(VedicChart chart) {
    return _calculateDivision(
      chart,
      4,
      (sign, degree) {
        final part = (degree / 7.5).floor();

        // Movable: start from Aries, Fixed: from Leo, Dual: from Sagittarius
        if (sign % 3 == 0) {
          return part % 12;
        } else if (sign % 3 == 1) {
          return (4 + part) % 12;
        } else {
          return (8 + part) % 12;
        }
      },
      name: 'Chaturthamsa',
      description: 'Fortune, Property',
    );
  }

  /// D-7: Saptamsa Chart - Division for children
  static DivisionalChartData _calculateSaptamsa(VedicChart chart) {
    return _calculateDivision(
      chart,
      7,
      (sign, degree) {
        final part = (degree / (30 / 7)).floor();

        if (sign % 2 == 0) {
          // Odd signs: direct order
          return (sign + part) % 12;
        } else {
          // Even signs: reverse order
          return (sign - part + 12) % 12;
        }
      },
      name: 'Saptamsa',
      description: 'Children',
    );
  }

  /// D-9: Navamsa Chart - Most important division for spouse and dharma
  /// Uses element-based starting signs (not modality)
  static DivisionalChartData _calculateNavamsa(VedicChart chart) {
    return _calculateDivision(
      chart,
      9,
      (sign, degree) {
        final navamsa = (degree / (30.0 / 9.0)).floor();

        // Element-based starting signs (correct Vedic Navamsa calculation):
        // Fire signs (Aries=0, Leo=4, Sagittarius=8): Start from Aries (0)
        // Earth signs (Taurus=1, Virgo=5, Capricorn=9): Start from Capricorn (9)
        // Air signs (Gemini=2, Libra=6, Aquarius=10): Start from Libra (6)
        // Water signs (Cancer=3, Scorpio=7, Pisces=11): Start from Cancer (3)
        int startSign;
        final element = sign % 4; // 0=Fire, 1=Earth, 2=Air, 3=Water
        switch (element) {
          case 0: // Fire signs
            startSign = 0; // Aries
            break;
          case 1: // Earth signs
            startSign = 9; // Capricorn
            break;
          case 2: // Air signs
            startSign = 6; // Libra
            break;
          case 3: // Water signs
            startSign = 3; // Cancer
            break;
          default:
            startSign = 0;
        }
        return (startSign + navamsa) % 12;
      },
      name: 'Navamsa',
      description: 'Spouse, Dharma',
    );
  }

  /// D-10: Dasamsa Chart - Division for career and power
  /// Each sign divided into 10 parts of 3° each
  static DivisionalChartData _calculateDasamsa(VedicChart chart) {
    return _calculateDivision(
      chart,
      10,
      (sign, degree) {
        final part = (degree / 3.0).floor(); // 10 parts of 3° each

        // Correct Dasamsa calculation:
        // Odd signs (0,2,4,6,8,10 = Aries,Gemini,Leo,Libra,Sag,Aqua):
        //   Start from same sign, count forward
        // Even signs (1,3,5,7,9,11 = Taurus,Cancer,Virgo,Scorpio,Cap,Pisces):
        //   Start from 9th sign from current, count forward
        int startSign;
        if (sign % 2 == 0) {
          // Odd zodiac signs (0-indexed even): start from same sign
          startSign = sign;
        } else {
          // Even zodiac signs (0-indexed odd): start from 9th sign
          startSign = (sign + 8) % 12; // 9th from current (0-indexed: +8)
        }
        return (startSign + part) % 12;
      },
      name: 'Dasamsa',
      description: 'Career, Power',
    );
  }

  /// D-16: Shodasamsa Chart - Division for vehicles and comfort
  static DivisionalChartData _calculateShodasamsa(VedicChart chart) {
    return _calculateDivision(
      chart,
      16,
      (sign, degree) {
        final part = (degree / (30 / 16)).floor();

        if (sign % 3 == 0) {
          return part % 12;
        } else if (sign % 3 == 1) {
          return (4 + part) % 12;
        } else {
          return (8 + part) % 12;
        }
      },
      name: 'Shodasamsa',
      description: 'Vehicles, Comfort',
    );
  }

  /// D-20: Vimsamsa Chart - Division for spirituality
  static DivisionalChartData _calculateVimsamsa(VedicChart chart) {
    return _calculateDivision(
      chart,
      20,
      (sign, degree) {
        final part = (degree / 1.5).floor();

        if (sign % 3 == 0) {
          return part % 12;
        } else if (sign % 3 == 1) {
          return (8 + part) % 12;
        } else {
          return (4 + part) % 12;
        }
      },
      name: 'Vimsamsa',
      description: 'Spirituality',
    );
  }

  /// D-24: Chaturvimsamsa Chart - Division for knowledge
  static DivisionalChartData _calculateChaturvimsamsa(VedicChart chart) {
    return _calculateDivision(
      chart,
      24,
      (sign, degree) {
        final part = (degree / (30 / 24)).floor();

        // Odd signs: Leo onwards, Even signs: Cancer onwards
        if (sign % 2 == 0) {
          return (4 + part) % 12;
        } else {
          return (3 + part) % 12;
        }
      },
      name: 'Chaturvimsamsa',
      description: 'Knowledge',
    );
  }

  /// D-27: Bhamsa Chart - Division for strengths and weaknesses
  static DivisionalChartData _calculateBhamsa(VedicChart chart) {
    return _calculateDivision(
      chart,
      27,
      (sign, degree) {
        final part = (degree / (30 / 27)).floor();

        if (sign % 3 == 0) {
          return (sign + part) % 12;
        } else if (sign % 3 == 1) {
          return (sign + 4 + part) % 12;
        } else {
          return (sign + 8 + part) % 12;
        }
      },
      name: 'Bhamsa',
      description: 'Strengths',
    );
  }

  /// D-30: Trimsamsa Chart - Division for misfortunes
  static DivisionalChartData _calculateTrimsamsa(VedicChart chart) {
    final positions = <String, double>{};

    chart.planets.forEach((planet, info) {
      final sign = (info.longitude / 30).floor();
      final degree = info.longitude % 30;
      final isOdd = sign % 2 == 0;

      int newSign;
      if (isOdd) {
        // Odd signs: Mars 0-5, Saturn 5-10, Jupiter 10-18, Mercury 18-25, Venus 25-30
        if (degree < 5) {
          newSign = 0; // Aries
        } else if (degree < 10) {
          newSign = 10; // Capricorn
        } else if (degree < 18) {
          newSign = 8; // Sagittarius
        } else if (degree < 25) {
          newSign = 2; // Gemini
        } else {
          newSign = 6; // Libra
        }
      } else {
        // Even signs: Venus 0-5, Mercury 5-12, Jupiter 12-20, Saturn 20-25, Mars 25-30
        if (degree < 5) {
          newSign = 6; // Libra
        } else if (degree < 12) {
          newSign = 2; // Gemini
        } else if (degree < 20) {
          newSign = 8; // Sagittarius
        } else if (degree < 25) {
          newSign = 10; // Capricorn
        } else {
          newSign = 0; // Aries
        }
      }

      final planetName = planet.toString().split('.').last;
      positions[planetName] = newSign * 30 + degree;
    });

    return DivisionalChartData(
      code: 'D-30',
      name: 'Trimsamsa',
      description: 'Misfortunes',
      positions: positions,
    );
  }

  /// D-40: Khavedamsa Chart - Division for auspicious results
  static DivisionalChartData _calculateKhavedamsa(VedicChart chart) {
    return _calculateDivision(
      chart,
      40,
      (sign, degree) {
        final part = (degree / (30 / 40)).floor();

        if (sign % 3 == 0) {
          return (sign + part) % 12;
        } else if (sign % 3 == 1) {
          return (sign + 4 + part) % 12;
        } else {
          return (sign + 8 + part) % 12;
        }
      },
      name: 'Khavedamsa',
      description: 'Auspicious Results',
    );
  }

  /// D-45: Akshavedamsa Chart - Division for general results
  static DivisionalChartData _calculateAkshavedamsa(VedicChart chart) {
    return _calculateDivision(
      chart,
      45,
      (sign, degree) {
        final part = (degree / (30 / 45)).floor();

        if (sign % 3 == 0) {
          return part % 12;
        } else if (sign % 3 == 1) {
          return (4 + part) % 12;
        } else {
          return (8 + part) % 12;
        }
      },
      name: 'Akshavedamsa',
      description: 'General Results',
    );
  }

  /// D-60: Shashtiamsa Chart - Division for general indication
  static DivisionalChartData _calculateShashtiamsa(VedicChart chart) {
    return _calculateDivision(
      chart,
      60,
      (sign, degree) {
        final part = (degree / 0.5).floor();

        // Odd signs: Aries onwards, Even signs: Libra onwards
        if (sign % 2 == 0) {
          return (sign + part) % 12;
        } else {
          return (sign + 6 + part) % 12;
        }
      },
      name: 'Shashtiamsa',
      description: 'General Indication',
    );
  }

  /// Generic division calculator
  static DivisionalChartData _calculateDivision(
    VedicChart chart,
    int divisions,
    int Function(int sign, double degree) calculateNewSign, {
    String? name,
    String? description,
  }) {
    final positions = <String, double>{};

    chart.planets.forEach((planet, info) {
      final sign = (info.longitude / 30).floor();
      final degree = info.longitude % 30;
      final newSign = calculateNewSign(sign, degree);
      final newLongitude = newSign * 30 + (degree * divisions) % 30;

      final planetName = planet.toString().split('.').last;
      positions[planetName] = newLongitude;
    });

    // Calculate ascendant for this division
    final ascSign = _getHouseCuspSign(chart, 0);
    final ascDegree = _getHouseCuspDegree(chart, 0);
    final newAscSign = calculateNewSign(ascSign, ascDegree);

    return DivisionalChartData(
      code: 'D-$divisions',
      name: name ?? 'Divisional Chart',
      description: description ?? 'Division by $divisions',
      positions: positions,
      ascendantSign: newAscSign,
    );
  }

  /// Safely get house cusp sign
  static int _getHouseCuspSign(VedicChart chart, int index) {
    try {
      final houses = chart.houses;
      // Fixed: Access cusps directly
      if (index < houses.cusps.length) {
        final long = houses.cusps[index];
        return (long / 30).floor();
      }
      return index;
    } catch (e) {
      return index;
    }
  }

  /// Safely get house cusp degree within sign
  static double _getHouseCuspDegree(VedicChart chart, int index) {
    try {
      final houses = chart.houses;
      // Fixed: Access cusps directly
      if (index < houses.cusps.length) {
        final long = houses.cusps[index];
        return long % 30;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get zodiac sign name from index (0-11)
  static String getSignName(int sign) {
    const signs = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces',
    ];
    return signs[sign % 12];
  }

  /// Get sign lord
  static String getSignLord(int sign) {
    const lords = [
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
    return lords[sign % 12];
  }
}
