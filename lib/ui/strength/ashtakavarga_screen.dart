import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../logic/ashtakavarga.dart';

class AshtakavargaScreen extends StatefulWidget {
  final CompleteChartData chartData;

  const AshtakavargaScreen({super.key, required this.chartData});

  @override
  State<AshtakavargaScreen> createState() => _AshtakavargaScreenState();
}

class _AshtakavargaScreenState extends State<AshtakavargaScreen> {
  int _currentIndex = 0;
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
  Widget build(BuildContext context) {
    try {
      AshtakavargaSystem.calculateSarvashtakavargaWithSodhana(
        widget.chartData.baseChart,
      );
      AshtakavargaSystem.calculateBhinnashtakavarga(
        widget.chartData.baseChart,
        _selectedPlanet,
      );
    } catch (e) {
      if (context.mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Calculation Error'),
            content: Text('Failed to calculate Ashtakavarga: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }

    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text('Ashtakavarga Analysis'),
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
            icon: const Icon(FluentIcons.table),
            title: const Text('Sarvashtakavarga'),
            body: _buildBody(_buildSarvashtakavargaTab()),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.pie_single),
            title: const Text('Bhinnashtakavarga'),
            body: _buildBody(_buildBhinnashtakavargaTab()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Widget content) {
    return ScaffoldPage(
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: content,
        ),
      ),
    );
  }

  Widget _buildSarvashtakavargaTab() {
    final sarva = _showSodhana
        ? AshtakavargaSystem.calculateSarvashtakavargaWithSodhana(
            widget.chartData.baseChart,
          )
        : AshtakavargaSystem.calculateSarvashtakavarga(
            widget.chartData.baseChart,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Educational info
        Card(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FluentIcons.info, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
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
                  'Sarvashtakavarga shows the total benefic points for each sign from all seven planets. '
                  'Higher points indicate more favorable results. Average is 28 points per sign.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Sodhana toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Apply Sodhana (Reduction)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ToggleSwitch(
              checked: _showSodhana,
              onChanged: (value) {
                setState(() {
                  _showSodhana = value;
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Points table
        _buildPointsTable(sarva),

        const SizedBox(height: 16),

        // Sign strengths heat map
        _buildHeatMap(sarva),
      ],
    );
  }

  Widget _buildBhinnashtakavargaTab() {
    final bhinna = AshtakavargaSystem.calculateBhinnashtakavarga(
      widget.chartData.baseChart,
      _selectedPlanet,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Educational info
        Card(
          backgroundColor: Colors.purple.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FluentIcons.info, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Text(
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
                  'Bhinnashtakavarga shows benefic points contributed by a single planet. '
                  'Range is 0-8. 4 points is average strength for a house.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Planet selector
        const Text(
          'Select Planet:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _planets.map((planet) {
            final isSelected = _selectedPlanet == planet;
            return Button(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                  isSelected ? Colors.purple.withValues(alpha: 0.1) : null,
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedPlanet = planet;
                });
              },
              child: Text(planet),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Points list for planet
        _buildPointsTable(bhinna, isBhinna: true),

        const SizedBox(height: 16),

        // Heat map
        _buildHeatMap(bhinna, isBhinna: true),
      ],
    );
  }

  Widget _buildPointsTable(Map<int, int> pointsMap, {bool isBhinna = false}) {
    return Card(
      child: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        children: [
          // Header
          const TableRow(
            decoration: BoxDecoration(color: Color(0x0A000000)),
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Sign Name',
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
            final points = pointsMap[index] ?? 0;

            Color statusColor;
            String statusText;

            if (isBhinna) {
              if (points >= 6) {
                statusText = 'Very Strong';
                statusColor = Colors.green;
              } else if (points >= 4) {
                statusText = 'Strong';
                statusColor = Colors.teal;
              } else if (points >= 3) {
                statusText = 'Average';
                statusColor = Colors.orange;
              } else {
                statusText = 'Weak';
                statusColor = Colors.red;
              }
            } else {
              // Sarva logic
              if (points >= 32) {
                statusText = 'Very Strong';
                statusColor = Colors.green;
              } else if (points >= 28) {
                statusText = 'Strong';
                statusColor = Colors.teal;
              } else if (points >= 25) {
                statusText = 'Average';
                statusColor = Colors.orange;
              } else {
                statusText = 'Weak';
                statusColor = Colors.red;
              }
            }

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
                    statusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: statusColor),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeatMap(Map<int, int> points, {bool isBhinna = false}) {
    // Determine max for normalization
    final maxValue = isBhinna ? 8.0 : 40.0;
    final color = isBhinna ? Colors.purple : Colors.blue;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Distribution Visualization',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(12, (index) {
                final pt = points[index] ?? 0;
                final intensity = (pt / maxValue).clamp(0.0, 1.0);
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: intensity),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _signNames[index].substring(0, 3),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: intensity > 0.5 ? Colors.white : Colors.black,
                        ),
                      ),
                      Text(
                        pt.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: intensity > 0.5 ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
