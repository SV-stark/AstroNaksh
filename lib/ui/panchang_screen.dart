import 'package:fluent_ui/fluent_ui.dart';
import '../logic/panchang_service.dart';
import '../data/models.dart';

class PanchangScreen extends StatefulWidget {
  const PanchangScreen({super.key});

  @override
  State<PanchangScreen> createState() => _PanchangScreenState();
}

class _PanchangScreenState extends State<PanchangScreen> {
  DateTime _selectedDate = DateTime.now();
  final PanchangService _panchangService = PanchangService();
  PanchangResult? _result;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculatePanchang();
  }

  Future<void> _calculatePanchang() async {
    setState(() => _isLoading = true);
    try {
      // Default to New Delhi coordinates
      final location = Location(latitude: 28.6139, longitude: 77.2090);

      final result = await _panchangService.getPanchang(
        _selectedDate,
        location,
      );
      setState(() {
        _result = result;
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Daily Panchang'),
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Date Header
                  Text(
                    _result!.date,
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 20),

                  // Grid of Cards
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.0,
                      children: [
                        _buildInfoCard(
                          'Tithi',
                          _result!.tithi,
                          FluentIcons.calendar_day,
                        ),
                        _buildInfoCard(
                          'Nakshatra',
                          _result!.nakshatra,
                          FluentIcons.favorite_star,
                        ),
                        _buildInfoCard('Yoga', _result!.yoga, FluentIcons.flow),
                        _buildInfoCard(
                          'Karana',
                          _result!.karana,
                          FluentIcons.stopwatch,
                        ),
                        _buildInfoCard(
                          'Vara',
                          _result!.vara,
                          FluentIcons.calendar,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: FluentTheme.of(context).accentColor),
          const SizedBox(height: 8),
          Text(title, style: FluentTheme.of(context).typography.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: FluentTheme.of(context).typography.bodyStrong,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
