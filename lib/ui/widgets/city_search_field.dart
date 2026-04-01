import 'package:fluent_ui/fluent_ui.dart';
import '../../data/city_database.dart';
import '../../core/error_handler.dart';

/// Reusable city search widget that eliminates duplication across
/// input_screen, panchang_screen, muhurta_finder_screen, and horary screens (DP8).
class CitySearchField extends StatefulWidget {
  final ValueChanged<City>? onCitySelected;
  final City? initialCity;
  final String? hintText;
  final bool showCurrentLocationButton;
  final EdgeInsetsGeometry? padding;

  const CitySearchField({
    super.key,
    this.onCitySelected,
    this.initialCity,
    this.hintText,
    this.showCurrentLocationButton = true,
    this.padding,
  });

  @override
  State<CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<CitySearchField> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<City> _results = [];
  City? _selectedCity;
  bool _isSearching = false;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.initialCity;
    if (_selectedCity != null) {
      _searchController.text = _selectedCity!.displayName;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _showDropdown = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final results = await errorHandler.safeAsync(
      () async => CityDatabase.searchCities(query),
      defaultValue: <City>[],
      context: 'CitySearchField.search',
    );

    if (!mounted) return;

    setState(() {
      _results = results.take(10).toList();
      _isSearching = false;
      _showDropdown = _results.isNotEmpty;
    });
  }

  void _selectCity(City city) {
    setState(() {
      _selectedCity = city;
      _searchController.text = city.displayName;
      _results = [];
      _showDropdown = false;
    });
    _focusNode.unfocus();
    widget.onCitySelected?.call(city);
  }

  Future<void> _useCurrentLocation() async {
    final city = await errorHandler.safeAsync(
      () => CityDatabase.getCurrentLocation(),
      context: 'CitySearchField.gps',
      userMessage: 'Unable to get your location',
    );

    if (city != null && mounted) {
      _selectCity(city);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextBox(
                controller: _searchController,
                focusNode: _focusNode,
                placeholder: widget.hintText ?? 'Search city...',
                suffix: _isSearching
                    ? const ProgressRing(strokeWidth: 2)
                    : null,
                onChanged: _onSearchChanged,
                onSubmitted: (_) {
                  if (_results.length == 1) {
                    _selectCity(_results.first);
                  }
                },
              ),
            ),
            if (widget.showCurrentLocationButton) ...[
              const SizedBox(width: 8),
              Button(
                child: const Icon(FluentIcons.location, size: 16),
                onPressed: _useCurrentLocation,
              ),
            ],
          ],
        ),
        if (_showDropdown) ...[
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final city = _results[index];
                return ListTile(
                  title: Text(city.name),
                  subtitle: Text('${city.state}, ${city.country}'),
                  onPressed: () => _selectCity(city),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
