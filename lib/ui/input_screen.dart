import 'package:flutter/material.dart';
import 'styles.dart';
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
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _citySearchController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  City? _selectedCity;
  List<City> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = false;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = picked.format(context);
      });
    }
  }

  void _onCitySearch(String query) {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = CityDatabase.searchCities(query).take(10).toList();
    });
  }

  void _selectCity(City city) {
    setState(() {
      _selectedCity = city;
      _citySearchController.text = city.displayName;
      _searchResults = [];
      _isSearching = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final city = await CityDatabase.getCurrentLocation();
      if (city != null && mounted) {
        _selectCity(city);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found: ${city.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not detect location. Please search manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied or unavailable'),
            backgroundColor: Colors.red,
          ),
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

  void _generateChart() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Date and Time')),
        );
        return;
      }

      if (_selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a birth place')),
        );
        return;
      }

      final dt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final lat = _selectedCity!.latitude;
      final long = _selectedCity!.longitude;

      // Save to Database
      final name = _nameController.text;
      final dbHelper = DatabaseHelper();

      dbHelper.insertChart({
        'name': name,
        'dateTime': dt.toIso8601String(),
        'latitude': lat,
        'longitude': long,
        'locationName': _selectedCity!.displayName,
      });

      final birthData = BirthData(
        dateTime: dt,
        location: Location(latitude: lat, longitude: long),
        name: name,
      );

      // Navigate to Chart Screen
      Navigator.pushNamed(context, '/chart', arguments: birthData);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _citySearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Chart")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Enter Birth Details",
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  prefixIcon: Icon(Icons.person, color: AppStyles.accentColor),
                ),
                validator: (value) => value!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: "Date of Birth",
                  prefixIcon: Icon(
                    Icons.calendar_today,
                    color: AppStyles.accentColor,
                  ),
                ),
                readOnly: true,
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                decoration: const InputDecoration(
                  labelText: "Time of Birth",
                  prefixIcon: Icon(
                    Icons.access_time,
                    color: AppStyles.accentColor,
                  ),
                ),
                readOnly: true,
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),

              // City Search Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _citySearchController,
                          decoration: InputDecoration(
                            labelText: "Birth Place",
                            hintText: "Search city...",
                            prefixIcon: const Icon(
                              Icons.location_city,
                              color: AppStyles.accentColor,
                            ),
                            suffixIcon: _selectedCity != null
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _selectedCity = null;
                                        _citySearchController.clear();
                                        _searchResults = [];
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: _onCitySearch,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _isLoadingLocation
                            ? null
                            : _useCurrentLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        tooltip: "Use current location",
                        style: IconButton.styleFrom(
                          backgroundColor: AppStyles.accentColor,
                        ),
                      ),
                    ],
                  ),

                  // Search Results Dropdown
                  if (_isSearching && _searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final city = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on),
                            title: Text(city.name),
                            subtitle: Text(city.country),
                            dense: true,
                            onTap: () => _selectCity(city),
                          );
                        },
                      ),
                    ),

                  // Selected City Info
                  if (_selectedCity != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppStyles.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppStyles.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppStyles.accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_selectedCity!.latitude.toStringAsFixed(4)}°N, '
                              '${_selectedCity!.longitude.toStringAsFixed(4)}°E',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _generateChart,
                child: const Text("Generate Chart"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
