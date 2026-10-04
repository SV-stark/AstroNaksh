// ignore_for_file: avoid_slow_async_io, unawaited_futures, deprecated_member_use, sort_constructors_first, implementation_imports
import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jyotish/core.dart';

import '../../core/app_environment.dart';
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
  ChartStyle? _styleOverride;
  String _selectedDivisionalChart = 'D-9';
  BirthData? _birthData;
  int _currentIndex = 0;
  int _dashaTabIndex = 0; // 0 = Vimshottari, 1 = Yogini, 2 = Chara
  bool _showAspects = false; // Toggle for planetary aspects (drishti)
  final GlobalKey _d1ChartKey = GlobalKey();

  // Timeline state variables
  DateTime _timelineCurrentDate = DateTime.now();
  bool _isTimelinePlaying = false;
  double _timelineSpeed = 1.0;
  Timer? _timelineTimer;

  /// Human readable reason the last [generateCompleteChart] call failed.
  /// The service intentionally swallows errors and returns `null`, so without
  /// this the screen would show a bare "No Data" with no way to recover.
  String? _lastChartError;

  /// Chart style in effect, falling back to the persisted preference.
  ChartStyle get _style =>
      _styleOverride ??
      ref.watch(settingsProvider).asData?.value.chartSettings.chartStyle ??
      ChartStyle.northIndian;

  /// Flips the chart style and persists it, so Settings and the chart screen
  /// can no longer disagree about which style is active.
  void _toggleChartStyle() {
    final next = _style == ChartStyle.northIndian
        ? ChartStyle.southIndian
        : ChartStyle.northIndian;
    setState(() => _styleOverride = next);
    final current =
        ref.read(settingsProvider).asData?.value.chartSettings ??
        ChartCustomization();
    unawaited(
      ref
          .read(settingsProvider.notifier)
          .updateChartSettings(current.copyWith(chartStyle: next))
          .catchError((Object error) {
            AppEnvironment.log('Failed to persist chart style: $error');
          }),
    );
  }

  /// Guards the one-shot birth-data resolution in [didChangeDependencies],
  /// which otherwise re-runs (and re-pops) on every inherited-widget change.
  bool _birthDataResolved = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_birthDataResolved) return;
    _birthDataResolved = true;

    final birthData = _resolveBirthData();
    if (birthData != null) {
      _birthData = birthData;
      _loadChartData();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Error'),
          content: const Text('No birth data provided'),
          severity: InfoBarSeverity.error,
          onClose: close,
        ),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        Navigator.pop(context);
      }
    });
  }

  /// Resolves the birth data handed to this screen. The router always supplies
  /// it via `extra`, so `GoRouterState`/`ModalRoute` are checked only as a
  /// fallback for direct `Navigator.push` callers.
  BirthData? _resolveBirthData() {
    final provided = widget.birthData;
    if (provided != null) return provided;

    try {
      final extra = GoRouterState.of(context).extra;
      if (extra is BirthData) return extra;
    } on Object catch (error, stackTrace) {
      AppEnvironment.log('Failed to read GoRouter extra: $error\n$stackTrace');
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    return args is BirthData ? args : null;
  }

  void _loadChartData() {
    final birthData = _birthData;
    if (birthData == null) return;

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

    _lastChartError = null;
    final future = _kpChartService.generateCompleteChart(
      birthData,
      vargaConfig: vargaConfig,
      onFailure: (error, _) {
        _lastChartError = _describeChartFailure(error);
      },
    );
    if (mounted) {
      setState(() => _chartDataFuture = future);
    } else {
      _chartDataFuture = future;
    }
  }

  /// Turns a swallowed chart-generation failure into something the user can act on.
  String _describeChartFailure(Object error) {
    final message = error.toString();

    const ephemerisMarkers = [
      'swisseph',
      'Failed to load dynamic library',
      'Dll',
      'FFI',
    ];
    if (ephemerisMarkers.any(message.contains)) {
      return 'The Swiss Ephemeris library could not be loaded. '
          'Reinstall the application or check that swisseph.dll is present.';
    }

    const coordinateMarkers = [
      'latitude',
      'longitude',
      'RangeError',
    ];
    if (coordinateMarkers.any(message.contains)) {
      return 'The birth details contain coordinates outside the supported '
          'range. Latitude must be -90..90 and longitude -180..180.';
    }

    return message;
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
    if (!mounted) return;
    if (data == null) {
      _showInfo(
        'Chart unavailable',
        _lastChartError ?? 'The chart data failed to load.',
        severity: InfoBarSeverity.error,
      );
      return;
    }

    await Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => BirthDetailsScreen(chartData: data),
      ),
    );
  }

  /// Shows a transient message anchored to this screen.
  void _showInfo(
    String title,
    String message, {
    InfoBarSeverity severity = InfoBarSeverity.info,
  }) {
    if (!mounted) return;
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(title),
        content: Text(message),
        severity: severity,
        onClose: close,
      ),
    );
  }

  /// Opens the birth-time rectifier and reloads the chart if it returns new data.
  Future<void> _openRectifier() async {
    final birthData = _birthData;
    if (birthData == null) return;

    final result = await Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => const BirthTimeRectifierScreen(),
        settings: RouteSettings(arguments: birthData),
      ),
    );

    if (!mounted) return;
    if (result is! BirthData) return;

    _birthData = result;
    _loadChartData();
  }

  /// Single share sheet used by both the primary and the overflow command bar.
  void _showShareDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('Share Chart'),
        content: const Text('How would you like to share this chart?'),
        actions: [
          Button(
            onPressed: () {
              Navigator.pop(dialogContext);
              _shareChartImage();
            },
            child: const Text('Image (D-1)'),
          ),
          Button(
            onPressed: () {
              Navigator.pop(dialogContext);
              _shareChartPdf();
            },
            child: const Text('PDF Report'),
          ),
          Button(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareChartImage() async {
    // The D-1 chart only exists while its pane is mounted, so say so instead of
    // failing silently.
    if (_d1ChartKey.currentContext == null) {
      _showInfo(
        'Chart image unavailable',
        'Open the D-1 Rashi tab first, then share the chart image.',
        severity: InfoBarSeverity.warning,
      );
      return;
    }
    try {
      await ChartShareService.shareChartImage(
        _d1ChartKey,
        filename: '${_birthData?.name ?? 'chart'}_D1.png',
      );
    } catch (error) {
      _showInfo('Share Failed', '$error', severity: InfoBarSeverity.error);
    }
  }

  Future<void> _shareChartPdf() async {
    final birthData = _birthData;
    if (birthData == null) return;
    final data = await _chartDataFuture;
    if (!mounted) return;
    if (data == null) {
      _showInfo(
        'Report unavailable',
        _lastChartError ?? 'The chart data failed to load.',
        severity: InfoBarSeverity.error,
      );
      return;
    }
    try {
      await ChartShareService.shareChartPdf(
        data,
        birthData,
        filename: '${birthData.name.isEmpty ? 'report' : birthData.name}.pdf',
      );
    } catch (error) {
      _showInfo('Share Failed', '$error', severity: InfoBarSeverity.error);
    }
  }

  void _saveCurrentChart() async {
    if (_birthData == null) return;

    // Save to both SharedPreferences and Database for compatibility
    await SavedChartsHelper.saveChart(_birthData!);

    final db = ref.read(databaseProvider);
    final birthIso = _birthData!.dateTime.toIso8601String();
    final existing =
        await (db.select(db.charts)..where(
              (tbl) =>
                  tbl.name.equals(_birthData!.name) &
                  tbl.birthTime.equals(birthIso),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await db
          .into(db.charts)
          .insert(
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
      await (db.update(
        db.charts,
      )..where((tbl) => tbl.id.equals(existing.id))).write(
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

  /// Upper bound on the timeline refresh rate. Every tick rebuilds the whole
  /// chart screen, so faster speeds would starve the UI thread for no gain.
  static const _minTimelineTick = Duration(milliseconds: 120);

  void _onTimelinePlay() {
    // Always drop any previous ticker first: calling play twice used to orphan
    // the old timer, leaving two tickers that could never be cancelled.
    _stopTimelineTimer();
    setState(() {
      _isTimelinePlaying = true;
    });

    final rawTick = Duration(milliseconds: (100 / _timelineSpeed).round());
    _timelineTimer = Timer.periodic(
      rawTick < _minTimelineTick ? _minTimelineTick : rawTick,
      (timer) {
        final next = _timelineCurrentDate.add(const Duration(days: 1));
        final horizon = DateTime.now().add(const Duration(days: 365));
        if (next.isAfter(horizon)) {
          if (mounted) {
            setState(() {
              _timelineCurrentDate = horizon;
            });
          }
          _onTimelinePause();
          return;
        }
        if (mounted) {
          setState(() {
            _timelineCurrentDate = next;
          });
        }
      },
    );
  }

  void _onTimelinePause() {
    _stopTimelineTimer();
    if (mounted) {
      setState(() {
        _isTimelinePlaying = false;
      });
    }
  }

  void _stopTimelineTimer() {
    _timelineTimer?.cancel();
    _timelineTimer = null;
  }

  void _onTimelineSpeedChanged(double speed) {
    setState(() {
      _timelineSpeed = speed;
    });
    // Restart the ticker so the new speed takes effect immediately, without
    // nesting one setState inside another.
    if (_isTimelinePlaying) {
      _onTimelinePause();
      _onTimelinePlay();
    }
  }

  @override
  void dispose() {
    _timelineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

    // The NavigationPane already collapses to its own menu button in
    // [PaneDisplayMode.minimal], so a parallel Material Drawer would render a
    // second, competing hamburger and swallow the back button.
    return content;
  }

  Widget _buildAnalysisLink(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: SizedBox(
        height: 48,
        child: Button(
          onPressed: () {
            Navigator.pop(context);
            _navigateTo(title);
          },
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(FluentIcons.chevron_right, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  /// Single source of truth for every analysis destination reachable from the
  /// chart. Both the desktop drop-down and the compact dialog render from this
  /// list, so a destination can never end up missing on one form factor only.
  static const List<_AnalysisGroup> _analysisGroups = <_AnalysisGroup>[
    _AnalysisGroup('Strength', FluentIcons.favorite_star, [
      _AnalysisDestination('shadbala', 'Shadbala', FluentIcons.favorite_star),
      _AnalysisDestination(
        'ashtakavarga',
        'Ashtakavarga',
        FluentIcons.grid_view_small,
      ),
      _AnalysisDestination('bhava-bala', 'Bhava Bala', FluentIcons.home),
    ]),
    _AnalysisGroup('Predictions', FluentIcons.calendar, [
      _AnalysisDestination('transit', 'Transit', FluentIcons.history),
      _AnalysisDestination('varshaphal', 'Varshaphal', FluentIcons.calendar),
      _AnalysisDestination(
        'sudarshan-chakra',
        'Sudarshan Chakra',
        FluentIcons.view_all,
      ),
    ]),
    _AnalysisGroup('Special', FluentIcons.lightbulb, [
      _AnalysisDestination(
        'jaimini',
        'Jaimini (AK, Karakamsa)',
        FluentIcons.favorite_star,
      ),
      _AnalysisDestination(
        'yoga-dosha',
        'Yoga & Dosha',
        FluentIcons.scale_volume,
      ),
      _AnalysisDestination(
        'planetary-maitri',
        'Planetary Maitri',
        FluentIcons.people,
      ),
      _AnalysisDestination('retrograde', 'Retrograde', FluentIcons.repeat_one),
      _AnalysisDestination('comparison', 'Comparison', FluentIcons.compare),
      _AnalysisDestination(
        'ayanamsa-sandbox',
        'Ayanamsa Sandbox',
        FluentIcons.globe,
      ),
      _AnalysisDestination('progeny', 'Progeny', FluentIcons.reminder_person),
      _AnalysisDestination('nadi', 'Nadi Analysis', FluentIcons.flow),
      _AnalysisDestination(
        'gochara-vedha',
        'Gochara Vedha',
        FluentIcons.sync_occurence,
      ),
      _AnalysisDestination(
        'graha-yuddha',
        'Planetary War (Graha Yuddha)',
        FluentIcons.warning,
      ),
      _AnalysisDestination(
        'remedies',
        'Remedies & Gemstones',
        FluentIcons.diamond,
      ),
    ]),
    _AnalysisGroup('Reports', FluentIcons.pdf, [
      _AnalysisDestination('pdf-report', 'PDF Report', FluentIcons.pdf),
    ]),
  ];

  /// Drop-down used on wide layouts, where there is room for nested sub-menus.
  ///
  /// `DropDownButton` is a plain widget rather than a `CommandBarItem`, so it is
  /// smuggled in through [CommandBarBuilderItem]. When the bar overflows, the
  /// item is rebuilt in secondary mode and the wrapped button is used instead,
  /// which keeps the destination reachable from the overflow menu.
  CommandBarItem _buildAnalysisDropDown() {
    return CommandBarBuilderItem(
      builder: (context, displayMode, wrapped) {
        if (displayMode == CommandBarItemDisplayMode.inSecondary) {
          return wrapped;
        }
        return DropDownButton(
          title: const Text('Analysis'),
          leading: const Icon(FluentIcons.analytics_view),
          items: [
            for (var i = 0; i < _analysisGroups.length; i++) ...[
              MenuFlyoutSubItem(
                text: Text(_analysisGroups[i].title),
                leading: Icon(_analysisGroups[i].icon),
                items: (context) => [
                  for (final destination in _analysisGroups[i].destinations)
                    MenuFlyoutItem(
                      text: Text(destination.title),
                      leading: Icon(destination.icon),
                      onPressed: () => _navigateTo(destination.key),
                    ),
                ],
              ),
              if (i != _analysisGroups.length - 1) const MenuFlyoutSeparator(),
            ],
          ],
        );
      },
      wrappedItem: CommandBarButton(
        icon: const Icon(FluentIcons.analytics_view),
        label: const Text('Analysis Tools'),
        onPressed: _showAnalysisDialog,
      ),
    );
  }

  /// Compact list used when there is not enough room for a drop-down.
  void _showAnalysisDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => ContentDialog(
        title: const Text('Analysis Tools'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final group in _analysisGroups) ...[
                  for (final destination in group.destinations)
                    _buildAnalysisLink(destination.title, destination.icon),
                  const Divider(),
                ],
              ],
            ),
          ),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Builds the destination screen for [key], or `null` when the key is unknown.
  Widget? _buildAnalysisScreen(String key, CompleteChartData chartData) {
    switch (key) {
      case 'shadbala':
        return ShadbalaScreen(chartData: chartData);
      case 'ashtakavarga':
        return AshtakavargaScreen(chartData: chartData);
      case 'bhava_bala':
        return BhavaBalaScreen(chartData: chartData);
      case 'yoga-dosha':
        return YogaDoshaScreen(chartData: chartData);
      case 'planetary-maitri':
        return PlanetaryMaitriScreen(chartData: chartData);
      case 'transit':
        return TransitScreen(natalChart: chartData);
      case 'varshaphal':
        return VarshaphalScreen(birthData: _birthData!);
      case 'retrograde':
        return RetrogradeScreen(chartData: chartData);
      case 'sudarshan-chakra':
        return SudarshanChakraScreen(chartData: chartData);
      case 'comparison':
        return ChartComparisonScreen(chart1: chartData);
      case 'ayanamsa-sandbox':
        return AyanamsaSandboxScreen(birthData: _birthData);
      case 'jaimini':
        return JaiminiScreen(chartData: chartData);
      case 'progeny':
        return ProgenyScreen(chartData: chartData);
      case 'nadi':
        return NadiScreen(chartData: chartData);
      case 'gochara-vedha':
        return GocharaVedhaScreen(chartData: chartData);
      case 'graha-yuddha':
        return GrahaYuddhaScreen(chartData: chartData);
      case 'pdf-report':
        return PDFReportScreen(chartData: chartData);
      case 'remedies':
        return RemediesScreen(chart: chartData.baseChart);
      default:
        return null;
    }
  }

  Future<void> _navigateTo(String key) async {
    final birthData = _birthData;
    if (_chartDataFuture == null || birthData == null) return;

    final chartData = await _chartDataFuture;
    if (!mounted) return;
    if (chartData == null) {
      _showInfo(
        'Chart unavailable',
        _lastChartError ?? 'The chart data failed to load.',
        severity: InfoBarSeverity.error,
      );
      return;
    }

    final screen = _buildAnalysisScreen(key, chartData);
    if (screen == null) {
      AppEnvironment.log('No analysis screen registered for key "$key"');
      return;
    }

    await Navigator.push(context, FluentPageRoute(builder: (_) => screen));
  }

  /// Full-pane placeholder used while the chart loads or after it failed.
  Widget _buildChartMessage(
    String title,
    String? message, {
    VoidCallback? onRetry,
  }) {
    final theme = FluentTheme.of(context);
    return ScaffoldPage(
      header: PageHeader(
        title: Text(title, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(FluentIcons.back, semanticLabel: 'Go back'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (message == null)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: ProgressRing(),
                  )
                else ...[
                  Icon(FluentIcons.error, size: 48, color: theme.accentColor),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.typography.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (onRetry != null)
                        Button(
                          onPressed: onRetry,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(FluentIcons.refresh, size: 16),
                              SizedBox(width: 8),
                              Text('Retry'),
                            ],
                          ),
                        ),
                      Button(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Widget Function(CompleteChartData) builder) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);
    return FutureBuilder<CompleteChartData?>(
      future: _chartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChartMessage('Loading', null);
        }

        final failure =
            snapshot.error?.toString() ??
            (snapshot.data == null
                ? _lastChartError ?? 'No chart data was returned.'
                : null);
        if (snapshot.data == null) {
          // generateCompleteChart() reports failures by returning null, so this
          // is the branch real errors land in. Surface the cause and a retry.
          return _buildChartMessage(
            'Chart unavailable',
            failure,
            onRetry: _loadChartData,
          );
        }

        return ScaffoldPage(
          header: PageHeader(
            title: const Flexible(
              child: Text('Vedic Chart', overflow: TextOverflow.ellipsis),
            ),
            leading: IconButton(
              icon: const Icon(FluentIcons.back, semanticLabel: 'Go back'),
              onPressed: () => Navigator.pop(context),
            ),
            commandBar: CommandBar(
              overflowBehavior: CommandBarOverflowBehavior.dynamicOverflow,
              mainAxisAlignment: MainAxisAlignment.end,
              primaryItems: [
                // --- View & Calculation Options (Left/Start) ---
                if (!isMobile) ...[
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
                    onPressed: _toggleChartStyle,
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
                if (!isMobile) _buildAnalysisDropDown(),
                if (!isMobile)
                  CommandBarButton(
                    icon: const Icon(FluentIcons.build),
                    label: const Text('Rectify'),
                    onPressed: _openRectifier,
                  ),

                if (!isMobile) ...[
                  const CommandBarSeparator(),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.save),
                    label: const Text('Save'),
                    onPressed: _saveCurrentChart,
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.share),
                    label: const Text('Share'),
                    onPressed: _showShareDialog,
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
                if (isMobile) ...[
                  CommandBarButton(
                    icon: const Icon(FluentIcons.save),
                    label: const Text('Save Chart'),
                    onPressed: _saveCurrentChart,
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.share),
                    label: const Text('Share Chart'),
                    onPressed: _showShareDialog,
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
                    onPressed: _toggleChartStyle,
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
                    onPressed: _showAnalysisDialog,
                  ),
                  CommandBarButton(
                    icon: const Icon(FluentIcons.build),
                    label: const Text('Birth Time Rectification'),
                    onPressed: _openRectifier,
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

/// A single analysis destination offered by the chart screen's Analysis menu.
class _AnalysisDestination {
  const _AnalysisDestination(this.key, this.title, this.icon);

  /// Stable identifier resolved by [_ChartScreenState._buildAnalysisScreen].
  final String key;
  final String title;
  final IconData icon;
}

/// A titled group of [ _AnalysisDestination]s shown as a drop-down sub-menu.
class _AnalysisGroup {
  const _AnalysisGroup(this.title, this.icon, this.destinations);

  final String title;
  final IconData icon;
  final List<_AnalysisDestination> destinations;
}
