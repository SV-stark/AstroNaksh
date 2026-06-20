// ignore_for_file: avoid_slow_async_io, unawaited_futures, deprecated_member_use, sort_constructors_first, implementation_imports
import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';

import '../core/ephemeris_manager.dart';
import '../core/utils/formatters.dart';
import '../data/city_database.dart';
import '../data/models.dart';
import '../logic/panchang_service.dart';
import '../ui/utils/responsive_helper.dart';
import 'panchang/panchang.dart';

class PanchangScreen extends StatefulWidget {
  const PanchangScreen({super.key});

  @override
  State<PanchangScreen> createState() => _PanchangScreenState();
}

class _PanchangScreenState extends State<PanchangScreen> {
  DateTime _selectedDate = DateTime.now();
  final PanchangService _panchangService = PanchangService();
  PanchangResult? _result;
  GowriPanchangamInfo? _gowri;
  List<PanchangInauspicious> _inauspicious = [];
  List<PanchangHora> _horas = [];
  List<PanchangChoghadiya> _choghadiya = [];
  AbhijitMuhurta? _abhijit;
  BrahmaMuhurta? _brahma;
  MoonPhaseDetails? _moonPhase;
  DateTime? _tithiJunction;
  EclipseData? _eclipseData;
  List<SpecialYoga> _specialYogas = [];
  bool _isLoading = false;
  PanchakStatus? _panchak;

  // Tab state
  int _selectedTabIndex = 0;

