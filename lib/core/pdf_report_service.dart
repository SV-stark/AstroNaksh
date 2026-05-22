import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';
import '../logic/matching/matching_models.dart';
import '../logic/varshaphal_system.dart';
import '../logic/yoga_dosha_analyzer.dart';
import 'pdf/pdf_widgets.dart';
import 'pdf/report_sections.dart';
import 'pdf/report_styles.dart';
import 'pdf_report_charts.dart';

/// Premium PDF Report Generation Service
class PDFReportService {
  /// Generate a complete premium PDF report for a chart
  static Future<File> generateReport(
    CompleteChartData chartData, {
    String? reportTitle,
    bool includeD1 = true,
    bool includeD9 = true,
    bool includeDasha = true,
    bool includeKP = true,
    bool includePredictions = true,
    bool includeDivisional = false,
    bool includeYogaDosha = true,
    bool includeAshtakavarga = false,
    bool includeShadbala = false,
    bool includeBhavaBala = false,
    bool includeTransit = false,
    bool includeLifePredictions = false,
    bool includeVarshaphal = false,
    Uint8List? coverImageBytes,
    Uint8List? bgImageBytes,
    PdfColor? customPrimaryColor,
    PdfColor? customAccentColor,
    Uint8List? logoBytes,
  }) async {
    final originalPrimaryColor = ReportStyles.primaryColor;
    final originalAccentColor = ReportStyles.accentColor;

    if (customPrimaryColor != null) {
      ReportStyles.primaryColor = customPrimaryColor;
    }
    if (customAccentColor != null) {
      ReportStyles.accentColor = customAccentColor;
    }

    try {
      final pdf = pw.Document();
      final title = reportTitle ?? 'Personalized Vedic Astrology Report';

      // Load assets & styles
      final font = await PdfGoogleFonts.playfairDisplayBold();
      final bodyFont = await PdfGoogleFonts.latoRegular();
      final bodyBoldFont = await PdfGoogleFonts.latoBold();

      final h2 = await ReportStyles.h2(font: font);
      final h3 = await ReportStyles.h3(font: font);
      final body = await ReportStyles.body(font: bodyFont);
      final bodyBold = await ReportStyles.bodyBold(font: bodyBoldFont);

      pw.MemoryImage? coverImage;
      if (coverImageBytes != null) {
        coverImage = pw.MemoryImage(coverImageBytes);
      }

      pw.MemoryImage? bgImage;
      if (bgImageBytes != null) {
        bgImage = pw.MemoryImage(bgImageBytes);
      }

      pw.MemoryImage? logo;
      if (logoBytes != null) {
        logo = pw.MemoryImage(logoBytes);
      }

      // 1. Cover Page
      pdf.addPage(
        ReportSections.buildCoverPage(
          chartData: chartData,
          title: title,
          coverImage: coverImage,
          backgroundImage: bgImage,
          logo: logo,
        ),
      );

      // 2. Summary & Predictions Page
      final summarySection = await ReportSections.buildSummarySection(
        chartData,
        h2,
        body,
        bodyBold,
      );
      pw.Widget? predictionSection;
      if (includePredictions || includeLifePredictions) {
        predictionSection = await ReportSections.buildPredictionSection(
          chartData,
          h2,
          h3,
          body,
        );
      }

      pdf.addPage(
        PdfWidgets.premiumPage(
          backgroundImage: bgImage,
          logo: logo,
          build: (context) => pw.Column(
            children: [
              summarySection,
              if (predictionSection != null) ...[
                pw.SizedBox(height: 20),
                predictionSection,
              ],
            ],
          ),
        ),
      );

      // 3. Birth Chart Section (D-1)
      if (includeD1) {
        pdf.addPage(
          PdfWidgets.premiumPage(
            backgroundImage: bgImage,
            logo: logo,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfWidgets.sectionHeader('Rashi Chart (D-1)', h2),
                pw.Text(
                  'The Rashi chart is the primary blueprint of your life, representing the physical manifestion and general destiny.',
                  style: body,
                ),
                pw.SizedBox(height: 30),
                pw.Center(
                  child: PdfReportCharts.drawPremiumNorthIndianChart(
                    chartData.significatorTable,
                    AstrologyConstants.signNames.indexOf(
                      chartData.baseChart.ascendantSign,
                    ),
                    width: 320,
                    height: 320,
                  ),
                ),
                pw.SizedBox(height: 40),
                PdfWidgets.sectionHeader('Planetary Positions', h3),
                PdfWidgets.premiumTable(
                  headers: ['Planet', 'Sign', 'Degree', 'House', 'Status'],
                  rows: chartData.baseChart.planets.entries.map((e) {
                    final p = e.value;
                    return [
                      e.key.displayName,
                      p.zodiacSign,
                      '${(p.longitude % 30).toStringAsFixed(2)}°',
                      'H${p.house}',
                      p.dignity.english,
                    ];
                  }).toList(),
                  bodyStyle: body,
                ),
              ],
            ),
          ),
        );
      }

