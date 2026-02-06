import 'package:fluent_ui/fluent_ui.dart';
import '../../logic/horary_service.dart';
import 'package:jyotish/jyotish.dart';

import '../../core/ephemeris_manager.dart';
import '../../data/models.dart';

class HoraryResultScreen extends StatefulWidget {
  final int seedNumber;
  final DateTime dateTime;
  final GeographicLocation location;
  final String locationName;

  const HoraryResultScreen({
    Key? key,
    required this.seedNumber,
    required this.dateTime,
    required this.location,
    required this.locationName,
  }) : super(key: key);

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
    // 1. Generate base Horary Chart (mixed Asc + Planets)
    final vedicChart = await _horaryService.generateHoraryChart(
      seedNumber: widget.seedNumber,
      dateTime: widget.dateTime,
      location: widget.location,
    );

    // 2. Generate KP Data on top of it
    // The KPChartService usually re-calculates, but we exposed methods?
    // Actually KPChartService.generateCompleteChart takes BirthData and does everything from scratch.
    // We need a way to reuse KP logic on an EXISTING chart.
    // I need to add a helper in KPChartService or replicate logic here.
    // For now, let's replicate the mapping logic quickly or trust I can refactor KPChartService later.
    // Let's implement a private helper in KPChartService or just map it here to avoid modifying core unnecessarily right now.

    // Actually, KPChartService methods are private or rigid.
    // BUT we have `EphemerisManager.jyotish.calculateKPData`.
    final nativeKP = await EphemerisManager.jyotish.calculateKPData(vedicChart);

    // Map manually (similar to KPChartService)
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

    // Houses
    final houseLords = <int, KPSubLord>{};
    nativeKP.houseDivisions.forEach((houseNum, houseDiv) {
      houseLords[houseNum] = KPSubLord(
        starLord: houseDiv.starLord.displayName,
        subLord: houseDiv.subLord.displayName,
        subSubLord: houseDiv.subSubLord?.displayName ?? '--',
        nakshatraName: '', // Not strictly needed for house row usually
      );
    });

    final kpData = KPData(
      subLords: subLords,
      significators: [], // TODO: Populate if needed
      rulingPlanets: [], // TODO: Populate
    );

    // For now returning a partial object just to display minimal data
    return CompleteChartData(
      baseChart: vedicChart,
      kpData: kpData,
      dashaData: DashaData(
        // Placeholder
        vimshottari: VimshottariDasha(
          birthLord: 'N/A',
          balanceAtBirth: 0,
          mahadashas: [],
        ),
        yogini: YoginiDasha(startYogini: '', mahadashas: []),
        chara: CharaDasha(startSign: 1, periods: []),
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text('Horary Result - Seed ${widget.seedNumber}'),
      ),
      content: FutureBuilder<CompleteChartData>(
        future: _chartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ProgressRing());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chart = snapshot.data!;
          final ascendant = chart.baseChart.houses.ascendant;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ascendant Longitude: ${ascendant.toStringAsFixed(4)}'),
                const SizedBox(height: 20),
                const Text(
                  'Chart generation successful. (Visuals coming soon)',
                ),

                // Simple debugging list of planets
                ...chart.baseChart.planets.entries.map(
                  (e) => Text(
                    '${e.key.name}: ${e.value.position.longitude.toStringAsFixed(2)} (${e.value.house}H)',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
