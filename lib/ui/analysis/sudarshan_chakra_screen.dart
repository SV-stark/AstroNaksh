import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';
import '../../core/responsive_helper.dart';
import '../../data/models.dart';
import '../../logic/sudarshan_chakra_service.dart';

/// Sudarshan Chakra Analysis Screen
/// Displays triple-perspective strength analysis from Lagna, Chandra, and Surya
class SudarshanChakraScreen extends StatefulWidget {
  final CompleteChartData chartData;

  const SudarshanChakraScreen({super.key, required this.chartData});

  @override
  State<SudarshanChakraScreen> createState() => _SudarshanChakraScreenState();
}

class _SudarshanChakraScreenState extends State<SudarshanChakraScreen> {
  final SudarshanChakraServiceWrapper _service =
      SudarshanChakraServiceWrapper();
  late Future<SudarshanChakraResult> _resultFuture;

  @override
  void initState() {
    super.initState();
    _resultFuture = _service.calculateSudarshanChakra(
      widget.chartData.baseChart,
    );
  }

  static const _signNames = [
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

  String _signName(int index) =>
      (index >= 0 && index < 12) ? _signNames[index] : 'Unknown';

  Color _categoryColor(SudarshanStrengthCategory cat) {
    switch (cat) {
      case SudarshanStrengthCategory.excellent:
        return Colors.green;
      case SudarshanStrengthCategory.good:
        return Colors.teal;
      case SudarshanStrengthCategory.moderate:
        return Colors.orange;
      case SudarshanStrengthCategory.weak:
        return Colors.red.lighter;
      case SudarshanStrengthCategory.veryWeak:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Sudarshan Chakra Analysis'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: FutureBuilder<SudarshanChakraResult>(
        future: _resultFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProgressRing(),
                  SizedBox(height: 16),
                  Text('Calculating Sudarshan Chakra...'),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final result = snapshot.data!;
          return SingleChildScrollView(
            padding: context.responsiveBodyPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Overview card
                _buildOverviewCard(context, result),
                const SizedBox(height: 20),

                // Reference signs
                _buildReferenceSignsCard(context, result),
                const SizedBox(height: 20),

                // House strengths
                _buildHouseStrengthsCard(context, result),
                const SizedBox(height: 20),

                // Planet strengths
                _buildPlanetStrengthsCard(context, result),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(
    BuildContext context,
    SudarshanChakraResult result,
  ) {
    final overall = result.overallStrength;
    final cat = SudarshanStrengthCategory.fromScore(overall);
    final color = _categoryColor(cat);

    return Card(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${overall.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Chart Strength',
                      style: FluentTheme.of(context).typography.subtitle
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat.name,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: ProgressBar(
                value: overall,
                backgroundColor: Colors.grey.withAlpha(30),
                activeColor: color,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Strong/weak houses summary
          Row(
            children: [
              Expanded(
                child: _buildSummaryChip(
                  context,
                  'Strong Houses',
                  result.strongHouses.map((h) => 'H$h').join(', '),
                  Colors.green,
                  FluentIcons.completed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryChip(
                  context,
                  'Weak Houses',
                  result.weakHouses.map((h) => 'H$h').join(', '),
                  Colors.red,
                  FluentIcons.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : 'None',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceSignsCard(
    BuildContext context,
    SudarshanChakraResult result,
  ) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Three Reference Points',
            style: FluentTheme.of(
              context,
            ).typography.bodyStrong?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Sudarshan Chakra evaluates from Lagna, Moon, and Sun perspectives',
            style: FluentTheme.of(
              context,
            ).typography.caption?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRefSign(
                  context,
                  'Lagna',
                  _signName(result.lagnaSign),
                  FluentIcons.home,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRefSign(
                  context,
                  'Chandra',
                  _signName(result.chandraSign),
                  FluentIcons.clear_night,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRefSign(
                  context,
                  'Surya',
                  _signName(result.suryaSign),
                  FluentIcons.sunny,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefSign(
    BuildContext context,
    String label,
    String sign,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            sign,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHouseStrengthsCard(
    BuildContext context,
    SudarshanChakraResult result,
  ) {
    final isMobile = context.isMobile;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'House Strengths',
            style: FluentTheme.of(
              context,
            ).typography.bodyStrong?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: isMobile
                ? const {
                    0: FixedColumnWidth(50),
                    1: FlexColumnWidth(1),
                    2: FixedColumnWidth(50),
                    3: FixedColumnWidth(70),
                  }
                : const {
                    0: FixedColumnWidth(60),
                    1: FixedColumnWidth(80),
                    2: FixedColumnWidth(80),
                    3: FixedColumnWidth(80),
                    4: FlexColumnWidth(1),
                    5: FixedColumnWidth(60),
                    6: FixedColumnWidth(80),
                  },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.withAlpha(30),
                width: 0.5,
              ),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor.withAlpha(15),
                ),
                children: isMobile
                    ? const [
                        _HeaderCell('House'),
                        _HeaderCell('Score'),
                        _HeaderCell('%'),
                        _HeaderCell('Rating'),
                      ]
                    : const [
                        _HeaderCell('House'),
                        _HeaderCell('Lagna'),
                        _HeaderCell('Chandra'),
                        _HeaderCell('Surya'),
                        _HeaderCell('Score'),
                        _HeaderCell('%'),
                        _HeaderCell('Rating'),
                      ],
              ),
              ...List.generate(12, (i) {
                final h = result.houseStrengths[i + 1];
                if (h == null)
                  return TableRow(
                    children: isMobile
                        ? List.generate(4, (_) => const SizedBox())
                        : List.generate(7, (_) => const SizedBox()),
                  );
                final color = _categoryColor(h.category);
                return TableRow(
                  children: isMobile
                      ? [
                          _DataCell('H${h.houseNumber}', bold: true),
                          _BarCell(h.combinedScore, color),
                          _DataCell('${h.combinedScore.toStringAsFixed(0)}'),
                          _CategoryCell(h.category.name, color),
                        ]
                      : [
                          _DataCell('H${h.houseNumber}', bold: true),
                          _DataCell('${h.lagnaHouse}'),
                          _DataCell('${h.chandraHouse}'),
                          _DataCell('${h.suryaHouse}'),
                          _BarCell(h.combinedScore, color),
                          _DataCell('${h.combinedScore.toStringAsFixed(0)}%'),
                          _CategoryCell(h.category.name, color),
                        ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanetStrengthsCard(
    BuildContext context,
    SudarshanChakraResult result,
  ) {
    final isMobile = context.isMobile;

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planet Strengths',
            style: FluentTheme.of(
              context,
            ).typography.bodyStrong?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: isMobile
                ? const {
                    0: FlexColumnWidth(1.5),
                    1: FlexColumnWidth(2),
                    2: FixedColumnWidth(45),
                    3: FixedColumnWidth(70),
                  }
                : const {
                    0: FlexColumnWidth(1.5),
                    1: FixedColumnWidth(70),
                    2: FixedColumnWidth(70),
                    3: FixedColumnWidth(70),
                    4: FlexColumnWidth(2),
                    5: FixedColumnWidth(55),
                    6: FixedColumnWidth(80),
                  },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.withAlpha(30),
                width: 0.5,
              ),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor.withAlpha(15),
                ),
                children: isMobile
                    ? const [
                        _HeaderCell('Planet'),
                        _HeaderCell('Score'),
                        _HeaderCell('%'),
                        _HeaderCell('Rating'),
                      ]
                    : const [
                        _HeaderCell('Planet'),
                        _HeaderCell('Lagna'),
                        _HeaderCell('Chandra'),
                        _HeaderCell('Surya'),
                        _HeaderCell('Score'),
                        _HeaderCell('%'),
                        _HeaderCell('Rating'),
                      ],
              ),
              ...result.planetStrengths.entries.map((entry) {
                final ps = entry.value;
                final color = _categoryColor(ps.category);
                return TableRow(
                  children: isMobile
                      ? [
                          _DataCell(ps.planet.displayName, bold: true),
                          _BarCell(ps.combinedScore, color),
                          _DataCell('${ps.combinedScore.toStringAsFixed(0)}'),
                          _CategoryCell(ps.category.name, color),
                        ]
                      : [
                          _DataCell(ps.planet.displayName, bold: true),
                          _DataCell('H${ps.lagnaPlacement}'),
                          _DataCell('H${ps.chandraPlacement}'),
                          _DataCell('H${ps.suryaPlacement}'),
                          _BarCell(ps.combinedScore, color),
                          _DataCell('${ps.combinedScore.toStringAsFixed(0)}%'),
                          _CategoryCell(ps.category.name, color),
                        ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper table cell widgets
class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final bool bold;
  const _DataCell(this.text, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _CategoryCell extends StatelessWidget {
  final String text;
  final Color color;
  const _CategoryCell(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BarCell extends StatelessWidget {
  final double value;
  final Color color;
  const _BarCell(this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          height: 6,
          child: ProgressBar(
            value: value,
            backgroundColor: Colors.grey.withAlpha(30),
            activeColor: color,
          ),
        ),
      ),
    );
  }
}
