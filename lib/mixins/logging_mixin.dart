import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/providers/log_provider.dart';

mixin LoggingMixin {
  Ref get ref;

  void logInfo(String message, {LogSource source = LogSource.app}) {
    _addLog(message, LogLevel.info, source);
  }

  void logDebug(String message, {LogSource source = LogSource.app}) {
    _addLog(message, LogLevel.debug, source);
  }

  void logWarning(String message, {LogSource source = LogSource.app}) {
    _addLog(message, LogLevel.warning, source);
  }

  void logError(String message, {LogSource source = LogSource.app}) {
    _addLog(message, LogLevel.error, source);
  }

  void logJava(
    String message, {
    LogLevel level = LogLevel.info,
    bool isStderr = false,
    String? userId,
  }) {
    final prefix =
        level == LogLevel.error || level == LogLevel.warning ? '[Java] ' : '';
    final userPrefix = userId != null ? '[User: $userId] ' : '';
    final logMessage = userPrefix + prefix + message;

    final source = isStderr ? LogSource.javaStdErr : LogSource.javaStdOut;

    ref
        .read(logProvider.notifier)
        .addLog(LogMessage(source: source, level: level, message: logMessage));
  }

  void clearLogs() {
    ref.read(logProvider.notifier).clearLogs();
  }

  void _addLog(String message, LogLevel level, LogSource source) {
    ref
        .read(logProvider.notifier)
        .addLog(LogMessage(source: source, level: level, message: message));
  }
}
