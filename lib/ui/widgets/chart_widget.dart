import 'package:fluent_ui/fluent_ui.dart';
import '../painters/north_indian_chart_painter.dart';
import '../painters/south_indian_chart_painter.dart';
import '../painters/aspect_painter.dart';
import '../../core/settings_manager.dart';
import '../../core/chart_customization.dart';
import '../../logic/planetary_aspect_service.dart';

enum ChartStyle { northIndian, southIndian }

class ChartWidget extends StatelessWidget {
  final Map<int, List<String>> planetsBySign; // Key: 0-11
  final int ascendantSign; // 1-12
  final ChartStyle style;
  final double size;
  final List<PlanetaryAspect>? aspects;
  final bool showAspects;

  const ChartWidget({
    super.key,
    required this.planetsBySign,
    required this.ascendantSign,
    required this.style,
    this.size = 300,
    this.aspects,
    this.showAspects = false,
  });

  @override
  Widget build(BuildContext context) {
    // Listen to SettingsManager for updates
    return ListenableBuilder(
      listenable: SettingsManager(),
      builder: (context, child) {
        final settings = SettingsManager().chartSettings;
        final colors = settings.colorScheme.colors;

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
        );
      },
    );
  }
}
