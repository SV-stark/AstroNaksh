import 'package:jyotish/src/models/calculation_flags.dart';
import 'package:jyotish/src/models/geographic_location.dart';
import 'package:jyotish/src/panchanga/masa.dart';
import 'package:jyotish/src/panchanga/nakshatra.dart';
import 'package:jyotish/src/panchanga/panchanga.dart';
import 'package:jyotish/src/models/planet.dart';
import 'package:jyotish/src/astronomy/planet_position.dart';
import 'package:jyotish/src/astronomy/ephemeris_service.dart';

class MasaService {
  MasaService(this._ephemerisService);
  final EphemerisService _ephemerisService;

  Future<MasaInfo> calculateMasa({
    required DateTime dateTime,
    required GeographicLocation location,
    MasaType type = MasaType.amanta,
  }) async {
    final flags = CalculationFlags.defaultFlags();

    final monthStart = await _findMasaStart(dateTime, location, type);

    // Current positions fix the tithi (and so the paksha, which sets the
    // Purnimanta offset) and supply the reported Sun longitude.
    final sunPos = await _ephemerisService.calculatePlanetPosition(
      planet: Planet.sun,
      dateTime: dateTime,
      location: location,
      flags: flags,
    );
    final moonPos = await _ephemerisService.calculatePlanetPosition(
      planet: Planet.moon,
      dateTime: dateTime,
      location: location,
      flags: flags,
    );
    final tithi = _calculateTithi(sunPos, moonPos);

    // The Amanta month name is ALWAYS derived from the exact new-moon boundary,
    // whichever calendar the caller asked for. The previous implementation
    // estimated that new moon's Sun longitude from the current instant using a
    // mean rate, which is what let the Adhika verdict (computed from the bisected
    // boundary) and the month name disagree near a sankranti.
    final amantaBoundary = type == MasaType.amanta
        ? monthStart
        : await _findMasaStart(dateTime, location, MasaType.amanta);
    final sunAtAmantaBoundary =
        await _ephemerisService.calculatePlanetPosition(
      planet: Planet.sun,
      dateTime: amantaBoundary,
      location: location,
      flags: flags,
    );
    final amantaMonth =
        MasaInfo.getMonthFromSunLongitude(sunAtAmantaBoundary.longitude);

    final LunarMonth month;
    if (type == MasaType.amanta) {
      // An Amanta month begins AT its new moon, so its name is simply the
      // Amanta name for the Sun's longitude at that boundary.
      month = amantaMonth;
    } else {
      // A Purnimanta month spans the second half of one Amanta month and the
      // first half of the next, because it ends on its own Purnima. So the
      // Purnimanta name is the Amanta name advanced by one during KRISHNA
      // paksha, and equals the Amanta name during SHUKLA paksha.
      //
      // That offset is a pure calendar convention needing no astronomical
      // estimate, so it is layered on top of the exact boundary-derived Amanta
      // month rather than being folded into a mean-rate approximation.
      final offset = tithi.paksha == Paksha.krishna ? 1 : 0;
      final amantaIndex = MasaInfo.amantaMonthOrder.indexOf(amantaMonth);
      month = MasaInfo.amantaMonthOrder[(amantaIndex + offset) % 12];
    }

    final monthNumber = type == MasaType.amanta
        ? _getAmantaMonthNumber(month)
        : _getPurnimantaMonthNumber(month);

    final adhikaType = await _checkAdhikaMasa(monthStart, location, type);

    return MasaInfo(
      month: month,
      monthNumber: monthNumber,
      type: type,
      adhikaType: adhikaType,
      sunLongitude: sunPos.longitude,
      tithiInfo: tithi,
    );
  }

