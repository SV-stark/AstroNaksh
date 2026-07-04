import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart'
    show Colors, Table, TableRow, FlexColumnWidth;

import '../../../data/models.dart';
import '../../utils/responsive_helper.dart';
import '../chart_helpers.dart';

class KPTab extends StatefulWidget {
  const KPTab({super.key, required this.data});

  final CompleteChartData data;

  @override
  State<KPTab> createState() => _KPTabState();
}

class _KPTabState extends State<KPTab> {
  String _selectedQuery = 'Career';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('KP System', style: FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 8),
          Text(
            'Lagna: ${ChartHelpers.getAscendantSign(widget.data.baseChart)}',
            style: FluentTheme.of(context).typography.body,
          ),
          const SizedBox(height: 16),
          // Premium KP Rule Analyzer Card
          _buildKPAnalyzerCard(context),
          const SizedBox(height: 16),
          _buildKPSubLordsCard(context),
          const SizedBox(height: 16),
          _buildKPSignificatorsCard(context),
          const SizedBox(height: 16),
          _buildRulingPlanetsCard(context),
        ],
      ),
    );
  }

  Widget _buildKPAnalyzerCard(BuildContext context) {
    // Evaluation data matching selected query
    int primeCusp = 10;
    List<int> positiveHouses = [2, 6, 10, 11];
    List<int> negativeHouses = [5, 8, 12];
    String primeDesc = 'Career (10th Cusp)';

    if (_selectedQuery == 'Marriage') {
      primeCusp = 7;
      positiveHouses = [2, 7, 11];
      negativeHouses = [1, 6, 10];
      primeDesc = 'Marriage (7th Cusp)';
    } else if (_selectedQuery == 'Foreign Travel') {
      primeCusp = 12;
      positiveHouses = [3, 9, 12];
      negativeHouses = [4, 8, 11];
      primeDesc = 'Foreign Travel (12th Cusp)';
    } else if (_selectedQuery == 'Health Recovery') {
      primeCusp = 11;
      positiveHouses = [1, 5, 11];
      negativeHouses = [6, 8, 12];
      primeDesc = 'Health Recovery (11th Cusp)';
    }

    // Get prime cusp sublord
    String primeSubLord = 'N/A';
    if (widget.data.kpData.cuspSubLords.length >= primeCusp) {
      primeSubLord = widget.data.kpData.cuspSubLords[primeCusp - 1];
    }

    // Evaluate prime sublord significations
    final subLordInfo = widget.data.significatorTable[primeSubLord];
    final subLordSigs = subLordInfo != null
        ? (subLordInfo['significations'] as List<dynamic>? ?? []).cast<int>()
        : <int>[];

    final matchingPositive = subLordSigs
        .where((h) => positiveHouses.contains(h))
        .toList();

    bool isPrimeFavorable = matchingPositive.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'KP Signification Rule Analyzer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(
                  width: 160,
                  child: ComboBox<String>(
                    value: _selectedQuery,
                    items: const [
                      ComboBoxItem(
                        value: 'Career',
                        child: Text('Career & Job'),
                      ),
                      ComboBoxItem(value: 'Marriage', child: Text('Marriage')),
                      ComboBoxItem(
                        value: 'Foreign Travel',
                        child: Text('Foreign Travel'),
                      ),
                      ComboBoxItem(
                        value: 'Health Recovery',
                        child: Text('Health Recovery'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedQuery = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Prime Sub-lord Evaluation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimeFavorable
                    ? Colors.green.withOpacity(0.06)
                    : Colors.orange.withOpacity(0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isPrimeFavorable
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPrimeFavorable ? FluentIcons.completed : FluentIcons.info,
                    color: isPrimeFavorable ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prime Sub-Lord for $primeDesc is: $primeSubLord',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        if (isPrimeFavorable)
                          Text(
                            'Favorable! $primeSubLord signifies positive houses: $matchingPositive.',
                            style: const TextStyle(fontSize: 12),
                          )
                        else
                          Text(
                            '$primeSubLord does not signify prime positive houses $positiveHouses (Signifies: $subLordSigs).',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Planets Checklist Table
            const Text(
              'Significator Diagnosis Matrix',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1.8),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.8),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Graha',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Positive Sigs',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Signified Houses',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                ...widget.data.significatorTable.entries.map((entry) {
                  final planetName = entry.key;
                  final info = entry.value;
                  final sigs = (info['significations'] as List<dynamic>? ?? [])
                      .cast<int>();

                  final posSigs = sigs
                      .where((h) => positiveHouses.contains(h))
                      .toList();
                  final negSigs = sigs
                      .where((h) => negativeHouses.contains(h))
                      .toList();

                  Widget statusWidget;
                  if (posSigs.isNotEmpty && negSigs.isEmpty) {
                    statusWidget = const Row(
                      children: [
                        Icon(
                          FluentIcons.completed,
                          color: Colors.green,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Positive',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  } else if (posSigs.isNotEmpty && negSigs.isNotEmpty) {
                    statusWidget = const Row(
                      children: [
                        Icon(FluentIcons.info, color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Mixed',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  } else if (negSigs.isNotEmpty) {
                    statusWidget = const Row(
                      children: [
                        Icon(FluentIcons.cancel, color: Colors.red, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Obstructed',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  } else {
                    statusWidget = const Row(
                      children: [
                        Icon(
                          FluentIcons.remove_from_shopping_list,
                          color: Colors.grey,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Neutral',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    );
                  }

                  return TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.2),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          planetName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          posSigs.isNotEmpty ? posSigs.join(', ') : '-',
                          style: TextStyle(
                            color: posSigs.isNotEmpty
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: posSigs.isNotEmpty
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: statusWidget,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(sigs.join(', ')),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPSubLordsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KP Sub Lords',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            ...widget.data.significatorTable.entries.map((entry) {
              final planet = entry.key;
              final info = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Expander(
                  header: Text(
                    planet,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  content: Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _buildKPDetailItem(
                        'Nakshatra',
                        info['nakshatra']?.toString() ?? '-',
                      ),
                      _buildKPDetailItem(
                        'Star Lord',
                        info['starLord']?.toString() ?? '-',
                      ),
                      _buildKPDetailItem(
                        'Sub Lord',
                        info['subLord']?.toString() ?? '-',
                      ),
                      _buildKPDetailItem(
                        'Sub-Sub',
                        info['subSubLord']?.toString() ?? '-',
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKPDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildKPSignificatorsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Significations',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            ...widget.data.significatorTable.entries.map((entry) {
              final planet = entry.key;
              final info = entry.value;
              final significations =
                  info['significations'] as List<dynamic>? ?? [];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Expander(
                  header: Text(
                    planet,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  content: Text(
                    significations.isNotEmpty
                        ? significations.join(', ')
                        : 'None',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRulingPlanetsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ruling Planets',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: widget.data.kpData.rulingPlanets
                  .map(
                    (planet) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FluentTheme.of(context).accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        planet,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
