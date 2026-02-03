import 'package:flutter/material.dart';
import 'ui/styles.dart';
import 'ui/home_screen.dart';
import 'ui/input_screen.dart';
import 'ui/chart_screen.dart';
import 'core/ephemeris_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ephemeris data before running the app
  await EphemerisManager.ensureEphemerisData();

  runApp(const AstroNakshApp());
}

class AstroNakshApp extends StatelessWidget {
  const AstroNakshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AstroNaksh',
      theme: AppStyles.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/input': (context) => const InputScreen(),
        '/chart': (context) => const ChartScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
