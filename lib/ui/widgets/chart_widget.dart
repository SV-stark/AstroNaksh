import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/chart_customization.dart';
import '../../core/settings_provider.dart';
import '../../logic/planetary_aspect_service.dart';
import '../painters/aspect_painter.dart';
import '../painters/north_indian_chart_painter.dart';
import '../painters/south_indian_chart_painter.dart';

import 'dart:ui';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jyotish/jyotish.dart' as j;

import '../../core/chart_customization.dart';
import '../../core/constants.dart';
import '../../core/settings_provider.dart';
import '../../data/models.dart';
import '../../logic/planetary_aspect_service.dart';
import '../painters/aspect_painter.dart';
import '../painters/north_indian_chart_painter.dart';
import '../painters/south_indian_chart_painter.dart';

class ChartWidget extends ConsumerStatefulWidget {
  const ChartWidget({
    super.key,
    required this.planetsBySign,
    required this.ascendantSign,
    required this.style,
    this.size = 300,
    this.aspects,
    this.showAspects = false,
    this.onHouseTapped,
    this.completeData,
    this.baseChart,
    this.divisionalChart,
  });

  final Map<int, List<String>> planetsBySign; // Key: 1-12
  final int ascendantSign; // 1-12
  final ChartStyle style;
  final double size;
  final List<PlanetaryAspect>? aspects;
  final bool showAspects;
  final void Function(int houseIndex)? onHouseTapped;
  final CompleteChartData? completeData;
  final j.VedicChart? baseChart;
  final DivisionalChartData? divisionalChart;

