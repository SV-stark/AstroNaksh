import 'package:flutter/material.dart';

class NorthIndianChartPainter extends CustomPainter {
  final Map<int, List<String>> planetsBySign; // Key: Sign Index (0-11)
  final int ascendantSign; // 1-12
  final Color lineColor;
  final Color textColor;

  NorthIndianChartPainter({
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

    // Draw the outer square
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

    // Draw diagonals
    canvas.drawLine(Offset(0, 0), Offset(width, height), paint);
    canvas.drawLine(Offset(width, 0), Offset(0, height), paint);

    // Draw diamonds (midpoints)
    final path = Path()
      ..moveTo(width / 2, 0)
      ..lineTo(width, height / 2)
      ..lineTo(width / 2, height)
      ..lineTo(0, height / 2)
      ..close();
    canvas.drawPath(path, paint);

    // Helper to draw text
    void drawContent(int houseIndex, Offset center) {
      // Calculate Sign for this house
      // House 1 (index 0) = Ascendant Sign
      // Sign indices are 0-11
      // AscendantSign is 1-based (1..12).
      // So if Ascendant is 1 (Aries), House 1 (index 0) should be Sign 0 (Aries).
      // Index = (Ascendant - 1 + HouseIndex) % 12
      final signIndex = ((ascendantSign - 1) + houseIndex) % 12;
      final signNumber = signIndex + 1; // 1-12

      // 1. Draw Sign Number (Small, secondary color)
      final signSpan = TextSpan(
        text: "$signNumber\n",
        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 10),
      );

      // 2. Draw Planets
      final planets = planetsBySign[signIndex] ?? [];
      // Combine planets with space
      final planetText = planets.join(' ');

      final planetSpan = TextSpan(
        text: planetText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );

      final textSpan = TextSpan(
        children: [signSpan, planetSpan],
        style: TextStyle(height: 1.2),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: width / 4);
      final offset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }

    // Positions for 12 houses (Fixed Layout)
    // House 1 (Top Diamond)
    drawContent(0, Offset(width * 0.5, height * 0.25));
    // House 2 (Top Left Triangle)
    drawContent(1, Offset(width * 0.25, height * 0.08));
    // House 3 (Left Top Triangle)
    drawContent(2, Offset(width * 0.08, height * 0.25));
    // House 4 (Left Diamond)
    drawContent(3, Offset(width * 0.25, height * 0.5));
    // House 5 (Left Bottom Triangle)
    drawContent(4, Offset(width * 0.08, height * 0.75));
    // House 6 (Bottom Left Triangle)
    drawContent(5, Offset(width * 0.25, height * 0.92));
    // House 7 (Bottom Diamond)
    drawContent(6, Offset(width * 0.5, height * 0.75));
    // House 8 (Bottom Right Triangle)
    drawContent(7, Offset(width * 0.75, height * 0.92));
    // House 9 (Right Bottom Triangle)
    drawContent(8, Offset(width * 0.92, height * 0.75));
    // House 10 (Right Diamond)
    drawContent(9, Offset(width * 0.75, height * 0.5));
    // House 11 (Right Top Triangle)
    drawContent(10, Offset(width * 0.92, height * 0.25));
    // House 12 (Top Right Triangle)
    drawContent(11, Offset(width * 0.75, height * 0.08));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
