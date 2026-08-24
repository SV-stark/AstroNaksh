import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'report_styles.dart';

class PdfWidgets {
  static pw.Widget sectionHeader(String title, pw.TextStyle style) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: style),
        pw.SizedBox(height: 4),
        pw.Container(height: 2, width: 40, color: ReportStyles.accentColor),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget infoCard({
    required String title,
    required List<pw.Widget> children,
    pw.Widget? trailing,
  }) {
    return pw.Container(
      decoration: ReportStyles.cardDecoration,
      padding: ReportStyles.paddingMedium,
      margin: const pw.EdgeInsets.only(bottom: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: ReportStyles.primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              ?trailing,
            ],
          ),
          pw.Divider(color: PdfColors.grey200, thickness: 0.5),
          pw.SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  static pw.Widget premiumTable({
    required List<String> headers,
    required List<List<String>> rows,
    required pw.TextStyle bodyStyle,
  }) {
    return pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
      ),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: ReportStyles.primaryColor),
          children: headers
              .map(
                (h) => pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    h,
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        ...rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final color = index % 2 == 0 ? PdfColors.white : PdfColors.grey50;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: color),
            children: row
                .map(
                  (cell) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(cell, style: bodyStyle),
                  ),
                )
                .toList(),
          );
        }),
      ],
    );
  }

  static pw.Page premiumPage({
    required pw.Widget Function(pw.Context) build,
    pw.MemoryImage? backgroundImage,
    pw.MemoryImage? logo,
    pw.EdgeInsets? margin,
    String? brandOrgName,
    String? brandOrgTagline,
    String? brandContactInfo,
  }) {
    final edgeMargin = margin ?? const pw.EdgeInsets.all(32);
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
                    opacity: 0.05,
                    child: pw.Image(backgroundImage, fit: pw.BoxFit.cover),
                  ),
                ),
              pw.Padding(
                padding: edgeMargin,
                child: pw.Column(
                  children: [
                    // Header
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        if (logo != null)
                          pw.Image(logo, height: 30)
                        else
                          pw.Text(
                            brandOrgName ?? 'ASTRONAKSH',
                            style: pw.TextStyle(
                              color: ReportStyles.primaryColor,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 2,
                            ),
                          ),
                        pw.Text(
                          (brandOrgTagline ?? 'PREMIUM ASTROLOGY REPORT')
                              .toUpperCase(),
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
                    // Content
                    pw.Expanded(child: build(context)),
                    // Footer
                    pw.SizedBox(height: 20),
                    pw.Divider(color: PdfColors.grey200, thickness: 0.5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          brandContactInfo ??
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
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
