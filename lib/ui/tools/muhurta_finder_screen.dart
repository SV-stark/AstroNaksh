import 'dart:async';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show showDatePicker;
import 'package:jyotish/core.dart';
import 'package:jyotish/muhurta.dart';

import '../../core/ephemeris_manager.dart';
import '../../core/utils/formatters.dart';
import '../../data/city_database.dart';
import '../../ui/utils/responsive_helper.dart';

class MuhurtaFinderScreen extends StatefulWidget {
  const MuhurtaFinderScreen({super.key});

  @override
  State<MuhurtaFinderScreen> createState() => _MuhurtaFinderScreenState();
}

class _MuhurtaFinderScreenState extends State<MuhurtaFinderScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedActivity = 'all';

  Muhurta? _muhurta;
  List<MuhurtaPeriod> _bestPeriods = [];
  List<MuhurtaScoreResult> _suitabilityTimeline = [];
  bool _isLoading = false;

  // Location state
  City? _selectedCity;
  final TextEditingController _citySearchController = TextEditingController();
  List<AutoSuggestBoxItem<City>> _cityItems = [];
  bool _isLoadingLocation = false;
  bool _showLocationEditor = false;

  final Map<String, String> _activities = {
    'all': 'General Auspiciousness',
    'marriage': 'Marriage & Relationships',
    'travel': 'Travel & Journeys',
    'business': 'Business & Commerce',
    'health': 'Health & Surgery',
    'education': 'Education & Learning',
    'routine work': 'Routine Work',
  };

  @override
  void initState() {
    super.initState();
    _selectedCity = const City(
      name: 'New Delhi',
      state: 'Delhi',
      country: 'India',
      latitude: 28.6139,
      longitude: 77.2090,
      timezone: 'Asia/Kolkata',
    );
    _calculateMuhurta();
  }

  @override
  void dispose() {
    _citySearchController.dispose();
    super.dispose();
  }

  Future<void> _calculateMuhurta() async {
    if (_selectedCity == null) return;

    setState(() => _isLoading = true);
    try {
      final ephemerisService = EphemerisManager.service;
      final location = GeographicLocation(
        latitude: _selectedCity!.latitude,
        longitude: _selectedCity!.longitude,
        altitude: 0,
      );

      final sunriseSunset = await ephemerisService.getSunriseSunset(
        date: _selectedDate,
        location: location,
      );

      if (sunriseSunset.$1 == null || sunriseSunset.$2 == null) {
        throw Exception(
          'Could not determine sunrise/sunset for this location and date.',
        );
      }

      final muhurtaService = MuhurtaService();
      final muhurta = muhurtaService.calculateMuhurta(
        date: _selectedDate,
        sunrise: sunriseSunset.$1!,
        sunset: sunriseSunset.$2!,
        location: location,
      );

      final start = sunriseSunset.$1!;
      final end = start.add(const Duration(hours: 24));

      final suitabilityTimeline = await EphemerisManager.jyotish
          .scanMuhurtaSuitability(
            startDateTime: start,
            endDateTime: end,
            location: location,
            step: const Duration(minutes: 30),
          );

      final suitabilityTimelineSorted = List<MuhurtaScoreResult>.from(
        suitabilityTimeline,
      )..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      setState(() {
        _muhurta = muhurta;
        _bestPeriods = muhurta.getFavorablePeriods(_selectedActivity);
        _suitabilityTimeline = suitabilityTimelineSorted;
        _isLoading = false;
      });
    } on PolarRegionException catch (e) {
      setState(() => _isLoading = false);
      if (mounted && !Platform.environment.containsKey('FLUTTER_TEST')) {
        unawaited(
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Polar Region Notice'),
              content: Text(
                'Sunrise/sunset cannot be determined in polar regions during perpetual day/night: ${e.message}',
              ),
              severity: InfoBarSeverity.warning,
              onClose: close,
            ),
          ),
        );
      }
    } on CalculationException catch (e) {
      setState(() => _isLoading = false);
      if (mounted && !Platform.environment.containsKey('FLUTTER_TEST')) {
        unawaited(
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Calculation Error'),
              content: Text(e.message),
              severity: InfoBarSeverity.error,
              onClose: close,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted && !Platform.environment.containsKey('FLUTTER_TEST')) {
        unawaited(
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Error'),
              content: Text(e.toString()),
              severity: InfoBarSeverity.error,
              onClose: close,
            ),
          ),
        );
      }
    }
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _calculateMuhurta();
  }

  Future<void> _onCitySearch(String text) async {
    if (text.length < 2) {
      if (_cityItems.isNotEmpty) setState(() => _cityItems = []);
      return;
    }

    final results = await CityDatabase.searchCities(text);
    final limited = results.take(10);
    setState(() {
      _cityItems = limited.map((city) {
        return AutoSuggestBoxItem<City>(
          value: city,
          label: '${city.name}, ${city.country}',
          onSelected: () {
            setState(() {
              _selectedCity = city;
              _showLocationEditor = false;
            });
            _calculateMuhurta();
          },
        );
      }).toList();
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final city = await CityDatabase.getCurrentLocation();
      if (city != null && mounted) {
        setState(() {
          _selectedCity = city;
          _showLocationEditor = false;
          _isLoadingLocation = false;
        });
        unawaited(_calculateMuhurta());
      } else {
        setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Muhurta Finder'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        commandBar: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_selectedCity != null)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Text(
                  _selectedCity!.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            IconButton(
              icon: const Icon(FluentIcons.poi),
              onPressed: () {
                setState(() => _showLocationEditor = !_showLocationEditor);
              },
            ),
          ],
        ),
      ),
      content: Column(
        children: [
          // Location Editor
          if (_showLocationEditor)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Row(
                  children: [
                    Expanded(
                      child: AutoSuggestBox<City>(
                        controller: _citySearchController,
                        items: _cityItems,
                        placeholder: 'Search for a city...',
                        onChanged: (text, reason) {
                          if (reason == TextChangedReason.userInput) {
                            _onCitySearch(text);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Use Current Location',
                      child: IconButton(
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: ProgressRing(strokeWidth: 2),
                              )
                            : const Icon(FluentIcons.map_pin),
                        onPressed: _isLoadingLocation
                            ? null
                            : _useCurrentLocation,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Date & Activity Selector
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Card(
              child: Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(FluentIcons.chevron_left),
                        onPressed: () => _changeDate(-1),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                            unawaited(_calculateMuhurta());
                          }
                        },
                        child: Text(
                          AppFormatters.formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(FluentIcons.chevron_right),
                        onPressed: () => _changeDate(1),
                      ),
                    ],
                  ),
                  if (isMobile) const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Activity: '),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: isMobile ? 180 : 250,
                        child: ComboBox<String>(
                          isExpanded: true,
                          value: _selectedActivity,
                          items: _activities.entries.map((e) {
                            return ComboBoxItem<String>(
                              value: e.key,
                              child: Text(e.value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedActivity = value);
                              _calculateMuhurta();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: ProgressRing())
                : _muhurta == null
                ? const Center(child: Text('No Muhurta Data'))
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Suitability Chart Section
                      _buildSuitabilityChart(),
                      // Best Periods Section
                      if (_bestPeriods.isNotEmpty) _buildBestMuhurtasCard(),
                      if (_bestPeriods.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: InfoBar(
                            title: Text('No Favorable Periods'),
                            content: Text(
                              'There are no highly favorable periods for this activity today. Consider selecting a different date.',
                            ),
                            severity: InfoBarSeverity.warning,
                            isLong: true,
                          ),
                        ),

                      // Inauspicious Warnings
                      if (_muhurta!.inauspiciousPeriods.warnings.isNotEmpty)
                        _buildInauspiciousCard(),

                      // Timeline of All Periods
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Daily Timeline',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildTimeline(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestMuhurtasCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        borderColor: Colors.green.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.favorite_star, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Best Times for Activity',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._bestPeriods.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${AppFormatters.formatTime(p.startTime)} - ${AppFormatters.formatTime(p.endTime)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${p.name} (${p.nature})')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInauspiciousCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        backgroundColor: Colors.red.withValues(alpha: 0.05),
        borderColor: Colors.red.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(FluentIcons.warning, color: Colors.red),
                const SizedBox(width: 8),
                const Text(
                  'Inauspicious Periods to Avoid',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._muhurta!.inauspiciousPeriods.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0, right: 8.0),
                    ),
                    Icon(
                      FluentIcons.status_circle_error_x,
                      size: 12,
                      color: Colors.red,
                    ),
                    Expanded(
                      child: Text(w, style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    // Combine Horas and Choghadiya into a timeline
    final allPeriods = <MuhurtaPeriod>[
      ..._muhurta!.horaPeriods,
      ..._muhurta!.choghadiya.allPeriods,
    ];

    // Sort by start time
    allPeriods.sort((a, b) => a.startTime.compareTo(b.startTime));

    return Column(
      children: allPeriods.map((period) {
        final isInauspicious = _muhurta!.inauspiciousPeriods.isInauspicious(
          period.startTime.add(const Duration(minutes: 5)),
        );

        Color indicatorColor = Colors.grey;
        if (isInauspicious) {
          indicatorColor = Colors.red;
        } else if (period.isFavorableFor(_selectedActivity)) {
          indicatorColor = Colors.green;
        } else if (period.isAuspicious) {
          indicatorColor = Colors.blue;
        }

        return Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: indicatorColor, width: 4),
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  '${AppFormatters.formatTime(period.startTime)} - ${AppFormatters.formatTime(period.endTime)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      period is HoraPeriod ? 'Hora' : 'Choghadiya',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: indicatorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isInauspicious ? 'Inauspicious' : period.nature,
                  style: TextStyle(color: indicatorColor, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuitabilityChart() {
    if (_suitabilityTimeline.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    final start = _suitabilityTimeline.first.dateTime;

    for (var i = 0; i < _suitabilityTimeline.length; i++) {
      final res = _suitabilityTimeline[i];
      final hoursOffset = res.dateTime.difference(start).inMinutes / 60.0;
      spots.add(FlSpot(hoursOffset, res.finalScore));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auspicious Suitability Score (24-Hour Scan)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'A higher percentage represents better planetary alignment for activities. Tap/hover on the graph for details.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          FluentTheme.of(context).scaffoldBackgroundColor,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final res = _suitabilityTimeline[spot.spotIndex];
                          final formattedTime = AppFormatters.formatTime(
                            res.dateTime,
                          );
                          return LineTooltipItem(
                            '$formattedTime\nScore: ${res.finalScore.toStringAsFixed(0)}%\n'
                            'Tithi: ${res.tithiScore.toStringAsFixed(0)}\n'
                            'Vara: ${res.varaScore.toStringAsFixed(0)}\n'
                            'Nak: ${res.nakshatraScore.toStringAsFixed(0)}\n'
                            'Yoga: ${res.yogaScore.toStringAsFixed(0)}\n'
                            'Karana: ${res.karanaScore.toStringAsFixed(0)}',
                            TextStyle(
                              color: FluentTheme.of(
                                context,
                              ).typography.body?.color,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (val, meta) {
                          final dt = start.add(
                            Duration(minutes: (val * 60).toInt()),
                          );
                          final hourStr = dt.hour.toString().padLeft(2, '0');
                          final minStr = dt.minute.toString().padLeft(2, '0');
                          if (val % 4 == 0) {
                            return Text(
                              '$hourStr:$minStr',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: FluentTheme.of(context).accentColor,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: FluentTheme.of(
                          context,
                        ).accentColor.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
