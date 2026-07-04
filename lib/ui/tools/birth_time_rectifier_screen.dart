// ignore_for_file: avoid_slow_async_io, unawaited_futures, deprecated_member_use, sort_constructors_first, implementation_imports
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;

import '../../core/birth_time_rectifier.dart';
import '../../core/utils/formatters.dart';
import '../../data/models.dart';
import '../../ui/utils/responsive_helper.dart';

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

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Birth Time Rectification Workspace'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.cancel),
              label: const Text('Cancel'),
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
              label: const Text('Apply Rectified Time'),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        padding: context.responsiveBodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Adjustment Workspace Panel
            Card(
              backgroundColor: FluentTheme.of(context).cardColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Original Birth Time',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppFormatters.formatDate(originalData.dateTime)} ${AppFormatters.formatTimeWithSeconds(originalData.dateTime)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Rectified Birth Time',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppFormatters.formatDate(adjustedTime)} ${AppFormatters.formatTimeWithSeconds(adjustedTime)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: FluentTheme.of(context).activeColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _adjustment.isNegative
                            ? Colors.red.withOpacity(0.08)
                            : Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _adjustment.isNegative
                              ? Colors.red.withOpacity(0.5)
                              : Colors.green.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        'Total Shift: ${_adjustment.inMinutes}m ${_adjustment.inSeconds % 60}s (${_adjustment.inSeconds} seconds)',
                        style: TextStyle(
                          color: _adjustment.isNegative
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Scrubber Slider
                    Row(
                      children: [
                        const Text(
                          '-30m',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Slider(
                              min: -1800,
                              max: 1800,
                              value: _adjustment.inSeconds.toDouble().clamp(
                                -1800.0,
                                1800.0,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _adjustment = Duration(seconds: val.toInt());
                                });
                              },
                              onChangeEnd: (val) {
                                _calculate();
                              },
                            ),
                          ),
                        ),
                        const Text(
                          '+30m',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick Buttons Row
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildControlButton(
                          '-5m',
                          const Duration(minutes: -5),
                          isNegative: true,
                        ),
                        _buildControlButton(
                          '-1m',
                          const Duration(minutes: -1),
                          isNegative: true,
                        ),
                        _buildControlButton(
                          '-10s',
                          const Duration(seconds: -10),
                          isNegative: true,
                        ),
                        _buildControlButton(
                          '-1s',
                          const Duration(seconds: -1),
                          isNegative: true,
                        ),
                        const SizedBox(width: 16),
                        _buildControlButton(
                          'Reset',
                          Duration.zero,
                          isNegative: false,
                          isReset: true,
                        ),
                        const SizedBox(width: 16),
                        _buildControlButton(
                          '+1s',
                          const Duration(seconds: 1),
                          isNegative: false,
                        ),
                        _buildControlButton(
                          '+10s',
                          const Duration(seconds: 10),
                          isNegative: false,
                        ),
                        _buildControlButton(
                          '+1m',
                          const Duration(minutes: 1),
                          isNegative: false,
                        ),
                        _buildControlButton(
                          '+5m',
                          const Duration(minutes: 5),
                          isNegative: false,
                        ),
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
                  padding: EdgeInsets.all(40),
                  child: ProgressRing(),
                ),
              )
            else if (_currentData == null)
              const Center(
                child: Text('No data loaded. Use the slider to begin.'),
              )
            else ...[
              // Grid for Side-by-side Charts / Boundaries and Dashas
              LayoutBuilder(
                builder: (context, constraints) {
                  final useHorizontal = constraints.maxWidth > 700;
                  final content = [
                    Expanded(
                      flex: useHorizontal ? 3 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Varga Charts & Boundaries'),
                          _buildVargaCard(
                            'D-1 Rashi Lagna',
                            _currentData!.d1Ascendant,
                            _currentData!.d1Boundary,
                            FluentTheme.of(context).accentColor,
                          ),
                          const SizedBox(height: 12),
                          _buildVargaCard(
                            'D-9 Navamsha Lagna',
                            _currentData!.d9Ascendant,
                            _currentData!.d9Boundary,
                            Colors.purple,
                            highlight: true,
                          ),
                          const SizedBox(height: 12),
                          _buildVargaCard(
                            'D-10 Dashamsha Lagna',
                            _currentData!.d10Ascendant,
                            _currentData!.d10Boundary,
                            Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _buildVargaCard(
                            'D-60 Shastiamsha Lagna',
                            _currentData!.d60Ascendant,
                            _currentData!.d60Boundary,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    if (useHorizontal)
                      const SizedBox(width: 16)
                    else
                      const SizedBox(height: 24),
                    Expanded(
                      flex: useHorizontal ? 2 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Key Positions & Dashas'),
                          _buildKeyPositionsCard(),
                          const SizedBox(height: 16),
                          _buildDashaTimelineCard(),
                        ],
                      ),
                    ),
                  ];

                  if (useHorizontal) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: content,
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: content.map((w) {
                        if (w is Expanded) return w.child;
                        return w;
                      }).toList(),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              const InfoBar(
                title: Text('Rectification Guidance'),
                content: Text(
                  '1. D-9 (Navamsha) Lagna changes every ~13 minutes. It signifies the spouse and general traits.\n'
                  '2. D-10 (Dashamsha) Lagna changes every ~12 minutes. It governs career, profession, and status.\n'
                  '3. D-60 (Shastiamsha) Lagna changes every ~2 minutes. It is highly sensitive and represents past karma and overall life trends.',
                ),
                severity: InfoBarSeverity.info,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
    String label,
    Duration delta, {
    required bool isNegative,
    bool isReset = false,
  }) {
    Color? color;
    if (isReset) {
      color = FluentTheme.of(context).activeColor;
    } else {
      color = isNegative ? Colors.red : Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Button(
        onPressed: () {
          if (isReset) {
            setState(() {
              _adjustment = Duration.zero;
            });
            _calculate();
          } else {
            _adjustTime(delta);
          }
        },
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildVargaCard(
    String varga,
    String ascendant,
    String boundary,
    Color accentColor, {
    bool highlight = false,
  }) {
    return Card(
      borderColor: highlight ? accentColor.withOpacity(0.4) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    varga,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    boundary,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Lagna Sign / Degree',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  ascendant,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: highlight ? accentColor : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyPositionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Planetary Signs',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildKeyRow('Moon Sign', _currentData!.moonSign),
            const Divider(
              style: DividerThemeData(
                verticalMargin: EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
            _buildKeyRow('D-9 Moon Sign', _currentData!.d9MoonSign),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildDashaTimelineCard() {
    final chartData = _currentData!.chartData;
    if (chartData == null) return const SizedBox.shrink();

    final dashas = chartData.getCurrentDashas(DateTime.now());
    if (dashas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No Dasha details found.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Vimshottari Dasha',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDashaRow(
              'Mahadasha',
              dashas['mahadasha'] as String,
              dashas['mahaStart'] as DateTime,
              dashas['mahaEnd'] as DateTime,
            ),
            const Divider(
              style: DividerThemeData(
                verticalMargin: EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
            _buildDashaRow(
              'Antardasha',
              dashas['antardasha'] as String,
              dashas['antarStart'] as DateTime,
              dashas['antarEnd'] as DateTime,
            ),
            const Divider(
              style: DividerThemeData(
                verticalMargin: EdgeInsets.symmetric(vertical: 8.0),
              ),
            ),
            _buildDashaRow(
              'Pratyantardasha',
              dashas['pratyantardasha'] as String,
              dashas['pratyanStart'] as DateTime,
              dashas['pratyanEnd'] as DateTime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashaRow(
    String label,
    String lord,
    DateTime start,
    DateTime end,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Text(
              lord,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: FluentTheme.of(context).accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Period: ${AppFormatters.formatDate(start)} to ${AppFormatters.formatDate(end)}',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
