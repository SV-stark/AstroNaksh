import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../data/life_prediction_models.dart';
import '../../logic/life_prediction_service.dart';

/// Life Predictions Screen
/// Displays comprehensive life predictions based on Vedic astrology
class LifePredictionsScreen extends StatefulWidget {
  final CompleteChartData chartData;

  const LifePredictionsScreen({super.key, required this.chartData});

  @override
  State<LifePredictionsScreen> createState() => _LifePredictionsScreenState();
}

class _LifePredictionsScreenState extends State<LifePredictionsScreen> {
  final LifePredictionService _service = LifePredictionService();
  late Future<LifePredictionsResult> _predictionsFuture;
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _predictionsFuture = _service.generateLifePredictions(widget.chartData);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Life Predictions'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: FutureBuilder<LifePredictionsResult>(
        future: _predictionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ProgressRing());
          }

          if (snapshot.hasError) {
            return Center(
              child: InfoBar(
                title: const Text('Error'),
                content: Text(
                  'Could not generate predictions: ${snapshot.error}',
                ),
                severity: InfoBarSeverity.error,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final result = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Overall Score Card
              _buildOverallScoreCard(context, result),
              const SizedBox(height: 16),

              // Info Card
              Card(
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(FluentIcons.info, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'These predictions are based on your D-1 birth chart analysis using classical Vedic astrology principles including Shadbala, Bhava Bala, and house lord placements.',
                          style: FluentTheme.of(context).typography.caption,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Life Aspect Cards
              ...result.aspects.asMap().entries.map((entry) {
                final index = entry.key;
                final aspect = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildAspectCard(context, aspect, index),
                );
              }),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverallScoreCard(
    BuildContext context,
    LifePredictionsResult result,
  ) {
    final score = result.overallScore;
    final color = _getScoreColor(score);

    return Card(
      backgroundColor: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Score Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: ProgressRing(
                  value: score.toDouble(),
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  activeColor: color,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'Overall',
                    style: FluentTheme.of(context).typography.caption,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Summary Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Life Overview',
                  style: FluentTheme.of(
                    context,
                  ).typography.subtitle?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  result.overallSummary,
                  style: FluentTheme.of(context).typography.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectCard(
    BuildContext context,
    LifeAspectPrediction aspect,
    int index,
  ) {
    final isExpanded = _expandedIndex == index;
    final color = _getScoreColor(aspect.score);

    return Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header (always visible)
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getAspectIcon(aspect.iconName),
                color: color,
                size: 24,
              ),
            ),
            title: Text(
              aspect.aspectName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              aspect.aspectDescription,
              style: FluentTheme.of(context).typography.caption,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Score Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${aspect.score}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded
                      ? FluentIcons.chevron_up_small
                      : FluentIcons.chevron_down_small,
                  size: 16,
                ),
              ],
            ),
            onPressed: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
          ),

          // Score Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildScoreProgressBar(aspect.score, color),
          ),

          // Expanded Content
          if (isExpanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Detailed Prediction
                  Text(
                    aspect.prediction,
                    style: FluentTheme.of(context).typography.body,
                  ),
                  const SizedBox(height: 16),

                  // Planetary Influences
                  Text(
                    'Planetary Influences',
                    style: FluentTheme.of(context).typography.bodyStrong,
                  ),
                  const SizedBox(height: 8),
                  ...aspect.influences.map(
                    (influence) => _buildInfluenceRow(context, influence),
                  ),

                  const SizedBox(height: 16),

                  // Advice Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          FluentIcons.lightbulb,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Guidance',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                aspect.advice,
                                style: FluentTheme.of(context).typography.body,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildScoreProgressBar(int score, Color color) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final progress = (score - 40) / 55; // Map 40-95 to 0-1

                  return Stack(
                    children: [
                      // Background
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      // Progress
                      Container(
                        height: 8,
                        width: width * progress.clamp(0, 1),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withValues(alpha: 0.7), color],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _getScoreLabel(score),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildInfluenceRow(
    BuildContext context,
    PlanetaryInfluence influence,
  ) {
    final color = influence.isBenefic ? Colors.green : Colors.orange;
    final strengthColor = _getStrengthColor(influence.strength);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FluentTheme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Planet indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                // Position
                Expanded(
                  child: Text(
                    influence.position,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      influence.status,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    influence.status,
                    style: TextStyle(
                      fontSize: 11,
                      color: _getStatusColor(influence.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Strength bar
            Row(
              children: [
                Text(
                  'Strength:',
                  style: FluentTheme.of(context).typography.caption,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: influence.strength / 100,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: strengthColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${influence.strength.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: strengthColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Effect description
            Text(
              influence.effect,
              style: FluentTheme.of(context).typography.caption,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 86) return Colors.green;
    if (score >= 71) return const Color(0xFF8BC34A); // Light Green
    if (score >= 56) return Colors.orange;
    return Colors.red;
  }

  Color _getStrengthColor(double strength) {
    if (strength >= 70) return Colors.green;
    if (strength >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Exalted':
        return Colors.green;
      case 'Own Sign':
        return const Color(0xFF4CAF50);
      case 'Friendly Sign':
        return Colors.blue;
      case 'Neutral Sign':
        return Colors.grey;
      case 'Enemy Sign':
        return Colors.orange;
      case 'Debilitated':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getScoreLabel(int score) {
    if (score >= 86) return 'Excellent';
    if (score >= 71) return 'Good';
    if (score >= 56) return 'Average';
    return 'Challenging';
  }

  IconData _getAspectIcon(String iconName) {
    switch (iconName) {
      case 'work':
        return FluentIcons.calendar;
      case 'money':
        return FluentIcons.money;
      case 'home':
        return FluentIcons.home;
      case 'heart':
        return FluentIcons.heart;
      case 'health':
        return FluentIcons.health;
      case 'child':
        return FluentIcons.people;
      case 'education':
        return FluentIcons.education;
      case 'peace':
        return FluentIcons.hands_free;
      default:
        return FluentIcons.circle_ring;
    }
  }
}
