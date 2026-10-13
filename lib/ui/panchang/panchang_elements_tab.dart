import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/muhurta.dart';

import '../../../core/utils/formatters.dart';
import '../../../logic/panchang_service.dart';
import '../../../ui/utils/responsive_helper.dart';
import 'panchang_helpers.dart';

/// Tab 0: Panchang Elements (Tithi, Nakshatra, Yoga, Karana, Vara)
class PanchangElementsTab extends StatelessWidget {
  const PanchangElementsTab({
    super.key,
    this.result,
    this.tithiJunction,
    this.isLoading = false,
  });
  final PanchangResult? result;
  final DateTime? tithiJunction;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading || result == null) {
      return const Center(child: ProgressRing());
    }

    final useMobile = ResponsiveHelper.useMobileLayout(context);
    final tithiEnd = tithiJunction != null
        ? AppFormatters.formatTime(tithiJunction!)
        : 'N/A';

    return GridView.count(
      crossAxisCount: useMobile ? 1 : 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: useMobile ? 2.5 : 1.5,
      children: [
        buildPanchangCard(
          title: 'Tithi',
          value: result!.tithi,
          subtitle: 'Ends: $tithiEnd',
          icon: FluentIcons.calendar_day,
          color: Colors.blue,
          description: 'Lunar day in the Hindu calendar',
        ),
        buildPanchangCard(
          title: 'Nakshatra',
          value: result!.nakshatra,
          subtitle: '',
          icon: FluentIcons.starburst,
          color: Colors.purple,
          description: 'Lunar mansion governing the day',
        ),
        buildPanchangCard(
          title: 'Yoga',
          value: result!.yoga,
          subtitle: '',
          icon: FluentIcons.sync,
          color: Colors.green,
          description: 'Auspicious combination of Sun and Moon',
        ),
        buildPanchangCard(
          title: 'Karana',
          value: result!.karana,
          subtitle: '',
          icon: FluentIcons.half_alpha,
          color: Colors.orange,
          description: 'Half of a Tithi, used for Muhurta',
        ),
        buildPanchangCard(
          title: 'Vara',
          value: result!.vara,
          subtitle: '',
          icon: FluentIcons.calendar,
          color: Colors.red,
          description: 'Day of the week ruled by a planet',
        ),
        if (result!.lunarMonth != null)
          buildPanchangCard(
            title: 'Lunar Month',
            value: result!.lunarMonth!,
            subtitle: 'Samvatsara: ${result!.samvatsara ?? 'N/A'}',
            icon: FluentIcons.calendar_day,
            color: Colors.purple,
            description: 'Hindu lunar month name',
          ),
        if (result!.ritu != null)
          buildPanchangCard(
            title: 'Ritu (Season)',
            value: result!.ritu!,
            subtitle: 'Ayana: ${result!.ayana ?? 'N/A'}',
            icon: FluentIcons.calendar_day,
            color: Colors.teal,
            description: 'Hindu season and solar half-year',
          ),
        if (result!.chandrabalam != null)
          buildPanchangCard(
            title: 'Chandrabalam',
            value: _getChandrabalamOverall(result!.chandrabalam!),
            subtitle:
                'Moon Rashi index: ${result!.chandrabalam!.moonRashiIndex}',
            icon: FluentIcons.brightness,
            color: Colors.orange,
            description: 'Moon strength across all 12 rashis',
          ),
        if (result!.tarabalam != null)
          buildPanchangCard(
            title: 'Tarabalam',
            value: result!.tarabalam!.taraType.name,
            subtitle: result!.tarabalam!.isAuspicious
                ? 'Auspicious - ${result!.tarabalam!.taraType.meaning}'
                : 'Inauspicious - ${result!.tarabalam!.taraType.meaning}',
            icon: FluentIcons.starburst,
            color: Colors.blue,
            description: 'Star strength relative to birth nakshatra',
          ),
        if (result!.rituals != null)
          buildPanchangCard(
            title: 'Ritual Readiness',
            value: 'Homa: ${result!.rituals!.homahuti.description}',
            subtitle:
                'Agni: ${result!.rituals!.agnivasa} • Shiva: ${result!.rituals!.shivavasa}',
            icon: FluentIcons.brightness,
            color: Colors.magenta,
            description:
                'Kumbha Chakra: ${result!.rituals!.kumbhaChakra.description}',
          ),
      ],
    );
  }

  String _getChandrabalamOverall(ChandrabalamInfo info) {
    final strong = info.entries.where((e) => e.level.name == 'strong').length;
    final moderate = info.entries
        .where((e) => e.level.name == 'moderate')
        .length;
    return '$strong Strong / $moderate Moderate / ${12 - strong - moderate} Weak';
  }
}
