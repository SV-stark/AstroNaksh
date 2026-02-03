import 'package:fluent_ui/fluent_ui.dart';
import '../../data/models.dart';
import '../../core/birth_time_rectifier.dart';
import 'package:intl/intl.dart';

class BirthTimeRectifierScreen extends StatefulWidget {
  const BirthTimeRectifierScreen({super.key});

  @override
  State<BirthTimeRectifierScreen> createState() =>
      _BirthTimeRectifierScreenState();
}

class _BirthTimeRectifierScreenState extends State<BirthTimeRectifierScreen> {
  final BirthTimeRectifier _rectifier = BirthTimeRectifier();

  late BirthData _originalData;
  Duration _adjustment = Duration.zero;

  RectificationData? _currentData;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is BirthData) {
        _originalData = args;
        _calculate();
        _initialized = true;
      }
    }
  }

  Future<void> _calculate() async {
    setState(() => _isLoading = true);
    try {
      final data = await _rectifier.calculateForTime(
        originalData: _originalData,
        adjustment: _adjustment,
      );
      setState(() => _currentData = data);
    } catch (e) {
      displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Calculation Error'),
            content: Text(e.toString()),
            severity: InfoBarSeverity.error,
            onClose: close,
          );
        },
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _adjustTime(Duration delta) {
    setState(() {
      _adjustment += delta;
    });
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const ScaffoldPage(
        content: Center(child: Text("No birth data provided")),
      );
    }

    final adjustedTime = _originalData.dateTime.add(_adjustment);
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    return ScaffoldPage(
      header: PageHeader(
        title: const Text("Birth Time Rectification"),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.check_mark),
              onPressed: () {
                // Return new BirthData to previous screen
                final newData = BirthData(
                  name: _originalData.name,
                  dateTime: adjustedTime,
                  location: _originalData.location,
                  place: _originalData.place,
                );
                Navigator.pop(context, newData);
              },
              label: const Text("Apply"),
            ),
          ],
        ),
      ),
      content: Column(
        children: [
          // Time Controls
          Card(
            backgroundColor: FluentTheme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Original: ${formatter.format(_originalData.dateTime)}",
                    style: FluentTheme.of(context).typography.caption,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatter.format(adjustedTime),
                    style: FluentTheme.of(context).typography.subtitle
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Shift: ${_adjustment.inMinutes}m ${_adjustment.inSeconds % 60}s",
                    style: TextStyle(
                      color: _adjustment.isNegative ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton("-1m", const Duration(minutes: -1)),
                      _buildControlButton("-10s", const Duration(seconds: -10)),
                      _buildControlButton("-1s", const Duration(seconds: -1)),
                      const SizedBox(width: 16),
                      _buildControlButton("+1s", const Duration(seconds: 1)),
                      _buildControlButton("+10s", const Duration(seconds: 10)),
                      _buildControlButton("+1m", const Duration(minutes: 1)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: ProgressRing())
                : _currentData == null
                ? const Center(child: Text("Error calculating"))
                : _buildAnalysis(_currentData!),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(String label, Duration delta) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Button(onPressed: () => _adjustTime(delta), child: Text(label)),
    );
  }

  Widget _buildAnalysis(RectificationData data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard("Ascendants (Lagna)", [
          _buildRow("D-1 (Rashi)", data.d1Ascendant),
          _buildRow("D-9 (Navamsa)", data.d9Ascendant, isBold: true),
          _buildRow("D-60 (Shashtyamsa)", data.d60Ascendant),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard("Key Positions", [
          _buildRow("Moon Sign", data.moonSign),
          _buildRow("Navamsa Moon", data.d9MoonSign),
        ]),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Note: Watch for changes in D-9 and D-60 Lagna. These are most sensitive to time. "
              "Matching D-9 Lagna with native's appearance/nature is a common rectification technique.",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: FluentTheme.of(context).typography.bodyStrong),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? FluentTheme.of(context).accentColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
