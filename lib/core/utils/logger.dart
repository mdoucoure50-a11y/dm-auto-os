import 'package:flutter/foundation.dart';

/// Lightweight logger for development and debugging.
abstract final class AppLogger {
  static void debug(String message, [Object? data]) {
    if (kDebugMode) {
      debugPrint('[DM Auto OS] $message${data != null ? ': $data' : ''}');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[DM Auto OS ERROR] $message');
      if (error != null) debugPrint('  Error: $error');
      if (stackTrace != null) debugPrint('  Stack: $stackTrace');
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[DM Auto OS INFO] $message');
    }
  }
}
