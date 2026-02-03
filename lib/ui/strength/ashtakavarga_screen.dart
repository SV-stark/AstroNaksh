import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../logic/ashtakavarga.dart';
import '../widgets/strength_meter.dart';

class AshtakavargaScreen extends StatefulWidget {
  final CompleteChartData chartData;

  const AshtakavargaScreen({super.key, required this.chartData});

  @override
  State<AshtakavargaScreen> createState() => _AshtakavargaScreenState();
}

class _AshtakavargaScreenState extends State<AshtakavargaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPlanet = 'Sun';
  bool _showSodhana = false;

  final List<String> _planets = [
    'Sun',
    'Moon',
    'Mars',
    'Mercury',
    'Jupiter',
    'Venus',
    'Saturn',
  ];

  final List<String> _signNames = [
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('Ashtakavarga Analysis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sarvashtakavarga'),
            Tab(text: 'Bhinnashtakavarga'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSarvashtakavargaTab(), _buildBhinnashtakavargaTab()],
      ),
    );
  }

  Widget _buildSarvashtakavargaTab() {
    final sarva = _showSodhana
        ? AshtakavargaSystem.calculateSarvashtakavargaWithSodhana(
            widget.chartData,
          )
        : AshtakavargaSystem.calculateSarvashtakavarga(widget.chartData);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Educational info
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'About Sarvashtakavarga',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sarvashtakavarga shows the total benefic points (0-8) for each sign from all seven planets. '
                    'Higher points indicate more favorable results. Signs with 4+ points are generally favorable.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Sodhana toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Apply Sodhana (Reduction)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _showSodhana,
                  onChanged: (value) {
                    setState(() {
                      _showSodhana = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Points table
          _buildPointsTable(sarva),

          const SizedBox(height: 16),

          // Visual heat map
          _buildHeatMap(sarva),

          const SizedBox(height: 16),

          // Summary
          _buildSummary(sarva),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPointsTable(Map<int, int> sarva) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Points Distribution',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                // Header
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Sign',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Points',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                // Data rows
                ...List.generate(12, (index) {
                  final points = sarva[index] ?? 0;
                  final status = points >= 5
                      ? 'Very Good'
                      : points >= 4
                      ? 'Good'
                      : points >= 3
                      ? 'Moderate'
                      : 'Weak';
                  final statusColor = points >= 5
                      ? Colors.green
                      : points >= 4
                      ? Colors.lightGreen
                      : points >= 3
                      ? Colors.orange
                      : Colors.red;

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(_signNames[index]),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          points.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          status,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: statusColor),
                        ),
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

  Widget _buildHeatMap(Map<int, int> sarva) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visual Heat Map',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final points = sarva[index] ?? 0;
                final intensity = points / 8.0;
                return Container(
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      Colors.red.shade100,
                      Colors.green.shade400,
                      intensity,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _signNames[index],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        points.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(Map<int, int> sarva) {
    final totalPoints = sarva.values.reduce((a, b) => a + b);
    final avgPoints = totalPoints / 12;
    final strongSigns = sarva.entries
        .where((e) => e.value >= 5)
        .map((e) => e.key)
        .toList();
    final weakSigns = sarva.entries
        .where((e) => e.value < 3)
        .map((e) => e.key)
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Total Points', totalPoints.toString()),
            _buildSummaryRow('Average Points', avgPoints.toStringAsFixed(2)),
            _buildSummaryRow(
              'Strong Signs (5+)',
              strongSigns.map((i) => _signNames[i]).join(', '),
            ),
            _buildSummaryRow(
              'Weak Signs (<3)',
              weakSigns.map((i) => _signNames[i]).join(', '),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildBhinnashtakavargaTab() {
    final bhinna = AshtakavargaSystem.calculateBhinnashtakavarga(
      widget.chartData,
      _selectedPlanet,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Educational info
          Card(
            margin: const EdgeInsets.all(16),
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'About Bhinnashtakavarga',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bhinnashtakavarga shows benefic points for a specific planet across all 12 signs. '
                    'These points help determine when and where a planet will give good results.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Planet selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: _selectedPlanet,
              decoration: const InputDecoration(
                labelText: 'Select Planet',
                border: OutlineInputBorder(),
              ),
              items: _planets.map((planet) {
                return DropdownMenuItem(value: planet, child: Text(planet));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPlanet = value;
                  });
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // Planet-specific points table
          _buildBhinnaPointsTable(bhinna),

          const SizedBox(height: 16),

          // Favorable/Unfavorable signs
          _buildFavorableUnfavorable(bhinna),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildBhinnaPointsTable(Map<int, int> bhinna) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_selectedPlanet Bhinnashtakavarga',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...List.generate(12, (index) {
              final points = bhinna[index] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 100, child: Text(_signNames[index])),
                    Expanded(
                      child: StrengthMeter(
                        value: (points / 8.0) * 100,
                        label: '$points points',
                        showPercentage: false,
                      ),
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

  Widget _buildFavorableUnfavorable(Map<int, int> bhinna) {
    final favorable = bhinna.entries
        .where((e) => e.value >= 4)
        .map((e) => e.key)
        .toList();
    final unfavorable = bhinna.entries
        .where((e) => e.value < 3)
        .map((e) => e.key)
        .toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analysis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Favorable Signs:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              favorable.isEmpty
                  ? 'None'
                  : favorable.map((i) => _signNames[i]).join(', '),
              style: const TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.cancel, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Unfavorable Signs:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              unfavorable.isEmpty
                  ? 'None'
                  : unfavorable.map((i) => _signNames[i]).join(', '),
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
