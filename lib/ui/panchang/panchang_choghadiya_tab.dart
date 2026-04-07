import 'package:fluent_ui/fluent_ui.dart';
import '../../../logic/panchang_service.dart';
import 'panchang_helpers.dart';

/// Tab 5: Choghadiya
class PanchangChoghadiyaTab extends StatelessWidget {
  const PanchangChoghadiyaTab({super.key, this.choghadiya = const []});
  final List<PanchangChoghadiya> choghadiya;

  @override
  Widget build(BuildContext context) {
    if (choghadiya.isEmpty) {
      return const Center(child: Text('No Choghadiya data'));
    }

    final day = choghadiya.where((c) => c.isDay).toList();
    final night = choghadiya.where((c) => !c.isDay).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (day.isNotEmpty) ...[
          buildSectionHeading('Day Choghadiya'),
          buildChoghadiyaList(day),
        ],
        if (night.isNotEmpty) ...[
          const SizedBox(height: 16),
          buildSectionHeading('Night Choghadiya'),
          buildChoghadiyaList(night),
        ],
      ],
    );
  }
}
