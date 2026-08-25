import 'package:astronaksh/core/database.dart';
import 'package:astronaksh/core/router.dart';
import 'package:astronaksh/ui/comparison/chart_comparison_screen.dart';
import 'package:astronaksh/ui/home_screen.dart';
import 'package:astronaksh/ui/input_screen.dart';
import 'package:astronaksh/ui/loading_screen.dart';
import 'package:astronaksh/ui/panchang_screen.dart';
import 'package:astronaksh/ui/settings_screen.dart';
import 'package:astronaksh/ui/tools/muhurta_finder_screen.dart';
import 'package:drift/native.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({'has_seen_tutorial': true});

    // Mock path_provider for AppEnvironment/Drift settings
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '.';
        });
  });

  group('App Router Tests', () {
    late AppDatabase mockDb;

    setUp(() {
      mockDb = AppDatabase.connect(NativeDatabase.memory());
    });

    tearDown(() async {
      await mockDb.close();
    });

    testWidgets('loading screen /loading', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(mockDb)],
          child: FluentApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      expect(find.byType(LoadingScreen), findsOneWidget);
    });

    testWidgets('home screen /', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(mockDb)],
          child: FluentApp.router(routerConfig: router),
        ),
      );
      router.go('/');
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('input screen /input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(mockDb)],
          child: FluentApp.router(routerConfig: router),
        ),
      );
      router.go('/input');
      await tester.pumpAndSettle();
      expect(find.byType(InputScreen), findsOneWidget);
    });

    testWidgets('settings screen /settings', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(mockDb)],
          child: FluentApp.router(routerConfig: router),
        ),
      );
      router.go('/settings');
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('panchang screen /panchang', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      final scrollController = ScrollController();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(mockDb)],
          child: PrimaryScrollController(
            controller: scrollController,
            child: FluentApp.router(routerConfig: router),
          ),
        ),
      );
      router.go('/panchang');
      await tester.pump();
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(find.byType(PanchangScreen), findsOneWidget);
    });

    testWidgets('comparison screen /comparison', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      final scrollController = ScrollController();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(mockDb)],
          child: PrimaryScrollController(
            controller: scrollController,
            child: FluentApp.router(routerConfig: router),
          ),
        ),
      );
      router.go('/comparison');
      await tester.pump();
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(find.byType(ChartComparisonScreen), findsOneWidget);
    });

    testWidgets('muhurta finder screen /muhurta', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      final scrollController = ScrollController();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(mockDb)],
          child: PrimaryScrollController(
            controller: scrollController,
            child: FluentApp.router(routerConfig: router),
          ),
        ),
      );
      router.go('/muhurta');
      await tester.pump();
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();
      expect(find.byType(MuhurtaFinderScreen), findsOneWidget);
    });
  });
}
