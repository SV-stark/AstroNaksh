import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' as m;
import 'package:jyotish/jyotish.dart';

import '../../data/models.dart';
import '../../ui/utils/responsive_helper.dart';

class GrahaYuddhaScreen extends StatelessWidget {
  const GrahaYuddhaScreen({super.key, required this.chartData});

  final CompleteChartData chartData;

  @override
  Widget build(BuildContext context) {
    final war = chartData.grahaYuddha;

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Planetary War (Graha Yuddha)'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: ListView(
        padding: ResponsiveHelper.getResponsivePadding(context),
        children: [
          if (war == null)
            _buildNoWarView(context)
          else
            _buildWarView(context, war),
          const SizedBox(height: 24),
          _buildEducationalCard(context),
        ],
      ),
    );
  }

  Widget _buildNoWarView(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FluentIcons.shield, size: 64, color: m.Colors.green),
          const SizedBox(height: 16),
          Text(
            'Peaceful Skies',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 12),
          const Text(
            'There is no active Planetary War (Graha Yuddha) in this birth chart. '
            'All planets are positioned at safe longitudinal distances from each other.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWarView(BuildContext context, WarDetails war) {
    final theme = FluentTheme.of(context);
    final p1 = war.planet1;
    final p2 = war.planet2;
    final winner = war.winnerId;

    final isP1Winner = winner == p1;
    final isP2Winner = winner == p2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          backgroundColor: theme.accentColor.withValues(alpha: 0.1),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(FluentIcons.warning, color: theme.accentColor, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Graha Yuddha Detected!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${p1.displayName} and ${p2.displayName} are in close planetary combat.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Combatants & Measurements', style: theme.typography.subtitle),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildPlanetCard(
                      context,
                      p1,
                      war.planet1Magnitude,
                      war.planet1Declination,
                      isP1Winner,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPlanetCard(
                      context,
                      p2,
                      war.planet2Magnitude,
                      war.planet2Declination,
                      isP2Winner,
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildPlanetCard(
                    context,
                    p1,
                    war.planet1Magnitude,
                    war.planet1Declination,
                    isP1Winner,
                  ),
                  const SizedBox(height: 16),
                  _buildPlanetCard(
                    context,
                    p2,
                    war.planet2Magnitude,
                    war.planet2Declination,
                    isP2Winner,
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 20),
        Card(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Astronomical Metrics',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.accentColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildMetricRow(
                'Longitudinal separation',
                '${war.longitudeDifference.toStringAsFixed(4)}°',
                'Must be < 1° for Graha Yuddha',
              ),
              const Divider(),
              _buildMetricRow(
                'Declination difference',
                '${(war.planet1Declination - war.planet2Declination).abs().toStringAsFixed(4)}°',
                'Influences latitudinal dominance',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanetCard(
    BuildContext context,
    Planet planet,
    double magnitude,
    double declination,
    bool isWinner,
  ) {
    final theme = FluentTheme.of(context);
    final borderColor = isWinner
        ? theme.accentColor
        : theme.resources.dividerStrokeColorDefault;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: isWinner ? 2.0 : 1.0),
        borderRadius: BorderRadius.circular(8),
        color: theme.cardColor,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planet.displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    planet.sanskritName,
                    style: TextStyle(
                      color: theme.typography.bodyLarge?.color?.withValues(
                        alpha: 0.6,
                      ),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (isWinner)
                const Row(
                  children: [
                    Icon(m.Icons.emoji_events, color: m.Colors.amber, size: 24),
                    SizedBox(width: 4),
                    Text(
                      'WINNER',
                      style: TextStyle(
                        color: m.Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Astronomical Magnitude', magnitude.toStringAsFixed(2)),
          const SizedBox(height: 8),
          _buildInfoRow('Declination', '${declination.toStringAsFixed(4)}°'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                note,
                style: const TextStyle(fontSize: 11, color: m.Colors.grey),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationalCard(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Graha Yuddha',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: FluentTheme.of(context).accentColor,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Graha Yuddha (Planetary War) occurs when two true planets are in close longitudinal conjunction (typically within 1 degree). '
            'Only the five non-luminous true planets—Mars, Mercury, Jupiter, Venus, and Saturn—participate in planetary war. '
            'The Sun, Moon, Rahu, and Ketu do not engage in Graha Yuddha.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 12),
          const Text(
            'Determination of the Winner:\n'
            'According to classic texts like the Surya Siddhanta, the planet with higher astronomical magnitude (brighter), '
            'favorable northern declination, or specific positioning wins the war. The winning planet gains immense strength '
            'and dominates the affairs ruled by both planets in the chart, while the defeated planet loses its capacity '
            'to deliver positive fruits.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
