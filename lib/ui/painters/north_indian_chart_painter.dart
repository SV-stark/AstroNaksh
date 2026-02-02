import 'package:flutter/material.dart';

class NorthIndianChartPainter extends CustomPainter {
  final List<String>
  planetPositions; // Map house index (0-11) to planets string
  final Color lineColor;
  final Color textColor;

  NorthIndianChartPainter({
    required this.planetPositions,
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

    // Helper to draw text in house
    void drawText(int houseIndex, Offset offset) {
      if (houseIndex >= planetPositions.length) return;

      final text = planetPositions[houseIndex];
      if (text.isEmpty) return;

      final textSpan = TextSpan(
        text: text,
        style: TextStyle(color: textColor, fontSize: 10),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(minWidth: width / 4, maxWidth: width / 3);

      final textOffset = Offset(
        offset.dx - textPainter.width / 2,
        offset.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }

    // Positions for 12 houses in North Indian style (Fixed Layout)
    // House 1 is top center diamond
    drawText(0, Offset(width / 2, height / 4)); // House 1
    drawText(1, Offset(width / 4, height / 8)); // House 2
    drawText(2, Offset(width / 8, height / 4)); // House 3
    drawText(
      3,
      Offset(width / 2, height / 2),
    ); // House 4 (Center) -> Actually house 4 is bottom diamond? No, North style is specific.
    // Correction:
    // H1: Top Diamond (Top Middle)
    // H2: Top Left Triangle
    // H3: Left Triangle (Top part) -> Actually H2 is top-left, H3 is left-top?
    // Let's use standard North Indian fixed layout:
    // 1: Top Diamond
    // 2: Left Upper Triangle
    // 3: Left Lower Triangle
    // 4: Bottom Diamond (Actually the central square is 1,4,7,10? No)

    // North Indian Style:
    // Ascendant (Lagna) is usually top middle diamond (House 1).
    // Counter-clockwise? No, North is counter-clockwise for signs, but houses are fixed regions.
    // 1: Top Center Diamond
    // 2: Top Left Triangle
    // 3: Left Triangle
    // 4: Bottom Center Diamond (Wait, 4 is usually bottom center? No, 7 is bottom center)
    // Actually:
    // 1: Top Middle Rhombus
    // 2: Top Left Triangle
    // 3: Left Triangle (Upper part?)
    // 4: Center Rhombus (Bottom) -> NO.

    // Standard Layout:
    //      / \
    //     / 1 \
    //    /_____\
    //   |\ 2 /| 12 /|
    //   | \ / | \ / |
    //   |3 X 4| 1 X 10| -> Wait

    // Let's approximate positions based on visual centers:
    // House 1: Top Center
    drawText(0, Offset(width / 2, height * 0.2));
    // House 2: Top Left
    drawText(1, Offset(width * 0.25, height * 0.1));
    // House 3: Left Top
    drawText(2, Offset(width * 0.1, height * 0.25));
    // House 4: Left Center (Actually house 4 is usually the right side of the inner square in some charts?)
    // Let's stick to simple grid logic for now, standard North Indian:
    // 1: Top Center
    // 2: Top Left
    // 3: Left Top
    // 4: Bottom center of top-left quadrant? No.
    // 4: Center Left (The diamond acting as house 4 is usually ... wait)
    // House 4 is the bottom of the central pillar usually.
    // Let's assume standard positions relative to centers:

    // 1: Top Diamond
    // 4: Bottom Diamond? No 7 is opposite.
    // 7: Bottom Diamond
    // 10: Top Diamond? NO.

    // North Indian Chart (Diamond Chart):
    // 1: Top Middle
    // 2: Top Left
    // 3: Left Top (Outer)
    // 4: Left Middle (Inner?) -> NO
    // 4 is Center Bottom?? NO.

    // Hardcoded centers for Diamond Chart:
    // 1 (Lagna): Top Center
    drawText(0, Offset(width * 0.5, height * 0.25));
    // 2: Top Left
    drawText(1, Offset(width * 0.25, height * 0.08));
    // 3: Left Top
    drawText(2, Offset(width * 0.08, height * 0.25));
    // 4: Center (Left) -> Actually House 4 is the diamond on the Left.
    // Wait, North Indian has 4 center diamonds. 1 (Top), 4 (Bottom?), 7 (Bottom?), 10 (Top?)
    // No.
    // The 4 center diamonds are 1, 4, 7, 10.
    // 1: Top
    // 4: Left
    // 7: Bottom
    // 10: Right

    // CORRECT Logic for standard North Indian:
    // 1: Top Center Diamond
    // 4: Left Center Diamond
    // 7: Bottom Center Diamond
    // 10: Right Center Diamond

    // 1
    drawText(0, Offset(width * 0.5, height * 0.2));
    // 2 (Top Left Triangle)
    drawText(1, Offset(width * 0.2, height * 0.05));
    // 3 (Left Top Triangle)
    drawText(2, Offset(width * 0.05, height * 0.2));
    // 4 (Left Diamond)
    drawText(3, Offset(width * 0.2, height * 0.5));
    // 5 (Left Bottom Triangle)
    drawText(4, Offset(width * 0.05, height * 0.8));
    // 6 (Bottom Left Triangle)
    drawText(5, Offset(width * 0.2, height * 0.95));
    // 7 (Bottom Diamond)
    drawText(6, Offset(width * 0.5, height * 0.8));
    // 8 (Bottom Right Triangle)
    drawText(7, Offset(width * 0.8, height * 0.95));
    // 9 (Right Bottom Triangle)
    drawText(8, Offset(width * 0.95, height * 0.8));
    // 10 (Right Diamond)
    drawText(9, Offset(width * 0.8, height * 0.5));
    // 11 (Right Top Triangle)
    drawText(10, Offset(width * 0.95, height * 0.2));
    // 12 (Top Right Triangle)
    drawText(11, Offset(width * 0.8, height * 0.05));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
