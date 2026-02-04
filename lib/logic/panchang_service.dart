import 'package:jyotish/jyotish.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';
import 'custom_chart_service.dart';
import '../core/ayanamsa_calculator.dart';
import '../core/settings_manager.dart';

class PanchangResult {
  final String date;
  final String tithi;
  final int tithiNumber;
  final String nakshatra;
  final int nakshatraNumber;
  final String yoga;
  final int yogaNumber;
  final String karana;
  final String vara;

  PanchangResult({
    required this.date,
    required this.tithi,
    required this.tithiNumber,
    required this.nakshatra,
    required this.nakshatraNumber,
    required this.yoga,
    required this.yogaNumber,
    required this.karana,
    required this.vara,
  });
}

class PanchangService {
  final CustomChartService _chartService = CustomChartService();

  Future<PanchangResult> getPanchang(
    DateTime dateTime,
    Location location,
  ) async {
    // Get Ayanamsa from settings
    final ayanamsaName = SettingsManager().chartSettings.ayanamsaSystem;
    final ayanamsaSystem = AyanamsaCalculator.getSystem(ayanamsaName);
    final mode = ayanamsaSystem?.mode ?? SiderealMode.lahiri;

    // Calculate chart properties
    final chart = await _chartService.calculateChart(
      dateTime: dateTime,
      location: GeographicLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        altitude: 0,
      ),
      ayanamsaMode: mode,
    );

    // Get Planet Positions
    final sunLong = chart.planets[Planet.sun]?.position.longitude ?? 0;
    final moonLong = chart.planets[Planet.moon]?.position.longitude ?? 0;

    // 1. Tithi Calculation
    // Tithi = (Moon Longitude - Sun Longitude) / 12
    double diff = moonLong - sunLong;
    if (diff < 0) diff += 360;

    // Tithi index 0-29. 1-15 Shukla (Waxing), 16-30 Krishna (Waning)
    int tithiIndex = (diff / 12).floor();
    // Tithi number 1-30
    int tithiNumber = tithiIndex + 1;

    // 2. Nakshatra Calculation
    // Nakshatra = Moon Longitude / 13.3333
    int nakshatraIndex = (moonLong / 13.333333333).floor();
    int nakshatraNumber = nakshatraIndex + 1;

    // 3. Yoga Calculation
    // Yoga = (Sun Longitude + Moon Longitude) / 13.3333
    double sum = sunLong + moonLong;
    if (sum > 360) sum -= 360;
    int yogaIndex = (sum / 13.333333333).floor();
    int yogaNumber = yogaIndex + 1;

    // 4. Karana Calculation
    // Karana is half of a Tithi (6 degrees)
    // There are 60 Karanas in a lunar month
    int karanaIndex = (diff / 6).floor();
    // 11 Karanas repeat.
    // Fixed: Shakuni, Chatushpada, Naga, Kimstughna
    // Movable: Bava, Balava, Kaulava, Taitila, Gara, Vanija, Vishti

    // 5. Vara (Weekday)
    String vara = DateFormat('EEEE').format(dateTime);

    return PanchangResult(
      date: DateFormat('dd MMMM yyyy, HH:mm').format(dateTime),
      tithi: _getTithiName(tithiIndex),
      tithiNumber: tithiNumber,
      nakshatra: _getNakshatraName(nakshatraIndex),
      nakshatraNumber: nakshatraNumber,
      yoga: _getYogaName(yogaIndex),
      yogaNumber: yogaNumber,
      karana: _getKaranaName(karanaIndex),
      vara: vara,
    );
  }

  String _getTithiName(int index) {
    // 0-14: Shukla Paksha (Pratipada to Purnima)
    // 15-29: Krishna Paksha (Pratipada to Amavasya)
    final paksha = index < 15 ? 'Shukla' : 'Krishna';
    final tithiInPaksha = (index % 15) + 1;

    const names = [
      'Pratipada',
      'Dwitiya',
      'Tritiya',
      'Chaturthi',
      'Panchami',
      'Shashthi',
      'Saptami',
      'Ashtami',
      'Navami',
      'Dashami',
      'Ekadashi',
      'Dwadashi',
      'Trayodashi',
      'Chaturdashi',
      'Purnima/Amavasya',
    ];

    var name = names[tithiInPaksha - 1];
    if (index == 14) name = 'Purnima';
    if (index == 29) name = 'Amavasya';

    return '$paksha $name';
  }

  String _getNakshatraName(int index) {
    const nakshatras = [
      'Ashwini',
      'Bharani',
      'Krittika',
      'Rohini',
      'Mrigashira',
      'Ardra',
      'Punarvasu',
      'Pushya',
      'Ashlesha',
      'Magha',
      'Purva Phalguni',
      'Uttara Phalguni',
      'Hasta',
      'Chitra',
      'Swati',
      'Vishakha',
      'Anuradha',
      'Jyeshtha',
      'Mula',
      'Purva Ashadha',
      'Uttara Ashadha',
      'Shravana',
      'Dhanishta',
      'Shatabhisha',
      'Purva Bhadrapada',
      'Uttara Bhadrapada',
      'Revati',
    ];
    return nakshatras[index % 27];
  }

  String _getYogaName(int index) {
    const yogas = [
      'Vishkambha',
      'Priti',
      'Ayushman',
      'Saubhagya',
      'Sobhana',
      'Atiganda',
      'Sukarma',
      'Dhriti',
      'Shoola',
      'Ganda',
      'Vriddhi',
      'Dhruva',
      'Vyaghata',
      'Harshana',
      'Vajra',
      'Siddhi',
      'Vyatipata',
      'Variyan',
      'Parigha',
      'Shiva',
      'Siddha',
      'Sadhya',
      'Shubha',
      'Shukla',
      'Brahma',
      'Indra',
      'Vaidhriti',
    ];
    return yogas[index % 27];
  }

  String _getKaranaName(int index) {
    // Karana logic is a bit complex cycling through the 7 movable ones
    // But for a simple display we can map the index 0-59 to the names.
    // 1-57 are movable (repeating 7), 58, 59, 60, 0 are fixed.

    // There are 4 Fixed Karanas:
    // 1. Shakuni (2nd half of Krishna Chaturdashi) -> Index 57
    // 2. Chatushpada (1st half of Amavasya) -> Index 58
    // 3. Naga (2nd half of Amavasya) -> Index 59
    // 4. Kimstughna (1st half of Shukla Pratipada) -> Index 0

    if (index == 0) return 'Kimstughna';
    if (index == 57) return 'Shakuni';
    if (index == 58) return 'Chatushpada';
    if (index == 59) return 'Naga';

    // Remaining 1-56 cycle through 7 movable karanas
    // Sequence: Bava, Balava, Kaulava, Taitila, Gara, Vanija, Vishti

    int adjustedIndex = (index - 1) % 7;
    const movableKaranas = [
      'Bava',
      'Balava',
      'Kaulava',
      'Taitila',
      'Gara',
      'Vanija',
      'Vishti',
    ];

    return movableKaranas[adjustedIndex];
  }
}
