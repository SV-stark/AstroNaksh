import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jyotish/core.dart';

import '../../core/ayanamsa_calculator.dart';
import '../../core/chart_customization.dart';
import '../../core/database.dart';
import '../../core/ephemeris_manager.dart';
import '../../core/settings_provider.dart';
import '../../data/models.dart' as model;
import '../../data/sample_charts.dart';
import '../chart/chart_helpers.dart';
import '../widgets/chart_widget.dart';

class AyanamsaSandboxScreen extends ConsumerStatefulWidget {
  const AyanamsaSandboxScreen({super.key, this.birthData});
  final model.BirthData? birthData;

  @override
  ConsumerState<AyanamsaSandboxScreen> createState() =>
      _AyanamsaSandboxScreenState();
}

class _TransitChartData {
  _TransitChartData({
    required this.chart,
    required this.planetsMap,
    required this.ascSign,
  });
  final VedicChart chart;
  final Map<int, List<String>> planetsMap;
  final int ascSign;
}

class _AyanamsaSandboxScreenState extends ConsumerState<AyanamsaSandboxScreen> {
  model.BirthData? _selectedBirthData;
  List<Chart> _savedCharts = [];

  SiderealMode _leftMode = SiderealMode.lahiri;
  SiderealMode _rightMode = SiderealMode.krishnamurtiVP291;

  _TransitChartData? _leftChartData;
  _TransitChartData? _rightChartData;
  bool _calculating = false;

  @override
  void initState() {
    super.initState();
    _selectedBirthData = widget.birthData;
    unawaited(_loadSavedCharts());
    if (_selectedBirthData == null && SampleCharts.samples.isNotEmpty) {
      _selectedBirthData = SampleCharts.samples.first;
    }
    unawaited(_calculateCharts());
  }

  Future<void> _loadSavedCharts() async {
    try {
      final db = ref.read(databaseProvider);
      final charts = await db.select(db.charts).get();
      if (mounted) {
        setState(() {
          _savedCharts = charts;
        });
      }
    } catch (_) {
      // Silently ignore — saved charts are a convenience, not required
    }
  }

