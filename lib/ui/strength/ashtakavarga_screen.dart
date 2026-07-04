import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';

import '../../core/ephemeris_manager.dart';
import '../../data/models.dart';
import '../../ui/utils/responsive_helper.dart';
import '../styles.dart';

class AshtakavargaScreen extends StatefulWidget {
  const AshtakavargaScreen({super.key, required this.chartData});
  final CompleteChartData chartData;

  @override
  State<AshtakavargaScreen> createState() => _AshtakavargaScreenState();
}

class _AshtakavargaScreenState extends State<AshtakavargaScreen> {
  int _currentIndex = 0;
  String _selectedPlanet = 'Sun';
  bool _showSodhana = false;

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
      setState(() => _isLoading = true);

      final chart = widget.chartData.baseChart;
      final jyotish = EphemerisManager.jyotish;

      _ashtakavarga = jyotish.calculateAshtakavarga(chart);
      _shodhyaPinda = jyotish.calculateShodhyaPinda(_ashtakavarga!);
      _allHousesPinda = jyotish.calculateAllHousesPinda(_ashtakavarga!);

      setState(() {
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
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
      titleBar: TitleBar(
        title: Row(
          children: [
            if (!ResponsiveHelper.useMobileLayout(context))
              IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => Navigator.pop(context),
              ),
            if (ResponsiveHelper.useMobileLayout(context))
              IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => Navigator.pop(context),
              ),
            const SizedBox(width: 8),
            const Text('Ashtakavarga Analysis'),
          ],
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
            icon: const Icon(FluentIcons.grid_view_small),
            title: const Text('Prastara Grid'),
            body: _buildBody(_buildPrastaraGridTab()),
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
      for (var i = 0; i < 12; i++) {
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
        for (var i = 0; i < 12; i++) {
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

  Widget _buildPrastaraGridTab() {
    Planet? target;
    for (final p in Planet.traditionalPlanets) {
      if (p.name.toLowerCase() == _selectedPlanet.toLowerCase()) {
        target = p;
        break;
      }
    }

    if (target == null) {
      return const Center(child: Text('Please select a planet.'));
    }

    final chart = widget.chartData.baseChart;
    final jyotish = EphemerisManager.jyotish;
    final prastara = jyotish.calculatePrastaraAshtakavarga(chart, target);

    final contributors = [
      'Sun',
      'Moon',
      'Mars',
      'Mercury',
      'Jupiter',
      'Venus',
      'Saturn',
      'Lagna',
    ];

    // Compute column totals
    final columnTotals = List<int>.generate(12, (colIndex) {
      var sum = 0;
      for (var rowIndex = 0; rowIndex < 8; rowIndex++) {
        sum += prastara.getContribution(rowIndex, colIndex);
      }
      return sum;
    });

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
                    Icon(FluentIcons.grid_view_small, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text(
                      'About Prastara Ashtakavarga Grid',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'The Prastara Grid decomposes the Bhinnashtakavarga score into its individual planetary contributors. '
                  'Each of the 8 points (7 planets + Lagna) contributes either 1 (Benefic Point) or 0 to the 12 signs. '
                  'The sum of all contributors for a sign equals its Bhinnashtakavarga score.',
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
                  isSelected ? Colors.teal.withValues(alpha: 0.1) : null,
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

        const Text(
          'Prastara Ashtakavarga Grid (8x12)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

        Card(
          padding: EdgeInsets.zero,
          child: Scrollbar(
            controller: ScrollController(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: {
                    0: const FixedColumnWidth(120),
                    for (var i = 1; i <= 12; i++) i: const FixedColumnWidth(55),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: FluentTheme.of(
                              context,
                            ).resources.dividerStrokeColorDefault,
                            width: 1.5,
                          ),
                        ),
                      ),
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Text(
                            'Contributor',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ..._signNames.map(
                          (sign) => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Text(
                              sign.substring(0, 3),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    for (var rowIndex = 0; rowIndex < 8; rowIndex++)
                      TableRow(
                        decoration: BoxDecoration(
                          color: rowIndex % 2 == 0
                              ? FluentTheme.of(
                                  context,
                                ).resources.controlAltFillColorTertiary
                              : null,
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
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Text(
                              contributors[rowIndex],
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          for (var colIndex = 0; colIndex < 12; colIndex++)
                            _buildGridCell(
                              prastara.getContribution(rowIndex, colIndex),
                              context,
                            ),
                        ],
                      ),
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.15),
                        border: Border(
                          top: BorderSide(
                            color: FluentTheme.of(context).accentColor,
                            width: 2,
                          ),
                        ),
                      ),
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          child: Text(
                            'Total Bindus',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...columnTotals.map(
                          (total) => Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 4,
                            ),
                            child: Text(
                              total.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridCell(int value, BuildContext context) {
    final isBenefic = value == 1;
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: isBenefic ? Colors.teal.withValues(alpha: 0.08) : null,
      child: Text(
        value.toString(),
        style: TextStyle(
          fontWeight: isBenefic ? FontWeight.bold : FontWeight.normal,
          color: isBenefic
              ? FluentTheme.of(context).accentColor
              : FluentTheme.of(context).typography.caption?.color,
        ),
      ),
    );
  }

  Widget _buildReductionsTab() {
    if (_shodhyaPinda == null) {
      return const Center(child: Text('Data not available'));
    }

    final trikona = <int, int>{};
    final trikonaB =
        _shodhyaPinda!.trikonaReducedAshtakavarga.sarvashtakavarga.bindus;
    for (var i = 0; i < 12; i++) {
      trikona[i] = trikonaB[i];
    }

    final ekadhipati = <int, int>{};
    final ekadhipatiB =
        _shodhyaPinda!.ekadhipatiReducedAshtakavarga.sarvashtakavarga.bindus;
    for (var i = 0; i < 12; i++) {
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

    var favorableSigns = <int>[];
    if (target != null) {
      favorableSigns = EphemerisManager.jyotish.getFavorableTransitSigns(
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

  HSLColor _getStrengthHSL(int value, bool isBhinna) {
    if (isBhinna) {
      if (value < 3) {
        // Critical: Soft Crimson Red
        return const HSLColor.fromAHSL(1.0, 355.0, 0.75, 0.50);
      } else if (value <= 4) {
        // Average: Muted Golden Orange
        return const HSLColor.fromAHSL(1.0, 38.0, 0.85, 0.55);
      } else if (value <= 6) {
        // Good: Soft Turquoise Teal
        return const HSLColor.fromAHSL(1.0, 168.0, 0.65, 0.45);
      } else {
        // Exceptional: Vibrant Emerald/Jade
        return const HSLColor.fromAHSL(1.0, 135.0, 0.75, 0.40);
      }
    } else {
      if (value < 20) {
        // Critical: Soft Crimson Red
        return const HSLColor.fromAHSL(1.0, 355.0, 0.75, 0.50);
      } else if (value <= 25) {
        // Average: Muted Golden Orange
        return const HSLColor.fromAHSL(1.0, 38.0, 0.85, 0.55);
      } else if (value <= 28) {
        // Good: Soft Turquoise Teal
        return const HSLColor.fromAHSL(1.0, 168.0, 0.65, 0.45);
      } else {
        // Exceptional: Vibrant Emerald/Jade
        return const HSLColor.fromAHSL(1.0, 135.0, 0.75, 0.40);
      }
    }
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildHeatMap(Map<int, int> points, {bool isBhinna = false}) {
    final gridMap = <String, int>{
      '0,0': 11,
      '0,1': 0,
      '0,2': 1,
      '0,3': 2,
      '1,3': 3,
      '2,3': 4,
      '3,3': 5,
      '3,2': 6,
      '3,1': 7,
      '3,0': 8,
      '2,0': 9,
      '1,0': 10,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBhinna
                  ? 'Bhinnashtakavarga Chart Map'
                  : 'Sarvashtakavarga Chart Map',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: FluentTheme.of(context)
                            .resources
                            .textFillColorPrimary
                            .withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: List.generate(4, (row) {
                        return Expanded(
                          child: Row(
                            children: List.generate(4, (col) {
                              final key = '$row,$col';
                              if (gridMap.containsKey(key)) {
                                final signIndex = gridMap[key]!;
                                final val = points[signIndex] ?? 0;
                                final hslColor = _getStrengthHSL(val, isBhinna);
                                final color = hslColor.toColor();

                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          color,
                                          color.withValues(alpha: 0.85),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.2),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1.5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _signNames[signIndex],
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(0, 1),
                                                blurRadius: 2,
                                                color: Color(0x73000000),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            val.toString(),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                // Center 2x2 cells
                                if (row == 1 && col == 1) {
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: FluentTheme.of(
                                          context,
                                        ).cardColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            isBhinna ? 'BAV' : 'SAV',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: FluentTheme.of(
                                                context,
                                              ).activeColor,
                                            ),
                                          ),
                                          const Text(
                                            'Heatmap',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                if (row == 1 && col == 2) {
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: FluentTheme.of(
                                          context,
                                        ).cardColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Legend',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              _legendDot(
                                                const Color(0xfff87171),
                                              ), // Red
                                              _legendDot(
                                                const Color(0xfffbbf24),
                                              ), // Amber
                                              _legendDot(
                                                const Color(0xff2dd4bf),
                                              ), // Teal
                                              _legendDot(
                                                const Color(0xff10b981),
                                              ), // Emerald
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                if (row == 2 && col == 1) {
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: FluentTheme.of(
                                          context,
                                        ).cardColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Target',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            isBhinna ? '4.0' : '28.0',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                if (row == 2 && col == 2) {
                                  int minVal = 999;
                                  int maxVal = -999;
                                  points.forEach((k, v) {
                                    if (v < minVal) minVal = v;
                                    if (v > maxVal) maxVal = v;
                                  });
                                  return Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: FluentTheme.of(
                                          context,
                                        ).cardColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'Range',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '$minVal - $maxVal',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return Expanded(child: Container());
                              }
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Explanatory card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FluentTheme.of(
                  context,
                ).resources.solidBackgroundFillColorBase,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Color Classification:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendRow(
                    const Color(0xfff87171),
                    isBhinna
                        ? 'Critical Strength (Points < 3) - Represents low planetary support.'
                        : 'Critical Strength (Points < 20) - Represents low overall support for the sign.',
                  ),
                  const SizedBox(height: 6),
                  _buildLegendRow(
                    const Color(0xfffbbf24),
                    isBhinna
                        ? 'Average Strength (Points 3-4) - Represents standard support.'
                        : 'Average Strength (Points 20-25) - Represents standard support.',
                  ),
                  const SizedBox(height: 6),
                  _buildLegendRow(
                    const Color(0xff2dd4bf),
                    isBhinna
                        ? 'Good Strength (Points 5-6) - Highly favorable houses.'
                        : 'Good Strength (Points 26-28) - Favorable houses with robust backing.',
                  ),
                  const SizedBox(height: 6),
                  _buildLegendRow(
                    const Color(0xff10b981),
                    isBhinna
                        ? 'Exceptional Strength (Points > 6) - Outstanding planetary power.'
                        : 'Exceptional Strength (Points > 28) - Extremely powerful houses.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(Color color, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 2, right: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Text(description, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
