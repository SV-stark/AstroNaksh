import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' as m;
import 'package:jyotish/core.dart';
import 'package:jyotish/systems.dart';

import '../../data/models.dart';
import '../../logic/shadbala.dart';
import '../../ui/utils/responsive_helper.dart';
import '../widgets/strength_meter.dart';

class ShadbalaScreen extends StatelessWidget {
  const ShadbalaScreen({super.key, required this.chartData});
  final CompleteChartData chartData;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShadbalaScreenData>(
      future: ShadbalaCalculator.getScreenData(chartData),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ScaffoldPage(
            header: PageHeader(
              title: const Text('Shadbala (Planetary Strength)'),
              leading: IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            content: const Center(child: ProgressRing()),
          );
        }
        if (snapshot.hasError) {
          return ScaffoldPage(
            header: PageHeader(
              title: const Text('Shadbala (Planetary Strength)'),
              leading: IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            content: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return ScaffoldPage(
            header: PageHeader(
              title: const Text('Shadbala (Planetary Strength)'),
              leading: IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            content: const Center(child: Text('No data available')),
          );
        }

        final data = snapshot.data!;
        final shadbalaMap = data.shadbala;
        final detailedShadbala = data.detailedShadbala;
        final isMobile = context.isMobile;

        return ScaffoldPage.scrollable(
          header: PageHeader(
            title: const Text('Shadbala (Planetary Strength)'),
            leading: IconButton(
              icon: const Icon(FluentIcons.back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          children: [
            if (!isMobile)
              _buildDesktopLayout(context, detailedShadbala, shadbalaMap)
            else
              _buildMobileLayout(context, detailedShadbala, shadbalaMap),
          ],
        );
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    Map<Planet, ShadbalaResult> detailedShadbala,
    Map<Planet, double> totalStrengths,
  ) {
    return Column(
      children: [
        _buildOverviewCard(context, totalStrengths),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildDetailsCard(context, detailedShadbala),
            ),
            const SizedBox(width: 24),
            Expanded(child: _buildStrengthChart(context, totalStrengths)),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    Map<Planet, ShadbalaResult> detailedShadbala,
    Map<Planet, double> totalStrengths,
  ) {
    return Column(
      children: [
        _buildOverviewCard(context, totalStrengths),
        const SizedBox(height: 16),
        _buildStrengthChart(context, totalStrengths),
        const SizedBox(height: 16),
        _buildDetailsCard(context, detailedShadbala),
      ],
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    Map<Planet, double> strengths,
  ) {
    final sortedPlanets = strengths.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Planetary Strength Overview',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: sortedPlanets.map((entry) {
              return SizedBox(
                width: 150,
                child: StrengthMeter(
                  label: entry.key.displayName,
                  value: (entry.value / 6).clamp(
                    0,
                    100,
                  ), // Normalize to 100 for display
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthChart(
    BuildContext context,
    Map<Planet, double> shadbalaData,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparative Strength Chart',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                dataSets: [
                  RadarDataSet(
                    fillColor: FluentTheme.of(
                      context,
                    ).accentColor.withValues(alpha: 0.2),
                    borderColor: FluentTheme.of(context).accentColor,
                    entryRadius: 3,
                    dataEntries: Planet.traditionalPlanets.map((p) {
                      final value = shadbalaData[p] ?? 0.0;
                      return RadarEntry(value: value);
                    }).toList(),
                  ),
                ],
                ticksTextStyle: const TextStyle(
                  fontSize: 10,
                  color: m.Colors.transparent,
                ),
                radarBorderData: const BorderSide(color: m.Colors.grey),
                gridBorderData: const BorderSide(
                  color: m.Colors.grey,
                  width: 1,
                ),
                tickBorderData: const BorderSide(color: m.Colors.transparent),
                getTitle: (index, angle) {
                  final planets = Planet.traditionalPlanets;
                  if (index < planets.length) {
                    return RadarChartTitle(
                      text: planets[index].displayName,
                      angle: angle,
                    );
                  }
                  return const RadarChartTitle(text: '');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    Map<Planet, ShadbalaResult> detailedShadbala,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shadbala Components (Virupas)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: m.DataTable(
              columns: [
                const m.DataColumn(label: Text('Component')),
                ...Planet.traditionalPlanets.map(
                  (p) => m.DataColumn(label: Text(p.displayName)),
                ),
              ],
              rows: [
                _buildDataRow(
                  'Sthana Bala',
                  (r) => r.sthanaBala,
                  detailedShadbala,
                ),
                _buildDataRow('Dig Bala', (r) => r.digBala, detailedShadbala),
                _buildDataRow('Kala Bala', (r) => r.kalaBala, detailedShadbala),
                _buildDataRow(
                  'Chesta Bala',
                  (r) => r.chestaBala,
                  detailedShadbala,
                ),
                _buildDataRow(
                  'Naisargika Bala',
                  (r) => r.naisargikaBala,
                  detailedShadbala,
                ),
                _buildDataRow('Drik Bala', (r) => r.drikBala, detailedShadbala),
                _buildDataRow(
                  'Total Virupas',
                  (r) => r.totalBala,
                  detailedShadbala,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  m.DataRow _buildDataRow(
    String label,
    double Function(ShadbalaResult) selector,
    Map<Planet, ShadbalaResult> detailedShadbala,
  ) {
    return m.DataRow(
      cells: [
        m.DataCell(
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        ...Planet.traditionalPlanets.map((p) {
          final result = detailedShadbala[p];
          final value = result != null ? selector(result) : 0.0;
          return m.DataCell(Text(value.toStringAsFixed(1)));
        }),
      ],
    );
  }
}
