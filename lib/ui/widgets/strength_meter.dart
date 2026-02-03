import 'package:flutter/material.dart';

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
    if (value >= 60) return Colors.lightGreen;
    if (value >= 40) return Colors.orange;
    if (value >= 20) return Colors.deepOrange;
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
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            if (showPercentage)
              Text(
                '${value.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: strengthColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100.0,
            backgroundColor: strengthColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            minHeight: 8,
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
        return Colors.lightGreen;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.deepOrange;
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

/// Expandable info card
class ExpandableInfoCard extends StatefulWidget {
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
  State<ExpandableInfoCard> createState() => _ExpandableInfoCardState();
}

class _ExpandableInfoCardState extends State<ExpandableInfoCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: widget.icon != null
                ? Icon(widget.icon, color: widget.color)
                : null,
            title: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(widget.summary),
            trailing: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded)
            Padding(padding: const EdgeInsets.all(16.0), child: widget.details),
        ],
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
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.deepOrange;
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
                child: CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: size * 0.1,
                  backgroundColor: _getScoreColor().withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor()),
                ),
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
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