  Future<void> _calculateCharts() async {
    if (_selectedBirthData == null) return;
    setState(() => _calculating = true);

    try {
      final birth = _selectedBirthData!;
      final location = GeographicLocation(
        latitude: birth.location.latitude,
        longitude: birth.location.longitude,
        altitude: 0,
      );

      final leftChart = await EphemerisManager.jyotish.calculateVedicChart(
        dateTime: birth.dateTime,
        location: location,
        flags: CalculationFlags.sidereal(_leftMode),
      );

      final rightChart = await EphemerisManager.jyotish.calculateVedicChart(
        dateTime: birth.dateTime,
        location: location,
        flags: CalculationFlags.sidereal(_rightMode),
      );

      if (mounted) {
        setState(() {
          _leftChartData = _TransitChartData(
            chart: leftChart,
            planetsMap: ChartHelpers.getPlanetsMap(leftChart),
            ascSign: ChartHelpers.getAscendantSignInt(leftChart),
          );
          _rightChartData = _TransitChartData(
            chart: rightChart,
            planetsMap: ChartHelpers.getPlanetsMap(rightChart),
            ascSign: ChartHelpers.getAscendantSignInt(rightChart),
          );
          _calculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _calculating = false);
        unawaited(
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Calculation Error'),
              content: Text(e.toString()),
              severity: InfoBarSeverity.error,
              onClose: close,
            ),
          ),
        );
      }
    }
  }

  void _onChartSelected(model.BirthData birthData) {
    setState(() {
      _selectedBirthData = birthData;
    });
    unawaited(_calculateCharts());
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider).value;
    final preferredStyle =
        settingsState?.chartSettings.chartStyle ?? ChartStyle.northIndian;

    final allSystems = AyanamsaCalculator.systems;

    return NavigationView(
      titleBar: TitleBar(
        title: Row(
          children: [
            IconButton(
              icon: const Icon(FluentIcons.back),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            const Text('Ayanamsa Sandbox & Comparison'),
          ],
        ),
      ),
      content: ScaffoldPage(
        header: _buildHeader(allSystems),
        content: _selectedBirthData == null
            ? const Center(child: Text('Please select or input birth data.'))
            : _calculating || _leftChartData == null || _rightChartData == null
            ? const Center(child: ProgressRing())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // Dual Charts Side-by-Side
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final useVertical = constraints.maxWidth < 750;
                        final chartSize = useVertical
                            ? constraints.maxWidth * 0.9
                            : (constraints.maxWidth - 32) / 2;

                        final leftChartWidget = Column(
                          children: [
                            _dropdownSelector(
                              label: 'Left System',
                              value: _leftMode,
                              systems: allSystems,
                              onChanged: (mode) {
                                if (mode != null) {
                                  setState(() => _leftMode = mode);
                                  _calculateCharts();
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            ChartWidget(
                              planetsBySign: _leftChartData!.planetsMap,
                              ascendantSign: _leftChartData!.ascSign,
                              style: preferredStyle,
                              size: chartSize.clamp(200.0, 400.0),
                              baseChart: _leftChartData!.chart,
                            ),
                          ],
                        );

                        final rightChartWidget = Column(
                          children: [
                            _dropdownSelector(
                              label: 'Right System',
                              value: _rightMode,
                              systems: allSystems,
                              onChanged: (mode) {
                                if (mode != null) {
                                  setState(() => _rightMode = mode);
                                  _calculateCharts();
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            ChartWidget(
                              planetsBySign: _rightChartData!.planetsMap,
                              ascendantSign: _rightChartData!.ascSign,
                              style: preferredStyle,
                              size: chartSize.clamp(200.0, 400.0),
                              baseChart: _rightChartData!.chart,
                            ),
                          ],
                        );

                        if (useVertical) {
                          return Column(
                            children: [
                              leftChartWidget,
                              const SizedBox(height: 24),
                              rightChartWidget,
                            ],
                          );
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: leftChartWidget),
                            const SizedBox(width: 16),
                            Expanded(child: rightChartWidget),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Comparison Table
                    _buildComparisonTable(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _dropdownSelector({
    required String label,
    required SiderealMode value,
    required List<AyanamsaSystem> systems,
    required ValueChanged<SiderealMode?> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        ComboBox<SiderealMode>(
          value: value,
          items: systems.where((s) => s.mode != null).map((s) {
            return ComboBoxItem<SiderealMode>(
              value: s.mode,
              child: Text(s.description),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildHeader(List<AyanamsaSystem> systems) {
    final dropDownItems = <MenuFlyoutItemBase>[];

    // Add sample charts
    for (final sample in SampleCharts.samples) {
      dropDownItems.add(
        MenuFlyoutItem(
          text: Text('${sample.name} (Sample)'),
          onPressed: () => _onChartSelected(sample),
        ),
      );
    }

    if (_savedCharts.isNotEmpty) {
      dropDownItems.add(const MenuFlyoutSeparator());
      for (final saved in _savedCharts) {
        dropDownItems.add(
          MenuFlyoutItem(
            text: Text(saved.name ?? 'Saved Chart'),
            onPressed: () {
              try {
                final birth = model.BirthData(
                  dateTime: DateTime.parse(saved.birthTime!),
                  location: model.Location(
                    latitude: saved.latitude!,
                    longitude: saved.longitude!,
                  ),
                  name: saved.name ?? '',
                  place: saved.locationName ?? '',
                  timezone: saved.timezone ?? '',
                );
                _onChartSelected(birth);
              } catch (_) {}
            },
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedBirthData?.name ?? 'No Chart Selected',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _selectedBirthData != null
                      ? '${_selectedBirthData!.place} • ${ChartHelpers.formatDate(_selectedBirthData!.dateTime)}'
                      : 'Select a chart to compare positions.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            DropDownButton(
              title: const Text('Change Chart'),
              leading: const Icon(FluentIcons.contact),
              items: dropDownItems,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    final leftChart = _leftChartData!.chart;
    final rightChart = _rightChartData!.chart;

    final planets = [
      Planet.sun,
      Planet.moon,
      Planet.mars,
      Planet.mercury,
      Planet.jupiter,
      Planet.venus,
      Planet.saturn,
      Planet.meanNode, // Rahu
      Planet.ketu,
    ];

    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.table,
                color: FluentTheme.of(context).accentColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Planetary Differences & Borderline Highlights',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.2),
              4: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Planet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Left Position',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Right Position',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Difference',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'House / Sign Shift',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ...planets.map((planet) {
                double leftLong = 0;
                double rightLong = 0;
                var leftFormatted = '';
                var rightFormatted = '';
                var leftHouse = 1;
                var rightHouse = 1;

                if (planet == Planet.ketu) {
                  leftLong = leftChart.ketu.longitude;
                  rightLong = rightChart.ketu.longitude;
                  leftFormatted =
                      '${leftChart.ketu.formattedPosition} (H${leftChart.houses.getHouseForLongitude(leftLong)})';
                  rightFormatted =
                      '${rightChart.ketu.formattedPosition} (H${rightChart.houses.getHouseForLongitude(rightLong)})';
                  leftHouse = leftChart.houses.getHouseForLongitude(leftLong);
                  rightHouse = rightChart.houses.getHouseForLongitude(
                    rightLong,
                  );
                } else {
                  final lInfo =
                      leftChart.getPlanet(planet) ??
                      (planet == Planet.meanNode ? leftChart.rahu : null);
                  final rInfo =
                      rightChart.getPlanet(planet) ??
                      (planet == Planet.meanNode ? rightChart.rahu : null);
                  if (lInfo != null && rInfo != null) {
                    leftLong = lInfo.longitude;
                    rightLong = rInfo.longitude;
                    leftFormatted =
                        '${lInfo.formattedPosition} (H${lInfo.house})';
                    rightFormatted =
                        '${rInfo.formattedPosition} (H${rInfo.house})';
                    leftHouse = lInfo.house;
                    rightHouse = rInfo.house;
                  }
                }

                // Calculate degree difference
                final diffDegrees = (leftLong - rightLong).abs() % 360;
                final diffMin = diffDegrees * 60;
                final diffSec = (diffMin - diffMin.floor()) * 60;
                final diffStr = '${diffMin.floor()}\' ${diffSec.floor()}"';

                final leftSign = (leftLong / 30).floor() % 12;
                final rightSign = (rightLong / 30).floor() % 12;

                final isSignShift = leftSign != rightSign;
                final isHouseShift = leftHouse != rightHouse;

                // Borderline condition (near boundaries: e.g. <0.5 degrees / 30 arcminutes from 0° or 30° of a sign)
                final leftBorderline =
                    (leftLong % 30 < 0.5) || (leftLong % 30 > 29.5);
                final rightBorderline =
                    (rightLong % 30 < 0.5) || (rightLong % 30 > 29.5);
                final isBorderline = leftBorderline || rightBorderline;

                Color? rowBg;
                var shiftDesc = 'No Shift';
                if (isSignShift || isHouseShift) {
                  rowBg = Colors.orange.withValues(alpha: 0.1);
                  shiftDesc =
                      '${isSignShift ? "Sign Shift" : ""} ${isHouseShift ? "House Shift" : ""}'
                          .trim();
                } else if (isBorderline) {
                  rowBg = Colors.yellow.withValues(alpha: 0.08);
                  shiftDesc = 'Borderline';
                }

                return TableRow(
                  decoration: BoxDecoration(
                    color: rowBg,
                    border: Border(
                      bottom: BorderSide(
                        color: FluentTheme.of(
                          context,
                        ).resources.dividerStrokeColorDefault.withAlpha(50),
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        planet.displayName,
                        style: TextStyle(
                          fontWeight:
                              (isSignShift || isHouseShift || isBorderline)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(leftFormatted),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(rightFormatted),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(diffStr),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        shiftDesc,
                        style: TextStyle(
                          color: (isSignShift || isHouseShift)
                              ? Colors.red
                              : isBorderline
                              ? Colors.orange
                              : Colors.green,
                          fontWeight:
                              (isSignShift || isHouseShift || isBorderline)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
