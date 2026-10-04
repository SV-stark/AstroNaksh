import 'package:fluent_ui/fluent_ui.dart';

/// Reusable widget to display strength as a visual meter
class StrengthMeter extends StatelessWidget {
  const StrengthMeter({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.showPercentage = true,
  });
  final double value; // 0-100
  final String label;
  final Color? color;
  final bool showPercentage;

  Color _getStrengthColor() {
    if (color != null) return color!;
    if (value >= 80) return Colors.green;
    if (value >= 60) return Colors.teal;
    if (value >= 40) return Colors.orange;
    if (value >= 20) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final strengthColor = _getStrengthColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: FluentTheme.of(context).typography.body,
              ),
            ),
            if (showPercentage)
              Text(
                value.toStringAsFixed(1),
                style: FluentTheme.of(context).typography.caption?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: strengthColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        // Custom Linear Progress Bar for explicit color control
        SizedBox(
          height: 6,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final progressWidth = (value / 100).clamp(0.0, 1.0) * width;

              return Stack(
                children: [
                  Container(
                    width: width,
                    decoration: BoxDecoration(
                      color: strengthColor.withValues(alpha: 0.2), // Background
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    width: progressWidth,
                    decoration: BoxDecoration(
                      color: strengthColor, // Foreground
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class CircularScoreIndicator extends StatelessWidget {
  const CircularScoreIndicator({
    super.key,
    required this.score,
    required this.label,
    this.size = 80,
  });
  final double score; // 0-100
  final String label;
  final double size;

  Color _getScoreColor() {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.teal;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: ProgressRing(
                  value: score,
                  strokeWidth: size * 0.15, // Slightly thicker
                  activeColor: _getScoreColor(),
                  backgroundColor: _getScoreColor().withValues(alpha: 0.1),
                ),
              ),
              Center(
                child: Text(
                  score.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: size * 0.35, // Adjust font size relative to ring
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: FluentTheme.of(context).typography.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
