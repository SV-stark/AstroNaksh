// ignore_for_file: avoid_slow_async_io, unawaited_futures, deprecated_member_use, sort_constructors_first, implementation_imports
import 'dart:io';
import 'dart:typed_data';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import '../../core/pdf_report_service.dart';
import '../../data/models.dart';
import '../../ui/utils/responsive_helper.dart';

class ColorPalette {
  final String name;
  final Color primary;
  final Color accent;
  const ColorPalette({required this.name, required this.primary, required this.accent});
}

const List<ColorPalette> _predefinedPalettes = [
  ColorPalette(
    name: 'Imperial',
    primary: Color(0xFF1A237E), // Indigo 900
    accent: Color(0xFFB8860B),  // Dark Goldenrod
  ),
  ColorPalette(
    name: 'Royal Crimson',
    primary: Color(0xFF800000), // Maroon
    accent: Color(0xFFCD7F32),  // Bronze
  ),
  ColorPalette(
    name: 'Forest Jade',
    primary: Color(0xFF1B5E20), // Forest Green
    accent: Color(0xFF8FBC8F),  // Sage
  ),
  ColorPalette(
    name: 'Classic Navy',
    primary: Color(0xFF0D47A1), // Deep Blue
    accent: Color(0xFFFFB300),  // Amber
  ),
];

class PDFReportScreen extends StatefulWidget {
  const PDFReportScreen({super.key, required this.chartData});
  final CompleteChartData chartData;

  @override
  State<PDFReportScreen> createState() => _PDFReportScreenState();
}

class _PDFReportScreenState extends State<PDFReportScreen> {
  String _reportType = 'comprehensive';
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String _generationStatus = '';

