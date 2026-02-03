import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../logic/transit_analysis.dart';
import 'package:intl/intl.dart';

class TransitScreen extends StatefulWidget {
  final CompleteChartData natalChart;

  const TransitScreen({super.key, required this.natalChart});

  @override
  State<TransitScreen> createState() => _TransitScreenState();
}

class _TransitScreenState extends State<TransitScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedDate;
  late TransitAnalysis _transitAnalysis;
  TransitChart? _transitChart;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedDate = DateTime.now();
    _transitAnalysis = TransitAnalysis();
    _loadTransits();
  }

  Future<void> _loadTransits() async {
    final chart = await _transitAnalysis.calculateTransitChart(
      widget.natalChart,
      _selectedDate,
    );
    setState(() {
      _transitChart = chart;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit Analysis'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Current', icon: Icon(Icons.schedule, size: 20)),
            Tab(text: 'Aspects', icon: Icon(Icons.aspect_ratio, size: 20)),
            Tab(text: 'Special', icon: Icon(Icons.star, size: 20)),
            Tab(text: 'Daily', icon: Icon(Icons.calendar_today, size: 20)),
          ],
        ),
      ),
      body: _transitChart == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildDateSelector(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCurrentTransitsTab(),
                      _buildAspectsTab(),
                      _buildSpecialTransitsTab(),
                      _buildPredictionsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDateSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_calendar),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                  });
                  _loadTransits();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTransitsTab() {
    final transit = _transitChart!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gochara Positions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                          isFavorable ? Icons.check_circle : Icons.warning,
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
      padding: const EdgeInsets.all(16),
      children: aspects.map((aspect) {
        final tPlanet = aspect.transitPlanet.toString().split('.').last;
        final nPlanet = aspect.natalPlanet.toString().split('.').last;
        final aspectName = aspect.aspectType.toString().split('.').last;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
            isThreeLine: true,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecialTransitsTab() {
    final transit = _transitChart!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Moon Transit
        _buildSpecialTransitCard(
          'Moon Transit',
          Icons.nightlight,
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
          Icons.ring_volume,
          Colors.indigo,
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
          Icons.auto_awesome,
          Colors.yellow.shade700,
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
          Icons.change_circle,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                          const Icon(Icons.arrow_right, size: 16),
                          Expanded(child: Text(rec)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab() {
    final transit = _transitChart!;
    final dailyPrediction = _transitAnalysis.getDailyPrediction(
      transit.moonTransit,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
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
                const Text(
                  'General Timing Advice',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

    // Check favorable aspects
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

    // Check challenging aspects
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

    // Jupiter advice
    if (transit.jupiterTransit.isBenefic) {
      advice.add('✓ Favorable for learning and spiritual growth');
    }

    // Saturn advice
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
        return Icons.radio_button_checked;
      case AspectType.opposition:
        return Icons.sync_alt;
      case AspectType.square:
        return Icons.crop_square;
      case AspectType.trine:
        return Icons.change_history;
      case AspectType.sextile:
        return Icons.hexagon_outlined;
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