  TithiInfo _calculateTithi(PlanetPosition sunPos, PlanetPosition moonPos) {
    var elongation = moonPos.longitude - sunPos.longitude;
    if (elongation < 0) elongation += 360;

    const tithiDegrees = 12.0;
    final tithiNumber = (elongation / tithiDegrees).floor() + 1;
    final elapsed = (elongation % tithiDegrees) / tithiDegrees;

    final paksha = Paksha.fromTithiNumber(tithiNumber);
    // Use paksha-aware lookup to correctly distinguish Purnima (Shukla 15) from Amavasya (Krishna 15)
    final name = TithiInfo.nameFromNumber(tithiNumber);

    return TithiInfo(
      number: tithiNumber,
      name: name,
      paksha: paksha,
      elapsed: elapsed,
    );
  }

  int _getAmantaMonthNumber(LunarMonth month) {
    return MasaInfo.amantaMonthOrder.indexOf(month) + 1;
  }

  int _getPurnimantaMonthNumber(LunarMonth month) {
    return MasaInfo.purnimantaMonthOrder.indexOf(month) + 1;
  }

  /// Mean rate at which the Moon's elongation from the Sun grows (deg/day).
  static const double _meanElongationPerDay = 12.190749;

  /// Mean synodic month (days) between one new moon and the next.
  static const double _meanSynodicMonthDays = 29.530589;

  /// Angular distance (degrees) that defines the searched lunar phase:
  /// 0 degrees (new moon) starts an Amanta month, 180 degrees (full moon)
  /// starts a Purnimanta month.
  double _phaseTarget(MasaType type) =>
      type == MasaType.purnimanta ? 180.0 : 0.0;

  /// Signed difference [a] - [b], wrapped to (-180, 180].
  static double _signedAngleDifference(double a, double b) {
    return (a - b + 180) % 360 - 180;
  }

  /// Moon-Sun elongation at [dateTime] in degrees (0 = new moon, 180 = full
  /// moon), measured as (moon longitude - sun longitude).
  Future<double> _moonSunElongation(
    DateTime dateTime,
    GeographicLocation location,
    CalculationFlags flags,
  ) async {
    final sunPos = await _ephemerisService.calculatePlanetPosition(
      planet: Planet.sun,
      dateTime: dateTime,
      location: location,
      flags: flags,
    );
    final moonPos = await _ephemerisService.calculatePlanetPosition(
      planet: Planet.moon,
      dateTime: dateTime,
      location: location,
      flags: flags,
    );

    return (moonPos.longitude - sunPos.longitude + 360) % 360;
  }

