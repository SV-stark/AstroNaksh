import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart' hide AspectType;
import '../../data/models.dart';
import '../../logic/chart_comparison.dart';
import '../../logic/kp_chart_service.dart';
import '../../logic/matching/matching_service.dart';
import '../../core/pdf_report_service.dart';
import '../../logic/matching/matching_models.dart';
import '../../core/database_helper.dart';
import '../widgets/chart_widget.dart';
import '../input_screen.dart';

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
        header: PageHeader(
          title: const Text('Detailed Kundali Matching'),
          leading: IconButton(
            icon: const Icon(FluentIcons.back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        content: _buildChartSelector(),
      );
    }

    final compatibilityReport = MatchingService.analyzeCompatibility(
      _selectedChart1!,
      _selectedChart2!,
    );

    // Also run synastry for extra tabs using existing logic
    final synastry = ChartComparison.analyzeCompatibility(
      _selectedChart1!,
      _selectedChart2!,
    );

    return NavigationView(
      appBar: NavigationAppBar(
        title: Text('Compatibility: ${compatibilityReport.overallConclusion}'),
        actions: CommandBar(
          overflowBehavior: CommandBarOverflowBehavior.noWrap,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.switch_widget),
              label: const Text('Swap'),
              onPressed: _swapCharts,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.side_panel_mirrored),
              label: const Text('View Charts'),
              onPressed: () => _showSideBySideView(),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.edit),
              label: const Text('New Pair'),
              onPressed: () {
                setState(() {
                  _selectedChart2 = null;
                });
              },
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.pdf),
              label: const Text('Export PDF'),
              onPressed: _exportPdf,
            ),
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
        items: [
          PaneItem(
            icon: Icon(
              FluentIcons.heart_fill,
              color: compatibilityReport.overallColor,
            ),
            title: const Text('Matching Overview'),
            body: _buildOverviewTab(compatibilityReport),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.list),
            title: const Text('Ashtakoota Details'),
            body: _buildAshtakootaTab(compatibilityReport),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.warning),
            title: const Text('Manglik & Doshas'),
            body: _buildDoshaTab(compatibilityReport),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.favorite_star),
            title: const Text('Planetary Synastry'),
            body: _buildSynastryTab(synastry),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.group),
            title: const Text('House Overlays'),
            body: _buildHouseOverlaysTab(synastry),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(MatchingReport report) {
    return ScaffoldPage(
      content: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Score Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${report.ashtakootaScore.toStringAsFixed(1)} / 36',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: report.overallColor,
                    ),
                  ),
                  Text(
                    report.overallConclusion,
                    style: TextStyle(
                      fontSize: 20,
                      color: report.overallColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Key Highlights
                  _buildHighlightRow(
                    'Ashtakoota Score',
                    '${report.ashtakootaScore} points',
                    report.ashtakootaScore >= 18 ? Colors.green : Colors.red,
                  ),
                  _buildHighlightRow(
                    'Mangal Dosha',
                    report.manglikMatch.description,
                    report.manglikMatch.isMatch ? Colors.green : Colors.red,
                  ),
                  if (report.extraChecks.isNotEmpty)
                    _buildHighlightRow(
                      'Mahendra Koota',
                      report.extraChecks
                          .firstWhere((e) => e.name == 'Mahendra')
                          .description,
                      report.extraChecks
                              .firstWhere((e) => e.name == 'Mahendra')
                              .isFavorable
                          ? Colors.green
                          : Colors.orange,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAshtakootaTab(MatchingReport report) {
    return ScaffoldPage(
      content: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: report.kootaResults.length,
        itemBuilder: (context, index) {
          final koota = report.kootaResults[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        koota.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: koota.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: koota.color),
                        ),
                        child: Text(
                          '${koota.score} / ${koota.maxScore}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: koota.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    koota.description,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(koota.detailedReason),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoshaTab(MatchingReport report) {
    return ScaffoldPage(
      content: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mangal Dosha Analysis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatusRow(
                    'Groom Status',
                    report.manglikMatch.maleManglik ? "Manglik" : "Non-Manglik",
                    report.manglikMatch.maleManglik
                        ? Colors.orange
                        : Colors.green,
                  ),
                  _buildStatusRow(
                    'Bride Status',
                    report.manglikMatch.femaleManglik
                        ? "Manglik"
                        : "Non-Manglik",
                    report.manglikMatch.femaleManglik
                        ? Colors.orange
                        : Colors.green,
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Conclusion: ${report.manglikMatch.description}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: report.manglikMatch.isMatch
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Additional Checks',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...report.extraChecks.map(
            (check) => ListTile(
              leading: Icon(
                check.isFavorable
                    ? FluentIcons.check_mark
                    : FluentIcons.warning,
                color: check.isFavorable ? Colors.green : Colors.orange,
              ),
              title: Text(check.name),
              subtitle: Text(check.description),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
                  'Compatibility Check',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(height: 8),
                Text(
                  'Analyze horoscope compatibility based on Vedic Astrology including Ashtakoota, Mangal Dosha, and planetary factors.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildChartSelection(
                'Groom (Boy)',
                _selectedChart1,
                (chart) => setState(() => _selectedChart1 = chart),
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FluentTheme.of(
                  context,
                ).accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FluentIcons.heart_fill,
                color: FluentTheme.of(context).accentColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartSelection(
                'Bride (Girl)',
                _selectedChart2,
                (chart) => setState(() => _selectedChart2 = chart),
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (_selectedChart1 != null && _selectedChart2 != null)
          Center(
            child: FilledButton(
              onPressed: () => setState(() {}),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.heart),
                    SizedBox(width: 8),
                    Text('Check Compatibility', style: TextStyle(fontSize: 16)),
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
                  if (chart != null) onSelect(chart);
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: FilledButton(
                    onPressed: () async {
                      final result = await Navigator.push<BirthData>(
                        context,
                        FluentPageRoute(
                          builder: (context) =>
                              const InputScreen(onSelectionMode: true),
                        ),
                      );

                      if (result != null && context.mounted) {
                        try {
                          final completeData = await _kpChartService
                              .generateCompleteChart(result);
                          if (context.mounted) {
                            Navigator.pop(context, completeData);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            displayInfoBar(
                              context,
                              builder: (context, close) {
                                return InfoBar(
                                  title: const Text('Error'),
                                  content: const Text(
                                    'Failed to generate chart',
                                  ),
                                  severity: InfoBarSeverity.error,
                                  onClose: close,
                                );
                              },
                            );
                          }
                        }
                      }
                    },
                    child: const SizedBox(
                      width: double.infinity,
                      child: Center(child: Text('+ Create New Profile')),
                    ),
                  ),
                ),
                Expanded(
                  child: charts.isEmpty
                      ? const Center(child: Text('No saved charts found.'))
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
                                  return;
                                }
                                try {
                                  final birthData = BirthData(
                                    dateTime: DateTime.parse(
                                      chart['dateTime'] as String,
                                    ),
                                    location: Location(
                                      latitude: (chart['latitude'] as num)
                                          .toDouble(),
                                      longitude: (chart['longitude'] as num)
                                          .toDouble(),
                                    ),
                                    name: chart['name'] ?? '',
                                    place: chart['locationName'] ?? '',
                                  );
                                  // Instantiate service locally to be safe
                                  final service = KPChartService();
                                  final completeData = await service
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
              ],
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
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      Text(_selectedChart1!.birthData.name),
                      Expanded(child: _buildMiniChart(_selectedChart1!)),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'VS',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Card(
                  child: Column(
                    children: [
                      Text(_selectedChart2!.birthData.name),
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
    return ((chart.houses.cusps[0] / 30).floor() + 1);
  }

  Widget _buildSynastryTab(SynastryAnalysis compatibility) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: compatibility.aspects.length,
      itemBuilder: (context, index) {
        final aspect = compatibility.aspects[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: _getAspectIcon(aspect.effect),
            title: Text(aspect.description),
            subtitle: Text(
              '${aspect.effect.toString().split('.').last} (Orb: ${aspect.orb.toStringAsFixed(1)}°)',
            ),
            trailing: Text(
              _getAspectSymbol(aspect.aspectType),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHouseOverlaysTab(SynastryAnalysis compatibility) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Chart 1 Planets in Chart 2 Houses',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...compatibility.houseOverlays
            .where((o) => o.chart == 1)
            .map((o) => _buildOverlayItem(o)),
        const SizedBox(height: 24),
        const Text(
          'Chart 2 Planets in Chart 1 Houses',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...compatibility.houseOverlays
            .where((o) => o.chart == 2)
            .map((o) => _buildOverlayItem(o)),
      ],
    );
  }

  Widget _buildOverlayItem(HouseOverlay overlay) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          '${overlay.planet.toString().split('.').last} in ${overlay.house}th House',
        ),
        subtitle: Text('Impacts: ${overlay.significance}'),
      ),
    );
  }

  Widget _getAspectIcon(AspectEffect effect) {
    switch (effect) {
      case AspectEffect.veryPositive:
        return Icon(FluentIcons.favorite_star_fill, color: Colors.green);
      case AspectEffect.positive:
        return Icon(FluentIcons.check_mark, color: Colors.green);
      case AspectEffect.challenging:
        return Icon(FluentIcons.warning, color: Colors.orange);
      case AspectEffect.veryChallenging:
        return Icon(FluentIcons.error_badge, color: Colors.red);
      default:
        return Icon(FluentIcons.info);
    }
  }

  String _getAspectSymbol(AspectType type) {
    switch (type) {
      case AspectType.conjunction:
        return '☌';
      case AspectType.opposition:
        return '☍';
      case AspectType.trine:
        return '△';
      case AspectType.square:
        return '□';
      case AspectType.sextile:
        return '⚹';
    }
  }

  Future<void> _exportPdf() async {
    if (_selectedChart1 == null || _selectedChart2 == null) {
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        builder: (context) => const ContentDialog(
          title: Text('Exporting PDF'),
          content: Row(
            children: [
              ProgressRing(),
              SizedBox(width: 20),
              Text('Generating comprehensive report...'),
            ],
          ),
        ),
      );

      // Recalculate report for export
      final report = MatchingService.analyzeCompatibility(
        _selectedChart1!,
        _selectedChart2!,
      );

      // Generate PDF
      final file = await PDFReportService.generateMatchingReport(
        _selectedChart1!,
        _selectedChart2!,
        report,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Open/Share PDF
      await PDFReportService.printReport(file);
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);

      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Export Failed'),
              content: Text(e.toString()),
              severity: InfoBarSeverity.error,
              onClose: close,
            );
          },
        );
      }
    }
  }
}
