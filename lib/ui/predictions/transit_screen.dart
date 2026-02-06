import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../logic/transit_analysis.dart';

class TransitScreen extends StatefulWidget {
  final CompleteChartData natalChart;

  const TransitScreen({super.key, required this.natalChart});

  @override
  State<TransitScreen> createState() => _TransitScreenState();
}

class _TransitScreenState extends State<TransitScreen> {
  late DateTime _selectedDate;
  late TransitAnalysis _transitAnalysis;
  TransitChart? _transitChart;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _transitAnalysis = TransitAnalysis();
    _loadTransits();
  }

  Future<void> _loadTransits() async {
    final chart = await _transitAnalysis.calculateTransitChart(
      widget.natalChart,
      _selectedDate,
    );
    if (mounted) {
      setState(() {
        _transitChart = chart;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text('Transit Analysis'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (index) => setState(() => _currentIndex = index),
        displayMode: PaneDisplayMode.top,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.clock),
            title: const Text('Current'),
            body: _buildBody(_buildCurrentTransitsTab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.switch_widget),
            title: const Text('Aspects'),
            body: _buildBody(_buildAspectsTab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.favorite_star),
            title: const Text('Special'),
            body: _buildBody(_buildSpecialTransitsTab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.calendar),
            title: const Text('Daily'),
            body: _buildBody(_buildPredictionsTab),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Widget Function() builder) {
    if (_transitChart == null) {
      return const Center(child: ProgressRing());
    }
    return ScaffoldPage(
      header: PageHeader(title: _buildDateSelector()),
      content: Padding(
        // Add padding around the content
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: builder(),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        const Text("Date: ", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 200),
          child: DatePicker(
            selected: _selectedDate,
            onChanged: (date) {
              setState(() => _selectedDate = date);
              _loadTransits();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTransitsTab() {
    final transit = _transitChart!;
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gochara Positions',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Planetary positions from natal Moon:',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ...transit.gochara.positions.entries.map((entry) {
                  final planet = entry.key.toString().split('.').last;
                  final house = entry.value;
                  final isFavorable = transit.gochara.isFavorable(entry.key);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          isFavorable
                              ? FluentIcons.completed
                              : FluentIcons.warning,
                          color: isFavorable ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            planet,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          'House $house',
                          style: TextStyle(
                            color: isFavorable ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAspectsTab() {
    final aspects = _transitChart!.aspects;

    if (aspects.isEmpty) {
      return const Center(child: Text('No major aspects at this time'));
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: aspects.map((aspect) {
        final tPlanet = aspect.transitPlanet.toString().split('.').last;
        final nPlanet = aspect.natalPlanet.toString().split('.').last;
        final aspectName = aspect.aspectType.toString().split('.').last;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Card(
            child: ListTile(
              leading: Icon(
                _getAspectIcon(aspect.aspectType),
                color: _getAspectColor(aspect.aspectType),
              ),
              title: Text('$tPlanet $aspectName $nPlanet'),
              subtitle: Text(
                'Orb: ${aspect.orb.toStringAsFixed(1)}° • ${aspect.isApplying ? "Applying" : "Separating"}\n'
                '${aspect.effect.nature.join(", ")}',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecialTransitsTab() {
    final transit = _transitChart!;

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        // Moon Transit
        _buildSpecialTransitCard(
          'Moon Transit',
          FluentIcons.clear_night,
          Colors.blue,
          [
            'Nakshatra: ${transit.moonTransit.nakshatra}',
            'Tithi: ${transit.moonTransit.tithi}',
            'House: ${transit.moonTransit.houseFromNatalMoon} from natal Moon',
            'Status: ${transit.moonTransit.isFavorable ? "Favorable" : "Challenging"}',
          ],
          transit.moonTransit.recommendations,
        ),

        // Saturn Transit
        _buildSpecialTransitCard(
          'Saturn Transit',
          FluentIcons.circle_ring,
          Colors.purple,
          [
            'House: ${transit.saturnTransit.houseFromMoon} from natal Moon',
            if (transit.saturnTransit.isSadeSati)
              'Sade Sati: ${transit.saturnTransit.sadeSatiPhase.toString().split('.').last}',
            if (transit.saturnTransit.kantakaShani) 'Kantaka Shani Active',
            if (transit.saturnTransit.isRetrograde) 'Retrograde',
            ...transit.saturnTransit.effects,
          ],
          transit.saturnTransit.recommendations,
        ),

        // Jupiter Transit
        _buildSpecialTransitCard(
          'Jupiter Transit',
          FluentIcons.asterisk,
          Colors.yellow,
          [
            'House: ${transit.jupiterTransit.houseFromMoon} from natal Moon',
            'Status: ${transit.jupiterTransit.isBenefic ? "Benefic" : "Challenging"}',
            ...transit.jupiterTransit.effects,
          ],
          transit.jupiterTransit.recommendations,
        ),

        // Rahu-Ketu Transit
        _buildSpecialTransitCard(
          'Rahu-Ketu Transit',
          FluentIcons.sync_occurence,
          Colors.purple,
          [
            'Rahu in sign ${transit.rahuKetuTransit.rahuSign + 1}',
            'Ketu in sign ${transit.rahuKetuTransit.ketuSign + 1}',
            if (transit.rahuKetuTransit.affectedNatalPlanets.isNotEmpty)
              'Affecting: ${transit.rahuKetuTransit.affectedNatalPlanets.join(", ")}',
            ...transit.rahuKetuTransit.effects,
          ],
          transit.rahuKetuTransit.recommendations,
        ),
      ],
    );
  }

  Widget _buildSpecialTransitCard(
    String title,
    IconData icon,
    Color color,
    List<String> details,
    List<String> recommendations,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Expander(
        header: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details.isNotEmpty) ...[
              const Text(
                'Details:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(detail)),
                    ],
                  ),
                ),
              ),
            ],
            if (recommendations.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Recommendations:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...recommendations.map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(FluentIcons.chevron_right_small, size: 16),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionsTab() {
    final transit = _transitChart!;
    final dailyPrediction = _transitAnalysis.getDailyPrediction(
      transit.moonTransit,
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        Card(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FluentIcons.favorite_star, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Daily Guidance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(dailyPrediction, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'General Timing Advice',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const SizedBox(height: 12),
                _buildTimingAdvice(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimingAdvice() {
    final transit = _transitChart!;
    final advice = <String>[];

    final favorableAspects = transit.aspects
        .where(
          (a) =>
              a.aspectType == AspectType.trine ||
              a.aspectType == AspectType.sextile,
        )
        .length;

    if (favorableAspects > 2) {
      advice.add('✓ Good time for new ventures and collaborations');
    }

    final challengingAspects = transit.aspects
        .where(
          (a) =>
              a.aspectType == AspectType.square ||
              a.aspectType == AspectType.opposition,
        )
        .length;

    if (challengingAspects > 2) {
      advice.add('⚠ Exercise caution with major decisions');
    }

    if (transit.jupiterTransit.isBenefic) {
      advice.add('✓ Favorable for learning and spiritual growth');
    }

    if (transit.saturnTransit.isSadeSati) {
      advice.add('⚠ Focus on discipline and long-term planning');
    }

    if (advice.isEmpty) {
      advice.add('Proceed with normal caution and awareness');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: advice
          .map(
            (text) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(text, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
    );
  }

  IconData _getAspectIcon(AspectType type) {
    switch (type) {
      case AspectType.conjunction:
        return FluentIcons.radio_bullet;
      case AspectType.opposition:
        return FluentIcons.sync_occurence;
      case AspectType.square:
        return FluentIcons.checkbox;
      case AspectType.trine:
        return FluentIcons.triangle_solid;
      case AspectType.sextile:
        return FluentIcons.hexagon;
    }
  }

  Color _getAspectColor(AspectType type) {
    switch (type) {
      case AspectType.conjunction:
        return Colors.purple;
      case AspectType.opposition:
        return Colors.red;
      case AspectType.square:
        return Colors.orange;
      case AspectType.trine:
        return Colors.green;
      case AspectType.sextile:
        return Colors.blue;
    }
  }
}
