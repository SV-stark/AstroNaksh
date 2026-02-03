import 'package:fluent_ui/fluent_ui.dart';

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

    // Outer border
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

    // Inner lines
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

      if (i == (ascendantSign - 1)) {
        displayList.insert(0, "Asc");
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
