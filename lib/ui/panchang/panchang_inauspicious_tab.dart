import 'package:astronaksh/logic/panchang_service.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// Tab 2: Inauspicious Periods
class PanchangInauspiciousTab extends StatelessWidget {
  const PanchangInauspiciousTab({super.key, this.inauspicious = const []});
  final List<PanchangInauspicious> inauspicious;

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
