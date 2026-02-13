import 'package:jyotish/jyotish.dart';
import '../../data/models.dart';
import '../core/ephemeris_manager.dart';

class NadiService {
  /// Get Nadi analysis for a chart
  NadiAnalysis analyzeNadi(CompleteChartData chartData) {
    final moon = chartData.baseChart.planets[Planet.moon];
    if (moon == null) {
      return NadiAnalysis(
        nadiType: 'Unknown',
        description: 'Moon position not available',
        strength: 0,
      );
    }

    final nakshatraIndex = moon.position.nakshatraIndex;
    final nadiType = _getNadiType(nakshatraIndex);
    final strength = _calculateNadiStrength(nakshatraIndex, chartData);

    return NadiAnalysis(
      nadiType: nadiType,
      nakshatra: moon.position.nakshatra,
      pada: moon.position.pada,
      strength: strength,
      description: _getNadiDescription(nadiType),
    );
  }

  String _getNadiType(int nakshatraIndex) {
    final pattern = ['Adi (Vata)', 'Madhya (Pitta)', 'Antya (Kapha)'];
    return pattern[nakshatraIndex % 3];
  }

  int _calculateNadiStrength(int nakshatraIndex, CompleteChartData chartData) {
    int strength = 50;
    
    // Check Moon's strength
    final moon = chartData.baseChart.planets[Planet.moon];
    if (moon != null) {
      // Exalted Moon (in Taurus) = strong
      final signIndex = (moon.position.longitude / 30).floor();
      if (signIndex == 1) strength += 20; // Exalted
      if (signIndex == 7) strength -= 20; // Debilitated
    }
    
    // Check aspects on Moon
    // This is simplified - library would do more detailed analysis
    
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
  final String nadiType;
  final String? nakshatra;
  final int pada;
  final int strength;
  final String description;

  NadiAnalysis({
    required this.nadiType,
    this.nakshatra,
    required this.pada,
    required this.strength,
    required this.description,
  });
}