  /// Brackets and bisects the lunar phase that defines a month boundary.
  ///
  /// [low]/[high] must bracket the phase (the angular offset is negative just
  /// before it and positive just after) and [cycles] states how many whole
  /// lunations before the reference instant the boundary lies, which makes
  /// [high] the start of the *following* month when [cycles] is negative.
  /// The phase is returned to within one minute.
  Future<DateTime> _bisectMasaPhase(
    DateTime low,
    DateTime high,
    int cycles,
    MasaType type,
    GeographicLocation location,
    CalculationFlags flags,
  ) async {
    final reference = _phaseTarget(type) + 360 * cycles;

    Future<double> offsetFromPhase(DateTime when) async {
      final elongation = await _moonSunElongation(when, location, flags);
      return _signedAngleDifference(elongation, reference);
    }

    const accuracy = Duration(minutes: 1);

    for (var i = 0; i < 40 && high.difference(low) > accuracy; i++) {
      final mid = low.add(
        Duration(milliseconds: high.difference(low).inMilliseconds ~/ 2),
      );

      if (await offsetFromPhase(mid) < 0) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return high;
  }

  /// Most recent lunar month boundary at or before [dateTime] - the new moon
  /// for Amanta, the full moon for Purnimanta.
  Future<DateTime> _findMasaStart(
    DateTime dateTime,
    GeographicLocation location,
    MasaType type,
  ) async {
    final flags = CalculationFlags.defaultFlags();
    final target = _phaseTarget(type);

    final elongation = await _moonSunElongation(dateTime, location, flags);

    // Whole lunations already elapsed since a phase of this kind, and how far
    // into the current one we are (0 <= x < 360).
    final cycles = ((elongation - target) / 360).floor();
    final sincePhase = elongation - target - 360 * cycles;

    // The phase is [sincePhase] degrees of elongation in the past; the mean
    // rate brackets it to within about half a day, and +/- 3 days comfortably
    // encloses that error (a synodic month runs 29.27 - 29.83 days).
    final estimated = dateTime.subtract(
      Duration(seconds: (sincePhase / _meanElongationPerDay * 86400).round()),
    );

    return _bisectMasaPhase(
      estimated.subtract(const Duration(days: 3)),
      estimated.add(const Duration(days: 3)),
      cycles,
      type,
      location,
      flags,
    );
  }

  /// Start of the lunar month that begins right after [monthStart].
  Future<DateTime> _findNextMasaStart(
    DateTime monthStart,
    GeographicLocation location,
    MasaType type,
  ) async {
    final flags = CalculationFlags.defaultFlags();
    final estimated = monthStart.add(
      Duration(seconds: (_meanSynodicMonthDays * 86400).round()),
    );

    // A boundary one full lunation (360 degrees of elongation) beyond
    // [monthStart], hence cycles = -1 relative to it.
    return _bisectMasaPhase(
      estimated.subtract(const Duration(days: 3)),
      estimated.add(const Duration(days: 3)),
      -1,
      type,
      location,
      flags,
    );
  }

  /// Whether the lunar month starting at [monthStart] is an Adhika Masa.
  ///
  /// Rule: a lunar month is Adhika (a leap month) when the Sun makes no
  /// Sankranti - no ingress into a new rashi - during that month. The Sun
  /// covers roughly 29.1 degrees in a lunar month, so an ordinary month always
  /// contains exactly one Sankranti, whereas in an Adhika month the Sun enters
  /// and leaves the *same* rashi and the next ingress falls after the month
  /// ends. The Adhika month and the Nija month that follows it therefore share
  /// a month name, and the two are told apart by whether a rashi boundary is
  /// crossed between their boundaries - which is what this compares.
  ///
  /// [monthStart] is the new moon (Amanta) or full moon (Purnimanta) that
  /// opens the month under test.
  Future<AdhikaMasaType> _checkAdhikaMasa(
    DateTime monthStart,
    GeographicLocation location,
    MasaType type,
  ) async {
    final flags = CalculationFlags.defaultFlags();

    Future<int> sunRashiAt(DateTime moment) async {
      final pos = await _ephemerisService.calculatePlanetPosition(
        planet: Planet.sun,
        dateTime: moment,
        location: location,
        flags: flags,
      );
      return (pos.longitude / 30).floor();
    }

    final monthEnd = await _findNextMasaStart(monthStart, location, type);

    final rashiAtStart = await sunRashiAt(monthStart);
    final rashiAtEnd = await sunRashiAt(monthEnd);

    // Sun in the same rashi at both ends of the month => no Sankranti inside,
    // so the Sun never left the rashi and this is an Adhika (leap) month.
    if (rashiAtStart == rashiAtEnd) {
      return AdhikaMasaType.adhika;
    }

    // A regular month is the Nija ("real") month only when the lunar month
    // immediately before it was Adhika: the Adhika month and the Nija month
    // that follows share a month name, and they are told apart precisely by
    // which of the two contains the missing Sankranti. Without this check a
    // Nija month was indistinguishable from any other ordinary month.
    final previousMonthStart = await _findMasaStart(
      monthStart.subtract(const Duration(days: 1)),
      location,
      type,
    );
    if (previousMonthStart.isBefore(monthStart)) {
      final rashiAtPreviousStart = await sunRashiAt(previousMonthStart);
      if (rashiAtPreviousStart == rashiAtStart) {
        return AdhikaMasaType.nija;
      }
    }

    return AdhikaMasaType.none;
  }

  Future<String> getSamvatsara({
    required DateTime dateTime,
    required GeographicLocation location,
  }) async {
    const cycleStartYear = 1987; // Prabhava starts 1987
    final samvatsaraIndex = ((dateTime.year - cycleStartYear) % 60 + 60) % 60;

    return Samvatsara.getSamvatsaraName(samvatsaraIndex);
  }

  Future<NakshatraInfo> getNakshatraWithAbhijit({
    required DateTime dateTime,
    required GeographicLocation location,
  }) async {
    final flags = CalculationFlags.defaultFlags();

    final moonPos = await _ephemerisService.calculatePlanetPosition(
      planet: Planet.moon,
      dateTime: dateTime,
      location: location,
      flags: flags,
    );

    return _calculateNakshatraWithAbhijit(moonPos.longitude);
  }

  /// Calculates nakshatra information from a longitude value.
  ///
  /// This is the core calculation used by other methods. It determines
  /// which of the 27 nakshatras a given longitude falls into.
  ///
  /// [longitude] - The longitude in degrees (0-360)
  ///
  /// Returns [NakshatraInfo] without Abhijit calculation (standard 27 nakshatras)
  NakshatraInfo calculateNakshatraFromLongitude(double longitude) {
    var normalizedLongitude = longitude % 360;
    if (normalizedLongitude < 0) normalizedLongitude += 360;

    const nakshatraWidth = 360.0 / 27;
    final nakshatraNumber = (normalizedLongitude / nakshatraWidth).floor() + 1;
    final name = NakshatraInfo.nakshatraNames[nakshatraNumber - 1];
    final rulingPlanet = NakshatraInfo.nakshatraLords[nakshatraNumber - 1];

    final positionInNakshatra = normalizedLongitude % nakshatraWidth;
    final pada = (positionInNakshatra / (nakshatraWidth / 4)).floor() + 1;

    return NakshatraInfo(
      number: nakshatraNumber,
      name: name,
      rulingPlanet: rulingPlanet,
      longitude: normalizedLongitude,
      pada: pada,
      isAbhijit: false,
      abhijitPortion: 0.0,
    );
  }

  NakshatraInfo _calculateNakshatraWithAbhijit(double longitude) {
    var normalizedLongitude = longitude % 360;
    if (normalizedLongitude < 0) normalizedLongitude += 360;

    final isAbhijit = normalizedLongitude >= NakshatraInfo.abhijitStart &&
        normalizedLongitude < NakshatraInfo.abhijitEnd;

    int nakshatraNumber;
    String name;
    Planet rulingPlanet;

    if (isAbhijit) {
      nakshatraNumber = 28;
      name = 'Abhijit';
      rulingPlanet = Planet.sun;
    } else {
      const nakshatraWidth = 360.0 / 27;
      nakshatraNumber = (normalizedLongitude / nakshatraWidth).floor() + 1;
      name = NakshatraInfo.nakshatraNames[nakshatraNumber - 1];
      rulingPlanet = NakshatraInfo.nakshatraLords[nakshatraNumber - 1];
    }

    const nakshatraWidth = 360.0 / 27;
    final positionInNakshatra = normalizedLongitude % nakshatraWidth;
    final pada = (positionInNakshatra / (nakshatraWidth / 4)).floor() + 1;

    final abhijitPortion = isAbhijit
        ? (normalizedLongitude - NakshatraInfo.abhijitStart) /
            (NakshatraInfo.abhijitEnd - NakshatraInfo.abhijitStart)
        : 0.0;

    return NakshatraInfo(
      number: nakshatraNumber,
      name: name,
      rulingPlanet: rulingPlanet,
      longitude: normalizedLongitude,
      pada: pada,
      isAbhijit: isAbhijit,
      abhijitPortion: abhijitPortion,
    );
  }

  /// Every lunar month that begins within [year], in chronological order.
  ///
  /// The list is driven by real month boundaries (new moons for Amanta, full
  /// moons for Purnimanta) instead of by fixed solar intervals, so no month is
  /// skipped or repeated and a leap year correctly yields 13 months.
  Future<List<MasaInfo>> getMasaListForYear({
    required int year,
    required GeographicLocation location,
    MasaType type = MasaType.amanta,
  }) async {
    final masaList = <MasaInfo>[];

    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year + 1, 1, 1);

    // _findMasaStart returns the boundary at or before the given instant, so
    // step forward while that boundary still belongs to the previous year.
    var monthStart = await _findMasaStart(yearStart, location, type);
    while (monthStart.isBefore(yearStart)) {
      monthStart = await _findNextMasaStart(monthStart, location, type);
    }

    while (monthStart.isBefore(yearEnd)) {
      // Noon of the first day of the month: unambiguously inside the month.
      final masa = await calculateMasa(
        dateTime: monthStart.add(const Duration(hours: 12)),
        location: location,
        type: type,
      );
      masaList.add(masa);

      final nextMonthStart = await _findNextMasaStart(
        monthStart,
        location,
        type,
      );
      if (!nextMonthStart.isAfter(monthStart)) break; // safety net
      monthStart = nextMonthStart;
    }

    return masaList;
  }

