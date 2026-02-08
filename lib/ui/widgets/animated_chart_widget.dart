import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';
import '../../core/ephemeris_manager.dart';

import '../../data/models.dart';
import 'chart_widget.dart' as chart_widget;

/// Animated chart widget for real-time planetary motion visualization
/// Shows planets moving as time changes with smooth animations
class AnimatedChartWidget extends StatefulWidget {
  final CompleteChartData chartData;
  final chart_widget.ChartStyle style;
  final double size;
  final DateTime currentDate;
  final bool showAspects;
  final bool enableAnimation;
  final Duration animationDuration;

  const AnimatedChartWidget({
    super.key,
    required this.chartData,
    required this.style,
    required this.size,
    required this.currentDate,
    this.showAspects = false,
    this.enableAnimation = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedChartWidget> createState() => _AnimatedChartWidgetState();
}

class _AnimatedChartWidgetState extends State<AnimatedChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Map<int, List<String>> _previousPlanets = {};
  Map<int, List<String>> _currentPlanets = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _updatePlanetsForDate(widget.currentDate);
  }

  @override
  void didUpdateWidget(covariant AnimatedChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currentDate != widget.currentDate) {
      _previousPlanets = Map.from(_currentPlanets);
      _updatePlanetsForDate(widget.currentDate);

      if (widget.enableAnimation) {
        _controller.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Update planetary positions for a specific date using Ephemeris
  Future<void> _updatePlanetsForDate(DateTime date) async {
    if (!mounted) return;

    try {
      // Get the Ephemeris Service
      final ephemerisService = EphemerisManager.service;

      // Use the location from the base chart if available, otherwise default
      // Note: In a real app, you might want to pass the location specifically
      // or use the chart's stored location.
      // The base chart likely has location strings, but we need GeographicLocation.
      // For animation purposes, valid lat/long matters less than time for *relative* movement,
      // but essential for Ascendant.
      // We'll assume a default or try to parse if needed, but for now,
      // let's use the chart's location if we can access it, or a default.
      // The `CompleteChartData` doesn't expose `GeographicLocation` directly easily
      // without parsing.
      // However, for planetary *longitudes* (Sidereal), location has minimal effect
      // (parallax is small), so 0,0 is acceptable for animation updates
      // if we stick to geocentric.
      final defaultLocation = GeographicLocation(latitude: 0, longitude: 0);

      final newPlanets = <int, List<String>>{};
      for (int i = 0; i < 12; i++) {
        newPlanets[i] = [];
      }

      // Calculate for each supported planet
      for (final planet in [
        Planet.sun,
        Planet.moon,
        Planet.mars,
        Planet.mercury,
        Planet.jupiter,
        Planet.venus,
        Planet.saturn,
        Planet.meanNode, // Rahu
      ]) {
        // Calculate tropical position
        final pos = await ephemerisService.calculatePlanetPosition(
          planet: planet,
          dateTime: date,
          location: defaultLocation,
          flags: CalculationFlags.sidereal(SiderealMode.lahiri), // Using Lahiri
        );

        final sign = (pos.longitude / 30).floor() % 12;
        String planetName = planet.name;
        // Capitalize
        planetName = planetName[0].toUpperCase() + planetName.substring(1);
        if (planet == Planet.meanNode) planetName = 'Rahu';

        newPlanets[sign]?.add(planetName);

        // Handle Ketu (Opposite to Rahu)
        if (planet == Planet.meanNode) {
          final ketuLong = (pos.longitude + 180) % 360;
          final ketuSign = (ketuLong / 30).floor() % 12;
          newPlanets[ketuSign]?.add('Ketu');
        }
      }

      if (mounted) {
        setState(() {
          _currentPlanets = newPlanets;
        });
      }
    } catch (e) {
      debugPrint('Error updating planets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Interpolate between previous and current positions
        final interpolatedPlanets =
            widget.enableAnimation && _controller.isAnimating
            ? _interpolatePlanets(
                _previousPlanets,
                _currentPlanets,
                _animation.value,
              )
            : _currentPlanets;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Base chart with interpolated positions
            chart_widget.ChartWidget(
              planetsBySign: interpolatedPlanets,
              ascendantSign: ((widget.chartData.baseChart.ascendant.sign) + 1)
                  .toInt(),
              style: widget.style,
              size: widget.size,
              showAspects: widget.showAspects,
            ),

            // Conjunction indicator overlay
            if (_hasConjunction(interpolatedPlanets))
              Positioned(top: 8, right: 8, child: _buildConjunctionBadge()),

            // Date indicator overlay
            Positioned(bottom: 8, left: 8, child: _buildDateBadge()),
          ],
        );
      },
    );
  }

  /// Interpolate between two planetary position maps
  Map<int, List<String>> _interpolatePlanets(
    Map<int, List<String>> previous,
    Map<int, List<String>> current,
    double t,
  ) {
    // For simplicity, we'll just return current positions
    // In a full implementation, you could animate planets moving between houses
    return current;
  }

  /// Check if there are any conjunctions (multiple planets in same sign)
  bool _hasConjunction(Map<int, List<String>> planets) {
    for (final entry in planets.entries) {
      if (entry.value.length >= 2) {
        return true;
      }
    }
    return false;
  }

  /// Build conjunction indicator badge
  Widget _buildConjunctionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.warning, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'Conjunction!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build date indicator badge
  Widget _buildDateBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _formatDate(widget.currentDate),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontFamily: 'Consolas',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Extension for handling planet position animations
extension PlanetPositionAnimation on Map<int, List<String>> {
  /// Get animated position for a planet
  double? getAnimatedLongitude(String planet, double animationValue) {
    // This would be used for more complex interpolation
    // Currently simplified
    for (final entry in entries) {
      if (entry.value.contains(planet)) {
        return entry.key * 30.0; // Each sign is 30 degrees
      }
    }
    return null;
  }
}
