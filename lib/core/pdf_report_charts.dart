import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfReportCharts {
  static pw.Widget drawNorthIndianChart(
    Map<String, Map<String, dynamic>> significators,
    int ascendantSign, { // 0-11
    double width = 300,
    double height = 300,
  }) {
    // Prepare data: Map Sign (1-12) -> List of Planet Names
    final planetsBySign = <int, List<String>>{};
    for (int i = 1; i <= 12; i++) {
      planetsBySign[i] = [];
    }

    significators.forEach((planet, info) {
      final position = info['position'] as double? ?? 0.0;
      final signIndex = (position / 30).floor(); // 0-11
      final signNumber = signIndex + 1; // 1-12
      // Using short names for PDF to save space
      final shortName = _getShortName(planet);
      planetsBySign[signNumber]?.add(shortName);
    });

    return pw.Container(
      width: width,
      height: height,
      child: pw.CustomPaint(
        size: PdfPoint(width, height),
        painter: (PdfGraphics canvas, PdfPoint size) {
          final w = size.x;
          final h = size.y;

          // Paint settings
          canvas
            ..setColor(PdfColors.black)
            ..setLineWidth(1.0);

          // 1. Draw Outer Square
          canvas.drawRect(0, 0, w, h);
          canvas.strokePath();

          // 2. Draw Diagonals
          canvas.drawLine(
            0,
            h,
            w,
            0,
          ); // Top-left to Bottom-right (PDF coords are bottom-up?)
          // Note: PdfGraphics usually uses bottom-left as (0,0).
          // Let's assume (0,0) is bottom-left for now.
          // If (0,0) is bottom-left:
          // TL is (0, h), TR is (w, h), BL is (0, 0), BR is (w, 0).
          // Diagonals: TL(0,h) to BR(w,0) and TR(w,h) to BL(0,0).
          canvas.drawLine(0, 0, w, h);
          canvas.strokePath();

          // 3. Draw Inner Diamond
          // Mid-Top: (w/2, h)
          // Mid-Right: (w, h/2)
          // Mid-Bottom: (w/2, 0)
          // Mid-Left: (0, h/2)

          canvas.drawLine(w / 2, h, 0, h / 2); // Top-Mid to Left-Mid
          canvas.drawLine(0, h / 2, w / 2, 0); // Left-Mid to Bottom-Mid
          canvas.drawLine(w / 2, 0, w, h / 2); // Bottom-Mid to Right-Mid
          canvas.drawLine(w, h / 2, w / 2, h); // Right-Mid to Top-Mid
          canvas.strokePath();

          // Draw content
          // We need to place text. PdfGraphics has simple text drawing,
          // but managing layout (centering, wrapping) is hard with raw canvas.
          // Since we are inside a CustomPaint widget, we can't easily use pw.Text widgets *inside* the painter for layout.
          // However, we can overlay pw.Stack on top of this CustomPaint for the text!
          // That is much easier than calculating text widths in PdfGraphics.
        },
      ),
    );
  }

  static pw.Widget buildChartWithTextOverlay(
    Map<String, Map<String, dynamic>> significators,
    int ascendantSign, { // 0-11
    double width = 300,
    double height = 300,
  }) {
    return pw.Stack(
      children: [
        drawNorthIndianChart(
          significators,
          ascendantSign,
          width: width,
          height: height,
        ),
        ..._buildHouseContents(significators, ascendantSign, width, height),
      ],
    );
  }

  static List<pw.Widget> _buildHouseContents(
    Map<String, Map<String, dynamic>> significators,
    int ascendantSign,
    double w,
    double h,
  ) {
    final widgets = <pw.Widget>[];

    // Prepare data
    final planetsBySign = <int, List<String>>{};
    for (int i = 1; i <= 12; i++) {
      planetsBySign[i] = [];
    }

    significators.forEach((planet, info) {
      final position = info['position'] as double? ?? 0.0;
      final signIndex = (position / 30).floor(); // 0-11
      final signNumber = signIndex + 1; // 1-12
      planetsBySign[signNumber]?.add(_getShortName(planet));
    });

    // Centers for 12 houses (approximate percentage of w, h)
    // Assuming PDF coordinates: (0,0) is BOTTOM-LEFT.
    // House 1: Top Center -> (0.5w, 0.75h)
    // House 2: Top Left -> (0.25w, 0.875h)
    // House 3: Left Top -> (0.125w, 0.75h)
    // House 4: Left Center -> (0.25w, 0.5h)
    // House 5: Left Bottom -> (0.125w, 0.25h)
    // House 6: Bottom Left -> (0.25w, 0.125h)
    // House 7: Bottom Center -> (0.5w, 0.25h)
    // House 8: Bottom Right -> (0.75w, 0.125h)
    // House 9: Right Bottom -> (0.875w, 0.25h)
    // House 10: Right Center -> (0.75w, 0.5h)
    // House 11: Right Top -> (0.875w, 0.75h)
    // House 12: Top Right -> (0.75w, 0.875h)

    final centers = [
      PdfPoint(0.5, 0.75), // 1
      PdfPoint(0.25, 0.875), // 2
      PdfPoint(0.125, 0.75), // 3
      PdfPoint(0.25, 0.5), // 4
      PdfPoint(0.125, 0.25), // 5
      PdfPoint(0.25, 0.125), // 6
      PdfPoint(0.5, 0.25), // 7
      PdfPoint(0.75, 0.125), // 8
      PdfPoint(0.875, 0.25), // 9
      PdfPoint(0.75, 0.5), // 10
      PdfPoint(0.875, 0.75), // 11
      PdfPoint(0.75, 0.875), // 12
    ];

    for (int i = 0; i < 12; i++) {
      // House Index i (0-11) -> 1st House is i=0
      // Sign in this house = (Asc + i) % 12
      // If Asc is 0 (Aries), House 0 has Sign 0 (Aries).
      // ascendantSign is 0-based.

      final signIndex = (ascendantSign + i) % 12;
      final signNumber = signIndex + 1;

      // Content
      final planets = planetsBySign[signNumber] ?? [];
      final planetText = planets.join('\n'); // Stack vertically or horizontally

      final cx = centers[i].x * w;
      final cy = centers[i].y * h;

      // Sign number
      widgets.add(
        pw.Positioned(
          left: cx - 10,
          bottom:
              cy +
              (planets.isNotEmpty
                  ? 10
                  : -6), // Adjust position relative to planets
          child: pw.Container(
            width: 20,
            alignment: pw.Alignment.center,
            child: pw.Text(
              '$signNumber',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ),
        ),
      );

      // Planet Text
      if (planets.isNotEmpty) {
        widgets.add(
          pw.Positioned(
            left: cx - 25,
            bottom: cy - 20, // Centered-ish
            child: pw.Container(
              width: 50,
              alignment: pw.Alignment.center,
              child: pw.Text(
                planetText,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  static String _getShortName(String planet) {
    if (planet.length <= 2) return planet;
    return planet.substring(0, 2);
  }
}
