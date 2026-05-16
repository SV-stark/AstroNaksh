import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf/report_styles.dart';

class PdfReportCharts {
  /// Draw a premium North Indian chart with custom colors
  static pw.Widget drawPremiumNorthIndianChart(
    Map<String, Map<String, dynamic>> significators,
    int ascendantSign, {
    double width = 300,
    double height = 300,
    PdfColor? lineColor,
  }) {
    final color = lineColor ?? ReportStyles.primaryColor;

    return pw.Stack(
      children: [
        pw.Container(
          width: width,
          height: height,
          child: pw.CustomPaint(
            size: PdfPoint(width, height),
            painter: (PdfGraphics canvas, PdfPoint size) {
              final w = size.x;
              final h = size.y;

              canvas
                ..setColor(color)
                ..setLineWidth(1.5);

              // 1. Outer Square
              canvas.drawRect(0, 0, w, h);
              canvas.strokePath();

              // 2. Diagonals
              canvas.drawLine(0, 0, w, h);
              canvas.drawLine(0, h, w, 0);
              canvas.strokePath();

              // 3. Inner Diamond
              canvas.drawLine(w / 2, h, 0, h / 2);
              canvas.drawLine(0, h / 2, w / 2, 0);
              canvas.drawLine(w / 2, 0, w, h / 2);
              canvas.drawLine(w, h / 2, w / 2, h);
              canvas.strokePath();

              // 4. Center decorative circle
              canvas.drawEllipse(w / 2, h / 2, 10, 10);
              canvas.strokePath();
            },
          ),
        ),
        ..._buildHouseContents(
          significators,
          ascendantSign,
          width,
          height,
          isPremium: true,
        ),
      ],
    );
  }

