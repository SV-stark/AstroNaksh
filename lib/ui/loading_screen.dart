import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import '../core/ephemeris_manager.dart';
import '../data/city_database.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  String _status = "Initializing...";

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // We can't easily get granular progress from ensureEphemerisData
      // without modifying it, but we can at least show it's working.
      setState(() => _status = "Loading City Database...");
      await CityDatabase.initialize();

      setState(() => _status = "Loading Ephemeris Data...");
      await EphemerisManager.ensureEphemerisData();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      setState(() => _status = "Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isError = _status.startsWith("Error:");

    return ScaffoldPage(
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isError) ...[
              const ProgressRing(),
              const SizedBox(height: 20),
            ] else ...[
              Icon(FluentIcons.error, size: 48, color: Colors.red),
              const SizedBox(height: 20),
            ],
            Text("AstroNaksh", style: FluentTheme.of(context).typography.title),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _status,
                textAlign: TextAlign.center,
              ),
            ),
            if (isError) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Button(
                    onPressed: () {
                      setState(() => _status = "Retrying...");
                      _initApp();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FluentIcons.refresh, size: 16),
                        const SizedBox(width: 8),
                        const Text("Retry"),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Button(
                    onPressed: () {
                      // Exit the application
                      exit(0);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(FluentIcons.cancel, size: 16),
                        const SizedBox(width: 8),
                        const Text("Exit"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
