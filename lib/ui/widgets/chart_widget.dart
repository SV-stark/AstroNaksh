import 'package:flutter/material.dart';
import '../painters/north_indian_chart_painter.dart';
import '../painters/south_indian_chart_painter.dart';
import '../styles.dart';

enum ChartStyle { northIndian, southIndian }

class ChartWidget extends StatelessWidget {
  final List<String> planetPositions;
  final ChartStyle style;
  final double size;

  const ChartWidget({
    super.key,
    required this.planetPositions,
    required this.style,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppStyles.surfaceColor,
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
                planetPositions: planetPositions,
                lineColor: AppStyles.accentColor,
              )
            : SouthIndianChartPainter(
                planetPositions: planetPositions,
                lineColor: AppStyles.accentColor,
              ),
      ),
    );
  }
}
