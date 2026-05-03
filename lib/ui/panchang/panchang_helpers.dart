// ignore_for_file: avoid_slow_async_io, unawaited_futures, deprecated_member_use, sort_constructors_first, implementation_imports
import 'package:fluent_ui/fluent_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../logic/panchang_service.dart';

/// Reusable helper widgets for the Panchang screen.
/// Extracted to eliminate duplication and reduce the main screen's size.

Widget buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget buildSectionHeading(String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );
}

Widget buildTabButton({
  required IconData icon,
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Button(
      onPressed: onTap,
      style: ButtonStyle(
        backgroundColor: ButtonState.all(
          isSelected ? Colors.blue : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(label)],
      ),
    ),
  );
}

Widget buildTimeCard({
  required String title,
  required String time,
  required IconData icon,
  required Color color,
  required String description,
}) {
  return Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Text(time, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(description, style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );
}

Widget buildPanchangCard({
  required String title,
  required String value,
  required String subtitle,
  required IconData icon,
  required Color color,
  required String description,
}) {
  return Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ],
    ),
  );
}

Widget buildChoghadiyaList(List<PanchangChoghadiya> list) {
  final typeColors = {
    'Shubh': Colors.green,
    'Amrit': Colors.green,
    'Labh': Colors.green,
    'Rog': Colors.red,
    'Kaal': Colors.red,
    'Udveg': Colors.red,
    'Char': Colors.orange,
  };

  return Column(
    children: list.map((c) {
      final color = typeColors[c.type] ?? Colors.grey;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Card(
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(c.type, style: TextStyle(color: color)),
                  ],
                ),
              ),
              Text(
                '${c.startTime} - ${c.endTime}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }).toList(),
  );
}

Widget buildMuhurtaCard(
  String title,
  DateTime start,
  DateTime end,
  IconData icon,
  Color color,
  String desc,
) {
  return Expander(
    header: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        Text('${AppFormatters.formatTime(start)} - ${AppFormatters.formatTime(end)}'),
      ],
    ),
    content: Padding(padding: const EdgeInsets.all(8), child: Text(desc)),
  );
}
