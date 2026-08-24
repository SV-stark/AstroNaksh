import 'dart:async';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/app_environment.dart';
import 'core/router.dart';
import 'core/settings_provider.dart';
import 'ui/styles.dart';

List<String> _appArgs = const [];

void main(List<String> args) {
  _appArgs = args;
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
      await AppEnvironment.initialize(_appArgs);

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
      error: (err, stack) {
        AppEnvironment.log('Error loading settings: $err\n$stack');
        return FluentApp.router(
          title: 'AstroNaksh',
          themeMode: ThemeMode.system,
          theme: AppStyles.lightTheme,
          darkTheme: AppStyles.darkTheme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
      data: (settings) => FluentApp.router(
        title: 'AstroNaksh',
        themeMode: settings.themeMode,
        theme: AppStyles.lightTheme,
        darkTheme: AppStyles.darkTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', 'US')],
      ),
    );
  }
}
