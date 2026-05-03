import 'package:jyotish/jyotish.dart';
import '../../data/models.dart';

class ProgenyService {
  /// Analyze prospects for children
  ProgenyAnalysis analyzeProgeny(CompleteChartData chartData) {
    final factors = <ProgenyFactor>[];

    // Check 5th house (children)
    final fifthHouse = _getFifthHouse(chartData);
    factors.add(fifthHouse);

    // Check Jupiter (natural karaka for children)
    final jupiterFactor = _analyzeJupiter(chartData);
    factors.add(jupiterFactor);

    // Check Venus (alternates for male/female chart)
    final venusFactor = _analyzeVenus(chartData);
    factors.add(venusFactor);

    // Check Mars (for male chart)
    final marsFactor = _analyzeMars(chartData);
    factors.add(marsFactor);

    // Check Moon (for female chart)
    final moonFactor = _analyzeMoon(chartData);
    factors.add(moonFactor);

    // Calculate overall prospects
    final score = factors.fold(0, (sum, f) => sum + f.score) ~/ factors.length;

    return ProgenyAnalysis(
      factors: factors,
      overallScore: score,
      prospects: _getProspects(score),
      prediction: _generatePrediction(score, factors),
      recommendations: _getRecommendations(factors),
    );
  }

  String _generatePrediction(int score, List<ProgenyFactor> factors) {
    final buffer = StringBuffer();

    // Overall assessment
    if (score >= 75) {
      buffer.write(
          'Your birth chart indicates exceptionally strong and auspicious prospects for progeny. ');
    } else if (score >= 60) {
      buffer.write(
          'There are very positive and supportive planetary configurations for children in your chart. ');
    } else if (score >= 45) {
      buffer.write(
          'The astrological factors suggest favorable prospects for family growth, with a balanced influence of planets. ');
    } else if (score >= 30) {
      buffer.write(
          'The analysis shows mixed results regarding progeny. While there are some supportive factors, certain planetary positions might cause some delays. ');
    } else {
      buffer.write(
          'The planetary configurations regarding progeny appear quite challenging. This suggests that parenthood may involve significant delays or may require specific traditional remedies and medical guidance. ');
    }

    // Jupiter Analysis (Karaka)
    final jupiter = factors.firstWhere((f) => f.name == 'Jupiter',
        orElse: () => ProgenyFactor(name: '', score: 0, description: ''));
    if (jupiter.score >= 70) {
      buffer.write(
          'Jupiter, the natural significator for children, is powerfully placed, acting as a divine shield and blessing for your lineage. ');
    } else if (jupiter.score < 40) {
      buffer.write(
          'The current placement of Jupiter is somewhat weak, which often correlates with delays or the need for more effort in conceiving. ');
    }

    // 5th House Analysis
    final fifthHouse = factors.firstWhere((f) => f.name == '5th House',
        orElse: () => ProgenyFactor(name: '', score: 0, description: ''));
    if (fifthHouse.description.contains('Saturn')) {
      buffer.write(
          'The influence of Saturn on the 5th house indicates that patience will be key, as results may be slow but stable. ');
    }
    if (fifthHouse.description.contains('Jupiter') ||
        fifthHouse.description.contains('Venus')) {
      buffer.write(
          'Benefic influences on your 5th house suggest that the children will bring happiness and grace to the family. ');
    }
    if (fifthHouse.description.contains('Ketu') ||
        fifthHouse.description.contains('Rahu')) {
      buffer.write(
          'The presence of nodal planets suggests some unconventional or unexpected developments in progeny matters. ');
    }

    // Conclusion
    if (score >= 50) {
      buffer.write(
          '\n\nIn conclusion, your chart reflects a promising and fulfilling path toward parenthood. Maintaining a healthy lifestyle and following the suggested spiritual remedies will further enhance these positive vibrations.');
    } else {
      buffer.write(
          '\n\nWhile the astrological indicators suggest hurdles, do not be discouraged. Astrological challenges are often meant to be overcome through specific remedies, perseverance, and faith.');
    }

    return buffer.toString();
  }

  ProgenyFactor _getFifthHouse(CompleteChartData chartData) {
    final lagna = (chartData.baseChart.houses.cusps[0] / 30).floor();
    final fifthHouse = (lagna + 4) % 12;

    // Check planets in 5th house
    final planetsIn5th = <Planet>[];
    for (final entry in chartData.baseChart.planets.entries) {
      final planetSign = (entry.value.position.longitude / 30).floor();
      final planetHouse = (planetSign - lagna + 12) % 12;
      if (planetHouse == fifthHouse) {
        planetsIn5th.add(entry.key);
      }
    }

    var score = 50;
    var description = '5th house has ${planetsIn5th.length} planet(s)';

    if (planetsIn5th.contains(Planet.jupiter)) {
      score += 20;
      description += ', Jupiter blessed';
    }
    if (planetsIn5th.contains(Planet.venus)) {
      score += 15;
      description += ', Venus favorable';
    }
    if (planetsIn5th.contains(Planet.saturn)) {
      score -= 20;
      description += ', Saturn delays';
    }
    if (planetsIn5th.contains(Planet.meanNode)) {
      score += 10;
      description += ', Rahu can give children';
    }
    if (planetsIn5th.contains(Planet.ketu)) {
      score -= 10;
      description += ', Ketu may cause delays';
    }

    return ProgenyFactor(
      name: '5th House',
      score: score.clamp(0, 100),
      description: description,
    );
  }

