import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';

import '../../data/city_database.dart';
import 'horary_result_screen.dart';
import '../../core/responsive_helper.dart';

class HoraryInputScreen extends StatefulWidget {
  const HoraryInputScreen({super.key});

  @override
  State<HoraryInputScreen> createState() => _HoraryInputScreenState();
}

class _HoraryInputScreenState extends State<HoraryInputScreen> {
  // Form State
  int _seedNumber = 0;
  DateTime _selectedDate = DateTime.now();

  // Location State
  City? _selectedCity;
  List<AutoSuggestBoxItem<City>> _cityItems = [];
  bool _isLoadingLocation = false;
  bool _useManualCoordinates = false;

  // Controllers
  final TextEditingController _seedController = TextEditingController();
  final TextEditingController _citySearchController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Optional: Try to get current location on load or let user choose
    // _useCurrentLocation();
  }

  @override
  void dispose() {
    _seedController.dispose();
    _citySearchController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _onCitySearch(String text) {
    if (text.length < 2) {
      if (_cityItems.isNotEmpty) setState(() => _cityItems = []);
      return;
    }

    final results = CityDatabase.searchCities(text).take(10);
    setState(() {
      _cityItems = results.map((city) {
        return AutoSuggestBoxItem<City>(
          value: city,
          label: '${city.name}, ${city.country}',
          onSelected: () {
            setState(() {
              _selectedCity = city;
            });
          },
        );
      }).toList();
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final city = await CityDatabase.getCurrentLocation();
      if (city != null && mounted) {
        setState(() {
          _selectedCity = city;
          _citySearchController.text = city.displayName;
        });
        _showInfo('Location Found', city.displayName);
      } else if (mounted) {
        _showInfo(
          'Location Error',
          'Could not detect location.',
          severity: InfoBarSeverity.warning,
        );
      }
    } catch (e) {
      if (mounted) {
        _showInfo(
          'Permission Error',
          'Location permission denied.',
          severity: InfoBarSeverity.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _showInfo(
    String title,
    String content, {
    InfoBarSeverity severity = InfoBarSeverity.info,
  }) {
    displayInfoBar(
      context,
      builder: (context, close) {
        return InfoBar(
          title: Text(title),
          content: Text(content),
          severity: severity,
          onClose: close,
        );
      },
    );
  }

  void _onGenerate() {
    // Validate Seed
    final seed = int.tryParse(_seedController.text);
    if (seed == null || seed < 1 || seed > 249) {
      _showInfo(
        'Invalid Number',
        'Please enter a number between 1 and 249.',
        severity: InfoBarSeverity.warning,
      );
      return;
    }

    // Validate Location
    if (!_useManualCoordinates && _selectedCity == null) {
      _showInfo(
        'Missing Location',
        'Please select a city or enter coordinates.',
        severity: InfoBarSeverity.warning,
      );
      return;
    }

    double lat, long;
    String locName;

    if (_useManualCoordinates) {
      lat = double.tryParse(_latitudeController.text) ?? 0;
      long = double.tryParse(_longitudeController.text) ?? 0;

      if (lat < -90 || lat > 90 || long < -180 || long > 180) {
        _showInfo(
          'Invalid Coordinates',
          'Lat: -90 to 90, Long: -180 to 180.',
          severity: InfoBarSeverity.warning,
        );
        return;
      }
      locName = "Custom: ${lat.toStringAsFixed(2)}, ${long.toStringAsFixed(2)}";
    } else {
      lat = _selectedCity!.latitude;
      long = _selectedCity!.longitude;
      locName = _selectedCity!.displayName;
    }

    Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => HoraryResultScreen(
          seedNumber: seed,
          dateTime: _selectedDate,
          location: GeographicLocation(
            latitude: lat,
            longitude: long,
            altitude: 0,
          ),
          locationName: locName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Horary (Prashna) ASTRO'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: Padding(
        padding: context.responsiveBodyPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Compact layout
          children: [
            const Text('Enter a number between 1 and 249 to generate a chart.'),
            const SizedBox(height: 20),

            // Seed Input
            InfoLabel(
              label: 'Horary Number (1-249)',
              child: NumberBox<int>(
                value: _seedNumber == 0 ? null : _seedNumber,
                min: 1,
                max: 249,
                onChanged: (v) => setState(() {
                  _seedNumber = v ?? 0;
                  _seedController.text = (v ?? '').toString();
                }),
                mode: SpinButtonPlacementMode.inline,
              ),
            ),
            const SizedBox(height: 20),

            // Date Time Input
            InfoLabel(
              label: 'Date & Time of Judgment',
              child: DatePicker(
                selected: _selectedDate,
                onChanged: (v) => setState(() => _selectedDate = v),
              ),
            ),
            const SizedBox(height: 10),
            InfoLabel(
              label: '',
              child: TimePicker(
                selected: _selectedDate,
                onChanged: (v) => setState(() => _selectedDate = v),
              ),
            ),
            const SizedBox(height: 20),

            // Location Input
            InfoLabel(
              label: 'Location',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    checked: _useManualCoordinates,
                    onChanged: (v) {
                      setState(() {
                        _useManualCoordinates = v ?? false;
                        if (!_useManualCoordinates) {
                          _latitudeController.clear();
                          _longitudeController.clear();
                        }
                      });
                    },
                    content: const Text('Enter coordinates manually'),
                  ),
                  const SizedBox(height: 10),
                  if (_useManualCoordinates)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormBox(
                            controller: _latitudeController,
                            placeholder: 'Lat (-90 to 90)',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormBox(
                            controller: _longitudeController,
                            placeholder: 'Long (-180 to 180)',
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: AutoSuggestBox<City>(
                            controller: _citySearchController,
                            items: _cityItems,
                            onChanged: (text, reason) => _onCitySearch(text),
                            onSelected: (item) {
                              setState(() => _selectedCity = item.value);
                            },
                            placeholder: 'Search City...',
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: _isLoadingLocation
                              ? const ProgressRing(strokeWidth: 2.5)
                              : const Icon(FluentIcons.location),
                          onPressed: _isLoadingLocation
                              ? null
                              : _useCurrentLocation,
                        ),
                      ],
                    ),
                  if (!_useManualCoordinates && _selectedCity != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Selected: ${_selectedCity!.displayName}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            FilledButton(
              onPressed: _onGenerate,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text('Generate Horary Chart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
