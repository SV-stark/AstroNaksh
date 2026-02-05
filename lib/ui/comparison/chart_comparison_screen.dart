import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';
import '../../data/models.dart';
import '../../logic/chart_comparison.dart';
import '../../logic/kp_chart_service.dart';
import '../../core/database_helper.dart';
import '../widgets/chart_widget.dart';

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

  void _swapCharts() {
    setState(() {
      final temp = _selectedChart1;
      _selectedChart1 = _selectedChart2;
      _selectedChart2 = temp;
    });
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
        title: Row(
          children: [
            const Text('Chart Comparison'),
            const SizedBox(width: 16),
            // Chart names display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: FluentTheme.of(
                  context,
                ).accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedChart1!.birthData.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  const Icon(FluentIcons.heart_fill, size: 12),
                  const SizedBox(width: 8),
                  Text(
                    _selectedChart2!.birthData.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: CommandBar(
          overflowBehavior: CommandBarOverflowBehavior.noWrap,
          primaryItems: [
            // Swap Button
            CommandBarButton(
              icon: const Icon(FluentIcons.switch_widget),
              label: const Text('Swap'),
              onPressed: _swapCharts,
            ),
            // Side-by-Side View Button
            CommandBarButton(
              icon: const Icon(FluentIcons.side_panel_mirrored),
              label: const Text('View Charts'),
              onPressed: () => _showSideBySideView(),
            ),
            const CommandBarSeparator(),
            CommandBarButton(
              icon: const Icon(FluentIcons.edit),
              label: const Text('Change'),
              onPressed: () {
                setState(() {
                  _selectedChart2 = null;
                });
              },
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.back),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
        displayMode: PaneDisplayMode.open,
        size: const NavigationPaneSize(openWidth: 220),
        header: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                FluentIcons.heart_fill,
                size: 32,
                color: FluentTheme.of(context).accentColor,
              ),
              const SizedBox(height: 8),
              Text(
                'Compatibility',
                style: FluentTheme.of(
                  context,
                ).typography.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Score: ${compatibility.overallScore.toStringAsFixed(1)}',
                style: TextStyle(
                  color: _getScoreColor(compatibility.overallScore),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.heart),
            title: const Text('Overview'),
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

  void _showSideBySideView() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Charts Side by Side'),
        constraints: const BoxConstraints(maxWidth: 900),
        content: SizedBox(
          height: 500,
          child: Row(
            children: [
              // Person 1 Chart
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _selectedChart1!.birthData.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(child: _buildMiniChart(_selectedChart1!)),
                    ],
                  ),
                ),
              ),
              // VS indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FluentIcons.heart_fill,
                      color: FluentTheme.of(context).accentColor,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: FluentTheme.of(context).accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Person 2 Chart
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _selectedChart2!.birthData.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(child: _buildMiniChart(_selectedChart2!)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(CompleteChartData data) {
    final planetsMap = _getPlanetsMap(data.baseChart);
    final ascSign = _getAscendantSignInt(data.baseChart);

    return ChartWidget(
      planetsBySign: planetsMap,
      ascendantSign: ascSign,
      style: ChartStyle.northIndian,
      size: 300,
    );
  }

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

  Widget _buildChartSelector() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kundali Matching (36 Kutas)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(height: 8),
                Text(
                  'Compare two birth charts for marriage compatibility. '
                  'The Ashtakoota system analyzes 8 factors totaling 36 points.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Charts Selection Area
        Row(
          children: [
            Expanded(
              child: _buildChartSelection(
                'Person 1',
                _selectedChart1,
                (chart) => setState(() => _selectedChart1 = chart),
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            // VS or Swap indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FluentTheme.of(
                  context,
                ).accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedChart1 != null && _selectedChart2 != null
                    ? FluentIcons.heart_fill
                    : FluentIcons.heart,
                color: FluentTheme.of(context).accentColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartSelection(
                'Person 2',
                _selectedChart2,
                (chart) => setState(() => _selectedChart2 = chart),
                Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Compare Button
        if (_selectedChart1 != null && _selectedChart2 != null)
          Center(
            child: FilledButton(
              onPressed: () {
                setState(() {});
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.heart),
                    SizedBox(width: 8),
                    Text('Compare Charts', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChartSelection(
    String label,
    CompleteChartData? selected,
    Function(CompleteChartData?) onSelect,
    Color accentColor,
  ) {
    return Card(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: accentColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.contact, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selected != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(FluentIcons.check_mark),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.birthData.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${selected.birthData.dateTime.day}/${selected.birthData.dateTime.month}/${selected.birthData.dateTime.year}',
                            style: FluentTheme.of(context).typography.caption,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(FluentIcons.delete),
                      onPressed: () => onSelect(null),
                    ),
                  ],
                ),
              ),
            ] else ...[
              FilledButton(
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
            width: 350,
            height: 450,
            child: charts.isEmpty
                ? const Center(
                    child: Text('No saved charts found. Create a chart first.'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: charts.length,
                    itemBuilder: (context, index) {
                      final chart = charts[index];
                      return ListTile.selectable(
                        title: Text(chart['name'] ?? 'Unknown'),
                        subtitle: Text(chart['dateTime'] ?? ''),
                        onPressed: () async {
                          if (chart['dateTime'] == null ||
                              chart['latitude'] == null ||
                              chart['longitude'] == null) {
                            if (context.mounted) {
                              await showDialog<void>(
                                context: context,
                                builder: (context) => ContentDialog(
                                  title: const Text('Invalid Chart Data'),
                                  content: const Text(
                                    'This chart is missing required information (date/time or location). Please delete and recreate this chart.',
                                  ),
                                  actions: [
                                    Button(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return;
                          }

                          try {
                            final birthData = BirthData(
                              dateTime: DateTime.parse(
                                chart['dateTime'] as String,
                              ),
                              location: Location(
                                latitude: (chart['latitude'] as num).toDouble(),
                                longitude: (chart['longitude'] as num)
                                    .toDouble(),
                              ),
                              name: chart['name'] ?? '',
                              place: chart['locationName'] ?? '',
                            );

                            final completeData = await _kpChartService
                                .generateCompleteChart(birthData);
                            if (context.mounted) {
                              Navigator.pop(context, completeData);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              await showDialog<void>(
                                context: context,
                                builder: (context) => ContentDialog(
                                  title: const Text('Error Loading Chart'),
                                  content: Text(
                                    'Failed to load chart data: $e',
                                  ),
                                  actions: [
                                    Button(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
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
        // Overall score card with visual indicator
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Overall Compatibility',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Score ring
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: ProgressRing(
                            value: compatibility.overallScore,
                            strokeWidth: 10,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            activeColor: _getScoreColor(
                              compatibility.overallScore,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              compatibility.overallScore.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '/ 100',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    // Grade and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getScoreColor(
                                compatibility.overallScore,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getCompatibilityGrade(
                                compatibility.overallScore,
                              ),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getScoreColor(
                                  compatibility.overallScore,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _getCompatibilityDescription(
                              compatibility.overallScore,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Kuta matching detailed breakdown
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kuta Matching (Ashtakoota)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: FluentTheme.of(
                          context,
                        ).accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${compatibility.nakshatraAnalysis.totalScore.toStringAsFixed(0)}/36',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: FluentTheme.of(context).accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildKutaMeter(
                  'Varna (Caste)',
                  compatibility.nakshatraAnalysis.varna,
                  1,
                  'Spiritual compatibility',
                ),
                _buildKutaMeter(
                  'Vashya (Control)',
                  compatibility.nakshatraAnalysis.vashya,
                  2,
                  'Mutual control and dominance',
                ),
                _buildKutaMeter(
                  'Tara (Star)',
                  compatibility.nakshatraAnalysis.tara,
                  3,
                  'Destiny and fortune',
                ),
                _buildKutaMeter(
                  'Yoni (Sexual)',
                  compatibility.nakshatraAnalysis.yoni,
                  4,
                  'Physical compatibility',
                ),
                _buildKutaMeter(
                  'Graha Maitri (Friendship)',
                  compatibility.nakshatraAnalysis.maitri,
                  5,
                  'Planetary friendship',
                ),
                _buildKutaMeter(
                  'Gana (Temperament)',
                  compatibility.nakshatraAnalysis.gana,
                  6,
                  'Nature compatibility',
                ),
                _buildKutaMeter(
                  'Bhakoot (Relative)',
                  compatibility.nakshatraAnalysis.bhakoot,
                  7,
                  'Sign relationship',
                ),
                _buildKutaMeter(
                  'Nadi (Health)',
                  compatibility.nakshatraAnalysis.nadi,
                  8,
                  'Health and progeny',
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

  Widget _buildKutaMeter(
    String label,
    double value,
    int max,
    String description,
  ) {
    final percentage = (value / max) * 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      description,
                      style: FluentTheme.of(context).typography.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: percentage >= 50
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${value.toStringAsFixed(0)}/$max',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: percentage >= 50 ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(
            value: percentage,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            activeColor: percentage >= 50 ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSynastryTab(SynastryAnalysis compatibility) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          backgroundColor: Colors.purple.withValues(alpha: 0.1),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(FluentIcons.info),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Synastry aspects show how planets from one chart interact with planets in another chart.',
                  ),
                ),
              ],
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
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPositive
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPositive ? FluentIcons.heart_fill : FluentIcons.warning,
              color: isPositive ? Colors.green : Colors.orange,
            ),
          ),
          title: Text(
            '${aspect.planet1} ${aspect.aspectType} ${aspect.planet2}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${aspect.effect.toString().split('.').last} • Orb: ${aspect.orb.toStringAsFixed(1)}°',
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
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(FluentIcons.info),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'House overlays show where one person\'s planets fall in the other person\'s houses.',
                  ),
                ),
              ],
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
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'H${overlay.house}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: FluentTheme.of(context).accentColor,
              ),
            ),
          ),
          title: Text(
            '${overlay.planet} in House ${overlay.house}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(overlay.significance),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Chart ${overlay.chart}',
              style: TextStyle(
                fontSize: 12,
                color: FluentTheme.of(context).accentColor,
              ),
            ),
          ),
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
                  'Navamsa (D-9) Compatibility',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildNavamsaItem(
                  'Ascendant',
                  compatibility.navamsaCompatibility.ascendantCompatibility,
                  FluentIcons.contact,
                ),
                _buildNavamsaItem(
                  'Moon Sign',
                  compatibility.navamsaCompatibility.moonSignCompatibility,
                  FluentIcons.heart,
                ),
                _buildNavamsaItem(
                  'Venus Sign',
                  compatibility.navamsaCompatibility.venusSignCompatibility,
                  FluentIcons.favorite_star,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Navamsa Score',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: FluentTheme.of(
                          context,
                        ).accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        compatibility.navamsaCompatibility.score
                            .toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: FluentTheme.of(context).accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavamsaItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: FluentTheme.of(context).typography.caption),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
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
