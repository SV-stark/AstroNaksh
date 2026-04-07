// ignore_for_file: avoid_slow_async_io, unawaited_futures, deprecated_member_use, sort_constructors_first, implementation_imports
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
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // We can't easily get granular progress from ensureEphemerisData
      // without modifying it, but we can at least show it's working.
      setState(() => _status = 'Loading City Database...');
      await CityDatabase.initialize();

      setState(() => _status = 'Loading Ephemeris Data...');
      await EphemerisManager.ensureEphemerisData();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isError = _status.startsWith('Error:');

    return ScaffoldPage(
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'AstroNaksh',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            if (!isError) ...[
              const ProgressBar(),
              const SizedBox(height: 16),
            ] else ...[
              Icon(FluentIcons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
            ],
            Text(
              _status,
              style: TextStyle(color: isError ? Colors.red : null),
              textAlign: TextAlign.center,
            ),
            if (isError) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Button(
                    onPressed: _initApp,
                    child: const Row(
                      children: [
                        Icon(FluentIcons.refresh),
                        SizedBox(width: 8),
                        Text('Retry'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Button(
                    onPressed: () => exit(1),
                    child: const Row(
                      children: [
                        Icon(FluentIcons.cancel),
                        SizedBox(width: 8),
                        Text('Exit'),
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
