class MinecraftState {
  final bool isLaunching;

  final double progressValue;

  final String progressText;

  final List<LogMessage> logs;

  const MinecraftState({
    this.isLaunching = false,
    this.progressValue = 0.0,
    this.progressText = 'プレイ',
    this.logs = const [],
  });

  MinecraftState copyWith({
    bool? isLaunching,
    double? progressValue,
    String? progressText,
    List<LogMessage>? logs,
  }) {
    return MinecraftState(
      isLaunching: isLaunching ?? this.isLaunching,
      progressValue: progressValue ?? this.progressValue,
      progressText: progressText ?? this.progressText,
      logs: logs ?? this.logs,
    );
  }
}

class LogMessage {
  final DateTime timestamp;
  final String message;
  final LogLevel level;
  final LogSource source;

  LogMessage({
    required this.message,
    this.level = LogLevel.info,
    this.source = LogSource.app,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return '${timestamp.toIso8601String()} [${describeEnum(source)}:${describeEnum(level)}] $message';
  }
}

enum LogLevel { debug, info, warning, error }

enum LogSource { app, javaStdOut, javaStdErr }

String describeEnum(Object enumValue) {
  final String description = enumValue.toString();
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}