  late final TextEditingController _titleController;
  late final TextEditingController _primaryColorController;
  late final TextEditingController _accentColorController;
  Color _primaryColor = const Color(0xFF1A237E);
  Color _accentColor = const Color(0xFFB8860B);
  File? _logoFile;
  Uint8List? _logoBytes;

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
    'Life Predictions': false,
    'Varshaphal (Annual)': false,
  };

  @override
  void initState() {
    super.initState();
    final name = widget.chartData.birthData.name.isNotEmpty
        ? widget.chartData.birthData.name
        : 'Unknown';
    _titleController = TextEditingController(
      text: '$name - Birth Chart Report',
    );
    _primaryColorController = TextEditingController(
      text: '#${_primaryColor.value.toRadixString(16).substring(2).toUpperCase()}',
    );
    _accentColorController = TextEditingController(
      text: '#${_accentColor.value.toRadixString(16).substring(2).toUpperCase()}',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _primaryColorController.dispose();
    _accentColorController.dispose();
    super.dispose();
  }

  Color? _parseHexColor(String hex) {
    var cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }
    if (cleaned.length != 8) return null;
    final val = int.tryParse(cleaned, radix: 16);
    if (val == null) return null;
    return Color(val);
  }

  void _selectPalette(ColorPalette palette) {
    setState(() {
      _primaryColor = palette.primary;
      _accentColor = palette.accent;
      _primaryColorController.text = '#${palette.primary.value.toRadixString(16).substring(2).toUpperCase()}';
      _accentColorController.text = '#${palette.accent.value.toRadixString(16).substring(2).toUpperCase()}';
    });
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final bytes = await file.readAsBytes();
        setState(() {
          _logoFile = file;
          _logoBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking logo: $e');
    }
  }

  void _clearLogo() {
    setState(() {
      _logoFile = null;
      _logoBytes = null;
    });
  }

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
      content: SingleChildScrollView(
        padding: context.responsiveBodyPadding,
        child: context.isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(),
                  const SizedBox(height: 16),
                  _buildPreviewCard(),
                  const SizedBox(height: 16),
                  _buildCustomizationForm(),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildIntroCard(),
                        const SizedBox(height: 16),
                        _buildCustomizationForm(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildPreviewCard(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Card(
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
              'Select the sections you want to include, customize the color theme, '
              'and upload a custom logo for a fully branded experience.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Live Cover Page Preview',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildLivePreview(),
            const SizedBox(height: 8),
            const Text(
              'Mockup of the premium PDF cover page.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreview() {
    final name = widget.chartData.birthData.name.isNotEmpty
        ? widget.chartData.birthData.name
        : 'Unknown';
    final dateStr = '${widget.chartData.birthData.dateTime.day.toString().padLeft(2, '0')}/${widget.chartData.birthData.dateTime.month.toString().padLeft(2, '0')}/${widget.chartData.birthData.dateTime.year}';
    final place = widget.chartData.birthData.place.isNotEmpty
        ? widget.chartData.birthData.place
        : 'Unknown Place';

    return Container(
      width: 260,
      height: 360,
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _accentColor.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: _PreviewPatternPainter(_accentColor),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      if (_logoBytes != null)
                        Image.memory(
                          _logoBytes!,
                          height: 48,
                          fit: BoxFit.contain,
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: _accentColor, width: 1.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ASTRONAKSH',
                            style: GoogleFonts.lato(
                              color: _accentColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Container(
                        height: 1.5,
                        width: 40,
                        color: _accentColor,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      _titleController.text,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: _accentColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: _accentColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateStr | $place',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaletteSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Theme Palette',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _predefinedPalettes.map((palette) {
            final isSelected = _primaryColor.value == palette.primary.value &&
                _accentColor.value == palette.accent.value;

            return Button(
              style: ButtonStyle(
                padding: ButtonState.all(EdgeInsets.zero),
                border: ButtonState.all(
                  BorderSide(
                    color: isSelected
                        ? FluentTheme.of(context).accentColor
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              onPressed: () => _selectPalette(palette),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: palette.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(palette.name),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomColorInputs() {
    return Row(
      children: [
        Expanded(
          child: InfoLabel(
            label: 'Primary Color (Hex)',
            child: TextBox(
              controller: _primaryColorController,
              placeholder: '#1A237E',
              onChanged: (val) {
                final color = _parseHexColor(val);
                if (color != null) {
                  setState(() {
                    _primaryColor = color;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InfoLabel(
            label: 'Accent Color (Hex)',
            child: TextBox(
              controller: _accentColorController,
              placeholder: '#B8860B',
              onChanged: (val) {
                final color = _parseHexColor(val);
                if (color != null) {
                  setState(() {
                    _accentColor = color;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Report Brand Logo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _logoFile != null
                      ? _logoFile!.path.split(Platform.pathSeparator).last
                      : 'No logo selected (using default text brand)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _logoFile != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Button(
              onPressed: _pickLogo,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.photo_collection),
                  SizedBox(width: 8),
                  Text('Choose File'),
                ],
              ),
            ),
            if (_logoFile != null) ...[
              const SizedBox(width: 8),
              Button(
                onPressed: _clearLogo,
                child: const Icon(FluentIcons.clear, color: Colors.red),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCustomizationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Custom Report Title',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextBox(
                  controller: _titleController,
                  placeholder: 'Enter custom report title',
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Color Theme Customization',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildPaletteSelector(),
                const SizedBox(height: 16),
                _buildCustomColorInputs(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogoPicker(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
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
        if (_reportType == 'custom') ...[
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
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 24),
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
                ProgressBar(value: _generationProgress),
                const SizedBox(height: 8),
                Text(
                  _generationStatus,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
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
            'Varshaphal (Annual)',
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
          .replaceAll(RegExp('_+'), '_');

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

      final file = await PDFReportService.generateReport(
        widget.chartData,
        reportTitle: _titleController.text,
        customPrimaryColor: PdfColor.fromInt(_primaryColor.value),
        customAccentColor: PdfColor.fromInt(_accentColor.value),
        logoBytes: _logoBytes,
        includeD1: _sections['Chart Diagram'] ?? true,
        includeD9: _sections['Planetary Positions'] ?? true,
        includeDasha: _sections['Dasha Periods'] ?? true,
        includeKP: _sections['KP System'] ?? true,
        includeDivisional: _reportType == 'comprehensive',
        includeYogaDosha: _sections['Yogas & Doshas'] ?? true,
        includeAshtakavarga: _sections['Ashtakavarga'] ?? false,
        includeShadbala: _sections['Shadbala'] ?? false,
        includeBhavaBala: _sections['Bhava Bala'] ?? false,
        includeTransit: _sections['Transit Analysis'] ?? false,
        includeLifePredictions: _sections['Life Predictions'] ?? false,
        includeVarshaphal: _sections['Varshaphal (Annual)'] ?? false,
      );

      await file.copy(path);

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

class _PreviewPatternPainter extends CustomPainter {
  final Color color;
  _PreviewPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 60, paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 80, paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 100, paint);

    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
