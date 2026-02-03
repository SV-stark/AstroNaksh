import 'package:fluent_ui/fluent_ui.dart';

class NorthIndianChartPainter extends CustomPainter {
  final Map<int, List<String>> planetsBySign;
  final int ascendantSign;
  final Color textColor;
  final Color borderColor;

  NorthIndianChartPainter({
    required this.planetsBySign,
    required this.ascendantSign,
    this.textColor = Colors.black,
    this.borderColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final width = size.width;
    final height = size.height;

    // 1. Draw Outer Square
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

    // 2. Draw Diagonals
    canvas.drawLine(Offset(0, 0), Offset(width, height), paint);
    canvas.drawLine(Offset(width, 0), Offset(0, height), paint);

    // 3. Draw Inner Diamond
    canvas.drawLine(Offset(width / 2, 0), Offset(0, height / 2), paint);
    canvas.drawLine(Offset(0, height / 2), Offset(width / 2, height), paint);
    canvas.drawLine(
      Offset(width / 2, height),
      Offset(width, height / 2),
      paint,
    );
    canvas.drawLine(Offset(width, height / 2), Offset(width / 2, 0), paint);

    // 4. Content Drawing logic
    void drawContent(int houseIndex, Offset center) {
      // Calculate Sign for this house
      final signIndex = ((ascendantSign - 1) + houseIndex) % 12;
      final signNumber = signIndex + 1; // 1-12

      // 1. Draw Sign Number (Small, secondary color)
      final signSpan = TextSpan(
        text: "$signNumber\n",
        style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 10),
      );

      // 2. Draw Planets
      final planets = planetsBySign[signIndex] ?? [];
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
        style: const TextStyle(height: 1.2),
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

    // House Centers (Approximate)
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

    for (int i = 0; i < 12; i++) {
      drawContent(i, centers[i]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
