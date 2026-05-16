import 'package:dartx/dartx.dart';
import 'package:jyotish/jyotish.dart';

import '../core/ephemeris_manager.dart';
import '../data/models.dart';

/// Shadbala (Six-Fold Strength) Calculator
/// Uses EphemerisManager.jyotish facade for all calculations
class ShadbalaCalculator {
  static ShadbalaService? _combustionService;

  static Future<Map<Planet, double>> calculateShadbala(
    CompleteChartData chartData,
  ) async {
    final nativeResults = await EphemerisManager.jyotish.getShadbala(
      chartData.baseChart,
    );

    return nativeResults.entries
        .filter((e) => !Planet.lunarNodes.contains(e.key))
        .associate((e) => MapEntry(e.key, e.value.totalBala));
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
    final shadbala = detailedShadbala.entries
        .filter((e) => !Planet.lunarNodes.contains(e.key))
        .associate((e) => MapEntry(e.key, e.value.totalBala));

    final vimsopaka = strengthService.getAllPlanetsVimshopakBala(chart);

    final sunPos = chart.getPlanet(Planet.sun)?.longitude ?? 0.0;

    final combustion = Planet.traditionalPlanets
        .filter((p) => p != Planet.sun)
        .associateWith((planet) {
          final info = chart.getPlanet(planet);
          if (info == null) return null;
          _combustionService ??= ShadbalaService(EphemerisManager.service);
          return _combustionService!.checkCombustion(
            planet: planet,
            planetLongitude: info.longitude,
            sunLongitude: sunPos,
          );
        })
        .filterValues((v) => v != null)
        .cast<Planet, CombustionInfo>();

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
      combustion: Map<Planet, CombustionInfo>.from(combustion),
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
  final Map<Planet, double> shadbala;
  final Map<Planet, ShadbalaResult> detailedShadbala;
  final Map<Planet, VimshopakBala> vimsopaka;
  final Map<Planet, CombustionInfo> combustion;
  final List<Planet> horaLords;
}
