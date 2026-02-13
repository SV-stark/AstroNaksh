import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../logic/progeny_service.dart';

class ProgenyScreen extends StatelessWidget {
  final CompleteChartData chartData;

  const ProgenyScreen({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    final service = ProgenyService();
    final analysis = service.analyzeProgeny(chartData);

    return ScaffoldPage(
      header: const PageHeader(
        title: Text('Progeny Analysis'),
      ),
      content: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall Score
          Card(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '${analysis.overallScore}%',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  analysis.prospects,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 16),
                _buildProgressBar(analysis.overallScore),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Factors
          const Text(
            'Analysis Factors',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...analysis.factors.map((f) => _buildFactorCard(f)),
          const SizedBox(height: 16),

          // Recommendations
          const Text(
            'Recommendations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: analysis.recommendations.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(child: Text(r)),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int score) {
    Color color;
    if (score >= 60) {
      color = Colors.green;
    } else if (score >= 40) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: score / 100,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildFactorCard(ProgenyFactor factor) {
    Color color;
    if (factor.score >= 60) {
      color = Colors.green;
    } else if (factor.score >= 40) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Card(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(factor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(factor.description, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withAlpha(50),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color),
            ),
            child: Text(
              '${factor.score}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
