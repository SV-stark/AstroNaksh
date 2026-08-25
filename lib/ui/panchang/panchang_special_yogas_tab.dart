import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/muhurta.dart';

class PanchangSpecialYogasTab extends StatelessWidget {
  const PanchangSpecialYogasTab({super.key, required this.specialYogas});
  final List<SpecialYoga> specialYogas;

  @override
  Widget build(BuildContext context) {
    if (specialYogas.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.favorite_star,
              size: 56,
              color: Colors.grey.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'No Special Yogas Today',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 8),
            Text(
              'None of the 6 special Muhurta Yogas (Guru Pushya, Sarvartha Siddhi, etc.) '
              'are active for the selected date and location.',
              textAlign: TextAlign.center,
              style: FluentTheme.of(
                context,
              ).typography.caption?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(FluentIcons.info, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Special Yogas are rare intersections of Weekday, Tithi, and Nakshatra '
                    'that amplify results. Guru Pushya and Amrit Siddhi are the most auspicious.',
                    style: FluentTheme.of(context).typography.caption,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...specialYogas.map((yoga) => _buildYogaCard(context, yoga)),
      ],
    );
  }

  Widget _buildYogaCard(BuildContext context, SpecialYoga yoga) {
    final isAuspicious = yoga.isAuspicious;
    final color = isAuspicious ? Colors.green : Colors.orange;
    final icon = isAuspicious ? FluentIcons.starburst : FluentIcons.repeat_all;

    final label = switch (yoga.type) {
      SpecialYogaType.guruPushya => '👑 King of Yogas',
      SpecialYogaType.amritSiddhi => '✨ Highly Auspicious',
      SpecialYogaType.sarvarthaSiddhi => '🌟 General Success',
      SpecialYogaType.raviPushya => '☀️ Sun + Pushya',
      SpecialYogaType.dwiPushkar => '🔁 Results Doubled',
      SpecialYogaType.triPushkar => '🔁 Results Tripled',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            yoga.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (yoga.description != null &&
                        yoga.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        yoga.description!,
                        style: FluentTheme.of(context).typography.caption,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          FluentIcons.clock,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_fmt(yoga.startTime)} – ${_fmt(yoga.endTime)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }
}
