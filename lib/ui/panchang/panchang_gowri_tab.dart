import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/muhurta.dart';
import 'panchang_helpers.dart';

/// Tab 6: Gowri Panchanga
class PanchangGowriTab extends StatelessWidget {
  const PanchangGowriTab({super.key, this.gowri});
  final GowriPanchangamInfo? gowri;

  @override
  Widget build(BuildContext context) {
    if (gowri == null) return const Center(child: ProgressRing());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gowri!.type.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(gowri!.description),
              const SizedBox(height: 8),
              buildInfoRow('Time of Day', gowri!.isDaytime ? 'Day' : 'Night'),
              buildInfoRow('Period', '${gowri!.periodNumber}'),
              buildInfoRow(
                'Auspicious',
                gowri!.type.isAuspicious ? 'Yes' : 'No',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const InfoBar(
          title: Text('About Gowri Panchanga'),
          content: Text(
            'Gowri Panchanga divides the day into 5 periods ruled by Gowri. '
            'Each period has unique qualities for planning activities.',
          ),
          severity: InfoBarSeverity.info,
        ),
      ],
    );
  }
}
