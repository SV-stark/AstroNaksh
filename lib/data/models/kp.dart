class KPSubLord {
  final String starLord;
  final String subLord;
  final String subSubLord;
  final int nakshatraIndex;
  final String nakshatraName;

  KPSubLord({
    required this.starLord,
    required this.subLord,
    required this.subSubLord,
    this.nakshatraIndex = 0,
    this.nakshatraName = '',
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
