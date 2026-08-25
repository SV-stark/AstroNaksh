// ignore_for_file: avoid_slow_async_io, unawaited_futures, deprecated_member_use, sort_constructors_first, implementation_imports
import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' as m;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jyotish/core.dart';

import '../../core/ayanamsa_calculator.dart';
import '../../core/chart_customization.dart';
import '../../core/chart_share_service.dart';
import '../../core/database.dart';
import '../../core/saved_charts_helper.dart';
import '../../core/settings_provider.dart';
import '../../core/settings_state.dart';
import '../../data/models.dart';
import '../../logic/kp_chart_service.dart';
import 'analysis/ayurvedic_recommendations_screen.dart';
import 'analysis/gochara_vedha_screen.dart';
import 'analysis/graha_yuddha_screen.dart';
import 'analysis/jaimini_screen.dart';
import 'analysis/nadi_screen.dart';
import 'analysis/planetary_maitri_screen.dart';
import 'analysis/progeny_screen.dart';
import 'analysis/remedies_screen.dart';
import 'analysis/retrograde_screen.dart';
import 'analysis/sudarshan_chakra_screen.dart';
import 'analysis/yoga_dosha_screen.dart';
import 'birth_details_screen.dart';
import 'chart/tabs/d1_tab.dart';
import 'chart/tabs/dasha_tab.dart';
import 'chart/tabs/details_tab.dart';
import 'chart/tabs/kp_tab.dart';
import 'chart/tabs/strength_tab.dart';
import 'chart/tabs/vargas_tab.dart';
import 'comparison/chart_comparison_screen.dart';
import 'predictions/life_predictions_screen.dart';
import 'predictions/rashiphal_dashboard.dart';
import 'predictions/transit_screen.dart';
import 'predictions/varshaphal_screen.dart';
import 'reports/pdf_report_screen.dart';
import 'strength/ashtakavarga_screen.dart';
import 'strength/bhava_bala_screen.dart';
import 'strength/shadbala_screen.dart';
import 'tools/ayanamsa_sandbox_screen.dart';
import 'tools/birth_time_rectifier_screen.dart';
import 'utils/responsive_helper.dart';

