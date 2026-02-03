import 'package:fluent_ui/fluent_ui.dart';
import 'styles.dart';
import '../core/database_helper.dart';
import '../data/models.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCharts();
    _searchController.addListener(_onSearchChanged);
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
        title: const Text("AstroFast"),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('New Chart'),
              onPressed: () async {
                await Navigator.pushNamed(context, '/input');
                _loadCharts();
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
              icon: const Icon(FluentIcons.settings),
              label: const Text('Settings'),
              onPressed: () {
                // TODO: Settings
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
