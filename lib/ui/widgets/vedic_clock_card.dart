// ignore_for_file: deprecated_member_use, sort_constructors_first
import 'dart:async';
import 'dart:math' as math;

import 'package:fluent_ui/fluent_ui.dart' hide Colors, FontWeight;
import 'package:flutter/material.dart' show Colors, FontWeight;
import 'package:jyotish/jyotish.dart';

import '../../core/ephemeris_manager.dart';
import '../styles.dart';

/// Information about a Vedic Prahar (3-hour / 7.5-Ghati quadrant)
class PraharInfo {
  const PraharInfo({
    required this.number,
    required this.name,
    required this.sanskrit,
    required this.meaning,
    required this.energy,
    required this.isDay,
    required this.startGhati,
    required this.endGhati,
  });

  final int number; // 1 to 8
  final String name;
  final String sanskrit;
  final String meaning;
  final String energy;
  final bool isDay;
  final double startGhati;
  final double endGhati;

  static const List<PraharInfo> all = [
    PraharInfo(
      number: 1,
      name: 'Pratah (Early Morning)',
      sanskrit: 'प्रातः प्रहर',
      meaning: 'Sunrise to Mid-Morning',
      energy: 'Spiritual, Meditation, Planning',
      isDay: true,
      startGhati: 0.0,
      endGhati: 7.5,
    ),
    PraharInfo(
      number: 2,
      name: 'Sangava (Mid-Morning)',
      sanskrit: 'सांगव प्रहर',
      meaning: 'Mid-Morning to Noon',
      energy: 'Action, Learning, Commerce',
      isDay: true,
      startGhati: 7.5,
      endGhati: 15.0,
    ),
    PraharInfo(
      number: 3,
      name: 'Madhyahna (Noon)',
      sanskrit: 'मध्याह्न प्रहर',
      meaning: 'Solar Zenith / Abhijit',
      energy: 'Vitality, Nourishment, Victory',
      isDay: true,
      startGhati: 15.0,
      endGhati: 22.5,
    ),
    PraharInfo(
      number: 4,
      name: 'Aparahna (Afternoon)',
      sanskrit: 'अपराह्न प्रहर',
      meaning: 'Mid-Afternoon to Sunset',
      energy: 'Completion, Rest, Reflection',
      isDay: true,
      startGhati: 22.5,
      endGhati: 30.0,
    ),
    PraharInfo(
      number: 5,
      name: 'Sayam / Pradosha (Twilight)',
      sanskrit: 'सायं / प्रदोष प्रहर',
      meaning: 'Sunset to Early Night',
      energy: 'Evening Puja, Harmony, Unwinding',
      isDay: false,
      startGhati: 30.0,
      endGhati: 37.5,
    ),
    PraharInfo(
      number: 6,
      name: 'Nishita (Midnight)',
      sanskrit: 'निशीथ प्रहर',
      meaning: 'Night to Cosmic Midnight',
      energy: 'Deep Silence, Yoga, Regeneration',
      isDay: false,
      startGhati: 37.5,
      endGhati: 45.0,
    ),
    PraharInfo(
      number: 7,
      name: 'Triyama (Late Night)',
      sanskrit: 'त्रियाम प्रहर',
      meaning: 'Midnight to Pre-Dawn',
      energy: 'Deep Sleep, Subconscious Healing',
      isDay: false,
      startGhati: 45.0,
      endGhati: 52.5,
    ),
    PraharInfo(
      number: 8,
      name: 'Usha / Brahma (Dawn)',
      sanskrit: 'उषा / ब्राह्म प्रहर',
      meaning: 'Pre-Dawn to Sunrise',
      energy: 'Brahma Muhurta, Highest Consciousness',
      isDay: false,
      startGhati: 52.5,
      endGhati: 60.0,
    ),
  ];

