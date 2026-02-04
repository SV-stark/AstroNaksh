import 'package:fluent_ui/fluent_ui.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'styles.dart';
import '../core/database_helper.dart';
import '../data/models.dart';
import '../core/settings_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _charts = [];
  List<Map<String, dynamic>> _filteredCharts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  // Tutorial Keys
  final GlobalKey _newChartKey = GlobalKey();
  final GlobalKey _panchangKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadCharts();
    _searchController.addListener(_onSearchChanged);

    // Check for tutorial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!SettingsManager().hasSeenTutorial) {
        _showTutorial();
      }
    });
  }

  void _showTutorial() {
    List<TargetFocus> targets = [];

    targets.add(
      TargetFocus(
        identify: "newChart",
        keyTarget: _newChartKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Create New Chart",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Click here to calculate a new birth chart by entering birth details.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "panchang",
        keyTarget: _panchangKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Daily Panchang",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Check daily Tithi, Nakshatra, and other almanac details here.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "search",
        keyTarget: _searchKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Search Charts",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Quickly find your saved charts by name.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    // Add Settings Target
    targets.add(
      TargetFocus(
        identify: "settings",
        keyTarget: _settingsKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Settings",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Configure app theme, language, and chart calculation preferences.",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        SettingsManager().setHasSeenTutorial(true);
      },
      onClickTarget: (target) {
        // Continue to next
      },
      onClickOverlay: (target) {
        // Continue to next
      },
      onSkip: () {
        SettingsManager().setHasSeenTutorial(true);
        return true;
      },
    ).show(context: context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCharts() async {
    setState(() => _isLoading = true);
    final charts = await _dbHelper.getCharts();
    setState(() {
      _charts = charts;
      _filteredCharts = charts;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCharts = _charts.where((chart) {
        final name = (chart['name'] as String? ?? '').toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dt = DateTime.parse(dateTimeStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }

  void _openChart(Map<String, dynamic> chart) {
    try {
      final birthData = BirthData(
        dateTime: DateTime.parse(chart['dateTime']),
        location: Location(
          latitude: chart['latitude'],
          longitude: chart['longitude'],
        ),
        name: chart['name'] ?? '',
        place: chart['locationName'] ?? '',
      );
      Navigator.pushNamed(context, '/chart', arguments: birthData);
    } catch (e) {
      displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Error opening chart'),
            content: Text(e.toString()),
            severity: InfoBarSeverity.error,
            onClose: close,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text("AstroNaksh"),
        commandBar: CommandBar(
          primaryItems: [],
          secondaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.share),
              label: const Text('Import/Export'),
              onPressed: () {},
            ),
            CommandBarButton(
              key: _settingsKey,
              icon: const Icon(FluentIcons.settings),
              label: const Text('Settings'),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quick Actions",
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      _buildQuickAction(
                        key: _newChartKey,
                        icon: FluentIcons.add,
                        title: "New Chart",
                        subtitle: "Calculate birth data",
                        color: AppStyles.primaryColor,
                        onTap: () async {
                          await Navigator.pushNamed(context, '/input');
                          _loadCharts();
                        },
                      ),
                      _buildQuickAction(
                        key: _panchangKey,
                        icon: FluentIcons.calendar,
                        title: "Panchang",
                        subtitle: "Daily almanac",
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pushNamed(context, '/panchang');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Search & History Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Text(
                    "Recent Charts",
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 250,
                    child: TextBox(
                      key: _searchKey,
                      controller: _searchController,
                      placeholder: "Search charts...",
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(FluentIcons.search),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: ProgressRing()),
                  )
                : _filteredCharts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(
                            FluentIcons.contact_list,
                            size: 48,
                            color: Colors.grey.withAlpha(128),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No charts found.",
                            style: TextStyle(color: Colors.grey[100]),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredCharts.length,
                    itemBuilder: (context, index) {
                      final chart = _filteredCharts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 4,
                        ),
                        child: Card(
                          padding: EdgeInsets.zero,
                          child: ListTile.selectable(
                            onPressed: () => _openChart(chart),
                            leading: Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppStyles.primaryColor.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                FluentIcons.contact,
                                color: AppStyles.primaryColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              chart['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${_formatDateTime(chart['dateTime'])}'
                              '${chart['locationName'] != null ? ' • ${chart['locationName']}' : ''}',
                            ),
                            trailing: IconButton(
                              icon: Icon(FluentIcons.delete, color: Colors.red),
                              onPressed: () async {
                                await _dbHelper.deleteChart(chart['id']);
                                _loadCharts();
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return HoverButton(
      onPressed: onTap,
      builder: (context, states) {
        return Card(
          key: key,
          padding: const EdgeInsets.all(12),
          backgroundColor: states.isHovered ? color.withAlpha(25) : null,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[100]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
