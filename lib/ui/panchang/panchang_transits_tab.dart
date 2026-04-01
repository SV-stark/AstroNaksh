import 'package:fluent_ui/fluent_ui.dart';
import '../../../data/models.dart';
import 'panchang_helpers.dart';

/// Tab 7: Transits (Panchak, Sade Sati, Dhaiya)
class PanchangTransitsTab extends StatelessWidget {
  final PanchakStatus? panchak;
  const PanchangTransitsTab({super.key, this.panchak});

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
            const Row(
              children: [
                Icon(FluentIcons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Panchak Active',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(panchak!.description),
            if (panchak!.daysRemaining > 0) ...[
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

    return const Card(
      child: Row(
        children: [
          Icon(FluentIcons.check_mark, color: Colors.green),
          SizedBox(width: 8),
          Text('Panchak Inactive - Auspicious activities can proceed'),
        ],
      ),
    );
  }
}
