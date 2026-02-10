import 'package:fluent_ui/fluent_ui.dart';
import '../../logic/horary_service.dart';
import 'package:jyotish/jyotish.dart';
import '../../core/ephemeris_manager.dart';
import '../../core/responsive_helper.dart';
import '../../core/settings_manager.dart';
import '../../data/models.dart';
import '../widgets/chart_widget.dart';

class HoraryResultScreen extends StatefulWidget {
  final int seedNumber;
  final DateTime dateTime;
  final GeographicLocation location;
  final String locationName;

  const HoraryResultScreen({
    super.key,
    required this.seedNumber,
    required this.dateTime,
    required this.location,
    required this.locationName,
  });

  @override
  State<HoraryResultScreen> createState() => _HoraryResultScreenState();
}

class _HoraryResultScreenState extends State<HoraryResultScreen> {
  final HoraryService _horaryService = HoraryService();

  late Future<CompleteChartData> _chartFuture;

  @override
  void initState() {
    super.initState();
    _chartFuture = _calculateChart();
  }

  Future<CompleteChartData> _calculateChart() async {
    final vedicChart = await _horaryService.generateHoraryChart(
      seedNumber: widget.seedNumber,
      dateTime: widget.dateTime,
      location: widget.location,
    );

    final nativeKP = await EphemerisManager.jyotish.calculateKPData(vedicChart);

    final List<KPSubLord> subLords = [];
    vedicChart.planets.forEach((planet, info) {
      final planetKP = nativeKP.planetDivisions[planet];
      if (planetKP != null) {
        subLords.add(
          KPSubLord(
            starLord: planetKP.starLord.displayName,
            subLord: planetKP.subLord.displayName,
            subSubLord: planetKP.subSubLord?.displayName ?? '--',
            nakshatraName: info.nakshatra,
          ),
        );
      }
    });

    final houseLords = <int, KPSubLord>{};
    nativeKP.houseDivisions.forEach((houseNum, houseDiv) {
      houseLords[houseNum] = KPSubLord(
        starLord: houseDiv.starLord.displayName,
        subLord: houseDiv.subLord.displayName,
        subSubLord: houseDiv.subSubLord?.displayName ?? '--',
        nakshatraName: '',
      );
    });

    final kpData = KPData(
      subLords: subLords,
      significators: [],
      rulingPlanets: [],
    );

    return CompleteChartData(
      baseChart: vedicChart,
      kpData: kpData,
      dashaData: DashaData(
        vimshottari: VimshottariDasha(
          birthLord: 'N/A',
          balanceAtBirth: 0,
          mahadashas: [],
        ),
        yogini: YoginiDasha(startYogini: '', mahadashas: []),
        chara: CharaDasha(startSign: 1, periods: []),
        narayana: NarayanaDasha(startSign: 0, periods: []),
      ),
      divisionalCharts: {},
      significatorTable: {},
      birthData: BirthData(
        dateTime: widget.dateTime,
        location: Location(
          latitude: widget.location.latitude,
          longitude: widget.location.longitude,
        ),
      ),
    );
  }

  Map<int, List<String>> _getPlanetsMap(VedicChart chart) {
    final map = <int, List<String>>{};
    chart.planets.forEach((p, info) {
      final sign = (info.longitude / 30).floor() + 1;
      map.putIfAbsent(sign, () => []).add(p.toString().split('.').last);
    });
    return map;
  }

  int _getAscendantSign(VedicChart chart) {
    return (chart.houses.ascendant / 30).floor() + 1;
  }

