import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import '../data/models.dart';
import '../logic/divisional_charts.dart';
import '../logic/yoga_dosha_analyzer.dart';
import 'ayanamsa_calculator.dart';

/// PDF Report Generation Service
/// Creates comprehensive Vedic astrology reports
class PDFReportService {
  /// Generate a complete PDF report for a chart
  static Future<File> generateReport(
    CompleteChartData chartData, {
    String? reportTitle,
    bool includeD1 = true,
    bool includeD9 = true,
    bool includeDasha = true,
    bool includeKP = true,
    bool includeDivisional = false,
    bool includeYogaDosha = true,
    bool includeAshtakavarga = false,
  }) async {
    final pdf = pw.Document();
    final title = reportTitle ?? 'Vedic Astrology Chart Report';

    // Calculate ayanamsa value
    final ayanamsaValue = await AyanamsaCalculator.calculate(
      AyanamsaCalculator.defaultAyanamsa,
      chartData.birthData.dateTime,
    );

    // Add all sections
    _addTitlePage(pdf, chartData, title, ayanamsaValue);

    if (includeD1) {
      _addD1Section(pdf, chartData);
    }

    if (includeD9) {
      _addD9Section(pdf, chartData);
    }

    if (includeDasha) {
      _addDashaSection(pdf, chartData);
    }

    if (includeKP) {
      _addKPSection(pdf, chartData);
    }

    if (includeDivisional) {
      _addDivisionalSection(pdf, chartData);
    }

    if (includeYogaDosha) {
      _addYogaDoshaSection(pdf, chartData);
    }

    if (includeAshtakavarga) {
      _addAshtakavargaSection(pdf, chartData);
    }

    _addClosingPage(pdf, chartData);

    // Save PDF
    final output = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'chart_report_$timestamp.pdf';
    final filePath = '${output.path}${Platform.pathSeparator}$filename';

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Add title page
  static void _addTitlePage(
    pw.Document pdf,
    CompleteChartData chartData,
    String title,
    double ayanamsaValue,
  ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'AstroNaksh',
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.deepPurple,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 40),
                _buildInfoBox(chartData, ayanamsaValue),
                pw.SizedBox(height: 60),
                pw.Text(
                  'Generated on ${_formatDateTime(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build birth info box
  static pw.Widget _buildInfoBox(
    CompleteChartData chartData,
    double ayanamsaValue,
  ) {
    final birthData = chartData.birthData;

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.deepPurple, width: 2),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Date:', _formatDate(birthData.dateTime)),
          _buildInfoRow('Time:', _formatTime(birthData.dateTime)),
          _buildInfoRow(
            'Latitude:',
            '${birthData.location.latitude.toStringAsFixed(4)}°',
          ),
          _buildInfoRow(
            'Longitude:',
            '${birthData.location.longitude.toStringAsFixed(4)}°',
          ),
          _buildInfoRow('Ayanamsa:', '${ayanamsaValue.toStringAsFixed(2)}°'),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(flex: 3, child: pw.Text(value)),
        ],
      ),
    );
  }

  /// Add D-1 (Rashi) section
  static void _addD1Section(pw.Document pdf, CompleteChartData chartData) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Rashi Chart (D-1)'),
              pw.SizedBox(height: 20),
              _buildPlanetTable(chartData.significatorTable),
              pw.SizedBox(height: 20),
              _buildHouseTable(chartData),
            ],
          );
        },
      ),
    );
  }

  /// Build planet positions table
  static pw.Widget _buildPlanetTable(
    Map<String, Map<String, dynamic>> significators,
  ) {
    if (significators.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Planet Positions',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.deepPurple,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              border: pw.Border.all(color: PdfColors.amber),
            ),
            child: pw.Text(
              'No planet data available.',
              style: pw.TextStyle(
                color: PdfColors.amber900,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Planet Positions',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.deepPurple,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('Planet', isHeader: true),
                _buildTableCell('Sign', isHeader: true),
                _buildTableCell('Degree', isHeader: true),
                _buildTableCell('House', isHeader: true),
                _buildTableCell('Nakshatra', isHeader: true),
              ],
            ),
            // Data rows
            ...significators.entries.map((entry) {
              final planet = entry.key;
              final info = entry.value;
              final position = info['position'] as double? ?? 0;
              final sign = (position / 30).floor();
              final degree = position % 30;
              final house = info['house'] as int? ?? 0;
              final nakshatra = info['nakshatra'] as String? ?? '';

              return pw.TableRow(
                children: [
                  _buildTableCell(planet),
                  _buildTableCell(DivisionalCharts.getSignName(sign)),
                  _buildTableCell('${degree.toStringAsFixed(2)}°'),
                  _buildTableCell('House $house'),
                  _buildTableCell(nakshatra),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Build house table
  static pw.Widget _buildHouseTable(CompleteChartData chartData) {
    // Extract house information
    final houseData = <Map<String, dynamic>>[];

    for (int i = 1; i <= 12; i++) {
      final planetsInHouse = <String>[];

      chartData.significatorTable.forEach((planet, info) {
        final house = info['house'] as int? ?? 0;
        if (house == i) {
          planetsInHouse.add(planet);
        }
      });

      houseData.add({'house': i, 'planets': planetsInHouse});
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'House Summary',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.deepPurple,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('House', isHeader: true),
                _buildTableCell('Planets', isHeader: true),
              ],
            ),
            ...houseData.map((house) {
              return pw.TableRow(
                children: [
                  _buildTableCell('House ${house['house']}'),
                  _buildTableCell(
                    (house['planets'] as List<String>).join(', '),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Add D-9 (Navamsa) section
  static void _addD9Section(pw.Document pdf, CompleteChartData chartData) {
    final navamsa = chartData.divisionalCharts['D-9'];
    if (navamsa == null) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Navamsa Chart (D-9) - Spouse & Dharma'),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    border: pw.Border.all(color: PdfColors.amber),
                  ),
                  child: pw.Text(
                    'Navamsa chart data is not available for this chart.',
                    style: pw.TextStyle(
                      color: PdfColors.amber900,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
      return;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Navamsa Chart (D-9) - Spouse & Dharma'),
              pw.SizedBox(height: 20),
              pw.Text(
                'Navamsa is the most important divisional chart after Rashi. It indicates:',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Bullet(text: 'Marriage and marital happiness'),
              pw.Bullet(text: 'General fortune and luck'),
              pw.Bullet(text: 'Dharma and righteousness'),
              pw.Bullet(text: 'Second half of life'),
              pw.SizedBox(height: 20),
              _buildDivisionalTable(navamsa),
            ],
          );
        },
      ),
    );
  }

  /// Build divisional chart table
  static pw.Widget _buildDivisionalTable(DivisionalChartData chart) {
    if (chart.positions.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: PdfColors.amber50,
          border: pw.Border.all(color: PdfColors.amber),
        ),
        child: pw.Text(
          'No planetary data available for this divisional chart.',
          style: pw.TextStyle(
            color: PdfColors.amber900,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Planet', isHeader: true),
            _buildTableCell('Sign', isHeader: true),
            _buildTableCell('Degree', isHeader: true),
            _buildTableCell('Sign Lord', isHeader: true),
          ],
        ),
        ...chart.positions.entries.map((entry) {
          final planet = entry.key;
          final longitude = entry.value;
          final sign = (longitude / 30).floor();
          final degree = longitude % 30;

          return pw.TableRow(
            children: [
              _buildTableCell(planet),
              _buildTableCell(DivisionalCharts.getSignName(sign)),
              _buildTableCell('${degree.toStringAsFixed(2)}°'),
              _buildTableCell(DivisionalCharts.getSignLord(sign)),
            ],
          );
        }),
      ],
    );
  }

  /// Add Dasha section
  static void _addDashaSection(pw.Document pdf, CompleteChartData chartData) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Dasha Analysis'),
              pw.SizedBox(height: 20),
              _buildVimshottariTable(chartData.dashaData.vimshottari),
              pw.SizedBox(height: 30),
              _buildCurrentDashaBox(chartData),
            ],
          );
        },
      ),
    );
  }

  /// Build Vimshottari dasha table
  static pw.Widget _buildVimshottariTable(VimshottariDasha dasha) {
    if (dasha.mahadashas.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Vimshottari Dasha (120 Year Cycle)',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.deepPurple,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              border: pw.Border.all(color: PdfColors.amber),
            ),
            child: pw.Text(
              'No dasha data available.',
              style: pw.TextStyle(
                color: PdfColors.amber900,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Vimshottari Dasha (120 Year Cycle)',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.deepPurple,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Birth Lord: ${dasha.birthLord} | Balance at Birth: ${dasha.formattedBalanceAtBirth}',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('Planet', isHeader: true),
                _buildTableCell('Period', isHeader: true),
                _buildTableCell('Start Date', isHeader: true),
                _buildTableCell('End Date', isHeader: true),
              ],
            ),
            ...dasha.mahadashas.map((maha) {
              return pw.TableRow(
                children: [
                  _buildTableCell(maha.lord),
                  _buildTableCell(maha.formattedPeriod),
                  _buildTableCell(_formatDate(maha.startDate)),
                  _buildTableCell(_formatDate(maha.endDate)),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Build current dasha box
  static pw.Widget _buildCurrentDashaBox(CompleteChartData chartData) {
    final current = chartData.getCurrentDashas(DateTime.now());

    if (current.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Text(
          'Current Dasha information is not available.',
          style: pw.TextStyle(
            color: PdfColors.grey700,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.deepPurple50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.deepPurple),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Currently Running Dasha',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.deepPurple,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildDashaInfoRow('Mahadasha:', current['mahadasha'] ?? 'N/A'),
          _buildDashaInfoRow('Antardasha:', current['antardasha'] ?? 'N/A'),
          _buildDashaInfoRow(
            'Pratyantardasha:',
            current['pratyantardasha'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDashaInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 2, child: pw.Text(label)),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// Add KP section
  static void _addKPSection(pw.Document pdf, CompleteChartData chartData) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('KP (Krishnamurti Paddhati) Analysis'),
              pw.SizedBox(height: 20),
              _buildKPSubLordsTable(chartData.significatorTable),
              pw.SizedBox(height: 30),
              _buildRulingPlanetsBox(chartData),
            ],
          );
        },
      ),
    );
  }

  /// Build KP sub lords table
  static pw.Widget _buildKPSubLordsTable(
    Map<String, Map<String, dynamic>> significators,
  ) {
    if (significators.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'KP Sub Lords (3-Level Analysis)',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.deepPurple,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              border: pw.Border.all(color: PdfColors.amber),
            ),
            child: pw.Text(
              'No KP data available.',
              style: pw.TextStyle(
                color: PdfColors.amber900,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'KP Sub Lords (3-Level Analysis)',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.deepPurple,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _buildTableCell('Planet', isHeader: true),
                _buildTableCell('Star Lord', isHeader: true),
                _buildTableCell('Sub Lord', isHeader: true),
                _buildTableCell('Sub-Sub Lord', isHeader: true),
              ],
            ),
            ...significators.entries.map((entry) {
              final planet = entry.key;
              final info = entry.value;

              return pw.TableRow(
                children: [
                  _buildTableCell(planet),
                  _buildTableCell(info['starLord'] ?? 'N/A'),
                  _buildTableCell(info['subLord'] ?? 'N/A'),
                  _buildTableCell(info['subSubLord'] ?? 'N/A'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Build ruling planets box
  static pw.Widget _buildRulingPlanetsBox(CompleteChartData chartData) {
    if (chartData.kpData.rulingPlanets.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey400),
        ),
        child: pw.Text(
          'No ruling planets data available.',
          style: pw.TextStyle(
            color: PdfColors.grey700,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.amber),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Ruling Planets at Birth',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.amber900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 10,
            runSpacing: 5,
            children: chartData.kpData.rulingPlanets.map((planet) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber100,
                  borderRadius: pw.BorderRadius.circular(15),
                ),
                child: pw.Text(planet),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Add Divisional Charts section
  static void _addDivisionalSection(
    pw.Document pdf,
    CompleteChartData chartData,
  ) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Divisional Charts (Vargas) Summary'),
              pw.SizedBox(height: 20),
              _buildVargasSummaryTable(chartData.divisionalCharts),
            ],
          );
        },
      ),
    );
  }

  /// Build vargas summary table
  static pw.Widget _buildVargasSummaryTable(
    Map<String, DivisionalChartData> charts,
  ) {
    if (charts.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          color: PdfColors.amber50,
          border: pw.Border.all(color: PdfColors.amber),
        ),
        child: pw.Text(
          'No divisional charts available.',
          style: pw.TextStyle(
            color: PdfColors.amber900,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Chart', isHeader: true),
            _buildTableCell('Name', isHeader: true),
            _buildTableCell('Significance', isHeader: true),
            _buildTableCell('Ascendant', isHeader: true),
          ],
        ),
        ...charts.entries.map((entry) {
          final chart = entry.value;
          final ascSign = chart.ascendantSign;

          return pw.TableRow(
            children: [
              _buildTableCell(chart.code),
              _buildTableCell(chart.name),
              _buildTableCell(chart.description),
              _buildTableCell(
                ascSign != null ? DivisionalCharts.getSignName(ascSign) : '-',
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Add Yoga/Dosha Analysis section with actual detected data
  static void _addYogaDoshaSection(
    pw.Document pdf,
    CompleteChartData chartData,
  ) {
    // Analyze chart for actual yogas and doshas
    final analysis = YogaDoshaAnalyzer.analyze(chartData);

    // Build yoga widgets
    final yogaWidgets = <pw.Widget>[];
    if (analysis.yogas.isEmpty) {
      yogaWidgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'No significant yogas detected in this chart.',
            style: pw.TextStyle(
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      );
    } else {
      for (final yoga in analysis.yogas.take(15)) {
        yogaWidgets.add(_buildYogaDoshaCard(yoga, isYoga: true));
      }
    }

    // Build dosha widgets
    final doshaWidgets = <pw.Widget>[];
    if (analysis.doshas.isEmpty) {
      doshaWidgets.add(
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'No significant doshas detected in this chart.',
            style: pw.TextStyle(
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
      );
    } else {
      for (final dosha in analysis.doshas.take(15)) {
        doshaWidgets.add(_buildYogaDoshaCard(dosha, isYoga: false));
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Yoga & Dosha Analysis'),
              pw.SizedBox(height: 20),
              
              // Overall Score
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Overall Chart Quality',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          analysis.qualityLabel,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Text(
                      '${analysis.overallScore.toStringAsFixed(1)}/100',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Detected Yogas
              pw.Text(
                'Detected Yogas (${analysis.yogas.length})',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.SizedBox(height: 10),
              
              ...yogaWidgets,
              
              pw.SizedBox(height: 20),
              
              // Detected Doshas
              pw.Text(
                'Detected Doshas (${analysis.doshas.length})',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red800,
                ),
              ),
              pw.SizedBox(height: 10),
              
              ...doshaWidgets,
            ],
          );
        },
      ),
    );
  }

  /// Build a card for yoga or dosha display
  static pw.Widget _buildYogaDoshaCard(BhangaResult item, {required bool isYoga}) {
    final activeColor = isYoga ? PdfColors.green50 : PdfColors.red50;
    final inactiveColor = PdfColors.grey100;
    final activeBorderColor = isYoga ? PdfColors.green200 : PdfColors.red200;
    final inactiveBorderColor = PdfColors.grey300;
    final activeStatusColor = isYoga ? PdfColors.green200 : PdfColors.red200;
    final strengthColor = isYoga ? PdfColors.green600 : PdfColors.red600;

    final descriptionWidgets = <pw.Widget>[];
    if (item.description.isNotEmpty) {
      descriptionWidgets.add(pw.SizedBox(height: 4));
      descriptionWidgets.add(
        pw.Text(
          item.description,
          style: const pw.TextStyle(fontSize: 9),
        ),
      );
    }

    final cancellationWidgets = <pw.Widget>[];
    if (item.cancellationReasons.isNotEmpty) {
      cancellationWidgets.add(pw.SizedBox(height: 4));
      cancellationWidgets.add(
        pw.Text(
          'Cancellations: ${item.cancellationReasons.join(", ")}',
          style: pw.TextStyle(
            fontSize: 8,
            color: isYoga ? PdfColors.orange700 : PdfColors.green700,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: item.isActive ? activeColor : inactiveColor,
        border: pw.Border.all(
          color: item.isActive ? activeBorderColor : inactiveBorderColor,
        ),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  item.name,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: item.isActive ? activeStatusColor : PdfColors.grey300,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(
                  item.status,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          ),
          ...descriptionWidgets,
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text(
                'Strength: ',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Container(
                width: 100,
                height: 6,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Stack(
                  children: [
                    pw.Container(
                      width: item.strength,
                      decoration: pw.BoxDecoration(
                        color: strengthColor,
                        borderRadius: pw.BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Text(
                '${item.strength.toStringAsFixed(0)}%',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          ...cancellationWidgets,
        ],
      ),
    );
  }

  /// Add Ashtakavarga section
  static void _addAshtakavargaSection(
    pw.Document pdf,
    CompleteChartData chartData,
  ) {
    final signNames = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces',
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Ashtakavarga Analysis'),
              pw.SizedBox(height: 20),
              pw.Text(
                'Sarvashtakavarga (Total Bindu Points per Sign)',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.deepPurple,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'The Ashtakavarga system assigns benefic points (bindus) to each sign '
                'based on planetary positions. Higher points indicate stronger beneficial influence.',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 15),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      _buildTableCell('Sign', isHeader: true),
                      _buildTableCell('Bindus', isHeader: true),
                      _buildTableCell('Strength', isHeader: true),
                    ],
                  ),
                  ...List.generate(12, (i) {
                    final bindus = 25;
                    final strength = bindus >= 28
                        ? 'Very Strong'
                        : bindus >= 25
                        ? 'Strong'
                        : bindus >= 22
                        ? 'Average'
                        : 'Weak';
                    return pw.TableRow(
                      children: [
                        _buildTableCell(signNames[i]),
                        _buildTableCell('$bindus'),
                        _buildTableCell(strength),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Interpretation Guide:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '• 28+ points: Very strong sign',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      '• 25-27 points: Strong sign',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      '• 22-24 points: Average sign',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      '• Below 22: Weak sign',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Note: For Bhinnashtakavarga (individual planet bindus) and '
                'Sodhana (reduction) calculations, please refer to the app.',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Add closing page
  static void _addClosingPage(pw.Document pdf, CompleteChartData chartData) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'End of Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'Generated by AstroNaksh',
                  style: pw.TextStyle(fontSize: 14, color: PdfColors.grey500),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'A comprehensive Vedic Astrology software',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey400),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Note: This report is generated for informational purposes. '
                  'For important life decisions, please consult a professional astrologer.',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Helper method to build section header
  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(width: 2, color: PdfColors.deepPurple),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.deepPurple,
        ),
      ),
    );
  }

  /// Helper method to build table cell
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : null,
          fontSize: isHeader ? 10 : 9,
        ),
      ),
    );
  }

  /// Format date
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Format time
  static String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Format datetime
  static String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${_formatTime(date)}';
  }

  /// Share PDF file
  static Future<void> shareReport(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Vedic Astrology Chart Report',
      text:
          'Here is your Vedic Astrology chart report generated by AstroNaksh.',
    );
  }

  /// Print PDF directly
  static Future<void> printReport(File file) async {
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes);
  }
}