      // 4. Navamsa Section (D-9)
      if (includeD9 && chartData.divisionalCharts.containsKey('D-9')) {
        final navamsa = chartData.divisionalCharts['D-9']!;
        pdf.addPage(
          PdfWidgets.premiumPage(
            backgroundImage: bgImage,
            logo: logo,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfWidgets.sectionHeader('Navamsa Chart (D-9)', h2),
                pw.Text(
                  'Navamsa is the most important divisional chart, representing the fruit of your actions and spiritual strength.',
                  style: body,
                ),
                pw.SizedBox(height: 30),
                pw.Center(
                  child: PdfReportCharts.drawPremiumNorthIndianChart(
                    _convertDivisionalToSignificators(navamsa),
                    navamsa.ascendantSign ?? 0,
                    width: 320,
                    height: 320,
                    lineColor: ReportStyles.accentColor,
                  ),
                ),
                pw.SizedBox(height: 40),
                PdfWidgets.sectionHeader('Navamsa Detail', h3),
                PdfWidgets.premiumTable(
                  headers: ['Planet', 'Sign', 'Degree', 'Lord'],
                  rows: navamsa.positions.entries.map((e) {
                    final sign = (e.value / 30).floor();
                    return [
                      e.key,
                      AstrologyConstants.signNames[sign],
                      '${(e.value % 30).toStringAsFixed(2)}°',
                      AstrologyConstants.getSignLord(sign).displayName,
                    ];
                  }).toList(),
                  bodyStyle: body,
                ),
              ],
            ),
          ),
        );
      }

      // Yogas & Doshas Section
      if (includeYogaDosha) {
        final yogaAnalysis = YogaDoshaAnalyzer.analyze(chartData);
        final yogaDoshaSection = await ReportSections.buildYogaDoshaSection(
          yogaAnalysis,
          h2,
          h3,
          body,
        );
        pdf.addPage(
          PdfWidgets.premiumPage(
            backgroundImage: bgImage,
            logo: logo,
            build: (context) => yogaDoshaSection,
          ),
        );
      }

      // Varshaphal Section
      if (includeVarshaphal) {
        final varsha = await VarshaphalSystem.calculateVarshaphal(
          chartData.birthData,
          DateTime.now().year,
        );

        final varshaPage1 = await ReportSections.buildVarshaphalPage1(
          varsha,
          h2,
          h3,
          body,
        );

        final varshaPage2 = await ReportSections.buildVarshaphalPage2(
          varsha,
          h2,
          h3,
          body,
        );

        // Page 1: Varsha Chart & Indicators
        pdf.addPage(
          PdfWidgets.premiumPage(
            backgroundImage: bgImage,
            logo: logo,
            build: (context) => varshaPage1,
          ),
        );

        // Page 2: Varsha Analysis (Dasha, Yogas, Sahams)
        pdf.addPage(
          PdfWidgets.premiumPage(
            backgroundImage: bgImage,
            logo: logo,
            build: (context) => varshaPage2,
          ),
        );
      }

      // 5. Dasha Section
      if (includeDasha) {
        pdf.addPage(
          PdfWidgets.premiumPage(
            backgroundImage: bgImage,
            logo: logo,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfWidgets.sectionHeader('Time Cycles (Vimshottari Dasha)', h2),
                pw.Text(
                  'Vedic astrology uses dasha cycles to predict when specific planetary influences will manifest in your life.',
                  style: body,
                ),
                pw.SizedBox(height: 20),
                PdfWidgets.premiumTable(
                  headers: ['Mahadasha', 'Period', 'Start Date', 'End Date'],
                  rows: chartData.dashaData.vimshottari.mahadashas
                      .map(
                        (m) => [
                          m.lord,
                          m.formattedPeriod,
                          _formatDate(m.startDate),
                          _formatDate(m.endDate),
                        ],
                      )
                      .toList(),
                  bodyStyle: body,
                ),
                pw.SizedBox(height: 30),
                PdfWidgets.sectionHeader('Current Planetary Influence', h3),
                pw.Text(
                  'You are currently undergoing the ${_getCurrentDashaText(chartData)} period.',
                  style: body,
                ),
              ],
            ),
          ),
        );

        // Retrieve active Mahadasha and Antardasha
        final now = DateTime.now();
        Mahadasha? tempM;
        for (final m in chartData.dashaData.vimshottari.mahadashas) {
          if (now.isAfter(m.startDate) && now.isBefore(m.endDate)) {
            tempM = m;
            break;
          }
        }
        final activeM =
            tempM ?? chartData.dashaData.vimshottari.mahadashas.first;

        Antardasha? tempA;
        for (final a in activeM.antardashas) {
          if (now.isAfter(a.startDate) && now.isBefore(a.endDate)) {
            tempA = a;
            break;
          }
        }
        final activeA = tempA ?? activeM.antardashas.first;

        final sookshmaRows = <List<String>>[];
        const vLords = [
          'Ketu',
          'Venus',
          'Sun',
          'Moon',
          'Mars',
          'Rahu',
          'Jupiter',
          'Saturn',
          'Mercury',
        ];
        const vYears = {
          'Ketu': 7,
          'Venus': 20,
          'Sun': 6,
          'Moon': 10,
          'Mars': 7,
          'Rahu': 18,
          'Jupiter': 16,
          'Saturn': 19,
          'Mercury': 17,
        };

        for (final pd in activeA.pratyantardashas) {
          final pdLord = pd.lord;
          final pdStart = pd.startDate;
          final pdEnd = pd.endDate;
          final durationMs = pdEnd.difference(pdStart).inMilliseconds;

          var startIdx = vLords.indexWhere(
            (l) => l.toLowerCase() == pdLord.toLowerCase(),
          );
          if (startIdx == -1) startIdx = 0;

          var currentStart = pdStart;
          for (var i = 0; i < 9; i++) {
            final lord = vLords[(startIdx + i) % 9];
            final ratio = vYears[lord]! / 120.0;
            final chunkMs = (durationMs * ratio).round();
            var currentEnd = currentStart.add(
              Duration(milliseconds: chunkMs),
            );

            if (i == 8) {
              currentEnd = pdEnd;
            }

            sookshmaRows.add([
              pd.lord, // Pratyantardasha Lord
              lord, // Sookshmadasha Lord
              _formatDate(currentStart),
              _formatDate(currentEnd),
            ]);

            currentStart = currentEnd;
          }
        }

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            header: (context) {
              return pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      if (logo != null)
                        pw.Image(logo, height: 30)
                      else
                        pw.Text(
                          'ASTRONAKSH',
                          style: pw.TextStyle(
                            color: ReportStyles.primaryColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 2,
                          ),
                        ),
                      pw.Text(
                        'PREMIUM ASTROLOGY REPORT',
                        style: const pw.TextStyle(
                          color: ReportStyles.grey,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: ReportStyles.accentColor, thickness: 0.5),
                  pw.SizedBox(height: 20),
                ],
              );
            },
            footer: (context) {
              return pw.Column(
                children: [
                  pw.SizedBox(height: 20),
                  pw.Divider(color: PdfColors.grey200, thickness: 0.5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '© ${DateTime.now().year} AstroNaksh - Vedic Insights',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey,
                        ),
                      ),
                      pw.Text(
                        'Page ${context.pageNumber} of ${context.pagesCount}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            build: (context) => [
              PdfWidgets.sectionHeader('Detailed 4-Level Dasha Breakdown', h2),
              pw.SizedBox(height: 5),
              pw.Text(
                'Detailed Vimshottari Sookshmadasha cycles under the active Mahadasha (${activeM.lord}) and active Antardasha (${activeA.lord}: ${_formatDate(activeA.startDate)} to ${_formatDate(activeA.endDate)}).',
                style: body,
              ),
              pw.SizedBox(height: 15),
              PdfWidgets.premiumTable(
                headers: [
                  'Pratyantardasha',
                  'Sookshmadasha',
                  'Start Date',
                  'End Date',
                ],
                rows: sookshmaRows,
                bodyStyle: body,
              ),
            ],
          ),
        );
      }

      // 6. KP Section
      if (includeKP) {
        pdf.addPage(
          PdfWidgets.premiumPage(
            backgroundImage: bgImage,
            logo: logo,
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                PdfWidgets.sectionHeader('KP Astrology (Sub-Lords)', h2),
                pw.Text(
                  'KP System provides precise timing and results based on Sub-Lord theory.',
                  style: body,
                ),
                pw.SizedBox(height: 20),
                PdfWidgets.premiumTable(
                  headers: ['Planet', 'Star Lord', 'Sub Lord', 'Sub-Sub Lord'],
                  rows: chartData.significatorTable.entries.map((e) {
                    final info = e.value;
                    return [
                      e.key,
                      info['starLord']?.toString() ?? 'N/A',
                      info['subLord']?.toString() ?? 'N/A',
                      info['subSubLord']?.toString() ?? 'N/A',
                    ];
                  }).toList(),
                  bodyStyle: body,
                ),
              ],
            ),
          ),
        );
      }

      // 7. Transit Section
      if (includeTransit) {
        final transitSection = await ReportSections.buildTransitSection(
          chartData,
          h2,
          h3,
          body,
        );
        pdf.addPage(
          PdfWidgets.premiumPage(
            backgroundImage: bgImage,
            logo: logo,
            build: (context) => transitSection,
          ),
        );
      }

      // Save PDF
      final output = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'premium_report_$timestamp.pdf';
      final filePath = '${output.path}${Platform.pathSeparator}$filename';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      return file;
    } finally {
      ReportStyles.primaryColor = originalPrimaryColor;
      ReportStyles.accentColor = originalAccentColor;
    }
  }

  /// Generate a matching report for two people
  static Future<File> generateMatchingReport(
    CompleteChartData chart1,
    CompleteChartData chart2,
    MatchingReport report,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.playfairDisplayBold();
    final h2 = await ReportStyles.h2(font: font);
    final bodyFont = await PdfGoogleFonts.latoRegular();
    final body = await ReportStyles.body(font: bodyFont);

    pdf.addPage(
      PdfWidgets.premiumPage(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            PdfWidgets.sectionHeader('Kundali Matching Analysis', h2),
            pw.Text(
              'A comprehensive Vedic matching analysis for ${chart1.birthData.name} and ${chart2.birthData.name}.',
              style: body,
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              'Ashtakoota Score: ${report.ashtakootaScore}/36',
              style: h2,
            ),
            pw.Text('Conclusion: ${report.overallConclusion}', style: body),
            pw.SizedBox(height: 20),
            PdfWidgets.premiumTable(
              headers: ['Koota', 'Score', 'Status', 'Description'],
              rows: report.kootaResults
                  .map(
                    (k) => [
                      k.name,
                      '${k.score}/${k.maxScore}',
                      k.description,
                      k.detailedReason,
                    ],
                  )
                  .toList(),
              bodyStyle: body,
            ),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/matching_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Print or preview the report
  static Future<void> printReport(File file) async {
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (format) => bytes);
  }

  static Map<String, Map<String, dynamic>> _convertDivisionalToSignificators(
    DivisionalChartData data,
  ) {
    final map = <String, Map<String, dynamic>>{};
    data.positions.forEach((planet, longitude) {
      map[planet] = {'position': longitude, 'house': 0};
    });
    return map;
  }

  static String _getCurrentDashaText(CompleteChartData chartData) {
    final current = chartData.getCurrentDashas(DateTime.now());
    if (current.isEmpty) return 'N/A';
    return '${current['mahadasha']} - ${current['antardasha']} - ${current['pratyantardasha']}';
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static Future<void> shareReport(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'My Vedic Astrology Report from AstroNaksh',
      ),
    );
  }
}
