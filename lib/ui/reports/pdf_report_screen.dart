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
  double _generationProgress = 0.0;
  String _generationStatus = '';

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
      header: PageHeader(
        title: const Text('Generate PDF Report'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            backgroundColor: Colors.teal.withValues(alpha: 0.1),
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
                    _isGenerating
                        ? _generationStatus.isNotEmpty
                            ? '$_generationStatus (${(_generationProgress * 100).toInt()}%)'
                            : 'Generating...'
                        : 'Generate PDF Report',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  ProgressBar(
                    value: _generationProgress,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _generationStatus,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
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
      _generationProgress = 0.0;
      _generationStatus = 'Initializing...';
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

      final sanitized = '$name - $place'
          .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
          .trim()
          .replaceAll(RegExp(r'_+'), '_');

      final filename = '$sanitized.pdf';

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final path = '${dir.path}${Platform.pathSeparator}$filename';

      if (mounted) {
        setState(() {
          _generationProgress = 0.3;
          _generationStatus = 'Generating PDF content...';
        });
      }

      await PdfReportGenerator.generateBirthChartReport(
        widget.chartData,
        widget.chartData.birthData,
        outputPath: path,
      );

      if (mounted) {
        setState(() {
          _generationProgress = 1.0;
          _generationStatus = 'Complete!';
        });
      }

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
                try {
                  final file = File(path);
                  if (!file.existsSync()) {
                    throw Exception('File not found');
                  }

                  if (Platform.isWindows) {
                    Process.run('explorer', ['/select,', path]);
                  } else if (Platform.isMacOS) {
                    Process.run('open', [path]);
                  } else if (Platform.isLinux) {
                    Process.run('xdg-open', [path]);
                  }
                } catch (e) {
                  if (context.mounted) {
                    displayInfoBar(
                      context,
                      builder: (context, close) {
                        return InfoBar(
                          title: const Text('Unable to Open'),
                          content: Text('Could not open file: $e'),
                          severity: InfoBarSeverity.warning,
                          onClose: close,
                        );
                      },
                    );
                  }
                }
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
