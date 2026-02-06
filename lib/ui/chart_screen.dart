import 'package:fluent_ui/fluent_ui.dart';
import 'widgets/chart_widget.dart';
import '../../data/models.dart';
import '../../logic/kp_chart_service.dart';

import 'package:jyotish/jyotish.dart';
import '../../core/ayanamsa_calculator.dart';
import '../../core/constants.dart';

import '../../core/settings_manager.dart';
import 'tools/birth_time_rectifier_screen.dart';
import '../../core/saved_charts_helper.dart';
import '../../core/database_helper.dart';
// New analysis screens
import 'strength/ashtakavarga_screen.dart';
import 'strength/shadbala_screen.dart';
import 'strength/bhava_bala_screen.dart';
import 'analysis/yoga_dosha_screen.dart';
import 'predictions/transit_screen.dart';
import 'predictions/varshaphal_screen.dart';
import 'analysis/retrograde_screen.dart';
import 'comparison/chart_comparison_screen.dart';
import 'predictions/rashiphal_dashboard.dart';
import 'reports/pdf_report_screen.dart';
import '../../core/chart_share_service.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final KPChartService _kpChartService = KPChartService();
  Future<CompleteChartData>? _chartDataFuture;
  ChartStyle _style = ChartStyle.northIndian;
  String _selectedDivisionalChart = 'D-9';
  BirthData? _birthData;
  int _currentIndex = 0;
  final GlobalKey _d1ChartKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_birthData == null) {
      final args = ModalRoute.of(context)?.settings.arguments as BirthData?;
      if (args != null) {
        _birthData = args;
        _loadChartData();
      } else {
        // Handle missing arguments
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            displayInfoBar(
              context,
              builder: (context, close) => InfoBar(
                title: const Text('Error'),
                content: const Text('No birth data provided'),
                severity: InfoBarSeverity.error,
              ),
            );
            Navigator.pop(context);
          }
        });
      }
    }
  }

  void _loadChartData() {
    if (_birthData != null) {
      setState(() {
        _chartDataFuture = _kpChartService.generateCompleteChart(_birthData!);
      });
    }
  }

  void _openAyanamsaSelection() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
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
                      placeholder: "Search Ayanamsa...",
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
                      child: ListView.builder(
                        itemCount: filteredSystems.length,
                        itemBuilder: (context, index) {
                          final system = filteredSystems[index];
                          final isSelected =
                              SettingsManager().chartSettings.ayanamsaSystem
                                  .toLowerCase() ==
                              system.name.toLowerCase();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: RadioButton(
                              checked: isSelected,
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
                              onChanged: (v) {
                                if (v == true) {
                                  SettingsManager()
                                          .chartSettings
                                          .ayanamsaSystem =
                                      system.name;
                                  Navigator.pop(context);
                                  _loadChartData();
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

  void _showBirthDetails() {
    if (_birthData == null) return;
    showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: const Text('Birth Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: ${_birthData!.name}"),
              Text(
                "Date: ${_birthData!.dateTime.day}/${_birthData!.dateTime.month}/${_birthData!.dateTime.year}",
              ),
              Text(
                "Time: ${_birthData!.dateTime.hour.toString().padLeft(2, '0')}:${_birthData!.dateTime.minute.toString().padLeft(2, '0')}",
              ),
              Text("Place: ${_birthData!.place}"),
              Text(
                "Lat: ${_birthData!.location.latitude.toStringAsFixed(4)}, Lon: ${_birthData!.location.longitude.toStringAsFixed(4)}",
              ),
            ],
          ),
          actions: [
            Button(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _saveCurrentChart() async {
    if (_birthData == null) return;

    // Save to both SharedPreferences and Database for compatibility
    await SavedChartsHelper.saveChart(_birthData!);

    final dbHelper = DatabaseHelper();
    await dbHelper.insertChart({
      'name': _birthData!.name,
      'dateTime': _birthData!.dateTime.toIso8601String(),
      'latitude': _birthData!.location.latitude,
      'longitude': _birthData!.location.longitude,
      'locationName': _birthData!.place,
      'timezone': _birthData!.timezone.isEmpty ? 'UTC' : _birthData!.timezone,
    });

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

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text("Vedic Chart"),
        actions: CommandBar(
          overflowBehavior: CommandBarOverflowBehavior.noWrap,
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            // 1. Info Button (New)
            CommandBarButton(
              icon: const Icon(FluentIcons.info),
              label: const Text('Info'),
              onPressed: _showBirthDetails,
            ),
            // 2. Save Button (New)
            CommandBarButton(
              icon: const Icon(FluentIcons.save),
              label: const Text('Save'),
              onPressed: _saveCurrentChart,
            ),
            // 3. Share/Export Button (New)
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
                            if (_d1ChartKey.currentContext == null) return;
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
            // 3. Settings
            CommandBarButton(
              icon: const Icon(FluentIcons.settings),
              label: const Text('Settings'),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            // 4. Analysis DropDown (Existing, made prominent)
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
                          leading: const Icon(FluentIcons.grid_view_small),
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
                          text: const Text('Yoga & Dosha'),
                          leading: const Icon(FluentIcons.scale_volume),
                          onPressed: () => _navigateTo('yoga_dosha'),
                        ),
                        MenuFlyoutItem(
                          text: const Text('Retrograde'),
                          leading: const Icon(FluentIcons.repeat_one),
                          onPressed: () => _navigateTo('retrograde'),
                        ),
                        MenuFlyoutItem(
                          text: const Text('Comparison'),
                          leading: const Icon(FluentIcons.compare),
                          onPressed: () => _navigateTo('comparison'),
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
                onPressed: () {},
              ),
            ),
            const CommandBarSeparator(),
            // 5. Ayanamsa
            CommandBarButton(
              icon: const Icon(FluentIcons.globe),
              label: const Text('Ayanamsa'),
              onPressed: _openAyanamsaSelection,
            ),
            // 6. Style
            CommandBarButton(
              icon: Icon(
                _style == ChartStyle.northIndian
                    ? FluentIcons.grid_view_small
                    : FluentIcons.diamond,
              ),
              label: const Text('Style'),
              onPressed: () {
                setState(() {
                  _style = _style == ChartStyle.northIndian
                      ? ChartStyle.southIndian
                      : ChartStyle.northIndian;
                });
              },
            ),
            // 7. Rectify
            CommandBarButton(
              icon: const Icon(FluentIcons.build),
              label: const Text('Rectify'),
              onPressed: () async {
                if (_birthData == null) return;
                final newData = await Navigator.push(
                  context,
                  FluentPageRoute(
                    builder: (context) => const BirthTimeRectifierScreen(),
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
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
        displayMode: PaneDisplayMode.open,
        size: const NavigationPaneSize(openWidth: 200),
        header: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getCurrentTabIcon(_currentIndex),
                size: 32,
                color: FluentTheme.of(context).accentColor,
              ),
              const SizedBox(height: 8),
              Text(
                _getCurrentTabTitle(_currentIndex),
                style: FluentTheme.of(
                  context,
                ).typography.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        items: [
          PaneItemHeader(header: const Text('Main Charts')),
          PaneItem(
            icon: const Icon(FluentIcons.contact_card),
            title: const Text("D-1 Rashi"),
            body: _buildBody(_buildD1Tab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.grid_view_large),
            title: const Text("Vargas"),
            body: _buildBody(_buildVargasTab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.scatter_chart),
            title: const Text("KP System"),
            body: _buildBody(_buildKPTab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.timer),
            title: const Text("Dasha Periods"),
            body: _buildBody(_buildDashaTab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.list),
            title: const Text("Planet Details"),
            body: _buildBody(_buildDetailsTab),
          ),
          PaneItemHeader(header: const Text('Analysis')),
          PaneItem(
            icon: const Icon(FluentIcons.lightbulb),
            title: const Text("Daily Rashiphal"),
            body: _buildBody(
              (data) => RashiphalDashboardScreen(chartData: data),
            ),
          ),
        ],
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
      case 'transit':
        screen = TransitScreen(natalChart: chartData);
        break;
      case 'varshaphal':
        screen = VarshaphalScreen(birthData: _birthData!);
        break;
      case 'retrograde':
        screen = RetrogradeScreen(chartData: chartData);
        break;
      case 'comparison':
        screen = ChartComparisonScreen(chart1: chartData);
        break;
      case 'pdf_report':
        screen = PDFReportScreen(chartData: chartData);
        break;
      default:
        return;
    }

    Navigator.push(context, FluentPageRoute(builder: (context) => screen));
  }

  Widget _buildBody(Widget Function(CompleteChartData) builder) {
    return FutureBuilder<CompleteChartData>(
      future: _chartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ProgressRing());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: FluentTheme.of(context).typography.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Button(
                      onPressed: _loadChartData,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(FluentIcons.refresh, size: 16),
                          const SizedBox(width: 8),
                          const Text("Retry"),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Button(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Go Back"),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData) {
          return const Center(child: Text("No Data"));
        }
        return builder(snapshot.data!);
      },
    );
  }

  Widget _buildD1Tab(CompleteChartData data) {
    final planetsMap = _getPlanetsMap(data.baseChart);
    final ascSign = _getAscendantSignInt(data.baseChart);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Rashi Chart (D-1)",
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 8),
          Text(
            "Lagna: ${_getAscendantSign(data.baseChart)}",
            style: FluentTheme.of(context).typography.body,
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: _d1ChartKey,
            child: ChartWidget(
              planetsBySign: planetsMap,
              ascendantSign: ascSign,
              style: _style,
              size: 350,
            ),
          ),
          const SizedBox(height: 16),
          _buildPlanetPositionsTable(data),
        ],
      ),
    );
  }

  Widget _buildVargasTab(CompleteChartData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Divisional Charts (Vargas)",
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling list for Charts
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  [
                        'D-1',
                        'D-2',
                        'D-3',
                        'D-4',
                        'D-7',
                        'D-9',
                        'D-10',
                        'D-12',
                        'D-16',
                        'D-20',
                        'D-24',
                        'D-27',
                        'D-30',
                        'D-40',
                        'D-45',
                        'D-60',
                      ]
                      .map(
                        (code) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ToggleButton(
                            checked: _selectedDivisionalChart == code,
                            onChanged: (selected) {
                              if (selected) {
                                setState(() => _selectedDivisionalChart = code);
                              }
                            },
                            child: Text(code),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildDivisionalChartDisplay(data, _selectedDivisionalChart),
        ],
      ),
    );
  }

  Widget _buildDivisionalChartDisplay(CompleteChartData data, String code) {
    final chart = data.divisionalCharts[code];
    if (chart == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Chart data not available"),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "${chart.name} (${chart.code})",
              style: FluentTheme.of(context).typography.subtitle,
            ),
            Text(
              chart.description,
              style: FluentTheme.of(context).typography.caption,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),
            ChartWidget(
              planetsBySign: _getDivisionalPlanetsMap(chart),
              ascendantSign: (chart.ascendantSign ?? 0) + 1,
              style: _style,
              size: 350,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPTab(CompleteChartData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("KP System", style: FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 16),
          _buildKPSubLordsCard(data),
          const SizedBox(height: 16),
          _buildKPSignificatorsCard(data),
          const SizedBox(height: 16),
          _buildRulingPlanetsCard(data),
        ],
      ),
    );
  }

  Widget _buildKPSubLordsCard(CompleteChartData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "KP Sub Lords",
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 10),
            // Simple Table Concept (using Column/Rows)
            Table(
              columnWidths: const {0: FlexColumnWidth(1)},
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: FluentTheme.of(context).cardColor,
                    border: Border(
                      bottom: BorderSide(
                        color: FluentTheme.of(
                          context,
                        ).resources.dividerStrokeColorDefault,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Planet",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: FluentTheme.of(context).accentColor,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Nakshatra",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Star Lord",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Sub Lord",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Sub-Sub",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const TableRow(
                  children: [
                    SizedBox(height: 8),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                  ],
                ),
                ...data.significatorTable.entries.map((entry) {
                  final planet = entry.key;
                  final info = entry.value;
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          planet,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(info['nakshatra'] ?? ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(info['starLord'] ?? ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(info['subLord'] ?? ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(info['subSubLord'] ?? ''),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPSignificatorsCard(CompleteChartData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Significations",
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(4),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: FluentTheme.of(
                          context,
                        ).resources.dividerStrokeColorDefault,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Planet",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: FluentTheme.of(context).accentColor,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Houses (Significations)",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const TableRow(children: [SizedBox(height: 8), SizedBox()]),
                ...data.significatorTable.entries.map((entry) {
                  final planet = entry.key;
                  final info = entry.value;
                  final significations =
                      info['significations'] as List<dynamic>? ?? [];
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          planet,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(significations.join(', ')),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulingPlanetsCard(CompleteChartData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ruling Planets",
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: data.kpData.rulingPlanets
                  .map(
                    (planet) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FluentTheme.of(context).accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        planet,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashaTab(CompleteChartData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Vimshottari Dasha",
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 16),
          // Timeline-like visual for Dasha
          _buildVimshottariDashaCard(data.dashaData.vimshottari),
          const SizedBox(height: 16),
          _buildYoginiDashaCard(data.dashaData.yogini),
          const SizedBox(height: 16),
          _buildCharaDashaCard(data.dashaData.chara),
        ],
      ),
    );
  }

  Widget _buildYoginiDashaCard(YoginiDasha dasha) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Yogini Dasha",
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            Text("Start Yogini: ${dasha.startYogini}"),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            // Yogini periods are often short enough to list, or we use a table
            SizedBox(
              height: 250, // Constrain height if list is long
              child: ListView.builder(
                itemCount: dasha.mahadashas.length,
                itemBuilder: (context, index) {
                  final maha = dasha.mahadashas[index];
                  return ListTile(
                    title: Text("${maha.name} (${maha.lord})"),
                    subtitle: Text(
                      "${_formatDate(maha.startDate)} - ${_formatDate(maha.endDate)}",
                    ),
                    trailing: Text("${maha.periodYears}y"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharaDashaCard(CharaDasha dasha) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chara Dasha (Jaimini)",
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Sign (Rashi)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("Period", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Divider(),
            SizedBox(
              height: 250,
              child: ListView.builder(
                itemCount: dasha.periods.length,
                itemBuilder: (context, index) {
                  final period = dasha.periods[index];
                  return ListTile(
                    title: Text("${period.signName} (${period.lord})"),
                    subtitle: Text(
                      "${_formatDate(period.startDate)} - ${_formatDate(period.endDate)}",
                    ),
                    trailing: Text("${period.periodYears.toInt()}y"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVimshottariDashaCard(VimshottariDasha dasha) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Vimshottari Dasha",
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            Text("Birth Lord: ${dasha.birthLord}"),
            Text("Balance: ${dasha.formattedBalanceAtBirth}"),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            ...dasha.mahadashas.map(
              (maha) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Expander(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: FluentTheme.of(context).accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  header: Text(
                    "${maha.lord} - ${maha.formattedPeriod}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: maha.antardashas
                        .map(
                          (antar) => ListTile(
                            title: Text(
                              "${antar.lord} (${antar.periodYears.toStringAsFixed(2)}y)",
                            ),
                            subtitle: Text(
                              "${_formatDate(antar.startDate)} - ${_formatDate(antar.endDate)}",
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(CompleteChartData data) {
    final planets = data.baseChart.planets;
    final navamsa = data.divisionalCharts['D-9'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Planetary Details",
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 16),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(0.5),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: FluentTheme.of(
                                context,
                              ).resources.dividerStrokeColorDefault,
                            ),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              "Planet",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: FluentTheme.of(context).accentColor,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              "Sign",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              "Long",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              "R",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const TableRow(
                        children: [
                          SizedBox(height: 8),
                          SizedBox(),
                          SizedBox(),
                          SizedBox(),
                        ],
                      ),
                      ...planets.entries.map((e) {
                        final planetName = e.key.toString().split('.').last;
                        final info = e.value;
                        final signName = _getSignName(
                          (info.longitude / 30).floor() + 1,
                        );
                        final normLongitude = info.longitude % 30;

                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                planetName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(signName),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(normLongitude.toStringAsFixed(2)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                info.isRetrograde ? "R" : "",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      // Add Rahu
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'Rahu',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              _getSignName(
                                (data.baseChart.rahu.longitude / 30).floor() +
                                    1,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              (data.baseChart.rahu.longitude % 30)
                                  .toStringAsFixed(2),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text(''),
                          ),
                        ],
                      ),
                      // Add Ketu
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'Ketu',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              _getSignName(
                                (data.baseChart.ketu.longitude / 30).floor() +
                                    1,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              (data.baseChart.ketu.longitude % 30)
                                  .toStringAsFixed(2),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text(''),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (navamsa != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Navamsa (D-9) Summary",
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 16),
                    // Display Navamsa positions
                    Table(
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: FluentTheme.of(
                                  context,
                                ).resources.dividerStrokeColorDefault,
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                "Planet",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: FluentTheme.of(context).accentColor,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                "Sign",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const TableRow(
                          children: [SizedBox(height: 8), SizedBox()],
                        ),
                        ...navamsa.positions.entries.map((e) {
                          final planetName = e.key;
                          final longitude = e.value;
                          final signName = _getSignName(
                            (longitude / 30).floor() + 1,
                          );
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(
                                  planetName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(signName),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanetPositionsTable(CompleteChartData data) {
    final planets = data.baseChart.planets;
    final nakshatras = AppConstants.nakshatras;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planet Positions',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(0.6),
                5: FlexColumnWidth(0.6),
                6: FlexColumnWidth(0.8),
              },
              children: [
                const TableRow(
                  children: [
                    Text(
                      'Planet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Sign', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'Degrees',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Nakshatra',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Pada', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'House',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const TableRow(
                  children: [
                    SizedBox(height: 8),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                  ],
                ),
                // Divider Row
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: FluentTheme.of(
                          context,
                        ).resources.dividerStrokeColorDefault,
                      ),
                    ),
                  ),
                  children: List.filled(7, const SizedBox(height: 4)),
                ),
                const TableRow(
                  children: [
                    SizedBox(height: 8),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                  ],
                ),
                ...planets.entries.map((entry) {
                  final planetName = entry.key.toString().split('.').last;
                  final info = entry.value;
                  final longitude = info.longitude;

                  // Sign (1-12)
                  final signIndex = (longitude / 30).floor();
                  final signName = _getSignName(signIndex + 1);

                  // Degrees within sign
                  final degInSign = longitude % 30;
                  final degrees = degInSign.floor();
                  final minutes = ((degInSign - degrees) * 60).floor();
                  final seconds = (((degInSign - degrees) * 60 - minutes) * 60)
                      .round();
                  final degStr =
                      '${degrees.toString().padLeft(2, '0')}°${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';

                  // Nakshatra (each is 13°20' = 13.333...)
                  final nakshatraIndex = (longitude / 13.333333).floor() % 27;
                  final nakshatraName = nakshatras[nakshatraIndex];

                  // Pada (4 padas per nakshatra, each 3°20' = 3.333...)
                  final padaInNakshatra =
                      ((longitude % 13.333333) / 3.333333).floor() + 1;

                  // House (approximate based on sign difference from ascendant)
                  final ascSign = _getAscendantSignInt(data.baseChart);
                  final house = ((signIndex + 1) - ascSign + 12) % 12 + 1;

                  // Status
                  List<String> status = [];
                  if (info.isRetrograde) status.add('R');
                  // Add more status if available in the data

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(planetName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(signName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(degStr),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(nakshatraName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('$padaInNakshatra'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('$house'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          status.join(' '),
                          style: TextStyle(
                            color: status.contains('R') ? Colors.orange : null,
                            fontWeight: status.isNotEmpty
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                // Add Rahu
                _buildRahuKetuTableRow(
                  'Rahu',
                  data.baseChart.rahu.longitude,
                  data.baseChart,
                  nakshatras,
                ),
                // Add Ketu
                _buildRahuKetuTableRow(
                  'Ketu',
                  data.baseChart.ketu.longitude,
                  data.baseChart,
                  nakshatras,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<int, List<String>> _getPlanetsMap(VedicChart chart) {
    final map = <int, List<String>>{};
    chart.planets.forEach((planet, info) {
      final sign = (info.longitude / 30).floor() + 1; // 1-12
      final planetName = planet.toString().split('.').last;
      String abbr = AppConstants.getPlanetAbbreviation(planetName);

      map
          .putIfAbsent(sign, () => [])
          .add(abbr + (info.isRetrograde ? "(R)" : ""));
    });

    // Add Rahu
    {
      final rahuSign = (chart.rahu.longitude / 30).floor() + 1;
      map.putIfAbsent(rahuSign, () => []).add("Ra");
    }

    // Add Ketu
    {
      final ketuSign = (chart.ketu.longitude / 30).floor() + 1;
      map.putIfAbsent(ketuSign, () => []).add("Ke");
    }

    // Ascendant
    final ascSign = _getAscendantSignInt(chart);
    map.putIfAbsent(ascSign, () => []).add("Asc");
    return map;
  }

  Map<int, List<String>> _getDivisionalPlanetsMap(DivisionalChartData chart) {
    final map = <int, List<String>>{};
    chart.positions.forEach((planetName, longitude) {
      final sign = (longitude / 30).floor() + 1; // 1-12

      String abbr = planetName.length > 2
          ? planetName.substring(0, 2)
          : planetName;
      if (planetName == 'Mars') abbr = 'Ma';
      if (planetName == 'Mercury') abbr = 'Me';
      if (planetName == 'Jupiter') abbr = 'Ju';
      if (planetName == 'Venus') abbr = 'Ve';
      if (planetName == 'Saturn') abbr = 'Sa';
      if (planetName == 'Rahu') abbr = 'Ra';
      if (planetName == 'Ketu') abbr = 'Ke';
      if (planetName == 'Sun') abbr = 'Su';
      if (planetName == 'Moon') abbr = 'Mo';

      map.putIfAbsent(sign, () => []).add(abbr);
    });
    // Ascendant
    if (chart.ascendantSign != null) {
      // ascendantSign is likely 1-12 usually.
      map.putIfAbsent(chart.ascendantSign!, () => []).add("Asc");
    }
    return map;
  }

  String _getSignName(int signNum) {
    if (signNum <= 0) signNum = signNum + 12;
    return AppConstants.signs[(signNum - 1) % 12];
  }

  int _getAscendantSignInt(VedicChart chart) {
    try {
      final houses = chart.houses;
      if (houses.cusps.isNotEmpty) {
        final long = houses.cusps[0];
        final sign = (long / 30).floor(); // 0-11
        return sign + 1; // 1-12
      }
      return 1; // Default Aries
    } catch (e) {
      return 1;
    }
  }

  String _getAscendantSign(VedicChart chart) {
    try {
      final houses = chart.houses;
      if (houses.cusps.isNotEmpty) {
        final long = houses.cusps[0];
        final sign = (long / 30).floor();
        return _getSignName(sign + 1);
      }
      return "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  TableRow _buildRahuKetuTableRow(
    String name,
    double longitude,
    VedicChart chart,
    List<String> nakshatras,
  ) {
    // Sign (1-12)
    final signIndex = (longitude / 30).floor();
    final signName = _getSignName(signIndex + 1);

    // Degrees within sign
    final degInSign = longitude % 30;
    final degrees = degInSign.floor();
    final minutes = ((degInSign - degrees) * 60).floor();
    final seconds = (((degInSign - degrees) * 60 - minutes) * 60).round();
    final degStr =
        '${degrees.toString().padLeft(2, '0')}°${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';

    // Nakshatra (each is 13°20' = 13.333...)
    final nakshatraIndex = (longitude / 13.333333).floor() % 27;
    final nakshatraName = nakshatras[nakshatraIndex];

    // Pada (4 padas per nakshatra, each 3°20' = 3.333...)
    final padaInNakshatra = ((longitude % 13.333333) / 3.333333).floor() + 1;

    // House (approximate based on sign difference from ascendant)
    final ascSign = _getAscendantSignInt(chart);
    final house = ((signIndex + 1) - ascSign + 12) % 12 + 1;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(name),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(signName),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(degStr),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(nakshatraName),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('$padaInNakshatra'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('$house'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(''), // Rahu/Ketu are never retrograde
        ),
      ],
    );
  }

  IconData _getCurrentTabIcon(int index) {
    switch (index) {
      case 0:
        return FluentIcons.contact_card;
      case 1:
        return FluentIcons.grid_view_large;
      case 2:
        return FluentIcons.scatter_chart;
      case 3:
        return FluentIcons.timer;
      case 4:
        return FluentIcons.list;
      case 5:
        return FluentIcons.lightbulb;
      default:
        return FluentIcons.chart;
    }
  }

  String _getCurrentTabTitle(int index) {
    switch (index) {
      case 0:
        return "D-1 Rashi";
      case 1:
        return "Vargas";
      case 2:
        return "KP System";
      case 3:
        return "Dasha Periods";
      case 4:
        return "Planet Details";
      case 5:
        return "Daily Rashiphal";
      default:
        return "Chart Views";
    }
  }
}
