import 'package:astronaksh/logic/astrology/avakahada_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AvakahadaService Gana and Nadi Tests', () {
    test('Nadi serpentine pattern matching', () {
      // 0 (Ashwini) -> Adi
      expect(AvakahadaService.getNadi(0), equals('Adi (Beginning)'));
      // 3 (Rohini) -> Antya
      expect(AvakahadaService.getNadi(3), equals('Antya (End)'));
      // 5 (Ardra) -> Adi
      expect(AvakahadaService.getNadi(5), equals('Adi (Beginning)'));
      // 7 (Pushya) -> Madhya
      expect(AvakahadaService.getNadi(7), equals('Madhya (Middle)'));
      // 23 (Shatabhisha) -> Adi
      expect(AvakahadaService.getNadi(23), equals('Adi (Beginning)'));
    });

    test('Gana authentic groupings', () {
      // 0 (Ashwini) -> Deva
      expect(AvakahadaService.getGana(0), equals('Deva (Divine)'));
      // 16 (Anuradha) -> Deva
      expect(AvakahadaService.getGana(16), equals('Deva (Divine)'));
      // 20 (Uttara Ashadha) -> Manushya
      expect(AvakahadaService.getGana(20), equals('Manushya (Human)'));
      // 13 (Chitra) -> Rakshasa
      expect(AvakahadaService.getGana(13), equals('Rakshasa (Demon)'));
    });
  });
}
