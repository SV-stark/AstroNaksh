import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';
import 'package:intl/intl.dart';
import '../../ui/utils/responsive_helper.dart';
import '../../core/ephemeris_manager.dart';
import '../../data/city_database.dart';
import 'package:flutter/material.dart' show showDatePicker;

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
    _selectedCity = City(
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
          "Could not determine sunrise/sunset for this location and date.",
        );
      }

      final muhurtaService = MuhurtaService();
      final muhurta = muhurtaService.calculateMuhurta(
        date: _selectedDate,
        sunrise: sunriseSunset.$1!,
        sunset: sunriseSunset.$2!,
        location: location,
      );

      final bestPeriods = muhurtaService.findBestMuhurta(
        muhurta: muhurta,
        activity: _selectedActivity,
      );

      setState(() {
        _muhurta = muhurta;
        _bestPeriods = bestPeriods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Error'),
            content: Text(e.toString()),
            severity: InfoBarSeverity.error,
            onClose: close,
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

  void _onCitySearch(String text) {
    if (text.length < 2) {
      if (_cityItems.isNotEmpty) setState(() => _cityItems = []);
      return;
    }

    final results = CityDatabase.searchCities(text).take(10);
    setState(() {
      _cityItems = results.map((city) {
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
        _calculateMuhurta();
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
        commandBar: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_selectedCity != null)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Text(
                  _selectedCity!.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                            _calculateMuhurta();
                          }
                        },
                        child: Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
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
                        '${DateFormat('hh:mm a').format(p.startTime)} - ${DateFormat('hh:mm a').format(p.endTime)}',
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
          period.startTime.add(Duration(minutes: 5)),
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
                  '${DateFormat('hh:mm').format(period.startTime)} - ${DateFormat('hh:mm a').format(period.endTime)}',
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
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
}