  /// Draw a South Indian style chart (4x4 grid with center empty)
  static pw.Widget drawSouthIndianChart(
    Map<String, Map<String, dynamic>> significators, {
    double width = 300,
    double height = 300,
  }) {
    final cellW = width / 4;
    final cellH = height / 4;

    // Signs in South Indian chart are fixed in position:
    // 11 0  1  2
    // 10       3
    // 9        4
    // 8  7  6  5
    // Sign Index 0 is Aries (Top-row, 2nd column)
    final signToPos = [
      const PdfPoint(1, 3), // 0: Aries
      const PdfPoint(2, 3), // 1: Taurus
      const PdfPoint(3, 3), // 2: Gemini
      const PdfPoint(3, 2), // 3: Cancer
      const PdfPoint(3, 1), // 4: Leo
      const PdfPoint(3, 0), // 5: Virgo
      const PdfPoint(2, 0), // 6: Libra
      const PdfPoint(1, 0), // 7: Scorpio
      const PdfPoint(0, 0), // 8: Sagittarius
      const PdfPoint(0, 1), // 9: Capricorn
      const PdfPoint(0, 2), // 10: Aquarius
      const PdfPoint(0, 3), // 11: Pisces
    ];

    // Prepare data
    final planetsBySign = <int, List<String>>{};
    for (var i = 0; i < 12; i++) {
      planetsBySign[i] = [];
    }

    significators.forEach((planet, info) {
      final position = info['position'] as double? ?? 0.0;
      final signIndex = (position / 30).floor() % 12;
      planetsBySign[signIndex]?.add(_getShortName(planet));
    });

    final widgets = <pw.Widget>[];

    // Draw Grid Lines using CustomPaint
    widgets.add(
      pw.Container(
        width: width,
        height: height,
        child: pw.CustomPaint(
          size: PdfPoint(width, height),
          painter: (PdfGraphics canvas, PdfPoint size) {
            canvas
              ..setColor(ReportStyles.primaryColor)
              ..setLineWidth(1.0);

            // Outer
            canvas.drawRect(0, 0, width, height);
            // Inner lines
            for (var i = 1; i < 4; i++) {
              canvas.drawLine(i * cellW, 0, i * cellW, height);
              canvas.drawLine(0, i * cellH, width, i * cellH);
            }
            canvas.strokePath();

            // Clear Center
            canvas.setFillColor(PdfColors.white);
            canvas.drawRect(cellW + 1, cellH + 1, cellW * 2 - 2, cellH * 2 - 2);
            canvas.fillPath();
          },
        ),
      ),
    );

    // Add Content
    for (var i = 0; i < 12; i++) {
      final pos = signToPos[i];
      final planets = planetsBySign[i] ?? [];

      widgets.add(
        pw.Positioned(
          left: pos.x * cellW,
          bottom: pos.y * cellH,
          child: pw.Container(
            width: cellW,
            height: cellH,
            padding: const pw.EdgeInsets.all(4),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${i + 1}',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Text(
                      planets.join(' '),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: ReportStyles.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return pw.Stack(children: widgets);
  }

  static List<pw.Widget> _buildHouseContents(
    Map<String, Map<String, dynamic>> significators,
    int ascendantSign,
    double w,
    double h, {
    bool isPremium = false,
  }) {
    final widgets = <pw.Widget>[];

    final planetsBySign = <int, List<String>>{};
    for (var i = 1; i <= 12; i++) {
      planetsBySign[i] = [];
    }

    significators.forEach((planet, info) {
      final position = info['position'] as double? ?? 0.0;
      final signIndex = (position / 30).floor();
      final signNumber = signIndex + 1;
      planetsBySign[signNumber]?.add(_getShortName(planet));
    });

    final centers = [
      const PdfPoint(0.5, 0.75), // 1
      const PdfPoint(0.25, 0.875), // 2
      const PdfPoint(0.125, 0.75), // 3
      const PdfPoint(0.25, 0.5), // 4
      const PdfPoint(0.125, 0.25), // 5
      const PdfPoint(0.25, 0.125), // 6
      const PdfPoint(0.5, 0.25), // 7
      const PdfPoint(0.75, 0.125), // 8
      const PdfPoint(0.875, 0.25), // 9
      const PdfPoint(0.75, 0.5), // 10
      const PdfPoint(0.875, 0.75), // 11
      const PdfPoint(0.75, 0.875), // 12
    ];

    for (var i = 0; i < 12; i++) {
      final signIndex = (ascendantSign + i) % 12;
      final signNumber = signIndex + 1;
      final planets = planetsBySign[signNumber] ?? [];
      final planetText = planets.join(' ');

      final cx = centers[i].x * w;
      final cy = centers[i].y * h;

      // Sign number
      widgets.add(
        pw.Positioned(
          left: cx - 10,
          bottom: cy + (planets.isNotEmpty ? 8 : -4),
          child: pw.Container(
            width: 20,
            alignment: pw.Alignment.center,
            child: pw.Text(
              '$signNumber',
              style: pw.TextStyle(
                fontSize: 8,
                color: isPremium ? ReportStyles.accentColor : PdfColors.grey700,
                fontWeight: isPremium
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
              ),
            ),
          ),
        ),
      );

      // Planet Text
      if (planets.isNotEmpty) {
        widgets.add(
          pw.Positioned(
            left: cx - 35,
            bottom: cy - 15,
            child: pw.Container(
              width: 70,
              alignment: pw.Alignment.center,
              child: pw.Text(
                planetText,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: isPremium
                      ? ReportStyles.primaryColor
                      : PdfColors.black,
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
    // Map common names to 2-letter codes if possible
    const maps = {
      'Sun': 'Su',
      'Moon': 'Mo',
      'Mars': 'Ma',
      'Mercury': 'Me',
      'Jupiter': 'Ju',
      'Venus': 'Ve',
      'Saturn': 'Sa',
      'Rahu': 'Ra',
      'Ketu': 'Ke',
      'Ascendant': 'As',
    };
    return maps[planet] ?? planet.substring(0, 2);
  }

  // Backwards compatibility
  static pw.Widget drawNorthIndianChart(
    Map<String, Map<String, dynamic>> significators,
    int ascendantSign, {
    double width = 300,
    double height = 300,
  }) => drawPremiumNorthIndianChart(
    significators,
    ascendantSign,
    width: width,
    height: height,
  );

  static pw.Widget buildChartWithTextOverlay(
    Map<String, Map<String, dynamic>> significators,
    int ascendantSign, {
    double width = 300,
    double height = 300,
  }) => drawPremiumNorthIndianChart(
    significators,
    ascendantSign,
    width: width,
    height: height,
  );
}
