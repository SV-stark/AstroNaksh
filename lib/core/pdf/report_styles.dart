import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportStyles {
  // Colors
  static const primaryColor = PdfColor.fromInt(0xFF1A237E); // Indigo 900
  static const accentColor = PdfColor.fromInt(0xFFB8860B); // Dark Goldenrod
  static const textColor = PdfColor.fromInt(0xFF212121); // Grey 900
  static const secondaryTextColor = PdfColor.fromInt(0xFF757575); // Grey 600
  static const lightBackgroundColor = PdfColor.fromInt(0xFFFFF8E1); // Amber 50 (subtle cream)
  static const white = PdfColors.white;
  static const grey = PdfColors.grey;

  // Fonts (to be loaded asynchronously)
  static Future<pw.TextStyle> h1({pw.Font? font}) async {
    return pw.TextStyle(
      font: font ?? await PdfGoogleFonts.playfairDisplayBold(),
      fontSize: 28,
      color: primaryColor,
    );
  }

  static Future<pw.TextStyle> h2({pw.Font? font}) async {
    return pw.TextStyle(
      font: font ?? await PdfGoogleFonts.playfairDisplayBold(),
      fontSize: 22,
      color: primaryColor,
    );
  }

  static Future<pw.TextStyle> h3({pw.Font? font}) async {
    return pw.TextStyle(
      font: font ?? await PdfGoogleFonts.playfairDisplayBold(),
      fontSize: 18,
      color: accentColor,
    );
  }

  static Future<pw.TextStyle> body({pw.Font? font}) async {
    return pw.TextStyle(
      font: font ?? await PdfGoogleFonts.latoRegular(),
      fontSize: 11,
      color: textColor,
    );
  }

  static Future<pw.TextStyle> bodyBold({pw.Font? font}) async {
    return pw.TextStyle(
      font: font ?? await PdfGoogleFonts.latoBold(),
      fontSize: 11,
      color: textColor,
      fontWeight: pw.FontWeight.bold,
    );
  }

  static Future<pw.TextStyle> caption({pw.Font? font}) async {
    return pw.TextStyle(
      font: font ?? await PdfGoogleFonts.latoItalic(),
      fontSize: 9,
      color: secondaryTextColor,
    );
  }

  // Decorations
  static pw.BoxDecoration cardDecoration = pw.BoxDecoration(
    color: white,
    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    border: pw.Border.all(color: primaryColor.shade(0.1), width: 1),
  );

  static pw.EdgeInsets paddingLarge = const pw.EdgeInsets.all(20);
  static pw.EdgeInsets paddingMedium = const pw.EdgeInsets.all(12);
  static pw.EdgeInsets paddingSmall = const pw.EdgeInsets.all(8);
}
