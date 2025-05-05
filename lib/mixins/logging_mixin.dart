import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/providers/log_provider.dart';

/// ロギング機能を提供するMixin
mixin LoggingMixin {
  /// Riverpodの参照
  Ref get ref;

  /// 情報ログを追加
  void logInfo(String message, {String source = 'app'}) {
    _addLog(message, LogLevel.info, source);
  }

  /// デバッグログを追加
  void logDebug(String message, {String source = 'app'}) {
    _addLog(message, LogLevel.debug, source);
  }

  /// 警告ログを追加
  void logWarning(String message, {String source = 'app'}) {
    _addLog(message, LogLevel.warning, source);
  }

  /// エラーログを追加
  void logError(String message, {String source = 'app'}) {
    _addLog(message, LogLevel.error, source);
  }

  /// Javaログを追加
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
    final source = isStderr ? 'javaStdErr' : 'javaStdOut';

    _addLog(logMessage, level, source);
  }

  /// ログをクリア
  void clearLogs() {
    ref.read(logProvider.notifier).clearLogs();
  }

  /// ログを追加（内部メソッド）
  void _addLog(String message, LogLevel level, String source) {
    ref
        .read(logProvider.notifier)
        .addLog(LogMessage(source: source, level: level, message: message));
  }
}
