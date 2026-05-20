import 'package:astronaksh/data/models.dart';
import 'package:astronaksh/logic/kp_chart_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KPChartService Error Handling Regression Tests', () {
    test('generateCompleteChart should return null when invalid coordinates are provided', () async {
      final service = KPChartService();
      final invalidBirthData = BirthData(
        dateTime: DateTime.now(),
        location: const Location(
          latitude: 999.0, // Invalid latitude
          longitude: 999.0, // Invalid longitude
        ),
        name: 'Invalid Test User',
        place: 'Invalid Coordinates City',
        timezone: 'UTC',
      );

      final result = await service.generateCompleteChart(invalidBirthData);
      expect(result, isNull);
    });

    test('generateKPChart should return null when generateCompleteChart returns null', () async {
      final service = KPChartService();
      final invalidBirthData = BirthData(
        dateTime: DateTime.now(),
        location: const Location(
          latitude: 999.0, // Invalid latitude
          longitude: 999.0, // Invalid longitude
        ),
        name: 'Invalid Test User',
        place: 'Invalid Coordinates City',
        timezone: 'UTC',
      );

      final result = await service.generateKPChart(invalidBirthData);
      expect(result, isNull);
    });
  });
}
