import 'package:fluent_ui/fluent_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models.dart';
import '../../logic/shadbala.dart';
import '../widgets/strength_meter.dart';

class ShadbalaScreen extends StatelessWidget {
  final CompleteChartData chartData;

  const ShadbalaScreen({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    final shadbalaData = ShadbalaCalculator.calculateShadbala(chartData);

    return ScaffoldPage(
      header: const PageHeader(title: Text('Shadbala Analysis')),
      content: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          // Educational info
          Card(
            backgroundColor: Colors.orange.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(FluentIcons.info, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'About Shadbala',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Shadbala (Six-Fold Strength) measures planetary power through 6 components: '
                    'Positional, Directional, Temporal, Motional, Natural, and Aspectual strength. '
                    'Higher values indicate stronger planets capable of delivering better results.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Overall strength ranking
          _buildStrengthRanking(context, shadbalaData),

          const SizedBox(height: 16),

          // Comparative radar chart
          _buildRadarChart(context, shadbalaData),

          const SizedBox(height: 16),

          // Individual planet cards
          ..._buildPlanetCards(context, shadbalaData),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStrengthRanking(
    BuildContext context,
    Map<String, double> shadbalaData,
  ) {
    // Sort planets by strength
    final rankings = shadbalaData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Planetary Strength Ranking',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...rankings.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final planetEntry = entry.value;
              final planetName = planetEntry.key;
              final totalStrength = planetEntry.value;
              final normalizedStrength = (totalStrength / 600) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getPlanetColor(planetName),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planetName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          StrengthMeter(
                            value: normalizedStrength,
                            label: '${totalStrength.toStringAsFixed(2)} units',
                            showPercentage: false,
                            color: _getPlanetColor(planetName),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarChart(
    BuildContext context,
    Map<String, double> shadbalaData,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  ticksTextStyle: const TextStyle(
                    fontSize: 10,
                    color: Colors.transparent,
                  ),
                  radarBorderData: const BorderSide(color: Colors.grey),
                  gridBorderData: const BorderSide(
                    color: Colors.grey,
                    width: 1,
                  ),
                  tickBorderData: const BorderSide(color: Colors.transparent),
                  getTitle: (index, angle) {
                    final planets = shadbalaData.keys.toList();
                    if (index < planets.length) {
                      return RadarChartTitle(
                        text: planets[index],
                        angle: angle,
                      );
                    }
                    return const RadarChartTitle(text: '');
                  },
                  dataSets: [
                    RadarDataSet(
                      fillColor: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.blue,
                      dataEntries: shadbalaData.entries.map((entry) {
                        return RadarEntry(value: entry.value / 6); // Normalize
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlanetCards(
    BuildContext context,
    Map<String, double> shadbalaData,
  ) {
    return shadbalaData.entries.map((entry) {
      final planetName = entry.key;
      final totalStrength = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: ExpandableInfoCard(
          title: planetName,
          summary:
              'Total Strength: ${totalStrength.toStringAsFixed(2)} units - ${_getStrengthInterpretation(totalStrength)}',
          icon: FluentIcons.favorite_star,
          color: _getPlanetColor(planetName),
          details: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Overall Strength:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    totalStrength.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StrengthMeter(
                value: (totalStrength / 600) * 100,
                label: _getStrengthInterpretation(totalStrength),
                showPercentage: true,
                color: _getPlanetColor(planetName),
              ),
              const SizedBox(height: 16),
              _buildInterpretationText(planetName, totalStrength),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildInterpretationText(String planet, double strength) {
    String interpretation;
    if (strength >= 400) {
      interpretation =
          '$planet is very strong and will deliver excellent results. This planet can fulfill its significations powerfully.';
    } else if (strength >= 300) {
      interpretation =
          '$planet has good strength and will give positive results. Most significations will be fulfilled.';
    } else if (strength >= 200) {
      interpretation =
          '$planet has moderate strength. Results will be mixed, depending on other factors.';
    } else if (strength >= 100) {
      interpretation =
          '$planet is weak and may struggle to deliver good results. Extra care needed in areas it rules.';
    } else {
      interpretation =
          '$planet is very weak and may not be able to fulfill its promises effectively.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        interpretation,
        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
      ),
    );
  }

  String _getStrengthInterpretation(double strength) {
    if (strength >= 400) return 'Very Strong';
    if (strength >= 300) return 'Strong';
    if (strength >= 200) return 'Moderate';
    if (strength >= 100) return 'Weak';
    return 'Very Weak';
  }

  Color _getPlanetColor(String planet) {
    switch (planet) {
      case 'Sun':
        return Colors.orange;
      case 'Moon':
        return const Color(0xFFADD8E6); // Light Blue
      case 'Mars':
        return Colors.red;
      case 'Mercury':
        return Colors.green;
      case 'Jupiter':
        return Colors.yellow;
      case 'Venus':
        return Colors.magenta; // Pinkish
      case 'Saturn':
        return Colors.purple; // Indigo replacement
      default:
        return Colors.grey;
    }
  }
}
