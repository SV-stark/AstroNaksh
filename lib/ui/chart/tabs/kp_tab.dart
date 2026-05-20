import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' as m;


import '../../../data/models.dart';
import '../../utils/responsive_helper.dart';
import '../chart_helpers.dart';

class KPTab extends StatelessWidget {
  const KPTab({super.key, required this.data});

  final CompleteChartData data;

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
            'Lagna: ${ChartHelpers.getAscendantSign(data.baseChart)}',
            style: FluentTheme.of(context).typography.body,
          ),
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
            ...data.significatorTable.entries.map((entry) {
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
        Text(label, style: const TextStyle(fontSize: 12, color: m.Colors.grey)),
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
            ...data.significatorTable.entries.map((entry) {
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
              children: data.kpData.rulingPlanets
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
                        style: const TextStyle(color: m.Colors.white),
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