  /// Gets the Hindu season (Ritu) based on the lunar month.
  ///
  /// In Vedic tradition, the year is divided into six seasons (Ritus),
  /// each associated with specific lunar months:
  /// - Vasanta (Spring): Chaitra, Vaishakha
  /// - Grishma (Summer): Jyeshtha, Ashadha
  /// - Varsha (Monsoon): Shravana, Bhadrapada
  /// - Sharad (Autumn): Ashwin, Kartika
  /// - Hemanta (Pre-winter): Margashirsha, Pausha
  /// - Shishira (Winter): Magha, Phalguna
  ///
  /// [masaInfo] - The MasaInfo containing the lunar month
  ///
  /// Returns the corresponding Ritu
  Ritu getRitu(MasaInfo masaInfo) {
    return switch (masaInfo.month) {
      LunarMonth.chaitra || LunarMonth.vaishakha => Ritu.vasanta,
      LunarMonth.jyeshtha || LunarMonth.ashadha => Ritu.grishma,
      LunarMonth.shravana || LunarMonth.bhadrapada => Ritu.varsha,
      LunarMonth.ashwin || LunarMonth.kartika => Ritu.sharad,
      LunarMonth.margashirsha || LunarMonth.pausha => Ritu.hemanta,
      LunarMonth.magha || LunarMonth.phalguna => Ritu.shishira,
    };
  }

