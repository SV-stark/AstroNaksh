import 'package:fluent_ui/fluent_ui.dart';
import '../../core/chart_customization.dart';

class NorthIndianChartPainter extends CustomPainter {
  NorthIndianChartPainter({
    required this.planetsBySign,
    required this.ascendantSign,
    required this.colors,
    this.hoveredHouse,
    this.selectedHouse,
    this.showSigns = true,
    this.showHouseNumbers = true,
    this.transitPlanetsBySign,
  });
  final Map<int, List<String>> planetsBySign;
  final Map<int, List<String>>? transitPlanetsBySign;
  final int ascendantSign;
  final ChartColors colors;
  final int? hoveredHouse;
  final int? selectedHouse;
  final bool showSigns;
  final bool showHouseNumbers;

  Path getHousePath(int houseIndex, double width, double height) {
    final path = Path();
    final w4 = width / 4;
    final h4 = height / 4;
    final w2 = width / 2;
    final h2 = height / 2;
    final w3_4 = 3 * w4;
    final h3_4 = 3 * h4;

    switch (houseIndex) {
      case 0: // 1st House (top central diamond)
        path.moveTo(w2, h2);
        path.lineTo(w4, h4);
        path.lineTo(w2, 0);
        path.lineTo(w3_4, h4);
        path.close();
        break;
      case 1: // 2nd House (top-left triangle)
        path.moveTo(0, 0);
        path.lineTo(w2, 0);
        path.lineTo(w4, h4);
        path.close();
        break;
      case 2: // 3rd House (left-top triangle)
        path.moveTo(0, 0);
        path.lineTo(w4, h4);
        path.lineTo(0, h2);
        path.close();
        break;
      case 3: // 4th House (left central diamond)
        path.moveTo(w2, h2);
        path.lineTo(w4, h3_4);
        path.lineTo(0, h2);
        path.lineTo(w4, h4);
        path.close();
        break;
      case 4: // 5th House (left-bottom triangle)
        path.moveTo(0, height);
        path.lineTo(0, h2);
        path.lineTo(w4, h3_4);
        path.close();
        break;
      case 5: // 6th House (bottom-left triangle)
        path.moveTo(0, height);
        path.lineTo(w4, h3_4);
        path.lineTo(w2, height);
        path.close();
        break;
      case 6: // 7th House (bottom central diamond)
        path.moveTo(w2, h2);
        path.lineTo(w3_4, h3_4);
        path.lineTo(w2, height);
        path.lineTo(w4, h3_4);
        path.close();
        break;
      case 7: // 8th House (bottom-right triangle)
        path.moveTo(width, height);
        path.lineTo(w2, height);
        path.lineTo(w3_4, h3_4);
        path.close();
        break;
      case 8: // 9th House (right-bottom triangle)
        path.moveTo(width, height);
        path.lineTo(w3_4, h3_4);
        path.lineTo(width, h2);
        path.close();
        break;
      case 9: // 10th House (right central diamond)
        path.moveTo(w2, h2);
        path.lineTo(w3_4, h4);
        path.lineTo(width, h2);
        path.lineTo(w3_4, h3_4);
        path.close();
        break;
      case 10: // 11th House (right-top triangle)
        path.moveTo(width, 0);
        path.lineTo(width, h2);
        path.lineTo(w3_4, h4);
        path.close();
        break;
      case 11: // 12th House (top-right triangle)
        path.moveTo(width, 0);
        path.lineTo(w3_4, h4);
        path.lineTo(w2, 0);
        path.close();
        break;
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. Draw Highlights
    if (hoveredHouse != null) {
      final fillPaint = Paint()
        ..color = colors.houseBorder.withAlpha(20)
        ..style = PaintingStyle.fill;
      canvas.drawPath(getHousePath(hoveredHouse!, width, height), fillPaint);
    }
    if (selectedHouse != null) {
      final fillPaint = Paint()
        ..color = colors.houseBorder.withAlpha(38)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = colors.houseBorder
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final selectedPath = getHousePath(selectedHouse!, width, height);
      canvas.drawPath(selectedPath, fillPaint);
      canvas.drawPath(selectedPath, borderPaint);
    }

    final borderPaint = Paint()
      ..color = colors.houseBorder
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 2. Draw Outer Square
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), borderPaint);

    // 3. Draw Diagonals
    canvas.drawLine(const Offset(0, 0), Offset(width, height), borderPaint);
    canvas.drawLine(Offset(width, 0), Offset(0, height), borderPaint);

    // 4. Draw Inner Diamond
    canvas.drawLine(Offset(width / 2, 0), Offset(0, height / 2), borderPaint);
    canvas.drawLine(
      Offset(0, height / 2),
      Offset(width / 2, height),
      borderPaint,
    );
    canvas.drawLine(
      Offset(width / 2, height),
      Offset(width, height / 2),
      borderPaint,
    );
    canvas.drawLine(
      Offset(width, height / 2),
      Offset(width / 2, 0),
      borderPaint,
    );

