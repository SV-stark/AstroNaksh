import 'package:fluent_ui/fluent_ui.dart';
import '../../core/chart_customization.dart';
import 'zodiac_glyphs.dart';

class SouthIndianChartPainter extends CustomPainter {
  SouthIndianChartPainter({
    required this.planetsBySign,
    required this.ascendantSign,
    required this.colors,
    this.hoveredHouse,
    this.selectedHouse,
  });
  final Map<int, List<String>> planetsBySign;
  final int ascendantSign; // 1-12
  final ChartColors colors;
  final int? hoveredHouse;
  final int? selectedHouse;

  Rect getCellRect(int signIndex, double width, double height) {
    final cellWidth = width / 4;
    final cellHeight = height / 4;
    switch (signIndex % 12) {
      case 0: return Rect.fromLTWH(cellWidth * 1, 0, cellWidth, cellHeight);
      case 1: return Rect.fromLTWH(cellWidth * 2, 0, cellWidth, cellHeight);
      case 2: return Rect.fromLTWH(cellWidth * 3, 0, cellWidth, cellHeight);
      case 3: return Rect.fromLTWH(cellWidth * 3, cellHeight * 1, cellWidth, cellHeight);
      case 4: return Rect.fromLTWH(cellWidth * 3, cellHeight * 2, cellWidth, cellHeight);
      case 5: return Rect.fromLTWH(cellWidth * 3, cellHeight * 3, cellWidth, cellHeight);
      case 6: return Rect.fromLTWH(cellWidth * 2, cellHeight * 3, cellWidth, cellHeight);
      case 7: return Rect.fromLTWH(cellWidth * 1, cellHeight * 3, cellWidth, cellHeight);
      case 8: return Rect.fromLTWH(0, cellHeight * 3, cellWidth, cellHeight);
      case 9: return Rect.fromLTWH(0, cellHeight * 2, cellWidth, cellHeight);
      case 10: return Rect.fromLTWH(0, cellHeight * 1, cellWidth, cellHeight);
      case 11: return Rect.fromLTWH(0, 0, cellWidth, cellHeight);
      default: return Rect.zero;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final cellWidth = width / 4;
    final cellHeight = height / 4;

    // 1. Draw Highlights
    if (hoveredHouse != null) {
      final fillPaint = Paint()
        ..color = colors.houseBorder.withOpacity(0.08)
        ..style = PaintingStyle.fill;
      final idx = (ascendantSign - 1 + hoveredHouse!) % 12;
      canvas.drawRect(getCellRect(idx, width, height), fillPaint);
    }
    if (selectedHouse != null) {
      final fillPaint = Paint()
        ..color = colors.houseBorder.withOpacity(0.15)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = colors.houseBorder
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final idx = (ascendantSign - 1 + selectedHouse!) % 12;
      final rect = getCellRect(idx, width, height);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect.deflate(1.0), borderPaint);
    }

    // Grid lines paint
    final borderPaint = Paint()
      ..color = colors.houseBorder
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Outer border
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), borderPaint);

    // Inner lines
    canvas.drawLine(Offset(0, cellHeight), Offset(width, cellHeight), borderPaint);
    canvas.drawLine(Offset(0, cellHeight * 2), Offset(cellWidth, cellHeight * 2), borderPaint);
    canvas.drawLine(Offset(cellWidth * 3, cellHeight * 2), Offset(width, cellHeight * 2), borderPaint);
    canvas.drawLine(Offset(0, cellHeight * 3), Offset(width, cellHeight * 3), borderPaint);

    canvas.drawLine(Offset(cellWidth, 0), Offset(cellWidth, height), borderPaint);
    canvas.drawLine(Offset(cellWidth * 2, 0), Offset(cellWidth * 2, cellHeight), borderPaint);
    canvas.drawLine(Offset(cellWidth * 2, cellHeight * 3), Offset(cellWidth * 2, height), borderPaint);
    canvas.drawLine(Offset(cellWidth * 3, 0), Offset(cellWidth * 3, height), borderPaint);

    final cellOffsets = [
      Offset(cellWidth * 1.5, cellHeight * 0.5), // Aries
      Offset(cellWidth * 2.5, cellHeight * 0.5), // Taurus
      Offset(cellWidth * 3.5, cellHeight * 0.5), // Gemini
      Offset(cellWidth * 3.5, cellHeight * 1.5), // Cancer
      Offset(cellWidth * 3.5, cellHeight * 2.5), // Leo
      Offset(cellWidth * 3.5, cellHeight * 3.5), // Virgo
      Offset(cellWidth * 2.5, cellHeight * 3.5), // Libra
      Offset(cellWidth * 1.5, cellHeight * 3.5), // Scorpio
      Offset(cellWidth * 0.5, cellHeight * 3.5), // Sagittarius
      Offset(cellWidth * 0.5, cellHeight * 2.5), // Capricorn
      Offset(cellWidth * 0.5, cellHeight * 1.5), // Aquarius
      Offset(cellWidth * 0.5, cellHeight * 0.5), // Pisces
    ];

    for (var i = 0; i < 12; i++) {
      // 2. Draw Zodiac Glyph Watermark
      final rect = getCellRect(i, width, height);
      final center = Offset(rect.left + cellWidth / 2, rect.top + cellHeight / 2);
      final glyphSize = cellWidth * 0.55;
      ZodiacGlyphs.drawGlyph(
        canvas,
        i,
        center,
        glyphSize,
        colors.planetText.withOpacity(0.12),
        strokeWidth: 1.2,
      );

      // 3. Draw Planets
      final planets = planetsBySign[i + 1] ?? [];
      final displayList = List<String>.from(planets);

      if (i == (ascendantSign - 1)) {
        displayList.insert(0, 'Asc');
      }

      if (displayList.isEmpty) continue;

      final text = displayList.join(' ');
      final fontSize = cellWidth / 8;

      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: colors.planetText,
          fontSize: fontSize.clamp(8.0, 16.0),
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: cellWidth - 4);
      textPainter.paint(
        canvas,
        Offset(
          cellOffsets[i].dx - textPainter.width / 2,
          cellOffsets[i].dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
