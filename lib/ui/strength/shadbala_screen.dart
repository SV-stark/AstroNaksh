import 'package:fluent_ui/fluent_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:jyotish/jyotish.dart';
import '../../data/models.dart';
import '../../logic/shadbala.dart';
import '../widgets/strength_meter.dart';
import '../../core/responsive_helper.dart';
import '../styles.dart';

class ShadbalaScreen extends StatelessWidget {
  final CompleteChartData chartData;

  const ShadbalaScreen({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShadbalaScreenData>(
      future: ShadbalaCalculator.getScreenData(chartData),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ScaffoldPage(
            header: PageHeader(title: Text('Shadbala Analysis')),
            content: Center(child: ProgressRing()),
          );
        }

        if (snapshot.hasError) {
          return ScaffoldPage(
            header: PageHeader(title: const Text('Shadbala Analysis')),
            content: Center(
              child: InfoBar(
                title: const Text('Calculation Error'),
                content: Text(
                  'Failed to calculate Shadbala: ${snapshot.error}',
                ),
                severity: InfoBarSeverity.error,
              ),
            ),
          );
        }

        if (snapshot.data == null) {
          return const ScaffoldPage(
            content: Center(child: Text('No data generated')),
          );
        }

        final screenData = snapshot.data!;
        final shadbalaData = screenData.shadbala;

        return ScaffoldPage(
          header: PageHeader(
            title: const Text('Shadbala Analysis'),
            leading: IconButton(
              icon: const Icon(FluentIcons.back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          content: ListView(
            padding: context.responsiveBodyPadding,
            children: [
              // Educational info
              Card(
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
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

              // Individual planet cards with Vimsopaka and Combustion details
              ..._buildPlanetCards(context, screenData),

              const SizedBox(height: 16),

              // Hora Lords section
              _buildHoraLordsCard(context, screenData.horaLords),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
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
                            color: _getStrengthColor(totalStrength),
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
                      fillColor: Colors.blue.withValues(alpha: 0.2),
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
    ShadbalaScreenData screenData,
  ) {
    return screenData.shadbala.entries.map((entry) {
      final planetName = entry.key;
      final totalStrength = entry.value;

      final planetObj = Planet.traditionalPlanets.firstWhere(
        (p) => p.displayName == planetName,
        orElse: () => Planet.sun,
      );
      final vimsopaka = screenData.vimsopaka[planetObj];
      final combustion = screenData.combustion[planetObj];

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
                color: _getStrengthColor(totalStrength),
              ),
              const SizedBox(height: 16),
              _buildInterpretationText(planetName, totalStrength),
              if (vimsopaka != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Vimsopaka Bala (20-Point Scale):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${vimsopaka.totalScore.toStringAsFixed(1)} / 20.0 (${vimsopaka.strengthCategory.name})',
                ),
                Text(
                  'Based on dignity in D-1, D-2, D-3, D-9, D-12, D-30 charts.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              if (combustion != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Combustion Status: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      combustion.isCombust ? 'Combust' : 'Not Combust',
                      style: TextStyle(
                        color: combustion.isCombust ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  combustion.description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
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
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        interpretation,
        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildHoraLordsCard(BuildContext context, List<Planet> horaLords) {
    if (horaLords.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.clock, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Hora Lords of the Day (24 Hours)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Each day is divided into 24 planetary hours (Horas). The first hora begins at sunrise and is ruled by the lord of the weekday. Each subsequent hora is ruled by the 6th planet in the weekday sequence.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(horaLords.length, (index) {
                final lord = horaLords[index];
                return Container(
                  width: 90,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getPlanetColor(
                      lord.displayName,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getPlanetColor(
                        lord.displayName,
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Hora ${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        lord.displayName,
                        style: TextStyle(
                          color: _getPlanetColor(lord.displayName),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
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

  Color _getStrengthColor(double strength) {
    if (strength >= 400) return AppStyles.beneficColor;
    if (strength >= 300) return AppStyles.beneficColor.withValues(alpha: 0.8);
    if (strength >= 200) return AppStyles.neutralColor;
    if (strength >= 100) return AppStyles.maleficColor.withValues(alpha: 0.8);
    return AppStyles.maleficColor;
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
