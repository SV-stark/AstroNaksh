import 'package:jyotish/core.dart';
import 'package:jyotish/nadi.dart' as jn;
import 'package:jyotish/nadi.dart' show NadiChart, NadiInfo;

import '../../data/models.dart';

class NadiService {
  final jn.NadiService _jyotishNadi = const jn.NadiService();

  /// Get comprehensive Nadi analysis for a chart (including 150 Nadi Amshas)
  NadiAnalysis analyzeNadi(CompleteChartData chartData) {
    final moon = chartData.baseChart.planets[Planet.moon];
    if (moon == null) {
      return NadiAnalysis(
        nadiType: 'Unknown',
        description: 'Moon position not available',
        strength: 0,
        pada: 1,
      );
    }

    final nakshatraIndex = moon.position.nakshatraIndex;
    final nadiType = _getNadiType(nakshatraIndex);
    final strength = _calculateNadiStrength(nakshatraIndex, chartData);

    // Calculate full 150-amsha Nadi Chart from jyotish library
    NadiChart? nadiChart;
    try {
      nadiChart = _jyotishNadi.calculateNadiChart(chartData.baseChart);
    } catch (_) {}

    return NadiAnalysis(
      nadiType: nadiType,
      nakshatra: moon.position.nakshatra,
      pada: moon.position.nakshatraPada,
      strength: strength,
      description: _getNadiDescription(nadiType),
      nadiChart: nadiChart,
    );
  }

  /// Get specific 150-amsha Nadi details for a zodiac longitude
  NadiInfo getNadiAmsha(double longitude) {
    return _jyotishNadi.getNadiFromLongitude(longitude);
  }

  /// Get Nadi karmic interpretation for a specific Nadi number (1-1800)
  String getNadiInterpretation(int nadiNumber) {
    return _jyotishNadi.getNadiInterpretation(nadiNumber);
  }

  /// Identify the Nadi seed from Moon's nakshatra number and pada.
  ///
  /// Returns [NadiSeedResult] with seedNumber (1-150), nadiType, primaryNadi,
  /// and relatedNadis (±2 nadi positions).
  jn.NadiSeedResult identifyNadiSeed(int nakshatraNumber, int pada) {
    return _jyotishNadi.identifyNadiSeed(nakshatraNumber, pada);
  }

  /// Get Nadi seed analysis for a chart based on Moon position.
  ///
  /// Extracts nakshatra number and pada from the Moon, then identifies the
  /// Nadi seed with full details including related nadis.
  Map<String, dynamic> getNadiSeedAnalysis(CompleteChartData chartData) {
    final moon = chartData.baseChart.planets[Planet.moon];
    if (moon == null) {
      return {'available': false, 'error': 'Moon position not available'};
    }

    try {
      final nakshatraNumber = moon.position.nakshatraIndex + 1;
      final pada = moon.position.nakshatraPada;

      final seed = _jyotishNadi.identifyNadiSeed(nakshatraNumber, pada);

      return {
        'available': true,
        'seedNumber': seed.seedNumber,
        'nadiType': seed.nadiType.name,
        'nakshatraNumber': nakshatraNumber,
        'nakshatraName': moon.position.nakshatra,
        'pada': pada,
        'primaryNadi': seed.primaryNadi,
        'relatedNadis': seed.relatedNadis,
      };
    } catch (e) {
      return {'available': false, 'error': e.toString()};
    }
  }

  String _getNadiType(int nakshatraIndex) {
    final remainder = nakshatraIndex % 6;
    if (remainder == 0 || remainder == 5) {
      return 'Adi (Vata)';
    } else if (remainder == 1 || remainder == 4) {
      return 'Madhya (Pitta)';
    } else {
      return 'Antya (Kapha)';
    }
  }

  int _calculateNadiStrength(int nakshatraIndex, CompleteChartData chartData) {
    var strength = 50;

    final moon = chartData.baseChart.planets[Planet.moon];
    if (moon != null) {
      final signIndex = (moon.position.longitude / 30).floor();
      if (signIndex == 1) strength += 20; // Exalted
      if (signIndex == 7) strength -= 20; // Debilitated
    }

    return strength.clamp(0, 100);
  }

  String _getNadiDescription(String nadiType) {
    switch (nadiType) {
      case 'Adi (Vata)':
        return 'Air nadi. Active, restless nature. Quick decisions.';
      case 'Madhya (Pitta)':
        return 'Fire nadi. Balanced, ambitious. Medium physique.';
      case 'Antya (Kapha)':
        return 'Water nadi. Calm, steady. Strong immunity.';
      default:
        return 'Unknown nadi type';
    }
  }
}

class NadiAnalysis {
  NadiAnalysis({
    required this.nadiType,
    this.nakshatra,
    required this.pada,
    required this.strength,
    required this.description,
    this.nadiChart,
  });
  final String nadiType;
  final String? nakshatra;
  final int pada;
  final int strength;
  final String description;
  final NadiChart? nadiChart;
}
