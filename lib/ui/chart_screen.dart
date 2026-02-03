import 'package:fluent_ui/fluent_ui.dart';
import 'widgets/chart_widget.dart';
import '../../data/models.dart';
import '../../logic/kp_chart_service.dart';

import 'package:jyotish/jyotish.dart';
import '../../core/ayanamsa_calculator.dart';
import '../../core/chart_customization.dart' hide ChartStyle;
import 'tools/birth_time_rectifier_screen.dart';
// New analysis screens
import 'strength/ashtakavarga_screen.dart';
import 'strength/shadbala_screen.dart';
import 'strength/bhava_bala_screen.dart';
import 'analysis/yoga_dosha_screen.dart';
import 'predictions/transit_screen.dart';
import 'predictions/varshaphal_screen.dart';
import 'analysis/retrograde_screen.dart';
import 'comparison/chart_comparison_screen.dart';
import 'reports/pdf_report_screen.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_birthData == null) {
      final args = ModalRoute.of(context)?.settings.arguments as BirthData?;
      if (args != null) {
        _birthData = args;
        _loadChartData();
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
        return ContentDialog(
          title: const Text('Select Ayanamsa'),
          content: SizedBox(
            height: 300, // Limit height
            child: ListView.builder(
              itemCount: AyanamsaCalculator.systems.length,
              itemBuilder: (context, index) {
                final system = AyanamsaCalculator.systems[index];
                final isSelected =
                    SettingsManager.current.ayanamsaSystem.toLowerCase() ==
                    system.name.toLowerCase();

                return ListTile.selectable(
                  selected: isSelected,
                  title: Text(system.name),
                  subtitle: Text(system.description),
                  onPressed: () {
                    SettingsManager.current.ayanamsaSystem = system.name;
                    Navigator.pop(context);
                    _loadChartData();
                  },
                );
              },
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
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text("Vedic Chart"),
        actions: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.settings),
              label: const Text('Ayanamsa'),
              onPressed: _openAyanamsaSelection,
            ),
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
            CommandBarButton(
              icon: const Icon(FluentIcons.build),
              label: const Text('Rectify'),
              onPressed: () async {
                if (_birthData == null) return;
                // Currently screens are Material. Use Navigator to push.
                // Assuming BirthTimeRectifierScreen uses Material structure, it might look odd but work.
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
          secondaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.analytics_view),
              label: const Text('Tools & Analysis'),
              onPressed: () {}, // Handled by flyout below?
              // Better to use a DropDownButton in primary or just list them.
              // Let's make this a flyout menu.
            ),
            // Actually, implementing a Flyout attached to a CommandBarButton requires logic.
            // Simpler: Just put analysis tools in a "More" menu or separate buttons if space permits.
            // Let's list major tools in secondary?
            CommandBarButton(
              icon: const Icon(FluentIcons.grid_view_small),
              label: const Text('Ashtakavarga'),
              onPressed: () => _navigateTo('ashtakavarga'),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.favorite_star),
              label: const Text('Shadbala'),
              onPressed: () => _navigateTo('shadbala'),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.home),
              label: const Text('Bhava Bala'),
              onPressed: () => _navigateTo('bhava_bala'),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.scale_volume), // Yoga/Dosha
              label: const Text('Yoga & Dosha'),
              onPressed: () => _navigateTo('yoga_dosha'),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.history),
              label: const Text('Transit'),
              onPressed: () => _navigateTo('transit'),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.calendar),
              label: const Text('Varshaphal'),
              onPressed: () => _navigateTo('varshaphal'),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.repeat_one),
              label: const Text('Retrograde'),
              onPressed: () => _navigateTo('retrograde'),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.compare),
              label: const Text('Comparison'),
              onPressed: () => _navigateTo('comparison'),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.pdf),
              label: const Text('PDF Report'),
              onPressed: () => _navigateTo('pdf_report'),
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
            icon: const Icon(FluentIcons.contact_card),
            title: const Text("D-1"),
            body: _buildBody(_buildD1Tab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.grid_view_large),
            title: const Text("Vargas"),
            body: _buildBody(_buildVargasTab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.scatter_chart),
            title: const Text("KP"),
            body: _buildBody(_buildKPTab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.timer),
            title: const Text("Dasha"),
            body: _buildBody(_buildDashaTab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.list),
            title: const Text("Details"),
            body: _buildBody(_buildDetailsTab),
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
          return Center(child: Text("Error: ${snapshot.error}"));
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
          ChartWidget(
            planetsBySign: planetsMap,
            ascendantSign: ascSign,
            style: _style,
            size: 350,
          ),
          const SizedBox(height: 16),
          _buildPlanetPositionsTable(data),
        ],
      ),
    );
  }

  Widget _buildVargasTab(CompleteChartData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Divisional Charts (Vargas)",
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                      (code) => ToggleButton(
                        checked: _selectedDivisionalChart == code,
                        onChanged: (selected) {
                          if (selected) {
                            setState(() => _selectedDivisionalChart = code);
                          }
                        },
                        child: Text(code),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  children: const [
                    Text(
                      "Planet",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Nakshatra",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Star Lord",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Sub Lord",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Sub-Sub",
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
                  ],
                ), // Spacing
                ...data.significatorTable.entries.map((entry) {
                  final planet = entry.key;
                  final info = entry.value;
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(planet),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(info['nakshatra'] ?? ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(info['starLord'] ?? ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(info['subLord'] ?? ''),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
            const SizedBox(height: 10),
            ...data.significatorTable.entries.map((entry) {
              final planet = entry.key;
              final info = entry.value;
              final significations =
                  info['significations'] as List<dynamic>? ?? [];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        planet,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text("Houses: ${significations.join(', ')}"),
                    ),
                  ],
                ),
              );
            }),
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
          _buildVimshottariDashaCard(data.dashaData.vimshottari),
          const SizedBox(height: 16),
          // Not displaying Yogini/Chara to save space for now, or add back if needed.
          // keeping implementation concise.
        ],
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
              (maha) => Expander(
                header: Text("${maha.lord} - ${maha.formattedPeriod}"),
                content: Column(
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
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(CompleteChartData data) {
    final planets = data.baseChart.planets;
    final navamsa = data.divisionalCharts['D-9'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
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
                      3: FlexColumnWidth(1),
                    },
                    children: [
                      const TableRow(
                        children: [
                          Text(
                            "Planet",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Sign",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Long",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "R",
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
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(planetName),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(signName),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(normLongitude.toStringAsFixed(2)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(info.isRetrograde ? "R" : ""),
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
                        const TableRow(
                          children: [
                            Text(
                              "Planet",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Sign",
                              style: TextStyle(fontWeight: FontWeight.bold),
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
                                  vertical: 4,
                                ),
                                child: Text(planetName),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
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
    return const SizedBox.shrink();
  }

  Map<int, List<String>> _getPlanetsMap(VedicChart chart) {
    final map = <int, List<String>>{};
    chart.planets.forEach((planet, info) {
      final sign = (info.longitude / 30).floor() + 1; // 1-12
      final planetName = planet.toString().split('.').last;
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

      map
          .putIfAbsent(sign, () => [])
          .add(abbr + (info.isRetrograde ? "(R)" : ""));
    });
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
    const signs = [
      "Aries",
      "Taurus",
      "Gemini",
      "Cancer",
      "Leo",
      "Virgo",
      "Libra",
      "Scorpio",
      "Sagittarius",
      "Capricorn",
      "Aquarius",
      "Pisces",
    ];
    if (signNum <= 0) signNum = signNum + 12;
    return signs[(signNum - 1) % 12];
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
}
