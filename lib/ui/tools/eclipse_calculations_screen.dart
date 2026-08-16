import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';

import '../../core/ephemeris_manager.dart';
import '../../core/utils/formatters.dart';
import '../../data/city_database.dart';
import '../../ui/widgets/city_search_field.dart';
import '../styles.dart';

class EclipseCalculationsScreen extends StatefulWidget {
  const EclipseCalculationsScreen({super.key});

  @override
  State<EclipseCalculationsScreen> createState() =>
      _EclipseCalculationsScreenState();
}

class _EclipseCalculationsScreenState extends State<EclipseCalculationsScreen> {
  int _selectedYear = DateTime.now().year;
  EclipseType _selectedType = EclipseType.any;
  bool _isLocal = false;
  City? _selectedCity;
  List<EclipseData> _eclipses = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Default city: New Delhi
    _selectedCity = const City(
      name: 'New Delhi',
      state: 'Delhi',
      country: 'India',
      latitude: 28.6139,
      longitude: 77.2090,
      timezone: 'Asia/Kolkata',
    );
    _calculateEclipses();
  }

  Future<void> _calculateEclipses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await EphemerisManager.ensureEphemerisData();

      GeographicLocation? location;
      if (_isLocal && _selectedCity != null) {
        location = GeographicLocation(
          latitude: _selectedCity!.latitude,
          longitude: _selectedCity!.longitude,
          altitude: 0,
        );
      }

      // Calculate eclipses for the selected year
      final yearEclipses = await EphemerisManager.jyotish.eclipse
          .predictEclipsesInYear(year: _selectedYear, location: location);

      // Filter by type if not "any"
      var filtered = yearEclipses;
      if (_selectedType != EclipseType.any) {
        if (_selectedType == EclipseType.solar) {
          filtered = yearEclipses
              .where(
                (e) =>
                    e.eclipseType == EclipseType.solarTotal ||
                    e.eclipseType == EclipseType.solarPartial ||
                    e.eclipseType == EclipseType.solarAnnular,
              )
              .toList();
        } else if (_selectedType == EclipseType.lunar) {
          filtered = yearEclipses
              .where(
                (e) =>
                    e.eclipseType == EclipseType.lunarTotal ||
                    e.eclipseType == EclipseType.lunarPartial ||
                    e.eclipseType == EclipseType.lunarPenumbral,
              )
              .toList();
        } else {
          filtered = yearEclipses
              .where((e) => e.eclipseType == _selectedType)
              .toList();
        }
      }

      setState(() {
        _eclipses = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getEclipseColor(EclipseType type) {
    if (type.name.contains('Solar')) {
      return const Color(0xFFD4AF37); // Cosmic Gold
    } else {
      return const Color(0xFF4B0082); // Deep Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Eclipse Calculations'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Controls Panel
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search Parameters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Year Selection
                      SizedBox(
                        width: 140,
                        child: InfoLabel(
                          label: 'Year',
                          child: NumberBox<int>(
                            value: _selectedYear,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedYear = val);
                                _calculateEclipses();
                              }
                            },
                            mode: SpinButtonPlacementMode.inline,
                          ),
                        ),
                      ),
                      // Type selection
                      SizedBox(
                        width: 180,
                        child: InfoLabel(
                          label: 'Eclipse Type',
                          child: ComboBox<EclipseType>(
                            value: _selectedType,
                            onChanged: (type) {
                              if (type != null) {
                                setState(() => _selectedType = type);
                                _calculateEclipses();
                              }
                            },
                            items: const [
                              ComboBoxItem(
                                value: EclipseType.any,
                                child: Text('Any Eclipse'),
                              ),
                              ComboBoxItem(
                                value: EclipseType.solar,
                                child: Text('All Solar'),
                              ),
                              ComboBoxItem(
                                value: EclipseType.lunar,
                                child: Text('All Lunar'),
                              ),
                              ComboBoxItem(
                                value: EclipseType.solarTotal,
                                child: Text('Solar Total'),
                              ),
                              ComboBoxItem(
                                value: EclipseType.solarPartial,
                                child: Text('Solar Partial'),
                              ),
                              ComboBoxItem(
                                value: EclipseType.solarAnnular,
                                child: Text('Solar Annular'),
                              ),
                              ComboBoxItem(
                                value: EclipseType.lunarTotal,
                                child: Text('Lunar Total'),
                              ),
                              ComboBoxItem(
                                value: EclipseType.lunarPartial,
                                child: Text('Lunar Partial'),
                              ),
                              ComboBoxItem(
                                value: EclipseType.lunarPenumbral,
                                child: Text('Lunar Penumbral'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Local visibility toggle
                      Padding(
                        padding: const EdgeInsets.only(top: 18.0),
                        child: ToggleSwitch(
                          checked: _isLocal,
                          onChanged: (val) {
                            setState(() => _isLocal = val);
                            _calculateEclipses();
                          },
                          content: const Text('Show Local Visibility Only'),
                        ),
                      ),
                    ],
                  ),
                  if (_isLocal) ...[
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: InfoLabel(
                        label: 'Location',
                        child: CitySearchField(
                          initialCity: _selectedCity,
                          onCitySelected: (city) {
                            setState(() => _selectedCity = city);
                            _calculateEclipses();
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Results Panel
            Expanded(
              child: _isLoading
                  ? const Center(child: ProgressRing())
                  : _errorMessage != null
                  ? Center(
                      child: InfoBar(
                        title: const Text('Calculation Error'),
                        content: Text(_errorMessage!),
                        severity: InfoBarSeverity.error,
                      ),
                    )
                  : _eclipses.isEmpty
                  ? const Center(
                      child: Text(
                        'No eclipses found matching the criteria.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _eclipses.length,
                      itemBuilder: (context, index) {
                        final eclipse = _eclipses[index];
                        final localTime = eclipse.date.toLocal();
                        final color = _getEclipseColor(eclipse.eclipseType);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Card(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Eclipse Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        eclipse.eclipseType.name.contains(
                                              'Solar',
                                            )
                                            ? FluentIcons.brightness
                                            : FluentIcons.contrast,
                                        color: color,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        eclipse.eclipseType.name
                                            .replaceAll('Solar ', '')
                                            .replaceAll('Lunar ', ''),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            eclipse.description,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          if (eclipse.magnitude > 0)
                                            Text(
                                              'Magnitude: ${eclipse.magnitude.toStringAsFixed(3)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppStyles.primaryColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Maximum Eclipse: ${AppFormatters.formatDateTime(localTime)} (${localTime.timeZoneName})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (eclipse.startTime != null &&
                                          eclipse.endTime != null)
                                        Text(
                                          'Duration: ${eclipse.startTime!.toLocal().hour.toString().padLeft(2, '0')}:${eclipse.startTime!.toLocal().minute.toString().padLeft(2, '0')} to ${eclipse.endTime!.toLocal().hour.toString().padLeft(2, '0')}:${eclipse.endTime!.toLocal().minute.toString().padLeft(2, '0')} (${eclipse.duration != null ? '${eclipse.duration!.inMinutes} mins' : ''})',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      const SizedBox(height: 6),
                                      if (eclipse.penumbralMagnitude != null)
                                        Text(
                                          'Penumbral Magnitude: ${eclipse.penumbralMagnitude!.toStringAsFixed(3)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
