import 'package:flutter/material.dart';
import 'widgets/chart_widget.dart';
import '../../data/models.dart';
import '../../logic/kp_chart_service.dart';
import 'package:jyotish/jyotish.dart'; // For VedicChart type

class ChartScreen extends StatefulWidget {
  const ChartScreen({Key? key}) : super(key: key);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vedic Chart"),
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
          // Transform planets to list of strings relative to houses (1-12)
          // For North Indian: List needs to be planets in House 1, House 2...
          // For South Indian: List needs to be planets in Aries, Taurus...

          List<String> displayPlanets = [];
          if (_style == ChartStyle.northIndian) {
            displayPlanets = _getPlanetsByHouse(data.baseChart);
          } else {
            displayPlanets = _getPlanetsBySign(data.baseChart);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ChartWidget(
                  planetPositions: displayPlanets,
                  style: _style,
                  size: 350,
                ),
                const SizedBox(height: 24),
                _buildKPInfo(data.kpData),
              ],
            ),
          );
        },
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
            ...kpData.subLords
                .asMap()
                .entries
                .map(
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
                )
                .toList(),
          ],
        ),
      ),
    );
  }
}
