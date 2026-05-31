// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' hide Colors, FontWeight;
import 'package:flutter/material.dart'
    show Colors, FontWeight, LinearProgressIndicator;
import 'package:jyotish/jyotish.dart';

import '../../core/ephemeris_manager.dart';

/// A premium Vedic Clock card for the home screen.
/// Shows the VedicDigitalClock + VedicAnalogClock and a Vedic↔Gregorian time converter.
class VedicClockCard extends StatefulWidget {
  const VedicClockCard({
    super.key,
    this.latitude = 28.6139,
    this.longitude = 77.2090,
  });
  final double latitude;
  final double longitude;

  @override
  State<VedicClockCard> createState() => _VedicClockCardState();
}

class _VedicClockCardState extends State<VedicClockCard> {
  int _tab = 0;
  VedicTime? _currentVedicTime;
  bool _isLoading = true;
  Timer? _refreshTimer;

  // Converter state
  int _convGhati = 0;
  int _convVighati = 0;
  int _convLipta = 0;
  DateTime? _convertedTime;

  GeographicLocation get _location => GeographicLocation(
    latitude: widget.latitude,
    longitude: widget.longitude,
  );

  @override
  void initState() {
    super.initState();
    _refreshVedicTime();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _refreshVedicTime();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshVedicTime() async {
    try {
      await EphemerisManager.ensureEphemerisData();
      final vt = await VedicTime.calculate(
        time: DateTime.now(),
        location: _location,
        getSunriseSunset: EphemerisManager.jyotish.getSunriseSunset,
      );
      if (mounted) {
        setState(() {
          _currentVedicTime = vt;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _convertToGregorian() {
    final vt = _currentVedicTime;
    if (vt == null) return;
    // Vedic time = elapsed since sunrise.
    // 1 Ghati = 24 minutes, 1 Vighati = 24 seconds, 1 Lipta = 0.4 seconds
    final secondsElapsed =
        _convGhati * 24 * 60 + _convVighati * 24 + (_convLipta * 24 ~/ 60);
    final converted = vt.currentSunrise.add(Duration(seconds: secondsElapsed));
    setState(() => _convertedTime = converted);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = FluentTheme.of(context).accentColor;

    return Card(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  Icon(FluentIcons.clock, color: accentColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Vedic Clock',
                    style: FluentTheme.of(context).typography.subtitle
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(DateTime.now()),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Tab row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  _tabButton('Clock View', 0, accentColor),
                  const SizedBox(width: 8),
                  _tabButton('Time Converter', 1, accentColor),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab content
            if (_tab == 0) _buildClockView(context, accentColor),
            if (_tab == 1) _buildConverterView(context, accentColor),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, int index, AccentColor accentColor) {
    final isSelected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildClockView(BuildContext context, AccentColor accentColor) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: ProgressRing()),
      );
    }
    final vt = _currentVedicTime;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Digital + Analog clocks
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Analog clock
              SizedBox(
                width: 120,
                height: 120,
                child: VedicAnalogClock(
                  location: _location,
                  getSunriseSunset: EphemerisManager.jyotish.getSunriseSunset,
                ),
              ),
              const SizedBox(width: 20),
              // Digital display
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VedicDigitalClock(
                      location: _location,
                      getSunriseSunset:
                          EphemerisManager.jyotish.getSunriseSunset,
                      showLocalTime: true,
                      showSunrise: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Progress bar + info
          if (vt != null) ...[
            const SizedBox(height: 16),
            // Day progress
            Row(
              children: [
                const Text(
                  'Day Progress',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${vt.totalGhatis.toStringAsFixed(1)} / 60 Ghatis',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (vt.totalGhatis / 60).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(accentColor),
              ),
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCell('Ghati', '${vt.ghati}'),
                _divider(),
                _statCell('Vighati', '${vt.vighati}'),
                _divider(),
                _statCell('Lipta', '${vt.lipta}'),
                _divider(),
                _statCell('Next Sunrise', _fmtTime(vt.nextSunrise)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConverterView(BuildContext context, AccentColor accentColor) {
    final vt = _currentVedicTime;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Now in Vedic
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(FluentIcons.sync_occurence, color: accentColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Now in Vedic Time',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vt != null ? vt.format() : '--:--:--',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (vt != null)
                        Text(
                          'Sunrise: ${_fmtTime(vt.currentSunrise)}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Converter: Vedic -> Gregorian
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vedic → Gregorian Converter',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _numSelector('Ghati', _convGhati, 0, 59, (v) {
                      setState(() => _convGhati = v);
                    }),
                    const SizedBox(width: 8),
                    _numSelector('Vighati', _convVighati, 0, 59, (v) {
                      setState(() => _convVighati = v);
                    }),
                    const SizedBox(width: 8),
                    _numSelector('Lipta', _convLipta, 0, 59, (v) {
                      setState(() => _convLipta = v);
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                Button(
                  onPressed: _convertToGregorian,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.calculator_delta, size: 14),
                      SizedBox(width: 6),
                      Text('Convert'),
                    ],
                  ),
                ),
                if (_convertedTime != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        FluentIcons.circle_right,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _fmtDateTime(_convertedTime!),
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numSelector(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  FluentIcons.chevron_left,
                  size: 12,
                  color: Colors.white70,
                ),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(
                  FluentIcons.chevron_right,
                  size: 12,
                  color: Colors.white70,
                ),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCell(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _fmtTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }

  String _fmtDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${_formatDate(local)} ${_fmtTime(local)}';
  }
}
