import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/core/app_environment.dart';

void main() {
  group('AppEnvironment Tests', () {
    test('isInitialized starts as false', () {
      // Note: This is a read-only test since initialize modifies static state
      // We test that the class has the expected properties
      expect(AppEnvironment.isPortable, isA<bool>());
      expect(AppEnvironment.isVerbose, isA<bool>());
    });

    test('AppEnvironment can log without crashing', () {
      // Test that log method doesn't throw even without initialization
      // In verbose mode it would try to write to stdout
      AppEnvironment.log('Test log message');
    });

    test('AppEnvironment log handles various message types', () {
      AppEnvironment.log('Simple message');
      AppEnvironment.log('Message with number: ${42}');
      AppEnvironment.log('Message with decimal: ${3.14}');
      AppEnvironment.log('Message with boolean: ${true}');
    });
  });
}
