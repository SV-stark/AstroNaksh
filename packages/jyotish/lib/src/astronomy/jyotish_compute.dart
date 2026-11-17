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
/// [JyotishCompute] maintains a persistent, lazy-initialized background worker isolate
/// and serializes dispatches through a queue. This avoids repeated isolate spawn and
/// Swiss Ephemeris FFI initialization overhead while guaranteeing that only one
/// calculation executes C calls at any given moment.
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
  static SendPort? _workerSendPort;
  static Isolate? _workerIsolate;

  /// Executes [computation] on the persistent background worker isolate,
  /// serialized through a queue to prevent concurrent corruption of
  /// Swiss Ephemeris C state.
  static Future<R> run<R>(FutureOr<R> Function() computation) {
    return _queueLock.synchronized(() async {
      final sendPort = await _ensureWorker();
      final responsePort = ReceivePort();
      try {
        sendPort.send((computation, responsePort.sendPort));
        final message = await responsePort.first;
        if (message is _WorkerError) {
          Error.throwWithStackTrace(message.error, message.stackTrace);
        }
        return (message as _WorkerResult<Object?>).value as R;
      } finally {
        responsePort.close();
      }
    });
  }

  /// Shuts down the persistent background worker isolate, if running.
  ///
  /// A subsequent call to [run] will lazily spawn a fresh worker isolate.
  static Future<void> dispose() {
    return _queueLock.synchronized(() async {
      _workerSendPort?.send(null);
      _workerSendPort = null;
      _workerIsolate?.kill(priority: Isolate.immediate);
      _workerIsolate = null;
    });
  }

  static Future<SendPort> _ensureWorker() async {
    final existing = _workerSendPort;
    if (existing != null) return existing;

    final initPort = ReceivePort();
    try {
      _workerIsolate = await Isolate.spawn(
        _workerMain,
        initPort.sendPort,
        debugName: 'JyotishComputeWorker',
      );
      final sendPort = await initPort.first as SendPort;
      _workerSendPort = sendPort;
      return sendPort;
    } finally {
      initPort.close();
    }
  }
}

void _workerMain(SendPort initReplyPort) {
  final commandPort = ReceivePort();
  initReplyPort.send(commandPort.sendPort);

  commandPort.listen((message) async {
    if (message == null) {
      commandPort.close();
      return;
    }

    final (computation, replyPort) =
        message as (FutureOr<Object?> Function(), SendPort);
    try {
      final result = await computation();
      replyPort.send(_WorkerResult<Object?>(result));
    } catch (error, stackTrace) {
      replyPort.send(_WorkerError(error, stackTrace));
    }
  });
}

final class _WorkerResult<T> {
  const _WorkerResult(this.value);
  final T value;
}

final class _WorkerError {
  const _WorkerError(this.error, this.stackTrace);
  final Object error;
  final StackTrace stackTrace;
}
