import 'package:flutter/material.dart';
import 'package:jyotish/jyotish.dart' as j;
import '../../logic/planetary_aspect_service.dart';
import '../../core/chart_customization.dart';

/// Painter for drawing planetary aspect (drishti) lines on charts
class AspectPainter extends CustomPainter {
  final List<PlanetaryAspect> aspects;
  final Map<int, List<String>> planetsBySign;
  final int ascendantSign;
  final ChartColors colors;
  final double lineOpacity;

  AspectPainter({
    required this.aspects,
    required this.planetsBySign,
    required this.ascendantSign,
    required this.colors,
    this.lineOpacity = 0.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Build planet position map
    final planetPositions = <j.Planet, Offset>{};

    // House centers (same as NorthIndianChartPainter)
    final centers = [
      Offset(width / 2, height / 4), // 1st
      Offset(width / 4, height / 8), // 2nd
      Offset(width / 8, height / 4), // 3rd
      Offset(width / 4, height / 2), // 4th
      Offset(width / 8, height * 0.75), // 5th
      Offset(width / 4, height * 0.875), // 6th
      Offset(width / 2, height * 0.75), // 7th
      Offset(width * 0.75, height * 0.875), // 8th
      Offset(width * 0.875, height * 0.75), // 9th
      Offset(width * 0.75, height / 2), // 10th
      Offset(width * 0.875, height / 4), // 11th
      Offset(width * 0.75, height / 8), // 12th
    ];

    // Map planets to their positions
    for (int houseIndex = 0; houseIndex < 12; houseIndex++) {
      final signIndex = ((ascendantSign - 1) + houseIndex) % 12;
      final signNumber = signIndex + 1; // 1-12
      final planets = planetsBySign[signNumber] ?? [];

      if (planets.isNotEmpty) {
        // Get center of this house
        final center = centers[houseIndex];

        // Position planets in this house
        for (int i = 0; i < planets.length; i++) {
          final planetName = planets[i].toLowerCase();
          final planet = _getPlanetFromName(planetName);

          if (planet != null) {
            // Offset planets slightly so they don't all overlap
            final offsetX = (i % 3 - 1) * width / 15;
            final offsetY = (i ~/ 3 - 0.5) * height / 20;
            planetPositions[planet] = Offset(center.dx + offsetX, center.dy + offsetY);
          }
        }
      }
    }

    // Draw aspect lines
    for (final aspect in aspects) {
      final startPos = planetPositions[aspect.aspectingPlanet];
      final endPos = planetPositions[aspect.aspectedPlanet];

      if (startPos != null && endPos != null) {
        final paint = Paint()
          ..color = PlanetaryAspectService.getAspectColor(aspect.type, opacity: lineOpacity)
          ..strokeWidth = _getAspectLineWidth(aspect.type)
          ..style = PaintingStyle.stroke;

        // Draw straight line between planets
        canvas.drawLine(startPos, endPos, paint);

        // Draw small indicator at midpoint showing aspect symbol
        final midPoint = Offset((startPos.dx + endPos.dx) / 2, (startPos.dy + endPos.dy) / 2);
        _drawAspectIndicator(canvas, midPoint, aspect.type);
      }
    }
  }

  void _drawAspectIndicator(Canvas canvas, Offset position, AspectType type) {
    // Draw small circle background
    final circlePaint = Paint()
      ..color = Colors.black.withAlpha(180)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 10, circlePaint);

    // Draw aspect symbol text
    final textSpan = TextSpan(
      text: type.symbol,
      style: TextStyle(
        color: PlanetaryAspectService.getAspectColor(type),
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
    );
  }

  double _getAspectLineWidth(AspectType type) {
    // Make tighter orbs slightly thicker
    switch (type) {
      case AspectType.conjunction:
        return 2.0;
      case AspectType.opposition:
        return 2.0;
      case AspectType.trine:
        return 1.5;
      case AspectType.square:
        return 1.5;
      case AspectType.sextile:
        return 1.0;
    }
  }

  j.Planet? _getPlanetFromName(String name) {
    // Handle common planet name variations
    final normalized = name.toLowerCase().trim();

    switch (normalized) {
      case 'sun':
      case 'surya':
        return j.Planet.sun;
      case 'moon':
      case 'chandra':
        return j.Planet.moon;
      case 'mars':
      case 'mangal':
        return j.Planet.mars;
      case 'mercury':
      case 'budha':
        return j.Planet.mercury;
      case 'jupiter':
      case 'guru':
      case 'brihaspati':
        return j.Planet.jupiter;
      case 'venus':
      case 'shukra':
        return j.Planet.venus;
      case 'saturn':
      case 'shani':
        return j.Planet.saturn;
      default:
        return null;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
