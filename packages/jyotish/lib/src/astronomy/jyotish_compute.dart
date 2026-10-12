import 'dart:async';
import 'dart:isolate';
import 'package:synchronized/synchronized.dart';

/// A safe runner for executing heavy Jyotish calculations on a background isolate.
///
/// ### C-FFI Multi-Isolate Safety Note:
/// Swiss Ephemeris is a native C library compiled with process-global static state
/// (e.g. calculation buffers, active ayanamsa mode, and topocentric geographic parameters).
/// While in-memory Dart mutexes (`Lock`) serialize calls within a single isolate,
/// launching multiple simultaneous background isolates via raw `compute()` or `Isolate.run()`
/// can cause multiple threads in the OS process to concurrently invoke `swe_calc_ut`,
/// leading to race conditions in C static variables.
///
/// [JyotishCompute] serializes background isolate dispatches to guarantee that
/// only one isolate executes Swiss Ephemeris C calculations at any given moment,
/// keeping the Flutter UI thread responsive at 60/120 fps without native race conditions.
///
/// ### Example:
/// ```dart
/// final chart = await JyotishCompute.run(() async {
///   final jyotish = Jyotish();
///   await jyotish.initialize();
///   return jyotish.calculateChart(
///     dateTime: DateTime.now(),
///     location: const GeographicLocation(latitude: 28.6139, longitude: 77.2090),
///   );
/// });
/// ```
class JyotishCompute {
  JyotishCompute._();

  static final Lock _queueLock = Lock();

  /// Executes [computation] in a background isolate using [Isolate.run], serialized
  /// through a queue to prevent concurrent multi-isolate corruption of Swiss Ephemeris C state.
  static Future<R> run<R>(FutureOr<R> Function() computation) {
    return _queueLock.synchronized(() => Isolate.run(computation));
  }
}
