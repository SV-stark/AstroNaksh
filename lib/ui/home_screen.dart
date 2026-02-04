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
          primaryItems: [
            CommandBarButton(
              key: _newChartKey,
              icon: const Icon(FluentIcons.add),
              label: const Text('New Chart'),
              onPressed: () async {
                await Navigator.pushNamed(context, '/input');
                _loadCharts();
              },
            ),
            CommandBarButton(
              key: _panchangKey,
              icon: const Icon(FluentIcons.calendar),
              label: const Text('Panchang'),
              onPressed: () {
                Navigator.pushNamed(context, '/panchang');
              },
            ),
          ],
          secondaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.share),
              label: const Text('Import/Export'),
              onPressed: () {
                // TODO: Import/Export Dialog
              },
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
      content: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
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

          Expanded(
            child: _isLoading
                ? const Center(child: ProgressRing())
                : _filteredCharts.isEmpty
                ? const Center(
                    child: Text(
                      "No charts found.",
                      style: TextStyle(
                        color: Colors.white,
                      ), // Colors.white works if imported from material? No, usually not. Fluent has Colors.white?
                      // Fluent Colors.white exists.
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCharts.length,
                    itemBuilder: (context, index) {
                      final chart = _filteredCharts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Card(
                          child: ListTile.selectable(
                            onPressed: () => _openChart(chart),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppStyles.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                FluentIcons.contact,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(chart['name'] ?? 'Unknown'),
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
          ),
        ],
      ),
    );
  }
}
