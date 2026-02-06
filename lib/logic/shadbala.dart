import 'package:jyotish/jyotish.dart';
import '../data/models.dart';
import '../core/ephemeris_manager.dart';

/// Shadbala (Six-Fold Strength) Calculator
/// Wraps the library's native ShadbalaService
class ShadbalaCalculator {
  static ShadbalaService? _service;

  /// Calculate complete Shadbala for all planets
  static Future<Map<String, double>> calculateShadbala(
    CompleteChartData chartData,
  ) async {
    _service ??= ShadbalaService(EphemerisManager.service);

    // Use the native library service
    final nativeResults = await _service!.calculateShadbala(
      chartData.baseChart,
    );

    final Map<String, double> shadbala = {};

    // Map native results to the format expected by the UI
    nativeResults.forEach((planet, result) {
      // Library includes nodes, but traditional Shadbala is for 7 planets
      if (!Planet.lunarNodes.contains(planet)) {
        shadbala[planet.displayName] = result.totalBala;
      }
    });

    return shadbala;
  }

  /// Get detailed Shadbala results if needed
  static Future<Map<Planet, ShadbalaResult>> calculateDetailedShadbala(
    VedicChart chart,
  ) async {
    _service ??= ShadbalaService(EphemerisManager.service);
    return await _service!.calculateShadbala(chart);
  }
}
