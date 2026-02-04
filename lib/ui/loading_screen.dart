import 'package:fluent_ui/fluent_ui.dart';
import '../core/ephemeris_manager.dart';

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
    return ScaffoldPage(
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ProgressRing(),
            const SizedBox(height: 20),
            Text("AstroNaksh", style: FluentTheme.of(context).typography.title),
            const SizedBox(height: 10),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
