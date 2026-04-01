import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import '../../../data/models.dart';
import 'panchang_helpers.dart';

/// Tab 1: Sun & Moon Times
class PanchangSunMoonTab extends StatelessWidget {
  final PanchangResult? result;
  final MoonPhaseDetails? moonPhase;
  final EclipseData? eclipseData;

  const PanchangSunMoonTab({
    super.key,
    this.result,
    this.moonPhase,
    this.eclipseData,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) return const Center(child: ProgressRing());

    final timeFormat = DateFormat('HH:mm');
    final sunrise = result!.sunrise != null
        ? timeFormat.format(result!.sunrise!)
        : 'N/A';
    final sunset = result!.sunset != null
        ? timeFormat.format(result!.sunset!)
        : 'N/A';
    final moonrise = result!.moonrise != null
        ? timeFormat.format(result!.moonrise!)
        : 'N/A';
    final moonset = result!.moonset != null
        ? timeFormat.format(result!.moonset!)
        : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTimeCard(
          title: 'Sunrise',
          time: sunrise,
          icon: FluentIcons.sunny,
          color: Colors.orange,
          description: 'First light of the day',
        ),
        const SizedBox(height: 8),
        buildTimeCard(
          title: 'Sunset',
          time: sunset,
          icon: FluentIcons.sunset,
          color: Colors.red,
          description: 'Last light of the day',
        ),
        const SizedBox(height: 8),
        buildTimeCard(
          title: 'Moonrise',
          time: moonrise,
          icon: FluentIcons.lightning_bolt,
          color: Colors.blue,
          description: 'Moon appears above horizon',
        ),
        const SizedBox(height: 8),
        buildTimeCard(
          title: 'Moonset',
          time: moonset,
          icon: FluentIcons.lightbulb,
          color: Colors.purple,
          description: 'Moon disappears below horizon',
        ),
        if (moonPhase != null) ...[
          const SizedBox(height: 16),
          buildSectionHeading('Moon Phase'),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moonPhase!.phaseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Illumination: ${(moonPhase!.illumination * 100).toStringAsFixed(1)}%',
                ),
                Text(
                  'Lunar Age: ${moonPhase!.lunarAge.toStringAsFixed(1)} days',
                ),
                Text(
                  moonPhase!.isWaxing
                      ? 'Waxing (growing)'
                      : 'Waning (shrinking)',
                ),
              ],
            ),
          ),
        ],
        if (eclipseData != null) ...[
          const SizedBox(height: 16),
          InfoBar(
            title: const Text('Eclipse Alert'),
            content: Text('${eclipseData!.type} eclipse detected'),
            severity: InfoBarSeverity.warning,
          ),
        ],
      ],
    );
  }
}
