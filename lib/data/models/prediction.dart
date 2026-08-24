import 'package:flutter/foundation.dart';

class DailyRashiphal {
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

  factory DailyRashiphal.fromJson(Map<String, dynamic> json) {
    return DailyRashiphal(
      date: DateTime.parse(json['date'] as String),
      moonSign: json['moonSign'] as String,
      nakshatra: json['nakshatra'] as String,
      tithi: json['tithi'] as String,
      overallPrediction: json['overallPrediction'] as String,
      keyHighlights: (json['keyHighlights'] as List).cast<String>(),
      auspiciousPeriods: (json['auspiciousPeriods'] as List).cast<String>(),
      cautions: (json['cautions'] as List).cast<String>(),
      recommendation: json['recommendation'] as String,
      favorableScore: (json['favorableScore'] as num?)?.toDouble() ?? 0.5,
      transitContext:
          (json['transitContext'] as List<dynamic>?)?.cast<String>() ??
          const [],
      dashaContext: json['dashaContext'] as String? ?? '',
    );
  }
  final DateTime date;
  final String moonSign;
  final String nakshatra;
  final String tithi;
  final String overallPrediction;
  final List<String> keyHighlights;
  final List<String> auspiciousPeriods;
  final List<String> cautions;
  final String recommendation;
  final double favorableScore;
  final List<String> transitContext;
  final String dashaContext;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'moonSign': moonSign,
    'nakshatra': nakshatra,
    'tithi': tithi,
    'overallPrediction': overallPrediction,
    'keyHighlights': keyHighlights,
    'auspiciousPeriods': auspiciousPeriods,
    'cautions': cautions,
    'recommendation': recommendation,
    'favorableScore': favorableScore,
    'transitContext': transitContext,
    'dashaContext': dashaContext,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyRashiphal &&
        other.date == date &&
        other.moonSign == moonSign &&
        other.nakshatra == nakshatra &&
        other.tithi == tithi &&
        other.overallPrediction == overallPrediction &&
        other.favorableScore == favorableScore;
  }

  @override
  int get hashCode => Object.hash(
    date,
    moonSign,
    nakshatra,
    tithi,
    overallPrediction,
    favorableScore,
  );
}

class RashiphalDashboard {
  RashiphalDashboard({
    required this.today,
    required this.tomorrow,
    required this.weeklyOverview,
  });

  factory RashiphalDashboard.fromJson(Map<String, dynamic> json) {
    return RashiphalDashboard(
      today: DailyRashiphal.fromJson(json['today']),
      tomorrow: DailyRashiphal.fromJson(json['tomorrow']),
      weeklyOverview: (json['weeklyOverview'] as List)
          .map((e) => DailyRashiphal.fromJson(e))
          .toList(),
    );
  }
  final DailyRashiphal today;
  final DailyRashiphal tomorrow;
  final List<DailyRashiphal> weeklyOverview;

  Map<String, dynamic> toJson() => {
    'today': today.toJson(),
    'tomorrow': tomorrow.toJson(),
    'weeklyOverview': weeklyOverview.map((e) => e.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RashiphalDashboard &&
        other.today == today &&
        other.tomorrow == tomorrow &&
        listEquals(other.weeklyOverview, weeklyOverview);
  }

  @override
  int get hashCode => Object.hash(today, tomorrow, Object.hashAll(weeklyOverview));
}
