import 'package:flutter/material.dart';
import 'widgets/chart_widget.dart';
import '../../data/models.dart';
import '../../logic/kp_chart_service.dart';
import '../../logic/divisional_charts.dart';
import 'package:jyotish/jyotish.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final KPChartService _kpChartService = KPChartService();
  Future<CompleteChartData>? _chartDataFuture;
  ChartStyle _style = ChartStyle.northIndian;
  String _selectedDivisionalChart = 'D-9';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as BirthData?;
    if (args != null && _chartDataFuture == null) {
      _chartDataFuture = _kpChartService.generateCompleteChart(args);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Vedic Chart"),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "D-1", icon: Icon(Icons.account_balance)),
              Tab(text: "Vargas", icon: Icon(Icons.grid_on)),
              Tab(text: "KP", icon: Icon(Icons.scatter_plot)),
              Tab(text: "Dasha", icon: Icon(Icons.timer)),
              Tab(text: "Details", icon: Icon(Icons.list)),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                _style == ChartStyle.northIndian
                    ? Icons.grid_view
                    : Icons.diamond,
              ),
              onPressed: () {
                setState(() {
                  _style = _style == ChartStyle.northIndian
                      ? ChartStyle.southIndian
                      : ChartStyle.northIndian;
                });
              },
              tooltip: "Toggle Chart Style",
            ),
          ],
        ),
        body: FutureBuilder<CompleteChartData>(
          future: _chartDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData) {
              return const Center(child: Text("No Data"));
            }

            final data = snapshot.data!;

            return TabBarView(
              children: [
                _buildD1Tab(data),
                _buildVargasTab(data),
                _buildKPTab(data),
                _buildDashaTab(data),
                _buildDetailsTab(data),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildD1Tab(CompleteChartData data) {
    final planetsBySign = _getPlanetsBySign(data.baseChart);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Rashi Chart (D-1)",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            "Lagna: ${_getAscendantSign(data.baseChart)}",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ChartWidget(planetPositions: planetsBySign, style: _style, size: 350),
          const SizedBox(height: 16),
          _buildPlanetPositionsTable(data),
        ],
      ),
    );
  }

  Widget _buildVargasTab(CompleteChartData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Divisional Charts (Vargas)",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Divisional chart selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                [
                      'D-1',
                      'D-2',
                      'D-3',
                      'D-4',
                      'D-7',
                      'D-9',
                      'D-10',
                      'D-12',
                      'D-16',
                      'D-20',
                      'D-24',
                      'D-27',
                      'D-30',
                      'D-40',
                      'D-45',
                      'D-60',
                    ]
                    .map(
                      (code) => ChoiceChip(
                        label: Text(code),
                        selected: _selectedDivisionalChart == code,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedDivisionalChart = code;
                            });
                          }
                        },
                      ),
                    )
                    .toList(),
          ),

          const SizedBox(height: 16),

          // Display selected divisional chart
          _buildDivisionalChartDisplay(data, _selectedDivisionalChart),
        ],
      ),
    );
  }

  Widget _buildDivisionalChartDisplay(CompleteChartData data, String code) {
    final chart = data.divisionalCharts[code];
    if (chart == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Chart data not available"),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${chart.name} (${chart.code})",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              chart.description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Planet positions in this division
            ...chart.positions.entries.map((entry) {
              final sign = (entry.value / 30).floor();
              final degree = entry.value % 30;
              final signName = DivisionalCharts.getSignName(sign);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text("${degree.toStringAsFixed(1)}° $signName"),
                    const Spacer(),
                    Text(
                      DivisionalCharts.getSignLord(sign),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              );
            }),

            if (chart.ascendantSign != null) ...[
              const Divider(),
              Text(
                "Ascendant: ${DivisionalCharts.getSignName(chart.ascendantSign!)} "
                "(${DivisionalCharts.getSignLord(chart.ascendantSign!)})",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKPTab(CompleteChartData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKPSubLordsCard(data),
          const SizedBox(height: 16),
          _buildKPSignificatorsCard(data),
          const SizedBox(height: 16),
          _buildRulingPlanetsCard(data),
        ],
      ),
    );
  }

  Widget _buildKPSubLordsCard(CompleteChartData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "KP Sub Lords",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),

            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Planet",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Nakshatra",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Star Lord",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Sub Lord",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Sub-Sub",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Planet rows
            ...data.significatorTable.entries.map((entry) {
              final planet = entry.key;
              final info = entry.value;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(planet)),
                    Expanded(flex: 2, child: Text(info['nakshatra'] ?? '')),
                    Expanded(flex: 2, child: Text(info['starLord'] ?? '')),
                    Expanded(flex: 2, child: Text(info['subLord'] ?? '')),
                    Expanded(flex: 2, child: Text(info['subSubLord'] ?? '')),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKPSignificatorsCard(CompleteChartData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Significations",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),

            ...data.significatorTable.entries.map((entry) {
              final planet = entry.key;
              final info = entry.value;
              final significations =
                  info['significations'] as List<dynamic>? ?? [];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        planet,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text("Houses: ${significations.join(', ')}"),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRulingPlanetsCard(CompleteChartData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ruling Planets",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: data.kpData.rulingPlanets
                  .map(
                    (planet) => Chip(
                      label: Text(planet),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashaTab(CompleteChartData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVimshottariDashaCard(data.dashaData.vimshottari),
          const SizedBox(height: 16),
          _buildYoginiDashaCard(data.dashaData.yogini),
          const SizedBox(height: 16),
          _buildCharaDashaCard(data.dashaData.chara),
        ],
      ),
    );
  }

  Widget _buildVimshottariDashaCard(VimshottariDasha dasha) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Vimshottari Dasha",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "Birth Lord: ${dasha.birthLord}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              "Balance at Birth: ${dasha.formattedBalanceAtBirth}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Show first 5 mahadashas
            ...dasha.mahadashas
                .take(5)
                .map(
                  (maha) => ExpansionTile(
                    title: Text("${maha.lord} - ${maha.formattedPeriod}"),
                    subtitle: Text(
                      "${_formatDate(maha.startDate)} to ${_formatDate(maha.endDate)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    children: maha.antardashas
                        .take(3)
                        .map(
                          (antar) => ListTile(
                            dense: true,
                            title: Text(
                              "  ${antar.lord} - ${antar.periodYears.toStringAsFixed(2)} years",
                            ),
                            subtitle: Text(
                              "  ${_formatDate(antar.startDate)} to ${_formatDate(antar.endDate)}",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildYoginiDashaCard(YoginiDasha dasha) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Yogini Dasha",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "Starting Yogini: ${dasha.startYogini}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(),
            const SizedBox(height: 8),

            ...dasha.mahadashas
                .map(
                  (d) => ListTile(
                    dense: true,
                    title: Text("${d.name} (${d.lord})"),
                    subtitle: Text(
                      "${_formatDate(d.startDate)} to ${_formatDate(d.endDate)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Text("${d.periodYears.toInt()} years"),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCharaDashaCard(CharaDasha dasha) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chara Dasha (Jaimini)",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "Starting Sign: ${dasha.periods.first.signName}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(),
            const SizedBox(height: 8),

            ...dasha.periods
                .take(8)
                .map(
                  (p) => ListTile(
                    dense: true,
                    title: Text("${p.signName} (${p.lord})"),
                    subtitle: Text(
                      "${_formatDate(p.startDate)} to ${_formatDate(p.endDate)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Text("${p.periodYears.toInt()} years"),
                  ),
                )
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(CompleteChartData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentDashaCard(data),
          const SizedBox(height: 16),
          _buildNavamsaSummaryCard(data),
        ],
      ),
    );
  }

  Widget _buildCurrentDashaCard(CompleteChartData data) {
    final currentDasha = data.getCurrentDashas(DateTime.now());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current Running Dasha",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            if (currentDasha.isNotEmpty) ...[
              _buildDashaRow(
                "Mahadasha",
                currentDasha['mahadasha'] ?? '',
                currentDasha['mahaStart'],
                currentDasha['mahaEnd'],
              ),
              const SizedBox(height: 8),
              _buildDashaRow(
                "Antardasha",
                currentDasha['antardasha'] ?? '',
                currentDasha['antarStart'],
                currentDasha['antarEnd'],
              ),
              const SizedBox(height: 8),
              _buildDashaRow(
                "Pratyantardasha",
                currentDasha['pratyantardasha'] ?? '',
                currentDasha['pratyanStart'],
                currentDasha['pratyanEnd'],
              ),
            ] else ...[
              const Text("Unable to calculate current dasha"),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDashaRow(
    String level,
    String lord,
    DateTime? start,
    DateTime? end,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                level,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                lord,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (start != null && end != null)
            Text(
              "${_formatDate(start)} to ${_formatDate(end)}",
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildNavamsaSummaryCard(CompleteChartData data) {
    final navamsa = data.divisionalCharts['D-9'];
    if (navamsa == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Navamsa (D-9) Summary",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(navamsa.getFormattedPositions()),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanetPositionsTable(CompleteChartData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Planet Positions",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            ...data.significatorTable.entries.map((entry) {
              final planet = entry.key;
              final info = entry.value;
              final position = info['position'] as double? ?? 0;
              final sign = (position / 30).floor();
              final degree = position % 30;
              final house = info['house'] as int? ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 60, child: Text(planet)),
                    Text(
                      "${degree.toStringAsFixed(1)}° ${DivisionalCharts.getSignName(sign)}",
                    ),
                    const Spacer(),
                    Text("House $house"),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<String> _getPlanetsBySign(VedicChart chart) {
    final positions = <String>[];

    chart.planets.forEach((planet, info) {
      final sign = (info.longitude / 30).floor();
      final degree = info.longitude % 30;
      final planetName = planet.toString().split('.').last;
      positions.add("$planetName:$sign:${degree.toStringAsFixed(1)}");
    });

    return positions;
  }

  String _getAscendantSign(VedicChart chart) {
    try {
      final houses = chart.houses;
      if (houses.cusps.isNotEmpty) {
        final long = houses.cusps[0];
        final sign = (long / 30).floor();
        return DivisionalCharts.getSignName(sign);
      }
      return "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
