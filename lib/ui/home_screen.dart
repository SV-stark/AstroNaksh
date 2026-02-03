import 'package:flutter/material.dart';
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
    // Convert DB row to BirthData
    // Note: DB structure needs to match BirthData conversion
    try {
      final birthData = BirthData(
        dateTime: DateTime.parse(chart['dateTime']),
        location: Location(
          latitude: chart['latitude'],
          longitude: chart['longitude'],
        ),
      );
      Navigator.pushNamed(context, '/chart', arguments: birthData);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening chart: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AstroFast"),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            onPressed: () {
              // TODO: Import/Export Dialog
            },
            tooltip: "Import/Export",
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search charts...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCharts.isEmpty
                ? const Center(
                    child: Text(
                      "No charts found.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCharts.length,
                    itemBuilder: (context, index) {
                      final chart = _filteredCharts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AppStyles.primaryColor,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(chart['name'] ?? 'Unknown'),
                          subtitle: Text(
                            '${_formatDateTime(chart['dateTime'])}'
                            '${chart['locationName'] != null ? ' • ${chart['locationName']}' : ''}',
                          ),
                          onTap: () => _openChart(chart),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              await _dbHelper.deleteChart(chart['id']);
                              _loadCharts();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/input');
          // Reload charts when returning from input screen
          _loadCharts();
        },
        icon: const Icon(Icons.add),
        label: const Text("New Chart"),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: AppStyles.white,
      ),
    );
  }
}
