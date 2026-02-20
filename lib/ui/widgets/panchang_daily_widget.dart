import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import '../../logic/panchang_service.dart';
import '../../data/models.dart';
import 'package:intl/intl.dart';

class PanchangDailyWidget extends StatefulWidget {
  final Location? currentLocation;
  const PanchangDailyWidget({super.key, this.currentLocation});

  @override
  State<PanchangDailyWidget> createState() => _PanchangDailyWidgetState();
}

class _PanchangDailyWidgetState extends State<PanchangDailyWidget> {
  final PanchangService _panchangaService = PanchangService();
  PanchangResult? _todayPanchang;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPanchang();
  }

  Future<void> _loadPanchang() async {
    try {
      final loc =
          widget.currentLocation ??
          Location(latitude: 28.6139, longitude: 77.2090); // Default Delhi
      final result = await _panchangaService.getPanchang(DateTime.now(), loc);
      if (mounted) {
        setState(() {
          _todayPanchang = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 120, child: Center(child: ProgressRing()));
    }

    if (_todayPanchang == null) {
      return const SizedBox.shrink();
    }

    final p = _todayPanchang!;

    return Card(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              FluentTheme.of(context).accentColor.withValues(alpha: 0.8),
              FluentTheme.of(context).accentColor.darkest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        FluentIcons.cloud_weather,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Today's Sky",
                        style: FluentTheme.of(context).typography.subtitle
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                        style: FluentTheme.of(context).typography.body
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _buildInfoItem("Tithi", p.tithi),
                      _buildInfoItem("Nakshatra", p.nakshatra),
                      _buildInfoItem("Yoga", p.yoga),
                      _buildInfoItem("Karana", p.karana),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
