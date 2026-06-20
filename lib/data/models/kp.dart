class KPSubLord {
  KPSubLord({
    required this.starLord,
    required this.subLord,
    required this.subSubLord,
    this.nakshatraIndex = 0,
    this.nakshatraName = '',
  });

  factory KPSubLord.fromJson(Map<String, dynamic> json) {
    return KPSubLord(
      starLord: json['starLord'] as String,
      subLord: json['subLord'] as String,
      subSubLord: json['subSubLord'] as String,
      nakshatraIndex: json['nakshatraIndex'] as int? ?? 0,
      nakshatraName: json['nakshatraName'] as String? ?? '',
    );
  }
  final String starLord;
  final String subLord;
  final String subSubLord;
  final int nakshatraIndex;
  final String nakshatraName;

  Map<String, dynamic> toJson() => {
    'starLord': starLord,
    'subLord': subLord,
    'subSubLord': subSubLord,
    'nakshatraIndex': nakshatraIndex,
    'nakshatraName': nakshatraName,
  };

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
  KPData({
    required this.subLords,
    required this.significators,
    required this.rulingPlanets,
    this.cuspSubLords = const [],
  });

  factory KPData.fromJson(Map<String, dynamic> json) {
    return KPData(
      subLords: (json['subLords'] as List)
          .map((e) => KPSubLord.fromJson(e))
          .toList(),
      significators: (json['significators'] as List).cast<String>(),
      rulingPlanets: (json['rulingPlanets'] as List).cast<String>(),
      cuspSubLords: (json['cuspSubLords'] as List? ?? []).cast<String>(),
    );
  }
  final List<KPSubLord> subLords;
  final List<String> significators;
  final List<String> rulingPlanets;
  final List<String> cuspSubLords;

  Map<String, dynamic> toJson() => {
    'subLords': subLords.map((e) => e.toJson()).toList(),
    'significators': significators,
    'rulingPlanets': rulingPlanets,
    'cuspSubLords': cuspSubLords,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KPData &&
        other.subLords.length == subLords.length &&
        other.significators.length == significators.length &&
        other.cuspSubLords.length == cuspSubLords.length;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(subLords),
    Object.hashAll(significators),
    Object.hashAll(rulingPlanets),
    Object.hashAll(cuspSubLords),
  );
}
