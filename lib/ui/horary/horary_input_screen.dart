import 'package:fluent_ui/fluent_ui.dart';
import 'package:jyotish/jyotish.dart';
import '../../data/models.dart';
import 'horary_result_screen.dart';

class HoraryInputScreen extends StatefulWidget {
  const HoraryInputScreen({Key? key}) : super(key: key);

  @override
  State<HoraryInputScreen> createState() => _HoraryInputScreenState();
}

class _HoraryInputScreenState extends State<HoraryInputScreen> {
  // Form State
  int _seedNumber = 0;
  DateTime _selectedDate = DateTime.now();
  String _locationName = 'Loading...';
  Location? _selectedLocation;

  // Controllers
  final TextEditingController _seedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _useCurrentLocation();
  }

  Future<void> _useCurrentLocation() async {
    // Rough mock or reuse logic from InputScreen
    // Ideally we extract this to a LocationService logic class, but for now:
    try {
      // Mock default for development if geolocator failing or permission issues
      // In real app, call Geolocator
      // For now, let's default to a known location or try to fetch
      // Assuming InputScreen logic availability:
      // For safety in this prompt context, I will default to New Delhi
      _selectedLocation = Location(latitude: 28.6139, longitude: 77.2090);
      _locationName = "New Delhi, India (Default)";
    } catch (e) {
      _locationName = "Error: $e";
    }
  }

  void _onGenerate() {
    // Validate
    final seed = int.tryParse(_seedController.text);
    if (seed == null || seed < 1 || seed > 249) {
      showDialog(
        context: context,
        builder: (context) => ContentDialog(
          title: const Text('Invalid Number'),
          content: const Text('Please enter a number between 1 and 249.'),
          actions: [
            Button(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      // Show error
      return;
    }

    Navigator.push(
      context,
      FluentPageRoute(
        builder: (context) => HoraryResultScreen(
          seedNumber: seed,
          dateTime: _selectedDate,
          location: GeographicLocation(
            latitude: _selectedLocation!.latitude,
            longitude: _selectedLocation!.longitude,
            altitude: 0,
          ),
          locationName: _locationName,
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
        padding: const EdgeInsets.all(20.0),
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

            // Location Display (Simplified for now)
            InfoLabel(
              label: 'Location',
              child: TextBox(
                readOnly: true,
                placeholder: _locationName,
                suffix: IconButton(
                  icon: const Icon(FluentIcons.location),
                  onPressed: _useCurrentLocation,
                ),
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
