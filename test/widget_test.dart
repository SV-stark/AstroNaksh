import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/main.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() {
  setUpAll(() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  testWidgets('App loads and showing loading screen', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AstroNakshApp());
    await tester.pump(const Duration(seconds: 1)); // Wait for initial loading

    // Verify that the loading screen appears (it should have a ProgressRing or similar from Fluent UI)
    // For now, just check if the app builds without crashing.
    expect(find.byType(AstroNakshApp), findsOneWidget);
  });
}
