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

  Map<String, dynamic> toJson() => {
    'starLord': starLord,
    'subLord': subLord,
    'subSubLord': subSubLord,
    'nakshatraIndex': nakshatraIndex,
    'nakshatraName': nakshatraName,
  };

  factory KPSubLord.fromJson(Map<String, dynamic> json) {
    return KPSubLord(
      starLord: json['starLord'] as String,
      subLord: json['subLord'] as String,
      subSubLord: json['subSubLord'] as String,
      nakshatraIndex: json['nakshatraIndex'] as int? ?? 0,
      nakshatraName: json['nakshatraName'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KPSubLord &&
        other.starLord == starLord &&
        other.subLord == subLord &&
        other.subSubLord == subSubLord &&
        other.nakshatraIndex == nakshatraIndex;
  }

  @override
  int get hashCode =>
      Object.hash(starLord, subLord, subSubLord, nakshatraIndex);
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

  Map<String, dynamic> toJson() => {
    'subLords': subLords.map((e) => e.toJson()).toList(),
    'significators': significators,
    'rulingPlanets': rulingPlanets,
  };

  factory KPData.fromJson(Map<String, dynamic> json) {
    return KPData(
      subLords: (json['subLords'] as List)
          .map((e) => KPSubLord.fromJson(e))
          .toList(),
      significators: (json['significators'] as List).cast<String>(),
      rulingPlanets: (json['rulingPlanets'] as List).cast<String>(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KPData &&
        other.subLords.length == subLords.length &&
        other.significators.length == significators.length;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(subLords),
    Object.hashAll(significators),
    Object.hashAll(rulingPlanets),
  );
}
