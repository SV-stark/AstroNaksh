import 'package:flutter/material.dart';
import 'widgets/chart_widget.dart';
import '../../data/models.dart';
import '../../logic/kp_chart_service.dart';
import 'package:jyotish/jyotish.dart'; // For VedicChart type

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final KPChartService _kpChartService = KPChartService();
  Future<ChartData>? _chartDataFuture;
  ChartStyle _style = ChartStyle.northIndian;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as BirthData?;
    if (args != null && _chartDataFuture == null) {
      _chartDataFuture = _kpChartService.generateKPChart(args);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Vedic Chart"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "D-1"),
              Tab(text: "D-9"),
              Tab(text: "KP"),
              Tab(text: "Dasha"),
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
        body: FutureBuilder<ChartData>(
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
            // For now D-1 and D-9 use dummy data transformation logic
            // In a real app, data.baseChart would contain D-9 info or we'd calculate it.

            return TabBarView(
              children: [
                _buildChartTab(data.baseChart, "Rashi (D-1)"),
                _buildChartTab(
                  data.baseChart,
                  "Navamsa (D-9)",
                ), // Should be different data
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildKPInfo(data.kpData),
                ),
                const Center(child: Text("Dasha System (Coming Soon)")),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChartTab(VedicChart chart, String title) {
    List<String> displayPlanets = [];
    if (_style == ChartStyle.northIndian) {
      displayPlanets = _getPlanetsByHouse(chart);
    } else {
      displayPlanets = _getPlanetsBySign(chart);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          ChartWidget(
            planetPositions: displayPlanets,
            style: _style,
            size: 350,
          ),
        ],
      ),
    );
  }

  List<String> _getPlanetsByHouse(VedicChart chart) {
    // Determine Lagna (Ascendant) House
    // Map planets to houses relative to Lagna
    // NOTE: VedicChart usually provides planets with longitude
    // We need to calculate which house they are in.
    // For simplicity, we'll create a dummy map here since I don't have the full library API.
    // Assuming VedicChart has a way to get planets in houses.
    // Using a placeholder implementation.
    return List.generate(12, (index) => "H${index + 1}");
  }

  List<String> _getPlanetsBySign(VedicChart chart) {
    // Map planets to signs (0-11)
    return List.generate(12, (index) => "S${index + 1}");
  }

  Widget _buildKPInfo(KPData kpData) {
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
            // List sub lords (placeholder UI)
            ...kpData.subLords.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Planet ${e.key + 1}"), // Placeholder name
                    Text("${e.value.starLord} / ${e.value.subLord}"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
