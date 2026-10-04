import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/muhurta.dart';

import '../../../logic/panchang_service.dart';
import 'panchang_helpers.dart';

/// Tab 3: Muhurta
///
/// Surfaces the day's named muhurtas plus a consolidated list of the auspicious
/// windows already computed by the panchang (Shubha Choghadiya, Abhijit and
/// Brahma). This replaces a "coming soon" placeholder with data the surrounding
/// screens had already loaded.
class PanchangMuhurtaTab extends StatelessWidget {
  const PanchangMuhurtaTab({
    super.key,
    this.abhijit,
    this.brahma,
    this.choghadiya = const [],
  });

  final AbhijitMuhurta? abhijit;
  final BrahmaMuhurta? brahma;
  final List<PanchangChoghadiya> choghadiya;

  /// Choghadiya periods the tradition treats as universally auspicious.
  static const _shubhaChoghadiya = {
    'Amrit',
    'Shubh',
    'Chakshush',
    'Labh',
    'Chamath',
  };

  @override
  Widget build(BuildContext context) {
    final auspicious = choghadiya
        .where((c) => _shubhaChoghadiya.contains(c.name.trim()))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSectionHeading('Auspicious Windows Today'),
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
        if (auspicious.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No Shubha Choghadiya windows for this date.',
              style: TextStyle(
                color: FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFB3B3B3)
                    : const Color(0xFF5A5A5A),
              ),
            ),
          )
        else
          ...auspicious.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: buildTimeCard(
                title: '${c.name} (${c.isDay ? 'Day' : 'Night'})',
                time: '${c.startTime} - ${c.endTime}',
                icon: FluentIcons.accept,
                color: const Color(0xFF2E7D32),
                description:
                    'Shubha Choghadiya - favourable for auspicious '
                    'undertakings.',
              ),
            ),
          ),
      ],
    );
  }
}