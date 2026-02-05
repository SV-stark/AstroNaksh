import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import 'package:intl/intl.dart';

class DailyPredictionCard extends StatelessWidget {
  final DailyRashiphal prediction;
  final bool isToday;

  const DailyPredictionCard({
    super.key,
    required this.prediction,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16.0),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Date and Tithi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(prediction.date),
                style: FluentTheme.of(context).typography.subtitle,
              ),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'Today',
                    style: FluentTheme.of(context).typography.caption?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Cosmic Context
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildChip(context, 'Moon: ${prediction.moonSign}'),
              _buildChip(context, 'Nakshatra: ${prediction.nakshatra}'),
              _buildChip(context, 'Tithi: ${prediction.tithi}'),
            ],
          ),
          const SizedBox(height: 16),

          // Day Quality Score
          _buildDayScoreCard(context),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Main Prediction
          Text(
            prediction.overallPrediction,
            style: FluentTheme.of(context).typography.bodyLarge,
          ),
          const SizedBox(height: 16),

          // Highlights
          if (prediction.keyHighlights.isNotEmpty) ...[
            Text(
              'Highlights',
              style: FluentTheme.of(context).typography.bodyStrong,
            ),
            const SizedBox(height: 4),
            ...prediction.keyHighlights.map(
              (h) => _buildBulletPoint(context, h, Colors.green),
            ),
            const SizedBox(height: 12),
          ],

          // Cautions
          if (prediction.cautions.isNotEmpty) ...[
            Text(
              'Cautions',
              style: FluentTheme.of(context).typography.bodyStrong,
            ),
            const SizedBox(height: 4),
            ...prediction.cautions.map(
              (c) => _buildBulletPoint(context, c, Colors.orange),
            ),
            const SizedBox(height: 12),
          ],

          // Auspicious Periods (Muhurta)
          if (prediction.auspiciousPeriods.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(FluentIcons.clock, size: 16, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Auspicious Timings',
                  style: FluentTheme.of(context).typography.bodyStrong,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...prediction.auspiciousPeriods.map(
              (t) => Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Text(
                  t,
                  style: FluentTheme.of(context).typography.caption,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
        ),
      ),
      child: Text(text, style: FluentTheme.of(context).typography.caption),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: FluentTheme.of(context).typography.body),
          ),
        ],
      ),
    );
  }

  Widget _buildDayScoreCard(BuildContext context) {
    final score = (prediction.favorableScore * 100).round();
    final color = _getScoreColor(score);
    final label = _getScoreLabel(score);

    return Card(
      backgroundColor: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Score Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: ProgressRing(
                  value: score.toDouble(),
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  activeColor: color,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Score Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day Quality Score',
                  style: FluentTheme.of(context).typography.bodyStrong,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getScoreDescription(score),
                  style: FluentTheme.of(context).typography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.teal;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Challenging';
  }

  String _getScoreDescription(int score) {
    if (score >= 80) {
      return 'Highly favorable day for important activities and decisions.';
    } else if (score >= 60) {
      return 'Generally positive day with good energy for most endeavors.';
    } else if (score >= 40) {
      return 'Mixed influences - proceed with caution and awareness.';
    }
    return 'Challenging day - avoid major decisions if possible.';
  }
}
