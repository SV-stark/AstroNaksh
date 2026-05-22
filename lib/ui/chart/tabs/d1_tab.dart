import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' as m;

import '../../../core/chart_customization.dart';
import '../../../data/models.dart';
import '../../../logic/planetary_aspect_service.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/chart_widget.dart';
import '../../widgets/planetary_timeline.dart';
import '../chart_helpers.dart';
import '../widgets/house_details_panel.dart';

class D1Tab extends StatelessWidget {
  const D1Tab({
    super.key,
    required this.data,
    required this.style,
    required this.showAspects,
    required this.timelineCurrentDate,
    required this.isTimelinePlaying,
    required this.timelineSpeed,
    required this.d1ChartKey,
    required this.onTimelineDateChanged,
    required this.onTimelinePlay,
    required this.onTimelinePause,
    required this.onTimelineSpeedChanged,
  });

  final CompleteChartData data;
  final ChartStyle style;
  final bool showAspects;
  final DateTime timelineCurrentDate;
  final bool isTimelinePlaying;
  final double timelineSpeed;
  final GlobalKey d1ChartKey;
  final ValueChanged<DateTime> onTimelineDateChanged;
  final VoidCallback onTimelinePlay;
  final VoidCallback onTimelinePause;
  final ValueChanged<double> onTimelineSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final planetsMap = ChartHelpers.getPlanetsMap(data.baseChart);
    final ascSign = ChartHelpers.getAscendantSignInt(data.baseChart);
    final aspects = PlanetaryAspectService.calculateAspects(data.baseChart);
    final chartSize = ResponsiveHelper.getChartSize(context);

    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        children: [
          Text(
            'Rashi Chart (D-1)',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 8),
          Text(
            'Lagna: ${ChartHelpers.getAscendantSign(data.baseChart)}',
            style: FluentTheme.of(context).typography.body,
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: d1ChartKey,
            child: ChartWidget(
              planetsBySign: planetsMap,
              ascendantSign: ascSign,
              style: style,
              size: chartSize,
              aspects: aspects,
              showAspects: showAspects,
              completeData: data,
              onHouseTapped: (houseIndex) {
                showHouseDetailsPanel(
                  context: context,
                  houseIndex: houseIndex,
                  data: data,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          // Timeline for planetary animation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        FluentIcons.timeline_progress,
                        size: 20,
                        color: FluentTheme.of(context).accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Planetary Timeline',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const Spacer(),
                      Text(
                        'Drag to see planetary motion',
                        style: FluentTheme.of(context).typography.caption
                            ?.copyWith(
                              color: FluentTheme.of(context).inactiveColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PlanetaryTimeline(
                    startDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    endDate: DateTime.now().add(const Duration(days: 365)),
                    currentDate: timelineCurrentDate,
                    onDateChanged: onTimelineDateChanged,
                    onPlayPressed: onTimelinePlay,
                    onPausePressed: onTimelinePause,
                    isPlaying: isTimelinePlaying,
                    playbackSpeed: timelineSpeed,
                    onSpeedChanged: onTimelineSpeedChanged,
                  ),
                  const SizedBox(height: 12),
                  // Show current date info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FluentTheme.of(
                        context,
                      ).accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.calendar,
                          size: 16,
                          color: FluentTheme.of(context).accentColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Viewing: ${timelineCurrentDate.day}/${timelineCurrentDate.month}/${timelineCurrentDate.year}',
                            style: FluentTheme.of(context).typography.body,
                          ),
                        ),
                        Text(
                          isTimelinePlaying ? 'Playing' : 'Paused',
                          style: FluentTheme.of(context).typography.caption
                              ?.copyWith(
                                color: isTimelinePlaying
                                    ? m.Colors.green
                                    : FluentTheme.of(context).inactiveColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ChartHelpers.buildPlanetPositionsTable(data: data, context: context),
        ],
      ),
    );
  }
}
