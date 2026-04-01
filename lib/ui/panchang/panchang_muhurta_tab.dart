import 'package:fluent_ui/fluent_ui.dart';
import '../../../data/models.dart';
import 'panchang_helpers.dart';

/// Tab 3: Muhurta
class PanchangMuhurtaTab extends StatelessWidget {
  final AbhijitMuhurta? abhijit;
  final BrahmaMuhurta? brahma;
  const PanchangMuhurtaTab({super.key, this.abhijit, this.brahma});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (abhijit != null)
          buildMuhurtaCard(
            'Abhijit Muhurta',
            abhijit!.start,
            abhijit!.end,
            FluentIcons.diamond,
            Colors.green,
            abhijit!.description,
          ),
        if (brahma != null) ...[
          const SizedBox(height: 8),
          buildMuhurtaCard(
            'Brahma Muhurta',
            brahma!.start,
            brahma!.end,
            FluentIcons.lightbulb,
            Colors.blue,
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
