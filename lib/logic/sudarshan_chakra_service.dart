import 'package:jyotish/jyotish.dart';

class SudarshanChakraServiceWrapper {
  final SudarshanChakraService _service = SudarshanChakraService();

  Future<SudarshanChakraResult> calculateSudarshanChakra(
    VedicChart chart,
  ) async {
    return _service.calculateSudarshanChakra(chart);
  }
}
