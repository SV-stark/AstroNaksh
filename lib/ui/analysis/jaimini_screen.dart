import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';
import '../../data/models.dart';
import '../../logic/jaimini_service.dart';

class JaiminiScreen extends StatelessWidget {
  final CompleteChartData chartData;

  const JaiminiScreen({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    final jaimini = JaiminiService();
    final analysis = jaimini.getJaiminiAnalysis(chartData);

    return ScaffoldPage(
      header: const PageHeader(
        title: Text('Jaimini Astrology'),
      ),
      content: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Atmakaraka
          _buildSection(
            'Atmakaraka (AK)',
            'Planet with highest degree',
            '${analysis.atmakaraka.displayName}',
            'The soul indicator - represents the native\'s main life purpose',
          ),
          const SizedBox(height: 16),

          // Karakamsa
          _buildSection(
            'Karakamsa',
            'AK in Navamsa',
            '${analysis.karakamsa.karakamsaRashi?.name ?? "Unknown"}',
            'Reieves spiritual progress and moksha indications',
          ),
          const SizedBox(height: 16),

          // Arudha Lagna
          Card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Arudha Lagna (AL)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('Appearance indicator', style: TextStyle(color: Colors.grey[400])),
                const SizedBox(height: 8),
                Text('Sign: ${analysis.arudhaLagna.rashi?.name ?? "Unknown"}'),
                Text('Lord: ${analysis.arudhaLagna.lord?.displayName ?? "Unknown"}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Upapada
          Card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upapada (UL)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('Spouse & marriage indicator', style: TextStyle(color: Colors.grey[400])),
                const SizedBox(height: 8),
                Text('Sign: ${analysis.upapada.rashi?.name ?? "Unknown"}'),
                Text('Lord: ${analysis.upapada.lord?.displayName ?? "Unknown"}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Rashi Drishti
          Card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rashi Drishti',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('Sign aspects (Jaimini)', style: TextStyle(color: Colors.grey[400])),
                const SizedBox(height: 8),
                if (analysis.rashiDrishti.isEmpty)
                  const Text('No significant Rashi Drishti found')
                else
                  ...analysis.rashiDrishti.take(5).map((rd) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('${rd.fromRashi?.name} → ${rd.toRashi?.name}'),
                  )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Argalas
          Card(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Argalas (Planetary Strengths)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('Planetary influences on houses', style: TextStyle(color: Colors.grey[400])),
                const SizedBox(height: 8),
                ...analysis.argalas.entries.take(6).map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('House ${e.key}: ${e.value.length} argala(s)'),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String subtitle, String value, String description) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: Colors.grey[300])),
        ],
      ),
    );
  }
}
