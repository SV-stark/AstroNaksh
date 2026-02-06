import 'dart:io';

import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models.dart';
import 'pdf_report_service.dart';

class ChartShareService {
  /// Capture a widget as an image and share it
  static Future<void> shareChartImage(
    GlobalKey key, {
    String filename = 'astronaksh_chart.png',
  }) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Could not find render boundary for chart");
      }

      // Convert layout to image
      // Increasing pixelRatio for better quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to capture image data");
      }

      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pngBytes);

      // Share the file
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Shared from AstroNaksh');
    } catch (e) {
      debugPrint("Error sharing image: $e");
      rethrow;
    }
  }

  /// Generate and share the PDF report
  static Future<void> shareChartPdf(
    CompleteChartData chartData,
    BirthData birthData, {
    String filename = 'astronaksh_report.pdf',
  }) async {
    try {
      // Generate PDF using PDFReportService
      final pdfFile = await PDFReportService.generateReport(
        chartData,
        reportTitle: '${birthData.name} - Birth Chart Report',
      );

      // Copy to temp with desired filename
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/$filename';
      final file = await pdfFile.copy(path);

      if (await file.exists()) {
        await Share.shareXFiles([
          XFile(path),
        ], text: 'Vedic Astrology Report from AstroNaksh');
      } else {
        throw Exception("PDF generation failed: File not found");
      }
    } catch (e) {
      debugPrint("Error sharing PDF: $e");
      rethrow;
    }
  }
}
