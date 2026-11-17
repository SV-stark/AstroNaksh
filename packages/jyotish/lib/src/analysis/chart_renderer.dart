import 'package:flutter/widgets.dart';

import 'package:jyotish/src/models/planet.dart';
import 'package:jyotish/src/models/vedic_chart.dart';
import 'package:jyotish/src/analysis/chart_svg_renderer.dart';

export 'package:jyotish/src/analysis/chart_svg_renderer.dart';

/// A Flutter [CustomPainter] that draws a traditional South Indian style Rashi chart.
class SouthIndianChartPainter extends CustomPainter {
  /// The vedic chart data.
  final VedicChart chart;

  /// Line and border paint color.
  final Color strokeColor;

  /// Text color for signs and planet names.
  final Color textColor;

  /// Text color for labels/sign titles.
  final Color labelColor;

  /// Color used to highlight the Ascendant.
  final Color ascendantColor;

  SouthIndianChartPainter({
    required this.chart,
    this.strokeColor = const Color(0xFF1E293B),
    this.textColor = const Color(0xFF0F172A),
    this.labelColor = const Color(0xFF64748B),
    this.ascendantColor = const Color(0xFFF59E0B),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw main frame outer boundary
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 4x4 Grid paths
    final stepX = size.width / 4;
    final stepY = size.height / 4;

    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(i * stepX, 0),
        Offset(i * stepX, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, i * stepY),
        Offset(size.width, i * stepY),
        paint,
      );
    }

    // Highlight center box
    paint.strokeWidth = 3.0;
    canvas.drawRect(Rect.fromLTWH(stepX, stepY, stepX * 2, stepY * 2), paint);

    // Coordinate mapping for South Indian Signs
    final gridCoords = [
      Offset(1 * stepX, 0 * stepY), // Aries (0)
      Offset(2 * stepX, 0 * stepY), // Taurus (1)
      Offset(3 * stepX, 0 * stepY), // Gemini (2)
      Offset(3 * stepX, 1 * stepY), // Cancer (3)
      Offset(3 * stepX, 2 * stepY), // Leo (4)
      Offset(3 * stepX, 3 * stepY), // Virgo (5)
      Offset(2 * stepX, 3 * stepY), // Libra (6)
      Offset(1 * stepX, 3 * stepY), // Scorpio (7)
      Offset(0 * stepX, 3 * stepY), // Sagittarius (8)
      Offset(0 * stepX, 2 * stepY), // Capricorn (9)
      Offset(0 * stepX, 1 * stepY), // Aquarius (10)
      Offset(0 * stepX, 0 * stepY), // Pisces (11)
    ];

    final signAbbr = [
      'Ar',
      'Ta',
      'Ge',
      'Ca',
      'Le',
      'Vi',
      'Li',
      'Sc',
      'Sa',
      'Cp',
      'Aq',
      'Pi',
    ];

    // Map each planet to its zodiac sign
    final planetsInSign = List.generate(12, (_) => <String>[]);
    for (final info in chart.planets.values) {
      final signIndex = (info.longitude / 30).floor() % 12;
      planetsInSign[signIndex].add(_getAbbreviation(info.planet));
    }
    final rahuSign = (chart.rahu.longitude / 30).floor() % 12;
    planetsInSign[rahuSign].add('Ra');
    final ketuSign = (chart.ketu.longitude / 30).floor() % 12;
    planetsInSign[ketuSign].add('Ke');

    final ascSign = (chart.ascendant / 30).floor() % 12;