  static PraharInfo fromGhatis(double totalGhatis) {
    final clamped = totalGhatis.clamp(0.0, 59.9999);
    final index = (clamped / 7.5).floor().clamp(0, 7);
    return all[index];
  }
}

/// Ultra-Modern Cosmic Vedic Clock & Moment Dashboard Card
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

class _VedicClockCardState extends State<VedicClockCard>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: Live Chronometer, 1: Converter, 2: Vedic Units Guide
  VedicTime? _currentVedicTime;
  DateTime _currentTime = DateTime.now();
  bool _isLoading = true;
  Timer? _tickerTimer;

  // Converter State
  int _convGhati = 15;
  int _convVighati = 0;
  int _convLipta = 0;
  DateTime? _convertedGregorian;

  // Gregorian to Vedic Converter State
  DateTime _selectedGregTime = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 12, 0);
  VedicTime? _convertedVedic;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  GeographicLocation get _location => GeographicLocation(
        latitude: widget.latitude,
        longitude: widget.longitude,
        altitude: 0,
      );

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _refreshVedicTime();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
        _refreshVedicTime();
      }
    });
  }

  @override
  void didUpdateWidget(covariant VedicClockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != oldWidget.latitude ||
        widget.longitude != oldWidget.longitude) {
      _refreshVedicTime();
    }
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _pulseController.dispose();
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

  void _convertVedicToGregorian() {
    final vt = _currentVedicTime;
    if (vt == null) return;
    final totalDuration = vt.nextSunrise.difference(vt.currentSunrise);
    final totalGhatis = _convGhati + (_convVighati / 60.0) + (_convLipta / 3600.0);
    final elapsedMs = (totalGhatis / 60.0) * totalDuration.inMilliseconds;
    final converted = vt.currentSunrise.add(Duration(milliseconds: elapsedMs.round()));
    setState(() => _convertedGregorian = converted);
  }

  Future<void> _convertGregorianToVedic(DateTime time) async {
    try {
      final vt = await VedicTime.calculate(
        time: time,
        location: _location,
        getSunriseSunset: EphemerisManager.jyotish.getSunriseSunset,
      );
      if (mounted) {
        setState(() => _convertedVedic = vt);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F0B1E),
            Color(0xFF16102B),
            Color(0xFF1F1238),
            Color(0xFF0B0818),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppStyles.primaryColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppStyles.primaryColor.withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Background cosmic ambient glow
            Positioned(
              top: -60,
              right: -60,
              child: IgnorePointer(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppStyles.primaryColor.withValues(alpha: 0.22),
                        const Color(0xFF7B2CBF).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00B4D8).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content Body
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildModernHeader(context),
                _buildModernTabBar(context),
                const SizedBox(height: 8),
                if (_selectedTab == 0) _buildChronometerTab(context),
                if (_selectedTab == 1) _buildConverterTab(context),
                if (_selectedTab == 2) _buildReferenceGuideTab(context),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    final vt = _currentVedicTime;
    final prahar = vt != null ? PraharInfo.fromGhatis(vt.totalGhatis) : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo Icon with animated aura
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppStyles.primaryColor.withValues(alpha: 0.45 * _pulseAnimation.value),
                      const Color(0xFF7B2CBF).withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppStyles.primaryColor.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.primaryColor.withValues(alpha: 0.3 * _pulseAnimation.value),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  FluentIcons.sunny,
                  color: AppStyles.primaryColor,
                  size: 22,
                ),
              );
            },
          ),
          const SizedBox(width: 14),

          // Title & Sanskrit designation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'VEDIC MOMENT',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppStyles.primaryColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Text(
                        'काल-चक्र',
                        style: TextStyle(
                          color: AppStyles.primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  prahar != null
                      ? '${prahar.sanskrit} (${prahar.name.split('(')[0].trim()})'
                      : 'Live Vedic Chronometer',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Live Pulse Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00F5D4).withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00F5D4).withValues(alpha: 0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00F5D4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00F5D4).withValues(alpha: _pulseAnimation.value),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 7),
                const Text(
                  'SYNCED',
                  style: TextStyle(
                    color: Color(0xFF00F5D4),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            _modernTabItem(0, 'Live Chronometer', FluentIcons.clock),
            _modernTabItem(1, 'Time Converter', FluentIcons.sync_occurence),
            _modernTabItem(2, 'Vedic Units Guide', FluentIcons.education),
          ],
        ),
      ),
    );
  }

  Widget _modernTabItem(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppStyles.primaryColor.withValues(alpha: 0.35),
                      const Color(0xFF7B2CBF).withValues(alpha: 0.35),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: AppStyles.primaryColor.withValues(alpha: 0.8),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? AppStyles.primaryColor : Colors.white54,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChronometerTab(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProgressRing(),
              SizedBox(height: 14),
              Text(
                'Calculating exact solar sunrise & Ghatis...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    final vt = _currentVedicTime;
    if (vt == null) {
      return const Center(child: Text('Vedic time calculation unavailable'));
    }

    final prahar = PraharInfo.fromGhatis(vt.totalGhatis);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Upper Visualizer: Modern 60-Ghati Dial + Cyber Readout
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 500;
              if (isNarrow) {
                return Column(
                  children: [
                    _buildModernDial(vt, 170),
                    const SizedBox(height: 16),
                    _buildDigitalPillHero(vt),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildModernDial(vt, 160),
                  const SizedBox(width: 20),
                  Expanded(child: _buildDigitalPillHero(vt)),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          // Day / Night Progress Bar (Ahoratra 60-Ghati Spectrum)
          _buildDayProgressSpectrum(vt, prahar),

          const SizedBox(height: 16),

          // Astrological Horizon Context Tiles (Sunrise, Zenith, Sunset, Next Sunrise)
          _buildAstronomicalHorizonBar(vt),
        ],
      ),
    );
  }

  Widget _buildModernDial(VedicTime vt, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [
            Color(0xFF1E1438),
            Color(0xFF120B24),
            Color(0xFF0A0614),
          ],
        ),
        border: Border.all(
          color: AppStyles.primaryColor.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppStyles.primaryColor.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _CyberVedicDialPainter(
          time: vt,
          primaryColor: AppStyles.primaryColor,
          accentColor: const Color(0xFF00F5D4),
          secColor: const Color(0xFFFF007F),
        ),
      ),
    );
  }

  Widget _buildDigitalPillHero(VedicTime vt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3 Large Glass Glowing Display Tiles (Ghati : Vighati : Lipta)
        Row(
          children: [
            Expanded(
              child: _buildTimeUnitCard(
                value: vt.ghati.toString().padLeft(2, '0'),
                unit: 'GHATI (घटी)',
                color: AppStyles.primaryColor,
                progress: vt.ghati / 60.0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimeUnitCard(
                value: vt.vighati.toString().padLeft(2, '0'),
                unit: 'VIGHATI (विघटी)',
                color: const Color(0xFF00F5D4),
                progress: vt.vighati / 60.0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimeUnitCard(
                value: vt.lipta.toString().padLeft(2, '0'),
                unit: 'LIPTA (लिप्ता)',
                color: const Color(0xFFFF70A6),
                progress: vt.lipta / 60.0,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Live Local Gregorian Sync Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(FluentIcons.clock, size: 14, color: Colors.white70),
                  const SizedBox(width: 8),
                  Text(
                    'Gregorian Clock: ${_fmtTime(_currentTime)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Prana: ${vt.prana}/6',
                  style: const TextStyle(
                    color: AppStyles.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeUnitCard({
    required String value,
    required String unit,
    required Color color,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.14),
            Colors.black.withValues(alpha: 0.35),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            unit,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: color.withValues(alpha: 0.7),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ProgressBar(
            value: (progress * 100).clamp(0.0, 100.0),
          ),
        ],
      ),
    );
  }

  Widget _buildDayProgressSpectrum(VedicTime vt, PraharInfo prahar) {
    final ghatiProgress = (vt.totalGhatis / 60.0).clamp(0.0, 1.0);
    final isDaytime = vt.totalGhatis < 30.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isDaytime ? FluentIcons.sunny : FluentIcons.clear_night,
                    size: 14,
                    color: isDaytime ? const Color(0xFFFFB703) : const Color(0xFF90E0EF),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AHORATRA CYCLE (60 GHATIS)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              Text(
                '${vt.totalGhatis.toStringAsFixed(2)} / 60.00 Ghatis (${(ghatiProgress * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(
                  color: AppStyles.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Multi-gradient Day (0-30) / Night (30-60) timeline bar
          Stack(
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFB703), // Sunrise
                      Color(0xFFFB8500), // Midday
                      Color(0xFFFF006E), // Sunset
                      Color(0xFF8338EC), // Night
                      Color(0xFF3A0CA3), // Midnight
                      Color(0xFF4CC9F0), // Pre-dawn
                    ],
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ghatiProgress,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Prahar breakdown tag
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppStyles.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'Active: ${prahar.sanskrit} (${prahar.name})',
                  style: const TextStyle(
                    color: AppStyles.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Energy: ${prahar.energy}',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAstronomicalHorizonBar(VedicTime vt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _horizonItem(
            'TODAY SUNRISE',
            _fmtTime(vt.currentSunrise),
            FluentIcons.sunny,
            const Color(0xFFFFB703),
          ),
          _divider(),
          _horizonItem(
            'SOLAR NOON (ZENITH)',
            _fmtTime(vt.currentSunrise.add(const Duration(hours: 6))),
            FluentIcons.sun_add,
            const Color(0xFFFF70A6),
          ),
          _divider(),
          _horizonItem(
            'NEXT SUNRISE',
            _fmtTime(vt.nextSunrise),
            FluentIcons.circle_half_full,
            const Color(0xFF00F5D4),
          ),
        ],
      ),
    );
  }

  Widget _horizonItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConverterTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vedic to Gregorian Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppStyles.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        FluentIcons.calculator_delta,
                        size: 14,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Convert Vedic Time ➔ Gregorian Clock',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Steppers
                Row(
                  children: [
                    _modernNumberStepper('GHATI (0-59)', _convGhati, 0, 59, (v) {
                      setState(() => _convGhati = v);
                      _convertVedicToGregorian();
                    }),
                    const SizedBox(width: 8),
                    _modernNumberStepper('VIGHATI (0-59)', _convVighati, 0, 59, (v) {
                      setState(() => _convVighati = v);
                      _convertVedicToGregorian();
                    }),
                    const SizedBox(width: 8),
                    _modernNumberStepper('LIPTA (0-59)', _convLipta, 0, 59, (v) {
                      setState(() => _convLipta = v);
                      _convertVedicToGregorian();
                    }),
                  ],
                ),

                const SizedBox(height: 12),

                // Quick presets
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _quickPreset('Sunrise (0 G)', 0, 0),
                    _quickPreset('Midday (15 G)', 15, 0),
                    _quickPreset('Sunset (30 G)', 30, 0),
                    _quickPreset('Midnight (45 G)', 45, 0),
                    _quickPreset('Brahma (54 G)', 54, 0),
                  ],
                ),

                if (_convertedGregorian != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppStyles.primaryColor.withValues(alpha: 0.25),
                          const Color(0xFF7B2CBF).withValues(alpha: 0.25),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppStyles.primaryColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(FluentIcons.event, color: AppStyles.primaryColor, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GREGORIAN RESULT:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                '${_formatDate(_convertedGregorian!)} at ${_fmtTime(_convertedGregorian!)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Gregorian to Vedic Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF00F5D4).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00F5D4).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        FluentIcons.clock,
                        size: 14,
                        color: Color(0xFF00F5D4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Convert Gregorian Clock ➔ Vedic Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TimePicker(
                        selected: _selectedGregTime,
                        onChanged: (time) {
                          setState(() => _selectedGregTime = time);
                          _convertGregorianToVedic(time);
                        },
                      ),
                    ),
                  ],
                ),

                if (_convertedVedic != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00F5D4).withValues(alpha: 0.2),
                          const Color(0xFF3A0CA3).withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF00F5D4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(FluentIcons.timer, color: Color(0xFF00F5D4), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'VEDIC RESULT:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                '${_convertedVedic!.ghati} Ghatis, ${_convertedVedic!.vighati} Vighatis, ${_convertedVedic!.lipta} Liptas (${PraharInfo.fromGhatis(_convertedVedic!.totalGhatis).sanskrit})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

  Widget _quickPreset(String label, int ghati, int vighati) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _convGhati = ghati;
          _convVighati = vighati;
          _convLipta = 0;
        });
        _convertVedicToGregorian();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _modernNumberStepper(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: value > min ? () => onChanged(value - 1) : null,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: value > min ? 0.12 : 0.03),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      FluentIcons.chevron_left,
                      size: 11,
                      color: value > min ? Colors.white : Colors.white24,
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: value < max ? () => onChanged(value + 1) : null,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: value < max ? 0.12 : 0.03),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      FluentIcons.chevron_right,
                      size: 11,
                      color: value < max ? Colors.white : Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceGuideTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(FluentIcons.education, color: AppStyles.primaryColor, size: 16),
                SizedBox(width: 8),
                Text(
                  'Vedic Time Measurement Hierarchy (काल-मान)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _unitRow('1 Truti (त्रुटि)', '29.62 microseconds', 'Base atomic quantum of time'),
            _unitRow('1 Tatpara (तत्पर)', '100 Trutis (~2.96 ms)', 'Solar ray vibration'),
            _unitRow('1 Nimesha (निमेष)', '30 Tatparas (~0.213 s)', 'Blink of an eye'),
            _unitRow('1 Kashta (काष्ठा)', '15 Nimeshas (~3.2 s)', 'Breath cadence'),
            _unitRow('1 Kala (कला)', '30 Kashtas (~1.6 minutes)', 'Micro-cycle'),
            _unitRow('1 Ghatika / Ghati (घटी)', '60 Vighatis = 24 minutes', '1/60th of a full solar day'),
            _unitRow('1 Muhurta (मुहूर्त)', '2 Ghatis = 48 minutes', 'Core astrological window'),
            _unitRow('1 Prahar / Yama (प्रहर)', '7.5 Ghatis = 3 hours', '1/8th quadrant of Ahoratra'),
            _unitRow('1 Ahoratra (अहोरात्र)', '60 Ghatis = 24 hours', 'Full day (Sunrise to Sunrise)'),
          ],
        ),
      ),
    );
  }

  Widget _unitRow(String unit, String value, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              unit,
              style: const TextStyle(
                color: AppStyles.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _fmtTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m:$s $period';
  }
}

