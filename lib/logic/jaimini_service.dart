import 'package:astronaksh/core/ephemeris_manager.dart';
import 'package:jyotish/jyotish.dart';
import '../../data/models.dart';

class JaiminiAnalysisService {
  final DivisionalChartService _divService = DivisionalChartService();

  JaiminiAnalysis getJaiminiAnalysis(CompleteChartData chartData) {
    final atmakaraka = getAtmakaraka(chartData);
    final karakamsa = getKarakamsa(chartData);
    final rashiDrishti = getRashiDrishti(chartData);
    final arudhaPadas = getArudhaPadas(chartData);
    final arudhaLagna = getArudhaLagna(chartData);
    final upapada = getUpapada(chartData);
    final allArgalas = getAllArgalas(chartData);

    return JaiminiAnalysis(
      atmakaraka: atmakaraka,
      karakamsa: karakamsa,
      rashiDrishti: rashiDrishti,
      arudhaPadas: arudhaPadas,
      arudhaLagna: arudhaLagna,
      upapada: upapada,
      argalas: allArgalas,
    );
  }

  /// Get Atmakaraka - planet with highest degree
  Planet getAtmakaraka(CompleteChartData chartData) {
    return EphemerisManager.jyotish.getAtmakaraka(chartData.baseChart);
  }

  /// Get Karakamsa - AK in Navamsa
  KarakamsaInfo getKarakamsa(CompleteChartData chartData) {
    final rashiChart = chartData.baseChart;
    final navamsa = chartData.divisionalCharts['D-9'];
    final navamsaChart = (navamsa != null)
        ? _divService.calculateDivisionalChart(
            rashiChart,
            DivisionalChartType.d9,
          )
        : _divService.calculateDivisionalChart(
            rashiChart,
            DivisionalChartType.d9,
          );

    return EphemerisManager.jyotish.getKarakamsa(
      rashiChart: rashiChart,
      navamsaChart: navamsaChart,
    );
  }

  /// Calculate Rashi Drishti (Sign Aspects - Jaimini)
  List<RashiDrishtiInfo> getRashiDrishti(CompleteChartData chartData) {
    return EphemerisManager.jyotish.getRashiDrishti(chartData.baseChart);
  }

  /// Calculate all Arudha Padas
  ArudhaPadaResult getArudhaPadas(CompleteChartData chartData) {
    return EphemerisManager.jyotish.getArudhaPadas(chartData.baseChart);
  }

  /// Calculate Arudha Lagna (AL)
  ArudhaPadaInfo getArudhaLagna(CompleteChartData chartData) {
    return EphemerisManager.jyotish.getArudhaLagna(chartData.baseChart);
  }

  /// Calculate Upapada (UL) - for spouse analysis
  ArudhaPadaInfo getUpapada(CompleteChartData chartData) {
    return EphemerisManager.jyotish.getUpapada(chartData.baseChart);
  }

  /// Calculate all Argalas for all houses
  Map<int, List<ArgalaInfo>> getAllArgalas(CompleteChartData chartData) {
    return EphemerisManager.jyotish.getAllArgalas(chartData.baseChart);
  }

  /// Calculate Argalas for a specific house
  List<ArgalaInfo> getArgalaForHouse(CompleteChartData chartData, int house) {
    return EphemerisManager.jyotish.getArgalaForHouse(
      chartData.baseChart,
      house,
    );
  }
}

class JaiminiAnalysis {
  final Planet atmakaraka;
  final KarakamsaInfo karakamsa;
  final List<RashiDrishtiInfo> rashiDrishti;
  final ArudhaPadaResult arudhaPadas;
  final ArudhaPadaInfo arudhaLagna;
  final ArudhaPadaInfo upapada;
  final Map<int, List<ArgalaInfo>> argalas;

  JaiminiAnalysis({
    required this.atmakaraka,
    required this.karakamsa,
    required this.rashiDrishti,
    required this.arudhaPadas,
    required this.arudhaLagna,
    required this.upapada,
    required this.argalas,
  });
}
