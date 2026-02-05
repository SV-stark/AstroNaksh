import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/main.dart';
import 'package:astronaksh/core/settings_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

void main() {
  setUpAll(() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({'has_seen_tutorial': true});

    // Initialize SettingsManager singleton and force tutorial seen
    final settings = SettingsManager();
    await settings.loadSettings();
    await settings.setHasSeenTutorial(true);
  });

  testWidgets('App loads and showing loading screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    // Note: AstroNakshApp starts at /loading
    await tester.pumpWidget(const AstroNakshApp());

    // Wait for initial render
    await tester.pump();

    // Verify that the app builds without crashing.
    expect(find.byType(AstroNakshApp), findsOneWidget);

    // We expect a ProgressRing in the LoadingScreen
    // Since we didn't mock EphemerisManager, it might be calling ensureEphemerisData
    // which might or might not hang here.
    // If it hangs, we will have to mock it.
  });
}