  @override
  ConsumerState<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends ConsumerState<ChartWidget> {
  int? _hoveredHouseIndex; // 0-11
  int? _selectedHouseIndex; // 0-11

  int? _getHouseFromOffset(Offset offset, Size size) {
    if (widget.style == ChartStyle.northIndian) {
      final width = size.width;
      final height = size.height;
      final centers = [
        Offset(width / 2, height / 4), // 1st
        Offset(width / 4, height / 8), // 2nd
        Offset(width / 8, height / 4), // 3rd
        Offset(width / 4, height / 2), // 4th
        Offset(width / 8, height * 0.75), // 5th
        Offset(width / 4, height * 0.875), // 6th
        Offset(width / 2, height * 0.75), // 7th
        Offset(width * 0.75, height * 0.875), // 8th
        Offset(width * 0.875, height * 0.75), // 9th
        Offset(width * 0.75, height / 2), // 10th
        Offset(width * 0.875, height / 4), // 11th
        Offset(width * 0.75, height / 8), // 12th
      ];
      int closestIndex = 0;
      double minDistance = double.infinity;
      for (int i = 0; i < 12; i++) {
        final dist = (offset - centers[i]).distance;
        if (dist < minDistance) {
          minDistance = dist;
          closestIndex = i;
        }
      }
      return closestIndex + 1;
    } else {
      final width = size.width;
      final height = size.height;
      final cellWidth = width / 4;
      final cellHeight = height / 4;

      final col = (offset.dx / cellWidth).floor().clamp(0, 3);
      final row = (offset.dy / cellHeight).floor().clamp(0, 3);

      int? signIndex;
      if (row == 0) {
        if (col == 1) signIndex = 0; // Aries
        else if (col == 2) signIndex = 1; // Taurus
        else if (col == 3) signIndex = 2; // Gemini
        else if (col == 0) signIndex = 11; // Pisces
      } else if (row == 1) {
        if (col == 3) signIndex = 3; // Cancer
        else if (col == 0) signIndex = 10; // Aquarius
      } else if (row == 2) {
        if (col == 3) signIndex = 4; // Leo
        else if (col == 0) signIndex = 9; // Capricorn
      } else if (row == 3) {
        if (col == 3) signIndex = 5; // Virgo
        else if (col == 2) signIndex = 6; // Libra
        else if (col == 1) signIndex = 7; // Scorpio
        else if (col == 0) signIndex = 8; // Sagittarius
      }

      if (signIndex == null) return null;

      // Map sign index back to house index based on ascendantSign (1-12)
      return (signIndex - widget.ascendantSign + 1 + 12) % 12 + 1;
    }
  }

  String _getSignLordName(int signIndex) {
    try {
      return AstrologyConstants.getSignLord(signIndex).displayName;
    } catch (e) {
      const lords = [
        'Mars',
        'Venus',
        'Mercury',
        'Moon',
        'Sun',
        'Mercury',
        'Venus',
        'Mars',
        'Jupiter',
        'Saturn',
        'Saturn',
        'Jupiter'
      ];
      return lords[signIndex % 12];
    }
  }

  List<Map<String, dynamic>> _getPlanetsInHouse(int houseIndex) {
    final list = <Map<String, dynamic>>[];
    final signIndex = ((widget.ascendantSign - 1) + houseIndex) % 12;
    final signNumber = signIndex + 1;
    final nakshatraLords = [
      'Ketu',
      'Venus',
      'Sun',
      'Moon',
      'Mars',
      'Rahu',
      'Jupiter',
      'Saturn',
      'Mercury'
    ];

    final chart = widget.baseChart ?? widget.completeData?.baseChart;
    if (chart != null) {
      chart.planets.forEach((planet, info) {
        final pSign = (info.longitude / 30).floor() + 1;
        if (pSign == signNumber) {
          final deg = info.longitude % 30;
          final nakIdx = (info.longitude / 13.333333).floor() % 27;
          final nakName = AppConstants.nakshatras[nakIdx];
          final nakLordName = nakshatraLords[nakIdx % 9];
          list.add({
            'name': planet.displayName,
            'degree': deg,
            'nakshatra': nakName,
            'nakLord': nakLordName,
            'retrograde': info.isRetrograde,
          });
        }
      });

      final rahuSign = (chart.rahu.longitude / 30).floor() + 1;
      if (rahuSign == signNumber) {
        final deg = chart.rahu.longitude % 30;
        final nakIdx = (chart.rahu.longitude / 13.333333).floor() % 27;
        final nakName = AppConstants.nakshatras[nakIdx];
        final nakLordName = nakshatraLords[nakIdx % 9];
        list.add({
          'name': 'Rahu',
          'degree': deg,
          'nakshatra': nakName,
          'nakLord': nakLordName,
          'retrograde': false,
        });
      }

      final ketuSign = (chart.ketu.longitude / 30).floor() + 1;
      if (ketuSign == signNumber) {
        final deg = chart.ketu.longitude % 30;
        final nakIdx = (chart.ketu.longitude / 13.333333).floor() % 27;
        final nakName = AppConstants.nakshatras[nakIdx];
        final nakLordName = nakshatraLords[nakIdx % 9];
        list.add({
          'name': 'Ketu',
          'degree': deg,
          'nakshatra': nakName,
          'nakLord': nakLordName,
          'retrograde': true,
        });
      }
    } else if (widget.divisionalChart != null) {
      widget.divisionalChart!.positions.forEach((planetName, longitude) {
        final pSign = (longitude / 30).floor() + 1;
        if (pSign == signNumber) {
          final deg = longitude % 30;
          final nakIdx = (longitude / 13.333333).floor() % 27;
          final nakName = AppConstants.nakshatras[nakIdx];
          final nakLordName = nakshatraLords[nakIdx % 9];
          list.add({
            'name': planetName.substring(0, 1).toUpperCase() +
                planetName.substring(1),
            'degree': deg,
            'nakshatra': nakName,
            'nakLord': nakLordName,
            'retrograde': false,
          });
        }
      });
    } else {
      final planetNames = widget.planetsBySign[signNumber] ?? [];
      for (final name in planetNames) {
        if (name == 'Asc') continue;
        final isRetro = name.contains('(R)');
        final clean = name.replaceAll('(R)', '').trim();
        list.add({
          'name': clean,
          'degree': null,
          'nakshatra': null,
          'nakLord': null,
          'retrograde': isRetro,
        });
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.maybeWhen(
      data: (settings) {
        final chartSettings = settings.chartSettings;
        final colors = chartSettings.colorScheme.colors;

        final activeHouseIndex = _hoveredHouseIndex ?? _selectedHouseIndex;
        Widget? tooltipCard;

        if (activeHouseIndex != null) {
          final signIndex = ((widget.ascendantSign - 1) + activeHouseIndex) % 12;
          final signName = AppConstants.signs[signIndex];
          final lordName = _getSignLordName(signIndex);
          final planetsInHouse = _getPlanetsInHouse(activeHouseIndex);

          tooltipCard = Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.background.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.houseBorder.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'House ${activeHouseIndex + 1} - $signName',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.planetText,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Lord: $lordName',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.planetText.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (planetsInHouse.isEmpty)
                        Text(
                          'No occupying planets',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.planetText.withOpacity(0.6),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: planetsInHouse.map((p) {
                            final name = p['name'];
                            final deg = p['degree'];
                            final nak = p['nakshatra'];
                            final nakL = p['nakLord'];
                            final isRetro = p['retrograde'] == true;
                            final retroStr = isRetro ? ' (R)' : '';
                            final degStr =
                                deg != null ? ' ${deg.toStringAsFixed(1)}°' : '';
                            final detailsStr = nak != null ? ' ($nak - $nakL)' : '';
                            return Text(
                              '• $name$retroStr:$degStr$detailsStr',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.planetText,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: MouseRegion(
            onHover: (event) {
              final house = _getHouseFromOffset(
                event.localPosition,
                Size(widget.size, widget.size),
              );
              if (house != null && (house - 1) != _hoveredHouseIndex) {
                setState(() {
                  _hoveredHouseIndex = house - 1;
                });
              }
            },
            onExit: (event) {
              setState(() {
                _hoveredHouseIndex = null;
              });
            },
            child: GestureDetector(
              onTapUp: (details) {
                final house = _getHouseFromOffset(
                  details.localPosition,
                  Size(widget.size, widget.size),
                );
                if (house != null) {
                  setState(() {
                    _selectedHouseIndex = house - 1;
                  });
                  if (widget.onHouseTapped != null) {
                    widget.onHouseTapped!(house);
                  }
                }
              },
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: widget.style == ChartStyle.northIndian
                        ? NorthIndianChartPainter(
                            planetsBySign: widget.planetsBySign,
                            ascendantSign: widget.ascendantSign,
                            colors: colors,
                            hoveredHouse: _hoveredHouseIndex,
                            selectedHouse: _selectedHouseIndex,
                          )
                        : SouthIndianChartPainter(
                            planetsBySign: widget.planetsBySign,
                            ascendantSign: widget.ascendantSign,
                            colors: colors,
                            hoveredHouse: _hoveredHouseIndex,
                            selectedHouse: _selectedHouseIndex,
                          ),
                  ),
                  if (widget.showAspects &&
                      widget.aspects != null &&
                      widget.aspects!.isNotEmpty)
                    CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: AspectPainter(
                        aspects: widget.aspects!,
                        planetsBySign: widget.planetsBySign,
                        ascendantSign: widget.ascendantSign,
                        colors: colors,
                        lineOpacity: 0.4,
                        activeHouse: _hoveredHouseIndex ?? _selectedHouseIndex,
                      ),
                    ),
                  if (tooltipCard != null) tooltipCard,
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => Container(
        width: widget.size,
        height: widget.size,
        color: Colors.grey.withOpacity(0.1),
        child: const Center(child: ProgressRing()),
      ),
    );
  }
}
