import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';
import '../logic/panchang_service.dart';
import '../data/models.dart';
import '../data/city_database.dart';
import 'package:intl/intl.dart';

class PanchangScreen extends StatefulWidget {
  const PanchangScreen({super.key});

  @override
  State<PanchangScreen> createState() => _PanchangScreenState();
}

class _PanchangScreenState extends State<PanchangScreen> {
  DateTime _selectedDate = DateTime.now();
  final PanchangService _panchangService = PanchangService();
  PanchangResult? _result;
  List<PanchangInauspicious> _inauspicious = [];
  List<PanchangHora> _horas = [];
  List<PanchangChoghadiya> _choghadiya = [];
  AbhijitMuhurta? _abhijit;
  BrahmaMuhurta? _brahma;
  bool _isLoading = false;

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
    _selectedCity = City(
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

      setState(() {
        _result = result;
        _inauspicious = inauspicious;
        _horas = horas;
        _choghadiya = choghadiya;
        _abhijit = abhijit;
        _brahma = brahma;
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
    _calculatePanchang();
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
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Daily Panchang'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        commandBar: CommandBar(
          primaryItems: [
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
          ? const Center(child: Text("No Data"))
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
                                    DateFormat('EEEE').format(_selectedDate),
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
                                        ?.copyWith(fontWeight: FontWeight.bold),
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
                            Icon(
                              FluentIcons.location,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCity?.displayName ??
                                  'New Delhi, Delhi, India',
                              style: FluentTheme.of(context).typography.caption
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
                            style: FluentTheme.of(
                              context,
                            ).typography.caption?.copyWith(color: Colors.grey),
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
                        Row(
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
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Tab Content
                if (_selectedTabIndex == 0)
                  _buildPanchangElementsTab()
                else if (_selectedTabIndex == 1)
                  _buildSunMoonTimesTab()
                else if (_selectedTabIndex == 2)
                  _buildInauspiciousTab()
                else if (_selectedTabIndex == 3)
                  _buildMuhurtaTab()
                else if (_selectedTabIndex == 4)
                  _buildHoraTab()
                else if (_selectedTabIndex == 5)
                  _buildChoghadiyaTab(),

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
    );
  }

  Widget _buildInauspiciousTab() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSectionHeading('Inauspicious Periods'),
          const SizedBox(height: 16),
          ..._inauspicious.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Expander(
                header: Row(
                  children: [
                    Icon(FluentIcons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 12),
                    Text(p.name, style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(
                      '${p.startTime} - ${p.endTime}',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                content: Text(
                  'During ${p.name}, it is generally advised to avoid starting new ventures or important activities.',
                ),
              ),
            ),
          ),
          if (_inauspicious.isEmpty)
            const Center(
              child: Text('No inauspicious periods calculated for today.'),
            ),
        ]),
      ),
    );
  }

  Widget _buildMuhurtaTab() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSectionHeading('Auspicious Muhurtas'),
          const SizedBox(height: 16),
          if (_abhijit != null)
            _buildMuhurtaCard(
              'Abhijit Muhurta',
              (_abhijit as dynamic).start,
              (_abhijit as dynamic).end,
              FluentIcons.sunny,
              Colors.orange,
              'Abhijit Muhurta is the most auspicious time of the day to start any work.',
            ),
          if (_brahma != null) ...[
            const SizedBox(height: 12),
            _buildMuhurtaCard(
              'Brahma Muhurta',
              (_brahma as dynamic).start,
              (_brahma as dynamic).end,
              FluentIcons.diamond,
              Colors.blue,
              'Brahma Muhurta is ideal for meditation, spiritual practices, and study.',
            ),
          ],
          const SizedBox(height: 12),
          const InfoBar(
            title: Text('More Muhurtas'),
            content: Text(
              'Additional muhurtas like Amrit Kaalam are coming soon. Brahma Muhurta values vary based on local sunrise.',
            ),
            severity: InfoBarSeverity.info,
          ),
        ]),
      ),
    );
  }

  Widget _buildHoraTab() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSectionHeading('Hora (Planetary Hours)'),
          const SizedBox(height: 16),
          ..._horas.map(
            (h) => ListTile(
              leading: Icon(
                h.isDay ? FluentIcons.sunny : FluentIcons.clear_night,
                color: h.isDay ? Colors.orange : Colors.purple,
              ),
              title: Text('${h.planet} Hora'),
              subtitle: Text('${h.startTime} - ${h.endTime}'),
              trailing: h.isDay ? Text('Day') : Text('Night'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildChoghadiyaTab() {
    final dayChoghadiya = _choghadiya.where((c) => c.isDay).toList();
    final nightChoghadiya = _choghadiya.where((c) => !c.isDay).toList();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildSectionHeading('Day Choghadiya'),
          const SizedBox(height: 8),
          _buildChoghadiyaList(dayChoghadiya),
          const SizedBox(height: 24),
          _buildSectionHeading('Night Choghadiya'),
          const SizedBox(height: 8),
          _buildChoghadiyaList(nightChoghadiya),
        ]),
      ),
    );
  }

  Widget _buildSectionHeading(String title) {
    return Text(
      title,
      style: FluentTheme.of(
        context,
      ).typography.subtitle?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildChoghadiyaList(List<PanchangChoghadiya> list) {
    return Column(
      children: list.map((c) {
        Color color;
        IconData icon;
        switch (c.type.toLowerCase()) {
          case 'good':
          case 'shubh':
          case 'amrit':
          case 'labh':
            color = Colors.green;
            icon = FluentIcons.completed;
            break;
          case 'bad':
          case 'rog':
          case 'kaal':
          case 'udveg':
            color = Colors.red;
            icon = FluentIcons.error;
            break;
          default:
            color = Colors.orange;
            icon = FluentIcons.info;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Card(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        c.type,
                        style: TextStyle(color: color, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${c.startTime} - ${c.endTime}',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMuhurtaCard(
    String title,
    DateTime start,
    DateTime end,
    IconData icon,
    Color color,
    String desc,
  ) {
    final format = DateFormat('HH:mm');
    return Expander(
      header: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            '${format.format(start.toLocal())} - ${format.format(end.toLocal())}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(desc),
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

  Widget _buildPanchangElementsTab() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverGrid.count(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
        children: [
          _buildPanchangCard(
            title: 'Tithi',
            value: _result!.tithi,
            subtitle: 'Lunar Day',
            icon: FluentIcons.calendar_day,
            color: Colors.orange,
            description: 'The lunar day based on moon phases',
          ),
          _buildPanchangCard(
            title: 'Nakshatra',
            value: _result!.nakshatra,
            subtitle: 'Lunar Mansion',
            icon: FluentIcons.favorite_star,
            color: Colors.purple,
            description: 'The constellation moon is transiting',
          ),
          _buildPanchangCard(
            title: 'Yoga',
            value: _result!.yoga,
            subtitle: 'Sun-Moon Angle',
            icon: FluentIcons.flow,
            color: Colors.blue,
            description: 'Angular relationship between Sun and Moon',
          ),
          _buildPanchangCard(
            title: 'Karana',
            value: _result!.karana,
            subtitle: 'Half Tithi',
            icon: FluentIcons.stopwatch,
            color: Colors.teal,
            description: 'Half of a lunar day',
          ),
          _buildPanchangCard(
            title: 'Vara',
            value: _result!.vara,
            subtitle: 'Weekday',
            icon: FluentIcons.calendar,
            color: Colors.green,
            description: 'Day of the week ruled by a planet',
          ),
        ],
      ),
    );
  }

  Widget _buildSunMoonTimesTab() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Sun & Moon Rise/Set Times',
            style: FluentTheme.of(
              context,
            ).typography.subtitle?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeCard(
                  title: 'Sunrise',
                  time: _result!.sunrise ?? '--:--',
                  icon: FluentIcons.sunny,
                  color: Colors.orange,
                  description:
                      'The moment when the upper limb of the sun appears above the horizon',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeCard(
                  title: 'Sunset',
                  time: _result!.sunset ?? '--:--',
                  icon: FluentIcons.clear_night,
                  color: Colors.orange,
                  description:
                      'The moment when the upper limb of the sun disappears below the horizon',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeCard(
                  title: 'Moonrise',
                  time: _result!.moonrise ?? '--:--',
                  icon: FluentIcons.up,
                  color: Colors.purple,
                  description:
                      'The moment when the upper limb of the moon appears above the horizon',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeCard(
                  title: 'Moonset',
                  time: _result!.moonset ?? '--:--',
                  icon: FluentIcons.down,
                  color: Colors.purple,
                  description:
                      'The moment when the upper limb of the moon disappears below the horizon',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(FluentIcons.info, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Times are calculated for ${_selectedCity?.displayName ?? 'the selected location'} and shown in local time.',
                    style: FluentTheme.of(
                      context,
                    ).typography.caption?.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTimeCard({
    required String title,
    required String time,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return HoverButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => ContentDialog(
            title: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(title),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: FluentTheme.of(
                    context,
                  ).typography.title?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(description),
              ],
            ),
            actions: [
              Button(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      builder: (context, states) {
        return Card(
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.all(16.0),
          backgroundColor: states.isHovered ? color.withAlpha(15) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPanchangCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    return HoverButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => ContentDialog(
            title: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Text(title),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: FluentTheme.of(
                    context,
                  ).typography.title?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Text(description),
              ],
            ),
            actions: [
              Button(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      builder: (context, states) {
        return Card(
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.all(8.0),
          backgroundColor: states.isHovered ? color.withAlpha(15) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 8,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
