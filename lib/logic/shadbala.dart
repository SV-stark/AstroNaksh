import 'package:jyotish/jyotish.dart';

import '../core/ephemeris_manager.dart';
import '../data/models.dart';

/// Shadbala (Six-Fold Strength) Calculator
/// Uses EphemerisManager.jyotish facade for all calculations
class ShadbalaCalculator {
  static ShadbalaService? _combustionService;

  static Future<Map<String, double>> calculateShadbala(
    CompleteChartData chartData,
  ) async {
    final nativeResults = await EphemerisManager.jyotish.getShadbala(
      chartData.baseChart,
    );

    final shadbala = <String, double>{};

    nativeResults.forEach((planet, result) {
      if (!Planet.lunarNodes.contains(planet)) {
        shadbala[planet.displayName] = result.totalBala;
      }
    });

    return shadbala;
  }

  static Future<Map<Planet, ShadbalaResult>> calculateDetailedShadbala(
    VedicChart chart,
  ) async {
    return EphemerisManager.jyotish.getShadbala(chart);
  }

  static Future<ShadbalaScreenData> getScreenData(
    CompleteChartData chartData,
  ) async {
    final jyotish = EphemerisManager.jyotish;
    final strengthService = StrengthAnalysisService();

    final chart = chartData.baseChart;

    final detailedShadbala = await jyotish.getShadbala(chart);
    final shadbala = <String, double>{};
    detailedShadbala.forEach((planet, result) {
      if (!Planet.lunarNodes.contains(planet)) {
        shadbala[planet.displayName] = result.totalBala;
      }
    });

    final vimsopaka = strengthService.getAllPlanetsVimshopakBala(chart);

    final sunPos = chart.getPlanet(Planet.sun)?.longitude ?? 0.0;
    final combustion = <Planet, CombustionInfo>{};
    for (final planet in Planet.traditionalPlanets) {
      if (planet == Planet.sun) continue;
      final info = chart.getPlanet(planet);
      if (info != null) {
        _combustionService ??= ShadbalaService(EphemerisManager.service);
        combustion[planet] = _combustionService!.checkCombustion(
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

    final horaLords = await jyotish.calculateHoraLordsForDay(
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
  ShadbalaScreenData({
    required this.shadbala,
    required this.detailedShadbala,
    required this.vimsopaka,
    required this.combustion,
    required this.horaLords,
  });
  final Map<String, double> shadbala;
  final Map<Planet, ShadbalaResult> detailedShadbala;
  final Map<Planet, VimshopakBala> vimsopaka;
  final Map<Planet, CombustionInfo> combustion;
  final List<Planet> horaLords;
}