  // Location state
  City? _selectedCity;
  final TextEditingController _citySearchController = TextEditingController();
  List<AutoSuggestBoxItem<City>> _cityItems = [];
  bool _isLoadingLocation = false;
  bool _showLocationEditor = false;

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
    _calculatePanchang();
  }

  Future<void> _calculatePanchang() async {
    setState(() => _isLoading = true);
    try {
      final location = Location(
        latitude: _selectedCity!.latitude,
        longitude: _selectedCity!.longitude,
      );
      final result = await _panchangService.getPanchang(
        _selectedDate,
        location,
      );

      final inauspicious = await _panchangService.getInauspicious(
        _selectedDate,
        location,
      );

      final horas = await _panchangService.getHoras(_selectedDate, location);

      final choghadiya = await _panchangService.getChoghadiya(
        _selectedDate,
        location,
      );

      final abhijit = await _panchangService.getAbhijitMuhurta(
        _selectedDate,
        location,
      );

      final brahma = await _panchangService.getBrahmaMuhurta(
        _selectedDate,
        location,
      );

      final gowri = await EphemerisManager.jyotish.getCurrentGowriPanchangam(
        dateTime: _selectedDate,
        location: GeographicLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          altitude: 0,
        ),
      );

      final moonPhase = await _panchangService.getMoonPhaseDetails(
        _selectedDate,
        location,
      );

      final nightInauspicious = await _panchangService.getNighttimeInauspicious(
        _selectedDate,
        location,
      );

      inauspicious.add(
        PanchangInauspicious(
          name: 'Night Rahukalam',
          startTime: AppFormatters.formatTime(
            nightInauspicious.rahuKaal.start.toLocal(),
          ),
          endTime: AppFormatters.formatTime(
            nightInauspicious.rahuKaal.end.toLocal(),
          ),
        ),
      );
      inauspicious.add(
        PanchangInauspicious(
          name: 'Night Gulikalam',
          startTime: AppFormatters.formatTime(
            nightInauspicious.gulikaKaal.start.toLocal(),
          ),
          endTime: AppFormatters.formatTime(
            nightInauspicious.gulikaKaal.end.toLocal(),
          ),
        ),
      );
      inauspicious.add(
        PanchangInauspicious(
          name: 'Night Yamagandam',
          startTime: AppFormatters.formatTime(
            nightInauspicious.yamagandam.start.toLocal(),
          ),
          endTime: AppFormatters.formatTime(
            nightInauspicious.yamagandam.end.toLocal(),
          ),
        ),
      );

      final tithiEndTime = await _panchangService.getTithiEndTime(
        _selectedDate,
        location,
      );

      final eclipseData = await EphemerisManager.service.getEclipseData(
        date: _selectedDate,
        location: GeographicLocation(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );

      final specialYogas = await _panchangService.getSpecialYogas(
        _selectedDate,
        location,
      );

      setState(() {
        _result = result;
        _gowri = gowri;
        _inauspicious = inauspicious;
        _horas = horas;
        _choghadiya = choghadiya;
        _abhijit = abhijit;
        _brahma = brahma;
        _moonPhase = moonPhase;
        _tithiJunction = tithiEndTime;
        _eclipseData = eclipseData;
        _specialYogas = specialYogas;
        _isLoading = false;
      });

      // Load Panchak (only needs transit Moon, use current transit chart)
      try {
        final transitChart = await EphemerisManager.jyotish.calculateVedicChart(
          dateTime: _selectedDate,
          location: GeographicLocation(
            latitude: _selectedCity!.latitude,
            longitude: _selectedCity!.longitude,
          ),
        );
        final specialTransits = await EphemerisManager.jyotish
            .calculateSpecialTransits(
              natalChart: transitChart,
              checkDate: _selectedDate,
              location: GeographicLocation(
                latitude: _selectedCity!.latitude,
                longitude: _selectedCity!.longitude,
              ),
            );
        if (mounted) {
          setState(() {
            _panchak = specialTransits.panchak;
          });
        }
      } catch (_) {
        // Panchak load failed — not critical, UI will show a message
      }
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
    _calculatePanchang();
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
            _calculatePanchang();
          },
        );
      }).toList();
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final city = await CityDatabase.getCurrentLocation();
      if (city != null && mounted) {
        setState(() {
          _selectedCity = city;
          _showLocationEditor = false;
        });
        _calculatePanchang();

        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Location Found'),
              content: Text(city.displayName),
              severity: InfoBarSeverity.success,
              onClose: close,
            );
          },
        );
      } else if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Location Error'),
              content: const Text(
                'Could not detect location. Please search manually.',
              ),
              severity: InfoBarSeverity.warning,
              onClose: close,
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Permission Error'),
              content: const Text('Location permission denied or unavailable'),
              severity: InfoBarSeverity.error,
              onClose: close,
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) return;
      },
      child: ScaffoldPage(
        header: PageHeader(
          title: const Text('Daily Panchang'),
          leading: IconButton(
            icon: const Icon(FluentIcons.back),
            onPressed: () => Navigator.pop(context),
          ),
          commandBar: CommandBar(
            overflowBehavior: CommandBarOverflowBehavior.dynamicOverflow,
            primaryItems: [
              if (!isMobile)
                CommandBarBuilderItem(
                  builder: (context, mode, w) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: DatePicker(
                        selected: _selectedDate,
                        onChanged: (date) {
                          setState(() => _selectedDate = date);
                          _calculatePanchang();
                        },
                      ),
                    );
                  },
                  wrappedItem: CommandBarButton(
                    icon: const Icon(FluentIcons.calendar),
                    label: const Text('Date'),
                    onPressed: () {},
                  ),
                ),
              if (isMobile)
                CommandBarButton(
                  icon: const Icon(FluentIcons.calendar),
                  label: const Text('Select Date'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => ContentDialog(
                        title: const Text('Select Date'),
                        content: SizedBox(
                          height: 300,
                          child: DatePicker(
                            selected: _selectedDate,
                            onChanged: (date) {
                              setState(() => _selectedDate = date);
                              _calculatePanchang();
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                        actions: [
                          Button(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              CommandBarButton(
                icon: const Icon(FluentIcons.location),
                label: const Text('Location'),
                onPressed: () {
                  setState(() {
                    _showLocationEditor = !_showLocationEditor;
                  });
                },
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.refresh),
                label: const Text('Refresh'),
                onPressed: _calculatePanchang,
              ),
            ],
          ),
        ),
        content: _isLoading
            ? const Center(child: ProgressRing())
            : _result == null
            ? const Center(child: Text('No Data'))
            : CustomScrollView(
                slivers: [
                  // Date Navigation Header
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 20.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            FluentTheme.of(context).accentColor.withAlpha(30),
                            FluentTheme.of(context).accentColor.withAlpha(10),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: FluentTheme.of(
                            context,
                          ).accentColor.withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Date Navigation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(FluentIcons.chevron_left),
                                onPressed: () => _changeDate(-1),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      AppFormatters.formatDayName(
                                        _selectedDate,
                                      ),
                                      style: FluentTheme.of(context)
                                          .typography
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: FluentTheme.of(
                                              context,
                                            ).accentColor,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _result!.date,
                                      style: FluentTheme.of(context)
                                          .typography
                                          .title
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(FluentIcons.chevron_right),
                                onPressed: () => _changeDate(1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Location indicator with edit button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                FluentIcons.location,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedCity?.displayName ??
                                    'New Delhi, Delhi, India',
                                style: FluentTheme.of(context)
                                    .typography
                                    .caption
                                    ?.copyWith(color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  FluentIcons.edit,
                                  size: 12,
                                  color: FluentTheme.of(context).accentColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showLocationEditor = !_showLocationEditor;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Location Editor
                  if (_showLocationEditor)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: FluentTheme.of(
                              context,
                            ).accentColor.withAlpha(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FluentIcons.location,
                                  size: 16,
                                  color: FluentTheme.of(context).accentColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Change Location',
                                  style: FluentTheme.of(context).typography.body
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            AutoSuggestBox<City>(
                              controller: _citySearchController,
                              items: _cityItems,
                              onChanged: (text, reason) {
                                _onCitySearch(text);
                              },
                              placeholder: 'Search for a city...',
                              trailingIcon: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: ProgressRing(strokeWidth: 2),
                                    )
                                  : IconButton(
                                      icon: const Icon(FluentIcons.globe),
                                      onPressed: _useCurrentLocation,
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type at least 2 characters to search cities. Click the globe icon to use your current location.',
                              style: FluentTheme.of(context).typography.caption
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Tab Navigation
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    _buildTabButton(
                                      icon: FluentIcons.calendar_day,
                                      label: 'Panchang',
                                      isSelected: _selectedTabIndex == 0,
                                      onTap: () =>
                                          setState(() => _selectedTabIndex = 0),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTabButton(
                                      icon: FluentIcons.sunny,
                                      label: 'Sun & Moon',
                                      isSelected: _selectedTabIndex == 1,
                                      onTap: () =>
                                          setState(() => _selectedTabIndex = 1),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTabButton(
                                      icon: FluentIcons.warning,
                                      label: 'Inauspicious',
                                      isSelected: _selectedTabIndex == 2,
                                      onTap: () =>
                                          setState(() => _selectedTabIndex = 2),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTabButton(
                                      icon: FluentIcons.diamond,
                                      label: 'Muhurta',
                                      isSelected: _selectedTabIndex == 3,
                                      onTap: () =>
                                          setState(() => _selectedTabIndex = 3),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTabButton(
                                      icon: FluentIcons.clock,
                                      label: 'Hora',
                                      isSelected: _selectedTabIndex == 4,
                                      onTap: () =>
                                          setState(() => _selectedTabIndex = 4),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTabButton(
                                      icon: FluentIcons.grid_view_medium,
                                      label: 'Choghadiya',
                                      isSelected: _selectedTabIndex == 5,
                                      onTap: () =>
                                          setState(() => _selectedTabIndex = 5),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTabButton(
                                      icon: FluentIcons.favorite_star,
                                      label: 'Gowri',
                                      isSelected: _selectedTabIndex == 6,
                                      onTap: () =>
                                          setState(() => _selectedTabIndex = 6),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTabButton(
                                      icon: FluentIcons.sync_occurence,
                                      label: 'Transits',
                                      isSelected: _selectedTabIndex == 7,
                                      onTap: () =>
                                          setState(() => _selectedTabIndex = 7),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildTabButton(
                                      icon: FluentIcons.starburst,
                                      label: 'Special Yogas',
                                      isSelected: _selectedTabIndex == 8,
                                      onTap: () =>
                                          setState(() => _selectedTabIndex = 8),
                                    ),
                                  ],
                                ),
                              ),
                            ), // SingleChild
                          ), // Scrollbar
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Tab Content
                  if (_selectedTabIndex == 0)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: PanchangElementsTab(
                          result: _result,
                          tithiJunction: _tithiJunction,
                          isLoading: _isLoading,
                        ),
                      ),
                    )
                  else if (_selectedTabIndex == 1)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: PanchangSunMoonTab(
                          result: _result,
                          moonPhase: _moonPhase,
                          eclipseData: _eclipseData,
                        ),
                      ),
                    )
                  else if (_selectedTabIndex == 2)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: PanchangInauspiciousTab(
                          inauspicious: _inauspicious,
                        ),
                      ),
                    )
                  else if (_selectedTabIndex == 3)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: PanchangMuhurtaTab(
                          abhijit: _abhijit,
                          brahma: _brahma,
                        ),
                      ),
                    )
                  else if (_selectedTabIndex == 4)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: PanchangHoraTab(horas: _horas),
                      ),
                    )
                  else if (_selectedTabIndex == 5)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: PanchangChoghadiyaTab(choghadiya: _choghadiya),
                      ),
                    )
                  else if (_selectedTabIndex == 6)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: PanchangGowriTab(gowri: _gowri),
                      ),
                    )
                  else if (_selectedTabIndex == 7)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: PanchangTransitsTab(panchak: _panchak),
                      ),
                    )
                  else if (_selectedTabIndex == 8)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      sliver: SliverToBoxAdapter(
                        child: PanchangSpecialYogasTab(
                          specialYogas: _specialYogas,
                        ),
                      ),
                    ),

                  // Information Section
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                FluentIcons.info,
                                size: 16,
                                color: FluentTheme.of(context).accentColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'About Panchang',
                                style: FluentTheme.of(context).typography.body
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Panchang (Five Limbs) is the Hindu almanac that provides astrological information about the day. '
                            'It consists of five elements: Tithi (lunar day), Nakshatra (lunar mansion), Yoga (sun-moon angle), '
                            'Karana (half tithi), and Vara (weekday). These elements help determine auspicious times and activities for the day.',
                            style: FluentTheme.of(context).typography.caption,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return HoverButton(
      onPressed: onTap,
      builder: (context, states) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? FluentTheme.of(context).accentColor
                : Colors.grey.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
