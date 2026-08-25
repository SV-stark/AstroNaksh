import 'package:jyotish/core.dart';
import 'package:jyotish/strength.dart';
import 'package:jyotish/systems.dart';

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

    return Map.fromEntries(
      nativeResults.entries
          .where((e) => !Planet.lunarNodes.contains(e.key))
          .map((e) => MapEntry(e.key, e.value.totalBala)),
    );
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
    final shadbala = Map<Planet, double>.fromEntries(
      detailedShadbala.entries
          .where((e) => !Planet.lunarNodes.contains(e.key))
          .map((e) => MapEntry(e.key, e.value.totalBala)),
    );

    final vimsopaka = strengthService.getAllPlanetsVimshopakBala(chart);

    final sunPos = chart.getPlanet(Planet.sun)?.longitude ?? 0.0;

    final combustion = <Planet, CombustionInfo>{};
    for (final planet in Planet.traditionalPlanets) {
      if (planet == Planet.sun) continue;
      final info = chart.getPlanet(planet);
      if (info == null) continue;
      _combustionService ??= ShadbalaService(EphemerisManager.service);
      final c = _combustionService!.checkCombustion(
        planet: planet,
        planetLongitude: info.longitude,
        sunLongitude: sunPos,
      );
      combustion[planet] = c;
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
