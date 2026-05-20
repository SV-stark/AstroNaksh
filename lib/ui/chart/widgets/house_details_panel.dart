import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as m;
import 'package:jyotish/jyotish.dart';

import '../../../core/constants.dart';
import '../../../data/models.dart';
import '../chart_helpers.dart';

class HouseDetailsPanel extends StatelessWidget {
  const HouseDetailsPanel({
    super.key,
    required this.houseIndex,
    required this.data,
    this.divisionalChart,
  });

  final int houseIndex; // 1-12
  final CompleteChartData data;
  final DivisionalChartData? divisionalChart;

  // House Names (Bhava Names)
  static const Map<int, String> _houseNames = {
    1: 'Tanu Bhava (Self / Identity)',
    2: 'Dhana Bhava (Wealth / Speech)',
    3: 'Sahaja Bhava (Courage / Siblings)',
    4: 'Bandhu Bhava (Mother / Happiness)',
    5: 'Putra Bhava (Children / Creativity)',
    6: 'Ari Bhava (Debts / Disease / Enemies)',
    7: 'Yuvati Bhava (Spouse / Partnerships)',
    8: 'Randhra Bhava (Longevity / Secrets)',
    9: 'Dharma Bhava (Fortune / Religion / Guru)',
    10: 'Karma Bhava (Profession / Status)',
    11: 'Labha Bhava (Gains / Desires)',
    12: 'Vyaya Bhava (Losses / Moksha / Foreign)',
  };

  // House Significations
  static const Map<int, String> _houseSignifications = {
    1: 'Physical body, appearance, character, health, longevity, beginnings, head, self-expression, and overall life path.',
    2: 'Wealth, family, speech, primary education, right eye, food, savings, oral expression, family history, and values.',
    3: 'Younger siblings, courage, short journeys, communication, writing, arms, hands, initiative, mental strength, and hobbies.',
    4: 'Mother, home environment, assets (land, vehicles), happiness, emotions, chest, basic education, peace of mind, and domestic life.',
    5: 'Children, intelligence, creativity, romance, speculation (stock market), purva punya (past life merits), upper abdomen, and education.',
    6: 'Enemies, obstacles, debts, daily labor, health/disease, service, pets, maternal uncle, lower abdomen, and litigation.',
    7: 'Spouse, marriage, partnership, public relations, foreign travels, business associates, lower back, pelvic region, and open interactions.',
    8: 'Longevity, sudden events, secrets, unearned wealth (inheritance), research, occult/astrology, chronic illnesses, transformation, and reproductive organs.',
    9: 'Dharma, fortune/luck, father, higher education, long-distance travel, spiritual teacher (Guru), thighs, moral values, and wisdom.',
    10: 'Career, profession, social status, fame, authority, knees, father\'s wealth, public identity, and achievements.',
    11: 'Gains, elder siblings, friends, fulfillment of desires, income source, calves, shins, networks, and aspirations.',
    12: 'Losses, expenditure, isolation (hospitals/prisons), foreign settlement, sleep/bed pleasures, moksha (liberation), feet, and charity.',
  };

  String _getSignLord(String signName) {
    switch (signName) {
      case 'Aries': return 'Mars';
      case 'Taurus': return 'Venus';
      case 'Gemini': return 'Mercury';
      case 'Cancer': return 'Moon';
      case 'Leo': return 'Sun';
      case 'Virgo': return 'Mercury';
      case 'Libra': return 'Venus';
      case 'Scorpio': return 'Mars';
      case 'Sagittarius': return 'Jupiter';
      case 'Capricorn': return 'Saturn';
      case 'Aquarius': return 'Saturn';
      case 'Pisces': return 'Jupiter';
      default: return 'Unknown';
    }
  }

