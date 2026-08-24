import 'dart:async';

import 'package:astronaksh/core/database.dart';
import 'package:astronaksh/ui/input_screen.dart';
import 'package:drift/native.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('InputScreen Widget Tests', () {
    testWidgets('Renders all fields and validates input', (tester) async {
      // Set test viewport size to make everything visible
      await tester.binding.setSurfaceSize(const Size(800, 1200));

      final mockDb = AppDatabase.connect(NativeDatabase.memory());

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const ScaffoldPage(content: SizedBox.shrink()),
          ),
          GoRoute(
            path: '/input',
            builder: (context, state) =>
                const InputScreen(onSelectionMode: true),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(mockDb)],
          child: FluentApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Push `/input` onto the stack
      unawaited(router.push('/input'));
      await tester.pumpAndSettle();

      // Check fields existence
      expect(find.text('Personal Details'), findsOneWidget);
      expect(find.text('Birth Date & Time'), findsOneWidget);
      expect(find.text('Birth Place'), findsOneWidget);
      expect(find.text('Enter coordinates manually'), findsOneWidget);

      // Check form validation on empty submit
      final generateBtn = find.text('Generate Chart');
      expect(generateBtn, findsOneWidget);

      await tester.ensureVisible(generateBtn);
      await tester.tap(generateBtn);
      await tester.pump();

      // "Required" validation error should appear
      expect(find.text('Required'), findsOneWidget);

      // Enter name
      final nameFieldFinder = find.byType(TextFormBox).first;
      expect(nameFieldFinder, findsOneWidget);
      await tester.ensureVisible(nameFieldFinder);
      await tester.enterText(nameFieldFinder, 'Test Person');
      await tester.pump();

      // Enable manual coordinates
      final checkbox = find.byType(Checkbox);
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();

      // Enter coordinates
      // With manual coordinates active, there should be 3 TextFormBox widgets in total.
      final textFormBoxes = find.byType(TextFormBox);
      expect(textFormBoxes, findsNWidgets(3));

      final latFieldFinder = textFormBoxes.at(1);
      final lngFieldFinder = textFormBoxes.at(2);

      await tester.ensureVisible(latFieldFinder);
      await tester.enterText(latFieldFinder, '28.6139');
      await tester.ensureVisible(lngFieldFinder);
      await tester.enterText(lngFieldFinder, '77.2090');
      await tester.pump();

      // Submit form
      await tester.ensureVisible(generateBtn);
      await tester.tap(generateBtn);
      // Let any asynchronous operations run and pump router pop transitions
      await tester.pumpAndSettle();

      // Verify saving to db worked by checking in-memory db charts table
      final allCharts = await mockDb.select(mockDb.charts).get();
      expect(allCharts, hasLength(1));
      expect(allCharts.first.name, equals('Test Person'));
      expect(allCharts.first.latitude, equals(28.6139));
      expect(allCharts.first.longitude, equals(77.2090));

      // Close database and let any leftover animations/timers clear out
      await mockDb.close();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}
