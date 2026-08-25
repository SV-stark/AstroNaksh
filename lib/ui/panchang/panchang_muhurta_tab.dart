import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/muhurta.dart';
import 'panchang_helpers.dart';

/// Tab 3: Muhurta
class PanchangMuhurtaTab extends StatelessWidget {
  const PanchangMuhurtaTab({super.key, this.abhijit, this.brahma});
  final AbhijitMuhurta? abhijit;
  final BrahmaMuhurta? brahma;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (abhijit != null)
          buildMuhurtaCard(
            'Abhijit Muhurta',
            abhijit!.startTime,
            abhijit!.endTime,
            FluentIcons.starburst,
            Colors.orange,
            abhijit!.description,
          ),
        if (brahma != null) ...[
          const SizedBox(height: 8),
          buildMuhurtaCard(
            'Brahma Muhurta',
            brahma!.startTime,
            brahma!.endTime,
            FluentIcons.clear_night,
            Colors.purple,
            brahma!.description,
          ),
        ],
        const SizedBox(height: 16),
        const InfoBar(
          title: Text('More Muhurtas'),
          content: Text('Additional Muhurta calculations coming soon.'),
          severity: InfoBarSeverity.info,
        ),
      ],
    );
  }
}
