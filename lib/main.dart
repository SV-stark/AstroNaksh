import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'ui/styles.dart';
import 'ui/home_screen.dart';
import 'ui/input_screen.dart';
import 'ui/chart_screen.dart';
import 'ui/settings_screen.dart';
import 'core/ephemeris_manager.dart';
import 'core/settings_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Window for Acrylic effect
  try {
    await Window.initialize();
    await Window.setEffect(
      effect: WindowEffect.acrylic,
      color: const Color(0xCC222222),
    );
  } catch (e) {
    debugPrint("Failed to initialize window effect: $e");
  }

  // Initialize settings
  try {
    await SettingsManager().loadSettings();
  } catch (e) {
    debugPrint("Failed to load settings: $e");
  }

  // Initialize ephemeris data before running the app
  try {
    await EphemerisManager.ensureEphemerisData();
  } catch (e) {
    debugPrint("Failed to initialize EphemerisManager: $e");
  }

  runApp(const AstroNakshApp());
}

class AstroNakshApp extends StatelessWidget {
  const AstroNakshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SettingsManager(),
      builder: (context, child) {
        return FluentApp(
          title: 'AstroNaksh',
          themeMode: SettingsManager().themeMode,
          theme: AppStyles.lightTheme,
          darkTheme: AppStyles.darkTheme,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/input': (context) => const InputScreen(),
            '/chart': (context) => const ChartScreen(),
            '/settings': (context) => const SettingsScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
