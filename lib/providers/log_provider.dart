import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/mixins/logging_mixin.dart';

/// ログレベルの列挙型
enum LogLevel { info, debug, warning, error }

/// ログソースの列挙型
enum LogSource { app, javaStdOut, javaStdErr, network }

/// ログメッセージクラス
class LogMessage {
  final String source;
  final LogLevel level;
  final dynamic message;
  final DateTime timestamp;

  LogMessage({
    required this.source,
    required this.level,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return '[$timestamp] [${level.name.toUpperCase()}] [$source] $message';
  }
}

/// ログの状態を管理するクラス
class LogState {
  final List<LogMessage> logs;

  const LogState({this.logs = const []});

  LogState copyWith({List<LogMessage>? logs}) {
    return LogState(logs: logs ?? this.logs);
  }
}

/// ログの状態を管理するNotifierクラス
class LogNotifier extends StateNotifier<LogState> with LoggingMixin {
  final Ref _ref;

  LogNotifier(this._ref) : super(const LogState());

  @override
  Ref get ref => _ref;

  /// ログを追加
  void addLog(LogMessage log) {
    state = state.copyWith(logs: [...state.logs, log]);
  }

  /// 情報ログを追加
  void info(String source, dynamic message) {
    addLog(LogMessage(source: source, level: LogLevel.info, message: message));
  }

  /// デバッグログを追加
  void debug(String source, dynamic message) {
    addLog(LogMessage(source: source, level: LogLevel.debug, message: message));
  }

  /// 警告ログを追加
  void warning(String source, dynamic message) {
    addLog(
      LogMessage(source: source, level: LogLevel.warning, message: message),
    );
  }

  /// エラーログを追加
  void error(String source, dynamic message) {
    addLog(LogMessage(source: source, level: LogLevel.error, message: message));
  }

  /// ログをクリア (mixinからの実装を使用)
  @override
  void clearLogs() {
    state = state.copyWith(logs: []);
  }
}

/// ログプロバイダー
final logProvider = StateNotifierProvider<LogNotifier, LogState>((ref) {
  return LogNotifier(ref);
});
