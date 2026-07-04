// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' hide Colors, FontWeight;
import 'package:flutter/material.dart' show Colors, FontWeight;
import 'package:jyotish/jyotish.dart';

import '../../core/ephemeris_manager.dart';
import '../styles.dart';

/// A premium Vedic Clock card.
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
    final secondsElapsed =
        _convGhati * 24 * 60 + _convVighati * 24 + (_convLipta * 24 ~/ 60);
    final converted = vt.currentSunrise.add(Duration(seconds: secondsElapsed));
    setState(() => _convertedTime = converted);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A0F2E), Color(0xFF120A22), Color(0xFF0D0820)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppStyles.primaryColor.withValues(alpha: 0.18),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Subtle cosmic accent — glowing radial wash in top-right
              Positioned(
                top: -40,
                right: -40,
                child: IgnorePointer(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppStyles.primaryColor.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  _buildTabBar(context),
                  if (_tab == 0) _buildClockView(context),
                  if (_tab == 1) _buildConverterView(context),
                  const SizedBox(height: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final vt = _currentVedicTime;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppStyles.primaryColor.withValues(alpha: 0.32),
                  AppStyles.primaryColor.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              FluentIcons.clock,
              color: AppStyles.primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VEDIC MOMENT',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(DateTime.now()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (vt != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppStyles.primaryColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppStyles.primaryColor.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppStyles.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          _tabButton('Clock View', 0),
          const SizedBox(width: 24),
          _tabButton('Time Converter', 1),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _tab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppStyles.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildClockView(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: ProgressRing()),
      );
    }
    final vt = _currentVedicTime;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Hero: Analog clock with golden glow + digital display
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.primaryColor.withValues(alpha: 0.18),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppStyles.primaryColor.withValues(alpha: 0.35),
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: VedicAnalogClock(
                    location: _location,
                    getSunriseSunset: EphemerisManager.jyotish.getSunriseSunset,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: VedicDigitalClock(
                  location: _location,
                  getSunriseSunset: EphemerisManager.jyotish.getSunriseSunset,
                  showLocalTime: true,
                  showSunriseSunset: true,
                ),
              ),
            ],
          ),
          if (vt != null) ...[
            const SizedBox(height: 22),
            // Day progress
            Row(
              children: [
                const Text(
                  'DAY PROGRESS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: vt.totalGhatis.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppStyles.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(
                        text: ' / 60 Ghatis',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  FractionallySizedBox(
                    widthFactor: (vt.totalGhatis / 60).clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppStyles.primaryColor,
                            AppStyles.primaryColor.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Expanded(child: _statCell('GHATI', '${vt.ghati}')),
                  _divider(),
                  Expanded(child: _statCell('VIGHATI', '${vt.vighati}')),
                  _divider(),
                  Expanded(child: _statCell('LIPTA', '${vt.lipta}')),
                  _divider(),
                  Expanded(
                    child: _statCell('NEXT SUNRISE', _fmtTime(vt.nextSunrise)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConverterView(BuildContext context) {
    final vt = _currentVedicTime;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Now in Vedic — hero monospace display
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppStyles.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppStyles.primaryColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    FluentIcons.sync_occurence,
                    color: AppStyles.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOW IN VEDIC TIME',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vt != null ? vt.format() : '--:--:--',
                        style: const TextStyle(
                          color: AppStyles.primaryColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          height: 1.0,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (vt != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              FluentIcons.sunny,
                              size: 11,
                              color: Colors.white54,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sunrise ${_fmtTime(vt.currentSunrise)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
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
          ),
          const SizedBox(height: 16),
          // Converter card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      FluentIcons.calculator_delta,
                      size: 14,
                      color: AppStyles.primaryColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Vedic → Gregorian Converter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _numSelector('Ghati', _convGhati, 0, 59, (v) {
                      setState(() => _convGhati = v);
                    }),
                    const SizedBox(width: 10),
                    _numSelector('Vighati', _convVighati, 0, 59, (v) {
                      setState(() => _convVighati = v);
                    }),
                    const SizedBox(width: 10),
                    _numSelector('Lipta', _convLipta, 0, 59, (v) {
                      setState(() => _convLipta = v);
                    }),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.hovered)) {
                          return AppStyles.primaryColor.withValues(alpha: 0.85);
                        }
                        return AppStyles.primaryColor;
                      }),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    onPressed: _convertToGregorian,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FluentIcons.calculator_delta,
                          size: 14,
                          color: Colors.black87,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Convert',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_convertedTime != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppStyles.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppStyles.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FluentIcons.event,
                          size: 14,
                          color: AppStyles.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _fmtDateTime(_convertedTime!),
                            style: const TextStyle(
                              color: AppStyles.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    FluentIcons.chevron_left,
                    size: 11,
                    color: value > min ? Colors.white70 : Colors.white24,
                  ),
                  onPressed: value > min ? () => onChanged(value - 1) : null,
                ),
                SizedBox(
                  width: 28,
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    FluentIcons.chevron_right,
                    size: 11,
                    color: value < max ? Colors.white70 : Colors.white24,
                  ),
                  onPressed: value < max ? () => onChanged(value + 1) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCell(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.08),
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
