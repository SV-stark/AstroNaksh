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
import '../../core/responsive_helper.dart';

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
          title: const Text('Kundali Matching'),
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

    final synastry = ChartComparison.analyzeCompatibility(
      _selectedChart1!,
      _selectedChart2!,
    );

    return NavigationView(
      appBar: NavigationAppBar(
        title: Row(
          children: [
            Icon(
              FluentIcons.heart_fill,
              color: compatibilityReport.overallColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(compatibilityReport.overallConclusion),
          ],
        ),
        actions: CommandBar(
          overflowBehavior: CommandBarOverflowBehavior.noWrap,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add_friend),
              label: const Text('New Pair'),
              onPressed: () {
                setState(() {
                  _selectedChart2 = null;
                });
              },
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.switch_widget),
              label: const Text('Swap'),
              onPressed: _swapCharts,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.side_panel_mirrored),
              label: const Text('Charts'),
              onPressed: () => _showSideBySideView(),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.pdf),
              label: const Text('Export'),
              onPressed: _exportPdf,
            ),
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
        displayMode: context.topPaneDisplayMode,
        items: [
          PaneItem(
            icon: Icon(
              FluentIcons.heart_fill,
              color: compatibilityReport.overallColor,
            ),
            title: const Text('Overview'),
            body: _buildOverviewTab(compatibilityReport),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.view_dashboard),
            title: const Text('Ashtakoota'),
            body: _buildAshtakootaTab(compatibilityReport),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.shield_alert),
            title: const Text('Doshas'),
            body: _buildDoshaTab(compatibilityReport),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.starburst),
            title: const Text('Synastry'),
            body: _buildSynastryTab(synastry),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.home_group),
            title: const Text('Houses'),
            body: _buildHouseOverlaysTab(synastry),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(MatchingReport report) {
    return ScaffoldPage(
      content: SingleChildScrollView(
        padding: context.responsiveBodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Score Card
            Card(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Score Circle
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            report.overallColor.withValues(alpha: 0.3),
                            report.overallColor.withValues(alpha: 0.1),
                          ],
                        ),
                        border: Border.all(
                          color: report.overallColor,
                          width: 4,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              report.ashtakootaScore.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: report.overallColor,
                              ),
                            ),
                            Text(
                              '/ 36',
                              style: TextStyle(
                                fontSize: 20,
                                color: report.overallColor.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: report.overallColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        report.overallConclusion,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: report.overallColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Partner Info Cards
            context.isMobile
                ? Column(
                    children: [
                      _buildPartnerCard('Groom', _selectedChart1!, Colors.blue),
                      const SizedBox(height: 16),
                      _buildPartnerCard(
                        'Bride',
                        _selectedChart2!,
                        Colors.purple,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildPartnerCard(
                          'Groom',
                          _selectedChart1!,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPartnerCard(
                          'Bride',
                          _selectedChart2!,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
            // Key Highlights
            Text(
              'Compatibility Highlights',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildHighlightChip(
                  'Ashtakoota',
                  '${report.ashtakootaScore.toStringAsFixed(1)}/36',
                  report.ashtakootaScore >= 18 ? Colors.green : Colors.red,
                  FluentIcons.heart,
                ),
                _buildHighlightChip(
                  'Mangal Dosha',
                  report.manglikMatch.isMatch ? 'Compatible' : 'Check Required',
                  report.manglikMatch.isMatch ? Colors.green : Colors.orange,
                  FluentIcons.shield,
                ),
                if (report.extraChecks.isNotEmpty)
                  _buildHighlightChip(
                    'Mahendra',
                    report.extraChecks
                            .firstWhere((e) => e.name == 'Mahendra')
                            .isFavorable
                        ? 'Favorable'
                        : 'Neutral',
                    report.extraChecks
                            .firstWhere((e) => e.name == 'Mahendra')
                            .isFavorable
                        ? Colors.green
                        : Colors.orange,
                    FluentIcons.starburst,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(String label, CompleteChartData chart, Color color) {
    return Card(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.contact, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              chart.birthData.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${chart.birthData.dateTime.day}/${chart.birthData.dateTime.month}/${chart.birthData.dateTime.year}',
              style: FluentTheme.of(context).typography.caption,
            ),
            Text(
              chart.birthData.place,
              style: FluentTheme.of(context).typography.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightChip(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: FluentTheme.of(context).typography.caption),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAshtakootaTab(MatchingReport report) {
    return ScaffoldPage(
      content: SingleChildScrollView(
        padding: context.responsiveBodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ashtakoota Analysis',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Detailed breakdown of the 8 compatibility factors (Kootas)',
              style: FluentTheme.of(context).typography.caption,
            ),
            const SizedBox(height: 16),
            // Total Progress
            Card(
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Score',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${report.ashtakootaScore.toStringAsFixed(1)} / 36',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: report.overallColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 12,
                        child: ProgressBar(
                          value: report.ashtakootaScore / 36 * 100,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                          activeColor: report.overallColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Individual Kootas
            ...report.kootaResults.map((koota) => _buildKootaCard(koota)),
          ],
        ),
      ),
    );
  }

  Widget _buildKootaCard(KootaResult koota) {
    final percentage = koota.score / koota.maxScore;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: koota.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${koota.score.toInt()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: koota.color,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        koota.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        koota.description,
                        style: FluentTheme.of(context).typography.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: koota.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: koota.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${koota.score.toInt()}/${koota.maxScore.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: koota.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 6,
                child: ProgressBar(
                  value: percentage * 100,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  activeColor: koota.color,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(FluentIcons.info, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      koota.detailedReason,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoshaTab(MatchingReport report) {
    return ScaffoldPage(
      content: SingleChildScrollView(
        padding: context.responsiveBodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dosha Analysis',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Mangal Dosha and other compatibility checks',
              style: FluentTheme.of(context).typography.caption,
            ),
            const SizedBox(height: 16),
            // Mangal Dosha Card
            Card(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: report.manglikMatch.isMatch
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            report.manglikMatch.isMatch
                                ? FluentIcons.check_mark
                                : FluentIcons.warning,
                            color: report.manglikMatch.isMatch
                                ? Colors.green
                                : Colors.orange,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mangal Dosha Analysis',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                report.manglikMatch.description,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: report.manglikMatch.isMatch
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    context.isMobile
                        ? Column(
                            children: [
                              _buildDoshaStatusCard(
                                'Groom',
                                report.manglikMatch.maleManglik,
                                Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              _buildDoshaStatusCard(
                                'Bride',
                                report.manglikMatch.femaleManglik,
                                Colors.purple,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildDoshaStatusCard(
                                  'Groom',
                                  report.manglikMatch.maleManglik,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDoshaStatusCard(
                                  'Bride',
                                  report.manglikMatch.femaleManglik,
                                  Colors.purple,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Additional Checks
            Text(
              'Additional Checks',
              style: FluentTheme.of(context).typography.bodyLarge,
            ),
            const SizedBox(height: 12),
            ...report.extraChecks.map((check) => _buildExtraCheckCard(check)),
          ],
        ),
      ),
    );
  }

  Widget _buildDoshaStatusCard(String label, bool isManglik, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isManglik
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isManglik
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            isManglik ? FluentIcons.warning : FluentIcons.check_mark,
            color: isManglik ? Colors.orange : Colors.green,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            isManglik ? 'Manglik' : 'Non-Manglik',
            style: TextStyle(
              color: isManglik ? Colors.orange : Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraCheckCard(ExtraMatchingCheck check) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: BorderRadius.circular(10),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: check.isFavorable
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            check.isFavorable ? FluentIcons.check_mark : FluentIcons.info,
            color: check.isFavorable ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          check.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(check.description),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: check.isFavorable
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            check.isFavorable ? 'Good' : 'Caution',
            style: TextStyle(
              color: check.isFavorable ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartSelector() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FluentTheme.of(context).accentColor.withValues(alpha: 0.15),
                    FluentTheme.of(context).accentColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FluentTheme.of(
                            context,
                          ).accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          FluentIcons.heart_fill,
                          color: FluentTheme.of(context).accentColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kundali Matching',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Analyze horoscope compatibility using Vedic Astrology principles',
                              style: FluentTheme.of(context).typography.body,
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
          const SizedBox(height: 32),
          // Chart Selection
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: context.isMobile
                  ? Column(
                      children: [
                        _buildChartSelection(
                          'Groom',
                          _selectedChart1,
                          (chart) => setState(() => _selectedChart1 = chart),
                          Colors.blue,
                          FluentIcons.user_followed,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withValues(alpha: 0.2),
                                  Colors.purple.withValues(alpha: 0.2),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: FluentTheme.of(
                                  context,
                                ).accentColor.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                FluentIcons.heart_fill,
                                color: FluentTheme.of(context).accentColor,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        _buildChartSelection(
                          'Bride',
                          _selectedChart2,
                          (chart) => setState(() => _selectedChart2 = chart),
                          Colors.purple,
                          FluentIcons.user_followed,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildChartSelection(
                            'Groom',
                            _selectedChart1,
                            (chart) => setState(() => _selectedChart1 = chart),
                            Colors.blue,
                            FluentIcons.user_followed,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withValues(alpha: 0.2),
                                  Colors.purple.withValues(alpha: 0.2),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: FluentTheme.of(
                                  context,
                                ).accentColor.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                FluentIcons.heart_fill,
                                color: FluentTheme.of(context).accentColor,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildChartSelection(
                            'Bride',
                            _selectedChart2,
                            (chart) => setState(() => _selectedChart2 = chart),
                            Colors.purple,
                            FluentIcons.user_followed,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 40),
          // Action Button
          if (_selectedChart1 != null && _selectedChart2 != null)
            Center(
              child: FilledButton(
                onPressed: () => setState(() {}),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.heart_fill, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'Analyze Compatibility',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartSelection(
    String label,
    CompleteChartData? selected,
    Function(CompleteChartData?) onSelect,
    Color accentColor,
    IconData icon,
  ) {
    return Card(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: accentColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (selected != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.birthData.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${selected.birthData.dateTime.day}/${selected.birthData.dateTime.month}/${selected.birthData.dateTime.year}',
                                style: FluentTheme.of(
                                  context,
                                ).typography.caption,
                              ),
                              Text(
                                selected.birthData.place,
                                style: FluentTheme.of(
                                  context,
                                ).typography.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            FluentIcons.delete,
                            color: Colors.red.withValues(alpha: 0.7),
                          ),
                          onPressed: () => onSelect(null),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final chart = await _showChartPicker();
                    if (chart != null) onSelect(chart);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FluentIcons.add, size: 18),
                        const SizedBox(width: 8),
                        Text('Select Chart'),
                      ],
                    ),
                  ),
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
          constraints: const BoxConstraints(maxWidth: 400),
          content: SizedBox(
            width: 350,
            height: 500,
            child: Column(
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FluentTheme.of(
                          context,
                        ).accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        FluentIcons.add,
                        color: FluentTheme.of(context).accentColor,
                      ),
                    ),
                    title: const Text('Create New Profile'),
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
                  ),
                ),
                Expanded(
                  child: charts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FluentIcons.chart,
                                size: 48,
                                color: Colors.grey.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No saved charts found',
                                style: FluentTheme.of(context).typography.body,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: charts.length,
                          itemBuilder: (context, index) {
                            final chart = charts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile.selectable(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: FluentTheme.of(
                                      context,
                                    ).accentColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    FluentIcons.contact,
                                    color: FluentTheme.of(context).accentColor,
                                  ),
                                ),
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
                              ),
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
        title: const Text('Charts Comparison'),
        constraints: const BoxConstraints(maxWidth: 1000),
        content: SizedBox(
          height: 520,
          child: context.isMobile
              ? SingleChildScrollView(
                  child: Column(
                    children: [
                      Card(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(FluentIcons.contact, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedChart1!.birthData.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 300,
                              child: _buildMiniChart(_selectedChart1!),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: FluentTheme.of(
                              context,
                            ).accentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: FluentTheme.of(context).accentColor,
                            ),
                          ),
                        ),
                      ),
                      Card(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    FluentIcons.contact,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedChart2!.birthData.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 300,
                              child: _buildMiniChart(_selectedChart2!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: Card(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(FluentIcons.contact, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedChart1!.birthData.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(child: _buildMiniChart(_selectedChart1!)),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: FluentTheme.of(
                            context,
                          ).accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: FluentTheme.of(context).accentColor,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    FluentIcons.contact,
                                    color: Colors.purple,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedChart2!.birthData.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ],
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
    return ((chart.houses.cusps[0] / 30).floor() + 1);
  }

  Widget _buildSynastryTab(SynastryAnalysis compatibility) {
    return ScaffoldPage(
      content: SingleChildScrollView(
        padding: context.responsiveBodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planetary Synastry',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Planetary aspects between the two charts',
              style: FluentTheme.of(context).typography.caption,
            ),
            const SizedBox(height: 16),
            ...compatibility.aspects.map((aspect) => _buildAspectCard(aspect)),
          ],
        ),
      ),
    );
  }

  Widget _buildAspectCard(SynastryAspect aspect) {
    Color effectColor;
    IconData effectIcon;

    switch (aspect.effect) {
      case AspectEffect.veryPositive:
        effectColor = Colors.green;
        effectIcon = FluentIcons.favorite_star_fill;
        break;
      case AspectEffect.positive:
        effectColor = Colors.green;
        effectIcon = FluentIcons.check_mark;
        break;
      case AspectEffect.challenging:
        effectColor = Colors.orange;
        effectIcon = FluentIcons.warning;
        break;
      case AspectEffect.veryChallenging:
        effectColor = Colors.red;
        effectIcon = FluentIcons.error_badge;
        break;
      default:
        effectColor = Colors.grey;
        effectIcon = FluentIcons.info;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: effectColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(effectIcon, color: effectColor),
        ),
        title: Text(
          aspect.description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${aspect.effect.toString().split('.').last} • Orb: ${aspect.orb.toStringAsFixed(1)}°',
          style: FluentTheme.of(context).typography.caption,
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getAspectSymbol(aspect.aspectType),
            style: TextStyle(
              fontSize: 20,
              color: effectColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHouseOverlaysTab(SynastryAnalysis compatibility) {
    return ScaffoldPage(
      content: SingleChildScrollView(
        padding: context.responsiveBodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'House Overlays',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            Text(
              'How planets from one chart activate houses in the other',
              style: FluentTheme.of(context).typography.caption,
            ),
            const SizedBox(height: 16),
            // Chart 1 in Chart 2
            Card(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.blue, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(FluentIcons.contact, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedChart1!.birthData.name}\'s Planets',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          ' in ',
                          style: FluentTheme.of(context).typography.body,
                        ),
                        Text(
                          '${_selectedChart2!.birthData.name}\'s Houses',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...compatibility.houseOverlays
                .where((o) => o.chart == 1)
                .map((o) => _buildOverlayItem(o)),
            const SizedBox(height: 24),
            // Chart 2 in Chart 1
            Card(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.purple, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(FluentIcons.contact, color: Colors.purple),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedChart2!.birthData.name}\'s Planets',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        Text(
                          ' in ',
                          style: FluentTheme.of(context).typography.body,
                        ),
                        Text(
                          '${_selectedChart1!.birthData.name}\'s Houses',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...compatibility.houseOverlays
                .where((o) => o.chart == 2)
                .map((o) => _buildOverlayItem(o)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayItem(HouseOverlay overlay) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: BorderRadius.circular(10),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${overlay.house}H',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: FluentTheme.of(context).accentColor,
              ),
            ),
          ),
        ),
        title: Text(
          '${overlay.planet.toString().split('.').last} in House ${overlay.house}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          overlay.significance,
          style: FluentTheme.of(context).typography.caption,
        ),
      ),
    );
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
      showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Exporting PDF'),
          content: Row(
            children: [
              const ProgressRing(),
              const SizedBox(width: 20),
              Text('Generating report...'),
            ],
          ),
        ),
      );

      final report = MatchingService.analyzeCompatibility(
        _selectedChart1!,
        _selectedChart2!,
      );

      final file = await PDFReportService.generateMatchingReport(
        _selectedChart1!,
        _selectedChart2!,
        report,
      );

      if (mounted) Navigator.pop(context);

      await PDFReportService.printReport(file);
    } catch (e) {
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
