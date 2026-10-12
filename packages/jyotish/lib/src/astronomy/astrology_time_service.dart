import '../exceptions/jyotish_exception.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for handling high-precision historical timezone conversions.
///
/// This service uses the IANA/Olson database to convert local times
/// to UTC for any historical date, accounting for local DST changes.
class AstrologyTimeService {
  static bool _isInitialized = false;

  /// Initializes the timezone database.
  ///
  /// This must be called once before performing any conversions.
  static void initialize() {
    if (_isInitialized) return;
    tz.initializeTimeZones();
    _isInitialized = true;
  }

  /// Loads custom/updated timezone database bytes at runtime.
  ///
  /// [databaseBytes] - Raw bytes of a timezone/zoneinfo database file (.tzf).
  ///
  /// The tz package clears the global database *before* parsing, so malformed
  /// bytes would otherwise leave the process with no zones at all. The current
  /// locations are snapshotted and restored when parsing fails, keeping the
  /// failure contained to this call.
  static void loadDatabase(List<int> databaseBytes) {
    final previous = Map<String, tz.Location>.of(tz.timeZoneDatabase.locations);
    try {
      tz.initializeDatabase(databaseBytes);
      _isInitialized = true;
    } catch (e) {
      tz.timeZoneDatabase.clear();
      previous.forEach((_, location) => tz.timeZoneDatabase.add(location));
      _isInitialized = previous.isNotEmpty;
      rethrow;
    }
  }

  /// Converts a local date and time to UTC using a specific IANA timezone ID.
  ///
  /// [localDt] - The date and time in the local timezone.
  /// [zoneId] - The IANA timezone ID (e.g., 'Asia/Kolkata', 'America/New_York').
  ///
  /// Returns a [DateTime] in UTC.
  ///
  /// Throws [ValidationException] if [zoneId] cannot be resolved.
  static DateTime localToUtc(DateTime localDt, String zoneId) {
    final location = _getLocationOrThrow(zoneId);
    final tzDt = tz.TZDateTime(
      location,
      localDt.year,
      localDt.month,
      localDt.day,
      localDt.hour,
      localDt.minute,
      localDt.second,
      localDt.millisecond,
      localDt.microsecond,
    );
    return tzDt.toUtc();
  }

  /// Gets the timezone offset for a specific date and timezone.
  ///
  /// Returns a [Duration] representing the offset from UTC.
  ///
  /// Throws [ValidationException] if [zoneId] cannot be resolved.
  static Duration getOffset(DateTime date, String zoneId) {
    final location = _getLocationOrThrow(zoneId);
    final tzDt = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
    );
    return Duration(milliseconds: tzDt.timeZoneOffset.inMilliseconds);
  }

  /// Converts a UTC date and time to a local date and time using a specific IANA timezone ID.
  ///
  /// Returns a [DateTime] whose fields represent the wall-clock time in
  /// [zoneId], resolved against the host zone (as elsewhere in this library).
  ///
  /// Throws [ValidationException] if [zoneId] cannot be resolved.
  static DateTime utcToLocal(DateTime utcDt, String zoneId) {
    final location = _getLocationOrThrow(zoneId);
    final tzDt = tz.TZDateTime.from(utcDt, location);
    return DateTime(
      tzDt.year,
      tzDt.month,
      tzDt.day,
      tzDt.hour,
      tzDt.minute,
      tzDt.second,
      tzDt.millisecond,
      tzDt.microsecond,
    );
  }

  /// Gets a list of all available IANA timezone IDs.
  static List<String> get availableTimezones =>
      tz.timeZoneDatabase.locations.keys.toList();

  /// Well-known UTC aliases, mapped to a canonical zero-offset zone.
  ///
  /// These are genuine IANA aliases, so resolving them is exact rather than a
  /// fallback that invents a result. They are also what the library's own
  /// `location.timezone ?? 'UTC'` defaults depend on.
  static const Map<String, String> _utcAliases = {
    'UTC': 'Etc/UTC',
    'GMT': 'Etc/GMT',
    'Etc/UTC': 'Etc/UTC',
    'Etc/GMT': 'Etc/GMT',
    'Z': 'Etc/UTC',
    'Zulu': 'Etc/UTC',
    'Universal': 'Etc/UTC',
  };

  /// Resolves [zoneId] to a [tz.Location], throwing on failure.
  ///
  /// There is deliberately no UTC fallback: an unknown zone must not yield a
  /// plausible-but-wrong instant. Reinterpreting a naive local wall clock as
  /// UTC shifts the resulting moment by the true zone offset (e.g. 10:00 IST
  /// read as 10:00 UTC is a 5.5 h error, ~82 degrees of ascendant), and it
  /// fails silently rather than surfacing the bad input.
  static tz.Location _getLocationOrThrow(String zoneId) {
    _ensureInitialized();

    final resolved = _utcAliases[zoneId] ?? zoneId;
    try {
      return tz.getLocation(resolved);
    } on tz.LocationNotFoundException catch (e) {
      throw ValidationException(
        'Unknown IANA timezone "$zoneId". Check AstrologyTimeService.'
        'availableTimezones for valid IDs.',
        originalError: e,
      );
    } on tz.TimeZoneInitException catch (e) {
      throw ValidationException(
        'Timezone database could not be queried for "$zoneId".',
        originalError: e,
      );
    }
  }

  static void _ensureInitialized() {
    if (!_isInitialized) {
      initialize();
    }
  }
}
