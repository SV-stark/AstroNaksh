# Accuracy Improvements - API Changes Documentation

## Overview

This document describes the accuracy improvements made to the Jyotish library's calculations. These changes improve the precision of traditional Vedic astrology calculations by using ephemeris-based computations instead of approximations.

## Changes Summary

### 1. Shadbala Service - Maasa Bala Fix

**Issue**: Maasa Bala was using Gregorian calendar months instead of Hindu lunar months.

**Solution**: Now uses the Sun's position in the zodiac to determine the Hindu lunar month and its ruling planet.

**API Changes**:
- `_calculateMaasaBala()` is now async and accepts `VedicChart` instead of `DateTime`
- `_getMonthLord()` replaced with `_getMonthLordFromSunLongitude()` which uses actual Sun position

**Technical Details**:
- Sun's longitude determines the lunar month (Maasa)
- Each 30° zodiac sign corresponds to a specific month lord
- Example: Sun in Aries (0°-30°) = Chaitra month = Jupiter lord

### 2. Shadbala Service - Varsha Bala Fix

**Issue**: Varsha Bala used a simplified year pattern that didn't include all planets (missing Moon and Venus).

**Solution**: Now calculates the year lord based on Jupiter's actual position in the 60-year Samvatsara (Brihaspati) cycle.

**API Changes**:
- `_calculateVarshaBala()` is now async and accepts `VedicChart` instead of `DateTime`
- `_getYearLord()` replaced with `_getYearLordFromJupiter()` which uses Jupiter's position

**Technical Details**:
- Jupiter's sign and degree determine the 60-year cycle position
- All 7 traditional planets (Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn) serve as year lords
- Follows traditional Samvatsara assignments

### 3. Shadbala Service - Natonnata Bala Fix

**Issue**: Used simplified house position (Sun in houses 7-12 = day) instead of actual sunrise/sunset times.

**Solution**: Now uses Swiss Ephemeris to calculate precise sunrise and sunset times for accurate day/night determination.

**API Changes**:
- `_calculateNatonnataBala()` is now async
- Added `_calculateNatonnataBalaFallback()` for when ephemeris data is unavailable
- Falls back to house-based calculation only when necessary

**Technical Details**:
- Birth time compared against actual sunrise/sunset for the location
- Accurate even for charts near sunrise/sunset
- Location-aware calculations using geographic coordinates

### 4. Panchanga Service - Tithi End Time Fix

**Issue**: Used fixed 20 iterations for binary search instead of accuracy-based termination.

**Solution**: Now uses accuracy threshold (default: 1 second) to determine when to stop searching.

**API Changes**:
- `getTithiEndTime()` accepts new optional parameter: `accuracyThreshold` (in seconds)
- Continues searching until desired accuracy is achieved or max iterations reached
- Extended search window to 48 hours to handle variations in tithi length

**Technical Details**:
- Binary search continues until time window <= accuracy threshold
- Default: 1 second precision
- Maximum 50 iterations as safety limit
- More accurate end times for tithi calculations

### 5. Special Transit Service - Sade Sati Date Calculation Fix

**Issue**: Used constant average motion (0.028°/day) which ignores retrograde periods, causing errors of months.

**Solution**: Now uses ephemeris-based projection with binary search to find exact sign entry/exit dates.

**API Changes**:
- `_calculateSadeSati()` is now async
- `_calculateDhaiya()` is now async
- Added `_calculateSignExitDate()` for precise exit timing
- Added `_calculateSignEntryDate()` for precise entry timing
- Added `_calculatePhaseStartDate()` for Sade Sati phase calculations

**Technical Details**:
- Projects Saturn's position day by day using actual ephemeris data
- Accounts for retrograde motion automatically
- 1-hour precision for date calculations
- Accurate within days instead of months

## Usage Examples

### Before (Old Approximations):
```dart
// Maasa Bala - Used calendar month
final monthLord = _getMonthLord(dateTime.month); // ❌ Gregorian month

// Varsha Bala - Used simplified pattern
final yearLord = _getYearLord(dateTime.year); // ❌ Missing Moon/Venus

// Natonnata Bala - Used house position
final isDay = sunHouse > 6; // ❌ Simplified

// Tithi End - Fixed iterations
for (var i = 0; i < 20; i++) { ... } // ❌ Fixed count

// Sade Sati - Average motion
const averageDailyMotion = 0.028; // ❌ Ignores retrograde
```

### After (Ephemeris-Based):
```dart
// Maasa Bala - Uses Sun's position
final monthLord = _getMonthLordFromSunLongitude(sunLongitude); // ✅ Accurate

// Varsha Bala - Uses Jupiter's position
final yearLord = await _getYearLordFromJupiter(chart); // ✅ All planets

// Natonnata Bala - Uses actual sunrise/sunset
final sunriseSunset = await _ephemerisService.getSunriseSunset(...); // ✅ Precise

// Tithi End - Accuracy threshold
while (window > accuracyThreshold) { ... } // ✅ Variable precision

// Sade Sati - Ephemeris projection
await _calculateSignExitDate(...); // ✅ Accounts for retrograde
```

## Accuracy Improvements

| Calculation | Before | After | Improvement |
|------------|--------|-------|-------------|
| Maasa Bala | Calendar month | Sun's zodiac position | Traditionally accurate |
| Varsha Bala | 5 planets only | All 7 planets | Complete Samvatsara cycle |
| Natonnata Bala | House-based | Sunrise/sunset times | Precise day/night detection |
| Tithi End | ~1 minute | ~1 second | 60x more precise |
| Sade Sati Dates | ± months | ± days | Substantial accuracy gain |

## Backward Compatibility

These changes maintain API compatibility where possible:
- All public methods remain accessible with same signatures
- Internal methods marked as async where needed
- Fallback mechanisms provided for edge cases
- No breaking changes to public API

## Testing Recommendations

When testing these changes:

1. **Maasa Bala**: Compare against traditional Panchanga calendars
2. **Varsha Bala**: Verify against 60-year Samvatsara tables
3. **Natonnata Bala**: Test charts near sunrise/sunset times
4. **Tithi End**: Compare with known tithi change times
5. **Sade Sati**: Verify against historical Saturn transit data

## References

- Parashara Hora Shastra (Shadbala calculations)
- Surya Siddhanta (Astronomical principles)
- Swiss Ephemeris documentation (for ephemeris calculations)
- Traditional Panchanga texts (for month/year lord assignments)
