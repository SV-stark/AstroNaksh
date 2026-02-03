import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../logic/chart_comparison.dart';
import '../../core/database_helper.dart';
import '../widgets/strength_meter.dart';

class ChartComparisonScreen extends StatefulWidget {
  final CompleteChartData? chart1;

  const ChartComparisonScreen({super.key, this.chart1});

  @override
  State<ChartComparisonScreen> createState() => _ChartComparisonScreenState();
}

class _ChartComparisonScreenState extends State<ChartComparisonScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CompleteChartData? _selectedChart1;
  CompleteChartData? _selectedChart2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedChart1 = widget.chart1;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart Comparison'),
        bottom: _selectedChart1 != null && _selectedChart2 != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Compatibility'),
                  Tab(text: 'Synastry'),
                  Tab(text: 'House Overlays'),
                  Tab(text: 'Navamsa'),
                ],
              )
            : null,
      ),
      body: _selectedChart1 == null || _selectedChart2 == null
          ? _buildChartSelector()
          : _buildComparisonView(),
    );
  }

  Widget _buildChartSelector() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue.shade50,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chart Comparison',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Compare two birth charts for compatibility analysis. '
                  'This includes Kuta matching, synastry aspects, and house overlays.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        _buildChartSelection(
          'Person 1',
          _selectedChart1,
          (chart) => setState(() => _selectedChart1 = chart),
        ),

        const SizedBox(height: 16),

        _buildChartSelection(
          'Person 2',
          _selectedChart2,
          (chart) => setState(() => _selectedChart2 = chart),
        ),

        const SizedBox(height: 24),

        if (_selectedChart1 != null && _selectedChart2 != null)
          ElevatedButton.icon(
            onPressed: () {
              setState(() {}); // Trigger rebuild to show comparison
            },
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Compare Charts'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
      ],
    );
  }

  Widget _buildChartSelection(
    String label,
    CompleteChartData? selected,
    Function(CompleteChartData?) onSelect,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (selected != null)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Chart Selected'),
                trailing: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => onSelect(null),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () async {
                  // Show chart picker dialog
                  final chart = await _showChartPicker();
                  if (chart != null) {
                    onSelect(chart);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Select Chart'),
              ),
          ],
        ),
      ),
    );
  }

  Future<CompleteChartData?> _showChartPicker() async {
    final db = DatabaseHelper();
    final charts = await db.getCharts();

    if (!mounted) return null;

    return showDialog<CompleteChartData>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Chart'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: charts.length,
              itemBuilder: (context, index) {
                final chart = charts[index];
                return ListTile(
                  title: Text(chart['name'] ?? 'Unknown'),
                  subtitle: Text(chart['dateTime'] ?? ''),
                  onTap: () {
                    // Convert chart map to CompleteChartData
                    // This is simplified - you'd need proper conversion
                    Navigator.pop(context, null);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildComparisonView() {
    final compatibility = ChartComparison.analyzeCompatibility(
      _selectedChart1!,
      _selectedChart2!,
    );

    return TabBarView(
      controller: _tabController,
      children: [
        _buildCompatibilityTab(compatibility),
        _buildSynastryTab(compatibility),
        _buildHouseOverlaysTab(compatibility),
        _buildNavamsaTab(compatibility),
      ],
    );
  }

  Widget _buildCompatibilityTab(SynastryAnalysis compatibility) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall score
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Compatibility Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                CircularScoreIndicator(
                  score: compatibility.overallScore,
                  label: _getCompatibilityGrade(compatibility.overallScore),
                  size: 120,
                ),
                const SizedBox(height: 16),
                Text(
                  _getCompatibilityDescription(compatibility.overallScore),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Kuta matching
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kuta Matching (Ashtakoota)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Total: ${compatibility.nakshatraAnalysis.totalScore}/36',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                StrengthMeter(
                  value: (compatibility.nakshatraAnalysis.varna / 1) * 100,
                  label: 'Varna: ${compatibility.nakshatraAnalysis.varna}/1',
                  showPercentage: false,
                ),
                StrengthMeter(
                  value: (compatibility.nakshatraAnalysis.vashya / 2) * 100,
                  label: 'Vashya: ${compatibility.nakshatraAnalysis.vashya}/2',
                  showPercentage: false,
                ),
                StrengthMeter(
                  value: (compatibility.nakshatraAnalysis.tara / 3) * 100,
                  label: 'Tara: ${compatibility.nakshatraAnalysis.tara}/3',
                  showPercentage: false,
                ),
                StrengthMeter(
                  value: (compatibility.nakshatraAnalysis.yoni / 4) * 100,
                  label: 'Yoni: ${compatibility.nakshatraAnalysis.yoni}/4',
                  showPercentage: false,
                ),
                StrengthMeter(
                  value: (compatibility.nakshatraAnalysis.maitri / 5) * 100,
                  label: 'Maitri: ${compatibility.nakshatraAnalysis.maitri}/5',
                  showPercentage: false,
                ),
                StrengthMeter(
                  value: (compatibility.nakshatraAnalysis.gana / 6) * 100,
                  label: 'Gana: ${compatibility.nakshatraAnalysis.gana}/6',
                  showPercentage: false,
                ),
                StrengthMeter(
                  value: (compatibility.nakshatraAnalysis.bhakoot / 7) * 100,
                  label:
                      'Bhakoot: ${compatibility.nakshatraAnalysis.bhakoot}/7',
                  showPercentage: false,
                ),
                StrengthMeter(
                  value: (compatibility.nakshatraAnalysis.nadi / 8) * 100,
                  label: 'Nadi: ${compatibility.nakshatraAnalysis.nadi}/8',
                  showPercentage: false,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analysis Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(compatibility.summary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSynastryTab(SynastryAnalysis compatibility) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          color: Colors.purple,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Synastry aspects show how planets from one chart interact with planets in another chart.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...compatibility.aspects.map(_buildSynastryCard),
      ],
    );
  }

  Widget _buildSynastryCard(SynastryAspect aspect) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          '${aspect.planet1} ${aspect.aspectType} ${aspect.planet2}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${aspect.effect.toString().split('.').last} • Orb: ${aspect.orb.toStringAsFixed(1)}°',
        ),
        leading: Icon(
          aspect.effect == AspectEffect.veryPositive ||
                  aspect.effect == AspectEffect.positive
              ? Icons.favorite
              : Icons.warning,
          color:
              aspect.effect == AspectEffect.veryPositive ||
                  aspect.effect == AspectEffect.positive
              ? Colors.green
              : Colors.orange,
        ),
      ),
    );
  }

  Widget _buildHouseOverlaysTab(SynastryAnalysis compatibility) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(
          color: Colors.indigo,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'House overlays show where one person\'s planets fall in the other person\'s houses.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...compatibility.houseOverlays.map(_buildOverlayCard),
      ],
    );
  }

  Widget _buildOverlayCard(HouseOverlay overlay) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          '${overlay.planet} in House ${overlay.house}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(overlay.significance),
      ),
    );
  }

  Widget _buildNavamsaTab(SynastryAnalysis compatibility) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Navamsa Compatibility',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  'Ascendant: ${compatibility.navamsaCompatibility.ascendantCompatibility}\n'
                  'Moon: ${compatibility.navamsaCompatibility.moonSignCompatibility}\n'
                  'Venus: ${compatibility.navamsaCompatibility.venusSignCompatibility}\n'
                  'Score: ${compatibility.navamsaCompatibility.score}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getCompatibilityGrade(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Very Good';
    if (score >= 50) return 'Good';
    if (score >= 35) return 'Fair';
    return 'Challenging';
  }

  String _getCompatibilityDescription(double score) {
    if (score >= 80) {
      return 'This is an excellent match with strong compatibility across multiple dimensions.';
    } else if (score >= 65) {
      return 'This is a very good match with favorable planetary interactions.';
    } else if (score >= 50) {
      return 'This is a good match with potential for a harmonious relationship.';
    } else if (score >= 35) {
      return 'This match has fair compatibility. Some adjustments may be needed.';
    }
    return 'This match has compatibility challenges. Understanding and effort will be important.';
  }
}
