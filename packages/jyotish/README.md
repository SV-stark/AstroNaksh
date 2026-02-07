# Jyotish (SV-stark Fork)

> [!NOTE]  
> This project is a **fork** of the original [jyotish-flutter-library](https://github.com/rajsanjib/jyotish-flutter-library). It builds upon the core high-precision Swiss Ephemeris integration and adds significant advanced Vedic astrology features.

A production-ready Flutter library for advanced Vedic astrology calculations using Swiss Ephemeris. Provides high-precision sidereal planetary positions with Lahiri ayanamsa for authentic Jyotish applications.

[![GitHub](https://img.shields.io/badge/GitHub-SV--stark%2Fjyotish--flutter--library--fork-blue?logo=github)](https://github.com/SV-stark/jyotish-flutter-library-fork)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.0.0-blue?logo=flutter)](https://flutter.dev)

## Core Features

✨ **High-Precision Sidereal Calculations**: Uses Swiss Ephemeris with Lahiri ayanamsa for accurate Vedic astrology.

🌍 **Authentic Vedic System**:
- Sidereal zodiac with support for 40+ ayanamsas.
- Geocentric and topocentric calculations.

🪐 **Comprehensive Planet Support**:
- Traditional Vedic planets + Rahu and Ketu.
- Optional outer planets (Uranus, Neptune, Pluto).
- Lunar apogees and asteroids.

## Advanced Vedic Features (Fork Additions)

This fork significantly extends the original library with high-level astrological services:

- **🔮 Varga Charts**: Support for all 16 major divisional charts (D1 to D60) plus D249 (249 subdivisions) for ultra-precise micro-level analysis.
- **⏳ Dasha Systems**: Vimshottari (120y), Yogini (36y), Ashtottari (108y), Kalachakra, Chara, and Narayana Dasha support.
- **✨ Panchanga**: Tithi, Yoga, Karana, Vara, and precise Sunrise/Sunset modules.
- **📊 Ashtakavarga**: Full BAV/SAV point system, Trikona Shodhana (reduction), and transit strength analysis.
- **⚖️ Shadbala & Bhava Bala**: Complete 6-fold planetary strength calculation and House Strength (Bhava Bala).
- **🤝 Planetary Friendship**: Logic for temporary (Tatkalika) and permanent (Naisargika) friendship status.
- **🎯 KP System**: Significators, Sub-Lord, and Sub-Sub-Lord logic with precise KP-specific ayanamsa calculation.
- **🪐 Special Transits**: Automated analysis for Sade Sati, Dhaiya, and Panchak.
- **📅 Muhurta**: Auspicious timings via Hora, Choghadiya, and Kalam analysis.
- **🎡 Sudarshan Chakra**: Triple-perspective strength analysis from Lagna, Moon, and Sun.
- **🧘 Jaimini Astrology**: Atmakaraka, Karakamsa, Arudha Lagna (AL), Upapada (UL), and Chara/Narayana Dashas.
- **❓ Prashna (Horary)**: Arudha calculation (1-249), Sphutas, and Gulika.

✨ **New Vedic Modules**:

- **Panchanga**: Tithi, Yoga, Karana, Vara, and Sunrise/Sunset
- **Ashtakavarga**: Bhinna and Sarvashtakavarga, transit strength analysis
- **KP System (Krishnamurti Paddhati)**: Significators, Sub-Lord, and Sub-Sub-Lord calculations
- **Special Transits**: Sade Sati, Dhaiya (Panoti), and Panchak analysis
- **Muhurta**: Hora, Choghadiya, and Inauspicious periods (Rahukalam, Gulikalam, Yamagandam)
- **Sudarshan Chakra**: Strength analysis from Lagna, Moon, and Sun perspectives.
- **Jaimini**: Karakas, Arudhas, and Rashi Drishti.
- **Prashna**: Horary astrology calculations.

🎯 **Easy to Use**: Simple, intuitive API designed for Vedic astrology

🔒 **Production Ready**: Proper error handling, input validation, and resource management

## Platform Support

| Platform | Support |
| -------- | ------- |
| Android  | ✅      |
| iOS      | ✅      |
| macOS    | ✅      |
| Linux    | ✅      |
| Windows  | ✅      |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  jyotish:
    git:
      url: https://github.com/rajsanjib/jyotish-flutter-library.git
      ref: main # or specify a tag/branch
```

Then run:

```bash
flutter pub get
```

### Alternative Installation Methods

You can also specify a specific version or branch:

**Using a specific tag/version:**

```yaml
dependencies:
  jyotish:
    git:
      url: https://github.com/rajsanjib/jyotish-flutter-library.git
      ref: v1.0.0 # Replace with desired version tag
```

**Using a specific branch:**

```yaml
dependencies:
  jyotish:
    git:
      url: https://github.com/rajsanjib/jyotish-flutter-library.git
      ref: develop # or any other branch
```

**For local development:**

```yaml
dependencies:
  jyotish:
    path: ../path/to/jyotish # Relative path to local library
```

### Swiss Ephemeris Data Files

The library requires Swiss Ephemeris data files for calculations. You have two options:

1. **Include data files in your app** (recommended for production):

   - Download ephemeris files from [Swiss Ephemeris](https://www.astro.com/ftp/swisseph/ephe/)
   - Place them in your app's assets folder
   - Initialize with the path to the data files

2. **Use built-in ephemeris** (limited accuracy):
   - The library includes a basic ephemeris for quick testing
   - Not recommended for production use

## Usage

### Basic Example

```dart
import 'package:jyotish/jyotish.dart';

void main() async {
  // Create an instance
  final jyotish = Jyotish();

  // Initialize the library
  await jyotish.initialize();

  // Define a location
  final location = GeographicLocation(
    latitude: 27.7172,  // Kathmandu, Nepal
    longitude: 85.3240,
    altitude: 1400,
  );

  // Calculate Sun's position (always sidereal with Lahiri ayanamsa)
  final sunPosition = await jyotish.getPlanetPosition(
    planet: Planet.sun,
    dateTime: DateTime.now(),
    location: location,
  );

  print('Sun is at ${sunPosition.formattedPosition}'); // Sidereal position
  print('Longitude: ${sunPosition.longitude}°');
  print('Nakshatra: ${sunPosition.nakshatra}');
  print('Is Retrograde: ${sunPosition.isRetrograde}');

  // Clean up
  jyotish.dispose();
}
```

### Calculate Multiple Planets

```dart
// Calculate all traditional Vedic planets at once
final positions = await jyotish.getAllPlanetPositions(
  dateTime: DateTime(2024, 1, 1, 12, 0),
  location: location,
);

for (final entry in positions.entries) {
  print('${entry.key.displayName}: ${entry.value.formattedPosition}');
}
```

### Custom Ayanamsa

```dart
// Use a different ayanamsa (default is Lahiri)
final flags = CalculationFlags.sidereal(SiderealMode.krishnamurti);

final position = await jyotish.getPlanetPosition(
  planet: Planet.moon,
  dateTime: DateTime.now(),
  location: location,
  flags: flags,
);
```

### Advanced: Custom Calculation Flags

```dart
// Create custom calculation flags
final flags = CalculationFlags(
  siderealMode: SiderealMode.krishnamurti,
  useTopocentric: true,
  calculateSpeed: true,
);

final position = await jyotish.getPlanetPosition(
  planet: Planet.mars,
  dateTime: DateTime.now(),
  location: location,
  flags: flags,
);
```

### Choosing Mean Node vs True Node (Rahu)

By default, the library uses **Mean Node** (Planet.meanNode) for Rahu calculations. However, you can switch to **True Node** for greater precision:

```dart
// Calculate chart with True Node (modern preference)
final flags = CalculationFlags.withNodeType(NodeType.trueNode);

final chart = await jyotish.calculateVedicChart(
  dateTime: DateTime(1990, 5, 15, 14, 30),
  location: location,
  flags: flags,
);

print('Rahu Position: ${chart.rahu.position.formattedPosition}');
print('Rahu Nakshatra: ${chart.rahu.position.nakshatra}');

// Or use NodeType directly with any API that accepts flags
final customFlags = CalculationFlags(
  siderealMode: SiderealMode.krishnamurti,
  nodeType: NodeType.trueNode,
);

// Get position of True Node directly
final trueNodePos = await jyotish.getPlanetPosition(
  planet: Planet.trueNode,
  dateTime: DateTime.now(),
  location: location,
);
```

**When to use each:**
- **Mean Node (default)**: Traditional Vedic astrology standard, smoother motion
- **True Node**: Modern preference, actual position with retrograde motion variations

### Vedic Astrology Chart

```dart
// Calculate a complete Vedic astrology birth chart
final chart = await jyotish.calculateVedicChart(
  dateTime: DateTime(1990, 5, 15, 14, 30), // Birth time
  location: location, // Birth place
);

// Access Ascendant (Lagna)
print('Ascendant: ${chart.ascendantSign}');
print('Ascendant Degree: ${chart.ascendant}°');

// Access planetary positions with Vedic-specific data
final sunInfo = chart.getPlanet(Planet.sun);
if (sunInfo != null) {
  print('Sun in ${sunInfo.zodiacSign}');
  print('House: ${sunInfo.house}');
  print('Nakshatra: ${sunInfo.nakshatra} (Pada ${sunInfo.pada})');
  print('Dignity: ${sunInfo.dignity.english}'); // e.g., "Exalted", "Debilitated"
  print('Combust: ${sunInfo.isCombust}');
}

// Access Rahu (North Node) and Ketu (South Node)
print('Rahu in ${chart.rahu.zodiacSign} - House ${chart.rahu.house}');
print('Ketu in ${chart.ketu.zodiacSign} - always 180° from Rahu');

// Get planets by house
final firstHousePlanets = chart.getPlanetsInHouse(1);

// Get planets by dignity
final exaltedPlanets = chart.exaltedPlanets;
final debilitatedPlanets = chart.debilitatedPlanets;
final combustPlanets = chart.combustPlanets;
final retrogradePlanets = chart.retrogradePlanets;

// Access house cusps
for (int i = 0; i < 12; i++) {
  print('House ${i + 1}: ${chart.houses.cusps[i]}°');
}
```

### Aspect Calculations (Graha Drishti)

```dart
// Calculate planetary aspects
final aspects = await jyotish.getAspects(
  dateTime: DateTime.now(),
  location: location,
);

for (final aspect in aspects) {
  print('${aspect.aspectingPlanet.displayName} aspects ${aspect.aspectedPlanet.displayName}');
  print('Type: ${aspect.type.name}'); // e.g., conjunction, opposition, marsSpecial4th
  print('Orb: ${aspect.orb.toStringAsFixed(2)}°');
}

// Get aspects for a specific planet
final marsAspects = await jyotish.getAspectsForPlanet(
  planet: Planet.mars,
  dateTime: DateTime.now(),
  location: location,
);
```

### Divisional Charts (Varga)

```dart
// 1. Calculate the base Rashi chart (D1)
final d1Chart = await jyotish.calculateVedicChart(
  dateTime:  DateTime(1990, 5, 15, 14, 30),
  location: location,
);

// 2. generate any divisional chart (D2-D60, D249)
// Example: Navamsa (D9) - Critical for marriage/dharma
final navamsa = jyotish.getDivisionalChart(
  rashiChart: d1Chart,
  type: DivisionalChartType.d9,
);

print('Navamsa Ascendant: ${navamsa.ascendantSign}');
print('Sun in D9: ${navamsa.getPlanet(Planet.sun)?.zodiacSign}');

// Example: Dasamsa (D10) - Critical for career
final dasamsa = jyotish.getDivisionalChart(
  rashiChart: d1Chart,
  type: DivisionalChartType.d10,
);

// Example: D249 - Ultra-fine micro analysis (249 subdivisions per sign)
final d249 = jyotish.getDivisionalChart(
  rashiChart: d1Chart,
  type: DivisionalChartType.d249,
);
print('D249 Ascendant: ${d249.ascendantSign}');
print('Sun in D249: ${d249.getPlanet(Planet.sun)?.zodiacSign}');
```

### Dasha System Support

```dart
// Calculate Vimshottari Dasha
final vimshottari = await jyotish.getVimshottariDasha(
  natalChart: d1Chart,
  levels: 3, // Mahadasha, Antardasha, Pratyantardasha
);

// Get current period
final now = DateTime.now();
final currentPeriod = vimshottari.getCurrentDasha(date: now);

print('Current Dasha Period:');
print('MD: ${currentPeriod.lord.displayName}'); // Mahadasha

// Calculate Yogini Dasha
final yogini = await jyotish.getYoginiDasha(
  natalChart: d1Chart,
  levels: 2,
);

// Calculate Ashtottari Dasha (108 years)
final ashtottari = await jyotish.getAshtottariDasha(
  natalChart: d1Chart,
);

// Calculate Kalachakra Dasha
final kalachakra = await jyotish.getKalachakraDasha(
  natalChart: d1Chart,
);

// Calculate Narayana Dasha (Jaimini)
final narayana = await jyotish.getNarayanaDasha(
  chart: d1Chart,
);

```

### Transit Calculations

```dart
// Check transits relative to natal chart
final transits = await jyotish.getTransitPositions(
  natalChart: d1Chart,
  transitDateTime: DateTime.now(),
  location: location,
);

final saturnTransit = transits[Planet.saturn];
print('Saturn is transiting House ${saturnTransit?.transitHouse}');

// Find specific transit events
final events = await jyotish.getTransitEvents(
  natalChart: d1Chart,
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 365)),
  location: location,
  planets: [Planet.jupiter, Planet.saturn], // Track major planets
);

for (final event in events) {
  print('${event.description} on ${event.exactDate}');
}
```

### Panchanga calculations

```dart
// Calculate daily Panchanga
final panchanga = await jyotish.calculatePanchanga(
  dateTime: DateTime.now(),
  location: location,
);

print('Tithi: ${panchanga.tithi.name}');
print('Yoga: ${panchanga.yoga.name}');
print('Karana: ${panchanga.karana.name}');
print('Vara: ${panchanga.vara.name}'); // Weekday name (e.g., "Monday")
print('Day Lord: ${panchanga.vara.rulingPlanet.displayName}'); // Planetary lord
print('Sunrise: ${panchanga.sunrise}');

// New: Find exact Tithi end time
final tithiEnd = await jyotish.getTithiEndTime(
  dateTime: DateTime.now(),
  location: location,
);
print('Current Tithi ends at: $tithiEnd');
```

### Ashtakavarga analysis

```dart
// Calculate Ashtakavarga from a birth chart
final ashtakavarga = jyotish.calculateAshtakavarga(d1Chart);

// Get SAV (Sarvashtakavarga) points for 1st house
print('1st House Points: ${ashtakavarga.getTotalBindusForHouse(1)}');

// Analyze transit strength
final transitStrength = jyotish.analyzeAshtakavargaTransit(
  ashtakavarga: ashtakavarga,
  transitPlanet: Planet.jupiter,
  transitSign: 5, // Virgo
);
print('Jupiter transit strength: ${transitStrength.strengthScore}%');
```

### KP System (Krishnamurti Paddhati)

```dart
// Calculate KP System data
final kpData = jyotish.calculateKPData(d1Chart);

// Get Sub-Lord for a planet
final sunDivision = kpData.planetDivisions[Planet.sun];
print('Sun Sub-Lord: ${sunDivision?.subLord.displayName}');

// Get planet significators (ABCD significators)
final sunSignificators = kpData.planetSignificators[Planet.sun];
print('Sun Significators: ${sunSignificators?.allSignificators}');

// Get house cusp Sub-Lord
final house1Division = kpData.houseDivisions[1];
print('House 1 Sub-Lord: ${house1Division?.subLord.displayName}');
```

### Special Transits (Sade Sati, etc.)

```dart
// Check for Sade Sati and Dhaiya
final specialTransits = await jyotish.calculateSpecialTransits(
  natalChart: d1Chart,
  location: location,
);

if (specialTransits.sadeSati.isActive) {
  print('Sade Sati Phase: ${specialTransits.sadeSati.phase?.name}');
}

if (specialTransits.panchak?.isActive ?? false) {
  print('Panchak is currently active');
}
```

### Muhurta and Auspicious Timing

```dart
// Calculate daily Muhurta
final muhurta = await jyotish.calculateMuhurta(
  date: DateTime.now(),
  location: location,
);

// Get current Choghadiya
final currentChoghadiya = muhurta.choghadiya.getPeriodForTime(DateTime.now());
print('Current Choghadiya: ${currentChoghadiya?.name} (${currentChoghadiya?.nature})');

// Check for inauspicious periods
if (muhurta.isCurrentlyInauspicious) {
  print('Active Period: ${muhurta.inauspiciousPeriods.getActivePeriod(DateTime.now())}');
}

// Find best Muhurta for an activity
final bestTimes = jyotish.findBestMuhurta(muhurta: muhurta, activity: 'marriage');
```

### Sudarshan Chakra Strength Analysis

```dart
// Calculate Sudarshan Chakra (Triple-perspective analysis)
final sudarshan = jyotish.calculateSudarshanChakra(d1Chart);

print('Overall Chart Strength: ${sudarshan.overallStrength.toStringAsFixed(1)}%');
print('Strong Houses: ${sudarshan.strongHouses}'); // Houses strong in all 3 views

// Calculate Bhava Bala (House Strength)
final bhavaBala = await jyotish.getBhavaBala(d1Chart);
print('10th House Strength: ${bhavaBala[10]?.totalStrength}');

```

### Abhijit Nakshatra Support

```dart
// Get Nakshatra with Abhijit detection
final nakshatra = await jyotish.getNakshatraWithAbhijit(
  dateTime: DateTime.now(),
  location: location,
);
print('Nakshatra: ${nakshatra.name} #${nakshatra.number}');
print('Ruler: ${nakshatra.rulingPlanet.displayName}');
print('Pada: ${nakshatra.pada}');

if (nakshatra.isAbhijit) {
  print('In auspicious Abhijit Nakshatra! (Portion: ${nakshatra.abhijitPortion.toStringAsFixed(2)})');
}

// Check if longitude is in Abhijit
final longitude = 280.0; // 280 degrees = 10° Capricorn
final isAbhijit = jyotish.isInAbhijitNakshatra(longitude);
print('Is in Abhijit: $isAbhijit');

// Get Abhijit boundaries
final (start, end) = jyotish.getAbhijitBoundaries();
print('Abhijit spans from ${start.toStringAsFixed(2)}° to ${end.toStringAsFixed(2)}°');
```

### Lunar Month (Masa) Calculations

```dart
// Get lunar month with Amanta system (Southern India, Gujarat)
final amantaMasa = await jyotish.getAmantaMasa(
  dateTime: DateTime.now(),
  location: location,
);
print('Month (Amanta): ${amantaMasa.displayName}');
print('Month Number: ${amantaMasa.monthNumber}');
print('Sun Longitude: ${amantaMasa.sunLongitude.toStringAsFixed(2)}°');
if (amantaMasa.adhikaType == AdhikaMasaType.adhika) {
  print('Adhika (Extra) Masa!');
}

// Get lunar month with Purnimanta system (Northern India)
final purnimantaMasa = await jyotish.getPurnimantaMasa(
  dateTime: DateTime.now(),
  location: location,
);
print('Month (Purnimanta): ${purnimantaMasa.displayName}');

// Get month with explicit type
final masa = await jyotish.getMasa(
  dateTime: DateTime.now(),
  location: location,
  type: MasaType.amanta, // or MasaType.purnimanta
);

// Get Samvatsara (60-year Jupiter cycle)
final samvatsara = await jyotish.getSamvatsara(
  dateTime: DateTime.now(),
  location: location,
);
print('Samvatsara: $samvatsara');

// Get list of all months for a year
final months = await jyotish.getMasaListForYear(
  year: 2024,
  location: location,
  type: MasaType.amanta,
);
for (final masa in months) {
  print('${masa.month.sanskrit}: ${masa.displayName}');
}
```

### Jaimini Astrology

```dart
// Get Atmakaraka (Soul Planet)
final ak = jyotish.getAtmakaraka(d1Chart);
print('Atmakaraka: ${ak.displayName}');

// Get Arudha Lagna (AL)
final al = jyotish.getArudhaLagna(d1Chart);
print('Arudha Lagna: ${al.name}');

// Get Karakamsa (Soul Planet in Navamsa)
final karakamsa = jyotish.getKarakamsa(
    rashiChart: d1Chart, 
    navamsaChart: navamsa
);
print('Karakamsa: ${karakamsa.sign.name}');
```

### Prashna (Horary) Astrology

```dart
// Calculate Arudha for a seed number (1-249)
final arudha = jyotish.calculatePrashnaArudha(108);
print('Prashna Arudha: ${arudha.name}');

// Calculate Sphutas
final sphutas = await jyotish.calculatePrashnaSphutas(d1Chart);
print('Trisphuta: ${sphutas.trisphuta.toStringAsFixed(2)}');
```
```

**Vedic Features:**

- ✨ Sidereal zodiac with Lahiri ayanamsa (authentic Vedic calculations)
- 🏠 Whole Sign house system
- 🌟 Rahu (North Node) and Ketu (South Node) as separate entities
- 🎯 Planetary dignities: Exalted, Debilitated, Own Sign, Moola Trikona, etc.
- 🔥 Combustion detection (planets too close to Sun)
- 📍 27 Nakshatras with pada (quarter) divisions
- ♃ Retrograde motion detection
- 🌍 Support for 40+ different ayanamsas (Lahiri, Krishnamurti, Raman, etc.)

**Note**: This library is designed specifically for Vedic astrology and uses sidereal calculations. All planetary positions are calculated in the sidereal zodiac, not tropical (Western astrology).

### Location from Degrees, Minutes, Seconds

```dart
final location = GeographicLocation.fromDMS(
  latDegrees: 27,
  latMinutes: 43,
  latSeconds: 1.92,
  isNorth: true,
  lonDegrees: 85,
  lonMinutes: 19,
  lonSeconds: 26.4,
  isEast: true,
  altitude: 1400,
);
```

## API Reference

### Main Classes

#### `Jyotish`

The main entry point for the library.

- `initialize({String? ephemerisPath})`: Initialize the library
- `getPlanetPosition(...)`: Calculate a single planet's position
- `getMultiplePlanetPositions(...)`: Calculate multiple planets
- `getAllPlanetPositions(...)`: Calculate all major planets
- `getVara(...)`: Get Vedic Vara (Day Lord) - **Async**
- `getTithiEndTime(...)`: Find precise Tithi end time - **New**
- `dispose()`: Clean up resources

**Abhijit Nakshatra Methods:**
- `getNakshatraWithAbhijit(...)`: Get nakshatra with 28th Abhijit support
- `isInAbhijitNakshatra(...)`: Check if longitude is in Abhijit (6°40' to 10°53'20" Capricorn)
- `getAbhijitBoundaries()`: Get start/end longitudes of Abhijit

**Lunar Month (Masa) Methods:**
- `getMasa(...)`: Calculate lunar month with Amanta/Purnimanta support
- `getAmantaMasa(...)`: Get lunar month using Amanta system (starts from New Moon)
- `getPurnimantaMasa(...)`: Get lunar month using Purnimanta system (starts from Full Moon)
- `getSamvatsara(...)`: Get 60-year Jupiter cycle (Samvatsara) name
- `getMasaListForYear(...)`: Get list of all lunar months for a year

#### `Planet` (enum)

Enumeration of supported celestial bodies.

Available planets:

- `Planet.sun`, `Planet.moon`
- `Planet.mercury`, `Planet.venus`, `Planet.mars`
- `Planet.jupiter`, `Planet.saturn`
- `Planet.uranus`, `Planet.neptune`, `Planet.pluto`
- `Planet.meanNode`, `Planet.trueNode`
- `Planet.chiron`, `Planet.ceres`, etc.

Static methods:

- `Planet.majorPlanets`: Sun through Pluto
- `Planet.traditionalPlanets`: Sun through Saturn
- `Planet.asteroids`: Chiron, Ceres, Pallas, Juno, Vesta

#### `PlanetPosition`

Contains calculated position data.

Properties:

- `longitude`: Ecliptic longitude (0-360°)
- `latitude`: Ecliptic latitude
- `distance`: Distance from Earth in AU
- `longitudeSpeed`: Degrees per day
- `zodiacSign`: Name of zodiac sign
- `positionInSign`: Degrees within sign (0-30°)
- `nakshatra`: Indian lunar mansion name
- `nakshatraPada`: Quarter of nakshatra (1-4)
- `isRetrograde`: Whether planet is in retrograde motion
- `formattedPosition`: Human-readable position string

#### `GeographicLocation`

Represents a location on Earth.

Properties:

- `latitude`: -90 to 90 (North positive)
- `longitude`: -180 to 180 (East positive)
- `altitude`: Meters above sea level

#### `CalculationFlags`

Controls calculation behavior.

Factory constructors:

- `CalculationFlags.defaultFlags()`: Tropical, geocentric
- `CalculationFlags.siderealLahiri()`: Sidereal with Lahiri ayanamsa
- `CalculationFlags.sidereal(SiderealMode)`: Custom sidereal mode
- `CalculationFlags.topocentric()`: Topocentric calculations

#### `SiderealMode` (enum)

Available ayanamsa systems for sidereal calculations.

Popular modes:

- `SiderealMode.lahiri`: Most common in Indian astrology
- `SiderealMode.faganBradley`: Western sidereal astrology
- `SiderealMode.krishnamurti`: KP astrology
- `SiderealMode.raman`: Raman ayanamsa
- 40+ other modes available

#### `NakshatraInfo`

Represents nakshatra information including Abhijit (28th nakshatra).

Properties:
- `number`: Nakshatra number (1-27 for standard, 28 for Abhijit)
- `name`: Nakshatra name (Sanskrit)
- `rulingPlanet`: Planet ruling the nakshatra
- `longitude`: Normalized longitude (0-360°)
- `pada`: Pada or quarter (1-4)
- `isAbhijit`: Whether currently in Abhijit nakshatra
- `abhijitPortion`: Portion through Abhijit (0.0-1.0, 0.0 if not in Abhijit)

Static Properties:
- `nakshatraNames`: List of all 28 nakshatra names
- `nakshatraLords`: List of ruling planets for each nakshatra
- `abhijitStart`: Start longitude of Abhijit (276.6666667°)
- `abhijitEnd`: End longitude of Abhijit (286.6666667°)
- `nakshatraDashaLords`: Map of nakshatra to Vimshottari dasha lords

#### `MasaInfo`

Represents lunar month (Masa) information.

Properties:
- `month`: Lunar month enum (Chaitra through Phalguna)
- `monthNumber`: Month number (1-12)
- `type`: MasaType (amanta or purnimanta)
- `adhikaType`: AdhikaMasaType (none, adhika, nija)
- `sunLongitude`: Sun's longitude in degrees
- `tithiInfo`: Current Tithi information
- `year`: Optional Samvatsara year number
- `isLunarLeapYear`: Whether it's a lunar leap year

Methods:
- `displayName`: Full display name including Adhika prefix if applicable

#### `MasaType` (enum)

Lunar month system types.
- `MasaType.amanta`: Month starts from Amavasya (New Moon) - Southern India, Gujarat
- `MasaType.purnimanta`: Month starts from Purnima (Full Moon) - Northern India

#### `LunarMonth` (enum)

The 12 lunar months in the Indian calendar.
- `LunarMonth.chaitra` through `LunarMonth.phalguna`
- Each month has `sanskrit` and `transliteration` properties

#### `AdhikaMasaType` (enum)

Adhika (extra) Masa status.
- `AdhikaMasaType.none`: Regular lunar month
- `AdhikaMasaType.adhika`: Extra leap month
- `AdhikaMasaType.nija`: Regular month in a year with Adhika

#### `Samvatsara`

Represents the 60-year Jupiter cycle.

Static Methods:
- `getSamvatsaraName(int yearIndex)`: Get Samvatsara name from year index
- `samvatsaraNames`: List of all 60 Samvatsara names (Prabhava to Akshaya)

#### `NodeType` (enum)

Lunar node type for Rahu/Ketu calculations.

- `NodeType.meanNode` - Uses Mean Node (default). This is the average position of Moon's orbit crossing. Preferred by traditional Vedic astrologers.
- `NodeType.trueNode` - Uses True Node. This is the actual position at the exact moment. Preferred by modern Vedic astrologers for greater precision.

Usage:
```dart
// Use True Node instead of Mean Node (default)
final flags = CalculationFlags.withNodeType(NodeType.trueNode);

final chart = await jyotish.calculateVedicChart(
  dateTime: DateTime.now(),
  location: location,
  flags: flags,
);

// Calculate specific planet with True Node
final rahuPosition = await jyotish.getPlanetPosition(
  planet: Planet.trueNode,
  dateTime: DateTime.now(),
  location: location,
);
```

Properties:
- `description`: Human-readable description
- `technicalDescription`: Technical explanation
  - `planet`: Returns the appropriate Planet enum (`Planet.meanNode` or `Planet.trueNode`)
 
#### `DivisionalChartType.d249`

D249 (249 Subdivisions) is a KP micro-level divisional chart that uses **Vimshottari Dasha proportional divisions**, NOT linear equal divisions.

**Important**: D249 is NOT a simple 1/249th division. Each subdivision's span is proportional to the dasha period of its ruling planet.

#### Key Characteristics:

1. **Proportional to Vimshottari Dasha**: Each subdivision's span is proportional to the dasha period of its ruling planet
2. **Total Subdivisions**: 249 = (27 complete cycles × 9 planets) + 6 extra subdivisions
3. **Pattern**: The 9-planet Vimshottari sequence repeats 27 times, with a partial 28th cycle

#### Vimshottari Dasha Proportions:

| Planet (Ruler) | Dash Period | Degree Span | Subdivisions per Sign |
|-----------------|------------|-------------|---------------------|
| Ketu | 7 years | 1.75° | 27 |
| Venus | 20 years | 5.0° | 54 |
| Sun | 6 years | 1.5° | 18 |
| Moon | 10 years | 2.5° | 27 |
| Mars | 7 years | 1.75° | 18 |
| Rahu | 18 years | 4.5° | 54 |
| Jupiter | 16 years | 4.0° | 48 |
| Saturn | 19 years | 4.75° | 48 |
| Mercury | 17 years | 4.25° | 51 |

**Complete Cycles**: 27 × 9 = 243 subdivisions  
**Partial 28th Cycle**: 6 subdivisions (Ketu through Rahu)  
**Total**: 243 + 6 = 249 subdivisions

#### Usage Example:

```dart
// Calculate D249 chart
final d249 = jyotish.getDivisionalChart(
  rashiChart: rashiChart,
  type: DivisionalChartType.d249,
);

// Check which subdivision a planet is in
final sunDivision = kpData.getPlanetSubLord(Planet.sun);
print('Sun in D249 subdivision: ${sunDivision?.subSpan.toStringAsFixed(4)}°');

// Works with both KP ayanamsas (already supported)
final kpOld = await jyotish.calculateKPData(
  natalChart: chart,
  useNewAyanamsa: false, // Old KP ayanamsa
);

final kpNew = await jyotish.calculateKPData(
  natalChart: chart,
  useNewAyanamsa: true, // KP New VP291 ayanamsa
);
```

#### Important Notes:

1. **KP Ayanamsa Support**: Both old and new KP ayanamsas are already supported via `useNewAyanamsa` parameter in `calculateKPData()`
2. **Node Type Compatibility**: Works with both Mean Node and True Node via `CalculationFlags.nodeType`
3. **Precision**: Provides 10-20x more precision than D9 (9 subdivisions) for micro-level analysis

## Error Handling

The library throws specific exception types:

```dart
try {
  final position = await jyotish.getPlanetPosition(...);
} on InitializationException catch (e) {
  print('Failed to initialize: $e');
} on CalculationException catch (e) {
  print('Calculation failed: $e');
} on ValidationException catch (e) {
  print('Invalid input: $e');
} on JyotishException catch (e) {
  print('General error: $e');
}
```

## Example App

Run the example app to see the library in action:

```bash
cd example
flutter run
```

The example app demonstrates:

- Calculating all major planet positions
- Switching between tropical and sidereal zodiac
- Displaying position in multiple formats
- Showing nakshatra and retrograde status

## Advanced Topics

### Custom Ephemeris Path

```dart
await jyotish.initialize(
  ephemerisPath: '/path/to/ephemeris/files',
);
```

### Topocentric vs Geocentric

Geocentric positions are calculated from Earth's center (default).
Topocentric positions are calculated from a specific location on Earth's surface.

```dart
final flags = CalculationFlags(useTopocentric: true);
```

### Understanding Ayanamsa

The ayanamsa is the difference between tropical and sidereal zodiac systems. Different systems use different reference points:

- **Lahiri**: Official ayanamsa of India
- **Fagan-Bradley**: Popular in Western sidereal astrology
- **Krishnamurti**: Used in KP system

Get current ayanamsa value:

```dart
final service = EphemerisService();
await service.initialize();
final ayanamsa = await service.getAyanamsa(
  dateTime: DateTime.now(),
  mode: SiderealMode.lahiri,
);
print('Lahiri Ayanamsa: ${ayanamsa.toStringAsFixed(6)}°');
```

## Performance Considerations

1. **Initialization**: Call `initialize()` once at app startup
2. **Batch Calculations**: Use `getMultiplePlanetPositions()` for multiple planets
3. **Caching**: Consider caching results if querying the same time repeatedly
4. **Resource Management**: Always call `dispose()` when done

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This library is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

Swiss Ephemeris is licensed under GNU GPL v2 or Swiss Ephemeris Professional License.

## Credits

This library uses:

- [Swiss Ephemeris](https://www.astro.com/swisseph/) by Astrodienst AG
- Developed with ❤️ for the Flutter community

## Support

- Issues: [GitHub Issues](https://github.com/SV-stark/jyotish-flutter-library-fork/issues)
- Original Repo: [rajsanjib/jyotish-flutter-library](https://github.com/rajsanjib/jyotish-flutter-library)

## Detailed Fork Additions Summary

This fork was created to bridge the gap between low-level astronomical calculations and high-level Vedic astrological analysis. The following modules were added entirely in this version:

### 1. Advanced Predictive Service
- **Vimshottari Dasha**: Full 120-year cycle with 5 levels of depth (Mahadasha to Sukshma Dasha) and refined Rahu/Ketu lordship logic.
- **Yogini Dasha**: 36-year cycle with accurate lord calculation and Nakshatra alignment.

### 2. Comprehensive Panchanga
- A complete Indian lunar calendar module providing **Tithi, Yoga, Karana, Vara**, and precise solar times (Sunrise/Sunset/Noon).
- **Corrected Vara**: Day lord now respects the **Sunrise boundary** as per traditional Vedic standards (births between midnight and sunrise use the previous day's lord).
- **Tithi Analysis**: New high-precision API for finding exact Tithi end times.

### 3. Strength & Relationship Systems
- **Shadbala**: Implementation of the complete 6-fold planetary strength system (Shadbala) including positional, directional, temporal, and motional strengths.
- **Planetary Relationships**: Automated determination of permanent and temporary friendships used for accurate dignity and strength analysis.

### 4. Mathematical Systems
- **Ashtakavarga**: Automated calculation of Bindus for all 7 planets (BAV) and the total system (SAV), including **Trikona Shodhana** (Trine Reduction) and transit strength analysis.
- **KP System**: Implementation of the Krishnamurti Paddhati, including high-precision significators, cuspal sub-lords, and precise KP ayanamsa formulas.
- **Divisional Charts (Varga)**: Calculations for all 16 major charts (D1-D60) plus D249 (249 subdivisions) with high-precision mapping rules for Saptamsa, Dasamsa, Shashtiamsa (D60), and 249-subdivision micro analysis.

### 5. Transit & Muhurta Analysis
- **Special Transits**: Real-time detection of Sade Sati, Dhaiya, and Panchak.
- **Muhurta Engine**: Daily Hora, Choghadiya, and inauspicious period (Rahu Kalam/Yamagandam) tracking.

### 6. Lunar Month (Masa) & Abhijit Nakshatra
- **Abhijit Nakshatra**: Full support for the 28th intercalary nakshatra (6°40' to 10°53'20" in Capricorn), including position checking and nakshatra calculation with Abhijit detection.
- **Lunar Month (Masa) Calculations**: Complete implementation of both Amanta and Purnimanta lunar month systems:
  - **Amanta (Amavasyanta)**: Month starts from Amavasya (New Moon). Used in Southern India, Gujarat, and other regions.
  - **Purnimanta (Suklanta)**: Month starts from Purnima (Full Moon). Used in Northern India.
- **Adhika Masa Detection**: Automatic detection of extra lunar months (leap months) in the lunar calendar.
- **Samvatsara**: Support for the 60-year Jupiter cycle (Samvatsara names from Prabhava to Akshaya).

### 7. Mean Node vs True Node (Rahu) Configuration
- **Configurable Node Type**: Full support for switching between Mean Node (traditional Vedic standard) and True Node (modern preference) for Rahu/Ketu calculations.
- **Global Setting via CalculationFlags**: Use `NodeType.meanNode` (default) for traditional calculations or `NodeType.trueNode` for greater precision with actual node positions.
- **Per-Call Flexibility**: Calculate specific charts with different node types without affecting global defaults.
- **Backward Compatible**: Mean Node remains the default to maintain compatibility with existing code and traditional astrologers.

---

Made with ❤️ using Swiss Ephemeris
