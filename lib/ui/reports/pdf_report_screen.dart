import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models.dart';
import '../../logic/pdf_report_generator.dart';

class PDFReportScreen extends StatefulWidget {
  final CompleteChartData chartData;

  const PDFReportScreen({super.key, required this.chartData});

  @override
  State<PDFReportScreen> createState() => _PDFReportScreenState();
}

class _PDFReportScreenState extends State<PDFReportScreen> {
  String _reportType = 'comprehensive';
  bool _isGenerating = false;

  final Map<String, bool> _sections = {
    'Basic Info': true,
    'Chart Diagram': true,
    'Planetary Positions': true,
    'Dasha Periods': true,
    'Ashtakavarga': false,
    'Shadbala': false,
    'Bhava Bala': false,
    'Yogas & Doshas': true,
    'Transit Analysis': false,
    'KP System': true,
  };

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Generate PDF Report')),
      content: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            backgroundColor: Colors.teal.withOpacity(0.1),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PDF Report Generator',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a comprehensive astrological report in PDF format. '
                    'Select the sections you want to include in your report.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Report type selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ComboBox<String>(
                      value: _reportType,
                      items: const [
                        ComboBoxItem(
                          value: 'basic',
                          child: Text('Basic Report'),
                        ),
                        ComboBoxItem(
                          value: 'standard',
                          child: Text('Standard Report'),
                        ),
                        ComboBoxItem(
                          value: 'comprehensive',
                          child: Text('Comprehensive Report'),
                        ),
                        ComboBoxItem(
                          value: 'custom',
                          child: Text('Custom Report'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _reportType = value;
                            _updateSectionsByType(value);
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section selection
          if (_reportType == 'custom')
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Sections',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._sections.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Checkbox(
                          content: Text(entry.key),
                          checked: entry.value,
                          onChanged: (value) {
                            setState(() {
                              _sections[entry.key] = value ?? false;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Generate button
          FilledButton(
            onPressed: _isGenerating ? null : _generateReport,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isGenerating) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                  ] else ...[
                    const Icon(FluentIcons.pdf),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    _isGenerating ? 'Generating...' : 'Generate PDF Report',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateSectionsByType(String type) {
    switch (type) {
      case 'basic':
        _sections.updateAll(
          (key, value) => [
            'Basic Info',
            'Chart Diagram',
            'Planetary Positions',
          ].contains(key),
        );
        break;
      case 'standard':
        _sections.updateAll(
          (key, value) => ![
            'Ashtakavarga',
            'Shadbala',
            'Bhava Bala',
            'Transit Analysis',
          ].contains(key),
        );
        break;
      case 'comprehensive':
        _sections.updateAll((key, value) => true);
        break;
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      Directory? dir;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        dir = await getDownloadsDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      if (dir == null) {
        throw Exception('Could not determine downloads directory');
      }

      final name = widget.chartData.birthData.name.isNotEmpty
          ? widget.chartData.birthData.name
          : 'Unknown';

      final place = widget.chartData.birthData.place.isNotEmpty
          ? widget.chartData.birthData.place
          : 'Place';

      final filename = '$name - $place.pdf'.replaceAll(
        RegExp(r'[<>:"/\\|?*]'),
        '_',
      ); // Sanitize filename

      // Ensure directory exists
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final path = '${dir.path}${Platform.pathSeparator}$filename';

      await PdfReportGenerator.generateBirthChartReport(
        widget.chartData,
        widget.chartData.birthData,
        outputPath: path,
      );

      if (!mounted) return;

      displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Report Generated'),
            content: Text('Saved to: $path'),
            severity: InfoBarSeverity.success,
            action: Button(
              onPressed: () {
                // TODO: Open file
                // On Windows strictly, we can use Process.run('explorer', [path])
              },
              child: const Text('Open'),
            ),
            onClose: close,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Error'),
            content: Text('Error generating report: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}
