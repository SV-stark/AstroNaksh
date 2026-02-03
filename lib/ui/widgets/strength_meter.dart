import 'package:fluent_ui/fluent_ui.dart';

/// Reusable widget to display strength as a visual meter
class StrengthMeter extends StatelessWidget {
  final double value; // 0-100
  final String label;
  final Color? color;
  final bool showPercentage;

  const StrengthMeter({
    super.key,
    required this.value,
    required this.label,
    this.color,
    this.showPercentage = true,
  });

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
                      color: strengthColor.withOpacity(0.2), // Background
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

/// Grade badge (A, B, C, D, F)
class GradeBadge extends StatelessWidget {
  final String grade;
  final double? size;

  const GradeBadge({super.key, required this.grade, this.size});

  Color _getGradeColor() {
    switch (grade) {
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.teal;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.orange;
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradeSize = size ?? 32;
    return Container(
      width: gradeSize,
      height: gradeSize,
      decoration: BoxDecoration(
        color: _getGradeColor(),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        grade,
        style: TextStyle(
          color: Colors.white,
          fontSize: gradeSize * 0.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Expandable info card using Expander
class ExpandableInfoCard extends StatelessWidget {
  final String title;
  final String summary;
  final Widget details;
  final IconData? icon;
  final Color? color;

  const ExpandableInfoCard({
    super.key,
    required this.title,
    required this.summary,
    required this.details,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Expander(
        header: Row(
          children: [
            if (icon != null) ...[
              Icon(icon!, color: color),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    summary,
                    style: FluentTheme.of(context).typography.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: details,
      ),
    );
  }
}

/// Score indicator with circular progress
class CircularScoreIndicator extends StatelessWidget {
  final double score; // 0-100
  final String label;
  final double size;

  const CircularScoreIndicator({
    super.key,
    required this.score,
    required this.label,
    this.size = 80,
  });

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
              ProgressRing(
                value: score,
                strokeWidth: size * 0.1,
                activeColor: _getScoreColor(),
                backgroundColor: _getScoreColor().withOpacity(0.2),
              ),
              Text(
                score.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(),
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
