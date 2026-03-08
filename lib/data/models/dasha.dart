import 'package:jyotish/jyotish.dart';

/// Vimshottari Dasha data class
class VimshottariDasha {
  final String birthLord;
  final double balanceAtBirth;
  final List<Mahadasha> mahadashas;

  VimshottariDasha({
    required this.birthLord,
    required this.balanceAtBirth,
    required this.mahadashas,
  });

  String get formattedBalanceAtBirth {
    final years = balanceAtBirth.floor();
    final months = ((balanceAtBirth - years) * 12).floor();
    final days = (((balanceAtBirth - years) * 12 - months) * 30).floor();
    return '$years years, $months months, $days days';
  }
}

/// Mahadasha data class
class Mahadasha {
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
  final List<Antardasha> antardashas;

  Mahadasha({
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
    required this.antardashas,
  });

  String get formattedPeriod {
    final years = periodYears.floor();
    final months = ((periodYears - years) * 12).floor();
    return '$years years $months months';
  }
}

/// Antardasha data class
class Antardasha {
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
  final List<Pratyantardasha> pratyantardashas;

  Antardasha({
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
    required this.pratyantardashas,
  });
}

/// Pratyantardasha data class
class Pratyantardasha {
  final String mahadashaLord;
  final String antardashaLord;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;

  Pratyantardasha({
    required this.mahadashaLord,
    required this.antardashaLord,
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
}

/// Yogini Dasha data class
class YoginiDasha {
  final String startYogini;
  final List<YoginiMahadasha> mahadashas;

  YoginiDasha({required this.startYogini, required this.mahadashas});
}

/// Yogini Mahadasha data class
class YoginiMahadasha {
  final String name;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;
  final List<YoginiAntardasha> antardashas;

  YoginiMahadasha({
    required this.name,
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
    this.antardashas = const [],
  });
}

class YoginiAntardasha {
  final String name;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final List<YoginiPratyantardasha> pratyantardashas;

  YoginiAntardasha({
    required this.name,
    required this.lord,
    required this.startDate,
    required this.endDate,
    this.pratyantardashas = const [],
  });
}

class YoginiPratyantardasha {
  final String name;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;

  YoginiPratyantardasha({
    required this.name,
    required this.lord,
    required this.startDate,
    required this.endDate,
  });
}

/// Chara Dasha data class
class CharaDasha {
  final int startSign;
  final List<CharaDashaPeriod> periods;

  CharaDasha({required this.startSign, required this.periods});
}

/// Chara Dasha Period data class
class CharaDashaPeriod {
  final int sign;
  final String signName;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;

  CharaDashaPeriod({
    required this.sign,
    required this.signName,
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
}

/// Narayana Dasha data class
class NarayanaDasha {
  final int startSign;
  final List<NarayanaDashaPeriod> periods;

  NarayanaDasha({required this.startSign, required this.periods});
}

/// Narayana Dasha Period data class
class NarayanaDashaPeriod {
  final int sign;
  final String signName;
  final String lord;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;

  NarayanaDashaPeriod({
    required this.sign,
    required this.signName,
    required this.lord,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
}

/// Ashtottari Dasha data class
class AshtottariDasha {
  final List<AshtottariMahadasha> mahadashas;
  final String birthNakshatra;
  final double balanceOfFirstDasha;

  AshtottariDasha({
    required this.mahadashas,
    required this.birthNakshatra,
    required this.balanceOfFirstDasha,
  });
}

/// Ashtottari Mahadasha data class
class AshtottariMahadasha {
  final Planet lord;
  final String lordName;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;

  AshtottariMahadasha({
    required this.lord,
    required this.lordName,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
}

/// Kalachakra Dasha data class
class KalachakraDasha {
  final List<KalachakraMahadasha> mahadashas;
  final String birthNakshatra;

  KalachakraDasha({required this.mahadashas, required this.birthNakshatra});
}

/// Kalachakra Mahadasha data class
class KalachakraMahadasha {
  final Rashi rashi;
  final String signName;
  final DateTime startDate;
  final DateTime endDate;
  final double periodYears;

  KalachakraMahadasha({
    required this.rashi,
    required this.signName,
    required this.startDate,
    required this.endDate,
    required this.periodYears,
  });
}

/// Combined Dasha data
class DashaData {
  final VimshottariDasha vimshottari;
  final YoginiDasha yogini;
  final CharaDasha chara;
  final NarayanaDasha narayana;
  final AshtottariDasha ashtottari;
  final KalachakraDasha kalachakra;

  DashaData({
    required this.vimshottari,
    required this.yogini,
    required this.chara,
    required this.narayana,
    required this.ashtottari,
    required this.kalachakra,
  });
}
