import 'package:fluent_ui/fluent_ui.dart';

import '../../data/models.dart';
import '../../data/city_database.dart';
import '../../core/database_helper.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _citySearchController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime _selectedTime = DateTime.now();
  City? _selectedCity;
  List<AutoSuggestBoxItem<City>> _cityItems = [];
  bool _isLoadingLocation = false;
  bool _useManualCoordinates = false;

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

        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Location Found'),
              content: Text(city.displayName),
              severity: InfoBarSeverity.success,
              onClose: close,
            );
          },
        );
      } else if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Location Error'),
              content: const Text(
                'Could not detect location. Please search manually.',
              ),
              severity: InfoBarSeverity.warning,
              onClose: close,
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Permission Error'),
              content: const Text('Location permission denied or unavailable'),
              severity: InfoBarSeverity.error,
              onClose: close,
            );
          },
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

  Future<void> _generateChart() async {
    if (_formKey.currentState!.validate()) {
      if (!_useManualCoordinates && _selectedCity == null) {
        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Missing Information'),
              content: const Text(
                'Please select a birth place or enter coordinates manually',
              ),
              severity: InfoBarSeverity.warning,
              onClose: close,
            );
          },
        );
        return;
      }

      if (_useManualCoordinates) {
        final lat = double.tryParse(_latitudeController.text);
        final long = double.tryParse(_longitudeController.text);

        if (lat == null ||
            long == null ||
            lat < -90 ||
            lat > 90 ||
            long < -180 ||
            long > 180) {
          displayInfoBar(
            context,
            builder: (context, close) {
              return InfoBar(
                title: const Text('Invalid Coordinates'),
                content: const Text(
                  'Please enter valid latitude (-90 to 90) and longitude (-180 to 180)',
                ),
                severity: InfoBarSeverity.warning,
                onClose: close,
              );
            },
          );
          return;
        }
      }

      // Validate Date (Future checks)
      final now = DateTime.now();
      if (_selectedDate.isAfter(now)) {
        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Invalid Date'),
              content: const Text('Birth date cannot be in the future.'),
              severity: InfoBarSeverity.warning,
              onClose: close,
            );
          },
        );
        return;
      }

      final dt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final double lat;
      final double long;
      final String locationName;
      final String timezone;

      if (_useManualCoordinates) {
        lat = double.parse(_latitudeController.text);
        long = double.parse(_longitudeController.text);
        locationName =
            'Lat: ${lat.toStringAsFixed(4)}, Long: ${long.toStringAsFixed(4)}';
        timezone = DateTime.now().timeZoneName;
      } else {
        lat = _selectedCity!.latitude;
        long = _selectedCity!.longitude;
        locationName = _selectedCity!.displayName;
        timezone = _selectedCity!.timezone;
      }

      // Save to Database
      final name = _nameController.text;
      final dbHelper = DatabaseHelper();

      await dbHelper.insertChart({
        'name': name,
        'dateTime': dt.toIso8601String(),
        'latitude': lat,
        'longitude': long,
        'locationName': locationName,
        'timezone': timezone,
      });

      final birthData = BirthData(
        dateTime: dt,
        location: Location(latitude: lat, longitude: long),
        name: name,
        place: locationName,
        timezone: timezone,
      );

      if (!mounted) return;

      // Navigate to Chart Screen
      Navigator.pushNamed(context, '/chart', arguments: birthData);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _citySearchController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text("New Chart")),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step 1: Personal Details
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(FluentIcons.personalize, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Personal Details",
                            style: FluentTheme.of(context).typography.subtitle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      InfoLabel(
                        label: "Full Name",
                        child: TextFormBox(
                          controller: _nameController,
                          placeholder: "Enter Name",
                          prefix: const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(FluentIcons.contact),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? "Required"
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Step 2: Birth Time & Date
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(FluentIcons.calendar, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Birth Date & Time",
                            style: FluentTheme.of(context).typography.subtitle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: InfoLabel(
                              label: "Date",
                              child: DatePicker(
                                selected: _selectedDate,
                                onChanged: (v) =>
                                    setState(() => _selectedDate = v),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InfoLabel(
                              label: "Time",
                              child: TimePicker(
                                selected: _selectedTime,
                                onChanged: (v) =>
                                    setState(() => _selectedTime = v),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Step 3: Location
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(FluentIcons.location, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Birth Place",
                            style: FluentTheme.of(context).typography.subtitle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Toggle for manual coordinates
                      Checkbox(
                        checked: _useManualCoordinates,
                        onChanged: (value) {
                          setState(() {
                            _useManualCoordinates = value ?? false;
                            if (!_useManualCoordinates) {
                              _latitudeController.clear();
                              _longitudeController.clear();
                            }
                          });
                        },
                        content: const Text('Enter coordinates manually'),
                      ),
                      const SizedBox(height: 16),
                      if (_useManualCoordinates)
                        Row(
                          children: [
                            Expanded(
                              child: InfoLabel(
                                label: "Latitude (-90 to 90)",
                                child: TextFormBox(
                                  controller: _latitudeController,
                                  placeholder: "e.g., 28.6139",
                                  prefix: const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(FluentIcons.globe),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                  validator: (value) {
                                    if (!_useManualCoordinates) return null;
                                    if (value == null || value.isEmpty)
                                      return "Required";
                                    final lat = double.tryParse(value);
                                    if (lat == null) return "Invalid number";
                                    if (lat < -90 || lat > 90)
                                      return "Must be -90 to 90";
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InfoLabel(
                                label: "Longitude (-180 to 180)",
                                child: TextFormBox(
                                  controller: _longitudeController,
                                  placeholder: "e.g., 77.2090",
                                  prefix: const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(FluentIcons.globe),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                  validator: (value) {
                                    if (!_useManualCoordinates) return null;
                                    if (value == null || value.isEmpty)
                                      return "Required";
                                    final long = double.tryParse(value);
                                    if (long == null) return "Invalid number";
                                    if (long < -180 || long > 180)
                                      return "Must be -180 to 180";
                                    return null;
                                  },
                                ),
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
                                onChanged: (text, reason) {
                                  _onCitySearch(text);
                                },
                                onSelected: (item) {
                                  setState(() {
                                    _selectedCity = item.value;
                                  });
                                },
                                placeholder: "Search city...",
                                leadingIcon: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(FluentIcons.city_next),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _isLoadingLocation
                                  ? null
                                  : _useCurrentLocation,
                              child: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: ProgressRing(strokeWidth: 2),
                                    )
                                  : const Icon(FluentIcons.location),
                            ),
                          ],
                        ),
                      if (!_useManualCoordinates && _selectedCity != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: InfoBar(
                            title: Text(_selectedCity!.displayName),
                            content: Text(
                              '${_selectedCity!.latitude.toStringAsFixed(4)}°N, ${_selectedCity!.longitude.toStringAsFixed(4)}°E',
                            ),
                            severity: InfoBarSeverity.info,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Action
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _generateChart,
                    child: const Text(
                      "Generate Chart",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
