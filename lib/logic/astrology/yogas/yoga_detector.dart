import 'package:jyotish/jyotish.dart';
import '../../../data/models.dart';

/// Base interface for all astrological yoga and dosha detectors.
/// This allows decomposing the monolithic YogaDoshaAnalyzer into focused strategy classes.
abstract class YogaDetector {
  /// Unique identifier for the yoga/dosha
  String get id;

  /// Display name
  String get name;

  /// Description of the yoga's effects and conditions
  String get description;

  /// Planets primarily involved in this yoga
  List<Planet> get keyPlanets;

  /// Detect if this yoga exists in the chart and calculate its strength/cancellation.
  BhangaResult detect(CompleteChartData chart);
}
