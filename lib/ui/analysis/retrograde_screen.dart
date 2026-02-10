import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../logic/retrograde_analysis.dart';
import '../../core/responsive_helper.dart';

class RetrogradeScreen extends StatelessWidget {
  final CompleteChartData chartData;

  const RetrogradeScreen({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    final analysis = RetrogradeAnalysis.analyzeRetrogrades(chartData);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.pop(context);
        },
      },
      child: ScaffoldPage(
        header: PageHeader(
          title: const Text('Retrograde Analysis'),
          leading: IconButton(
            icon: const Icon(FluentIcons.back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        content: ListView(
          padding: context.responsiveBodyPadding,
          children: [
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
                        const SizedBox(width: 12),
                        const Text(
                          'About Retrograde Motion',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
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

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      info.isRetrograde
                          ? FluentIcons.history
                          : FluentIcons.chevron_right,
                      color: info.isRetrograde ? Colors.orange : Colors.green,
                      size: 24,
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
                            color: info.isRetrograde
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(info.interpretation),
                        const SizedBox(height: 8),
                        Text(
                          'Frequency: ${RetrogradeAnalysis.getRetrogradeFrequency(planet)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
