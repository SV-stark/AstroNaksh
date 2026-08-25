import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jyotish/core.dart';

import '../../data/models.dart';
import '../../logic/kp_prashna_service.dart';

class KPPrashnaAssistantScreen extends StatefulWidget {

  const KPPrashnaAssistantScreen({
    super.key,
    required this.initialLocation,
  });
  final GeographicLocation initialLocation;

  @override
  State<KPPrashnaAssistantScreen> createState() => _KPPrashnaAssistantScreenState();
}

class _KPPrashnaAssistantScreenState extends State<KPPrashnaAssistantScreen> {
  int _seedNumber = 108;
  PrashnaCategory _selectedCategory = PrashnaCategory.career;
  final DateTime _selectedDateTime = DateTime.now();
  late GeographicLocation _location;

  bool _isAnalyzing = false;
  KPPrashnaResult? _result;

  final KPPrashnaService _prashnaService = KPPrashnaService();

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation;
  }

  void _runAnalysis() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _prashnaService.analyzePrashna(
        seedNumber: _seedNumber,
        category: _selectedCategory,
        dateTime: _selectedDateTime,
        location: _location,
      );

      setState(() {
        _result = result;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error analyzing Horary Prashna: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔮 Interactive KP 1-249 Horary Assistant'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Selector
            Text(
              'Select Query Category',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildCategoryGrid(theme),
            const SizedBox(height: 20),

            // KP Seed Picker
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'KP Seed Number (1 - 249)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Seed #$_seedNumber',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _seedNumber.toDouble(),
                      min: 1,
                      max: 249,
                      divisions: 248,
                      label: 'Seed $_seedNumber',
                      onChanged: (val) {
                        setState(() {
                          _seedNumber = val.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.shuffle, size: 18),
                          label: const Text('Random Seed'),
                          onPressed: () {
                            setState(() {
                              _seedNumber = Random().nextInt(249) + 1;
                            });
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, size: 18),
                          label: const Text('Time Seed'),
                          onPressed: () {
                            final now = DateTime.now();
                            final timeSeed = ((now.minute * 4 + now.second) % 249) + 1;
                            setState(() {
                              _seedNumber = timeSeed;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: _isAnalyzing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _isAnalyzing ? 'Calculating KP Prashna...' : '🔮 Generate Prashna Judgment',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isAnalyzing ? null : _runAnalysis,
              ),
            ),
            const SizedBox(height: 24),

            // Results Section
            if (_result != null) _buildResultSection(theme, _result!),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(ThemeData theme) {
    final categories = [
      (PrashnaCategory.career, '💼 Job / Career', Icons.work),
      (PrashnaCategory.marriage, '💍 Marriage / Union', Icons.favorite),
      (PrashnaCategory.health, '🏥 Health / Cure', Icons.healing),
      (PrashnaCategory.property, '🏠 Property / Car', Icons.home),
      (PrashnaCategory.finance, '💰 Wealth & Finance', Icons.attach_money),
      (PrashnaCategory.education, '🎓 Education / Exam', Icons.school),
      (PrashnaCategory.travel, '✈️ Foreign Travel', Icons.flight),
      (PrashnaCategory.litigation, '⚖️ Lawsuit / Court', Icons.gavel),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat.$1;
        return ChoiceChip(
          avatar: Icon(
            cat.$3,
            size: 18,
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
          ),
          label: Text(cat.$2),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedCategory = cat.$1;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildResultSection(ThemeData theme, KPPrashnaResult res) {
    final (verdictColor, verdictIcon, verdictTitle) = switch (res.verdict) {
      PrashnaVerdict.promised => (
          Colors.green,
          Icons.check_circle_rounded,
          'EVENT PROMISED / FAVORABLE'
        ),
      PrashnaVerdict.conditional => (
          Colors.orange,
          Icons.warning_amber_rounded,
          'EVENT CONDITIONAL / DELAYED'
        ),
      PrashnaVerdict.denied => (
          Colors.red,
          Icons.cancel_rounded,
          'EVENT UNFAVORABLE / DENIED'
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verdict Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: verdictColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: verdictColor, width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(verdictIcon, color: verdictColor, size: 36),
                  const SizedBox(width: 12),
                  Text(
                    verdictTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: verdictColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Chip(
                backgroundColor: verdictColor,
                label: Text(
                  '${res.confidencePercentage.round()}% Confidence',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                res.queryTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // House Matrix
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KP House Rules for ${res.queryTitle}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Primary Houses: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(res.primaryHouses.join(', '), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    const Text('Supporting Houses: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(res.supportingHouses.join(', '), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    const Text('Negating Houses: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(res.negatingHouses.join(', '), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Detailed Interpretation
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📖 KP Horary Analysis & Verdict',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  res.detailedInterpretation,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const Divider(height: 24),
                Text(
                  '⏳ Timing of Event Guidance',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  res.timingGuidance,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Cusp Sub-Lord Breakdown Table
        Text(
          '📊 Cusp Sub-Lord Significators',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        ...res.significatorBreakdown.map(
          (sig) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('House ${sig.houseNumber} Cusp Sub-Lord: ${sig.cuspSubLord}'),
              subtitle: Text(
                'Star Lord: ${sig.subLordStarLord}\n'
                'Star Lord Signifies Houses: ${sig.starLordSignifiedHouses.join(", ")}',
              ),
              isThreeLine: true,
            ),
          ),
        ),
      ],
    );
  }
}
