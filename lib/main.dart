import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/app_environment.dart';
import 'core/router.dart';
import 'core/settings_provider.dart';
import 'ui/styles.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: AstroNakshApp()));
}

class AstroNakshApp extends ConsumerStatefulWidget {
  const AstroNakshApp({super.key});

  @override
  ConsumerState<AstroNakshApp> createState() => _AstroNakshAppState();
}

class _AstroNakshAppState extends ConsumerState<AstroNakshApp> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
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
        } catch (_) {}
      }

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

    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const FluentApp(
        home: ScaffoldPage(content: Center(child: ProgressRing())),
      ),
      error: (err, stack) => FluentApp(
        home: ScaffoldPage(
          content: Center(child: Text('Error loading settings: $err')),
        ),
      ),
      data: (settings) => FluentApp.router(
        title: 'AstroNaksh',
        themeMode: settings.themeMode,
        theme: AppStyles.lightTheme,
        darkTheme: AppStyles.darkTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
