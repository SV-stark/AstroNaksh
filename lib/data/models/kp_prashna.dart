enum PrashnaCategory {
  career,
  marriage,
  health,
  property,
  finance,
  education,
  travel,
  litigation,
}

enum PrashnaVerdict {
  promised,
  conditional,
  denied,
}

class KPPrashnaHouseSignificator {
  final int houseNumber;
  final String houseName;
  final String cuspSubLord;
  final String subLordStarLord;
  final List<int> subLordSignifiedHouses;
  final List<int> starLordSignifiedHouses;

  const KPPrashnaHouseSignificator({
    required this.houseNumber,
    required this.houseName,
    required this.cuspSubLord,
    required this.subLordStarLord,
    required this.subLordSignifiedHouses,
    required this.starLordSignifiedHouses,
  });
}

class KPPrashnaResult {
  final int seedNumber;
  final PrashnaCategory category;
  final String queryTitle;
  final PrashnaVerdict verdict;
  final double confidencePercentage;
  final List<int> primaryHouses;
  final List<int> supportingHouses;
  final List<int> negatingHouses;
  final List<KPPrashnaHouseSignificator> significatorBreakdown;
  final String detailedInterpretation;
  final String timingGuidance;

  const KPPrashnaResult({
    required this.seedNumber,
    required this.category,
    required this.queryTitle,
    required this.verdict,
    required this.confidencePercentage,
    required this.primaryHouses,
    required this.supportingHouses,
    required this.negatingHouses,
    required this.significatorBreakdown,
    required this.detailedInterpretation,
    required this.timingGuidance,
  });
}
