import 'package:jyotish/jyotish.dart';

/// Vimshottari Dasha data class
class VimshottariDasha {
  VimshottariDasha({
    required this.birthLord,
    required this.balanceAtBirth,
    required this.mahadashas,
  });
  final String birthLord;
  final double balanceAtBirth;
  final List<Mahadasha> mahadashas;

  String get formattedBalanceAtBirth {
    final years = balanceAtBirth.floor();
    final months = ((balanceAtBirth - years) * 12).floor();
    final days = (((balanceAtBirth - years) * 12 - months) * 30).floor();
    return '$years years, $months months, $days days';
  }
}

/// Mahadasha data class
class Mahadasha {
  Mahadasha({
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
    required this.antardashas,
  });
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
  final List<Antardasha> antardashas;

  String get formattedPeriod {
    final years = periodYears.floor();
    final months = ((periodYears - years) * 12).floor();
    return '$years years $months months';
  }
}

/// Antardasha data class
class Antardasha {
  Antardasha({
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
    required this.pratyantardashas,
  });
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
  final List<Pratyantardasha> pratyantardashas;
}

/// Pratyantardasha data class
class Pratyantardasha {
  Pratyantardasha({
    required this.mahadashaLord,
    required this.antardashaLord,
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
  final String mahadashaLord;
  final String antardashaLord;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
}

/// Yogini Dasha data class
class YoginiDasha {
  YoginiDasha({required this.startYogini, required this.mahadashas});
  final String startYogini;
  final List<YoginiMahadasha> mahadashas;
}

/// Yogini Mahadasha data class
class YoginiMahadasha {
  YoginiMahadasha({
    required this.name,
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
    this.antardashas = const [],
  });
  final String name;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
  final List<YoginiAntardasha> antardashas;
}

class YoginiAntardasha {
  YoginiAntardasha({
    required this.name,
    required this.lord,
    required this.startDate,
    required this.endDate,
    this.pratyantardashas = const [],
  });
  final String name;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final List<YoginiPratyantardasha> pratyantardashas;
}

class YoginiPratyantardasha {
  YoginiPratyantardasha({
    required this.name,
    required this.lord,
    required this.startDate,
    required this.endDate,
  });
  final String name;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
}

/// Chara Dasha data class
class CharaDasha {
  CharaDasha({required this.startSign, required this.periods});
  final int startSign;
  final List<CharaDashaPeriod> periods;
}

/// Chara Dasha Period data class
class CharaDashaPeriod {
  CharaDashaPeriod({
    required this.sign,
    required this.signName,
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
  final int sign;
  final String signName;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
}

/// Narayana Dasha data class
class NarayanaDasha {
  NarayanaDasha({required this.startSign, required this.periods});
  final int startSign;
  final List<NarayanaDashaPeriod> periods;
}

/// Narayana Dasha Period data class
class NarayanaDashaPeriod {
  NarayanaDashaPeriod({
    required this.sign,
    required this.signName,
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
  final int sign;
  final String signName;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
}

/// Ashtottari Dasha data class
class AshtottariDasha {
  AshtottariDasha({
    required this.mahadashas,
    required this.birthNakshatra,
    required this.balanceOfFirstDasha,
  });
  final List<AshtottariMahadasha> mahadashas;
  final String birthNakshatra;
  final double balanceOfFirstDasha;
}

/// Ashtottari Mahadasha data class
class AshtottariMahadasha {
  AshtottariMahadasha({
    required this.lord,
    required this.lordName,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
  final Planet lord;
  final String lordName;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
}

/// Kalachakra Dasha data class
class KalachakraDasha {
  KalachakraDasha({required this.mahadashas, required this.birthNakshatra});
  final List<KalachakraMahadasha> mahadashas;
  final String birthNakshatra;
}

/// Kalachakra Mahadasha data class
class KalachakraMahadasha {
  KalachakraMahadasha({
    required this.rashi,
    required this.signName,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
  final Rashi rashi;
  final String signName;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
}

/// Combined Dasha data
class DashaData {
  DashaData({
    required this.vimshottari,
    required this.yogini,
    required this.chara,
    required this.narayana,
    required this.ashtottari,
    required this.kalachakra,
  });
  final VimshottariDasha vimshottari;
  final YoginiDasha yogini;
  final CharaDasha chara;
  final NarayanaDasha narayana;
  final AshtottariDasha ashtottari;
  final KalachakraDasha kalachakra;
}
