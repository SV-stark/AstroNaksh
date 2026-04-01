import 'dart:io';
import 'package:flutter/foundation.dart';
import 'app_environment.dart';

enum ErrorSeverity { info, warning, error, critical }

class AppError {
  final String message;
  final ErrorSeverity severity;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final String? context;
  final DateTime timestamp;

  AppError({
    required this.message,
    this.severity = ErrorSeverity.error,
    this.originalError,
    this.stackTrace,
    this.context,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    final buf = StringBuffer();
    buf.write('[${severity.name.toUpperCase()}] $message');
    if (context != null) buf.write(' (context: $context)');
    if (originalError != null) buf.write('\n  Caused by: $originalError');
    if (stackTrace != null && AppEnvironment.isVerbose) {
      buf.write('\n$stackTrace');
    }
    return buf.toString();
  }
}

typedef ErrorCallback = void Function(AppError error);

class AppErrorHandler {
  static final AppErrorHandler _instance = AppErrorHandler._internal();
  factory AppErrorHandler() => _instance;
  AppErrorHandler._internal();

  final List<ErrorCallback> _listeners = [];
  final List<AppError> _recentErrors = [];
  static const _maxRecentErrors = 50;

  void addListener(ErrorCallback callback) => _listeners.add(callback);
  void removeListener(ErrorCallback callback) => _listeners.remove(callback);

  List<AppError> get recentErrors => List.unmodifiable(_recentErrors);

  void handle(
    Object error, {
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.error,
    String? context,
    String? userMessage,
  }) {
    final appError = AppError(
      message: userMessage ?? _friendlyMessage(error),
      severity: severity,
      originalError: error,
      stackTrace: stackTrace,
      context: context,
    );

    _log(appError);
    _recentErrors.add(appError);
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeAt(0);
    }

    for (final listener in List.of(_listeners)) {
      try {
        listener(appError);
      } catch (_) {}
    }
  }

  T safe<T>(
    T Function() operation, {
    T? defaultValue,
    ErrorSeverity severity = ErrorSeverity.error,
    String? context,
    String? userMessage,
  }) {
    try {
      return operation();
    } catch (e, st) {
      handle(
        e,
        stackTrace: st,
        severity: severity,
        context: context,
        userMessage: userMessage,
      );
      return defaultValue as T;
    }
  }

  Future<T> safeAsync<T>(
    Future<T> Function() operation, {
    T? defaultValue,
    ErrorSeverity severity = ErrorSeverity.error,
    String? context,
    String? userMessage,
  }) async {
    try {
      return await operation();
    } catch (e, st) {
      handle(
        e,
        stackTrace: st,
        severity: severity,
        context: context,
        userMessage: userMessage,
      );
      return defaultValue as T;
    }
  }

  void clear() {
    _recentErrors.clear();
  }

  void _log(AppError error) {
    if (error.severity == ErrorSeverity.critical) {
      AppEnvironment.log('CRITICAL: $error');
      if (AppEnvironment.isVerbose) {
        stderr.writeln(error.toString());
      }
    } else if (error.severity == ErrorSeverity.error) {
      AppEnvironment.log('ERROR: ${error.message}');
      if (AppEnvironment.isVerbose && error.originalError != null) {
        AppEnvironment.log('  Caused by: ${error.originalError}');
      }
    } else if (error.severity == ErrorSeverity.warning) {
      AppEnvironment.log('WARNING: ${error.message}');
    } else {
      if (AppEnvironment.isVerbose) {
        AppEnvironment.log('INFO: ${error.message}');
      }
    }
  }

  String _friendlyMessage(Object error) {
    final msg = error.toString();
    if (msg.contains('SocketException') || msg.contains('Network')) {
      return 'Network connection failed. Please check your internet connection.';
    }
    if (msg.contains('TimeoutException')) {
      return 'The operation timed out. Please try again.';
    }
    if (msg.contains('FileSystemException') ||
        msg.contains('PathNotFoundException')) {
      return 'Unable to access required files. Please reinstall the application.';
    }
    if (msg.contains('FormatException')) {
      return 'Invalid data format encountered. The data may be corrupted.';
    }
    if (msg.contains('Null check operator used on a null value')) {
      return 'An unexpected error occurred. Please report this issue.';
    }
    return msg.length > 200 ? '${msg.substring(0, 200)}...' : msg;
  }
}

final errorHandler = AppErrorHandler();
