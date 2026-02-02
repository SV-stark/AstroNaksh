import 'package:jyotish/jyotish.dart';
 
 class Location {
   final double latitude;
   final double longitude;
   Location(this.latitude, this.longitude);
 }

class BirthData {
  final DateTime dateTime;
  final Location location;

  BirthData({required this.dateTime, required this.location});
}

class KPSubLord {
  final String starLord;
  final String subLord;
  final String subSubLord;

  KPSubLord({
    required this.starLord,
    required this.subLord,
    required this.subSubLord,
  });
}

class KPData {
  final List<KPSubLord> subLords;
  final List<String> significators;
  final List<String> rulingPlanets;

  KPData({
    required this.subLords,
    required this.significators,
    required this.rulingPlanets,
  });
}

class ChartData {
  final VedicChart baseChart;
  final KPData kpData;

  ChartData({required this.baseChart, required this.kpData});
}
