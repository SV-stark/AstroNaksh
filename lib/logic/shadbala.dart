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

  /// Get comprehensive screen data combining Shadbala, Vimsopaka, Combustion, and Hora Lords
  static Future<ShadbalaScreenData> getScreenData(
    CompleteChartData chartData,
  ) async {
    _service ??= ShadbalaService(EphemerisManager.service);
    final strengthService = StrengthAnalysisService();

    final chart = chartData.baseChart;

    final detailedShadbala = await _service!.calculateShadbala(chart);
    final Map<String, double> shadbala = {};
    detailedShadbala.forEach((planet, result) {
      if (!Planet.lunarNodes.contains(planet)) {
        shadbala[planet.displayName] = result.totalBala;
      }
    });

    final vimsopaka = strengthService.getAllPlanetsVimshopakBala(chart);

    final sunPos = chart.getPlanet(Planet.sun)?.longitude ?? 0.0;
    final Map<Planet, CombustionInfo> combustion = {};
    for (final planet in Planet.traditionalPlanets) {
      if (planet == Planet.sun) continue;
      final info = chart.getPlanet(planet);
      if (info != null) {
        // Speed is not readily available on VedicPlanetInfo in some implementations,
        // we omit it or pass 0. By default it assumes direct motion unless speed < 0.
        combustion[planet] = _service!.checkCombustion(
          planet: planet,
          planetLongitude: info.longitude,
          sunLongitude: sunPos,
        );
      }
    }

    final location = GeographicLocation(
      latitude: chart.latitude,
      longitude: chart.longitudeCoord,
      altitude: 0,
    );

    final horaLords = await _service!.calculateHoraLordsForDay(
      date: chart.dateTime,
      location: location,
    );

    return ShadbalaScreenData(
      shadbala: shadbala,
      detailedShadbala: detailedShadbala,
      vimsopaka: vimsopaka,
      combustion: combustion,
      horaLords: horaLords,
    );
  }
}

class ShadbalaScreenData {
  final Map<String, double> shadbala;
  final Map<Planet, ShadbalaResult> detailedShadbala;
  final Map<Planet, VimshopakBala> vimsopaka;
  final Map<Planet, CombustionInfo> combustion;
  final List<Planet> horaLords;

  ShadbalaScreenData({
    required this.shadbala,
    required this.detailedShadbala,
    required this.vimsopaka,
    required this.combustion,
    required this.horaLords,
  });
}
