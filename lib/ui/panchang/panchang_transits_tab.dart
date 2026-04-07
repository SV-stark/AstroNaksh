import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';
import 'panchang_helpers.dart';

/// Tab 7: Transits (Panchak, Sade Sati, Dhaiya)
class PanchangTransitsTab extends StatelessWidget {
  const PanchangTransitsTab({super.key, this.panchak});
  final PanchakStatus? panchak;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPanchakCard(),
        const SizedBox(height: 16),
        const InfoBar(
          title: Text('Sade Sati & Dhaiya'),
          content: Text(
            'Sade Sati and Dhaiya analysis requires a birth chart. '
            'Navigate to a chart and check transits there.',
          ),
          severity: InfoBarSeverity.info,
        ),
      ],
    );
  }

  Widget _buildPanchakCard() {
    if (panchak == null) {
      return const Card(child: Center(child: ProgressRing()));
    }

    if (panchak!.isActive) {
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Panchak Active',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(panchak!.description),
            if ((panchak!.daysRemaining ?? 0) > 0) ...[
              const SizedBox(height: 4),
              Text('Days remaining: ${panchak!.daysRemaining}'),
            ],
            if (panchak!.precautions.isNotEmpty) ...[
              const SizedBox(height: 8),
              buildSectionHeading('Precautions'),
              ...panchak!.precautions.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $p'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Card(
      child: Row(
        children: [
          Icon(FluentIcons.check_mark, color: Colors.green),
          const SizedBox(width: 8),
          const Text('Panchak Inactive - Auspicious activities can proceed'),
        ],
      ),
    );
  }
}