    // 5. Centers & Glyph Positions
    final w4 = width / 4;
    final h4 = height / 4;
    final w2 = width / 2;
    final h2 = height / 2;

    final centers = [
      Offset(w2, h4), // 1st
      Offset(w4, h4 / 2), // 2nd
      Offset(w4 / 2, h4), // 3rd
      Offset(w4, h2), // 4th
      Offset(w4 / 2, h4 * 3), // 5th
      Offset(w4, h4 * 3.5), // 6th
      Offset(w2, h4 * 3), // 7th
      Offset(w4 * 3, h4 * 3.5), // 8th
      Offset(w4 * 3.5, h4 * 3), // 9th
      Offset(w4 * 3, h2), // 10th
      Offset(w4 * 3.5, h4), // 11th
      Offset(w4 * 3, h4 / 2), // 12th
    ];

    final glyphCenters = [
      Offset(w2, h4 * 0.35), // 1st
      Offset(w4 * 0.5, h4 * 0.5), // 2nd
      Offset(w4 * 0.3, h4 * 1.2), // 3rd
      Offset(w4 * 0.65, h2), // 4th
      Offset(w4 * 0.3, h4 * 2.8), // 5th
      Offset(w4 * 0.5, h4 * 3.5), // 6th
      Offset(w2, h4 * 3.65), // 7th
      Offset(w4 * 3.5, h4 * 3.5), // 8th
      Offset(w4 * 3.7, h4 * 2.8), // 9th
      Offset(w4 * 3.35, h2), // 10th
      Offset(w4 * 3.7, h4 * 1.2), // 11th
      Offset(w4 * 3.5, h4 * 0.5), // 12th
    ];

    // Content Drawing logic
    void drawContent(int houseIndex, Offset center, Offset glyphCenter) {
      final signIndex = ((ascendantSign - 1) + houseIndex) % 12;

      // Draw Zodiac Sign Number (standard Vedic North Indian style)
      if (showSigns) {
        final signNumber = signIndex + 1;
        final fontSize = width / 26; // Responsive font size

        final textSpan = TextSpan(
          text: '$signNumber',
          style: TextStyle(
            color: colors.planetText.withAlpha(180),
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        final offset = Offset(
          glyphCenter.dx - textPainter.width / 2,
          glyphCenter.dy - textPainter.height / 2,
        );
        textPainter.paint(canvas, offset);
      }

      // Draw Planets
      final planets = planetsBySign[signIndex + 1] ?? [];
      final transitPlanets = transitPlanetsBySign?[signIndex + 1] ?? [];
      final fontSize = width / 25; // Responsive size

      final lines = <String>[];
      if (planets.length > 3) {
        for (var i = 0; i < planets.length; i += 3) {
          lines.add(
            planets
                .sublist(i, i + 3 > planets.length ? planets.length : i + 3)
                .join(' '),
          );
        }
      } else if (planets.isNotEmpty) {
        lines.add(planets.join(' '));
      }

      double natalHeight = 0;

      if (lines.isNotEmpty) {
        final textSpan = TextSpan(
          children: lines
              .map(
                (line) => TextSpan(
                  text: '$line\n',
                  style: TextStyle(
                    color: colors.planetText,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              .toList(),
          style: const TextStyle(height: 1.2),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: width / 4);
        natalHeight = textPainter.height;

        final offset = Offset(
          center.dx - textPainter.width / 2,
          center.dy - (transitPlanets.isNotEmpty ? textPainter.height * 0.8 : textPainter.height / 3),
        );
        textPainter.paint(canvas, offset);
      }

      // Draw Transit Planets
      if (transitPlanets.isNotEmpty) {
        final tLines = <String>[];
        final cleanTransitPlanets = transitPlanets.where((p) => p != 'Asc').toList();
        if (cleanTransitPlanets.isNotEmpty) {
          if (cleanTransitPlanets.length > 3) {
            for (var i = 0; i < cleanTransitPlanets.length; i += 3) {
              tLines.add(
                cleanTransitPlanets
                    .sublist(i, i + 3 > cleanTransitPlanets.length ? cleanTransitPlanets.length : i + 3)
                    .join(' '),
              );
            }
          } else {
            tLines.add(cleanTransitPlanets.join(' '));
          }

          final tTextSpan = TextSpan(
            children: tLines
                .map(
                  (line) => TextSpan(
                    text: '$line\n',
                    style: TextStyle(
                      color: const Color(0xFF10B981), // Emerald green for transits
                      fontSize: fontSize * 0.9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
            style: const TextStyle(height: 1.2),
          );

          final tTextPainter = TextPainter(
            text: tTextSpan,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          );

          tTextPainter.layout(maxWidth: width / 4);
          final offset = Offset(
            center.dx - tTextPainter.width / 2,
            center.dy + (natalHeight > 0 ? 2 : -tTextPainter.height / 3),
          );
          tTextPainter.paint(canvas, offset);
        }
      }
    }

    for (var i = 0; i < 12; i++) {
      drawContent(i, centers[i], glyphCenters[i]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
