# Changelog

All notable changes to AstroNaksh are documented in this file.

## [Unreleased] - 2026-11-17

### 🌟 Advanced Jyotish Engine Upgrade (v2.20.8 Integration)
- **Synchronized Jyotish Core**: Force-copied and integrated 153 calculation engine files from `jyotish-flutter-library-fork` v2.20.8, including modular calculation components (`widgets.dart`, `chart_svg_renderer.dart`, `ephemeris_models.dart`, and `ephemeris_cache.dart`).
- **Complete Re-Export Compatibility**: Preserved pure-Dart and Flutter compatibility in `package:jyotish/core.dart`, `analysis.dart`, and `muhurta.dart` for core models (`VedicChart`, `VargaConfiguration`, `SpecialLagnas`, `PrastaraResult`, `GrahaYuddha`, `CompatibilityReport`, `chart_renderer.dart`, `vedic_clock.dart`).
- **Dependency & SDK Modernization**: Upgraded `freezed: ^4.0.1`, `riverpod_generator: ^4.0.10`, and associated build dependencies in `pubspec.yaml` to ensure clean compatibility with current Flutter SDK null-safety constraints.

### 📐 Chart & Mathematical Precision Enhancements
- **High-Precision Solar Return Alignment**: Updated `VarshaphalScreen` to calculate native annual charts using exact astronomical `solarReturnTime` from `calculateSolarReturn(...)` rather than approximate calendar-year timestamps.
- **Special Mathematical Lagnas on Charts**:
  - Added `showSpecialLagnas` preference to `ChartCustomization` and `SettingsScreen`.
  - Added real-time display of **Hora Lagna (HL)**, **Ghati Lagna (GL)**, and **Sree Lagna (SL)** in `ChartWidget` house inspection cards.
- **Zodiac Sign Label Mapping**: Standardized `AstrologyConstants.signNames` and `getSignName` to use `Rashi.label` ('Aries', 'Taurus', etc.) instead of lowercase enum identifiers, resolving model and test assertions.

### 🎨 Vector SVG Export & Sharing
- **Native Vector SVG Generation**: Integrated `SvgChartExporter.fromVedicChart` and `saveVedicChartSvg` powered by `VedicChartRenderer` for lossless, high-DPI SVG chart exports.
- **Vector Chart Sharing**: Added `ChartShareService.shareChartSvg` for direct sharing of vector chart files across mobile and desktop platforms.
- **Ephemeris Cache Control**: Added `EphemerisManager.clearCache()` to allow explicit runtime clearing of Swiss Ephemeris FFI caches.

### 🛠️ Verification & Quality Assurance
- **GitHub Actions Linux CI Test Suite Fix**:
  - Enhanced `.github/workflows/nightly.yml` to install `libswe-dev` and `build-essential` on `ubuntu-latest`.
  - Added Linux C compilation of `libswisseph.so` directly from official Swiss Ephemeris sources in `scripts/setup_swisseph.ps1`.
  - Expanded `SwissEphBindings._loadLibrary` to automatically probe local project paths (`.`, `packages/jyotish`, `assets/ephe`, executable dir) and system library locations (`/usr/local/lib`, `/usr/lib/x86_64-linux-gnu`) before dynamic name fallback.
  - Hardened `AppEnvironment` and `EphemerisManager` against headless test runner missing plugin exceptions by adding Linux XDG/Home directory fallbacks and local disk ephemeris discovery.
- **100% Test Suite Verification**: All 164 unit, widget, and logic tests passing cleanly (`flutter test`).
- **Zero Static Analysis Errors**: `flutter analyze` passing across both root workspace and `packages/jyotish` with 0 errors and 0 warnings.
- **Consistent Code Formatting**: All files formatted according to Dart style guidelines with `dart format`.

## [1.0.0] - 2026-08-24

### 🚀 Dependency & Architecture Consolidation
- **Consolidated SQLite Stack**: Migrated `CityDatabase` from `sqflite` to `package:sqlite3/sqlite3.dart`, allowing complete removal of `sqflite` and `sqflite_common_ffi` dependencies and boilerplate FFI initializations.
- **Removed Unused / EOL Dependencies**:
  - Removed deprecated `sqlite3_flutter_libs` (functionality now provided directly by modern `sqlite3`).
  - Removed unused dependencies: `showcaseview`, `math_expressions`, `cupertino_icons`, `dartx`.
  - Removed brittle `dependency_overrides` from `pubspec.yaml`.
- **Added Testing & Security Tools**:
  - Added `flutter_secure_storage` for OS-level credential vault protection.
  - Added `mocktail` to `dev_dependencies` for clean mock testing.

### 🔒 Security & Persistence
- **Secure WebDAV Credential Storage**: WebDAV credentials are now secured via `FlutterSecureStorage` with XOR/base64 encoded fallback for resilient multi-platform support.
- **Non-Destructive Database Restore**: Upgraded `BackupService.restoreLocal` to transactional SQLite `ATTACH DATABASE` and schema-safe table data copying, preventing connection invalidation for active screens.
- **Fault-Tolerant Settings Deserialization**: Implemented field-by-field safe JSON decoding in `SettingsNotifier` so corrupted individual settings fields never wipe the entire settings payload.

### ⚡ Performance & Caching
- **Shadbala Calculation Caching**: Added upfront `ShadbalaResult` caching across `BhavaBala` and `LifePredictionService`, eliminating ~20× redundant ephemeris and planetary strength recalculations.
- **Immediate Chart Rendering**: Updated `ChartWidget` to instantly render using default theme fallbacks during initial asynchronous settings loading, preventing layout flicker and progress ring blocking.

### 🎯 Astrological Calculation Fixes & Enhancements
- **Ketu & Rahu Attribution**: Fixed `_parsePlanetName` so Ketu is accurately mapped to `Planet.southNode` (Mean Node) rather than Rahu, ensuring correct KP star/sub-lord prediction weights.
- **Tara Kuta Alignment**: Corrected off-by-one difference logic for Vipat, Pratyak, and Naidhana tara classifications in compatibility scoring.
- **Unified Compatibility Scoring**: Standardized single-source 36-point Ashta-Kuta engine and 100-point normalized compatibility scoring to eliminate score saturation and dual conflicting matching engines.
- **Exact Solar Return Age**: Fixed `calculateExactAge` in `VarshaphalSystem` to measure precise fractional elapsed years at solar return rather than simple calendar-year subtraction.
- **Dynamic Transit Tithi & Nodes**: Implemented dynamic tithi calculations and explicit Rahu/Ketu transit conjunction checks in `TransitAnalysis`.
- **Yoga & Dosha Model Completeness**: Added missing cancellation and manifestation fields to `BhangaResult.==` and `hashCode`.

### 🛠️ Code Health & Maintenance
- **Repository Hygiene**: Removed tracked build artifacts (`problems-report.html` and Gradle cache locks) and updated `.gitignore`.
- **Ephemeris Network Resiliency**: Added error handling and logging for non-200 HTTP responses during Swiss Ephemeris asset synchronization.
- **UI Responsiveness**: Added layout constraints and text ellipsis in `ChartWidget` house inspection cards to prevent `RenderFlex` overflows on small viewports.
- **100% Test Suite Verification**: All 152 unit, widget, and golden tests passing cleanly with 0 static analysis errors.
