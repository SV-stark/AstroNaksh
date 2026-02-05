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

  BirthData? _originalData;
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
    if (_originalData == null) return;
    
    setState(() => _isLoading = true);
    try {
      final data = await _rectifier.calculateForTime(
        originalData: _originalData!,
        adjustment: _adjustment,
      );
      setState(() => _currentData = data);
    } catch (e) {
      if (mounted) {
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
      }
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
    if (!_initialized || _originalData == null) {
      return const ScaffoldPage(content: Center(child: ProgressRing()));
    }

    final originalData = _originalData!;
    final adjustedTime = originalData.dateTime.add(_adjustment);
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    return ScaffoldPage(
      header: PageHeader(
        title: const Text("Birth Time Rectification"),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.cancel),
              label: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.check_mark),
            onPressed: () {
                // Return new BirthData to previous screen
                final newData = BirthData(
                  name: originalData.name,
                  dateTime: adjustedTime,
                  location: originalData.location,
                  place: originalData.place,
                );
                Navigator.pop(context, newData);
              },
              label: const Text("Apply New Time"),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Controls
            Card(
              backgroundColor: FluentTheme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Original: ${formatter.format(originalData.dateTime)}",
                      style: FluentTheme.of(context).typography.caption,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      formatter.format(adjustedTime),
                      style: FluentTheme.of(context).typography.title,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _adjustment.isNegative
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _adjustment.isNegative
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      child: Text(
                        "Shift: ${_adjustment.inMinutes}m ${_adjustment.inSeconds % 60}s",
                        style: TextStyle(
                          color: _adjustment.isNegative
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Negative Controls
                        _buildGroup([
                          _buildControlButton(
                            "-1m",
                            const Duration(minutes: -1),
                            isNegative: true,
                          ),
                          _buildControlButton(
                            "-10s",
                            const Duration(seconds: -10),
                            isNegative: true,
                          ),
                          _buildControlButton(
                            "-1s",
                            const Duration(seconds: -1),
                            isNegative: true,
                          ),
                        ]),

                        const SizedBox(width: 24),

                        // Positive Controls
                        _buildGroup([
                          _buildControlButton(
                            "+1s",
                            const Duration(seconds: 1),
                            isNegative: false,
                          ),
                          _buildControlButton(
                            "+10s",
                            const Duration(seconds: 10),
                            isNegative: false,
                          ),
                          _buildControlButton(
                            "+1m",
                            const Duration(minutes: 1),
                            isNegative: false,
                          ),
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: ProgressRing(),
                ),
              )
            else if (_currentData == null)
              const Center(child: Text("Error calculating data"))
            else
              Column(
                children: [
                  _buildSectionHeader("Analysis"),
                  _buildDataCard("Ascendants (Lagna)", [
                    _buildDataRow("D-1 (Rashi)", _currentData!.d1Ascendant),
                    _buildDataRow(
                      "D-9 (Navamsa)",
                      _currentData!.d9Ascendant,
                      highlight: true,
                    ),
                    _buildDataRow(
                      "D-60 (Shashtyamsa)",
                      _currentData!.d60Ascendant,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildDataCard("Key Positions", [
                    _buildDataRow("Moon Sign", _currentData!.moonSign),
                    _buildDataRow("Navamsa Moon", _currentData!.d9MoonSign),
                  ]),
                  const SizedBox(height: 24),
                  InfoBar(
                    title: const Text("Rectification Tip"),
                    content: const Text(
                      "Watch for changes in D-9 and D-60 Lagna. These are most sensitive to time. "
                      "Matching D-9 Lagna with native's appearance/nature is a common rectification technique.",
                    ),
                    severity: InfoBarSeverity.info,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildControlButton(
    String label,
    Duration delta, {
    required bool isNegative,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Button(
        onPressed: () => _adjustTime(delta),
        child: Text(
          label,
          style: TextStyle(
            color: isNegative ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: FluentTheme.of(context).typography.subtitle),
    );
  }

  Widget _buildDataCard(String title, List<TableRow> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(2),
              },
              children: rows,
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildDataRow(String label, String value, {bool highlight = false}) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: FluentTheme.of(
              context,
            ).resources.dividerStrokeColorDefault.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: FluentTheme.of(context).typography.caption),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? FluentTheme.of(context).accentColor : null,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
