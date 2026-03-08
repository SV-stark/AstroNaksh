class DailyRashiphal {
  final DateTime date;
  final String moonSign;
  final String nakshatra;
  final String tithi;
  final String overallPrediction;
  final List<String> keyHighlights;
  final List<String> auspiciousPeriods;
  final List<String> cautions;
  final String recommendation;
  final double favorableScore; // 0.0 to 1.0
  final List<String> transitContext; // Descriptive planetary transit positions
  final String dashaContext; // Current running Dasha period description

  DailyRashiphal({
    required this.date,
    required this.moonSign,
    required this.nakshatra,
    required this.tithi,
    required this.overallPrediction,
    required this.keyHighlights,
    required this.auspiciousPeriods,
    required this.cautions,
    required this.recommendation,
    this.favorableScore = 0.5,
    this.transitContext = const [],
    this.dashaContext = '',
  });
}

class RashiphalDashboard {
  final DailyRashiphal today;
  final DailyRashiphal tomorrow;
  final List<DailyRashiphal> weeklyOverview;

  RashiphalDashboard({
    required this.today,
    required this.tomorrow,
    required this.weeklyOverview,
  });
}