class ChartScreen extends ConsumerStatefulWidget {
  const ChartScreen({super.key, this.birthData});
  final BirthData? birthData;

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen> {
  final KPChartService _kpChartService = KPChartService();
  Future<CompleteChartData?>? _chartDataFuture;
  ChartStyle _style = ChartStyle.northIndian;
  String _selectedDivisionalChart = 'D-9';
  BirthData? _birthData;
  int _currentIndex = 0;
  int _dashaTabIndex = 0; // 0 = Vimshottari, 1 = Yogini, 2 = Chara
  bool _showAspects = false; // Toggle for planetary aspects (drishti)
  final GlobalKey<m.ScaffoldState> _scaffoldKey = GlobalKey<m.ScaffoldState>();
  final GlobalKey _d1ChartKey = GlobalKey();

  // Timeline state variables
  DateTime _timelineCurrentDate = DateTime.now();
  bool _isTimelinePlaying = false;
  double _timelineSpeed = 1.0;
  Timer? _timelineTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_birthData == null) {
      if (widget.birthData != null) {
        _birthData = widget.birthData;
        _loadChartData();
      } else {
        // Try to get from GoRouter extra first
        try {
          final extra = GoRouterState.of(context).extra;
          if (extra is BirthData) {
            _birthData = extra;
            _loadChartData();
            return;
          }
        } catch (_) {}

        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is BirthData) {
          _birthData = args;
          _loadChartData();
        } else {
          // Handle missing arguments
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              displayInfoBar(
                context,
                builder: (context, close) => const InfoBar(
                  title: Text('Error'),
                  content: Text('No birth data provided'),
                  severity: InfoBarSeverity.error,
                ),
              );
              if (context.canPop()) {
                context.pop();
              } else {
                Navigator.pop(context);
              }
            }
          });
        }
      }
    }
  }

  void _loadChartData() {
    if (_birthData != null) {
      final settingsState =
          ref.read(settingsProvider).value ??
          SettingsState(chartSettings: ChartCustomization());
      final chartSettings = settingsState.chartSettings;
      final vargaConfig = VargaConfiguration(
        horaMethod: chartSettings.horaMethod,
        drekkanaMethod: chartSettings.drekkanaMethod,
        navamshaMethod: chartSettings.navamshaMethod,
        dashamshaMethod: chartSettings.dashamshaMethod,
      );
      setState(() {
        _chartDataFuture = _kpChartService.generateCompleteChart(
          _birthData!,
          vargaConfig: vargaConfig,
        );
      });
    }
  }

  void _openAyanamsaSelection() {
    final settingsState =
        ref.read(settingsProvider).value ??
        SettingsState(chartSettings: ChartCustomization());
    final chartSettings = settingsState.chartSettings;

    showDialog(
      context: context,
      builder: (context) {
        var searchQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final allSystems = AyanamsaCalculator.systems;
            final filteredSystems = searchQuery.isEmpty
                ? allSystems
                : allSystems
                      .where(
                        (s) =>
                            s.name.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ||
                            s.id.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ||
                            s.description.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ),
                      )
                      .toList();

            return ContentDialog(
              title: const Text('Select Ayanamsa'),
              content: SizedBox(
                height: 400,
                child: Column(
                  children: [
                    TextBox(
                      placeholder: 'Search Ayanamsa...',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(FluentIcons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: RadioGroup<String>(
                        groupValue: chartSettings.ayanamsaSystem,
                        onChanged: (v) {
                          if (v != null) {
                            ref
                                .read(settingsProvider.notifier)
                                .updateChartSettings(
                                  chartSettings.copyWith(ayanamsaSystem: v),
                                );
                            Navigator.pop(context);
                            _loadChartData();
                          }
                        },
                        child: ListView.builder(
                          itemCount: filteredSystems.length,
                          itemBuilder: (context, index) {
                            final system = filteredSystems[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: RadioButton<String>(
                                value: system.id,
                                content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      system.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (system.description != system.name)
                                      Text(
                                        system.description,
                                        style: FluentTheme.of(
                                          context,
                                        ).typography.caption,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Button(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBirthDetails() async {
    final data = await _chartDataFuture;
    if (data == null || !mounted) return;

    Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => BirthDetailsScreen(chartData: data),
      ),
    );
  }

  void _saveCurrentChart() async {
    if (_birthData == null) return;

    // Save to both SharedPreferences and Database for compatibility
    await SavedChartsHelper.saveChart(_birthData!);

    final db = ref.read(databaseProvider);
    final birthIso = _birthData!.dateTime.toIso8601String();
    final existing = await (db.select(db.charts)
          ..where(
            (tbl) =>
                tbl.name.equals(_birthData!.name) &
                tbl.birthTime.equals(birthIso),
          ))
        .getSingleOrNull();

    if (existing == null) {
      await db.into(db.charts).insert(
            ChartsCompanion.insert(
              name: drift.Value(_birthData!.name),
              birthTime: drift.Value(birthIso),
              latitude: drift.Value(_birthData!.location.latitude),
              longitude: drift.Value(_birthData!.location.longitude),
              locationName: drift.Value(_birthData!.place),
              timezone: drift.Value(
                _birthData!.timezone.isEmpty ? 'UTC' : _birthData!.timezone,
              ),
            ),
          );
    } else {
      await (db.update(db.charts)..where((tbl) => tbl.id.equals(existing.id)))
          .write(
            ChartsCompanion(
              latitude: drift.Value(_birthData!.location.latitude),
              longitude: drift.Value(_birthData!.location.longitude),
              locationName: drift.Value(_birthData!.place),
              timezone: drift.Value(
                _birthData!.timezone.isEmpty ? 'UTC' : _birthData!.timezone,
              ),
            ),
          );
    }

    if (!mounted) return;
    displayInfoBar(
      context,
      builder: (context, close) {
        return InfoBar(
          title: const Text('Saved'),
          content: const Text('Chart details saved successfully.'),
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
          severity: InfoBarSeverity.success,
        );
      },
    );
  }

  // Timeline methods
  void _onTimelineDateChanged(DateTime date) {
    setState(() {
      _timelineCurrentDate = date;
    });
  }

  void _onTimelinePlay() {
    setState(() {
      _isTimelinePlaying = true;
    });
    _timelineTimer = Timer.periodic(
      Duration(milliseconds: (100 / _timelineSpeed).round()),
      (timer) {
        setState(() {
          _timelineCurrentDate = _timelineCurrentDate.add(
            const Duration(days: 1),
          );
          if (_timelineCurrentDate.isAfter(
            DateTime.now().add(const Duration(days: 365)),
          )) {
            _timelineCurrentDate = DateTime.now().add(
              const Duration(days: 365),
            );
            _onTimelinePause();
          }
        });
      },
    );
  }

  void _onTimelinePause() {
    setState(() {
      _isTimelinePlaying = false;
    });
    _timelineTimer?.cancel();
    _timelineTimer = null;
  }

  void _onTimelineSpeedChanged(double speed) {
    setState(() {
      _timelineSpeed = speed;
      if (_isTimelinePlaying) {
        _onTimelinePause();
        _onTimelinePlay();
      }
    });
  }

  @override
  void dispose() {
    _timelineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);

    final content = NavigationView(
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
        displayMode: ResponsiveHelper.getNavigationPaneDisplayMode(context),
        size: NavigationPaneSize(
          openWidth: context.paneWidth,
          compactWidth: context.compactPaneWidth,
        ),
        header: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Text(
            'AstroNaksh',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        items: [
          PaneItemHeader(header: const Text('Main Charts')),
          PaneItem(
            icon: const Icon(FluentIcons.contact_card),
            title: const Text('D-1 Rashi'),
            body: _buildBody(
              (data) => D1Tab(
                data: data,
                style: _style,
                showAspects: _showAspects,
                timelineCurrentDate: _timelineCurrentDate,
                isTimelinePlaying: _isTimelinePlaying,
                timelineSpeed: _timelineSpeed,
                d1ChartKey: _d1ChartKey,
                onTimelineDateChanged: _onTimelineDateChanged,
                onTimelinePlay: _onTimelinePlay,
                onTimelinePause: _onTimelinePause,
                onTimelineSpeedChanged: _onTimelineSpeedChanged,
              ),
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.grid_view_large),
            title: const Text('Vargas'),
            body: _buildBody(
              (data) => VargasTab(
                data: data,
                selectedDivisionalChart: _selectedDivisionalChart,
                style: _style,
                onDivisionalChartChanged: (code) =>
                    setState(() => _selectedDivisionalChart = code),
              ),
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.scatter_chart),
            title: const Text('KP System'),
            body: _buildBody((data) => KPTab(data: data)),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.timer),
            title: const Text('Dasha Periods'),
            body: _buildBody(
              (data) => DashaTab(
                data: data,
                dashaTabIndex: _dashaTabIndex,
                onDashaTabChanged: (idx) =>
                    setState(() => _dashaTabIndex = idx),
              ),
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.list),
            title: const Text('Planet Details'),
            body: _buildBody((data) => DetailsTab(data: data)),
          ),
          PaneItemHeader(header: const Text('Analysis')),
          PaneItem(
            icon: const Icon(FluentIcons.heart),
            title: const Text('Life Predictions'),
            body: _buildBody((data) => LifePredictionsScreen(chartData: data)),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.lightbulb),
            title: const Text('Daily Rashiphal'),
            body: _buildBody(
              (data) => RashiphalDashboardScreen(chartData: data),
            ),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.flower),
            title: const Text('Ayurveda'),
            body: _buildBody(
              (data) => AyurvedicRecommendationsScreen(chartData: data),
            ),
          ),
          PaneItemSeparator(),
          PaneItem(
            icon: const Icon(FluentIcons.scale_volume),
            title: const Text('Planetary Strength'),
            body: _buildBody((data) => StrengthTab(data: data)),
          ),
        ],
      ),
    );

    if (isMobile) {
      return m.Scaffold(
        key: _scaffoldKey,
        drawer: _buildMobileDrawer(),
        body: content,
      );
    }

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
      },
      child: content,
    );
  }

  Widget _buildMobileDrawer() {
    return m.Drawer(
      child: Container(
        color: FluentTheme.of(context).scaffoldBackgroundColor,
        child: m.ListView(
          padding: m.EdgeInsets.zero,
          children: [
            m.DrawerHeader(
              decoration: m.BoxDecoration(
                color: FluentTheme.of(
                  context,
                ).accentColor.withValues(alpha: 0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: m.MainAxisAlignment.end,
                children: [
                  Icon(
                    FluentIcons.contact_card,
                    size: 40,
                    color: FluentTheme.of(context).accentColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AstroNaksh',
                    style: FluentTheme.of(context).typography.title,
                  ),
                ],
              ),
            ),
            _buildDrawerHeader('Main Charts'),
            _buildDrawerItem(0, 'D-1 Rashi', FluentIcons.contact_card),
            _buildDrawerItem(1, 'Vargas', FluentIcons.grid_view_large),
            _buildDrawerItem(2, 'KP System', FluentIcons.scatter_chart),
            _buildDrawerItem(3, 'Dasha Periods', FluentIcons.timer),
            _buildDrawerItem(4, 'Planet Details', FluentIcons.list),
            _buildDrawerHeader('Analysis'),
            _buildDrawerItem(5, 'Life Predictions', FluentIcons.heart),
            _buildDrawerItem(6, 'Daily Rashiphal', FluentIcons.lightbulb),
            const m.Divider(),
            _buildDrawerItem(7, 'Planetary Strength', FluentIcons.scale_volume),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(String title) {
    return Padding(
      padding: const m.EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: FluentTheme.of(context).typography.caption?.copyWith(
          color: FluentTheme.of(context).accentColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;
    return m.ListTile(
      leading: Icon(
        icon,
        color: isSelected ? FluentTheme.of(context).accentColor : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? FluentTheme.of(context).accentColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        setState(() => _currentIndex = index);
        Navigator.pop(context); // Close drawer
      },
    );
  }

  Widget _buildMobileAnalysisLink(String title, String navKey, IconData icon) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SizedBox(
        height: isMobile ? 56 : 44,
        child: Button(
          onPressed: () {
            Navigator.pop(context);
            _navigateTo(navKey);
          },
          child: Row(
            children: [
              Icon(icon, size: isMobile ? 24 : 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: isMobile ? 16 : 14),
                ),
              ),
              Icon(FluentIcons.chevron_right, size: isMobile ? 20 : 12),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(String value) async {
    if (_chartDataFuture == null) return;
    // Wait for data? We can pass future or wait.
    // Usually users click after data loads.
    // For simplicity, we assume loaded or handle inside screen.
    // Most screens take 'chartData'.
    final chartData = await _chartDataFuture;
    if (chartData == null || !mounted) return;

    Widget screen;
    switch (value) {
      case 'ashtakavarga':
        screen = AshtakavargaScreen(chartData: chartData);
        break;
      case 'shadbala':
        screen = ShadbalaScreen(chartData: chartData);
        break;
      case 'bhava_bala':
        screen = BhavaBalaScreen(chartData: chartData);
        break;
      case 'yoga_dosha':
        screen = YogaDoshaScreen(chartData: chartData);
        break;
      case 'planetary_maitri':
        screen = PlanetaryMaitriScreen(chartData: chartData);
        break;
      case 'transit':
        screen = TransitScreen(natalChart: chartData);
        break;
      case 'varshaphal':
        screen = VarshaphalScreen(birthData: _birthData!);
        break;
      case 'retrograde':
        screen = RetrogradeScreen(chartData: chartData);
        break;
      case 'sudarshan_chakra':
        screen = SudarshanChakraScreen(chartData: chartData);
        break;
      case 'comparison':
        screen = ChartComparisonScreen(chart1: chartData);
        break;
      case 'ayanamsa_sandbox':
        screen = AyanamsaSandboxScreen(birthData: _birthData);
        break;
      case 'jaimini':
        screen = JaiminiScreen(chartData: chartData);
        break;
      case 'progeny':
        screen = ProgenyScreen(chartData: chartData);
        break;
      case 'nadi':
        screen = NadiScreen(chartData: chartData);
        break;
      case 'gochara_vedha':
        screen = GocharaVedhaScreen(chartData: chartData);
        break;
      case 'graha_yuddha':
        screen = GrahaYuddhaScreen(chartData: chartData);
        break;
      case 'pdf_report':
        screen = PDFReportScreen(chartData: chartData);
        break;
      case 'remedies':
        screen = RemediesScreen(chart: chartData.baseChart);
        break;

      default:

        return;
    }

    Navigator.push(context, FluentPageRoute(builder: (context) => screen));
  }

  Widget _buildBody(Widget Function(CompleteChartData) builder) {
    return FutureBuilder<CompleteChartData?>(
      future: _chartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ProgressRing());
        } else if (snapshot.hasError) {
          return ScaffoldPage(
            header: PageHeader(
              title: const Text('Error'),
              leading: IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            content: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(FluentIcons.error, size: 48, color: m.Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: FluentTheme.of(context).typography.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Button(
                        onPressed: _loadChartData,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(FluentIcons.refresh, size: 16),
                            SizedBox(width: 8),
                            Text('Retry'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Button(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No Data'));
        }

        return ScaffoldPage(
          header: PageHeader(
            title: const Flexible(
              child: Text('Vedic Chart', overflow: TextOverflow.ellipsis),
            ),
            leading: ResponsiveHelper.useMobileLayout(context)
                ? IconButton(
                    icon: const Icon(FluentIcons.global_nav_button),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  )
                : IconButton(
                    icon: const Icon(
                      FluentIcons.back,
                      semanticLabel: 'Go back',
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
            commandBar: CommandBar(
              overflowBehavior: CommandBarOverflowBehavior.dynamicOverflow,
              mainAxisAlignment: MainAxisAlignment.end,
              primaryItems: [
                // --- View & Calculation Options (Left/Start) ---
                if (!ResponsiveHelper.useMobileLayout(context)) ...[
                  CommandBarButton(
                    icon: Icon(
                      _style == ChartStyle.northIndian
                          ? FluentIcons.grid_view_small
                          : FluentIcons.diamond,
                      semanticLabel: 'Toggle chart style',
                    ),
                    label: const Text('Style'),
                    tooltip: _style == ChartStyle.northIndian
                        ? 'Currently North Indian style. Tap to switch to South Indian.'
                        : 'Currently South Indian style. Tap to switch to North Indian.',
                    onPressed: () {
                      setState(() {
                        _style = _style == ChartStyle.northIndian
                            ? ChartStyle.southIndian
                            : ChartStyle.northIndian;
                      });
                    },
                  ),
                  CommandBarButton(
                    icon: Icon(
                      _showAspects ? FluentIcons.view : FluentIcons.hide,
                      semanticLabel: _showAspects
                          ? 'Hide planetary aspects'
                          : 'Show planetary aspects',
                    ),
                    label: Text(_showAspects ? 'Aspects On' : 'Aspects Off'),
                    tooltip: _showAspects
                        ? 'Planetary aspects are visible. Tap to hide.'
                        : 'Tap to show planetary aspects (drishti).',
                    onPressed: () {
                      setState(() {
                        _showAspects = !_showAspects;
                      });
                    },
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.globe),
                    label: const Text('Ayanamsa'),
                    onPressed: _openAyanamsaSelection,
                  ),
                ],

                // --- Analysis & Tools ---
                if (!ResponsiveHelper.useMobileLayout(context))
                  CommandBarBuilderItem(
                    builder: (context, mode, w) {
                      return DropDownButton(
                        title: const Text('Analysis'),
                        leading: const Icon(FluentIcons.analytics_view),
                        items: [
                          MenuFlyoutSubItem(
                            text: const Text('Strength'),
                            leading: const Icon(FluentIcons.favorite_star),
                            items: (context) => [
                              MenuFlyoutItem(
                                text: const Text('Shadbala'),
                                leading: const Icon(FluentIcons.favorite_star),
                                onPressed: () => _navigateTo('shadbala'),
                              ),
                              MenuFlyoutItem(
                                text: const Text('Ashtakavarga'),
                                leading: const Icon(
                                  FluentIcons.grid_view_small,
                                ),
                                onPressed: () => _navigateTo('ashtakavarga'),
                              ),
                              MenuFlyoutItem(
                                text: const Text('Bhava Bala'),
                                leading: const Icon(FluentIcons.home),
                                onPressed: () => _navigateTo('bhava_bala'),
                              ),
                            ],
                          ),
                          MenuFlyoutSubItem(
                            text: const Text('Predictions'),
                            leading: const Icon(FluentIcons.calendar),
                            items: (context) => [
                              MenuFlyoutItem(
                                text: const Text('Transit'),
                                leading: const Icon(FluentIcons.history),
                                onPressed: () => _navigateTo('transit'),
                              ),
                              MenuFlyoutItem(
                                text: const Text('Varshaphal'),
                                leading: const Icon(FluentIcons.calendar),
                                onPressed: () => _navigateTo('varshaphal'),
                              ),
                            ],
                          ),
                          MenuFlyoutSubItem(
                            text: const Text('Special'),
                            leading: const Icon(FluentIcons.lightbulb),
                            items: (context) => [
                              MenuFlyoutItem(
                                text: const Text('Jaimini (AK, Karakamsa)'),
                                leading: const Icon(FluentIcons.favorite_star),
                                onPressed: () => _navigateTo('jaimini'),
                              ),
                              MenuFlyoutItem(
                                text: const Text('Yoga & Dosha'),
                                leading: const Icon(FluentIcons.scale_volume),
                                onPressed: () => _navigateTo('yoga_dosha'),
                              ),
                              MenuFlyoutItem(
                                text: const Text('Planetary Maitri'),
                                leading: const Icon(FluentIcons.people),
                                onPressed: () =>
                                    _navigateTo('planetary_maitri'),
                              ),
                              MenuFlyoutItem(
                                text: const Text('Retrograde'),
                                leading: const Icon(FluentIcons.repeat_one),
                                onPressed: () => _navigateTo('retrograde'),
                              ),
                              MenuFlyoutItem(
                                text: const Text('Sudarshan Chakra'),
                                leading: const Icon(FluentIcons.view_all),
                                onPressed: () =>
                                    _navigateTo('sudarshan_chakra'),
                              ),
                              MenuFlyoutItem(
                                text: const Text('Comparison'),
                                leading: const Icon(FluentIcons.compare),
                                onPressed: () => _navigateTo('comparison'),
                              ),
                              MenuFlyoutItem(
                                text: const Text('Ayanamsa Sandbox'),
                                leading: const Icon(FluentIcons.globe),
                                onPressed: () =>
                                    _navigateTo('ayanamsa_sandbox'),
                              ),
                              MenuFlyoutItem(
                                text: const Text('Progeny'),
                                leading: const Icon(
                                  FluentIcons.reminder_person,
                                ),
                                onPressed: () => _navigateTo('progeny'),
                              ),
                              MenuFlyoutItem(
                                text: const Text('Nadi Analysis'),
                                leading: const Icon(FluentIcons.flow),
                                onPressed: () => _navigateTo('nadi'),
                              ),
                              MenuFlyoutItem(
                                text: const Text('Gochara Vedha'),
                                leading: const Icon(FluentIcons.sync_occurence),
                                onPressed: () => _navigateTo('gochara_vedha'),
                              ),
                              MenuFlyoutItem(
                                text: const Text(
                                  'Planetary War (Graha Yuddha)',
                                ),
                                leading: const Icon(FluentIcons.warning),
                                onPressed: () => _navigateTo('graha_yuddha'),
                              ),
                            ],
                          ),
                          const MenuFlyoutSeparator(),
                          MenuFlyoutItem(
                            text: const Text('PDF Report'),
                            leading: const Icon(FluentIcons.pdf),
                            onPressed: () => _navigateTo('pdf_report'),
                          ),
                        ],
                      );
                    },
                    wrappedItem: CommandBarButton(
                      icon: const Icon(FluentIcons.analytics_view),
                      label: const Text('Analysis'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ContentDialog(
                            title: const Text('Analysis Tools'),
                            content: SizedBox(
                              height: 300,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildMobileAnalysisLink(
                                      'Shadbala',
                                      'shadbala',
                                      FluentIcons.favorite_star,
                                    ),
                                    _buildMobileAnalysisLink(
                                      'Ashtakavarga',
                                      'ashtakavarga',
                                      FluentIcons.grid_view_small,
                                    ),
                                    _buildMobileAnalysisLink(
                                      'Bhava Bala',
                                      'bhava_bala',
                                      FluentIcons.home,
                                    ),
                                    const Divider(),
                                    _buildMobileAnalysisLink(
                                      'Transit',
                                      'transit',
                                      FluentIcons.history,
                                    ),
                                    _buildMobileAnalysisLink(
                                      'Varshaphal',
                                      'varshaphal',
                                      FluentIcons.calendar,
                                    ),
                                    const Divider(),
                                    _buildMobileAnalysisLink(
                                      'Yoga & Dosha',
                                      'yoga_dosha',
                                      FluentIcons.scale_volume,
                                    ),
                                    _buildMobileAnalysisLink(
                                      'Remedies & Gemstones',
                                      'remedies',
                                      FluentIcons.diamond,
                                    ),
                                    _buildMobileAnalysisLink(
                                      'Planetary Maitri',
                                      'planetary_maitri',
                                      FluentIcons.people,
                                    ),
                                    _buildMobileAnalysisLink(
                                      'Retrograde',
                                      'retrograde',
                                      FluentIcons.repeat_one,
                                    ),
                                    _buildMobileAnalysisLink(
                                      'Sudarshan Chakra',
                                      'sudarshan_chakra',
                                      FluentIcons.view_all,
                                    ),
                                    _buildMobileAnalysisLink(
                                      'Comparison',
                                      'comparison',
                                      FluentIcons.compare,
                                    ),
                                    _buildMobileAnalysisLink(
                                      'Ayanamsa Sandbox',
                                      'ayanamsa_sandbox',
                                      FluentIcons.globe,
                                    ),
                                    _buildMobileAnalysisLink(
                                      'Gochara Vedha',
                                      'gochara_vedha',
                                      FluentIcons.sync_occurence,
                                    ),
                                    _buildMobileAnalysisLink(
                                      'Planetary War (Graha Yuddha)',
                                      'graha_yuddha',
                                      FluentIcons.warning,
                                    ),
                                    const Divider(),
                                    _buildMobileAnalysisLink(
                                      'PDF Report',
                                      'pdf_report',
                                      FluentIcons.pdf,
                                    ),
                                  ],
                                ),
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
                      },
                    ),
                  ),

                if (!ResponsiveHelper.useMobileLayout(context))
                  CommandBarButton(
                    icon: const Icon(FluentIcons.build),
                    label: const Text('Rectify'),
                    onPressed: () async {
                      // ... (Logic)
                      if (_birthData == null) return;
                      final newData = await Navigator.push(
                        context,
                        FluentPageRoute(
                          builder: (context) =>
                              const BirthTimeRectifierScreen(),
                          settings: RouteSettings(arguments: _birthData),
                        ),
                      );

                      if (newData != null && newData is BirthData) {
                        setState(() {
                          _birthData = newData;
                          _loadChartData();
                        });
                      }
                    },
                  ),

                // --- Primary Actions (End) ---
                if (!ResponsiveHelper.useMobileLayout(context)) ...[
                  const CommandBarSeparator(),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.save),
                    label: const Text('Save'),
                    onPressed: _saveCurrentChart,
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.share),
                    label: const Text('Share'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return ContentDialog(
                            title: const Text('Share Chart'),
                            content: const Text(
                              'How would you like to share this chart?',
                            ),
                            actions: [
                              Button(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  if (_d1ChartKey.currentContext == null) {
                                    return;
                                  }
                                  try {
                                    await ChartShareService.shareChartImage(
                                      _d1ChartKey,
                                      filename:
                                          '${_birthData?.name ?? 'chart'}_D1.png',
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      displayInfoBar(
                                        context,
                                        builder: (context, close) => InfoBar(
                                          title: const Text('Share Failed'),
                                          content: Text(e.toString()),
                                          severity: InfoBarSeverity.error,
                                          onClose: close,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Image (D-1)'),
                              ),
                              Button(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final data = await _chartDataFuture;
                                  if (data != null && _birthData != null) {
                                    try {
                                      await ChartShareService.shareChartPdf(
                                        data,
                                        _birthData!,
                                        filename:
                                            '${_birthData?.name ?? 'report'}.pdf',
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        displayInfoBar(
                                          context,
                                          builder: (context, close) => InfoBar(
                                            title: const Text('Share Failed'),
                                            content: Text(e.toString()),
                                            severity: InfoBarSeverity.error,
                                            onClose: close,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                child: const Text('PDF Report'),
                              ),
                              Button(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const CommandBarSeparator(),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.info),
                    label: const Text('Info'),
                    onPressed: _showBirthDetails,
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.settings),
                    label: const Text('Settings'),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ],
              secondaryItems: [
                // --- Secondary Actions (Overflow Menu) ---
                // Force these into overflow on mobile for better touch targets
                if (ResponsiveHelper.useMobileLayout(context)) ...[
                  CommandBarButton(
                    icon: const Icon(FluentIcons.save),
                    label: const Text('Save Chart'),
                    onPressed: _saveCurrentChart,
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.share),
                    label: const Text('Share Chart'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return ContentDialog(
                            title: const Text('Share Chart'),
                            content: const Text(
                              'How would you like to share this chart?',
                            ),
                            actions: [
                              Button(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  if (_d1ChartKey.currentContext == null) {
                                    return;
                                  }
                                  try {
                                    await ChartShareService.shareChartImage(
                                      _d1ChartKey,
                                      filename:
                                          '${_birthData?.name ?? 'chart'}_D1.png',
                                    );
                                  } catch (e) {
                                    if (context.mounted) {
                                      displayInfoBar(
                                        context,
                                        builder: (context, close) => InfoBar(
                                          title: const Text('Share Failed'),
                                          content: Text(e.toString()),
                                          severity: InfoBarSeverity.error,
                                          onClose: close,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Image (D-1)'),
                              ),
                              Button(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  final data = await _chartDataFuture;
                                  if (data != null && _birthData != null) {
                                    try {
                                      await ChartShareService.shareChartPdf(
                                        data,
                                        _birthData!,
                                        filename:
                                            '${_birthData?.name ?? 'report'}.pdf',
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        displayInfoBar(
                                          context,
                                          builder: (context, close) => InfoBar(
                                            title: const Text('Share Failed'),
                                            content: Text(e.toString()),
                                            severity: InfoBarSeverity.error,
                                            onClose: close,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                child: const Text('PDF Report'),
                              ),
                              Button(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const CommandBarSeparator(),
                  CommandBarButton(
                    icon: Icon(
                      _style == ChartStyle.northIndian
                          ? FluentIcons.grid_view_small
                          : FluentIcons.diamond,
                    ),
                    label: Text(
                      'Style: ${_style == ChartStyle.northIndian ? 'North Indian' : 'South Indian'}',
                    ),
                    onPressed: () {
                      setState(() {
                        _style = _style == ChartStyle.northIndian
                            ? ChartStyle.southIndian
                            : ChartStyle.northIndian;
                      });
                    },
                  ),
                  CommandBarButton(
                    icon: Icon(
                      _showAspects ? FluentIcons.view : FluentIcons.hide,
                    ),
                    label: Text(_showAspects ? 'Hide Aspects' : 'Show Aspects'),
                    onPressed: () {
                      setState(() {
                        _showAspects = !_showAspects;
                      });
                    },
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.globe),
                    label: const Text('Select Ayanamsa'),
                    onPressed: _openAyanamsaSelection,
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.analytics_view),
                    label: const Text('Analysis Tools'),
                    onPressed: () {
                      // Show a dialog or bottom sheet for analysis tools because
                      // a nested dropdown in a command bar menu might be weird.
                      // Or we can just navigate to a "Menu" or show the same Dropdown logic.
                      // Let's use a simple dialog for now to match the desktop dropdown content.
                      showDialog(
                        context: context,
                        builder: (context) => ContentDialog(
                          title: const Text('Analysis Tools'),
                          content: SizedBox(
                            height: 300,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildMobileAnalysisLink(
                                    'Shadbala',
                                    'shadbala',
                                    FluentIcons.favorite_star,
                                  ),
                                  _buildMobileAnalysisLink(
                                    'Ashtakavarga',
                                    'ashtakavarga',
                                    FluentIcons.grid_view_small,
                                  ),
                                  _buildMobileAnalysisLink(
                                    'Bhava Bala',
                                    'bhava_bala',
                                    FluentIcons.home,
                                  ),
                                  const Divider(),
                                  _buildMobileAnalysisLink(
                                    'Transit',
                                    'transit',
                                    FluentIcons.history,
                                  ),
                                  _buildMobileAnalysisLink(
                                    'Varshaphal',
                                    'varshaphal',
                                    FluentIcons.calendar,
                                  ),
                                  const Divider(),
                                  _buildMobileAnalysisLink(
                                    'Yoga & Dosha',
                                    'yoga_dosha',
                                    FluentIcons.scale_volume,
                                  ),
                                  _buildMobileAnalysisLink(
                                    'Planetary Maitri',
                                    'planetary_maitri',
                                    FluentIcons.people,
                                  ),
                                  _buildMobileAnalysisLink(
                                    'Retrograde',
                                    'retrograde',
                                    FluentIcons.repeat_one,
                                  ),
                                  _buildMobileAnalysisLink(
                                    'Sudarshan Chakra',
                                    'sudarshan_chakra',
                                    FluentIcons.view_all,
                                  ),
                                  _buildMobileAnalysisLink(
                                    'Comparison',
                                    'comparison',
                                    FluentIcons.compare,
                                  ),
                                  _buildMobileAnalysisLink(
                                    'Planetary War (Graha Yuddha)',
                                    'graha_yuddha',
                                    FluentIcons.warning,
                                  ),
                                  const Divider(),
                                  _buildMobileAnalysisLink(
                                    'PDF Report',
                                    'pdf_report',
                                    FluentIcons.pdf,
                                  ),
                                ],
                              ),
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
                    },
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.build),
                    label: const Text('Birth Time Rectification'),
                    onPressed: () async {
                      if (_birthData == null) return;
                      final newData = await Navigator.push(
                        context,
                        FluentPageRoute(
                          builder: (context) =>
                              const BirthTimeRectifierScreen(),
                          settings: RouteSettings(arguments: _birthData),
                        ),
                      );

                      if (newData != null && newData is BirthData) {
                        setState(() {
                          _birthData = newData;
                          _loadChartData();
                        });
                      }
                    },
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.info),
                    label: const Text('Birth Details'),
                    onPressed: _showBirthDetails,
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.settings),
                    label: const Text('Settings'),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ],
            ),
          ),
          content: builder(snapshot.data!),
        );
      },
    );
  }
}
