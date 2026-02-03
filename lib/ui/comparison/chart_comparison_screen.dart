import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../logic/chart_comparison.dart';
import '../../logic/kp_chart_service.dart';
import '../../core/database_helper.dart';
import '../widgets/strength_meter.dart';

class ChartComparisonScreen extends StatefulWidget {
  final CompleteChartData? chart1;

  const ChartComparisonScreen({super.key, this.chart1});

  @override
  State<ChartComparisonScreen> createState() => _ChartComparisonScreenState();
}

class _ChartComparisonScreenState extends State<ChartComparisonScreen> {
  CompleteChartData? _selectedChart1;
  CompleteChartData? _selectedChart2;
  int _currentIndex = 0;
  final KPChartService _kpChartService = KPChartService();

  @override
  void initState() {
    super.initState();
    _selectedChart1 = widget.chart1;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedChart1 == null || _selectedChart2 == null) {
      return ScaffoldPage(
        header: const PageHeader(title: Text('Chart Comparison')),
        content: _buildChartSelector(),
      );
    }

    final compatibility = ChartComparison.analyzeCompatibility(
      _selectedChart1!,
      _selectedChart2!,
    );

    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text('Chart Comparison'),
        leading: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.back),
              onPressed: () {
                // Try to navigate back, or reset state
                if (widget.chart1 != null) {
                  Navigator.pop(context);
                } else {
                  setState(() {
                    _selectedChart2 = null; // Basic reset
                  });
                }
              },
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.edit),
              label: const Text('Change Charts'),
              onPressed: () {
                setState(() {
                  _selectedChart2 = null; // Reset to go back to selection
                });
              },
            ),
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
        displayMode: PaneDisplayMode.top,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.heart),
            title: const Text('Compatibility'),
            body: _buildBody(_buildCompatibilityTab(compatibility)),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.relationship),
            title: const Text('Synastry'),
            body: _buildBody(_buildSynastryTab(compatibility)),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.group),
            title: const Text('House Overlays'),
            body: _buildBody(_buildHouseOverlaysTab(compatibility)),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.favorite_star),
            title: const Text('Navamsa'),
            body: _buildBody(_buildNavamsaTab(compatibility)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Widget content) {
    return ScaffoldPage(content: content);
  }

  Widget _buildChartSelector() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          backgroundColor: Colors.blue.withOpacity(0.1),
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
          FilledButton(
            onPressed: () {
              setState(() {}); // Trigger rebuild
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Compare Charts', style: TextStyle(fontSize: 16)),
            ),
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
                leading: const Icon(FluentIcons.contact),
                title: const Text('Chart Selected'),
                subtitle: Text(selected.birthData.name),
                trailing: IconButton(
                  icon: const Icon(FluentIcons.clear),
                  onPressed: () => onSelect(null),
                ),
              )
            else
              Button(
                onPressed: () async {
                  final chart = await _showChartPicker();
                  if (chart != null) {
                    onSelect(chart);
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.add),
                    SizedBox(width: 8),
                    Text('Select Chart'),
                  ],
                ),
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
        return ContentDialog(
          title: const Text('Select Chart'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: charts.length,
              itemBuilder: (context, index) {
                final chart = charts[index];
                return ListTile.selectable(
                  title: Text(chart['name'] ?? 'Unknown'),
                  subtitle: Text(chart['dateTime'] ?? ''),
                  onPressed: () async {
                    // Show loading if needed, or better, confirm
                    // Here we will try to load data
                    try {
                      final birthData = BirthData(
                        dateTime: DateTime.parse(chart['dateTime']),
                        location: Location(
                          latitude: chart['latitude'],
                          longitude: chart['longitude'],
                        ),
                        name: chart['name'] ?? '',
                        place: chart['locationName'] ?? '',
                      );

                      // Note: This is async and might take time.
                      // Ideally show progress.
                      final completeData = await _kpChartService
                          .generateCompleteChart(birthData);
                      if (context.mounted) {
                        Navigator.pop(context, completeData);
                      }
                    } catch (e) {
                      // Handle error
                    }
                  },
                );
              },
            ),
          ),
          actions: [
            Button(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
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
                // Custom Score Indicator using ProgressRing
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: ProgressRing(
                        value: compatibility.overallScore,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        activeColor: _getScoreColor(compatibility.overallScore),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          compatibility.overallScore.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getCompatibilityGrade(compatibility.overallScore),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getScoreColor(compatibility.overallScore),
                          ),
                        ),
                      ],
                    ),
                  ],
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
        Card(
          backgroundColor: Colors.purple.withOpacity(0.1),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Synastry aspects show how planets from one chart interact with planets in another chart.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...compatibility.aspects.map(_buildSynastryCard),
      ],
    );
  }

  Widget _buildSynastryCard(SynastryAspect aspect) {
    final isPositive =
        aspect.effect == AspectEffect.veryPositive ||
        aspect.effect == AspectEffect.positive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          title: Text(
            '${aspect.planet1} ${aspect.aspectType} ${aspect.planet2}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${aspect.effect.toString().split('.').last} • Orb: ${aspect.orb.toStringAsFixed(1)}°',
          ),
          leading: Icon(
            isPositive ? FluentIcons.heart : FluentIcons.warning,
            color: isPositive ? Colors.green : Colors.orange,
          ),
        ),
      ),
    );
  }

  Widget _buildHouseOverlaysTab(SynastryAnalysis compatibility) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'House overlays show where one person\'s planets fall in the other person\'s houses.',
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...compatibility.houseOverlays.map(_buildOverlayCard),
      ],
    );
  }

  Widget _buildOverlayCard(HouseOverlay overlay) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          title: Text(
            '${overlay.planet} in House ${overlay.house}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(overlay.significance),
        ),
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

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.teal;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}
