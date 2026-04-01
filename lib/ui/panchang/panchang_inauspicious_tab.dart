import 'package:fluent_ui/fluent_ui.dart';
import '../../../data/models.dart';
import 'panchang_helpers.dart';

/// Tab 2: Inauspicious Periods
class PanchangInauspiciousTab extends StatelessWidget {
  final List<PanchangInauspicious> inauspicious;
  const PanchangInauspiciousTab({super.key, this.inauspicious = const []});

  @override
  Widget build(BuildContext context) {
    if (inauspicious.isEmpty) {
      return const Center(child: Text('No inauspicious periods'));
    }
    return Column(
      children: inauspicious.map((p) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Expander(
            header: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text('${p.startTime} to ${p.endTime}'),
          ),
        );
      }).toList(),
    );
  }
}
