import 'package:fluent_ui/fluent_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/city_database.dart';
import '../../data/models.dart';
import '../../logic/rashiphal_service.dart';
import '../styles.dart';
import '../utils/responsive_helper.dart';
import '../widgets/daily_prediction_card.dart';

class RashiphalScreen extends StatefulWidget {
  const RashiphalScreen({super.key, this.initialSignIndex});

  /// Optional initial sign index (0: Aries .. 11: Pisces)
  final int? initialSignIndex;

  @override
  State<RashiphalScreen> createState() => _RashiphalScreenState();
}

class _RashiphalScreenState extends State<RashiphalScreen> {
  static const String _prefKeySignIndex = 'default_rashiphal_sign_index';
  static const String _prefKeyCityName = 'default_rashiphal_city_name';
  static const String _prefKeyLat = 'default_rashiphal_lat';
  static const String _prefKeyLng = 'default_rashiphal_lng';

  final RashiphalService _rashiphalService = RashiphalService();

  int _selectedSignIndex = 0;
  bool _isDefaultSign = false;
  City _selectedCity = const City(
    name: 'New Delhi',
    state: 'Delhi',
    country: 'India',
    latitude: 28.6139,
    longitude: 77.2090,
    timezone: 'Asia/Kolkata',
  );

  int _selectedTab = 0; // 0: Today, 1: Tomorrow, 2: 7-Day Weekly, 3: Custom Date
  DateTime _customDate = DateTime.now();

