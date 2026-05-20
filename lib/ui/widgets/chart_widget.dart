import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/chart_customization.dart';
import '../../core/settings_provider.dart';
import '../../logic/planetary_aspect_service.dart';
import '../painters/aspect_painter.dart';
import '../painters/north_indian_chart_painter.dart';
import '../painters/south_indian_chart_painter.dart';

class ChartWidget extends ConsumerWidget {
  const ChartWidget({
    super.key,
    required this.planetsBySign,
    required this.ascendantSign,
    required this.style,
    this.size = 300,
    this.aspects,
    this.showAspects = false,
    this.onHouseTapped,
  });
  final Map<int, List<String>> planetsBySign; // Key: 1-12
  final int ascendantSign; // 1-12
  final ChartStyle style;
  final double size;
  final List<PlanetaryAspect>? aspects;
  final bool showAspects;
  final void Function(int houseIndex)? onHouseTapped;

  int? _getHouseFromOffset(Offset offset, Size size) {
    if (style == ChartStyle.northIndian) {
      final width = size.width;
      final height = size.height;
      final centers = [
        Offset(width / 2, height / 4), // 1st
        Offset(width / 4, height / 8), // 2nd
        Offset(width / 8, height / 4), // 3rd
        Offset(width / 4, height / 2), // 4th
        Offset(width / 8, height * 0.75), // 5th
        Offset(width / 4, height * 0.875), // 6th
        Offset(width / 2, height * 0.75), // 7th
        Offset(width * 0.75, height * 0.875), // 8th
        Offset(width * 0.875, height * 0.75), // 9th
        Offset(width * 0.75, height / 2), // 10th
        Offset(width * 0.875, height / 4), // 11th
        Offset(width * 0.75, height / 8), // 12th
      ];
      int closestIndex = 0;
      double minDistance = double.infinity;
      for (int i = 0; i < 12; i++) {
        final dist = (offset - centers[i]).distance;
        if (dist < minDistance) {
          minDistance = dist;
          closestIndex = i;
        }
      }
      return closestIndex + 1;
    } else {
      final width = size.width;
      final height = size.height;
      final cellWidth = width / 4;
      final cellHeight = height / 4;

      final col = (offset.dx / cellWidth).floor().clamp(0, 3);
      final row = (offset.dy / cellHeight).floor().clamp(0, 3);

      int? signIndex;
      if (row == 0) {
        if (col == 1) signIndex = 0; // Aries
        else if (col == 2) signIndex = 1; // Taurus
        else if (col == 3) signIndex = 2; // Gemini
        else if (col == 0) signIndex = 11; // Pisces
      } else if (row == 1) {
        if (col == 3) signIndex = 3; // Cancer
        else if (col == 0) signIndex = 10; // Aquarius
      } else if (row == 2) {
        if (col == 3) signIndex = 4; // Leo
        else if (col == 0) signIndex = 9; // Capricorn
      } else if (row == 3) {
        if (col == 3) signIndex = 5; // Virgo
        else if (col == 2) signIndex = 6; // Libra
        else if (col == 1) signIndex = 7; // Scorpio
        else if (col == 0) signIndex = 8; // Sagittarius
      }

      if (signIndex == null) return null;

      // Map sign index back to house index based on ascendantSign (1-12)
      return (signIndex - ascendantSign + 1 + 12) % 12 + 1;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.maybeWhen(
      data: (settings) {
        final chartSettings = settings.chartSettings;
        final colors = chartSettings.colorScheme.colors;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colors.background, // Use theme background
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: GestureDetector(
            onTapUp: (details) {
              if (onHouseTapped != null) {
                final house = _getHouseFromOffset(details.localPosition, Size(size, size));
                if (house != null) {
                  onHouseTapped!(house);
                }
              }
            },
            child: Stack(
              children: [
                // Base chart painter
                CustomPaint(
                  size: Size(size, size),
                  painter: style == ChartStyle.northIndian
                      ? NorthIndianChartPainter(
                          planetsBySign: planetsBySign,
                          ascendantSign: ascendantSign,
                          colors: colors,
                        )
                      : SouthIndianChartPainter(
                          planetsBySign: planetsBySign,
                          ascendantSign: ascendantSign,
                          colors: colors,
                        ),
                ),
                // Aspect overlay
                if (showAspects && aspects != null && aspects!.isNotEmpty)
                  CustomPaint(
                    size: Size(size, size),
                    painter: AspectPainter(
                      aspects: aspects!,
                      planetsBySign: planetsBySign,
                      ascendantSign: ascendantSign,
                      colors: colors,
                      lineOpacity: 0.4,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      orElse: () => Container(
        width: size,
        height: size,
        color: Colors.grey.withValues(alpha: 0.1),
        child: const Center(child: ProgressRing()),
      ),
    );
  }
}
