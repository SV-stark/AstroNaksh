import 'package:flutter/material.dart';
import '../../data/models.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Generate PDF Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.teal.shade50,
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
                  DropdownButtonFormField<String>(
                    value: _reportType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'basic',
                        child: Text('Basic Report'),
                      ),
                      DropdownMenuItem(
                        value: 'standard',
                        child: Text('Standard Report'),
                      ),
                      DropdownMenuItem(
                        value: 'comprehensive',
                        child: Text('Comprehensive Report'),
                      ),
                      DropdownMenuItem(
                        value: 'custom',
                        child: Text('Custom Report'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _reportType = value!;
                        _updateSectionsByType(value);
                      });
                    },
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
                      return CheckboxListTile(
                        title: Text(entry.key),
                        value: entry.value,
                        onChanged: (value) {
                          setState(() {
                            _sections[entry.key] = value ?? false;
                          });
                        },
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Generate button
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateReport,
            icon: _isGenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(
              _isGenerating ? 'Generating...' : 'Generate PDF Report',
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
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
      await Future.delayed(const Duration(seconds: 2)); // Simulate generation

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF Report generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
}
