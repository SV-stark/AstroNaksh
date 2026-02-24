import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';
import '../../data/models.dart';
import '../../core/responsive_helper.dart';
import '../styles.dart';

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

  final AshtakavargaService _avService = AshtakavargaService();
  Ashtakavarga? _ashtakavarga;
  ShodhyaPindaResult? _shodhyaPinda;
  Map<int, double>? _allHousesPinda;
  bool _isLoading = true;
  String? _error;

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
    _calculateData();
  }

  Future<void> _calculateData() async {
    try {
      final av = _avService.calculateAshtakavarga(widget.chartData.baseChart);
      final shodhya = _avService.calculateShodhyaPinda(av);
      final allHouses = _avService.calculateAllHousesPinda(av);

      if (mounted) {
        setState(() {
          _ashtakavarga = av;
          _shodhyaPinda = shodhya;
          _allHousesPinda = allHouses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const ScaffoldPage(content: Center(child: ProgressRing()));
    }

    if (_error != null) {
      return ScaffoldPage(
        content: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(FluentIcons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Failed to calculate Ashtakavarga: $_error'),
            ],
          ),
        ),
      );
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
        displayMode: context.topPaneDisplayMode,
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
          PaneItem(
            icon: const Icon(FluentIcons.decrease_indent_arrow),
            title: const Text('Reductions'),
            body: _buildBody(_buildReductionsTab()),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.analytics_report),
            title: const Text('Pindas'),
            body: _buildBody(_buildPindasTab()),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.chart),
            title: const Text('Transit Analysis'),
            body: _buildBody(_buildTransitTab()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Widget content) {
    return ScaffoldPage(
      content: SingleChildScrollView(
        child: Padding(padding: context.responsiveBodyPadding, child: content),
      ),
    );
  }

  Widget _buildSarvashtakavargaTab() {
    final sarva = <int, int>{};
    if (_ashtakavarga != null && _shodhyaPinda != null) {
      final bindus = _showSodhana
          ? _shodhyaPinda!.ekadhipatiReducedAshtakavarga.sarvashtakavarga.bindus
          : _ashtakavarga!.sarvashtakavarga.bindus;
      for (int i = 0; i < 12; i++) {
        sarva[i] = bindus[i];
      }
    }

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
    final bhinna = <int, int>{};
    if (_ashtakavarga != null) {
      Planet? target;
      for (final p in Planet.traditionalPlanets) {
        if (p.name.toLowerCase() == _selectedPlanet.toLowerCase()) {
          target = p;
          break;
        }
      }
      if (target != null &&
          _ashtakavarga!.bhinnashtakavarga.containsKey(target)) {
        final bindus = _ashtakavarga!.bhinnashtakavarga[target]!.bindus;
        for (int i = 0; i < 12; i++) {
          bhinna[i] = bindus[i];
        }
      }
    }

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

  Widget _buildReductionsTab() {
    if (_shodhyaPinda == null) {
      return const Center(child: Text('Data not available'));
    }

    final trikona = <int, int>{};
    final trikonaB =
        _shodhyaPinda!.trikonaReducedAshtakavarga.sarvashtakavarga.bindus;
    for (int i = 0; i < 12; i++) {
      trikona[i] = trikonaB[i];
    }

    final ekadhipati = <int, int>{};
    final ekadhipatiB =
        _shodhyaPinda!.ekadhipatiReducedAshtakavarga.sarvashtakavarga.bindus;
    for (int i = 0; i < 12; i++) {
      ekadhipati[i] = ekadhipatiB[i];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          backgroundColor: Colors.teal.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FluentIcons.info, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text(
                      'About Reductions (Shodhana)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Trikona Shodhana eliminates points from trinal signs. Ekadhipati Shodhana removes points from signs owned by the same planet. This distills the raw strength into actual usable Pindas.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Trikona Shodhana (First Reduction)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildPointsTable(trikona),
        const SizedBox(height: 24),
        const Text(
          'Ekadhipati Shodhana (Final Reduction)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        _buildPointsTable(ekadhipati),
      ],
    );
  }

  Widget _buildPindasTab() {
    if (_shodhyaPinda == null || _allHousesPinda == null) {
      return const Center(child: Text('Data not available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FluentIcons.info, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'About Pindas (Strength Metrics)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Shodhya Pinda: ${_shodhyaPinda!.totalReducedPinda.toStringAsFixed(1)} | Total Yoga Pinda: ${_shodhyaPinda!.totalYogaPinda.toStringAsFixed(1)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Yoga Pinda represents the auspicious and tangible results a planet can give, while Shodhya Pinda is the baseline residual strength.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Planetary Pindas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Card(
          child: Table(
            border: TableBorder.symmetric(
              inside: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0x0A000000)),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Planet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Shodhya Pinda',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Yoga Pinda',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              ...Planet.traditionalPlanets.map((p) {
                final sp = _shodhyaPinda!.reducedPinda[p]?.totalPinda ?? 0.0;
                final yp = _shodhyaPinda!.yogaPinda[p]?.totalYogaPinda ?? 0.0;
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(p.displayName),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        sp.toStringAsFixed(1),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        yp.toStringAsFixed(1),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: yp >= 20 ? Colors.green : null,
                          fontWeight: yp >= 20 ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'House Pindas (Bhavas)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Card(
          child: Table(
            border: TableBorder.symmetric(
              inside: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0x0A000000)),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'House',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Pinda Strength',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              ...List.generate(12, (index) {
                final val = _allHousesPinda![index + 1] ?? 0.0;
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('House ${index + 1}'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        val.toStringAsFixed(1),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransitTab() {
    if (_ashtakavarga == null) {
      return const Center(child: Text('Data not available'));
    }

    Planet? target;
    for (final p in Planet.traditionalPlanets) {
      if (p.name.toLowerCase() == _selectedPlanet.toLowerCase()) {
        target = p;
        break;
      }
    }

    List<int> favorableSigns = [];
    if (target != null) {
      favorableSigns = _avService.getFavorableTransitSigns(
        _ashtakavarga!,
        target,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FluentIcons.info, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      'About Transit Analysis',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Signs with more than 28 bindus in Sarvashtakavarga are considered favorable for any planet to transit. This tool displays which zodiac signs will yield auspicious results when the selected planet travels through them.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
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
        if (target != null) ...[
          Text(
            'Signs yielding favorable results for ${target.displayName} transit:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (index) {
              final isFavorable = favorableSigns.contains(index);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isFavorable
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isFavorable
                        ? Colors.green
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _signNames[index],
                  style: TextStyle(
                    color: isFavorable ? Colors.green : Colors.red,
                    fontWeight: isFavorable
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ],
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
                statusColor = AppStyles.beneficColor;
              } else if (points >= 4) {
                statusText = 'Strong';
                statusColor = AppStyles.beneficColor.withValues(alpha: 0.8);
              } else if (points >= 3) {
                statusText = 'Average';
                statusColor = AppStyles.neutralColor;
              } else {
                statusText = 'Weak';
                statusColor = AppStyles.maleficColor;
              }
            } else {
              // Sarva logic
              if (points >= 32) {
                statusText = 'Very Strong';
                statusColor = AppStyles.beneficColor;
              } else if (points >= 28) {
                statusText = 'Strong';
                statusColor = AppStyles.beneficColor.withValues(alpha: 0.8);
              } else if (points >= 25) {
                statusText = 'Average';
                statusColor = AppStyles.neutralColor;
              } else {
                statusText = 'Weak';
                statusColor = AppStyles.maleficColor;
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