/// Custom Cyber-Vedic 60-Ghati Dial Painter
class _CyberVedicDialPainter extends CustomPainter {
  _CyberVedicDialPainter({
    required this.time,
    required this.primaryColor,
    required this.accentColor,
    required this.secColor,
  });

  final VedicTime time;
  final Color primaryColor;
  final Color accentColor;
  final Color secColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw 8 Prahar Quadrant segments on outer rim
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const sweepAngle = (2 * math.pi / 8) - 0.05;
    for (var i = 0; i < 8; i++) {
      final startAngle = -math.pi / 2 + (i * 2 * math.pi / 8);
      final isDay = i < 4;
      arcPaint.color = isDay
          ? const Color(0xFFFFB703).withValues(alpha: 0.4)
          : const Color(0xFF7B2CBF).withValues(alpha: 0.4);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 6),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }

    // 2. Draw 60 Ghati Tick marks
    final tickPaint = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final angle = -math.pi / 2 + (i * 2 * math.pi / 60);
      final isMajor = i % 5 == 0;
      final isQuadrant = i % 15 == 0;

      final tickLength = isQuadrant ? 10.0 : (isMajor ? 6.0 : 3.0);
      tickPaint.color = isQuadrant
          ? primaryColor
          : (isMajor ? Colors.white.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.2));
      tickPaint.strokeWidth = isQuadrant ? 2.0 : (isMajor ? 1.5 : 0.8);

      final outer = Offset(
        center.dx + (radius - 12) * math.cos(angle),
        center.dy + (radius - 12) * math.sin(angle),
      );
      final inner = Offset(
        center.dx + (radius - 12 - tickLength) * math.cos(angle),
        center.dy + (radius - 12 - tickLength) * math.sin(angle),
      );
      canvas.drawLine(outer, inner, tickPaint);
    }

    // 3. Draw Cardinal Ghati Numerals (0, 15, 30, 45)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const cardinals = {
      0: '0 G (Sunrise)',
      15: '15 G (Noon)',
      30: '30 G (Sunset)',
      45: '45 G (Midnt)',
    };

    cardinals.forEach((ghati, label) {
      final angle = -math.pi / 2 + (ghati * 2 * math.pi / 60);
      final textOffset = Offset(
        center.dx + (radius - 28) * math.cos(angle),
        center.dy + (radius - 28) * math.sin(angle),
      );

      textPainter.text = TextSpan(
        text: ghati.toString(),
        style: TextStyle(
          color: primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(textOffset.dx - textPainter.width / 2, textOffset.dy - textPainter.height / 2),
      );
    });

    // 4. Draw Ghati Hand (Hour equivalent - 60 Ghatis per revolution)
    final ghatiAngle = -math.pi / 2 + (time.totalGhatis * 2 * math.pi / 60);
    final ghatiHandLength = radius * 0.52;
    final ghatiHandPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final ghatiHandEnd = Offset(
      center.dx + ghatiHandLength * math.cos(ghatiAngle),
      center.dy + ghatiHandLength * math.sin(ghatiAngle),
    );
    canvas.drawLine(center, ghatiHandEnd, ghatiHandPaint);

    // 5. Draw Vighati Hand (Minute equivalent - 60 Vighatis per Ghati)
    final vighatiAngle = -math.pi / 2 + ((time.vighati + time.lipta / 60.0) * 2 * math.pi / 60);
    final vighatiHandLength = radius * 0.70;
    final vighatiHandPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final vighatiHandEnd = Offset(
      center.dx + vighatiHandLength * math.cos(vighatiAngle),
      center.dy + vighatiHandLength * math.sin(vighatiAngle),
    );
    canvas.drawLine(center, vighatiHandEnd, vighatiHandPaint);

    // 6. Draw Lipta Hand (Second equivalent - 60 Liptas per Vighati)
    final liptaAngle = -math.pi / 2 + (time.lipta * 2 * math.pi / 60);
    final liptaHandLength = radius * 0.82;
    final liptaHandPaint = Paint()
      ..color = secColor
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final liptaHandEnd = Offset(
      center.dx + liptaHandLength * math.cos(liptaAngle),
      center.dy + liptaHandLength * math.sin(liptaAngle),
    );
    canvas.drawLine(center, liptaHandEnd, liptaHandPaint);

    // 7. Center Jeweled Pivot
    final centerGlow = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7, centerGlow);

    final centerDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, centerDot);
  }

  @override
  bool shouldRepaint(covariant _CyberVedicDialPainter oldDelegate) {
    return oldDelegate.time.totalGhatis != time.totalGhatis ||
        oldDelegate.time.lipta != time.lipta;
  }
}
