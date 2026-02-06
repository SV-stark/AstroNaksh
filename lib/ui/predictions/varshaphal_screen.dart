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
  late int _selectedYear;
  int _expandedPeriodIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Varshaphal (Annual Horoscope)'),
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
            return const Center(child: ProgressRing());
          }

          if (snapshot.hasError) {
            return Center(
              child: InfoBar(
                title: const Text('Calculation Error'),
                content: Text(snapshot.error.toString()),
                severity: InfoBarSeverity.error,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No Data'));
          }

          final chart = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildYearSelector(),
              const SizedBox(height: 16),
              _buildHeaderCard(chart),
              const SizedBox(height: 16),
              _buildChartDisplay(chart),
              const SizedBox(height: 16),
              _buildVarsheshAnalysisCard(chart),
              const SizedBox(height: 16),
              _buildMuddaDashaSection(chart),
              const SizedBox(height: 16),
              _buildSahamsCard(chart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildYearSelector() {
    return Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(FluentIcons.chevron_left),
            onPressed: () => setState(() => _selectedYear--),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$_selectedYear - ${_selectedYear + 1}',
              style: FluentTheme.of(context).typography.title,
            ),
          ),
          IconButton(
            icon: const Icon(FluentIcons.chevron_right),
            onPressed: () => setState(() => _selectedYear++),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(VarshaphalChart chart) {
    return Card(
      backgroundColor: FluentTheme.of(context).accentColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solar Return (Varsha Pravesh)',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy HH:mm:ss',
                      ).format(chart.solarReturnTime),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      chart.isDayBirth ? 'Day Chart' : 'Night Chart',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: chart.isDayBirth ? Colors.orange : Colors.blue,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Varshesh',
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    Text(
                      chart.yearLord,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getPlanetColor(chart.yearLord),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(style: DividerThemeData(verticalMargin: 12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactInfo('Muntha', _getSignName(chart.muntha)),
                _buildCompactInfo('Muntha Lord', chart.munthaLord),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChartDisplay(VarshaphalChart chart) {
    final planetsMap = _getPlanetsMap(chart.chart);
    final ascSign = _getAscendantSignInt(chart.chart);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Varsha Kundali'),
            const SizedBox(height: 10),
            ChartWidget(
              planetsBySign: planetsMap,
              ascendantSign: ascSign,
              style: ChartStyle.northIndian,
              size: 300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVarsheshAnalysisCard(VarshaphalChart chart) {
    return Expander(
      header: const Text('Varshesh Selection & Strength (Panchavargiya Bala)'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The Year Lord (Varshesh) is selected from the 5 Office Bearers based on aspect and strength.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          // Candidates List
          ...chart.varsheshCandidates.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $c'),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Planetary Strengths (0-20 scale):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: Colors.grey.withOpacity(0.3)),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
              6: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFF0F0F0)),
                children: [
                  Padding(padding: EdgeInsets.all(4), child: Text('Planet')),
                  Padding(padding: EdgeInsets.all(4), child: Text('Ksh')),
                  Padding(padding: EdgeInsets.all(4), child: Text('Uch')),
                  Padding(padding: EdgeInsets.all(4), child: Text('Had')),
                  Padding(padding: EdgeInsets.all(4), child: Text('Dre')),
                  Padding(padding: EdgeInsets.all(4), child: Text('Nav')),
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...chart.panchavargiyaBala.entries.map((e) {
                final s = e.value;
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(e.key),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(s.kshetra.toStringAsFixed(1)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(s.uchcha.toStringAsFixed(1)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(s.hadda.toStringAsFixed(1)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(s.drekkana.toStringAsFixed(1)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(s.navamsa.toStringAsFixed(1)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        s.total.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMuddaDashaSection(VarshaphalChart chart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mudda Dasha (Annual Vimshottari)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...chart.varshikDasha.asMap().entries.map((entry) {
              final period = entry.value;
              final scorePercent = period.favorableScore; // 0.35 to 0.95
              final scoreInt = (scorePercent * 100).round();

              return Expander(
                header: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getPlanetColor(period.planet),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${period.planet}: ${DateFormat('MMM dd').format(period.startDate)} - ${DateFormat('MMM dd').format(period.endDate)}',
                      ),
                    ),
                    // Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getScoreColor(scoreInt),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$scoreInt',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Score Bar
                    Row(
                      children: [
                        const Text('Score: '),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: scorePercent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getScoreColor(scoreInt),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$scoreInt/100'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Duration: ${period.durationDays.toStringAsFixed(1)} days',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),
                    Text(period.prediction),
                    const SizedBox(height: 12),
                    // Key Themes
                    if (period.keyThemes.isNotEmpty) ...[
                      const Text(
                        'Key Themes:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: period.keyThemes
                            .map(
                              (t) => Chip(
                                label: Text(
                                  t,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                backgroundColor: Colors.blue.withOpacity(0.1),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Cautions
                    if (period.cautions.isNotEmpty) ...[
                      const Text(
                        'Watch Out For:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      ...period.cautions.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Row(
                            children: [
                              const Icon(
                                FluentIcons.warning,
                                size: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(c, style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSahamsCard(VarshaphalChart chart) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sahams (Key Points)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...chart.sahams.values.map(
              (s) => Text(
                '${s.name}: ${_getSignName(s.sign)} ${s.degreeInSign.toStringAsFixed(2)}°',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  String _getSignName(int sign) => AstrologyConstants.getSignName(sign);

  Map<int, List<String>> _getPlanetsMap(VedicChart chart) {
    final map = <int, List<String>>{};
    chart.planets.forEach((p, info) {
      final sign = (info.longitude / 30).floor() + 1;
      map.putIfAbsent(sign, () => []);
      map[sign]!.add(p.toString().split('.').last);
    });
    return map;
  }

  int _getAscendantSignInt(VedicChart chart) {
    return (chart.houses.cusps[0] / 30).floor() + 1;
  }

  Color _getPlanetColor(String planet) {
    switch (planet.toLowerCase()) {
      case 'sun':
        return Colors.orange;
      case 'moon':
        return Colors.blue;
      case 'mars':
        return Colors.red;
      case 'mercury':
        return Colors.green;
      case 'jupiter':
        return Colors.purple;
      case 'venus':
        return Colors.magenta;
      case 'saturn':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  Color _getScoreColor(int score) {
    // Gradient from Red (35) to Yellow (60) to Green (95)
    if (score >= 75) {
      return Colors.green;
    } else if (score >= 60) {
      return Colors.orange;
    } else if (score >= 50) {
      return Colors.yellow.darkest;
    } else {
      return Colors.red;
    }
  }
}
