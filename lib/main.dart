import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'ui/styles.dart';
import 'ui/home_screen.dart';
import 'ui/input_screen.dart';
import 'ui/chart_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/loading_screen.dart';
import 'ui/panchang_screen.dart';
import 'ui/comparison/chart_comparison_screen.dart';
import 'core/settings_manager.dart';
import 'dart:io';
import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'core/app_environment.dart';

void main(List<String> args) async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize App Environment (Portable Mode / Verbose Checks)
      await AppEnvironment.initialize(args);

      AppEnvironment.log('Main: Starting app initialization...');
      AppEnvironment.log(
        'Main: Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      );

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        try {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
          AppEnvironment.log('Main: sqflite_ffi initialized successfully');
        } catch (e, stack) {
          AppEnvironment.log(
            'Main: Failed to initialize sqflite_ffi: $e\n$stack',
          );
        }
      }

      tz.initializeTimeZones();
      AppEnvironment.log('Main: Timezones initialized');

      // Initialize Window for Acrylic effect (Desktop Only)
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        try {
          await Window.initialize();
          await Window.setEffect(
            effect: WindowEffect.acrylic,
            color: const Color(0xCC222222),
          );
          AppEnvironment.log('Main: Window effect initialized');
        } catch (e) {
          AppEnvironment.log("Main: Failed to initialize window effect: $e");
        }
      } else {
        AppEnvironment.log('Main: Window effect skipped on mobile platforms');
      }

      // Initialize settings
      try {
        final settings = SettingsManager();
        AppEnvironment.log(
          'Main: Loading settings (Portable: ${AppEnvironment.isPortable})...',
        );
        await settings.loadSettings();
        AppEnvironment.log('Main: Settings loaded');
      } catch (e, stack) {
        AppEnvironment.log("Main: Failed to load settings: $e\n$stack");
      }

      runApp(const AstroNakshApp());
      AppEnvironment.log('Main: runApp called');
    },
    (error, stack) {
      AppEnvironment.log('CRITICAL: Uncaught exception: $error\n$stack');
      if (AppEnvironment.isVerbose) {
        stderr.writeln('CRITICAL: Uncaught exception: $error\n$stack');
      }
    },
  );
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
          initialRoute: '/loading',
          routes: {
            '/loading': (context) => const LoadingScreen(),
            '/': (context) => const HomeScreen(),
            '/input': (context) => const InputScreen(),
            '/chart': (context) => const ChartScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/panchang': (context) => const PanchangScreen(),
            '/comparison': (context) => const ChartComparisonScreen(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
