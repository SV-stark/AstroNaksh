import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:astronaksh/logic/panchang_service.dart';
import 'package:astronaksh/data/models.dart';
import 'package:astronaksh/core/ephemeris_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '.'; // Return current directory for all path requests in tests
        });
  });

  test('PanchangService should include rise/set times', () async {
    final service = PanchangService();
    final date = DateTime(2024, 1, 1, 12, 0);
    final location = Location(latitude: 28.6139, longitude: 77.2090);

    await EphemerisManager.ensureEphemerisData();
    final result = await service.getPanchang(date, location);

    print('Date: ${result.date}');
    print('Sunrise: ${result.sunrise}');
    print('Sunset: ${result.sunset}');
    print('Moonrise: ${result.moonrise}');
    print('Moonset: ${result.moonset}');

    expect(result.sunrise, isNot('--:--'));
    expect(result.sunset, isNot('--:--'));
    expect(result.moonrise, isNotNull);
    expect(result.moonset, isNotNull);
  });
}
