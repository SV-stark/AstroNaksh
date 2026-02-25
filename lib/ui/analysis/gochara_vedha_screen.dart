import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../logic/transit_analysis.dart';
import 'package:jyotish/jyotish.dart';
import 'package:intl/intl.dart';

class GocharaVedhaScreen extends StatefulWidget {
  final CompleteChartData chartData;

  const GocharaVedhaScreen({super.key, required this.chartData});

  @override
  State<GocharaVedhaScreen> createState() => _GocharaVedhaScreenState();
}

class _GocharaVedhaScreenState extends State<GocharaVedhaScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  TransitChart? _transitChart;
  VedhaAnalysis? _vedhaAnalysis;
  final _transitAnalysis = TransitAnalysis();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final chart = await _transitAnalysis.calculateTransitChart(
        widget.chartData,
        _selectedDate,
      );
      final moonNakshatra =
          widget
              .chartData
              .baseChart
              .planets[Planet.moon]
              ?.position
              .nakshatraIndex ??
          0;
      final vedha = _transitAnalysis.analyzeVedha(
        moonNakshatra: moonNakshatra + 1,
        gocharaPositions: chart.gochara.positions,
      );
      if (mounted) {
        setState(() {
          _transitChart = chart;
          _vedhaAnalysis = vedha;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Error'),
            content: Text(e.toString()),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gochara Vedha'),
      ),
      content: ScaffoldPage(
        header: PageHeader(
          title: _buildDateHeader(),
          commandBar: CommandBar(
            primaryItems: [
              CommandBarButton(
                icon: const Icon(FluentIcons.refresh),
                label: const Text('Refresh'),
                onPressed: _loadData,
              ),
            ],
          ),
        ),
        content: _isLoading
            ? const Center(child: ProgressRing())
            : _transitChart == null
            ? const Center(child: Text('Failed to load data'))
            : _buildContent(),
      ),
    );
  }

  Widget _buildDateHeader() {
    return Row(
      children: [
        const Text(
          'Date: ',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        DatePicker(
          selected: _selectedDate,
          onChanged: (date) {
            setState(() => _selectedDate = date);
            _loadData();
          },
        ),
      ],
    );
  }

  Widget _buildContent() {
    final chart = _transitChart!;
    final vedha = _vedhaAnalysis!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Intro card
        const InfoBar(
          title: Text('Gochara Vedha — Transit Obstruction Analysis'),
          content: Text(
            'Vedha occurs when a planet in a favorable Gochara position '
            'is obstructed by its designated Vedha planet. '
            'Sun ↔ Saturn, Moon ↔ Mercury, Mars ↔ Venus. Jupiter has no Vedha.',
          ),
          severity: InfoBarSeverity.info,
        ),
        const SizedBox(height: 16),

        // Summary card
        _buildSummaryCard(vedha),
        const SizedBox(height: 16),

        // Planet-by-planet
        Text(
          'Transit Details',
          style: FluentTheme.of(
            context,
          ).typography.subtitle?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...vedha.results.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildPlanetRow(context, r, chart),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(VedhaAnalysis vedha) {
    final total = vedha.results.length;
    final favorable = vedha.results.where((r) => r.isFavorablePosition).length;
    final obstructed = vedha.results.where((r) => r.isObstructed).length;
    final clear = vedha.results.where((r) => r.isFullyFavorable).length;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.analytics_view,
                color: FluentTheme.of(context).accentColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Summary for ${DateFormat('d MMM yyyy').format(_selectedDate)}',
                style: FluentTheme.of(
                  context,
                ).typography.body?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryChip('Favorable', favorable, Colors.blue),
              const SizedBox(width: 8),
              _summaryChip('Clear (No Vedha)', clear, Colors.green),
              const SizedBox(width: 8),
              _summaryChip('Obstructed', obstructed, Colors.orange),
              const SizedBox(width: 8),
              _summaryChip('Unfavorable', total - favorable, Colors.grey),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            vedha.summary,
            style: TextStyle(color: Colors.grey[130], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[130])),
      ],
    );
  }

  Widget _buildPlanetRow(
    BuildContext context,
    VedhaResult result,
    TransitChart chart,
  ) {
    final house = result.houseFromMoon;
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!result.isFavorablePosition) {
      statusColor = Colors.grey;
      statusIcon = FluentIcons.blocked;
      statusText = 'Unfavorable (H$house)';
    } else if (result.isObstructed) {
      statusColor = Colors.orange;
      statusIcon = FluentIcons.warning;
      statusText = 'Obstructed (H$house)';
    } else {
      statusColor = Colors.green;
      statusIcon = FluentIcons.completed;
      statusText = 'Favorable (H$house)';
    }

    final effectiveness = (result.resultEffectiveness * 100).toStringAsFixed(0);

    return Expander(
      header: Row(
        children: [
          // Planet icon/name
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withAlpha(60)),
            ),
            child: Center(
              child: Icon(statusIcon, color: statusColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.transitPlanet.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 12, color: statusColor),
                ),
              ],
            ),
          ),
          // Effectiveness pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withAlpha(80)),
            ),
            child: Text(
              '$effectiveness%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interpretation
          Text(result.interpretation, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 10),

          // Vedha strength bar
          if (result.isObstructed) ...[
            Row(
              children: [
                const Text(
                  'Vedha Strength: ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  result.severity.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Container(
                        width: constraints.maxWidth,
                        color: Colors.grey.withAlpha(30),
                      ),
                      Container(
                        width:
                            constraints.maxWidth *
                            result.vedhaStrength.clamp(0.0, 1.0),
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Obstruction details
            if (result.obstructionDetails.isNotEmpty) ...[
              const Text(
                'Obstruction by:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              ...result.obstructionDetails.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: Row(
                    children: [
                      const Icon(FluentIcons.chevron_right_small, size: 12),
                      const SizedBox(width: 4),
                      Text(d, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],

          // Favorable houses reference
          _buildFavorableHousesRef(result.transitPlanet),
        ],
      ),
    );
  }

  Widget _buildFavorableHousesRef(Planet planet) {
    const favorableMap = {
      Planet.sun: [3, 6, 10, 11],
      Planet.moon: [1, 3, 6, 7, 10, 11],
      Planet.mars: [3, 6, 11],
      Planet.mercury: [2, 4, 6, 8, 10, 11],
      Planet.jupiter: [2, 5, 7, 9, 11],
      Planet.venus: [1, 2, 3, 4, 5, 8, 9, 11, 12],
      Planet.saturn: [3, 6, 11],
    };
    final houses = favorableMap[planet];
    if (houses == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        Text(
          'Favorable houses: ',
          style: TextStyle(fontSize: 11, color: Colors.grey[130]),
        ),
        ...houses.map(
          (h) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'H$h',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
