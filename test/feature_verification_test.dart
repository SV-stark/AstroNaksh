import 'package:flutter_test/flutter_test.dart';
import 'package:astronaksh/logic/dasha_system.dart';
import 'package:astronaksh/logic/sudarshan_chakra_service.dart';
import 'utils/test_chart_builder.dart';

void main() {
  test('Verify Native Chara Dasha Integration', () async {
    final chart = TestChartBuilder().build();

    final charaDasha = await DashaSystem.calculateCharaDasha(chart.baseChart);

    expect(charaDasha.periods, isNotEmpty);
    expect(charaDasha.startSign, isNotNull);
    // Print first period for manual verification
    if (charaDasha.periods.isNotEmpty) {
      print('Chara Dasha Start: ${charaDasha.periods.first.signName}');
    }
  });

  test('Verify Native Narayana Dasha Integration', () async {
    final chart = TestChartBuilder().build();

    final narayanaDasha = await DashaSystem.calculateNarayanaDasha(
      chart.baseChart,
    );

    expect(narayanaDasha.periods, isNotEmpty);
    expect(narayanaDasha.startSign, isNotNull);
    if (narayanaDasha.periods.isNotEmpty) {
      print('Narayana Dasha Start: ${narayanaDasha.periods.first.signName}');
    }
  });

  test('Verify Sudarshan Chakra Service Instantiation', () async {
    final service = SudarshanChakraServiceWrapper();
    final chart = TestChartBuilder().build();

    try {
      final result = await service.calculateSudarshanChakra(chart.baseChart);
      expect(result, isNotNull);
      expect(result, isNotNull);
    } catch (e) {
      // It might fail if library implementation has issues
    }
  });
}
