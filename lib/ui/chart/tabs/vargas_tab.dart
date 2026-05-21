import 'package:fluent_ui/fluent_ui.dart';


import '../../../core/chart_customization.dart';
import '../../../core/constants.dart';
import '../../../data/models.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/chart_widget.dart';
import '../chart_helpers.dart';
import '../widgets/house_details_panel.dart';

class VargasTab extends StatelessWidget {
  const VargasTab({
    super.key,
    required this.data,
    required this.selectedDivisionalChart,
    required this.style,
    required this.onDivisionalChartChanged,
  });

  final CompleteChartData data;
  final String selectedDivisionalChart;
  final ChartStyle style;
  final ValueChanged<String> onDivisionalChartChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Divisional Charts (Vargas)',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling list for Charts
          SizedBox(
            height: ResponsiveHelper.useMobileLayout(context) ? 56 : 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                'D-1',
                'D-2',
                'D-3',
                'D-4',
                'D-7',
                'D-9',
                'D-10',
                'D-12',
                'D-16',
                'D-20',
                'D-24',
                'D-27',
                'D-30',
                'D-40',
                'D-45',
                'D-60',
                'D-150',
                'D-249',
              ].map(
                (code) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    height: ResponsiveHelper.useMobileLayout(context) ? 48 : 32,
                    child: ToggleButton(
                      checked: selectedDivisionalChart == code,
                      onChanged: (selected) {
                        if (selected) {
                          onDivisionalChartChanged(code);
                        }
                      },
                      child: Text(
                        code,
                        style: TextStyle(
                          fontSize: ResponsiveHelper.useMobileLayout(context) ? 16 : 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildDivisionalChartDisplay(context, data, selectedDivisionalChart),
        ],
      ),
    );
  }

  Widget _buildDivisionalChartDisplay(BuildContext context, CompleteChartData data, String code) {
    final chart = data.divisionalCharts[code];
    final chartSize = ResponsiveHelper.getChartSize(context);

    if (chart == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Chart data not available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '${chart.name} (${chart.code})',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            Text(
              chart.description,
              style: FluentTheme.of(context).typography.caption,
            ),
            if (chart.ascendantSign != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ascendant: ${ChartHelpers.getSignName(chart.ascendantSign! + 1)}',
                style: FluentTheme.of(context).typography.body,
              ),
            ],
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),
            ChartWidget(
              planetsBySign: ChartHelpers.getDivisionalPlanetsMap(chart),
              ascendantSign: (chart.ascendantSign ?? 0) + 1,
              style: style,
              size: chartSize,
              completeData: data,
              divisionalChart: chart,
              onHouseTapped: (houseIndex) {
                showHouseDetailsPanel(
                  context: context,
                  houseIndex: houseIndex,
                  data: data,
                  divisionalChart: chart,
                );
              },
            ),
            const SizedBox(height: 16),
            _buildDivisionalPlanetPositionsTable(context, chart),
          ],
        ),
      ),
    );
  }

  Widget _buildDivisionalPlanetPositionsTable(BuildContext context, DivisionalChartData chart) {
    final positions = chart.positions;
    const nakshatras = AppConstants.nakshatras;

    return SizedBox(
      width: double.infinity,
      child: Card(
        backgroundColor: FluentTheme.of(context).accentColor.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Planet Positions in ${chart.name}',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 16),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1.5),
                  4: FlexColumnWidth(0.6),
                },
                children: [
                  const TableRow(
                    children: [
                      Text(
                        'Planet',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Sign',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Degrees',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Nakshatra',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Pada',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const TableRow(
                    children: [
                      SizedBox(height: 8),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                    ],
                  ),
                  // Divider Row
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
                        ),
                      ),
                    ),
                    children: List.filled(5, const SizedBox(height: 4)),
                  ),
                  const TableRow(
                    children: [
                      SizedBox(height: 8),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                    ],
                  ),
                  ...positions.entries.map((entry) {
                    final planetName = entry.key;
                    final longitude = entry.value;

                    // Sign (1-12)
                    final signIndex = (longitude / 30).floor();
                    final signName = ChartHelpers.getSignName(signIndex + 1);

                    // Degrees within sign
                    final degInSign = longitude % 30;
                    final degrees = degInSign.floor();
                    final minutes = ((degInSign - degrees) * 60).floor();
                    final seconds =
                        (((degInSign - degrees) * 60 - minutes) * 60).round();
                    final degStr =
                        '${degrees.toString().padLeft(2, '0')}°${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';

                    // Nakshatra (each is 13°20' = 13.333...)
                    final nakshatraIndex = (longitude / 13.333333).floor() % 27;
                    final nakshatraName = nakshatras[nakshatraIndex];

                    // Pada (4 padas per nakshatra, each 3°20' = 3.333...)
                    final padaInNakshatra =
                        ((longitude % 13.333333) / 3.333333).floor() + 1;

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            planetName.substring(0, 1).toUpperCase() +
                                planetName.substring(1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(signName),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(degStr),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(nakshatraName),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('$padaInNakshatra'),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
