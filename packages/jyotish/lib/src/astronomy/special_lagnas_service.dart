import 'package:jyotish/src/models/vedic_chart.dart';
import 'package:jyotish/src/models/planet.dart';
import 'package:jyotish/src/models/special_lagnas.dart';

/// Service for calculating special time-proportionate and mathematical lagnas.
class SpecialLagnasService {
  const SpecialLagnasService();

  /// Calculates Hora Lagna, Ghati Lagna, and Sree Lagna for a birth chart given the sunrise time.
  ///
  /// [sunLongitudeAtSunrise] optionally pins the anchor exactly. When omitted
  /// the Sun's longitude at sunrise is derived by rewinding the chart's Sun
  /// using its own `longitudeSpeed`, which is accurate to < 0.01 degrees over
  /// the few hours involved.
  SpecialLagnas calculateSpecialLagnas(
    VedicChart chart,
    DateTime sunrise, {
    double? sunLongitudeAtSunrise,
  }) {
    final ascendant = chart.ascendant;
    final birthTime = chart.dateTime;

    final sunInfo = chart.getPlanet(Planet.sun);
    final sunLongAtBirth = sunInfo?.longitude ?? 0.0;

    // Calculate elapsed time in hours from sunrise to birth time.
    var elapsedMs = birthTime.difference(sunrise).inMilliseconds;
    if (elapsedMs < 0) {
      // If birth is before today's sunrise, adjust by 24 hours
      elapsedMs += const Duration(days: 1).inMilliseconds;
    }
    final elapsedHours = elapsedMs / (1000 * 60 * 60);

    // Rewind the Sun from its birth position to its position at SUNRISE.
    //
    // BPHS Ch. 5 anchors Hora/Ghati Lagna at the Sun's longitude at the start
    // of the elapsed interval. Using the birth-moment Sun while also adding
    // hours measured from sunrise counts the Sun's own motion across that
    // window twice — about 1 degree of error per hour of elapsed time, so a
    // 6-hour gap alone is ~6 degrees.
    //
    // `longitudeSpeed` is degrees/day, so this rewinds accurately; the residual
    // error from assuming a constant speed over a few hours is < 0.01 degrees.
    // Callers that already know the Sun's longitude at sunrise can pass it via
    // [sunLongitudeAtSunrise] to skip the extrapolation entirely.
    final sunLong = (sunLongitudeAtSunrise ??
            (sunLongAtBirth -
                (sunInfo?.position.longitudeSpeed ?? 0.9856) *
                    (elapsedMs / (1000 * 60 * 60 * 24)) +
                360.0) %
                360.0) %
        360.0;

    // 1. Hora Lagna (HL): one sign (30 degrees) per 2.5 ghatis.
    //
    // 2.5 ghatis is 60 minutes, i.e. ONE HOUR, so this is 30 degrees per hour.
    // Note the unit trap: the classical statement is "per 2.5 ghatis", not "per
    // 2.5 hours". Reading it as hours (as an earlier revision did) advances the
    // lagna by only 12 degrees per 2.5 ghatis — a 2.5x error that runs the
    // other way to the alternative "one sign per 2.5 hours" formulation some
    // texts use. This implementation follows the ghati reading.
    final horaLagna = (sunLong + elapsedHours * 30.0) % 360.0;

    // 2. Ghati Lagna (GL): one sign (30 degrees) per ghati.
    // 1 ghati = 0.4 hours = 24 minutes, so 15 ghatis over a 6-hour window.
    final ghatiLagna = (sunLong + (elapsedHours / 0.4) * 30.0) % 360.0;

    // 3. Sree Lagna (SL): Point of Lakshmi based on Moon's nakshatra fraction added to Ascendant.
    final moonInfo = chart.getPlanet(Planet.moon);
    final double moonLong = moonInfo?.longitude ?? 0.0;
    const nakshatraSpan = 360.0 / 27.0; // 13.333333 degrees
    final posInNakshatra = moonLong % nakshatraSpan;
    final fraction = posInNakshatra / nakshatraSpan;
    final sreeLagna = (ascendant + fraction * 360.0) % 360.0;

    return SpecialLagnas(
      horaLagna: horaLagna,
      ghatiLagna: ghatiLagna,
      sreeLagna: sreeLagna,
    );
  }
}