  String _formatLongitude(double longitude) {
    final degInSign = longitude % 30;
    final degrees = degInSign.floor();
    final minutes = ((degInSign - degrees) * 60).floor();
    final seconds = (((degInSign - degrees) * 60 - minutes) * 60).round();
    return '${degrees.toString().padLeft(2, '0')}°${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = FluentTheme.of(context);

    // Calculate Sign and Sign Lord
    final int ascSign;
    final String signName;
    final List<String> planets = [];

    if (divisionalChart != null) {
      ascSign = divisionalChart!.ascendantSign ?? 1;
      final signNumber = (ascSign - 1 + houseIndex - 1) % 12 + 1;
      signName = ChartHelpers.getSignName(signNumber);

      divisionalChart!.positions.forEach((planetName, longitude) {
        final pSign = (longitude / 30).floor() + 1;
        final pHouse = (pSign - ascSign + 12) % 12 + 1;
        if (pHouse == houseIndex) {
          planets.add(planetName);
        }
      });
    } else {
      ascSign = ChartHelpers.getAscendantSignInt(data.baseChart);
      final signNumber = (ascSign - 1 + houseIndex - 1) % 12 + 1;
      signName = ChartHelpers.getSignName(signNumber);

      // Planets in this house
      data.baseChart.planets.forEach((planet, info) {
        final pSign = (info.longitude / 30).floor() + 1;
        final pHouse = (pSign - ascSign + 12) % 12 + 1;
        if (pHouse == houseIndex) {
          planets.add(planet.toString().split('.').last);
        }
      });

      // Rahu / Ketu
      final rahuSign = (data.baseChart.rahu.longitude / 30).floor() + 1;
      final rahuHouse = (rahuSign - ascSign + 12) % 12 + 1;
      if (rahuHouse == houseIndex) planets.add('Rahu');

      final ketuSign = (data.baseChart.ketu.longitude / 30).floor() + 1;
      final ketuHouse = (ketuSign - ascSign + 12) % 12 + 1;
      if (ketuHouse == houseIndex) planets.add('Ketu');
    }

    final signLord = _getSignLord(signName);

    // Cusp Info (only for base chart)
    String cuspDegStr = '';
    String cuspNak = '';
    int cuspPada = 1;
    if (divisionalChart == null && data.baseChart.houses.cusps.length >= houseIndex) {
      final cuspLon = data.baseChart.houses.cusps[houseIndex - 1];
      cuspDegStr = _formatLongitude(cuspLon);
      final nakIndex = (cuspLon / 13.333333).floor() % 27;
      cuspNak = AppConstants.nakshatras[nakIndex];
      cuspPada = ((cuspLon % 13.333333) / 3.333333).floor() + 1;
    }

    return Container(
      width: isMobile ? double.infinity : 380,
      height: isMobile ? MediaQuery.of(context).size.height * 0.65 : double.infinity,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF202020)
            : const Color(0xFFFAFAFA),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: isMobile ? const Offset(0, -5) : const Offset(-5, 0),
          ),
        ],
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : const BorderRadius.horizontal(left: Radius.circular(20)),
        border: Border.all(
          color: theme.resources.cardStrokeColorDefault,
          width: 1,
        ),
      ),
      child: m.Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Drag handle / Close bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.resources.dividerStrokeColorDefault,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        FluentIcons.home,
                        color: theme.accentColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'House $houseIndex Details',
                        style: theme.typography.subtitle,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.chrome_close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Panel Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Title Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _houseNames[houseIndex] ?? 'Bhava $houseIndex',
                            style: theme.typography.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.accentColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Sign: ',
                                style: theme.typography.caption?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$signName ($signLord)',
                                style: theme.typography.body,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Occupying Planets
                  Text(
                    'Planets in House',
                    style: theme.typography.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (planets.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'No planets present in this house.',
                          style: theme.typography.caption?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else Column(
                      children: planets.map((planet) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  FluentIcons.chevron_right_small,
                                  color: theme.accentColor,
                                  size: 12,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  planet,
                                  style: theme.typography.body?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),

                  // Cusp details (only for Rashi/D1)
                  if (divisionalChart == null && cuspDegStr.isNotEmpty) ...[
                    Text(
                      'Cusp Information',
                      style: theme.typography.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _buildInfoRow(context, 'Cusp Degree', cuspDegStr),
                            const Divider(),
                            _buildInfoRow(context, 'Nakshatra', cuspNak),
                            const Divider(),
                            _buildInfoRow(context, 'Nakshatra Pada', '$cuspPada'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // House Significations
                  Text(
                    'Significations & Karakatwas',
                    style: theme.typography.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _houseSignifications[houseIndex] ?? '',
                        style: theme.typography.body?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = FluentTheme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.typography.caption?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: theme.typography.body?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

void showHouseDetailsPanel({
  required BuildContext context,
  required int houseIndex,
  required CompleteChartData data,
  DivisionalChartData? divisionalChart,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      final isMobile = MediaQuery.of(context).size.width < 600;
      return Align(
        alignment: isMobile ? Alignment.bottomCenter : Alignment.centerRight,
        child: HouseDetailsPanel(
          houseIndex: houseIndex,
          data: data,
          divisionalChart: divisionalChart,
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final isMobile = MediaQuery.of(context).size.width < 600;
      return SlideTransition(
        position: Tween<Offset>(
          begin: isMobile ? const Offset(0, 1) : const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}
