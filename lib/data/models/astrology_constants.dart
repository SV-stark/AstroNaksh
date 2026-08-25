import 'package:jyotish/core.dart';
import 'package:jyotish/panchanga.dart';

class AstrologyConstants {
  static List<String> get nakshatraNames => NakshatraInfo.nakshatraNames;

  static List<String> get signNames => Rashi.values.map((s) => s.name).toList();

  static String getSignName(int sign) => Rashi.fromIndex(sign).name;

  static Planet getSignLord(int sign) {
    return Rashi.fromIndex(sign).lord;
  }
}
