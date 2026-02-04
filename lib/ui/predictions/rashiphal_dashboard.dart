import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../logic/rashiphal_service.dart';
import '../widgets/daily_prediction_card.dart';

class RashiphalDashboardScreen extends StatefulWidget {
  final CompleteChartData chartData;

  const RashiphalDashboardScreen({super.key, required this.chartData});

  @override
  State<RashiphalDashboardScreen> createState() =>
      _RashiphalDashboardScreenState();
}

class _RashiphalDashboardScreenState extends State<RashiphalDashboardScreen> {
  final RashiphalService _rashiphalService = RashiphalService();
  late Future<RashiphalDashboard> _dashboardFuture;
  int _selectedPivot = 0; // 0: Today, 1: Tomorrow, 2: Weekly

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _rashiphalService.getDashboardData(widget.chartData);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Daily Rashiphal'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: FutureBuilder<RashiphalDashboard>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ProgressRing());
          }

          if (snapshot.hasError) {
            return Center(
              child: InfoBar(
                title: const Text('Error'),
                content: Text('Could not load predictions: ${snapshot.error}'),
                severity: InfoBarSeverity.error,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final dashboard = snapshot.data!;

          return Column(
            children: [
              // Segmented Control (Pivots in Fluent UI usually act as tabs)
              // We'll use a simple Row of Buttons or a Pivot widget if available in this version.
              // Fluent UI 4.x has NavigationView or TabView, but for sub-page nav, Pivot is standard.
              // However, Fluent UI package might not expose Pivot as a standalone easily, let's use a custom toggle row.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ComboBox<int>(
                    value: _selectedPivot,
                    items: const [
                      ComboBoxItem(value: 0, child: Text("Today's Guidance")),
                      ComboBoxItem(value: 1, child: Text("Tomorrow's Preview")),
                      ComboBoxItem(value: 2, child: Text("Weekly Overview")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPivot = value ?? 0;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildContent(dashboard),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(RashiphalDashboard dashboard) {
    switch (_selectedPivot) {
      case 0:
        return DailyPredictionCard(prediction: dashboard.today, isToday: true);
      case 1:
        return DailyPredictionCard(
          prediction: dashboard.tomorrow,
          isToday: false,
        );
      case 2:
        return Column(
          children: dashboard.weeklyOverview.map((p) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: DailyPredictionCard(
                prediction: p,
                isToday: p.date.day == DateTime.now().day,
              ),
            );
          }).toList(),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