  ProgenyFactor _analyzeJupiter(CompleteChartData chartData) {
    final jupiter = chartData.baseChart.planets[Planet.jupiter];
    if (jupiter == null) {
      return ProgenyFactor(
        name: 'Jupiter',
        score: 50,
        description: 'Jupiter position not available',
      );
    }

    final signIndex = (jupiter.position.longitude / 30).floor();
    var score = 50;
    var desc = 'Jupiter in ${jupiter.position.zodiacSign}';

    // Exalted/Debilitated
    if (signIndex == 2 || signIndex == 4) {
      // Cancer, Pisces
      score += 25;
      desc += ' (Exalted)';
    } else if (signIndex == 8 || signIndex == 10) {
      // Capricorn, Aquarius
      score -= 20;
      desc += ' (Debilitated)';
    }

    // Check aspects
    // Simplified - would check actual aspects

    return ProgenyFactor(
      name: 'Jupiter',
      score: score.clamp(0, 100),
      description: desc,
    );
  }

  ProgenyFactor _analyzeVenus(CompleteChartData chartData) {
    final venus = chartData.baseChart.planets[Planet.venus];
    if (venus == null) {
      return ProgenyFactor(
        name: 'Venus',
        score: 50,
        description: 'Venus position not available',
      );
    }

    final signIndex = (venus.position.longitude / 30).floor();
    var score = 50;
    final desc = 'Venus in ${venus.position.zodiacSign}';

    if (signIndex == 0 || signIndex == 6) {
      // Aries, Libra
      score += 15;
    }

    return ProgenyFactor(
      name: 'Venus',
      score: score.clamp(0, 100),
      description: desc,
    );
  }

  ProgenyFactor _analyzeMars(CompleteChartData chartData) {
    final mars = chartData.baseChart.planets[Planet.mars];
    if (mars == null) {
      return ProgenyFactor(
        name: 'Mars',
        score: 50,
        description: 'Mars position not available',
      );
    }

    var score = 50;
    var desc = 'Mars in ${mars.position.zodiacSign}';

    // Manglik in 1, 4, 7, 8, 12 can affect progeny
    final signIndex = (mars.position.longitude / 30).floor();
    if ([0, 3, 6, 7, 11].contains(signIndex)) {
      score -= 10;
      desc += ' (Manglik position)';
    }

    return ProgenyFactor(
      name: 'Mars',
      score: score.clamp(0, 100),
      description: desc,
    );
  }

  ProgenyFactor _analyzeMoon(CompleteChartData chartData) {
    final moon = chartData.baseChart.planets[Planet.moon];
    if (moon == null) {
      return ProgenyFactor(
        name: 'Moon',
        score: 50,
        description: 'Moon position not available',
      );
    }

    var score = 50;
    final desc = 'Moon in ${moon.position.zodiacSign}';

    // Check for Chandra Mantas
    final signIndex = (moon.position.longitude / 30).floor();
    if (signIndex == 2 || signIndex == 4) {
      // Cancer, Pisces
      score += 20;
    }

    return ProgenyFactor(
      name: 'Moon',
      score: score.clamp(0, 100),
      description: desc,
    );
  }

  String _getProspects(int score) {
    if (score >= 75) return 'Excellent';
    if (score >= 60) return 'Very Good';
    if (score >= 45) return 'Good';
    if (score >= 30) return 'Moderate';
    return 'Challenged';
  }

  List<String> _getRecommendations(List<ProgenyFactor> factors) {
    final recs = <String>[];

    for (final f in factors) {
      if (f.score < 40) {
        if (f.name == 'Jupiter') {
          recs.add('Strengthen Jupiter through charitable acts on Thursdays');
        }
        if (f.name == '5th House') {
          recs.add('Consider remedies for 5th house');
        }
      }
    }

    if (recs.isEmpty) {
      recs.add('Progeny prospects appear favorable');
    }

    return recs;
  }
}

class ProgenyAnalysis {
  ProgenyAnalysis({
    required this.factors,
    required this.overallScore,
    required this.prospects,
    required this.prediction,
    required this.recommendations,
  });
  final List<ProgenyFactor> factors;
  final int overallScore;
  final String prospects;
  final String prediction;
  final List<String> recommendations;
}

class ProgenyFactor {
  ProgenyFactor({
    required this.name,
    required this.score,
    required this.description,
  });
  final String name;
  final int score;
  final String description;
}