  /// Gets Ritu details for a specific date.
  ///
  /// [dateTime] - The date to check
  /// [location] - Geographic location
  ///
  /// Returns detailed Ritu information
  Future<RituInfo> getRituDetails({
    required DateTime dateTime,
    required GeographicLocation location,
  }) async {
    final masa = await calculateMasa(dateTime: dateTime, location: location);

    final ritu = getRitu(masa);

    return RituInfo(
      ritu: ritu,
      masa: masa,
      description: ritu.description,
      characteristics: ritu.characteristics,
      governingElement: ritu.governingElement,
    );
  }

  /// Kartikadi (Gujarati) samvat rolls over at Kartika Shukla 1, about one
  /// month before the Chaitradi samvat rolls over at Chaitra Shukla 1. Both
  /// epochs are classified on the *Purnimanta* month: the purnimanta Kartika
  /// month ends on the Purnima that immediately precedes Kartika Shukla 1, so
  /// "Kartika with a Krishna Paksha" is exactly the span that still belongs to
  /// the outgoing Kartikadi year, and "Kartika with a Shukla Paksha" the span
  /// that already belongs to the new one.
  ///
  /// The Kartikadi year therefore runs one year BEHIND the Chaitradi year from
  /// Chaitra up to Kartika (roughly March to November) and is equal to it from
  /// Kartika up to Chaitra (roughly November to March).
  Future<SamvatInfo> getSamvatInfo({
    required DateTime dateTime,
    required GeographicLocation location,
  }) async {
    final masa = await calculateMasa(
      dateTime: dateTime,
      location: location,
      type: MasaType.purnimanta,
    );

    final int gregorianYear = dateTime.year;
    bool beforeChaitra = false;

    if (dateTime.month < 3) {
      beforeChaitra = true;
    } else if (dateTime.month == 3 || dateTime.month == 4) {
      if (masa.month == LunarMonth.phalguna ||
          masa.month == LunarMonth.magha ||
          masa.month == LunarMonth.pausha ||
          masa.month == LunarMonth.margashirsha) {
        beforeChaitra = true;
      }
      // The purnimanta Chaitra month opens with a Krishna Paksha that ends on
      // Chaitra Shukla 1, so the whole of it is still the outgoing year.
      if (masa.month == LunarMonth.chaitra &&
          masa.tithiInfo.paksha == Paksha.krishna) {
        beforeChaitra = true;
      }
    }

    final int vikramSamvat = gregorianYear + (beforeChaitra ? 56 : 57);
    final int shakaSamvat = gregorianYear - (beforeChaitra ? 79 : 78);
    int gujaratiSamvat = vikramSamvat;

    // Still within the Kartikadi year that has not started yet: Chaitra to
    // Ashwin, plus the Krishna Paksha of Kartika.
    bool beforeKartika = false;
    if (masa.month == LunarMonth.chaitra ||
        masa.month == LunarMonth.vaishakha ||
        masa.month == LunarMonth.jyeshtha ||
        masa.month == LunarMonth.ashadha ||
        masa.month == LunarMonth.shravana ||
        masa.month == LunarMonth.bhadrapada ||
        masa.month == LunarMonth.ashwin) {
      beforeKartika = true;
    } else if (masa.month == LunarMonth.kartika &&
        masa.tithiInfo.paksha == Paksha.krishna) {
      beforeKartika = true;
    }

    // Chaitra -> Kartika: Kartikadi lags the Chaitradi year by one. Outside
    // that span (Kartika -> Chaitra) the two run equal, and once Kartikadi has
    // rolled over Chaitradi has not, so both flags can never be true.
    if (beforeKartika && !beforeChaitra) {
      gujaratiSamvat = vikramSamvat - 1;
    }

    final samvatsaraName = await getSamvatsara(
      dateTime: dateTime,
      location: location,
    );
    const cycleStartYear = 1987;
    final samvatsaraNumber = ((dateTime.year - cycleStartYear) % 60 + 60) % 60;

    return SamvatInfo(
      vikramSamvat: vikramSamvat,
      shakaSamvat: shakaSamvat,
      gujaratiSamvat: gujaratiSamvat,
      samvatsaraName: samvatsaraName,
      samvatsaraNumber: samvatsaraNumber,
    );
  }

