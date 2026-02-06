import 'package:fluent_ui/fluent_ui.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'styles.dart';
import '../core/database_helper.dart';
import '../data/models.dart';
import '../core/settings_manager.dart';
import 'horary/horary_input_screen.dart';

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
    try {
      // Ensure database is initialized
      await _dbHelper.database;
      final charts = await _dbHelper.getCharts();
      print('DEBUG: Loaded ${charts.length} charts from database');
      setState(() {
        _charts = charts;
        _filteredCharts = charts;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG ERROR loading charts: $e');
      setState(() {
        _charts = [];
        _filteredCharts = [];
        _isLoading = false;
      });
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Error Loading Charts'),
            content: Text('Failed to load saved charts: $e'),
            severity: InfoBarSeverity.error,
          ),
        );
      }
    }
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
      content: CustomScrollView(
        slivers: [
          // Dashboard Quick Actions
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            sliver: SliverToBoxAdapter(
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
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.8,
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
                        icon: FluentIcons.heart_fill,
                        title: "Compare",
                        subtitle: "Chart compatibility",
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pushNamed(context, '/comparison');
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
                      _buildQuickAction(
                        icon: FluentIcons
                            .health, // Using Health icon as placeholder for Prasha/Question
                        title: "Horary (Prashna)",
                        subtitle: "Ask a question",
                        color: Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            FluentPageRoute(
                              builder: (_) => const HoraryInputScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Search & History Header
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            sliver: SliverToBoxAdapter(
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
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          _isLoading
              ? const SliverFillRemaining(child: Center(child: ProgressRing()))
              : _filteredCharts.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FluentIcons.contact_list,
                          size: 64,
                          color: Colors.grey.withAlpha(128),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "No saved charts yet",
                          style: FluentTheme.of(context).typography.title,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Create your first chart to get started",
                          style: TextStyle(color: Colors.grey[100]),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () async {
                            await Navigator.pushNamed(context, '/input');
                            _loadCharts();
                          },
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(FluentIcons.add),
                              SizedBox(width: 8),
                              Text("Create New Chart"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  sliver: SliverList.builder(
                    itemCount: _filteredCharts.length,
                    itemBuilder: (context, index) {
                      final chart = _filteredCharts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
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
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    Key? key,
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
