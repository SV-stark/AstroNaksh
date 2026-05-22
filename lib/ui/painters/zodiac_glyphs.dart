import 'package:flutter/material.dart';

/// Helper to draw high-quality vector glyphs for the 12 Zodiac signs.
/// Indexes: 0 = Aries, 1 = Taurus, 2 = Gemini, 3 = Cancer, 4 = Leo, 5 = Virgo,
///          6 = Libra, 7 = Scorpio, 8 = Sagittarius, 9 = Capricorn, 10 = Aquarius, 11 = Pisces.
class ZodiacGlyphs {
  static void drawGlyph(
    Canvas canvas,
    int signIndex,
    Offset center,
    double size,
    Color color, {
    double strokeWidth = 2.0,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final path = getGlyphPath(signIndex);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    // Path is normalized to a box of [-1, -1] to [1, 1], so scale by size / 2.0
    canvas.scale(size / 2.0, size / 2.0);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  static Path getGlyphPath(int index) {
    final path = Path();
    switch (index % 12) {
      case 0: // Aries (Ram Horns)
        path.moveTo(0, 0.8);
        path.lineTo(0, -0.3);
        // Left horn loop
        path.cubicTo(-0.1, -0.7, -0.7, -0.8, -0.6, -0.3);
        path.cubicTo(-0.55, -0.1, -0.3, -0.2, -0.25, -0.35);
        // Right horn loop
        path.moveTo(0, -0.3);
        path.cubicTo(0.1, -0.7, 0.7, -0.8, 0.6, -0.3);
        path.cubicTo(0.55, -0.1, 0.3, -0.2, 0.25, -0.35);
        break;

      case 1: // Taurus (Bull Head and Horns)
        // Horns crescent
        path.moveTo(-0.6, -0.5);
        path.cubicTo(-0.5, -0.1, -0.3, -0.1, -0.3, -0.1);
        path.moveTo(0.6, -0.5);
        path.cubicTo(0.5, -0.1, 0.3, -0.1, 0.3, -0.1);
        // Head circle
        path.addOval(
          Rect.fromCircle(center: const Offset(0, 0.3), radius: 0.45),
        );
        break;

      case 2: // Gemini (Roman Numeral II)
        // Top and bottom bars
        path.moveTo(-0.6, -0.7);
        path.lineTo(0.6, -0.7);
        path.moveTo(-0.6, 0.7);
        path.lineTo(0.6, 0.7);
        // Vertical pillars
        path.moveTo(-0.25, -0.7);
        path.lineTo(-0.25, 0.7);
        path.moveTo(0.25, -0.7);
        path.lineTo(0.25, 0.7);
        break;

      case 3: // Cancer (Crab claws - 69 shape sideways/vertical)
        // Top claw loop
        path.addOval(
          Rect.fromCircle(center: const Offset(-0.35, -0.25), radius: 0.15),
        );
        path.moveTo(-0.2, -0.25);
        path.cubicTo(0.0, -0.25, 0.5, -0.25, 0.5, -0.55);
        path.cubicTo(0.5, -0.8, 0.1, -0.75, -0.1, -0.55);

        // Bottom claw loop
        path.addOval(
          Rect.fromCircle(center: const Offset(0.35, 0.25), radius: 0.15),
        );
        path.moveTo(0.2, 0.25);
        path.cubicTo(0.0, 0.25, -0.5, 0.25, -0.5, 0.55);
        path.cubicTo(-0.5, 0.8, -0.1, 0.75, 0.1, 0.55);
        break;

      case 4: // Leo (Lion's Tail & Mane)
        // Mane circle
        path.addOval(
          Rect.fromCircle(center: const Offset(-0.35, 0.35), radius: 0.15),
        );
        // Wave/tail
        path.moveTo(-0.2, 0.35);
        path.cubicTo(-0.1, 0.35, -0.1, -0.55, -0.35, -0.55);
        path.cubicTo(-0.6, -0.55, -0.5, -0.8, -0.1, -0.8);
        path.cubicTo(0.3, -0.8, 0.3, 0.1, 0.45, 0.4);
        path.cubicTo(0.55, 0.6, 0.75, 0.65, 0.75, 0.2);
        break;

      case 5: // Virgo (M with loop tail)
        // First arch
        path.moveTo(-0.6, 0.6);
        path.lineTo(-0.6, -0.4);
        path.cubicTo(-0.6, -0.75, -0.3, -0.75, -0.3, -0.4);
        // Second arch
        path.lineTo(-0.3, 0.6);
        path.moveTo(-0.3, -0.4);
        path.cubicTo(-0.3, -0.75, 0.0, -0.75, 0.0, -0.4);
        // Third arch
        path.lineTo(0.0, 0.6);
        path.moveTo(0.0, -0.4);
        path.cubicTo(0.0, -0.75, 0.3, -0.75, 0.3, -0.4);
        path.lineTo(0.3, 0.3);
        // Loop tail
        path.cubicTo(0.35, 0.6, 0.6, 0.65, 0.6, 0.3);
        path.cubicTo(0.6, -0.1, 0.25, -0.2, 0.4, 0.7);
        break;

      case 6: // Libra (Scales)
        // Bottom flat line
        path.moveTo(-0.7, 0.5);
        path.lineTo(0.7, 0.5);
        // Top omega symbol
        path.moveTo(-0.7, -0.1);
        path.lineTo(-0.25, -0.1);
        path.cubicTo(-0.25, -0.6, -0.05, -0.6, 0.0, -0.6);
        path.cubicTo(0.05, -0.6, 0.25, -0.6, 0.25, -0.1);
        path.lineTo(0.7, -0.1);
        break;

      case 7: // Scorpio (M with arrow tail)
        // First arch
        path.moveTo(-0.6, 0.6);
        path.lineTo(-0.6, -0.4);
        path.cubicTo(-0.6, -0.75, -0.3, -0.75, -0.3, -0.4);
        // Second arch
        path.lineTo(-0.3, 0.6);
        path.moveTo(-0.3, -0.4);
        path.cubicTo(-0.3, -0.75, 0.0, -0.75, 0.0, -0.4);
        // Third arch & arrow
        path.lineTo(0.0, 0.6);
        path.moveTo(0.0, -0.4);
        path.cubicTo(0.0, -0.75, 0.3, -0.75, 0.3, -0.4);
        path.lineTo(0.3, 0.4);
        path.cubicTo(0.3, 0.7, 0.55, 0.7, 0.55, 0.3);
        // Arrow head pointing up-right
        path.lineTo(0.65, 0.5);
        path.moveTo(0.5, 0.4);
        path.lineTo(0.65, 0.5);
        path.lineTo(0.68, 0.32);
        break;

      case 8: // Sagittarius (Arrow & Crossbar)
        // Main diagonal arrow pointing top-right
        path.moveTo(-0.7, 0.7);
        path.lineTo(0.7, -0.7);
        // Arrow head
        path.moveTo(0.3, -0.7);
        path.lineTo(0.7, -0.7);
        path.lineTo(0.7, -0.3);
        // Crossbar
        path.moveTo(-0.35, -0.05);
        path.lineTo(0.05, 0.35);
        break;

      case 9: // Capricorn (Goat horn with loop)
        path.moveTo(-0.6, -0.4);
        path.lineTo(-0.25, 0.4);
        path.lineTo(0.05, -0.35);
        // Loop on the right
        path.cubicTo(0.2, -0.7, 0.4, -0.5, 0.4, -0.2);
        path.cubicTo(0.4, 0.3, 0.05, 0.4, 0.25, 0.7);
        break;

      case 10: // Aquarius (Water waves)
        // Top wave
        path.moveTo(-0.7, -0.3);
        path.lineTo(-0.45, -0.55);
        path.lineTo(-0.2, -0.3);
        path.lineTo(0.05, -0.55);
        path.lineTo(0.3, -0.3);
        path.lineTo(0.55, -0.55);
        path.lineTo(0.7, -0.3);
        // Bottom wave
        path.moveTo(-0.7, 0.2);
        path.lineTo(-0.45, -0.05);
        path.lineTo(-0.2, 0.2);
        path.lineTo(0.05, -0.05);
        path.lineTo(0.3, 0.2);
        path.lineTo(0.55, -0.05);
        path.lineTo(0.7, 0.2);
        break;

      case 11: // Pisces (Two fish connected)
        // Left curve
        path.moveTo(-0.4, -0.75);
        path.cubicTo(-0.15, -0.4, -0.15, 0.4, -0.4, 0.75);
        // Right curve
        path.moveTo(0.4, -0.75);
        path.cubicTo(0.15, -0.4, 0.15, 0.4, 0.4, 0.75);
        // Connecting bar
        path.moveTo(-0.3, 0.0);
        path.lineTo(0.3, 0.0);
        break;
    }
    return path;
  }
}
