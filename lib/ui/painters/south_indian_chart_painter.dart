import 'package:flutter/material.dart';

class SouthIndianChartPainter extends CustomPainter {
  final Map<int, List<String>> planetsBySign; // Key: Sign Index (0-11)
  final int ascendantSign; // 1-12
  final Color lineColor;
  final Color textColor;

  SouthIndianChartPainter({
    required this.planetsBySign,
    required this.ascendantSign,
    this.lineColor = Colors.white,
    this.textColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;

    final cellWidth = width / 4;
    final cellHeight = height / 4;

    // Draw grid
    // Outer border
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

    // Inner lines
    // Rows
    canvas.drawLine(Offset(0, cellHeight), Offset(width, cellHeight), paint);
    canvas.drawLine(
      Offset(0, cellHeight * 2),
      Offset(cellWidth, cellHeight * 2),
      paint,
    );
    canvas.drawLine(
      Offset(cellWidth * 3, cellHeight * 2),
      Offset(width, cellHeight * 2),
      paint,
    );
    canvas.drawLine(
      Offset(0, cellHeight * 3),
      Offset(width, cellHeight * 3),
      paint,
    );

    // Cols
    canvas.drawLine(Offset(cellWidth, 0), Offset(cellWidth, height), paint);
    canvas.drawLine(
      Offset(cellWidth * 2, 0),
      Offset(cellWidth * 2, cellHeight),
      paint,
    );
    canvas.drawLine(
      Offset(cellWidth * 2, cellHeight * 3),
      Offset(cellWidth * 2, height),
      paint,
    );
    canvas.drawLine(
      Offset(cellWidth * 3, 0),
      Offset(cellWidth * 3, height),
      paint,
    );

    // Fixed South Indian Layout (Sign positions are fixed)
    // 0: Aries (Top row, 2nd)
    // 1: Taurus (Top row, 3rd)
    // 2: Gemini (Top row, 4th)
    // 3: Cancer (Right col, 2nd)
    // 4: Leo (Right col, 3rd)
    // 5: Virgo (Bottom row, 4th)
    // 6: Libra (Bottom row, 3rd)
    // 7: Scorpio (Bottom row, 2nd)
    // 8: Sagittarius (Bottom row, 1st)
    // 9: Capricorn (Left col, 3rd)
    // 10: Aquarius (Left col, 2nd)
    // 11: Pisces (Top row, 1st)

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

    for (int i = 0; i < 12; i++) {
      final planets = planetsBySign[i] ?? [];
      final displayList = List<String>.from(planets);

      // Mark Ascendant
      // ascendantSign is 1-12. Index is ascendantSign - 1.
      if (i == (ascendantSign - 1)) {
        displayList.insert(0, "Asc"); // Or Lagna
      }

      if (displayList.isEmpty) continue;

      final text = displayList.join(' ');

      final textSpan = TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: cellWidth);
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
