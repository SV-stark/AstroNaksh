import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:flutter/material.dart' show Colors;
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../core/responsive_helper.dart';
import 'widgets/chart_widget.dart';
import 'widgets/planetary_timeline.dart';
import '../../data/models.dart';
import '../../logic/kp_chart_service.dart';

import 'package:jyotish/jyotish.dart';
import '../../core/ayanamsa_calculator.dart';
import '../../core/constants.dart';

import '../../core/settings_manager.dart';
import 'tools/birth_time_rectifier_screen.dart';
import '../../core/saved_charts_helper.dart';
import '../../core/database_helper.dart';
// New analysis screens
import 'strength/ashtakavarga_screen.dart';
import 'strength/shadbala_screen.dart';
import 'strength/bhava_bala_screen.dart';
import 'analysis/yoga_dosha_screen.dart';
import 'analysis/planetary_maitri_screen.dart';
import 'predictions/transit_screen.dart';
import '../../logic/planetary_aspect_service.dart';
import 'predictions/varshaphal_screen.dart';
import 'analysis/retrograde_screen.dart';
import 'analysis/sudarshan_chakra_screen.dart';
import 'comparison/chart_comparison_screen.dart';
import 'predictions/rashiphal_dashboard.dart';
import 'predictions/life_predictions_screen.dart';
import 'reports/pdf_report_screen.dart';
import '../../core/chart_share_service.dart';
import 'analysis/jaimini_screen.dart';
import 'analysis/progeny_screen.dart';
import 'analysis/nadi_screen.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final KPChartService _kpChartService = KPChartService();
  Future<CompleteChartData>? _chartDataFuture;
  ChartStyle _style = ChartStyle.northIndian;
  String _selectedDivisionalChart = 'D-9';
  BirthData? _birthData;
  int _currentIndex = 0;
  int _dashaTabIndex = 0; // 0 = Vimshottari, 1 = Yogini, 2 = Chara
  bool _showAspects = false; // Toggle for planetary aspects (drishti)
  final GlobalKey _d1ChartKey = GlobalKey();
  final GlobalKey _analysisMenuKey = GlobalKey();
  static bool _hasSeenChartTutorialSession = false;

  // Timeline state variables
  DateTime _timelineCurrentDate = DateTime.now();
  bool _isTimelinePlaying = false;
  double _timelineSpeed = 1.0;
  Timer? _timelineTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_birthData == null) {
      final args = ModalRoute.of(context)?.settings.arguments as BirthData?;
      if (args != null) {
        _birthData = args;
        _loadChartData();

        if (!_hasSeenChartTutorialSession) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showChartTutorial();
          });
        }
      } else {
        // Handle missing arguments
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            displayInfoBar(
              context,
              builder: (context, close) => InfoBar(
                title: const Text('Error'),
                content: const Text('No birth data provided'),
                severity: InfoBarSeverity.error,
              ),
            );
            Navigator.pop(context);
          }
        });
      }
    }
  }

  void _loadChartData() {
    if (_birthData != null) {
      setState(() {
        _chartDataFuture = _kpChartService.generateCompleteChart(_birthData!);
      });
    }
  }

  void _showChartTutorial() {
    _hasSeenChartTutorialSession = true;
    List<TargetFocus> targets = [];

    targets.add(
      TargetFocus(
        identify: "d1Chart",
        keyTarget: _d1ChartKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Birth Chart",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "This is your main D-1 Rashi chart. Scroll down for planetary details and timeline.",
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
        identify: "analysisMenu",
        keyTarget: _analysisMenuKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Deep Analysis",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Click here to access advanced tools like KP System, Shadbala, Ashtakavarga and PDF Reports.",
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
    ).show(context: context);
  }

  void _openAyanamsaSelection() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final allSystems = AyanamsaCalculator.systems;
            final filteredSystems = searchQuery.isEmpty
                ? allSystems
                : allSystems
                      .where(
                        (s) =>
                            s.name.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ) ||
                            s.description.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ),
                      )
                      .toList();

            return ContentDialog(
              title: const Text('Select Ayanamsa'),
              content: SizedBox(
                height: 400,
                child: Column(
                  children: [
                    TextBox(
                      placeholder: "Search Ayanamsa...",
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(FluentIcons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredSystems.length,
                        itemBuilder: (context, index) {
                          final system = filteredSystems[index];
                          final isSelected =
                              SettingsManager().chartSettings.ayanamsaSystem
                                  .toLowerCase() ==
                              system.name.toLowerCase();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: RadioButton(
                              checked: isSelected,
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    system.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (system.description != system.name)
                                    Text(
                                      system.description,
                                      style: FluentTheme.of(
                                        context,
                                      ).typography.caption,
                                    ),
                                ],
                              ),
                              onChanged: (v) {
                                if (v == true) {
                                  SettingsManager()
                                          .chartSettings
                                          .ayanamsaSystem =
                                      system.name;
                                  Navigator.pop(context);
                                  _loadChartData();
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Button(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBirthDetails() {
    if (_birthData == null) return;
    showDialog(
      context: context,
      builder: (context) {
        return ContentDialog(
          title: const Text('Birth Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Name: ${_birthData!.name}"),
              Text(
                "Date: ${_birthData!.dateTime.day}/${_birthData!.dateTime.month}/${_birthData!.dateTime.year}",
              ),
              Text(
                "Time: ${_birthData!.dateTime.hour.toString().padLeft(2, '0')}:${_birthData!.dateTime.minute.toString().padLeft(2, '0')}",
              ),
              Text("Place: ${_birthData!.place}"),
              Text(
                "Lat: ${_birthData!.location.latitude.toStringAsFixed(4)}, Lon: ${_birthData!.location.longitude.toStringAsFixed(4)}",
              ),
            ],
          ),
          actions: [
            Button(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _saveCurrentChart() async {
    if (_birthData == null) return;

    // Save to both SharedPreferences and Database for compatibility
    await SavedChartsHelper.saveChart(_birthData!);

    final dbHelper = DatabaseHelper();
    await dbHelper.insertChart({
      'name': _birthData!.name,
      'dateTime': _birthData!.dateTime.toIso8601String(),
      'latitude': _birthData!.location.latitude,
      'longitude': _birthData!.location.longitude,
      'locationName': _birthData!.place,
      'timezone': _birthData!.timezone.isEmpty ? 'UTC' : _birthData!.timezone,
    });

    if (!mounted) return;
    displayInfoBar(
      context,
      builder: (context, close) {
        return InfoBar(
          title: const Text('Saved'),
          content: const Text('Chart details saved successfully.'),
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
          severity: InfoBarSeverity.success,
        );
      },
    );
  }

  // Timeline methods
  void _onTimelineDateChanged(DateTime date) {
    setState(() {
      _timelineCurrentDate = date;
    });
  }

  void _onTimelinePlay() {
    setState(() {
      _isTimelinePlaying = true;
    });
    _timelineTimer = Timer.periodic(
      Duration(milliseconds: (100 / _timelineSpeed).round()),
      (timer) {
        setState(() {
          _timelineCurrentDate = _timelineCurrentDate.add(
            const Duration(days: 1),
          );
          if (_timelineCurrentDate.isAfter(
            DateTime.now().add(const Duration(days: 365)),
          )) {
            _timelineCurrentDate = DateTime.now().add(
              const Duration(days: 365),
            );
            _onTimelinePause();
          }
        });
      },
    );
  }

  void _onTimelinePause() {
    setState(() {
      _isTimelinePlaying = false;
    });
    _timelineTimer?.cancel();
    _timelineTimer = null;
  }

  void _onTimelineSpeedChanged(double speed) {
    setState(() {
      _timelineSpeed = speed;
      if (_isTimelinePlaying) {
        _onTimelinePause();
        _onTimelinePlay();
      }
    });
  }

  @override
  void dispose() {
    _timelineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Vedic Chart"),
        actions: CommandBar(
          overflowBehavior: CommandBarOverflowBehavior.dynamicOverflow,
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            // --- View & Calculation Options (Left/Start) ---
            if (!ResponsiveHelper.useMobileLayout(context)) ...[
              CommandBarButton(
                icon: Icon(
                  _style == ChartStyle.northIndian
                      ? FluentIcons.grid_view_small
                      : FluentIcons.diamond,
                ),
                label: const Text('Style'),
                onPressed: () {
                  setState(() {
                    _style = _style == ChartStyle.northIndian
                        ? ChartStyle.southIndian
                        : ChartStyle.northIndian;
                  });
                },
              ),
              CommandBarButton(
                icon: Icon(_showAspects ? FluentIcons.view : FluentIcons.hide),
                label: Text(_showAspects ? 'Aspects On' : 'Aspects Off'),
                onPressed: () {
                  setState(() {
                    _showAspects = !_showAspects;
                  });
                },
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.globe),
                label: const Text('Ayanamsa'),
                onPressed: _openAyanamsaSelection,
              ),
            ],

            // --- Analysis & Tools ---
            if (!ResponsiveHelper.useMobileLayout(context))
              CommandBarBuilderItem(
                builder: (context, mode, w) {
                  return DropDownButton(
                    title: const Text('Analysis'),
                    leading: const Icon(FluentIcons.analytics_view),
                    items: [
                      MenuFlyoutSubItem(
                        text: const Text('Strength'),
                        leading: const Icon(FluentIcons.favorite_star),
                        items: (context) => [
                          MenuFlyoutItem(
                            text: const Text('Shadbala'),
                            leading: const Icon(FluentIcons.favorite_star),
                            onPressed: () => _navigateTo('shadbala'),
                          ),
                          MenuFlyoutItem(
                            text: const Text('Ashtakavarga'),
                            leading: const Icon(FluentIcons.grid_view_small),
                            onPressed: () => _navigateTo('ashtakavarga'),
                          ),
                          MenuFlyoutItem(
                            text: const Text('Bhava Bala'),
                            leading: const Icon(FluentIcons.home),
                            onPressed: () => _navigateTo('bhava_bala'),
                          ),
                        ],
                      ),
                      MenuFlyoutSubItem(
                        text: const Text('Predictions'),
                        leading: const Icon(FluentIcons.calendar),
                        items: (context) => [
                          MenuFlyoutItem(
                            text: const Text('Transit'),
                            leading: const Icon(FluentIcons.history),
                            onPressed: () => _navigateTo('transit'),
                          ),
                          MenuFlyoutItem(
                            text: const Text('Varshaphal'),
                            leading: const Icon(FluentIcons.calendar),
                            onPressed: () => _navigateTo('varshaphal'),
                          ),
                        ],
                      ),
                      MenuFlyoutSubItem(
                        text: const Text('Special'),
                        leading: const Icon(FluentIcons.lightbulb),
                        items: (context) => [
                          MenuFlyoutItem(
                            text: const Text('Jaimini (AK, Karakamsa)'),
                            leading: const Icon(FluentIcons.favorite_star),
                            onPressed: () => _navigateTo('jaimini'),
                          ),
                          MenuFlyoutItem(
                            text: const Text('Yoga & Dosha'),
                            leading: const Icon(FluentIcons.scale_volume),
                            onPressed: () => _navigateTo('yoga_dosha'),
                          ),
                          MenuFlyoutItem(
                            text: const Text('Planetary Maitri'),
                            leading: const Icon(FluentIcons.people),
                            onPressed: () => _navigateTo('planetary_maitri'),
                          ),
                          MenuFlyoutItem(
                            text: const Text('Retrograde'),
                            leading: const Icon(FluentIcons.repeat_one),
                            onPressed: () => _navigateTo('retrograde'),
                          ),
                          MenuFlyoutItem(
                            text: const Text('Sudarshan Chakra'),
                            leading: const Icon(FluentIcons.view_all),
                            onPressed: () => _navigateTo('sudarshan_chakra'),
                          ),
                          MenuFlyoutItem(
                            text: const Text('Comparison'),
                            leading: const Icon(FluentIcons.compare),
                            onPressed: () => _navigateTo('comparison'),
                          ),
                          MenuFlyoutItem(
                            text: const Text('Progeny'),
                            leading: const Icon(FluentIcons.reminder_person),
                            onPressed: () => _navigateTo('progeny'),
                          ),
                          MenuFlyoutItem(
                            text: const Text('Nadi Analysis'),
                            leading: const Icon(FluentIcons.flow),
                            onPressed: () => _navigateTo('nadi'),
                          ),
                        ],
                      ),
                      const MenuFlyoutSeparator(),
                      MenuFlyoutItem(
                        text: const Text('PDF Report'),
                        leading: const Icon(FluentIcons.pdf),
                        onPressed: () => _navigateTo('pdf_report'),
                      ),
                    ],
                  );
                },
                wrappedItem: CommandBarButton(
                  key: _analysisMenuKey,
                  icon: const Icon(FluentIcons.analytics_view),
                  label: const Text('Analysis'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => ContentDialog(
                        title: const Text('Analysis Tools'),
                        content: SizedBox(
                          height: 300,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildMobileAnalysisLink(
                                  'Shadbala',
                                  'shadbala',
                                  FluentIcons.favorite_star,
                                ),
                                _buildMobileAnalysisLink(
                                  'Ashtakavarga',
                                  'ashtakavarga',
                                  FluentIcons.grid_view_small,
                                ),
                                _buildMobileAnalysisLink(
                                  'Bhava Bala',
                                  'bhava_bala',
                                  FluentIcons.home,
                                ),
                                const Divider(),
                                _buildMobileAnalysisLink(
                                  'Transit',
                                  'transit',
                                  FluentIcons.history,
                                ),
                                _buildMobileAnalysisLink(
                                  'Varshaphal',
                                  'varshaphal',
                                  FluentIcons.calendar,
                                ),
                                const Divider(),
                                _buildMobileAnalysisLink(
                                  'Yoga & Dosha',
                                  'yoga_dosha',
                                  FluentIcons.scale_volume,
                                ),
                                _buildMobileAnalysisLink(
                                  'Planetary Maitri',
                                  'planetary_maitri',
                                  FluentIcons.people,
                                ),
                                _buildMobileAnalysisLink(
                                  'Retrograde',
                                  'retrograde',
                                  FluentIcons.repeat_one,
                                ),
                                _buildMobileAnalysisLink(
                                  'Sudarshan Chakra',
                                  'sudarshan_chakra',
                                  FluentIcons.view_all,
                                ),
                                _buildMobileAnalysisLink(
                                  'Comparison',
                                  'comparison',
                                  FluentIcons.compare,
                                ),
                                const Divider(),
                                _buildMobileAnalysisLink(
                                  'PDF Report',
                                  'pdf_report',
                                  FluentIcons.pdf,
                                ),
                              ],
                            ),
                          ),
                        ),
                        actions: [
                          Button(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            if (!ResponsiveHelper.useMobileLayout(context))
              CommandBarButton(
                icon: const Icon(FluentIcons.build),
                label: const Text('Rectify'),
                onPressed: () async {
                  // ... (Logic)
                  if (_birthData == null) return;
                  final newData = await Navigator.push(
                    context,
                    FluentPageRoute(
                      builder: (context) => const BirthTimeRectifierScreen(),
                      settings: RouteSettings(arguments: _birthData),
                    ),
                  );

                  if (newData != null && newData is BirthData) {
                    setState(() {
                      _birthData = newData;
                      _loadChartData();
                    });
                  }
                },
              ),

            // --- Primary Actions (End) ---
            const CommandBarSeparator(),
            CommandBarButton(
              icon: const Icon(FluentIcons.save),
              label: const Text('Save'),
              onPressed: _saveCurrentChart,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.share),
              label: const Text('Share'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return ContentDialog(
                      title: const Text('Share Chart'),
                      content: const Text(
                        'How would you like to share this chart?',
                      ),
                      actions: [
                        Button(
                          onPressed: () async {
                            Navigator.pop(context);
                            if (_d1ChartKey.currentContext == null) return;
                            try {
                              await ChartShareService.shareChartImage(
                                _d1ChartKey,
                                filename:
                                    '${_birthData?.name ?? 'chart'}_D1.png',
                              );
                            } catch (e) {
                              if (context.mounted) {
                                displayInfoBar(
                                  context,
                                  builder: (context, close) => InfoBar(
                                    title: const Text('Share Failed'),
                                    content: Text(e.toString()),
                                    severity: InfoBarSeverity.error,
                                    onClose: close,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Image (D-1)'),
                        ),
                        Button(
                          onPressed: () async {
                            Navigator.pop(context);
                            final data = await _chartDataFuture;
                            if (data != null && _birthData != null) {
                              try {
                                await ChartShareService.shareChartPdf(
                                  data,
                                  _birthData!,
                                  filename:
                                      '${_birthData?.name ?? 'report'}.pdf',
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  displayInfoBar(
                                    context,
                                    builder: (context, close) => InfoBar(
                                      title: const Text('Share Failed'),
                                      content: Text(e.toString()),
                                      severity: InfoBarSeverity.error,
                                      onClose: close,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: const Text('PDF Report'),
                        ),
                        Button(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),

            if (!ResponsiveHelper.useMobileLayout(context)) ...[
              const CommandBarSeparator(),
              CommandBarButton(
                icon: const Icon(FluentIcons.info),
                label: const Text('Info'),
                onPressed: _showBirthDetails,
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.settings),
                label: const Text('Settings'),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ],
          secondaryItems: [
            // --- Secondary Actions (Overflow Menu) ---
            // Force these into overflow on mobile for better touch targets
            if (ResponsiveHelper.useMobileLayout(context)) ...[
              CommandBarButton(
                icon: Icon(
                  _style == ChartStyle.northIndian
                      ? FluentIcons.grid_view_small
                      : FluentIcons.diamond,
                ),
                label: Text(
                  'Style: ${_style == ChartStyle.northIndian ? 'North Indian' : 'South Indian'}',
                ),
                onPressed: () {
                  setState(() {
                    _style = _style == ChartStyle.northIndian
                        ? ChartStyle.southIndian
                        : ChartStyle.northIndian;
                  });
                },
              ),
              CommandBarButton(
                icon: Icon(_showAspects ? FluentIcons.view : FluentIcons.hide),
                label: Text(_showAspects ? 'Hide Aspects' : 'Show Aspects'),
                onPressed: () {
                  setState(() {
                    _showAspects = !_showAspects;
                  });
                },
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.globe),
                label: const Text('Select Ayanamsa'),
                onPressed: _openAyanamsaSelection,
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.analytics_view),
                label: const Text('Analysis Tools'),
                onPressed: () {
                  // Show a dialog or bottom sheet for analysis tools because
                  // a nested dropdown in a command bar menu might be weird.
                  // Or we can just navigate to a "Menu" or show the same Dropdown logic.
                  // Let's use a simple dialog for now to match the desktop dropdown content.
                  showDialog(
                    context: context,
                    builder: (context) => ContentDialog(
                      title: const Text('Analysis Tools'),
                      content: SizedBox(
                        height: 300,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildMobileAnalysisLink(
                                'Shadbala',
                                'shadbala',
                                FluentIcons.favorite_star,
                              ),
                              _buildMobileAnalysisLink(
                                'Ashtakavarga',
                                'ashtakavarga',
                                FluentIcons.grid_view_small,
                              ),
                              _buildMobileAnalysisLink(
                                'Bhava Bala',
                                'bhava_bala',
                                FluentIcons.home,
                              ),
                              const Divider(),
                              _buildMobileAnalysisLink(
                                'Transit',
                                'transit',
                                FluentIcons.history,
                              ),
                              _buildMobileAnalysisLink(
                                'Varshaphal',
                                'varshaphal',
                                FluentIcons.calendar,
                              ),
                              const Divider(),
                              _buildMobileAnalysisLink(
                                'Yoga & Dosha',
                                'yoga_dosha',
                                FluentIcons.scale_volume,
                              ),
                              _buildMobileAnalysisLink(
                                'Planetary Maitri',
                                'planetary_maitri',
                                FluentIcons.people,
                              ),
                              _buildMobileAnalysisLink(
                                'Retrograde',
                                'retrograde',
                                FluentIcons.repeat_one,
                              ),
                              _buildMobileAnalysisLink(
                                'Sudarshan Chakra',
                                'sudarshan_chakra',
                                FluentIcons.view_all,
                              ),
                              _buildMobileAnalysisLink(
                                'Comparison',
                                'comparison',
                                FluentIcons.compare,
                              ),
                              const Divider(),
                              _buildMobileAnalysisLink(
                                'PDF Report',
                                'pdf_report',
                                FluentIcons.pdf,
                              ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        Button(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.build),
                label: const Text('Birth Time Rectification'),
                onPressed: () async {
                  if (_birthData == null) return;
                  final newData = await Navigator.push(
                    context,
                    FluentPageRoute(
                      builder: (context) => const BirthTimeRectifierScreen(),
                      settings: RouteSettings(arguments: _birthData),
                    ),
                  );

                  if (newData != null && newData is BirthData) {
                    setState(() {
                      _birthData = newData;
                      _loadChartData();
                    });
                  }
                },
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.info),
                label: const Text('Birth Details'),
                onPressed: _showBirthDetails,
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.settings),
                label: const Text('Settings'),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ],
        ),
      ),
      pane: NavigationPane(
        selected: _currentIndex,
        onChanged: (i) => setState(() => _currentIndex = i),
        displayMode: ResponsiveHelper.getNavigationPaneDisplayMode(context),
        size: NavigationPaneSize(
          openWidth: context.paneWidth,
          compactWidth: context.compactPaneWidth,
        ),
        header: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getCurrentTabIcon(_currentIndex),
                size: 32,
                color: FluentTheme.of(context).accentColor,
              ),
              const SizedBox(height: 8),
              Text(
                _getCurrentTabTitle(_currentIndex),
                style: FluentTheme.of(
                  context,
                ).typography.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        items: [
          PaneItemHeader(header: const Text('Main Charts')),
          PaneItem(
            icon: const Icon(FluentIcons.contact_card),
            title: const Text("D-1 Rashi"),
            body: _buildBody(_buildD1Tab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.grid_view_large),
            title: const Text("Vargas"),
            body: _buildBody(_buildVargasTab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.scatter_chart),
            title: const Text("KP System"),
            body: _buildBody(_buildKPTab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.timer),
            title: const Text("Dasha Periods"),
            body: _buildBody(_buildDashaTab),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.list),
            title: const Text("Planet Details"),
            body: _buildBody(_buildDetailsTab),
          ),
          PaneItemHeader(header: const Text('Analysis')),
          PaneItem(
            icon: const Icon(FluentIcons.heart),
            title: const Text("Life Predictions"),
            body: _buildBody((data) => LifePredictionsScreen(chartData: data)),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.lightbulb),
            title: const Text("Daily Rashiphal"),
            body: _buildBody(
              (data) => RashiphalDashboardScreen(chartData: data),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAnalysisLink(String title, String navKey, IconData icon) {
    final isMobile = ResponsiveHelper.useMobileLayout(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SizedBox(
        height: isMobile ? 56 : 44,
        child: Button(
          onPressed: () {
            Navigator.pop(context);
            _navigateTo(navKey);
          },
          child: Row(
            children: [
              Icon(icon, size: isMobile ? 24 : 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: isMobile ? 16 : 14),
                ),
              ),
              Icon(FluentIcons.chevron_right, size: isMobile ? 20 : 12),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(String value) async {
    if (_chartDataFuture == null) return;
    // Wait for data? We can pass future or wait.
    // Usually users click after data loads.
    // For simplicity, we assume loaded or handle inside screen.
    // Most screens take 'chartData'.
    final chartData = await _chartDataFuture;
    if (chartData == null || !mounted) return;

    Widget screen;
    switch (value) {
      case 'ashtakavarga':
        screen = AshtakavargaScreen(chartData: chartData);
        break;
      case 'shadbala':
        screen = ShadbalaScreen(chartData: chartData);
        break;
      case 'bhava_bala':
        screen = BhavaBalaScreen(chartData: chartData);
        break;
      case 'yoga_dosha':
        screen = YogaDoshaScreen(chartData: chartData);
        break;
      case 'planetary_maitri':
        screen = PlanetaryMaitriScreen(chartData: chartData);
        break;
      case 'transit':
        screen = TransitScreen(natalChart: chartData);
        break;
      case 'varshaphal':
        screen = VarshaphalScreen(birthData: _birthData!);
        break;
      case 'retrograde':
        screen = RetrogradeScreen(chartData: chartData);
        break;
      case 'sudarshan_chakra':
        screen = SudarshanChakraScreen(chartData: chartData);
        break;
      case 'comparison':
        screen = ChartComparisonScreen(chart1: chartData);
        break;
      case 'jaimini':
        screen = JaiminiScreen(chartData: chartData);
        break;
      case 'progeny':
        screen = ProgenyScreen(chartData: chartData);
        break;
      case 'nadi':
        screen = NadiScreen(chartData: chartData);
        break;
      case 'pdf_report':
        screen = PDFReportScreen(chartData: chartData);
        break;
      default:
        return;
    }

    Navigator.push(context, FluentPageRoute(builder: (context) => screen));
  }

  Widget _buildBody(Widget Function(CompleteChartData) builder) {
    return FutureBuilder<CompleteChartData>(
      future: _chartDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: ProgressRing());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  "Error: ${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: FluentTheme.of(context).typography.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Button(
                      onPressed: _loadChartData,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(FluentIcons.refresh, size: 16),
                          const SizedBox(width: 8),
                          const Text("Retry"),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Button(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Go Back"),
                    ),
                  ],
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData) {
          return const Center(child: Text("No Data"));
        }
        return builder(snapshot.data!);
      },
    );
  }

  Widget _buildD1Tab(CompleteChartData data) {
    final planetsMap = _getPlanetsMap(data.baseChart);
    final ascSign = _getAscendantSignInt(data.baseChart);
    final aspects = PlanetaryAspectService.calculateAspects(data.baseChart);
    final chartSize = ResponsiveHelper.getChartSize(context);

    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        children: [
          Text(
            "Rashi Chart (D-1)",
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 8),
          Text(
            "Lagna: ${_getAscendantSign(data.baseChart)}",
            style: FluentTheme.of(context).typography.body,
          ),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: _d1ChartKey,
            child: ChartWidget(
              planetsBySign: planetsMap,
              ascendantSign: ascSign,
              style: _style,
              size: chartSize,
              aspects: aspects,
              showAspects: _showAspects,
            ),
          ),
          const SizedBox(height: 24),
          // Timeline for planetary animation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        FluentIcons.timeline_progress,
                        size: 20,
                        color: FluentTheme.of(context).accentColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Planetary Timeline',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      const Spacer(),
                      Text(
                        'Drag to see planetary motion',
                        style: FluentTheme.of(context).typography.caption
                            ?.copyWith(
                              color: FluentTheme.of(context).inactiveColor,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PlanetaryTimeline(
                    startDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    endDate: DateTime.now().add(const Duration(days: 365)),
                    currentDate: _timelineCurrentDate,
                    onDateChanged: _onTimelineDateChanged,
                    onPlayPressed: _onTimelinePlay,
                    onPausePressed: _onTimelinePause,
                    isPlaying: _isTimelinePlaying,
                    playbackSpeed: _timelineSpeed,
                    onSpeedChanged: _onTimelineSpeedChanged,
                  ),
                  const SizedBox(height: 12),
                  // Show current date info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FluentTheme.of(
                        context,
                      ).accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FluentIcons.calendar,
                          size: 16,
                          color: FluentTheme.of(context).accentColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Viewing: ${_timelineCurrentDate.day}/${_timelineCurrentDate.month}/${_timelineCurrentDate.year}',
                            style: FluentTheme.of(context).typography.body,
                          ),
                        ),
                        Text(
                          _isTimelinePlaying ? 'Playing' : 'Paused',
                          style: FluentTheme.of(context).typography.caption
                              ?.copyWith(
                                color: _isTimelinePlaying
                                    ? Colors.green
                                    : FluentTheme.of(context).inactiveColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildPlanetPositionsTable(data),
        ],
      ),
    );
  }

  Widget _buildVargasTab(CompleteChartData data) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Divisional Charts (Vargas)",
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling list for Charts
          SizedBox(
            height: ResponsiveHelper.useMobileLayout(context) ? 56 : 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children:
                  [
                        'D-1',
                        'D-2',
                        'D-3',
                        'D-4',
                        'D-7',
                        'D-9',
                        'D-10',
                        'D-12',
                        'D-16',
                        'D-20',
                        'D-24',
                        'D-27',
                        'D-30',
                        'D-40',
                        'D-45',
                        'D-60',
                      ]
                      .map(
                        (code) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            height: ResponsiveHelper.useMobileLayout(context)
                                ? 48
                                : 32,
                            child: ToggleButton(
                              checked: _selectedDivisionalChart == code,
                              onChanged: (selected) {
                                if (selected) {
                                  setState(
                                    () => _selectedDivisionalChart = code,
                                  );
                                }
                              },
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontSize:
                                      ResponsiveHelper.useMobileLayout(context)
                                      ? 16
                                      : 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildDivisionalChartDisplay(data, _selectedDivisionalChart),
        ],
      ),
    );
  }

  Widget _buildDivisionalChartDisplay(CompleteChartData data, String code) {
    final chart = data.divisionalCharts[code];
    final chartSize = ResponsiveHelper.getChartSize(context);

    if (chart == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Chart data not available"),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "${chart.name} (${chart.code})",
              style: FluentTheme.of(context).typography.subtitle,
            ),
            Text(
              chart.description,
              style: FluentTheme.of(context).typography.caption,
            ),
            if (chart.ascendantSign != null) ...[
              const SizedBox(height: 4),
              Text(
                "Ascendant: ${_getSignName(chart.ascendantSign! + 1)}",
                style: FluentTheme.of(context).typography.body,
              ),
            ],
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 16),
            ChartWidget(
              planetsBySign: _getDivisionalPlanetsMap(chart),
              ascendantSign: (chart.ascendantSign ?? 0) + 1,
              style: _style,
              size: chartSize,
            ),
            const SizedBox(height: 16),
            _buildDivisionalPlanetPositionsTable(chart),
          ],
        ),
      ),
    );
  }

  Widget _buildDivisionalPlanetPositionsTable(DivisionalChartData chart) {
    final positions = chart.positions;
    final nakshatras = AppConstants.nakshatras;

    return SizedBox(
      width: double.infinity,
      child: Card(
        backgroundColor: FluentTheme.of(context).accentColor.withAlpha(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Planet Positions in ${chart.name}',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 16),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1.2),
                  3: FlexColumnWidth(1.5),
                  4: FlexColumnWidth(0.6),
                },
                children: [
                  const TableRow(
                    children: [
                      Text(
                        'Planet',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Sign',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Degrees',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Nakshatra',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Pada',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const TableRow(
                    children: [
                      SizedBox(height: 8),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                    ],
                  ),
                  // Divider Row
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: FluentTheme.of(
                            context,
                          ).resources.dividerStrokeColorDefault,
                        ),
                      ),
                    ),
                    children: List.filled(5, const SizedBox(height: 4)),
                  ),
                  const TableRow(
                    children: [
                      SizedBox(height: 8),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                      SizedBox(),
                    ],
                  ),
                  ...positions.entries.map((entry) {
                    final planetName = entry.key;
                    final longitude = entry.value;

                    // Sign (1-12)
                    final signIndex = (longitude / 30).floor();
                    final signName = _getSignName(signIndex + 1);

                    // Degrees within sign
                    final degInSign = longitude % 30;
                    final degrees = degInSign.floor();
                    final minutes = ((degInSign - degrees) * 60).floor();
                    final seconds =
                        (((degInSign - degrees) * 60 - minutes) * 60).round();
                    final degStr =
                        '${degrees.toString().padLeft(2, '0')}°${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';

                    // Nakshatra (each is 13°20' = 13.333...)
                    final nakshatraIndex = (longitude / 13.333333).floor() % 27;
                    final nakshatraName = nakshatras[nakshatraIndex];

                    // Pada (4 padas per nakshatra, each 3°20' = 3.333...)
                    final padaInNakshatra =
                        ((longitude % 13.333333) / 3.333333).floor() + 1;

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            planetName.substring(0, 1).toUpperCase() +
                                planetName.substring(1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(signName),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(degStr),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(nakshatraName),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('$padaInNakshatra'),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPTab(CompleteChartData data) {
    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("KP System", style: FluentTheme.of(context).typography.subtitle),
          const SizedBox(height: 16),
          _buildKPSubLordsCard(data),
          const SizedBox(height: 16),
          _buildKPSignificatorsCard(data),
          const SizedBox(height: 16),
          _buildRulingPlanetsCard(data),
        ],
      ),
    );
  }

  Widget _buildKPSubLordsCard(CompleteChartData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "KP Sub Lords",
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            ...data.significatorTable.entries.map((entry) {
              final planet = entry.key;
              final info = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Expander(
                  header: Text(
                    planet,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  content: Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _buildKPDetailItem(
                        "Nakshatra",
                        info['nakshatra']?.toString() ?? '-',
                      ),
                      _buildKPDetailItem(
                        "Star Lord",
                        info['starLord']?.toString() ?? '-',
                      ),
                      _buildKPDetailItem(
                        "Sub Lord",
                        info['subLord']?.toString() ?? '-',
                      ),
                      _buildKPDetailItem(
                        "Sub-Sub",
                        info['subSubLord']?.toString() ?? '-',
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKPDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildKPSignificatorsCard(CompleteChartData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Significations",
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            ...data.significatorTable.entries.map((entry) {
              final planet = entry.key;
              final info = entry.value;
              final significations =
                  info['significations'] as List<dynamic>? ?? [];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Expander(
                  header: Text(
                    planet,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  content: Text(
                    significations.isNotEmpty
                        ? significations.join(', ')
                        : 'None',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRulingPlanetsCard(CompleteChartData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ruling Planets",
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: data.kpData.rulingPlanets
                  .map(
                    (planet) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FluentTheme.of(context).accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        planet,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashaTab(CompleteChartData data) {
    return Column(
      children: [
        // Tab bar for selecting dasha type
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildDashaTabButton(
                  'Vimshottari',
                  FluentIcons.timeline_progress,
                  0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDashaTabButton('Yogini', FluentIcons.flow, 1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDashaTabButton('Chara', FluentIcons.rotate, 2),
              ),
            ],
          ),
        ),
        const Divider(),
        // Content based on selected tab
        Expanded(
          child: IndexedStack(
            index: _dashaTabIndex,
            children: [
              _buildVimshottariDashaContent(data.dashaData.vimshottari),
              _buildYoginiDashaContent(data.dashaData.yogini),
              _buildCharaDashaContent(data.dashaData.chara),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashaTabButton(String label, IconData icon, int index) {
    final isSelected = _dashaTabIndex == index;
    final accentColor = FluentTheme.of(context).accentColor;

    return HoverButton(
      onPressed: () => setState(() => _dashaTabIndex = index),
      builder: (context, states) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : accentColor.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? accentColor : accentColor.withAlpha(50),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : accentColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : accentColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVimshottariDashaContent(VimshottariDasha dasha) {
    final now = DateTime.now();
    final currentMahaIndex = dasha.mahadashas.indexWhere(
      (m) => now.isAfter(m.startDate) && now.isBefore(m.endDate),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info Card
          Card(
            backgroundColor: FluentTheme.of(context).accentColor.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.info,
                    color: FluentTheme.of(context).accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Birth Lord: ${dasha.birthLord}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Balance at Birth: ${dasha.formattedBalanceAtBirth}',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Mahadasha Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mahadasha Periods',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 12),
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: FluentTheme.of(context).accentColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Lord',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Period',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Duration',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Table Rows
                  ...dasha.mahadashas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final maha = entry.value;
                    final isCurrent = index == currentMahaIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? FluentTheme.of(context).accentColor.withAlpha(40)
                            : (index % 2 == 0
                                  ? Colors.grey.withAlpha(10)
                                  : null),
                        borderRadius: BorderRadius.circular(4),
                        border: isCurrent
                            ? Border.all(
                                color: FluentTheme.of(context).accentColor,
                                width: 1,
                              )
                            : null,
                      ),
                      child: Expander(
                        initiallyExpanded: isCurrent,
                        header: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  if (isCurrent)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: FluentTheme.of(
                                          context,
                                        ).accentColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Text(
                                    maha.lord,
                                    style: TextStyle(
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isCurrent
                                          ? FluentTheme.of(context).accentColor
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${_formatDate(maha.startDate)} - ${_formatDate(maha.endDate)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                maha.formattedPeriod,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Antardashas:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ...maha.antardashas.map((antar) {
                              final isCurrentAntar =
                                  isCurrent &&
                                  now.isAfter(antar.startDate) &&
                                  now.isBefore(antar.endDate);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentAntar
                                      ? FluentTheme.of(
                                          context,
                                        ).accentColor.withAlpha(20)
                                      : null,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        antar.lord,
                                        style: TextStyle(
                                          fontWeight: isCurrentAntar
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${antar.periodYears.toStringAsFixed(2)}y',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${_formatDate(antar.startDate)} - ${_formatDate(antar.endDate)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYoginiDashaContent(YoginiDasha dasha) {
    final now = DateTime.now();
    final currentIndex = dasha.mahadashas.indexWhere(
      (m) => now.isAfter(m.startDate) && now.isBefore(m.endDate),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info Card
          Card(
            backgroundColor: FluentTheme.of(context).accentColor.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.info,
                    color: FluentTheme.of(context).accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting Yogini: ${dasha.startYogini}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Text(
                          'Total 8 Yogini periods (36 years cycle)',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Yogini Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yogini Dasha Periods',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 12),
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: FluentTheme.of(context).accentColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Yogini',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Lord',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Period',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Years',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Table Rows
                  ...dasha.mahadashas.asMap().entries.map((entry) {
                    final index = entry.key;
                    final maha = entry.value;
                    final isCurrent = index == currentIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? FluentTheme.of(context).accentColor.withAlpha(40)
                            : (index % 2 == 0
                                  ? Colors.grey.withAlpha(10)
                                  : null),
                        borderRadius: BorderRadius.circular(4),
                        border: isCurrent
                            ? Border.all(
                                color: FluentTheme.of(context).accentColor,
                                width: 1,
                              )
                            : null,
                      ),
                      child: Expander(
                        initiallyExpanded: isCurrent,
                        header: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  if (isCurrent)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: FluentTheme.of(
                                          context,
                                        ).accentColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  Text(
                                    maha.name,
                                    style: TextStyle(
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isCurrent
                                          ? FluentTheme.of(context).accentColor
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                maha.lord,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${_formatDate(maha.startDate)} - ${_formatDate(maha.endDate)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${maha.periodYears}y',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Antardashas (Sub-periods):',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ...maha.antardashas.map((antar) {
                              final isCurrentAntar =
                                  now.isAfter(antar.startDate) &&
                                  now.isBefore(antar.endDate);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: isCurrentAntar
                                      ? FluentTheme.of(
                                          context,
                                        ).accentColor.withAlpha(20)
                                      : null,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Expander(
                                  initiallyExpanded: isCurrentAntar,
                                  header: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          antar.name,
                                          style: TextStyle(
                                            fontWeight: isCurrentAntar
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '${_formatDate(antar.startDate)} - ${_formatDate(antar.endDate)}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          'Pratyantardashas (Sub-sub-periods):',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                      ...antar.pratyantardashas.map((pratyan) {
                                        final isCurrentPratyan =
                                            now.isAfter(pratyan.startDate) &&
                                            now.isBefore(pratyan.endDate);
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 2,
                                            horizontal: 4,
                                          ),
                                          color: isCurrentPratyan
                                              ? FluentTheme.of(
                                                  context,
                                                ).accentColor.withAlpha(10)
                                              : null,
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Text(
                                                  '  - ${pratyan.name}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: isCurrentPratyan
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: Text(
                                                  '${_formatDate(pratyan.startDate)} - ${_formatDate(pratyan.endDate)}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharaDashaContent(CharaDasha dasha) {
    final now = DateTime.now();
    final currentIndex = dasha.periods.indexWhere(
      (p) => now.isAfter(p.startDate) && now.isBefore(p.endDate),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Info Card
          Card(
            backgroundColor: FluentTheme.of(context).accentColor.withAlpha(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.info,
                    color: FluentTheme.of(context).accentColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting Sign: ${_getSignName(dasha.startSign)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Text(
                          'Jaimini Chara Dasha System',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Chara Dasha Table
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chara Dasha Periods',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 12),
                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: FluentTheme.of(context).accentColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Sign',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Lord',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Period',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Years',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Table Rows
                  ...dasha.periods.asMap().entries.map((entry) {
                    final index = entry.key;
                    final period = entry.value;
                    final isCurrent = index == currentIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? FluentTheme.of(context).accentColor.withAlpha(40)
                            : (index % 2 == 0
                                  ? Colors.grey.withAlpha(10)
                                  : null),
                        borderRadius: BorderRadius.circular(4),
                        border: isCurrent
                            ? Border.all(
                                color: FluentTheme.of(context).accentColor,
                                width: 1,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                if (isCurrent)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: FluentTheme.of(
                                        context,
                                      ).accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                Text(
                                  period.signName,
                                  style: TextStyle(
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCurrent
                                        ? FluentTheme.of(context).accentColor
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              period.lord,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${_formatDate(period.startDate)} - ${_formatDate(period.endDate)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${period.periodYears.toInt()}y',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSignName(int signNumber) {
    final signs = [
      'Aries',
      'Taurus',
      'Gemini',
      'Cancer',
      'Leo',
      'Virgo',
      'Libra',
      'Scorpio',
      'Sagittarius',
      'Capricorn',
      'Aquarius',
      'Pisces',
    ];
    return signs[signNumber % 12];
  }

  Widget _buildDetailsTab(CompleteChartData data) {
    final planets = data.baseChart.planets;
    final navamsa = data.divisionalCharts['D-9'];

    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Planetary Details",
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 16),
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(0.5),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: FluentTheme.of(
                                context,
                              ).resources.dividerStrokeColorDefault,
                            ),
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              "Planet",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: FluentTheme.of(context).accentColor,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              "Sign",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              "Long",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              "R",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const TableRow(
                        children: [
                          SizedBox(height: 8),
                          SizedBox(),
                          SizedBox(),
                          SizedBox(),
                        ],
                      ),
                      ...planets.entries.map((e) {
                        final planetName = e.key.toString().split('.').last;
                        final info = e.value;
                        final signName = _getSignName(
                          (info.longitude / 30).floor() + 1,
                        );
                        final normLongitude = info.longitude % 30;

                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                planetName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(signName),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(normLongitude.toStringAsFixed(2)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                info.isRetrograde ? "R" : "",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      // Add Rahu
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'Rahu',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              _getSignName(
                                (data.baseChart.rahu.longitude / 30).floor() +
                                    1,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              (data.baseChart.rahu.longitude % 30)
                                  .toStringAsFixed(2),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text(''),
                          ),
                        ],
                      ),
                      // Add Ketu
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              'Ketu',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              _getSignName(
                                (data.baseChart.ketu.longitude / 30).floor() +
                                    1,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              (data.baseChart.ketu.longitude % 30)
                                  .toStringAsFixed(2),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text(''),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (navamsa != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Navamsa (D-9) Summary",
                      style: FluentTheme.of(context).typography.subtitle,
                    ),
                    const SizedBox(height: 16),
                    // Display Navamsa positions
                    Table(
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: FluentTheme.of(
                                  context,
                                ).resources.dividerStrokeColorDefault,
                              ),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                "Planet",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: FluentTheme.of(context).accentColor,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Text(
                                "Sign",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const TableRow(
                          children: [SizedBox(height: 8), SizedBox()],
                        ),
                        ...navamsa.positions.entries.map((e) {
                          final planetName = e.key;
                          final longitude = e.value;
                          final signName = _getSignName(
                            (longitude / 30).floor() + 1,
                          );
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(
                                  planetName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(signName),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanetPositionsTable(CompleteChartData data) {
    final planets = data.baseChart.planets;
    final nakshatras = AppConstants.nakshatras;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Planet Positions',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(0.6),
                5: FlexColumnWidth(0.6),
                6: FlexColumnWidth(0.8),
              },
              children: [
                const TableRow(
                  children: [
                    Text(
                      'Planet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Sign', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'Degrees',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Nakshatra',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Pada', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      'House',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const TableRow(
                  children: [
                    SizedBox(height: 8),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                  ],
                ),
                // Divider Row
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: FluentTheme.of(
                          context,
                        ).resources.dividerStrokeColorDefault,
                      ),
                    ),
                  ),
                  children: List.filled(7, const SizedBox(height: 4)),
                ),
                const TableRow(
                  children: [
                    SizedBox(height: 8),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                    SizedBox(),
                  ],
                ),
                ...planets.entries.map((entry) {
                  final planetName = entry.key.toString().split('.').last;
                  final info = entry.value;
                  final longitude = info.longitude;

                  // Sign (1-12)
                  final signIndex = (longitude / 30).floor();
                  final signName = _getSignName(signIndex + 1);

                  // Degrees within sign
                  final degInSign = longitude % 30;
                  final degrees = degInSign.floor();
                  final minutes = ((degInSign - degrees) * 60).floor();
                  final seconds = (((degInSign - degrees) * 60 - minutes) * 60)
                      .round();
                  final degStr =
                      '${degrees.toString().padLeft(2, '0')}°${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';

                  // Nakshatra (each is 13°20' = 13.333...)
                  final nakshatraIndex = (longitude / 13.333333).floor() % 27;
                  final nakshatraName = nakshatras[nakshatraIndex];

                  // Pada (4 padas per nakshatra, each 3°20' = 3.333...)
                  final padaInNakshatra =
                      ((longitude % 13.333333) / 3.333333).floor() + 1;

                  // House (approximate based on sign difference from ascendant)
                  final ascSign = _getAscendantSignInt(data.baseChart);
                  final house = ((signIndex + 1) - ascSign + 12) % 12 + 1;

                  // Status
                  List<String> status = [];
                  if (info.isRetrograde) status.add('R');
                  // Add more status if available in the data

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(planetName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(signName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(degStr),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(nakshatraName),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('$padaInNakshatra'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('$house'),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          status.join(' '),
                          style: TextStyle(
                            color: status.contains('R') ? Colors.orange : null,
                            fontWeight: status.isNotEmpty
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                // Add Rahu
                _buildRahuKetuTableRow(
                  'Rahu',
                  data.baseChart.rahu.longitude,
                  data.baseChart,
                  nakshatras,
                ),
                // Add Ketu
                _buildRahuKetuTableRow(
                  'Ketu',
                  data.baseChart.ketu.longitude,
                  data.baseChart,
                  nakshatras,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<int, List<String>> _getPlanetsMap(VedicChart chart) {
    final map = <int, List<String>>{};
    chart.planets.forEach((planet, info) {
      final sign = (info.longitude / 30).floor() + 1; // 1-12
      final planetName = planet.toString().split('.').last;
      String abbr = AppConstants.getPlanetAbbreviation(planetName);

      map
          .putIfAbsent(sign, () => [])
          .add(abbr + (info.isRetrograde ? "(R)" : ""));
    });

    // Add Rahu
    {
      final rahuSign = (chart.rahu.longitude / 30).floor() + 1;
      map.putIfAbsent(rahuSign, () => []).add("Ra");
    }

    // Add Ketu
    {
      final ketuSign = (chart.ketu.longitude / 30).floor() + 1;
      map.putIfAbsent(ketuSign, () => []).add("Ke");
    }

    // Ascendant
    final ascSign = _getAscendantSignInt(chart);
    map.putIfAbsent(ascSign, () => []).add("Asc");
    return map;
  }

  Map<int, List<String>> _getDivisionalPlanetsMap(DivisionalChartData chart) {
    final map = <int, List<String>>{};
    chart.positions.forEach((planetName, longitude) {
      final sign = (longitude / 30).floor() + 1; // 1-12

      String abbr = planetName.length > 2
          ? planetName.substring(0, 2)
          : planetName;
      if (planetName == 'Mars') abbr = 'Ma';
      if (planetName == 'Mercury') abbr = 'Me';
      if (planetName == 'Jupiter') abbr = 'Ju';
      if (planetName == 'Venus') abbr = 'Ve';
      if (planetName == 'Saturn') abbr = 'Sa';
      if (planetName == 'Rahu') abbr = 'Ra';
      if (planetName == 'Ketu') abbr = 'Ke';
      if (planetName == 'Sun') abbr = 'Su';
      if (planetName == 'Moon') abbr = 'Mo';

      map.putIfAbsent(sign, () => []).add(abbr);
    });
    // Ascendant
    if (chart.ascendantSign != null) {
      // ascendantSign is likely 1-12 usually.
      map.putIfAbsent(chart.ascendantSign!, () => []).add("Asc");
    }
    return map;
  }

  int _getAscendantSignInt(VedicChart chart) {
    final index = AstrologyConstants.signNames.indexOf(chart.ascendantSign);
    if (index != -1) {
      return index + 1;
    }
    return 1; // Default Aries
  }

  String _getAscendantSign(VedicChart chart) {
    return chart.ascendantSign;
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  TableRow _buildRahuKetuTableRow(
    String name,
    double longitude,
    VedicChart chart,
    List<String> nakshatras,
  ) {
    // Sign (1-12)
    final signIndex = (longitude / 30).floor();
    final signName = _getSignName(signIndex + 1);

    // Degrees within sign
    final degInSign = longitude % 30;
    final degrees = degInSign.floor();
    final minutes = ((degInSign - degrees) * 60).floor();
    final seconds = (((degInSign - degrees) * 60 - minutes) * 60).round();
    final degStr =
        '${degrees.toString().padLeft(2, '0')}°${minutes.toString().padLeft(2, '0')}\'${seconds.toString().padLeft(2, '0')}"';

    // Nakshatra (each is 13°20' = 13.333...)
    final nakshatraIndex = (longitude / 13.333333).floor() % 27;
    final nakshatraName = nakshatras[nakshatraIndex];

    // Pada (4 padas per nakshatra, each 3°20' = 3.333...)
    final padaInNakshatra = ((longitude % 13.333333) / 3.333333).floor() + 1;

    // House (approximate based on sign difference from ascendant)
    final ascSign = _getAscendantSignInt(chart);
    final house = ((signIndex + 1) - ascSign + 12) % 12 + 1;

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(name),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(signName),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(degStr),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(nakshatraName),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('$padaInNakshatra'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text('$house'),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Text(''), // Rahu/Ketu are never retrograde
        ),
      ],
    );
  }

  IconData _getCurrentTabIcon(int index) {
    switch (index) {
      case 0:
        return FluentIcons.contact_card;
      case 1:
        return FluentIcons.grid_view_large;
      case 2:
        return FluentIcons.scatter_chart;
      case 3:
        return FluentIcons.timer;
      case 4:
        return FluentIcons.list;
      case 5:
        return FluentIcons.lightbulb;
      default:
        return FluentIcons.chart;
    }
  }

  String _getCurrentTabTitle(int index) {
    switch (index) {
      case 0:
        return "D-1 Rashi";
      case 1:
        return "Vargas";
      case 2:
        return "KP System";
      case 3:
        return "Dasha Periods";
      case 4:
        return "Planet Details";
      case 5:
        return "Daily Rashiphal";
      default:
        return "Chart Views";
    }
  }
}