  String _getSignName(int sign) {
    const signs = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces',
    ];
    if (sign >= 1 && sign <= 12) return signs[sign - 1];
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);
    final chartSize = ResponsiveHelper.getChartSize(context);

    return ScaffoldPage(
      header: PageHeader(
        title: Text('Horary Chart — Seed #${widget.seedNumber}'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: FutureBuilder<CompleteChartData>(
        future: _chartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProgressRing(),
                  SizedBox(height: 16),
                  Text('Generating horary chart...'),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  Button(
                    onPressed: () => setState(() {
                      _chartFuture = _calculateChart();
                    }),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final chart = snapshot.data!;
          final planetsMap = _getPlanetsMap(chart.baseChart);
          final ascSign = _getAscendantSign(chart.baseChart);
          final ascSignName = _getSignName(ascSign);
          final style =
              SettingsManager().chartSettings.chartStyle.name == 'northIndian'
              ? ChartStyle.northIndian
              : ChartStyle.southIndian;

          return SingleChildScrollView(
            padding: context.responsiveBodyPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card with query info
                _buildQueryInfoCard(context, ascSignName),
                const SizedBox(height: 20),

                // Chart + Planet table side by side on desktop, stacked on mobile
                if (isMobile) ...[
                  Center(
                    child: ChartWidget(
                      planetsBySign: planetsMap,
                      ascendantSign: ascSign,
                      style: style,
                      size: chartSize,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPlanetPositionsTable(context, chart.baseChart),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChartWidget(
                        planetsBySign: planetsMap,
                        ascendantSign: ascSign,
                        style: style,
                        size: chartSize,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildPlanetPositionsTable(
                          context,
                          chart.baseChart,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // KP Sub-Lords table
                if (chart.kpData.subLords.isNotEmpty)
                  _buildKPSubLordsCard(context, chart),

                const SizedBox(height: 24),

                // House cusps
                _buildHouseCuspsCard(context, chart.baseChart),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQueryInfoCard(BuildContext context, String ascSignName) {
    return Card(
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
                  color: FluentTheme.of(context).accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  FluentIcons.chat,
                  color: FluentTheme.of(context).accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prashna (Horary) Chart',
                      style: FluentTheme.of(context).typography.subtitle
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Seed Number: ${widget.seedNumber}',
                      style: FluentTheme.of(
                        context,
                      ).typography.caption?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                context,
                FluentIcons.calendar,
                'Date',
                '${widget.dateTime.day}/${widget.dateTime.month}/${widget.dateTime.year}',
              ),
              _buildInfoChip(
                context,
                FluentIcons.clock,
                'Time',
                '${widget.dateTime.hour.toString().padLeft(2, '0')}:${widget.dateTime.minute.toString().padLeft(2, '0')}',
              ),
              _buildInfoChip(
                context,
                FluentIcons.location,
                'Location',
                widget.locationName,
              ),
              _buildInfoChip(
                context,
                FluentIcons.home,
                'Ascendant',
                ascSignName,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: FluentTheme.of(
            context,
          ).typography.caption?.copyWith(color: Colors.grey),
        ),
        Text(
          value,
          style: FluentTheme.of(
            context,
          ).typography.body?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPlanetPositionsTable(BuildContext context, VedicChart chart) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planet Positions',
            style: FluentTheme.of(
              context,
            ).typography.bodyStrong?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(2),
            },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.withAlpha(40),
                width: 0.5,
              ),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor.withAlpha(15),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      'Planet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      'Sign',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      'House',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      'Nakshatra',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              ...chart.planets.entries.map((e) {
                final planetName = e.key.toString().split('.').last;
                final info = e.value;
                final sign = (info.longitude / 30).floor() + 1;
                final retroLabel = info.isRetrograde ? ' (R)' : '';
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Text(
                        '$planetName$retroLabel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: info.isRetrograde ? Colors.red : null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Text(
                        '${_getSignName(sign)} ${(info.longitude % 30).toStringAsFixed(1)}°',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Text(
                        '${info.house}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Text(
                        info.nakshatra,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKPSubLordsCard(BuildContext context, CompleteChartData chart) {
    final planets = chart.baseChart.planets.keys.toList();

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KP Sub-Lords',
            style: FluentTheme.of(
              context,
            ).typography.bodyStrong?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
            },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.withAlpha(40),
                width: 0.5,
              ),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor.withAlpha(15),
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      'Planet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      'Star Lord',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      'Sub Lord',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Text(
                      'Sub-Sub Lord',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              ...List.generate(chart.kpData.subLords.length, (i) {
                final sub = chart.kpData.subLords[i];
                final planetName = i < planets.length
                    ? planets[i].toString().split('.').last
                    : 'Planet ${i + 1}';
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Text(
                        planetName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Text(
                        sub.starLord,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Text(
                        sub.subLord,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Text(
                        sub.subSubLord,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHouseCuspsCard(BuildContext context, VedicChart chart) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'House Cusps',
            style: FluentTheme.of(
              context,
            ).typography.bodyStrong?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (i) {
              final houseNum = i + 1;
              final cusp = chart.houses.cusps[houseNum];
              final sign = (cusp / 30).floor() + 1;
              final degree = cusp % 30;
              return SizedBox(
                width: ResponsiveHelper.useMobileLayout(context) ? 160 : 120,
                child: Card(
                  padding: const EdgeInsets.all(8),
                  backgroundColor: FluentTheme.of(
                    context,
                  ).accentColor.withAlpha(8),
                  child: Column(
                    children: [
                      Text(
                        'H$houseNum',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: FluentTheme.of(context).accentColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_getSignName(sign)} ${degree.toStringAsFixed(1)}°',
                        style: const TextStyle(fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
