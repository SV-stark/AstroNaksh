import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../logic/nadi_service.dart';

class NadiScreen extends StatelessWidget {
  final CompleteChartData chartData;

  const NadiScreen({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    final service = NadiService();
    final analysis = service.analyzeNadi(chartData);

    return ScaffoldPage(
      header: const PageHeader(
        title: Text('Nadi Analysis'),
      ),
      content: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Main Nadi
          Card(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(FluentIcons.flow, size: 48),
                const SizedBox(height: 16),
                Text(
                  analysis.nadiType,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (analysis.nakshatra != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${analysis.nakshatra} - Pada ${analysis.pada}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
                const SizedBox(height: 16),
                _buildStrengthMeter(analysis.strength),
                const SizedBox(height: 16),
                Text(analysis.description),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nadi Types Explanation
          const Text(
            'Nadi Types',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          _buildNadiInfoCard(
            'Adi (Vata)',
            'Air Nadi',
            'Active, restless nature. Quick decisions. Thin build.',
            Colors.blue,
          ),
          const SizedBox(height: 8),
          _buildNadiInfoCard(
            'Madhya (Pitta)',
            'Fire Nadi',
            'Balanced, ambitious. Medium physique. Strong digestion.',
            Colors.orange,
          ),
          const SizedBox(height: 8),
          _buildNadiInfoCard(
            'Antya (Kapha)',
            'Water Nadi',
            'Calm, steady. Strong immunity. Larger build.',
            Colors.green,
          ),
          const SizedBox(height: 16),

          // Compatibility Note
          Card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compatibility Note',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'In Kundali matching, same Nadi (Adi-Madhya-Antya) between partners '
                  'is considered Nadi Dosha - a serious incompatibility that can affect '
                  'health and progeny. Different Nadis are considered more favorable.',
                  style: TextStyle(color: Colors.grey[300]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthMeter(int strength) {
    Color color;
    if (strength >= 60) {
      color = Colors.green;
    } else if (strength >= 40) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Nadi Strength'),
            Text('$strength%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: strength / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNadiInfoCard(String name, String type, String description, Color color) {
    return Card(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(type, style: TextStyle(color: color, fontSize: 12)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
