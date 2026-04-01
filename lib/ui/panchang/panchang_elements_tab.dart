import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/intl.dart';
import '../../../data/models.dart';
import '../../../ui/utils/responsive_helper.dart';
import 'panchang_helpers.dart';

/// Tab 0: Panchang Elements (Tithi, Nakshatra, Yoga, Karana, Vara)
class PanchangElementsTab extends StatelessWidget {
  final PanchangResult? result;
  final DateTime? tithiJunction;
  final bool isLoading;

  const PanchangElementsTab({
    super.key,
    this.result,
    this.tithiJunction,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || result == null) {
      return const Center(child: ProgressRing());
    }

    final useMobile = ResponsiveHelper.useMobileLayout(context);
    final timeFormat = DateFormat('HH:mm');
    final tithiEnd = tithiJunction != null
        ? timeFormat.format(tithiJunction!)
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
      ],
    );
  }
}
