import 'package:fluent_ui/fluent_ui.dart';
import '../../../data/models.dart';
import 'panchang_helpers.dart';

/// Tab 4: Hora
class PanchangHoraTab extends StatelessWidget {
  final List<PanchangHora> horas;
  const PanchangHoraTab({super.key, this.horas = const []});

  @override
  Widget build(BuildContext context) {
    if (horas.isEmpty)
      return const Center(child: Text('No Hora data available'));

    return Column(
      children: horas.map((h) {
        final isDay = h.isDay;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Card(
            child: Row(
              children: [
                Icon(isDay ? FluentIcons.sunny : FluentIcons.moon, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.planet,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isDay ? 'Day Hora' : 'Night Hora',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${h.startTime} - ${h.endTime}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
