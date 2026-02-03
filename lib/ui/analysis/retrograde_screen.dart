import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../logic/retrograde_analysis.dart';

class RetrogradeScreen extends StatelessWidget {
  final CompleteChartData chartData;

  const RetrogradeScreen({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    final analysis = RetrogradeAnalysis.analyzeRetrogrades(chartData);

    return Scaffold(
      appBar: AppBar(title: const Text('Retrograde Analysis')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.purple.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.purple),
                      SizedBox(width: 12),
                      Text(
                        'About Retrograde Motion',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When a planet appears to move backward in the sky, it is retrograde. '
                    'Retrograde planets internalize their energy and bring karmic lessons.',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          ...analysis.entries.map((entry) {
            final planet = entry.key;
            final info = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  info.isRetrograde ? Icons.replay : Icons.arrow_forward,
                  color: info.isRetrograde ? Colors.orange : Colors.green,
                  size: 32,
                ),
                title: Text(
                  planet,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      info.isRetrograde ? 'Retrograde ®' : 'Direct',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: info.isRetrograde ? Colors.orange : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(info.interpretation),
                    const SizedBox(height: 8),
                    Text(
                      'Frequency: ${RetrogradeAnalysis.getRetrogradeFrequency(planet)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          }),
        ],
      ),
    );
  }
}
