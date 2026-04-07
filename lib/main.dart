import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/app_environment.dart';
import 'core/settings_manager.dart';
import 'ui/chart_screen.dart';
import 'ui/comparison/chart_comparison_screen.dart';
import 'ui/home_screen.dart';
import 'ui/input_screen.dart';
import 'ui/loading_screen.dart';
import 'ui/panchang_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/styles.dart';
import 'ui/tools/muhurta_finder_screen.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AstroNakshApp());
}

class AstroNakshApp extends StatefulWidget {
  const AstroNakshApp({super.key});

  @override
  State<AstroNakshApp> createState() => _AstroNakshAppState();
}

class _AstroNakshAppState extends State<AstroNakshApp> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      // Initialize App Environment (Portable Mode / Verbose Checks)
      // Arguments are lost here, but usually not needed for normal run
      await AppEnvironment.initialize([]);

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      tz.initializeTimeZones();

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        try {
          await Window.initialize();
          await Window.setEffect(
            effect: WindowEffect.acrylic,
            color: const Color(0xCC222222),
          );
        } catch (e) {
          // Ignore
        }
      }

      final settings = SettingsManager();
      await settings.loadSettings();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return FluentApp(
        home: ScaffoldPage(
          content: Center(child: Text('Initialization Error: $_error')),
        ),
      );
    }

    if (!_initialized) {
      return const FluentApp(
        home: ScaffoldPage(content: Center(child: ProgressRing())),
      );
    }

    final settings = SettingsManager();
    return ListenableBuilder(
      listenable: settings,
      builder: (context, child) {
        return FluentApp(
          title: 'AstroNaksh',
          themeMode: settings.themeMode,
          theme: AppStyles.lightTheme,
          darkTheme: AppStyles.darkTheme,
          initialRoute: '/loading',
          routes: {
            '/loading': (context) => const LoadingScreen(),
            '/': (context) => const HomeScreen(),
            '/input': (context) => const InputScreen(),
            '/chart': (context) => const ChartScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/panchang': (context) => const PanchangScreen(),
            '/comparison': (context) => const ChartComparisonScreen(),
            '/muhurta': (context) => const MuhurtaFinderScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
