import 'package:fluent_ui/fluent_ui.dart';

/// A video-editor style timeline scrubber for planetary animation
/// Allows users to drag to move forward/backward in time
class PlanetaryTimeline extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final DateTime currentDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback? onPlayPressed;
  final VoidCallback? onPausePressed;
  final bool isPlaying;
  final double playbackSpeed;
  final ValueChanged<double>? onSpeedChanged;

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

  @override
  State<PlanetaryTimeline> createState() => _PlanetaryTimelineState();
}

class _PlanetaryTimelineState extends State<PlanetaryTimeline> {
  bool _isDragging = false;
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _updateSliderValue();
  }

  @override
  void didUpdateWidget(covariant PlanetaryTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && oldWidget.currentDate != widget.currentDate) {
      _updateSliderValue();
    }
  }

  void _updateSliderValue() {
    final totalDuration = widget.endDate.difference(widget.startDate).inSeconds;
    final currentDuration = widget.currentDate.difference(widget.startDate).inSeconds;
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
            color: Colors.black.withOpacity(0.1),
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
                icon: Icon(widget.isPlaying ? FluentIcons.pause : FluentIcons.play),
                onPressed: widget.isPlaying ? widget.onPausePressed : widget.onPlayPressed,
              ),
              const SizedBox(width: 12),
              // Date display
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withOpacity(0.1),
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
              if (widget.onSpeedChanged != null)
                _buildSpeedDropdown(),
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
                child: GestureDetector(
                  onHorizontalDragStart: (_) => setState(() => _isDragging = true),
                  onHorizontalDragEnd: (_) => setState(() => _isDragging = false),
                  onHorizontalDragUpdate: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(details.globalPosition);
                    final width = box.size.width - 100; // Account for labels
                    final newValue = (localPosition.dx - 50).clamp(0.0, width) / width;
                    setState(() => _sliderValue = newValue.clamp(0.0, 1.0));
                    widget.onDateChanged(_calculateDateFromSlider(_sliderValue));
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.resources.subtleFillColorTertiary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Stack(
                      children: [
                        // Timeline ticks
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _TimelineTicksPainter(
                              color: theme.inactiveColor,
                            ),
                          ),
                        ),
                        // Progress fill
                        FractionallySizedBox(
                          widthFactor: _sliderValue,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.accentColor.withOpacity(0.3),
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        // Slider thumb
                        AnimatedPositioned(
                          duration: _isDragging ? Duration.zero : const Duration(milliseconds: 100),
                          left: _isDragging ? null : (_sliderValue * MediaQuery.of(context).size.width * 0.7) - 10,
                          top: 8,
                          bottom: 8,
                          child: Container(
                            width: 20,
                            decoration: BoxDecoration(
                              color: theme.accentColor,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
              Text(
                'Navigate',
                style: theme.typography.caption,
              ),
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
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
      ),
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

/// Painter for timeline tick marks
class _TimelineTicksPainter extends CustomPainter {
  final Color color;

  _TimelineTicksPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Draw major ticks every 10%
    for (int i = 0; i <= 10; i++) {
      final x = (size.width / 10) * i;
      canvas.drawLine(
        Offset(x, size.height * 0.2),
        Offset(x, size.height * 0.8),
        paint,
      );
    }

    // Draw minor ticks every 2%
    for (int i = 0; i <= 50; i++) {
      if (i % 5 == 0) continue; // Skip major ticks
      final x = (size.width / 50) * i;
      canvas.drawLine(
        Offset(x, size.height * 0.35),
        Offset(x, size.height * 0.65),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
