import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import '../../data/models.dart';
import '../../logic/varshaphal_system.dart';
import '../widgets/chart_widget.dart';
import 'package:jyotish/jyotish.dart';

class VarshaphalScreen extends StatefulWidget {
  final BirthData birthData;

  const VarshaphalScreen({super.key, required this.birthData});

  @override
  State<VarshaphalScreen> createState() => _VarshaphalScreenState();
}

class _VarshaphalScreenState extends State<VarshaphalScreen> {
  int _selectedYear = DateTime.now().year;
  int _expandedPeriodIndex = 0; // First period expanded by default

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Varshaphal (Annual Predictions)'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: FutureBuilder<VarshaphalChart>(
        future: VarshaphalSystem.calculateVarshaphal(
          widget.birthData,
          _selectedYear,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ProgressRing(),
                  SizedBox(height: 16),
                  Text('Calculating annual chart...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: InfoBar(
                title: const Text('Error'),
                content: Text(
                  'Could not calculate Varshaphal: ${snapshot.error}',
                ),
                severity: InfoBarSeverity.error,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final varshaphal = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Year selector card
              _buildYearSelectorCard(),
              const SizedBox(height: 16),

              // Solar Return Info Card
              _buildSolarReturnCard(varshaphal),
              const SizedBox(height: 16),

              // Annual Chart Display
              _buildChartCard(varshaphal),
              const SizedBox(height: 16),

              // Year Lord & Muntha Info
              _buildYearLordCard(varshaphal),
              const SizedBox(height: 16),

              // Varshik Dasha Periods with Predictions
              _buildVarshikDashaSection(varshaphal),
              const SizedBox(height: 16),

              // Sahams (Arabic Parts)
              _buildSahamsCard(varshaphal),
              const SizedBox(height: 16),

              // Overall Annual Interpretation
              _buildInterpretationCard(varshaphal),
            ],
          );
        },
      ),
    );
  }

  Widget _buildYearSelectorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(FluentIcons.chevron_left),
              onPressed: _selectedYear > 1800
                  ? () => setState(() => _selectedYear--)
                  : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: FluentTheme.of(
                  context,
                ).accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_selectedYear',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(FluentIcons.chevron_right),
              onPressed: _selectedYear < 2100
                  ? () => setState(() => _selectedYear++)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolarReturnCard(VarshaphalChart varshaphal) {
    return Card(
      backgroundColor: FluentTheme.of(
        context,
      ).accentColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FluentIcons.calendar,
                  color: FluentTheme.of(context).accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Solar Return (Tajik)',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Exact Return Time: ${DateFormat('MMM dd, yyyy - HH:mm').format(varshaphal.solarReturnTime)}',
              style: FluentTheme.of(context).typography.body,
            ),
            const SizedBox(height: 4),
            Text(
              'This is the moment when the Sun returns to its exact natal position, marking the beginning of your ${_selectedYear - widget.birthData.dateTime.year}th year.',
              style: FluentTheme.of(context).typography.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(VarshaphalChart varshaphal) {
    final planetsMap = _getPlanetsMap(varshaphal.chart);
    final ascSign = _getAscendantSignInt(varshaphal.chart);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Annual Chart (Tajik)',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: FluentTheme.of(
                      context,
                    ).accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Lagna: ${_getSignName(ascSign - 1)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: FluentTheme.of(context).accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ChartWidget(
                planetsBySign: planetsMap,
                ascendantSign: ascSign,
                style: ChartStyle.northIndian,
                size: 350,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearLordCard(VarshaphalChart varshaphal) {
    final munthaSign = _getSignName(varshaphal.muntha);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildInfoTile(
                'Year Lord',
                varshaphal.yearLord,
                FluentIcons.contact,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoTile(
                'Muntha Position',
                munthaSign,
                FluentIcons.location,
                Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildVarshikDashaSection(VarshaphalChart varshaphal) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Varshik Dasha Periods',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '12 Periods',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Monthly periods ruled by planets. Click each period to see detailed predictions.',
              style: FluentTheme.of(context).typography.caption,
            ),
            const SizedBox(height: 16),
            ...varshaphal.varshikDasha.asMap().entries.map((entry) {
              final index = entry.key;
              final period = entry.value;
              return _buildPeriodCard(period, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodCard(VarshikDashaPeriod period, int index) {
    final isExpanded = _expandedPeriodIndex == index;
    final score = (period.favorableScore * 100).round();
    final color = _getScoreColor(score);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Expander(
        initiallyExpanded: isExpanded,
        onStateChanged: (expanded) {
          setState(() {
            _expandedPeriodIndex = expanded ? index : -1;
          });
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getPlanetColor(period.planet).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _getPlanetSymbol(period.planet),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getPlanetColor(period.planet),
              ),
            ),
          ),
        ),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${period.planet} Period',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '${DateFormat('MMM dd').format(period.startDate)} - ${DateFormat('MMM dd').format(period.endDate)}',
              style: FluentTheme.of(context).typography.caption,
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FluentTheme.of(context).cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Score
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.favorite_star, size: 14, color: color),
                        const SizedBox(width: 4),
                        Text(
                          '$score% ${score >= 70
                              ? 'Favorable'
                              : score >= 40
                              ? 'Mixed'
                              : 'Challenging'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${period.durationDays.toStringAsFixed(0)} days',
                    style: FluentTheme.of(context).typography.caption,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Main Prediction
              Text(
                'Period Overview',
                style: FluentTheme.of(context).typography.bodyStrong,
              ),
              const SizedBox(height: 8),
              Text(period.prediction),
              const SizedBox(height: 16),

              // Key Themes
              if (period.keyThemes.isNotEmpty) ...[
                Text(
                  'Key Themes',
                  style: FluentTheme.of(context).typography.bodyStrong,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: period.keyThemes.map((theme) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentIcons.check_mark,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            theme,
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Cautions
              if (period.cautions.isNotEmpty) ...[
                Text(
                  'Cautions',
                  style: FluentTheme.of(context).typography.bodyStrong,
                ),
                const SizedBox(height: 8),
                ...period.cautions.map((caution) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          FluentIcons.warning,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            caution,
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSahamsCard(VarshaphalChart varshaphal) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.calculator, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Sahams (Arabic Parts)',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...varshaphal.sahams.entries.map((entry) {
              final saham = entry.value;
              final signName = _getSignName(saham.sign);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: FluentTheme.of(
                      context,
                    ).cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: FluentTheme.of(
                        context,
                      ).resources.dividerStrokeColorDefault,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              saham.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$signName ${saham.degreeInSign.toStringAsFixed(1)}° - ${saham.interpretation}',
                              style: FluentTheme.of(context).typography.caption,
                            ),
                          ],
                        ),
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

  Widget _buildInterpretationCard(VarshaphalChart varshaphal) {
    return Card(
      backgroundColor: Colors.blue.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.lightbulb, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Overall Yearly Guidance',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(varshaphal.interpretation),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Map<int, List<String>> _getPlanetsMap(VedicChart chart) {
    final map = <int, List<String>>{};
    chart.planets.forEach((planet, info) {
      final sign = (info.longitude / 30).floor() + 1;
      map.putIfAbsent(sign, () => []);
      map[sign]!.add(planet.toString().split('.').last);
    });
    return map;
  }

  int _getAscendantSignInt(VedicChart chart) {
    final asc = chart.houses.cusps[0];
    return ((asc / 30).floor() + 1);
  }

  String _getSignName(int sign) {
    const signs = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces',
    ];
    return signs[sign % 12];
  }

  Color _getPlanetColor(String planet) {
    switch (planet) {
      case 'Sun':
        return Colors.orange;
      case 'Moon':
        return Colors.blue;
      case 'Mars':
        return Colors.red;
      case 'Mercury':
        return Colors.green;
      case 'Jupiter':
        return Colors.purple;
      case 'Venus':
        return const Color(0xFFE91E63);
      case 'Saturn':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getPlanetSymbol(String planet) {
    switch (planet) {
      case 'Sun':
        return '☉';
      case 'Moon':
        return '☽';
      case 'Mars':
        return '♂';
      case 'Mercury':
        return '☿';
      case 'Jupiter':
        return '♃';
      case 'Venus':
        return '♀';
      case 'Saturn':
        return '♄';
      default:
        return '○';
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.teal;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