    // Draw info inside sign cells
    for (var rashiIdx = 0; rashiIdx < 12; rashiIdx++) {
      final offset = gridCoords[rashiIdx];

      // Draw sign label
      final textPainter = TextPainter(
        text: TextSpan(
          text: signAbbr[rashiIdx],
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, offset + const Offset(6, 6));

      // Draw ASC marker
      if (rashiIdx == ascSign) {
        final ascPainter = TextPainter(
          text: TextSpan(
            text: 'ASC',
            style: TextStyle(
              color: ascendantColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        ascPainter.paint(canvas, offset + Offset(stepX - 30, 6));
      }

      // Draw planets
      final plList = planetsInSign[rashiIdx];
      var py = offset.dy + 26.0;
      for (var pIdx = 0; pIdx < plList.length; pIdx += 2) {
        final pair = plList
            .sublist(pIdx, pIdx + 2 > plList.length ? plList.length : pIdx + 2)
            .join(' ');
        final planetsPainter = TextPainter(
          text: TextSpan(
            text: pair,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        planetsPainter.paint(canvas, Offset(offset.dx + 8, py));
        py += 14.0;
      }
    }

    // Write Rashi text in the center
    final centerTitlePainter = TextPainter(
      text: TextSpan(
        text: 'RASHI CHART',
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    centerTitlePainter.paint(
      canvas,
      Offset(
        size.width / 2 - centerTitlePainter.width / 2,
        size.height / 2 - 25,
      ),
    );

    final centerSubPainter = TextPainter(
      text: TextSpan(
        text: 'Lagna: ${chart.houses.ascendantSign}',
        style: TextStyle(color: labelColor, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    centerSubPainter.paint(
      canvas,
      Offset(size.width / 2 - centerSubPainter.width / 2, size.height / 2 + 5),
    );
  }

  String _getAbbreviation(Planet planet) {
    return switch (planet) {
      Planet.sun => 'Su',
      Planet.moon => 'Mo',
      Planet.mars => 'Ma',
      Planet.mercury => 'Me',
      Planet.jupiter => 'Ju',
      Planet.venus => 'Ve',
      Planet.saturn => 'Sa',
      Planet.meanNode || Planet.trueNode => 'Ra',
      Planet.ketu => 'Ke',
      _ => planet.displayName.substring(0, 2),
    };
  }

  @override
  bool shouldRepaint(covariant SouthIndianChartPainter oldDelegate) {
    return oldDelegate.chart != chart ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.ascendantColor != ascendantColor;
  }
}

/// A Flutter [CustomPainter] that draws a traditional North Indian style diamond chart.
class NorthIndianChartPainter extends CustomPainter {
  /// The vedic chart data.
  final VedicChart chart;

  /// Line and border paint color.
  final Color strokeColor;

  /// Text color for sign numbers and planet names.
  final Color textColor;

  /// Text color for labels/sign titles.
  final Color labelColor;

  /// Color used to highlight the Ascendant.
  final Color ascendantColor;

  NorthIndianChartPainter({
    required this.chart,
    this.strokeColor = const Color(0xFF1E293B),
    this.textColor = const Color(0xFF0F172A),
    this.labelColor = const Color(0xFF64748B),
    this.ascendantColor = const Color(0xFFF59E0B),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw main frame outer boundary
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Draw Diagonals
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // Draw Inner Diamond
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas.drawPath(path, paint);

    // Define center points for each of the 12 houses to place text relative to size
    final stepX = size.width / 500.0;
    final stepY = size.height / 500.0;
    final centers = [
      Offset(250.0 * stepX, 120.0 * stepY), // House 1
      Offset(120.0 * stepX, 60.0 * stepY), // House 2
      Offset(60.0 * stepX, 120.0 * stepY), // House 3
      Offset(125.0 * stepX, 250.0 * stepY), // House 4
      Offset(60.0 * stepX, 380.0 * stepY), // House 5
      Offset(120.0 * stepX, 440.0 * stepY), // House 6
      Offset(250.0 * stepX, 380.0 * stepY), // House 7
      Offset(380.0 * stepX, 440.0 * stepY), // House 8
      Offset(440.0 * stepX, 380.0 * stepY), // House 9
      Offset(375.0 * stepX, 250.0 * stepY), // House 10
      Offset(440.0 * stepX, 120.0 * stepY), // House 11
      Offset(380.0 * stepX, 60.0 * stepY), // House 12
    ];

    final ascSign = (chart.ascendant / 30).floor() % 12;

    for (var h = 1; h <= 12; h++) {
      final center = centers[h - 1];
      final signNumber = ((ascSign + h - 1) % 12) + 1;

      // Draw sign number
      final numPainter = TextPainter(
        text: TextSpan(
          text: '$signNumber',
          style: TextStyle(
            color: labelColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      numPainter.paint(canvas, center - Offset(numPainter.width / 2, 22));

      // Get planets in this house
      final planetsInHouse = chart
          .getPlanetsInHouse(h)
          .map((info) => _getAbbreviation(info.planet))
          .toList();
      final rahuHouse = chart.houses.getHouseForLongitude(chart.rahu.longitude);
      if (rahuHouse == h) planetsInHouse.add('Ra');
      final ketuHouse = chart.houses.getHouseForLongitude(chart.ketu.longitude);
      if (ketuHouse == h) planetsInHouse.add('Ke');

      // Draw ASC
      if (h == 1) {
        final ascPainter = TextPainter(
          text: TextSpan(
            text: 'ASC',
            style: TextStyle(
              color: ascendantColor,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        ascPainter.paint(canvas, center - Offset(ascPainter.width / 2, 34));
      }

      // Draw planets
      if (planetsInHouse.isNotEmpty) {
        var py = center.dy;
        for (var pIdx = 0; pIdx < planetsInHouse.length; pIdx += 3) {
          final chunk = planetsInHouse
              .sublist(
                pIdx,
                pIdx + 3 > planetsInHouse.length
                    ? planetsInHouse.length
                    : pIdx + 3,
              )
              .join(' ');
          final plPainter = TextPainter(
            text: TextSpan(
              text: chunk,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          plPainter.paint(canvas, Offset(center.dx - plPainter.width / 2, py));
          py += 13.0;
        }
      }
    }
  }

  String _getAbbreviation(Planet planet) {
    return switch (planet) {
      Planet.sun => 'Su',
      Planet.moon => 'Mo',
      Planet.mars => 'Ma',
      Planet.mercury => 'Me',
      Planet.jupiter => 'Ju',
      Planet.venus => 'Ve',
      Planet.saturn => 'Sa',
      Planet.meanNode || Planet.trueNode => 'Ra',
      Planet.ketu => 'Ke',
      _ => planet.displayName.substring(0, 2),
    };
  }

  @override
  bool shouldRepaint(covariant NorthIndianChartPainter oldDelegate) {
    return oldDelegate.chart != chart ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.labelColor != labelColor ||
        oldDelegate.ascendantColor != ascendantColor;
  }
}

/// A convenient Flutter [Widget] for rendering Vedic astrology charts.
class VedicChartView extends StatelessWidget {
  /// The Vedic chart data.
  final VedicChart chart;

  /// Rendering style (North Indian diamond or South Indian grid).
  final ChartStyle style;

  /// Whether to render using dark theme colors.
  final bool darkTheme;

  /// Size of the chart widget.
  final Size size;

  /// Line and border paint color override.
  final Color? strokeColor;

  /// Text color for signs and planet names override.
  final Color? textColor;

  /// Text color for labels/sign titles override.
  final Color? labelColor;

  /// Color used to highlight the Ascendant override.
  final Color? ascendantColor;

  const VedicChartView({
    super.key,
    required this.chart,
    this.style = ChartStyle.northIndian,
    this.darkTheme = false,
    this.size = const Size(350, 350),
    this.strokeColor,
    this.textColor,
    this.labelColor,
    this.ascendantColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStroke =
        strokeColor ??
        (darkTheme ? const Color(0xFFFFFFFF) : const Color(0xFF1E293B));
    final effectiveText =
        textColor ??
        (darkTheme ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A));
    final effectiveLabel =
        labelColor ??
        (darkTheme ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
    final effectiveAsc = ascendantColor ?? const Color(0xFFF59E0B);

    final painter = style == ChartStyle.northIndian
        ? NorthIndianChartPainter(
            chart: chart,
            strokeColor: effectiveStroke,
            textColor: effectiveText,
            labelColor: effectiveLabel,
            ascendantColor: effectiveAsc,
          )
        : SouthIndianChartPainter(
            chart: chart,
            strokeColor: effectiveStroke,
            textColor: effectiveText,
            labelColor: effectiveLabel,
            ascendantColor: effectiveAsc,
          );

    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(painter: painter, size: size),
    );
  }
}
