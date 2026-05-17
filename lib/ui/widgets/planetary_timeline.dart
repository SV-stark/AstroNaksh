import 'package:fluent_ui/fluent_ui.dart';

/// A video-editor style timeline scrubber for planetary animation
/// Allows users to drag to move forward/backward in time
class PlanetaryTimeline extends StatefulWidget {
  const PlanetaryTimeline({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.currentDate,
    required this.onDateChanged,
    this.onPlayPressed,
    this.onPausePressed,
    this.isPlaying = false,
    this.playbackSpeed = 1.0,
    this.onSpeedChanged,
  });
  final DateTime startDate;
  final DateTime endDate;
  final DateTime currentDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback? onPlayPressed;
  final VoidCallback? onPausePressed;
  final bool isPlaying;
  final double playbackSpeed;
  final ValueChanged<double>? onSpeedChanged;

  @override
  State<PlanetaryTimeline> createState() => _PlanetaryTimelineState();
}

class _PlanetaryTimelineState extends State<PlanetaryTimeline> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _updateSliderValue();
  }

  @override
  void didUpdateWidget(covariant PlanetaryTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDate != widget.currentDate) {
      _updateSliderValue();
    }
  }

  void _updateSliderValue() {
    final totalDuration = widget.endDate.difference(widget.startDate).inSeconds;
    final currentDuration = widget.currentDate
        .difference(widget.startDate)
        .inSeconds;
    _sliderValue = totalDuration > 0 ? currentDuration / totalDuration : 0.0;
  }

  DateTime _calculateDateFromSlider(double value) {
    final totalDuration = widget.endDate.difference(widget.startDate).inSeconds;
    final secondsFromStart = (value * totalDuration).round();
    return widget.startDate.add(Duration(seconds: secondsFromStart));
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.resources.dividerStrokeColorDefault,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timeline header with date display
          Row(
            children: [
              // Play/Pause button
              IconButton(
                icon: Icon(
                  widget.isPlaying ? FluentIcons.pause : FluentIcons.play,
                ),
                onPressed: widget.isPlaying
                    ? widget.onPausePressed
                    : widget.onPlayPressed,
              ),
              const SizedBox(width: 12),
              // Date display
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDate(widget.currentDate),
                    textAlign: TextAlign.center,
                    style: theme.typography.body?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Consolas',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Speed control
              if (widget.onSpeedChanged != null) _buildSpeedDropdown(),
            ],
          ),
          const SizedBox(height: 12),
          // Timeline slider
          Row(
            children: [
              // Start date label
              Text(
                _formatShortDate(widget.startDate),
                style: theme.typography.caption?.copyWith(
                  color: theme.inactiveColor,
                ),
              ),
              const SizedBox(width: 8),
              // Timeline track
              Expanded(
                child: Slider(
                  value: _sliderValue,
                  onChanged: (newValue) {
                    setState(() => _sliderValue = newValue);
                    widget.onDateChanged(
                      _calculateDateFromSlider(newValue),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              // End date label
              Text(
                _formatShortDate(widget.endDate),
                style: theme.typography.caption?.copyWith(
                  color: theme.inactiveColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Quick navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickNavButton(
                icon: FluentIcons.previous,
                tooltip: 'Previous Day',
                onPressed: () => _adjustDate(const Duration(days: -1)),
              ),
              _buildQuickNavButton(
                icon: FluentIcons.back,
                tooltip: 'Previous Hour',
                onPressed: () => _adjustDate(const Duration(hours: -1)),
              ),
              const SizedBox(width: 16),
              Text('Navigate', style: theme.typography.caption),
              const SizedBox(width: 16),
              _buildQuickNavButton(
                icon: FluentIcons.forward,
                tooltip: 'Next Hour',
                onPressed: () => _adjustDate(const Duration(hours: 1)),
              ),
              _buildQuickNavButton(
                icon: FluentIcons.next,
                tooltip: 'Next Day',
                onPressed: () => _adjustDate(const Duration(days: 1)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedDropdown() {
    final speeds = [0.5, 1.0, 2.0, 5.0, 10.0];

    return DropDownButton(
      title: Text('${widget.playbackSpeed}x'),
      items: speeds.map((speed) {
        return MenuFlyoutItem(
          text: Text('${speed}x'),
          onPressed: () => widget.onSpeedChanged?.call(speed),
        );
      }).toList(),
    );
  }

  Widget _buildQuickNavButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(icon: Icon(icon, size: 16), onPressed: onPressed),
    );
  }

  void _adjustDate(Duration duration) {
    final newDate = widget.currentDate.add(duration);
    if (newDate.isAfter(widget.startDate) && newDate.isBefore(widget.endDate)) {
      widget.onDateChanged(newDate);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
  }
}
