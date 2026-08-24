# Changelog

All notable changes to AstroNaksh are documented in this file.

## [Unreleased] - 2026-08-24

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
