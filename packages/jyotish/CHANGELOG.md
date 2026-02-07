# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - 2026-02-05

### Added

- **D249 - 249 Subdivisions (High-Precision Micro Analysis)**
  - Complete implementation of 249 subdivisions per zodiac sign
  - Ultra-fine granularity for advanced Vedic analysis (~0.12° per subdivision)
  - Odd sign mapping: starts from same sign, counts forward through 249 parts
  - Even sign mapping: starts from 9th sign, counts forward through 249 parts
  - Compatible with existing D1-D60 divisional chart infrastructure
  - Comprehensive test suite with 10+ test cases
  - API: `DivisionalChartType.d249`

- **Corrected Vara (Weekday) Calculation**
  - Updated `PanchangaService` to use Sunrise as the day boundary instead of midnight
  - Births between midnight and sunrise now correctly resolve to the previous day's planet lord
  - API: `jyotish.getVara()` is now asynchronous and requires `location`

- **Tithi End-Time Analysis**
  - New API for finding exact moments when a Tithi ends
  - Uses high-precision binary search with sub-second accuracy
  - API: `jyotish.getTithiEndTime()`

- **Shadbala (Six-fold Planetary Strength)**
  - Complete implementation of all 6 strength types:
    - Sthana Bala (Positional Strength)
    - Dig Bala (Directional Strength) 
    - Kala Bala (Temporal Strength)
    - Chesta Bala (Motional Strength)
    - Naisargika Bala (Natural Strength)
    - Drik Bala (Aspectual Strength)
  - `calculateShadbala()` - Calculate complete Shadbala for all planets
  - Strength categorization (Very Strong, Strong, Moderate, Weak, Very Weak)

- **Ashtakavarga Reductions (Shodhana)**
  - `applyTrikonaShodhana()` - Trine reduction for 1-5-9 groups
  - `applyEkadhipatiShodhana()` - Reduction for same sign ownership
  - `calculatePinda()` - Final planetary strength (Rupas calculation)

### Fixed

- **Planetary Friendship Calculations**
  - Now properly calculates friend, enemy, and neutral relationships
  - Added `greatFriend` (Adhi-Mitra) and `greatEnemy` (Adhi-Shatru) dignities
  - Affects dignity calculations in both Rashi and all D-Charts

- **D-Chart Dignity Calculations**
  - All divisional charts (D1-D60) now calculate dignities correctly
  - Dignities no longer default to "neutral" in D-Charts

- **Sade Sati Date Estimation**
  - Replaced constant `daysPerSign` with variable Saturn speed calculation
  - Now accounts for retrograde motion and sign-specific variations
  - More accurate start/end date predictions

- **Rahu/Ketu Distinguishability**
  - Added `lordName` field to `DashaPeriod` to properly distinguish Rahu from Ketu
  - Both planets display correctly in dasha output (e.g., "Rahu-Mercury-Venus")

- **KP Ayanamsa Calculation**
  - Now uses precise time-varying formula from Swiss Ephemeris
  - Uses `SiderealMode.krishnamurtiVP291` instead of hardcoded offset

### Breaking Changes

- **`calculateKPData()` is now async** - Returns `Future<KPCalculations>` instead of `KPCalculations`
  - Migration: Add `await` before the call: `final kpData = await jyotish.calculateKPData(chart)`

## [1.2.0] - 2026-02-05

### Added

- **Panchanga Module**
  - Tithi, Yoga, Karana, and Vara calculations
  - High-precision sunrise and sunset times using Swiss Ephemeris
- **Ashtakavarga System**
  - Bhinnashtakavarga (BAV) for all planets
  - Sarvashtakavarga (SAV) calculation
  - Ashtakavarga-based transit strength analysis
- **KP System (Krishnamurti Paddhati)**
  - Support for KP-specific ayanamsas (New VP291, Khullar)
  - Sign, Star, Sub-Lord, and Sub-Sub-Lord calculations
  - House and planet significators
- **Special Transits**
  - Sade Sati (Saturn's 7.5 year transit) status and phase analysis
  - Dhaiya (Saturn's 2.5 year transit/Panoti) analysis
  - Panchak detection and precautions
- **Muhurta & Auspicious Timings**
  - Hourly Hora Lord calculation
  - Daytime and Nighttime Choghadiya periods
  - Inauspicious periods: Rahukalam, Gulikalam, and Yamagandam
  - Activity-based Muhurta filtering

### Improved

- **Ephemeris Service**: Enhanced support for rise/set transitions and topocentric corrections.
- **Vedic Chart**: Improved planet data model to support extended Vedic properties.

## [1.1.0] - 2026-02-04

### Added

- **Vedic Aspect Calculations (Graha Drishti)**
  - All planets aspect 7th house (opposition)
  - Mars special aspects (4th, 8th houses)
  - Jupiter special aspects (5th, 9th houses)
  - Saturn special aspects (3rd, 10th houses)
  - Applying/separating aspect detection
  - Aspect strength calculation

- **Transit Calculations**
  - Current planetary transits over natal positions
  - Transit house placements
  - Transit aspects to natal planets
  - Transit event prediction with date ranges

- **Dasha System Support**
  - Vimshottari Dasha (120-year cycle)
  - Yogini Dasha (36-year cycle)
  - Mahadasha, Antardasha, Pratyantardasha levels
  - Current period calculation
  - Birth time precision warnings

### New API Methods

- `getAspects()` - Calculate all Vedic aspects between planets
- `getAspectsForPlanet()` - Get aspects involving a specific planet
- `getChartAspects()` - Calculate aspects from a VedicChart
- `getTransitPositions()` - Calculate transit positions relative to natal chart
- `getTransitEvents()` - Find significant transit events in a date range
- `getVimshottariDasha()` - Calculate Vimshottari dasha periods
- `getYoginiDasha()` - Calculate Yogini dasha periods
- `getCurrentDasha()` - Get active dasha periods at any date

### New Models

- `AspectType` - Enum of Vedic aspect types
- `AspectInfo` - Detailed aspect information
- `AspectConfig` - Aspect calculation configuration
- `TransitInfo` - Transit position data
- `TransitEvent` - Transit event details
- `TransitConfig` - Transit calculation configuration
- `DashaPeriod` - Dasha period data
- `DashaResult` - Complete dasha calculation result
- `DashaType` - Enum of dasha systems
- `Yogini` - Enum of Yogini dasha lords

## [1.0.1] - 2025-11-25

### Fixed

- Fixed package validation errors for pub.dev publishing
- Improved export organization (alphabetically sorted)

## [1.0.0] - 2025-10-19

### Added

- Initial release of Jyotish library
- Swiss Ephemeris integration via FFI
- Support for all major planets (Sun through Pluto)
- Lunar nodes (Mean and True Node)
- Lunar apogees (Black Moon Lilith)
- Major asteroids (Chiron, Pholus, Ceres, Pallas, Juno, Vesta)
- Tropical and sidereal zodiac calculations
- 40+ ayanamsa systems for sidereal calculations
- Geocentric and topocentric position calculations
- Retrograde detection
- Nakshatra (lunar mansion) calculations
- Zodiac sign and position calculations
- Speed/velocity calculations
- Comprehensive error handling
- Input validation
- Production-ready API
- Full documentation and examples
- Example Flutter app
- Platform support: Android, iOS, macOS, Linux, Windows

### Features

- High-precision astronomical calculations
- Easy-to-use API
- Batch planet calculations
- Flexible calculation flags
- Geographic location support with DMS conversion
- JSON serialization support
- Proper resource management

[1.1.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v1.1.0
[1.0.1]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v1.0.1
[1.0.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v1.0.0
