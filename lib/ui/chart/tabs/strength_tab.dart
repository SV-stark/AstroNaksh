import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' as m;
import 'package:jyotish/jyotish.dart';

import '../../../data/models.dart';
import '../../../logic/shadbala.dart';
import '../../utils/responsive_helper.dart';

class StrengthTab extends StatelessWidget {
  const StrengthTab({super.key, required this.data});

  final CompleteChartData data;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShadbalaScreenData>(
      future: ShadbalaCalculator.getScreenData(data),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ProgressRing());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: InfoBar(
              title: const Text('Error'),
              content: Text('Failed to calculate strength: ${snapshot.error}'),
              severity: InfoBarSeverity.error,
            ),
          );
        }
        final sd = snapshot.data!;
        final strengthService = StrengthAnalysisService();
        final bhavaBala = strengthService.getBhavaBala(
          chart: data.baseChart,
          shadbalaResults: {
            for (final e in sd.detailedShadbala.entries)
              e.key: e.value.totalBala,
          },
        );
        return SingleChildScrollView(
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ishtaphala / Kashtaphala table ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ishtaphala & Kashtaphala',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Favorable (Ishta) vs. Unfavorable (Kashta) fruit each planet can deliver.',
                        style: TextStyle(fontSize: 12, color: m.Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: FluentTheme.of(
                            context,
                          ).accentColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Planet',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Ishta ✨',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Kashta ⚠️',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Net',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...sd.detailedShadbala.entries.map((entry) {
                        final planet = entry.key;
                        final shadbalaStrength = entry.value.totalBala;
                        final ishta = strengthService.getIshtaphala(
                          planet: planet,
                          chart: data.baseChart,
                          shadbalaStrength: shadbalaStrength,
                        );
                        final kashta = strengthService.getKashtaphala(
                          planet: planet,
                          chart: data.baseChart,
                          shadbalaStrength: shadbalaStrength,
                        );
                        final net = ishta - kashta;
                        final netColor = net > 0
                            ? m.Colors.green
                            : m.Colors.red;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 3),
                          padding: const EdgeInsets.symmetric(
                            vertical: 7,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: net > 0
                                ? m.Colors.green.withAlpha(12)
                                : m.Colors.red.withAlpha(12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  planet.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${(ishta * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(color: m.Colors.green),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${(kashta * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: m.Colors.orange,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${net >= 0 ? '+' : ''}${(net * 100).toStringAsFixed(0)}%',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: netColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ── Vimshopak Bala table ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vimshopak Bala (20-fold Varga Strength)',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Measures planetary dignity across 16 divisional charts on a 0–20 scale.',
                        style: TextStyle(fontSize: 12, color: m.Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ...sd.vimsopaka.entries.map((entry) {
                        final planet = entry.key;
                        final vb = entry.value;
                        final pct = vb.totalScore / 20.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      planet.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${vb.totalScore.toStringAsFixed(1)} / 20',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: pct >= 0.7
                                          ? m.Colors.green.withAlpha(30)
                                          : pct >= 0.4
                                          ? m.Colors.orange.withAlpha(30)
                                          : m.Colors.red.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      vb.strengthCategory.name,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: pct >= 0.7
                                            ? m.Colors.green
                                            : pct >= 0.4
                                            ? m.Colors.orange
                                            : m.Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                height: 6,
                                child: LayoutBuilder(
                                  builder: (ctx, constraints) {
                                    return Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: m.Colors.grey.withAlpha(40),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: pct.clamp(0.0, 1.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: pct >= 0.7
                                                  ? m.Colors.green
                                                  : pct >= 0.4
                                                  ? m.Colors.orange
                                                  : m.Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // ── Bhava Bala (House Strength) table ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bhava Bala (House Strength)',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Strength of each house (0–100). Kendra houses (1,4,7,10) are inherently strongest.',
                        style: TextStyle(fontSize: 12, color: m.Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ...bhavaBala.entries.map((entry) {
                        final house = entry.key;
                        final strength = entry.value;
                        final pct = strength / 100.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  'House $house',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  height: 6,
                                  child: LayoutBuilder(
                                    builder: (ctx, constraints) {
                                      return Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: m.Colors.grey.withAlpha(
                                                40,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: pct.clamp(0.0, 1.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: FluentTheme.of(
                                                  context,
                                                ).accentColor,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  strength.toStringAsFixed(0),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