  RashiphalDashboard? _dashboard;
  DailyRashiphal? _customPrediction;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedSignIndex = widget.initialSignIndex ?? 0;
    _loadPreferencesAndFetch();
  }

  Future<void> _loadPreferencesAndFetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSign = prefs.getInt(_prefKeySignIndex);
      final savedCityName = prefs.getString(_prefKeyCityName);
      final savedLat = prefs.getDouble(_prefKeyLat);
      final savedLng = prefs.getDouble(_prefKeyLng);

      if (widget.initialSignIndex == null && savedSign != null && savedSign >= 0 && savedSign < 12) {
        _selectedSignIndex = savedSign;
        _isDefaultSign = true;
      } else if (savedSign != null && savedSign == _selectedSignIndex) {
        _isDefaultSign = true;
      }

      if (savedCityName != null && savedLat != null && savedLng != null) {
        _selectedCity = City(
          name: savedCityName,
          state: '',
          country: '',
          latitude: savedLat,
          longitude: savedLng,
          timezone: 'UTC',
        );
      }
    } catch (_) {}

    await _fetchPredictions();
  }

  Future<void> _fetchPredictions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final location = Location(
        latitude: _selectedCity.latitude,
        longitude: _selectedCity.longitude,
      );

      final dashboard = await _rashiphalService.getDashboardForSign(
        _selectedSignIndex,
        location: location,
      );

      DailyRashiphal? custom;
      if (_selectedTab == 3) {
        custom = await _rashiphalService.generateDailyPredictionForSign(
          _selectedSignIndex,
          location,
          _customDate,
        );
      }

      if (mounted) {
        setState(() {
          _dashboard = dashboard;
          _customPrediction = custom;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleDefaultSign(bool value) async {
    setState(() => _isDefaultSign = value);
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setInt(_prefKeySignIndex, _selectedSignIndex);
    } else {
      await prefs.remove(_prefKeySignIndex);
    }
  }

  Future<void> _selectCity() async {
    final searchController = TextEditingController();
    var searchResults = <City>[];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ContentDialog(
              title: const Text('Select Location for Panchang'),
              content: SizedBox(
                width: 400,
                height: 320,
                child: Column(
                  children: [
                    TextBox(
                      controller: searchController,
                      placeholder: 'Search city (e.g. Delhi, Mumbai, London)...',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(FluentIcons.search),
                      ),
                      onChanged: (query) async {
                        if (query.trim().length >= 2) {
                          final results = await CityDatabase.searchCities(query.trim());
                          setDialogState(() {
                            searchResults = results;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: searchResults.isEmpty
                          ? Center(
                              child: Text(
                                searchController.text.isEmpty
                                    ? 'Type a city name to search'
                                    : 'No matching cities found',
                                style: FluentTheme.of(context).typography.caption,
                              ),
                            )
                          : ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final city = searchResults[index];
                                return ListTile.selectable(
                                  title: Text(city.name),
                                  subtitle: Text('${city.state}, ${city.country}'),
                                  onPressed: () async {
                                    Navigator.pop(dialogContext);
                                    setState(() {
                                      _selectedCity = city;
                                    });
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.setString(_prefKeyCityName, city.name);
                                    await prefs.setDouble(_prefKeyLat, city.latitude);
                                    await prefs.setDouble(_prefKeyLng, city.longitude);
                                    await _fetchPredictions();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                Button(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);
    final rashi = RashiInfo.all[_selectedSignIndex];

    return ScaffoldPage(
      header: PageHeader(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(FluentIcons.back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            const Icon(FluentIcons.sunny, color: AppStyles.primaryColor, size: 24),
            const SizedBox(width: 10),
            Text(
              'Daily Rashifal',
              style: FluentTheme.of(context).typography.title,
            ),
            const SizedBox(width: 8),
            Text(
              '(${rashi.sanskrit} - ${rashi.name})',
              style: FluentTheme.of(context).typography.subtitle?.copyWith(
                    color: AppStyles.primaryColor,
                  ),
            ),
          ],
        ),
        commandBar: CommandBar(
          overflowBehavior: CommandBarOverflowBehavior.dynamicOverflow,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.poi),
              label: Text(_selectedCity.name),
              onPressed: _selectCity,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: _fetchPredictions,
            ),
          ],
        ),
      ),
      content: CustomScrollView(
        slivers: [
          // 1. Rashi Selector Grid / Carousel
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: 8,
              ),
              child: _buildRashiSelector(context, isMobile),
            ),
          ),

          // 2. Selected Rashi Overview Card
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: 6,
              ),
              child: _buildRashiProfileBanner(context, rashi),
            ),
          ),

          // 3. Tab / Timeline Selector (Today / Tomorrow / Weekly / Custom)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: 8,
              ),
              child: _buildTimeframeSelector(context, isMobile),
            ),
          ),

          // 4. Content Area
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProgressRing(),
                      SizedBox(height: 16),
                      Text('Calculating planetary transits & daily influences...'),
                    ],
                  ),
                ),
              ),
            )
          else if (_errorMessage != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: InfoBar(
                  title: const Text('Calculation Error'),
                  content: Text(_errorMessage!),
                  severity: InfoBarSeverity.error,
                  action: Button(
                    onPressed: _fetchPredictions,
                    child: const Text('Retry'),
                  ),
                ),
              ),
            )
          else if (_dashboard != null)
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: 8,
              ),
              sliver: SliverToBoxAdapter(
                child: _buildSelectedContent(_dashboard!),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildRashiSelector(BuildContext context, bool isMobile) {
    return Card(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Moon Sign (राशि चयन करें)',
                style: FluentTheme.of(context).typography.bodyStrong,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    checked: _isDefaultSign,
                    onChanged: (v) => _toggleDefaultSign(v ?? false),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Remember my Rashi',
                    style: FluentTheme.of(context).typography.caption,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: isMobile ? 86 : 96,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: RashiInfo.all.length,
              itemBuilder: (context, index) {
                final item = RashiInfo.all[index];
                final isSelected = index == _selectedSignIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: HoverButton(
                    onPressed: () {
                      if (_selectedSignIndex != index) {
                        setState(() {
                          _selectedSignIndex = index;
                          _isDefaultSign = false;
                        });
                        _fetchPredictions();
                      }
                    },
                    builder: (context, states) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isMobile ? 90 : 105,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppStyles.primaryColor.withValues(alpha: 0.18)
                              : (states.contains(WidgetState.hovered)
                                  ? FluentTheme.of(context).cardColor.withValues(alpha: 0.8)
                                  : FluentTheme.of(context).cardColor),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppStyles.primaryColor
                                : FluentTheme.of(context).resources.dividerStrokeColorDefault,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.symbol,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isSelected
                                        ? AppStyles.primaryColor
                                        : FluentTheme.of(context).typography.body?.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.sanskrit,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppStyles.primaryColor
                                        : FluentTheme.of(context).typography.body?.color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.name,
                              style: FluentTheme.of(context).typography.caption?.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.lord} • ${item.element}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRashiProfileBanner(BuildContext context, RashiInfo rashi) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles.darkSurface,
            AppStyles.accentColor.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppStyles.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppStyles.primaryColor, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  rashi.symbol,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${rashi.name} (${rashi.sanskrit})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Lord: ${rashi.lord}  |  Element: ${rashi.element}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildRashiMetaBadge('Lucky Color', rashi.luckyColor, FluentIcons.color),
              _buildRashiMetaBadge('Lucky Number', '${rashi.luckyNumber}', FluentIcons.number_field),
              _buildRashiMetaBadge('Lucky Direction', rashi.luckyDirection, FluentIcons.compass_n_w),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRashiMetaBadge(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppStyles.primaryColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeframeSelector(BuildContext context, bool isMobile) {
    return Card(
      padding: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(10),
      child: isMobile
          ? ComboBox<int>(
              value: _selectedTab,
              items: const [
                ComboBoxItem(value: 0, child: Text("Today's Guidance (आज)")),
                ComboBoxItem(value: 1, child: Text("Tomorrow's Preview (कल)")),
                ComboBoxItem(value: 2, child: Text('7-Day Forecast (साप्ताहिक)')),
                ComboBoxItem(value: 3, child: Text('Custom Date (तिथि अनुसार)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedTab = val);
                  if (val == 3 && _customPrediction == null) {
                    _fetchPredictions();
                  }
                }
              },
            )
          : Row(
              children: [
                _buildTabButton(0, "Today's Guidance (आज)", FluentIcons.sunny),
                const SizedBox(width: 8),
                _buildTabButton(1, "Tomorrow's Preview (कल)", FluentIcons.calendar_reply),
                const SizedBox(width: 8),
                _buildTabButton(2, '7-Day Forecast (साप्ताहिक)', FluentIcons.calendar_week),
                const SizedBox(width: 8),
                _buildTabButton(3, 'Custom Date', FluentIcons.date_time),
                if (_selectedTab == 3) ...[
                  const SizedBox(width: 16),
                  DatePicker(
                    selected: _customDate,
                    onChanged: (date) {
                      setState(() => _customDate = date);
                      _fetchPredictions();
                    },
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: Button(
        onPressed: () {
          setState(() => _selectedTab = index);
          if (index == 3 && _customPrediction == null) {
            _fetchPredictions();
          }
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(
            isSelected
                ? AppStyles.primaryColor.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              side: BorderSide(
                color: isSelected ? AppStyles.primaryColor : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppStyles.primaryColor : null,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppStyles.primaryColor : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedContent(RashiphalDashboard dashboard) {
    switch (_selectedTab) {
      case 0:
        return DailyPredictionCard(prediction: dashboard.today, isToday: true);
      case 1:
        return DailyPredictionCard(prediction: dashboard.tomorrow, isToday: false);
      case 2:
        return Column(
          children: dashboard.weeklyOverview.map((p) {
            final isToday = p.date.day == DateTime.now().day &&
                p.date.month == DateTime.now().month &&
                p.date.year == DateTime.now().year;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: DailyPredictionCard(
                prediction: p,
                isToday: isToday,
              ),
            );
          }).toList(),
        );
      case 3:
        if (_customPrediction != null) {
          return DailyPredictionCard(
            prediction: _customPrediction!,
            isToday: _customDate.day == DateTime.now().day,
          );
        }
        return const Center(child: ProgressRing());
      default:
        return const SizedBox.shrink();
    }
  }
}
