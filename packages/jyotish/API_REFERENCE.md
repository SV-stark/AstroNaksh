# Jyotish Library API Reference

A comprehensive API reference for the Jyotish Flutter library - production-ready Vedic astrology using Swiss Ephemeris.

---

## Table of Contents

- [Quick Start](#quick-start)
- [Core Classes](#core-classes)
  - [Jyotish](#jyotish)
  - [GeographicLocation](#geographiclocation)
  - [CalculationFlags](#calculationflags)
- [Services](#services)
  - [EphemerisService](#ephemerisservice)
  - [VedicChartService](#vedicchartservice)
  - [DashaService](#dashaservice)
  - [PanchangaService](#panchangaservice)
  - [AshtakavargaService](#ashtakavargaservice)
  - [AspectService](#aspectservice)
  - [TransitService](#transitservice)
  - [SpecialTransitService](#specialtransitservice)
  - [DivisionalChartService](#divisionalchartservice)
  - [ShadbalaService](#shadbalaservice)
  - [KPService](#kpservice)
  - [MuhurtaService](#muhurtaservice)
  - [MasaService](#masaservice)
  - [SudarshanChakraService](#sudarshanchakraservice)
  - [StrengthAnalysisService](#strengthanalysisservice)
  - [GocharaVedhaService](#gocharavedhaservice)
- [Models](#models)
  - [SudarshanChakraResult](#sudarshanchakraresult)
- [Enums](#enums)

---

## Quick Start

```dart
import 'package:jyotish/jyotish.dart';

// 1. Initialize
final jyotish = Jyotish();
await jyotish.initialize();

// 2. Define location
final location = GeographicLocation(
  latitude: 27.7172,   // Kathmandu, Nepal
  longitude: 85.3240,
  altitude: 1400,
  timezone: 'Asia/Kathmandu',
);

// 3. Calculate birth chart
final chart = await jyotish.calculateVedicChart(
  dateTime: DateTime(1990, 5, 15, 14, 30),
  location: location,
);

// 4. Access chart data
print('Ascendant: ${chart.ascendantSign}');
print('Moon: ${chart.getPlanet(Planet.moon)?.zodiacSign}');

// 5. Cleanup
jyotish.dispose();
```

---

## Core Classes

### Jyotish

The main entry point for all library operations. Provides a high-level API wrapping all services.

#### Initialization

```dart
final jyotish = Jyotish();
await jyotish.initialize({String? ephemerisPath});
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `ephemerisPath` | `String?` | No | Custom path to Swiss Ephemeris data files |

#### Planetary Position Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getPlanetPosition({planet, dateTime, location, flags?})` | `Future<PlanetPosition>` | Calculate single planet position |
| `getMultiplePlanetPositions({planets, dateTime, location, flags?})` | `Future<Map<Planet, PlanetPosition>>` | Calculate multiple planets |
| `getAllPlanetPositions({dateTime, location, flags?})` | `Future<Map<Planet, PlanetPosition>>` | All major planets (Sun-Pluto) |

#### Chart Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateVedicChart({dateTime, location, houseSystem?, includeOuterPlanets?, flags?})` | `Future<VedicChart>` | Complete Vedic birth chart |
| `getDivisionalChart({rashiChart, type})` | `VedicChart` | Calculate divisional chart (D1-D60, D249) |

#### Aspect Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getAspects({dateTime, location, config?})` | `Future<List<AspectInfo>>` | All planetary aspects |
| `getAspectsForPlanet({planet, dateTime, location})` | `Future<List<AspectInfo>>` | Aspects for specific planet |
| `getChartAspects(chart, {config?})` | `List<AspectInfo>` | Aspects within a chart |

#### Dasha Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getVimshottariDasha({natalChart, levels?})` | `Future<DashaResult>` | Vimshottari Dasha (120-year) |
| `getYoginiDasha({natalChart, levels?})` | `Future<DashaResult>` | Yogini Dasha (36-year) |
| `getCharaDasha({natalChart, levels?})` | `Future<CharaDashaResult>` | Chara Dasha (Jaimini) |
| `getNarayanaDasha({chart, levels?})` | `Future<NarayanaDashaResult>` | Narayana Dasha (Jaimini) |
| `getAshtottariDasha({natalChart, scheme?})` | `Future<AshtottariDashaResult>` | Ashtottari Dasha (108-year) |
| `getKalachakraDasha({natalChart})` | `Future<KalachakraDashaResult>` | Kalachakra Dasha |
| `getCurrentDasha({natalChart, targetDate, type?})` | `DashaPeriod` | Current active period |

#### Transit Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getTransitPositions({natalChart, transitDateTime?, location})` | `Future<Map<Planet, TransitInfo>>` | Transit positions vs natal |
| `getTransitEvents({natalChart, startDate, endDate, location, planets?})` | `Future<List<TransitEvent>>` | Transit events in date range |
| `calculateSpecialTransits({natalChart, checkDate?, location})` | `Future<SpecialTransits>` | Sade Sati, Dhaiya, Panchak |

#### Panchanga Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `calculatePanchanga({dateTime, location})` | `Future<Panchanga>` | Complete Panchanga (5 limbs) |
| `getTithi({dateTime, location})` | `Future<TithiInfo>` | Lunar day |
| `getTithiEndTime({dateTime, location, accuracyThreshold?})` | `Future<DateTime>` | Precise Tithi end time |
| `getYoga({dateTime, location})` | `Future<YogaInfo>` | Sun-Moon combination |
| `getKarana({dateTime, location})` | `Future<KaranaInfo>` | Half-Tithi |
| `getVara({dateTime, location})` | `Future<VaraInfo>` | Weekday/planetary lord |
| `getNakshatra({dateTime, location})` | `Future<NakshatraInfo>` | Moon's nakshatra |
| `getNakshatraWithAbhijit({dateTime, location})` | `Future<NakshatraInfo>` | With 28th nakshatra |

#### Ashtakavarga Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateAshtakavarga(natalChart)` | `Ashtakavarga` | Complete Ashtakavarga |
| `analyzeAshtakavargaTransit({ashtakavarga, transitPlanet, transitSign})` | `TransitAnalysis` | Transit strength analysis |
| `getAshtakavargaReductions(ashtakavarga, {trikonaReduction?, ekadhipatiReduction?})` | `Ashtakavarga` | Reduced Ashtakavarga |

#### KP System Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateKPData(natalChart, {useNewAyanamsa?})` | `KPCalculations` | Complete KP data |
| `getSubLord(longitude)` | `Planet` | Sub-Lord for longitude |
| `getSubSubLord(longitude)` | `Planet` | Sub-Sub-Lord |

#### Muhurta Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateMuhurta({date, location})` | `Future<Muhurta>` | Complete Muhurta |
| `getHoraPeriods({date, sunrise, sunset})` | `List<HoraPeriod>` | Planetary hours |
| `getCurrentHora({dateTime, location})` | `Future<HoraPeriod>` | Current planetary hour |
| `getHorasForDay({date, location})` | `Future<List<HoraPeriod>>` | All Horas for a day |
| `getChoghadiya({date, sunrise, sunset})` | `List<ChoghadiyaPeriod>` | Choghadiya periods |
| `getCurrentChoghadiya({dateTime, location})` | `Future<ChoghadiyaPeriod>` | Current Choghadiya |
| `getInauspiciousPeriods({date, sunrise, sunset})` | `InauspiciousPeriods` | Rahukalam, Gulikalam, Yamagandam |
| `findBestMuhurta({muhurta, activity})` | `List<TimePeriod>` | Best times for activity |
| `getCurrentGowriPanchangam({dateTime, location})` | `Future<GowriPeriod>` | Current Gowri Panchangam |

#### Masa Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getMasa({dateTime, location, type?})` | `Future<MasaInfo>` | Lunar month |
| `getAmantaMasa({dateTime, location})` | `Future<MasaInfo>` | Amanta system |
| `getPurnimantaMasa({dateTime, location})` | `Future<MasaInfo>` | Purnimanta system |
| `getSamvatsara({dateTime, location})` | `Future<String>` | 60-year cycle name |
| `getMasaListForYear({year, location, type?})` | `Future<List<MasaInfo>>` | All months in year |
| `getRitu(masaInfo)` | `Ritu` | Hindu season |

#### Shadbala Method

| Method | Returns | Description |
|--------|---------|-------------|
| `getShadbala(chart)` | `Map<Planet, ShadbalaResult>` | Six-fold planetary strength |

#### Sudarshan Chakra Analysis

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateSudarshanChakra(chart)` | `SudarshanChakraResult` | Triple-perspective strength analysis |
| `getBhavaBala(chart)` | `Future<Map<int, BhavaBalaResult>>` | House Strength (Bhava Bala) |

#### Jaimini Astrology Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getAtmakaraka(chart)` | `Planet` | Uses 7 or 8 karaka scheme |
| `getKarakamsa({rashiChart, navamsaChart})` | `KarakamsaInfo` | Soul planet in Navamsa |
| `getRashiDrishti(chart)` | `List<RashiDrishtiInfo>` | Sign-based aspects |
| `getActiveRashiDrishti(chart)` | `List<RashiDrishtiInfo>` | Aspects from occupied signs |
| `getArudhaPadas(chart)` | `Map<int, ArudhaPada>` | Arudha Padas for all houses |
| `getArudhaLagna(chart)` | `Rashi` | Arudha Lagna (AL) |
| `getUpapada(chart)` | `Rashi` | Upapada Lagna (UL) |
| `getAllArgalas(chart)` | `Map<int, List<ArgalaInfo>>` | Argalas for all houses |

#### Prashna (Horary) Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `calculatePrashnaArudha(seed)` | `Rashi` | Arudha based on seed (1-249) |
| `calculatePrashnaSphutas(chart)` | `Future<PrashnaSphutas>` | Trisphuta, Chatursphuta, etc. |
| `calculateGulikaSphuta(chart)` | `Future<double>` | Gulika position |

#### Compatibility Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `getPlanetaryRelationships({natalChart})` | `Map<Planet, Map<Planet, RelationshipInfo>>` | Panchadha Maitri |

#### Cleanup

```dart
jyotish.dispose();
```

---

### GeographicLocation

Represents a geographic location on Earth.

#### Constructors

```dart
// Decimal degrees
GeographicLocation({
  required double latitude,    // -90 to 90 (North positive)
  required double longitude,   // -180 to 180 (East positive)
  double altitude = 0.0,       // Meters above sea level
  String? timezone,            // IANA timezone ID
});

// From DMS
GeographicLocation.fromDMS({
  required int latDegrees,
  required int latMinutes,
  required double latSeconds,
  required bool isNorth,
  required int lonDegrees,
  required int lonMinutes,
  required double lonSeconds,
  required bool isEast,
  double altitude = 0.0,
  String? timezone,
});

// From JSON
GeographicLocation.fromJson(Map<String, dynamic> json);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `latitude` | `double` | Latitude (-90 to 90) |
| `longitude` | `double` | Longitude (-180 to 180) |
| `altitude` | `double` | Meters above sea level |
| `timezone` | `String?` | IANA timezone ID |
| `latitudeDMS` | `Map<String, dynamic>` | Latitude in DMS format |
| `longitudeDMS` | `Map<String, dynamic>` | Longitude in DMS format |

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `copyWith({...})` | `GeographicLocation` | Create modified copy |
| `toJson()` | `Map<String, dynamic>` | Convert to JSON |

---

### CalculationFlags

Controls calculation behavior for planetary positions.

#### Factory Constructors

```dart
// Default flags
CalculationFlags.defaultFlags();

// Sidereal with Lahiri ayanamsa (default for Vedic)
CalculationFlags.siderealLahiri();

// Custom sidereal mode
CalculationFlags.sidereal(SiderealMode mode);

// Topocentric calculations
CalculationFlags.topocentric();

// Specify node type (Mean vs True Node)
CalculationFlags.withNodeType(NodeType nodeType);
```

#### Main Constructor

```dart
CalculationFlags({
  SiderealMode? siderealMode,
  bool useTopocentric = false,
  bool calculateSpeed = true,
  NodeType nodeType = NodeType.meanNode,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `siderealMode` | `SiderealMode?` | Ayanamsa mode |
| `useTopocentric` | `bool` | Use topocentric calculations |
| `calculateSpeed` | `bool` | Calculate planetary speed |
| `nodeType` | `NodeType` | Mean or True Node |

---

## Services

Services provide low-level access to specific calculation domains. For most use cases, use the `Jyotish` class which wraps these services.

### EphemerisService

Core planetary position calculations using Swiss Ephemeris.

```dart
final service = EphemerisService();
await service.initialize();
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculatePlanetPosition({planet, dateTime, location, flags})` | `Future<PlanetPosition>` | Calculate planet position |
| `getAyanamsa({dateTime, mode, timezoneId?})` | `Future<double>` | Get ayanamsa value |
| `calculateHouses({dateTime, location, houseSystem?})` | `Future<HouseSystem>` | Calculate house cusps |
| `getRiseSet({planet, date, location, rsmi, atpress?, attemp?})` | `Future<DateTime?>` | Rise/set time |
| `getSunriseSunset({date, location, atpress?, attemp?})` | `Future<(DateTime?, DateTime?)>` | Sunrise and sunset |
| `getPlanetRiseSet({planet, date, location})` | `Future<(DateTime?, DateTime?)>` | Rise/set for any planet |
| `getMeridianTransit({planet, date, location, upperCulmination})` | `Future<DateTime?>` | Upper/lower culmination |
| `getPlanetVisibility({planet, date, location})` | `Future<PlanetVisibility>` | Heliacal rise/set |
| `getEclipseData({date, location, eclipseType})` | `Future<EclipseData?>` | Solar/lunar eclipse info |
| `getJulianDay(dateTime, {timezoneId?})` | `double` | DateTime to Julian Day |
| `dispose()` | `void` | Release resources |

---

### VedicChartService

Calculates complete Vedic astrology charts.

```dart
final service = VedicChartService(ephemerisService);
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateChart({dateTime, location, houseSystem?, includeOuterPlanets?, flags?})` | `Future<VedicChart>` | Complete Vedic chart |

---

### DashaService

Vedic dasha period calculations.

```dart
final service = DashaService();
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateVimshottariDasha({moonLongitude, birthDateTime, levels?, birthTimeUncertainty?})` | `DashaResult` | Vimshottari (120-year) dasha |
| `calculateYoginiDasha({moonLongitude, birthDateTime, levels?, birthTimeUncertainty?})` | `DashaResult` | Yogini (36-year) dasha |
| `calculateCharaDasha(rashiChart, {levels?})` | `CharaDashaResult` | Chara (Jaimini) dasha |
| `getNarayanaDasha(rashiChart, {levels?})` | `NarayanaDashaResult` | Jaimini sign-based dasha |
| `getAshtottariDasha(chart, {scheme?})` | `AshtottariDashaResult` | 108-year cycle dasha |
| `getKalachakraDasha(chart)` | `KalachakraDashaResult` | Nakshatra-based dasha |

---

### PanchangaService

Panchanga (five limbs) calculations.

```dart
final service = PanchangaService(ephemerisService);
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculatePanchanga({dateTime, location})` | `Future<Panchanga>` | Complete Panchanga |
| `getTithi({dateTime, location})` | `Future<TithiInfo>` | Tithi (lunar day) |
| `getYoga({dateTime, location})` | `Future<YogaInfo>` | Yoga (Sun+Moon combination) |
| `getKarana({dateTime, location})` | `Future<KaranaInfo>` | Karana (half-Tithi) |
| `getVara(dateTime, location)` | `Future<VaraInfo>` | Vara (weekday lord) |
| `getNakshatra({dateTime, location})` | `Future<NakshatraInfo>` | Moon's nakshatra |
| `getTithiEndTime({dateTime, location, accuracyThreshold?})` | `Future<DateTime>` | Precise Tithi end |
| `calculateAbhijitMuhurta({date, location})` | `Future<AbhijitMuhurta>` | Midday 8th Muhurta |
| `calculateBrahmaMuhurta({date, location})` | `Future<BrahmaMuhurta>` | Pre-dawn auspicious period |
| `calculateNighttimeInauspicious({date, location})` | `Future<NighttimeInauspiciousPeriods>` | Night Rahu/Gulika/Yamagandam |
| `getTithiJunction({targetTithiNumber, startDate, location})` | `Future<DateTime>` | Microsecond-precision Tithi change |
| `getMoonPhaseDetails({dateTime, location})` | `Future<MoonPhaseDetails>` | Comprehensive lunar data |

---

### AshtakavargaService

Ashtakavarga (eightfold division) calculations.

```dart
final service = AshtakavargaService();
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateAshtakavarga(natalChart)` | `Ashtakavarga` | Complete Ashtakavarga |
| `analyzeTransit({ashtakavarga, transitPlanet, transitSign, transitDate?})` | `TransitAnalysis` | Transit strength |
| `getFavorableTransitSigns(ashtakavarga, planet)` | `List<int>` | Favorable signs (>28 bindus) |
| `getBinduDetailsForSign(ashtakavarga, signIndex)` | `Map<Planet, int>` | Bindus per planet |
| `applyTrikonaShodhana(ashtakavarga)` | `Ashtakavarga` | Apply trine reduction |
| `applyEkadhipatiShodhana(ashtakavarga)` | `Ashtakavarga` | Apply lordship reduction |
| `calculatePinda(ashtakavarga)` | `Map<Planet, double>` | Planetary strength |
| `calculateYogaPinda(ashtakavarga)` | `Map<Planet, double>` | Auspicious strength |
| `calculateShodhyaPinda(ashtakavarga)` | `ShodhyaPindaResult` | Reduced strength |
| `calculateHousePinda(ashtakavarga, houseNumber)` | `double` | House strength |
| `calculateAllHousesPinda(ashtakavarga)` | `Map<int, double>` | All house strengths |

---

### AspectService

Vedic planetary aspects (Graha Drishti).

```dart
final service = AspectService();
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateAspects(positions, {config?})` | `List<AspectInfo>` | All aspects |
| `getAspectsForPlanet(planet, positions, {config?})` | `List<AspectInfo>` | Aspects involving planet |
| `getAspectsCastBy(planet, positions, {config?})` | `List<AspectInfo>` | Aspects cast by planet |
| `getAspectsReceivedBy(planet, positions, {config?})` | `List<AspectInfo>` | Aspects received by planet |
| `getPlanetsAspectingSign(houseSignIndex, positions)` | `List<Planet>` | Planets aspecting sign |

---

### TransitService

Transit position calculations.

```dart
final service = TransitService(ephemerisService);
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateTransits({natalChart, transitDateTime, location})` | `Future<Map<Planet, TransitInfo>>` | Transit positions |
| `findTransitEvents({natalChart, config, location})` | `Future<List<TransitEvent>>` | Transit events |

---

### SpecialTransitService

Special transit features (Sade Sati, Dhaiya, Panchak).

```dart
final service = SpecialTransitService(ephemerisService);
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateSpecialTransits({natalChart, checkDate?, location})` | `Future<SpecialTransits>` | All special transits |
| `predictSadeSatiPeriods(natalChart, {yearsBefore?, yearsAfter?})` | `Future<List<SadeSatiPeriod>>` | Past/future Sade Sati |

---

### DivisionalChartService

Divisional charts (Varga) calculations.

```dart
final service = DivisionalChartService();
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateDivisionalChart(rashiChart, type)` | `VedicChart` | Any divisional chart |

**Supported Chart Types**: D1 (Rashi), D2 (Hora), D3 (Drekkana), D4 (Chaturthamsa), D5 (Panchamsa), D6 (Shashthamsa), D7 (Saptamsa), D8 (Ashtamsa), D9 (Navamsa), D10 (Dasamsa), D11 (Rudramsa), D12 (Dwadasamsa), D16 (Shodasamsa), D20 (Vimsamsa), D24 (Chaturvimshamsa), D27 (Saptavimshamsa), D30 (Trimsamsa), D40 (Khavedamsa), D45 (Akshavedamsa), D60 (Shashtiamsa), D150 (Nadi Amsa), D249 (KP micro-divisions)

---

### ShadbalaService

Six-fold planetary strength calculations.

```dart
final service = ShadbalaService(ephemerisService);
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateShadbala(chart)` | `Map<Planet, ShadbalaResult>` | Complete Shadbala |
| `calculateHoraLordsForDay({date, location})` | `Future<List<Planet>>` | 24 Hora lords |
| `checkCombustion({planet, planetLongitude, sunLongitude})` | `CombustionInfo` | Detailed combustion status |

**Shadbala Components**:
1. **Sthana Bala** - Positional strength (Uchcha, Saptavargaja, Ojayugma, Drekkana, Kendra)
2. **Dig Bala** - Directional strength
3. **Kala Bala** - Temporal strength (Natonnata, Paksha, Tribhaga, VMDH, Ayana)
4. **Chesta Bala** - Motional strength
5. **Naisargika Bala** - Natural strength
6. **Drik Bala** - Aspectual strength

---

### KPService

Krishnamurti Paddhati (KP) system calculations.

```dart
final service = KPService(ephemerisService);
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateKPData(natalChart, {useNewAyanamsa?})` | `KPCalculations` | Complete KP data |
| `getSubLord(longitude)` | `Planet` | Sub-Lord for longitude |
| `getSubSubLord(longitude)` | `Planet` | Sub-Sub-Lord |
| `getHouseGroupSignificators(significators)` | `Map<int, Set<Planet>>` | House significators |
| `calculateTransitKPDivisions(transitPositions)` | `Map<Planet, KPDivision>` | Transit KP data |

---

### MuhurtaService

Muhurta (auspicious timing) calculations.

```dart
final service = MuhurtaService();
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateMuhurta({date, sunrise, sunset, location})` | `Muhurta` | Complete Muhurta |
| `getHoraPeriods({date, sunrise, sunset})` | `List<HoraPeriod>` | Planetary hours (24) |
| `getChoghadiya({date, sunrise, sunset})` | `List<ChoghadiyaPeriod>` | Choghadiya periods (16) |
| `getInauspiciousPeriods({date, sunrise, sunset})` | `InauspiciousPeriods` | Rahukalam/Gulikalam/Yamagandam |
| `findBestMuhurta({muhurta, activity})` | `List<TimePeriod>` | Best times for activity |
| `getHoraLordForHour(dateTime, sunrise)` | `Planet` | Hora lord at time |

---

### MasaService

Lunar month (Masa) and calendar calculations.

```dart
final service = MasaService(ephemerisService);
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateMasa({dateTime, location, type?})` | `Future<MasaInfo>` | Lunar month info |
| `getSamvatsara({dateTime, location})` | `Future<String>` | 60-year cycle name |
| `getNakshatraWithAbhijit({dateTime, location})` | `Future<NakshatraInfo>` | With 28th nakshatra |
| `calculateNakshatraFromLongitude(longitude)` | `NakshatraInfo` | Nakshatra from longitude |
| `getMasaListForYear({year, location, type?})` | `Future<List<MasaInfo>>` | All months in year |
| `getRitu(masaInfo)` | `Ritu` | Hindu season |
| `getRituDetails({dateTime, location})` | `Future<RituDetails>` | Season details |

---

### SudarshanChakraService

Service for calculating Sudarshan Chakra strength from Lagna, Moon, and Sun perspectives.

```dart
final service = SudarshanChakraService();
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateSudarshanChakra(chart)` | `SudarshanChakraResult` | Calculate triple-perspective strength |

---

### StrengthAnalysisService

Advanced planetary strength and house analysis.

```dart
final service = StrengthAnalysisService();
```

| Method | Returns | Description |
|--------|---------|-------------|
| `getIshtaphala({planet, chart, shadbalaStrength})` | `double` | Ishtaphala (auspicious fruit) |
| `getKashtaphala({planet, chart, shadbalaStrength})` | `double` | Kashtaphala (inauspicious fruit) |
| `getBhavaBala({chart, shadbalaResults})` | `Map<int, double>` | Strength for all 12 houses |
| `getVimshopakBala({chart, planet})` | `VimshopakBala` | 20-fold strength for planet |
| `getAllPlanetsVimshopakBala(chart)` | `Map<Planet, VimshopakBala>` | Vimshopak Bala for all planets |

---

### GocharaVedhaService

Transit obstruction (Vedha) analysis.

```dart
final service = GocharaVedhaService();
```

| Method | Returns | Description |
|--------|---------|-------------|
| `calculateVedha({transitPlanet, houseFromMoon, moonNakshatra, otherTransits})` | `VedhaResult` | Check Vedha for single transit |
| `calculateMultipleVedha({transits, moonNakshatra})` | `List<VedhaResult>` | Check Vedha for multiple transits |
| `findFavorablePeriodsWithoutVedha(transitSnapshots)` | `List<TimePeriod>` | Find periods free from obstruction |
| `getVedhaRemedies(vedhaResult)` | `List<String>` | Remedies for obstruction |


---

## Models

### VedicChart

Complete Vedic astrology chart data.

| Property | Type | Description |
|----------|------|-------------|
| `dateTime` | `DateTime` | Chart date/time |
| `location` | `GeographicLocation` | Chart location |
| `ayanamsa` | `double` | Ayanamsa value used |
| `ascendant` | `double` | Ascendant longitude |
| `ascendantSign` | `String` | Ascendant zodiac sign |
| `planets` | `Map<Planet, VedicPlanetInfo>` | All planetary data |
| `houses` | `HouseSystem` | House cusps |
| `rahu` | `VedicPlanetInfo` | Rahu position |
| `ketu` | `KetuPosition` | Ketu position |

| Method | Returns | Description |
|--------|---------|-------------|
| `getPlanet(planet)` | `VedicPlanetInfo?` | Get planet info |
| `getPlanetsInHouse(houseNumber)` | `List<VedicPlanetInfo>` | Planets in house |

---

### PlanetPosition

Calculated position of a celestial body.

| Property | Type | Description |
|----------|------|-------------|
| `planet` | `Planet` | The planet |
| `longitude` | `double` | Ecliptic longitude (0-360°) |
| `latitude` | `double` | Ecliptic latitude |
| `distance` | `double` | Distance from Earth (AU) |
| `longitudeSpeed` | `double` | Speed (degrees/day) |
| `zodiacSign` | `String` | Zodiac sign name |
| `signIndex` | `int` | Sign index (0-11) |
| `positionInSign` | `double` | Degrees in sign (0-30) |
| `nakshatra` | `String` | Nakshatra name |
| `nakshatraIndex` | `int` | Nakshatra index (0-26) |
| `nakshatraPada` | `int` | Pada (1-4) |
| `isRetrograde` | `bool` | Retrograde motion |
| `isCombust` | `bool` | Combustion status |
| `formattedPosition` | `String` | Human-readable position |

---

### VedicPlanetInfo

Extended Vedic planetary information.

| Property | Type | Description |
|----------|------|-------------|
| `planet` | `Planet` | The planet |
| `position` | `PlanetPosition` | Calculated position |
| `house` | `int` | House number (1-12) |
| `zodiacSign` | `String` | Zodiac sign name |
| `nakshatra` | `String` | Nakshatra name |
| `pada` | `int` | Nakshatra pada (1-4) |
| `dignity` | `PlanetaryDignity` | Dignity status |
| `isRetrograde` | `bool` | Retrograde status |
| `isCombust` | `bool` | Combustion status |

---

### Panchanga

Complete Panchanga (five limbs) data.

| Property | Type | Description |
|----------|------|-------------|
| `dateTime` | `DateTime` | Calculation time |
| `tithi` | `TithiInfo` | Lunar day |
| `nakshatra` | `NakshatraInfo` | Moon's nakshatra |
| `yoga` | `YogaInfo` | Sun-Moon combination |
| `karana` | `KaranaInfo` | Half-Tithi |
| `vara` | `VaraInfo` | Weekday/lord |
| `sunrise` | `DateTime` | Sunrise time |
| `sunset` | `DateTime` | Sunset time |

---

### DashaResult

Dasha calculation result.

| Property | Type | Description |
|----------|------|-------------|
| `system` | `DashaSystem` | Dasha system used |
| `birthDateTime` | `DateTime` | Birth date/time |
| `moonLongitude` | `double` | Moon longitude at birth |
| `startingNakshatra` | `String` | Birth nakshatra |
| `startingLord` | `Planet` | Starting dasha lord |
| `balanceAtBirth` | `double` | Balance of first dasha (days) |
| `mahadashas` | `List<MahadashaPeriod>` | All mahadasha periods |

| Method | Returns | Description |
|--------|---------|-------------|
| `getActivePeriodsAt(date)` | `List<DashaPeriod>` | Active periods at date |

---

### Ashtakavarga

Complete Ashtakavarga data.

| Property | Type | Description |
|----------|------|-------------|
| `bhinnashtakavarga` | `Map<Planet, Bhinnashtakavarga>` | Individual planet scores |
| `sarvashtakavarga` | `List<int>` | Combined scores per sign |
| `samudaya` | `int` | Total points |

| Method | Returns | Description |
|--------|---------|-------------|
| `getTotalBindusForHouse(house)` | `int` | SAV for house |
| `getBindusForPlanet(planet, sign)` | `int` | BAV for planet in sign |

---

### VimshopakBala

20-fold strength result.

| Property | Type | Description |
|----------|------|-------------|
| `totalScore` | `double` | Total score out of 20 |
| `strengthCategory` | `StrengthCategory` | Category (Very Strong, Strong, etc) |
| `individualScores` | `Map<DivisionalChartType, double>` | Score per varga |

---

### CombustionInfo

Detailed combustion status.

| Property | Type | Description |
|----------|------|-------------|
| `isCombust` | `bool` | Is planet combust |
| `distanceFromSun` | `double` | Distance from Sun in degrees |
| `combustionOrb` | `double` | Allowed orb for combustion |
| `severity` | `CombustionSeverity` | Severity (None, Partial, Deep, etc) |
| `remainingDegrees` | `double` | Degrees to exit combustion |

---

### YogaPindaResult

Yoga Pinda calculation result.

| Property | Type | Description |
|----------|------|-------------|
| `planet` | `Planet` | The planet |
| `totalYogaPinda` | `double` | Total Yoga Pinda points |
| `strengthRating` | `String` | Strength description |

---

### ShodhyaPindaResult

Complete Shodhya Pinda analysis.

| Property | Type | Description |
|----------|------|-------------|
| `yogaPinda` | `Map<Planet, YogaPindaResult>` | Yoga Pinda per planet |
| `totalYogaPinda` | `double` | Sum of all Yoga Pindas |
| `averageYogaPinda` | `double` | Average Yoga Pinda |
| `overallStrength` | `String` | Overall chart strength |

---

### VedhaResult

Transit obstruction analysis.

| Property | Type | Description |
|----------|------|-------------|
| `transitPlanet` | `Planet` | Transiting planet |
| `houseFromMoon` | `int` | House from natal Moon |
| `isFavorablePosition` | `bool` | Is in favorable house |
| `isObstructed` | `bool` | Is obstructed by Vedha |
| `obstructingPlanets` | `List<Planet>` | Planets causing obstruction |
| `severity` | `VedhaSeverity` | Severity of obstruction |

---

### PlanetVisibility

Visibility analysis result.

| Property | Type | Description |
|----------|------|-------------|
| `isVisible` | `bool` | Is planet visible |
| `visibilityType` | `VisibilityType` | Type of visibility |
| `elongation` | `double` | Angle from Sun |
| `magnitude` | `double` | Approximate magnitude |
| `description` | `String` | Visibility description |

---

### EclipseData

Solar or lunar eclipse information.

| Property | Type | Description |
|----------|------|-------------|
| `date` | `DateTime` | Date of maximum eclipse |
| `eclipseType` | `EclipseType` | Solar or Lunar |
| `magnitude` | `double` | Eclipse magnitude |
| `isVisible` | `bool` | Visible at location |
| `isTotal` | `bool` | Is total eclipse |
| `description` | `String` | Eclipse description |

---

### AbhijitMuhurta

Abhijit Muhurta timing.

| Property | Type | Description |
|----------|------|-------------|
| `startTime` | `DateTime` | Start time |
| `endTime` | `DateTime` | End time |
| `duration` | `Duration` | Length of muhurta |
| `description` | `String` | Description |

| Method | Returns | Description |
|--------|---------|-------------|
| `contains(dateTime)` | `bool` | Is time in muhurta |

---

### BrahmaMuhurta

Brahma Muhurta timing.

| Property | Type | Description |
|----------|------|-------------|
| `startTime` | `DateTime` | Start time |
| `endTime` | `DateTime` | End time |
| `duration` | `Duration` | Length of muhurta |
| `description` | `String` | Description |

---

### NighttimeInauspiciousPeriods

Night inauspicious times.

| Property | Type | Description |
|----------|------|-------------|
| `rahuKaal` | `TimePeriod` | Night Rahu Kaal |
| `gulikaKaal` | `TimePeriod` | Night Gulika Kaal |
| `yamagandam` | `TimePeriod` | Night Yamagandam |

| Method | Returns | Description |
|--------|---------|-------------|
| `isInauspicious(dateTime)` | `bool` | Is time in any period |

---

### MoonPhaseDetails

Comprehensive Moon data.

| Property | Type | Description |
|----------|------|-------------|
| `phaseName` | `String` | Name of phase |
| `illumination` | `double` | % Illumination |
| `isWaxing` | `bool` | Waxing or Waning |
| `lunarAge` | `double` | Days since New Moon |
| `elongation` | `double` | Angle from Sun |
| `elongationVelocity` | `double` | Speed relative to Sun |
| `tithiNumber` | `int` | Current Tithi (1-30) |
| `isFullMoon` | `bool` | Is Full Moon |
| `isNewMoon` | `bool` | Is New Moon |

---

### YogaDetails

27 Nitya Yoga descriptions.

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | Yoga name |
| `nature` | `String` | Nature (Benefic/Malefic) |
| `rulingPlanet` | `String` | Ruling planet |
| `description` | `String` | Description |
| `effects` | `String` | General effects |
| `recommendations` | `String` | Recommended activities |

| Method | Returns | Description |
|--------|---------|-------------|
| `isFavorableFor(activity)` | `bool` | Check activity |

---

## Enums

### Planet

Celestial bodies supported by the library.

| Value | Description |
|-------|-------------|
| `sun`, `moon` | Luminaries |
| `mercury`, `venus`, `mars`, `jupiter`, `saturn` | Traditional planets |
| `uranus`, `neptune`, `pluto` | Outer planets |
| `meanNode`, `trueNode`, `ketu` | Lunar nodes |
| `chiron`, `ceres`, `pallas`, `juno`, `vesta` | Asteroids |

**Static Getters**: `majorPlanets`, `traditionalPlanets`, `outerPlanets`, `lunarNodes`, `asteroids`, `all`

---

### SiderealMode

Ayanamsa modes for sidereal calculations.

| Value | Description |
|-------|-------------|
| `lahiri` | Most common in Indian astrology |
| `krishnamurti` | KP astrology |
| `raman` | Raman ayanamsa |
| `faganBradley` | Western sidereal |
| ... | 40+ modes available |

---

### DivisionalChartType

Divisional chart types.

| Value | Description |
|-------|-------------|
| `d1` | Rashi (birth chart) |
| `d2` | Hora (wealth) |
| `d3` | Drekkana (siblings) |
| `d4` | Chaturthamsa (fortune) |
| `d7` | Saptamsa (children) |
| `d9` | Navamsa (marriage/dharma) |
| `d10` | Dasamsa (career) |
| `d12` | Dwadasamsa (parents) |
| `d16` | Shodasamsa (vehicles) |
| `d20` | Vimsamsa (spiritual) |
| `d24` | Chaturvimshamsa (education) |
| `d27` | Saptavimshamsa (strength) |
| `d30` | Trimsamsa (misfortune) |
| `d40` | Khavedamsa (auspiciousness) |
| `d45` | Akshavedamsa (general) |
| `d60` | Shashtiamsa (past karma) |
| `d249` | KP micro-divisions |

---

### PlanetaryDignity

Planetary dignity status.

| Value | English | Sanskrit |
|-------|---------|----------|
| `exalted` | Exalted | Uccha |
| `moolaTrikona` | Moola Trikona | Moola Trikona |
| `ownSign` | Own Sign | Swakshetra |
| `greatFriend` | Great Friend | Adhi-Mitra |
| `friendSign` | Friend's Sign | Mitra |
| `neutral` | Neutral | Sama |
| `enemySign` | Enemy's Sign | Shatru |
| `greatEnemy` | Great Enemy | Adhi-Shatru |
| `debilitated` | Debilitated | Neecha |

---

### NodeType

Lunar node calculation type.

| Value | Description |
|-------|-------------|
| `meanNode` | Mean Node (traditional, smoother) |
| `trueNode` | True Node (modern, precise) |

---

### MasaType

Lunar month system.

| Value | Description |
|-------|-------------|
| `amanta` | Starts from New Moon (South India, Gujarat) |
| `purnimanta` | Starts from Full Moon (North India) |

---

### LunarMonth

The 12 lunar months.

| Value | Sanskrit | Period |
|-------|----------|--------|
| `chaitra` | चैत्र | March-April |
| `vaishakha` | वैशाख | April-May |
| `jyeshtha` | ज्येष्ठ | May-June |
| `ashadha` | आषाढ़ | June-July |
| `shravana` | श्रावण | July-August |
| `bhadrapada` | भाद्रपद | August-September |
| `ashwina` | अश्विन | September-October |
| `kartika` | कार्तिक | October-November |
| `margashirsha` | मार्गशीर्ष | November-December |
| `pausha` | पौष | December-January |
| `magha` | माघ | January-February |
| `phalguna` | फाल्गुन | February-March |

---

### Ritu

Hindu seasons.

| Value | Description | Months |
|-------|-------------|--------|
| `vasanta` | Spring | Chaitra, Vaishakha |
| `grishma` | Summer | Jyeshtha, Ashadha |
| `varsha` | Monsoon | Shravana, Bhadrapada |
| `sharad` | Autumn | Ashwina, Kartika |
| `hemanta` | Pre-winter | Margashirsha, Pausha |
| `shishira` | Winter | Magha, Phalguna |

---

### VisibilityType

Planet visibility status.

| Value | Description |
|-------|-------------|
| `notVisible` | Too close to Sun |
| `heliacalRise` | First visible before sunrise |
| `heliacalSet` | Last visible after sunset |
| `daytime` | Visible in daylight |
| `evening` | Evening star |
| `morning` | Morning star |

---

### EclipseType

Type of eclipse.

| Value | Description |
|-------|-------------|
| `solar` | Solar eclipse |
| `lunar` | Lunar eclipse |

---

## Error Handling

The library throws `JyotishException` for errors:

```dart
try {
  final chart = await jyotish.calculateVedicChart(...);
} on InitializationException catch (e) {
  // Library not initialized
} on CalculationException catch (e) {
  // Calculation failed
} on JyotishException catch (e) {
  // General error
}
```

---

## Best Practices

1. **Always initialize before use**: Call `jyotish.initialize()` before any calculations
2. **Dispose when done**: Call `jyotish.dispose()` to free resources
3. **Use timezone**: Include timezone in `GeographicLocation` for accurate historical calculations
4. **Prefer Jyotish class**: Use the main `Jyotish` class instead of individual services for simpler code
5. **Cache charts**: Reuse `VedicChart` objects for multiple calculations (aspects, dashas, etc.)

---

*Generated for Jyotish Flutter Library (SV-stark Fork)*
