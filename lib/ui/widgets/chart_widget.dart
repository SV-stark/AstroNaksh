import 'package:fluent_ui/fluent_ui.dart';
import '../painters/north_indian_chart_painter.dart';
import '../painters/south_indian_chart_painter.dart';

enum ChartStyle { northIndian, southIndian }

class ChartWidget extends StatelessWidget {
  final Map<int, List<String>> planetsBySign; // Key: 0-11
  final int ascendantSign; // 1-12
  final ChartStyle style;
  final double size;

  const ChartWidget({
    super.key,
    required this.planetsBySign,
    required this.ascendantSign,
    required this.style,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black;
    final southLineColor = isDark ? Colors.white : Colors.black;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CustomPaint(
        painter: style == ChartStyle.northIndian
            ? NorthIndianChartPainter(
                planetsBySign: planetsBySign,
                ascendantSign: ascendantSign,
                borderColor: borderColor,
                textColor: textColor,
              )
            : SouthIndianChartPainter(
                planetsBySign: planetsBySign,
                ascendantSign: ascendantSign,
                lineColor: southLineColor,
                textColor: textColor,
              ),
      ),
    );
  }
}