  Future<Ayana> getAyana({
    required DateTime dateTime,
    required GeographicLocation location,
  }) async {
    final defaultFlags = CalculationFlags.defaultFlags();
    final sunPos = await _ephemerisService.calculatePlanetPosition(
      planet: Planet.sun,
      dateTime: dateTime,
      location: location,
      flags: defaultFlags,
    );

    final ayanamsa = await _ephemerisService.getAyanamsa(
      dateTime: dateTime,
      mode: defaultFlags.siderealMode,
    );

    final tropicalLongitude = (sunPos.longitude + ayanamsa) % 360;

    if (tropicalLongitude >= 270 || tropicalLongitude < 90) {
      return Ayana.uttarayana;
    } else {
      return Ayana.dakshinayana;
    }
  }

  Future<PravishteInfo> getPravishte({
    required DateTime dateTime,
    required GeographicLocation location,
  }) async {
    final flags = CalculationFlags.defaultFlags();
    final sunPos = await _ephemerisService.calculatePlanetPosition(
      planet: Planet.sun,
      dateTime: dateTime,
      location: location,
      flags: flags,
    );

    final sunLongitude = sunPos.longitude;
    final rashiIndex = (sunLongitude / 30).floor();

    const rashiNames = [
      'Mesha',
      'Vrishabha',
      'Mithuna',
      'Karka',
      'Simha',
      'Kanya',
      'Tula',
      'Vrishchika',
      'Dhanu',
      'Makara',
      'Kumbha',
      'Meena',
    ];

    final monthName = rashiNames[rashiIndex];
    final degreesInSign = sunLongitude % 30;
    final dayNumber = (degreesInSign / 0.9856).floor() + 1;

    return PravishteInfo(day: dayNumber, monthName: monthName);
  }
}
