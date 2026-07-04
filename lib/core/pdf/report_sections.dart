import 'package:jyotish/jyotish.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models.dart';
import '../../logic/life_prediction_service.dart';
import '../../logic/transit_analysis.dart';
import '../../logic/varshaphal_system.dart';
import '../pdf_report_charts.dart';
import 'pdf_widgets.dart';
import 'report_styles.dart';

class ReportSections {
  static pw.Page buildCoverPage({
    required CompleteChartData chartData,
    required String title,
    pw.MemoryImage? coverImage,
    pw.MemoryImage? backgroundImage,
    pw.MemoryImage? logo,
    String? brandOrgName,
    String? brandOrgTagline,
    String? brandContactInfo,
    pw.EdgeInsets? margin,
  }) {
    final edgeMargin = margin ?? const pw.EdgeInsets.all(40);
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: edgeMargin,
      build: (context) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Stack(
            children: [
              if (backgroundImage != null)
                pw.Positioned.fill(
                  child: pw.Opacity(
                    opacity: 0.1,
                    child: pw.Image(backgroundImage, fit: pw.BoxFit.cover),
                  ),
                ),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: ReportStyles.accentColor,
                    width: 2,
                  ),
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                padding: edgeMargin,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (logo != null) ...[
                      pw.Container(
                        height: 80,
                        width: 80,
                        alignment: pw.Alignment.center,
                        child: pw.Image(logo),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                    pw.Text(
                      brandOrgName ?? 'ASTRONAKSH',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: ReportStyles.primaryColor,
                        letterSpacing: 6,
                      ),
                    ),
                    if (brandOrgTagline != null &&
                        brandOrgTagline.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        brandOrgTagline,
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: ReportStyles.grey,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 10),
                    pw.Container(
                      height: 2,
                      width: 100,
                      color: ReportStyles.accentColor,
                    ),
                    pw.SizedBox(height: 40),
                    if (coverImage != null)
                      pw.Center(
                        child: pw.Container(
                          height: 200,
                          width: 200,
                          child: pw.Image(coverImage),
                        ),
                      ),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      title.toUpperCase(),
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: ReportStyles.primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(20),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(
                          color: PdfColor.fromHex('#C5A059').flatten(),
                        ),
                      ),
                      child: pw.Column(
                        children: [
                          _buildInfoRow('Name', chartData.birthData.name),
                          _buildInfoRow(
                            'Date',
                            _formatDate(chartData.birthData.dateTime),
                          ),
                          _buildInfoRow(
                            'Time',
                            _formatTime(chartData.birthData.dateTime),
                          ),
                          _buildInfoRow('Place', chartData.birthData.place),
                        ],
                      ),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      brandContactInfo ?? 'PRODUCED BY ASTRONAKSH VEDIC ENGINE',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: ReportStyles.grey,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Future<pw.Widget> buildSummarySection(
    CompleteChartData chartData,
    pw.TextStyle h2,
    pw.TextStyle body,
    pw.TextStyle bodyBold,
  ) async {
    final currentDasha = chartData.getCurrentDashas(DateTime.now());

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfWidgets.sectionHeader('Chart Summary', h2),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: PdfWidgets.infoCard(
                title: 'Key Indicators',
                children: [
                  _buildSummaryItem(
                    'Ascendant',
                    chartData.baseChart.ascendantSign,
                    body,
                    bodyBold,
                  ),
                  _buildSummaryItem(
                    'Moon Sign',
                    chartData.baseChart.planets[Planet.moon]?.zodiacSign ??
                        'N/A',
                    body,
                    bodyBold,
                  ),
                  _buildSummaryItem(
                    'Sun Sign',
                    chartData.baseChart.planets[Planet.sun]?.zodiacSign ??
                        'N/A',
                    body,
                    bodyBold,
                  ),
                  _buildSummaryItem(
                    'Nakshatra',
                    chartData.baseChart.planets[Planet.moon]?.nakshatra ??
                        'N/A',
                    body,
                    bodyBold,
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: PdfWidgets.infoCard(
                title: 'Current Period',
                children: [
                  _buildSummaryItem(
                    'Mahadasha',
                    currentDasha['mahadasha'] ?? 'N/A',
                    body,
                    bodyBold,
                  ),
                  _buildSummaryItem(
                    'Antardasha',
                    currentDasha['antardasha'] ?? 'N/A',
                    body,
                    bodyBold,
                  ),
                  _buildSummaryItem(
                    'Ends On',
                    _formatDate(
                      currentDasha['antarEnd'] as DateTime? ?? DateTime.now(),
                    ),
                    body,
                    bodyBold,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Special Transits (Sade Sati / Dhaiya)
        await _buildSpecialTransitSummary(chartData, body, bodyBold),
      ],
    );
  }

  static Future<pw.Widget> _buildSpecialTransitSummary(
    CompleteChartData chartData,
    pw.TextStyle body,
    pw.TextStyle bodyBold,
  ) async {
    final transitAnalysis = TransitAnalysis();
    final transitChart = await transitAnalysis.calculateTransitChart(
      chartData,
      DateTime.now(),
    );
    final saturn = transitChart.saturnTransit;

    if (!saturn.isSadeSati && !saturn.isDhaiya) return pw.SizedBox();

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16),
      child: PdfWidgets.infoCard(
        title: 'Special Transit Warnings',
        children: [
          if (saturn.isSadeSati)
            _buildSummaryItem(
              'Sade Sati',
              '${saturn.sadeSatiPhase.name} phase',
              body,
              bodyBold,
            ),
          if (saturn.isDhaiya)
            _buildSummaryItem(
              'Dhaiya',
              '${saturn.dhaiyaType.name} active',
              body,
              bodyBold,
            ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Special Saturn transits often bring periods of discipline, transformation, and karmic adjustments.',
            style: body.copyWith(fontSize: 8, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  static Future<pw.Widget> buildTransitSection(
    CompleteChartData chartData,
    pw.TextStyle h2,
    pw.TextStyle h3,
    pw.TextStyle body,
  ) async {
    final transitAnalysis = TransitAnalysis();
    final transitChart = await transitAnalysis.calculateTransitChart(
      chartData,
      DateTime.now(),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfWidgets.sectionHeader('Current Transit Analysis (Gochara)', h2),
        pw.Text(
          'Gochara analysis examines how current planetary positions interact with your natal chart to influence your present circumstances.',
          style: body,
        ),
        pw.SizedBox(height: 20),

        // Gochara Positions Table
        pw.Text('Planetary Placements from Moon', style: h3),
        pw.SizedBox(height: 10),
        PdfWidgets.premiumTable(
          headers: ['Planet', 'Current Sign', 'House from Moon', 'Nature'],
          rows: transitChart.gochara.positions.entries.map((entry) {
            final planet = entry.key;
            final house = entry.value;
            final isFavorable = transitChart.gochara.isFavorable(planet);

            return [
              planet.displayName,
              AstrologyConstants.getSignName(
                transitChart
                        .transitPositions
                        .planets[planet]
                        ?.position
                        .zodiacSignIndex ??
                    0,
              ),
              'House $house',
              if (isFavorable) 'Favorable' else 'Challenging',
            ];
          }).toList(),
          bodyStyle: body.copyWith(fontSize: 9),
        ),

        pw.SizedBox(height: 30),

        // Special Transits
        pw.Text('Major Planetary Transits', style: h3),
        pw.SizedBox(height: 10),

        // Saturn Card
        _buildTransitDetailCard(
          'Saturn (Shani)',
          transitChart.saturnTransit.effects,
          transitChart.saturnTransit.recommendations,
          body,
        ),

        pw.SizedBox(height: 12),

        // Jupiter Card
        _buildTransitDetailCard(
          'Jupiter (Guru)',
          transitChart.jupiterTransit.effects,
          transitChart.jupiterTransit.recommendations,
          body,
        ),
      ],
    );
  }

  static pw.Widget _buildTransitDetailCard(
    String title,
    List<String> effects,
    List<String> recommendations,
    pw.TextStyle body,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: ReportStyles.accentColor.shade(0.8)),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: body.copyWith(
              fontWeight: pw.FontWeight.bold,
              color: ReportStyles.primaryColor,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Effects: ${effects.join("; ")}',
            style: body.copyWith(fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Advice: ${recommendations.join("; ")}',
            style: body.copyWith(fontSize: 9, fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );
  }

  static Future<pw.Widget> buildPredictionSection(
    CompleteChartData chartData,
    pw.TextStyle h2,
    pw.TextStyle h3,
    pw.TextStyle body,
  ) async {
    final predictionService = LifePredictionService();
    final result = await predictionService.generateLifePredictions(chartData);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfWidgets.sectionHeader('Life Interpretations', h2),
        ...result.aspects.map((aspect) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text(aspect.aspectName, style: h3),
                    pw.Spacer(),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _getScoreColor(aspect.score),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Text(
                        'Score: ${aspect.score}%',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  aspect.prediction,
                  style: body,
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Advice: ${aspect.advice}',
                  style: body.copyWith(
                    fontStyle: pw.FontStyle.italic,
                    color: ReportStyles.primaryColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static Future<pw.Widget> buildYogaDoshaSection(
    YogaDoshaAnalysisResult analysis,
    pw.TextStyle h2,
    pw.TextStyle h3,
    pw.TextStyle body,
  ) async {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfWidgets.sectionHeader('Yogas & Doshas Analysis', h2),
        pw.Text(
          'Vedic Yogas are planetary combinations that produce specific results, while Doshas indicate karmic challenges and areas requiring attention.',
          style: body,
        ),
        pw.SizedBox(height: 20),

        // Overall Summary Card
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: ReportStyles.primaryColor.shade(0.95),
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: ReportStyles.primaryColor.shade(0.8)),
          ),
          child: pw.Row(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Overall Quality: ${analysis.qualityLabel}',
                    style: h3.copyWith(color: ReportStyles.primaryColor),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    width: 400,
                    child: pw.Text(
                      analysis.qualityDescription,
                      style: body.copyWith(fontSize: 9),
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: ReportStyles.primaryColor,
                ),
                child: pw.Text(
                  '${analysis.overallScore.toInt()}',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 30),

        // Yogas Section
        pw.Text('Auspicious Yogas', style: h3),
        pw.SizedBox(height: 10),
        if (analysis.yogas.isEmpty)
          pw.Text(
            'No major auspicious yogas detected.',
            style: body.copyWith(fontStyle: pw.FontStyle.italic),
          )
        else
          PdfWidgets.premiumTable(
            headers: ['Yoga Name', 'Strength', 'Peak Period'],
            rows: analysis.yogas
                .map(
                  (y) => [
                    y.name,
                    '${y.strength.toInt()}%',
                    y.manifestationPeriod,
                  ],
                )
                .toList(),
            bodyStyle: body.copyWith(fontSize: 9),
          ),

        pw.SizedBox(height: 30),

        // Doshas Section
        pw.Text('Karmic Doshas (Challenges)', style: h3),
        pw.SizedBox(height: 10),
        if (analysis.doshas.isEmpty)
          pw.Text(
            'No major doshas detected in the chart.',
            style: body.copyWith(fontStyle: pw.FontStyle.italic),
          )
        else
          PdfWidgets.premiumTable(
            headers: ['Dosha Name', 'Status', 'Impact Period'],
            rows: analysis.doshas
                .map((d) => [d.name, d.status, d.manifestationPeriod])
                .toList(),
            bodyStyle: body.copyWith(fontSize: 9),
          ),

        pw.SizedBox(height: 20),
        pw.Text(
          '* Strengths and manifestation periods are calculated based on current Dasha cycles and planetary dignities.',
          style: body.copyWith(fontSize: 8, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static Future<pw.Widget> buildVarshaphalPage1(
    VarshaphalChart varsha,
    pw.TextStyle h2,
    pw.TextStyle h3,
    pw.TextStyle body,
  ) async {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfWidgets.sectionHeader(
          'Annual Analysis (Varshaphal - ${varsha.year})',
          h2,
        ),
        pw.Text(
          'The Varshaphal chart provides insights into the major themes and events of your current year starting from your solar return.',
          style: body,
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                children: [
                  PdfWidgets.infoCard(
                    title: 'Year Indicators',
                    children: [
                      _buildSummaryItem(
                        'Year Lord',
                        varsha.yearLord,
                        body,
                        body,
                      ),
                      _buildSummaryItem(
                        'Muntha Sign',
                        VarshaphalSystem.getSignName(varsha.muntha),
                        body,
                        body,
                      ),
                      _buildSummaryItem(
                        'Muntha Lord',
                        varsha.munthaLord,
                        body,
                        body,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  PdfWidgets.infoCard(
                    title: 'Solar Return Info',
                    children: [
                      _buildSummaryItem(
                        'Return Time',
                        _formatDate(varsha.solarReturnTime),
                        body,
                        body,
                      ),
                      _buildSummaryItem(
                        'Return Status',
                        varsha.isDayBirth ? 'Day Birth' : 'Night Birth',
                        body,
                        body,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              flex: 3,
              child: pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Varsha Chart (Solar Return)', style: h3),
                    pw.SizedBox(height: 10),
                    PdfReportCharts.drawPremiumNorthIndianChart(
                      _convertVarshaToSignificators(varsha),
                      VarshaphalSystem.getAscendantSign(varsha.chart),
                      width: 240,
                      height: 240,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Future<pw.Widget> buildVarshaphalPage2(
    VarshaphalChart varsha,
    pw.TextStyle h2,
    pw.TextStyle h3,
    pw.TextStyle body,
  ) async {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfWidgets.sectionHeader('Yearly Timeline (Mudda Dasha)', h2),
        PdfWidgets.premiumTable(
          headers: ['Planet', 'Start Date', 'End Date', 'Themes'],
          rows: varsha.varshikDasha
              .map(
                (d) => [
                  d.planet,
                  _formatDateShort(d.startDate),
                  _formatDateShort(d.endDate),
                  d.keyThemes.take(2).join(', '),
                ],
              )
              .toList(),
          bodyStyle: body.copyWith(fontSize: 8),
        ),
        pw.SizedBox(height: 30),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  PdfWidgets.sectionHeader('Tajik Yogas', h3),
                  ...varsha.tajikYogas.map(
                    (y) =>
                        pw.Bullet(text: y, style: body.copyWith(fontSize: 9)),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  PdfWidgets.sectionHeader('Key Sahams', h3),
                  ...varsha.sahams.entries
                      .take(5)
                      .map(
                        (e) => pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '${e.key}: ${VarshaphalSystem.getSignName(e.value.sign)} ${e.value.degreeInSign.toStringAsFixed(2)}°',
                              style: body.copyWith(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                            pw.Text(
                              e.value.interpretation,
                              style: body.copyWith(fontSize: 8),
                            ),
                            pw.SizedBox(height: 4),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 30),
        PdfWidgets.sectionHeader('Yearly Predictions', h3),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: ReportStyles.accentColor.shade(0.9),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(varsha.interpretation, style: body),
        ),
      ],
    );
  }

  static String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: ReportStyles.primaryColor,
            ),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(
    String label,
    String value,
    pw.TextStyle body,
    pw.TextStyle bodyBold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: body),
          pw.Text(value, style: bodyBold),
        ],
      ),
    );
  }

  static PdfColor _getScoreColor(int score) {
    if (score >= 80) return PdfColors.green800;
    if (score >= 60) return PdfColors.blue800;
    if (score >= 40) return PdfColors.orange800;
    return PdfColors.red800;
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $amPm';
  }

  static Map<String, Map<String, dynamic>> _convertVarshaToSignificators(
    VarshaphalChart varsha,
  ) {
    final map = <String, Map<String, dynamic>>{};
    final planets = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Rahu',
      'Ketu',
    ];
    for (final p in planets) {
      final pEnum = VarshaphalSystem.getPlanetFromString(p);
      final longitude = VarshaphalSystem.getPlanetLongitude(
        varsha.chart,
        pEnum,
      );
      map[p] = {'position': longitude, 'house': 0};
    }
    // Add Muntha as a special indicator
    map['Muntha'] = {
      'position': varsha.muntha * 30.0 + 15.0, // Mid-sign
      'house': 0,
    };
    return map;
  }
}
