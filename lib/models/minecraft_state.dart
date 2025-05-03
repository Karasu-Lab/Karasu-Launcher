class UserProgress {
  final double value;
  final String text;

  UserProgress({required this.value, required this.text});
}

class MinecraftState {
  final bool isLaunching;
  final bool isGlobalLaunching; // グローバル起動フラグを追加
  final double progressValue;
  final String progressText;
  final List<LogMessage> logs;
  final Map<String, bool> launchingUsers;
  final Map<String, UserProgress> userProgress;
  final Map<String, List<String>> userLaunchingProfiles;
  final Map<String, bool> offlineUsers;

  const MinecraftState({
    this.isLaunching = false,
    this.isGlobalLaunching = false,
    this.progressValue = 0.0,
    this.progressText = 'プレイ',
    this.logs = const [],
    this.launchingUsers = const {},
    this.userProgress = const {},
    this.userLaunchingProfiles = const {},
    this.offlineUsers = const {},
  });

  MinecraftState copyWith({
    bool? isLaunching,
    bool? isGlobalLaunching,
    double? progressValue,
    String? progressText,
    List<LogMessage>? logs,
    Map<String, bool>? launchingUsers,
    Map<String, UserProgress>? userProgress,
    Map<String, List<String>>? userLaunchingProfiles,
    Map<String, bool>? offlineUsers,
  }) {
    return MinecraftState(
      isLaunching: isLaunching ?? this.isLaunching,
      isGlobalLaunching: isGlobalLaunching ?? this.isGlobalLaunching,
      progressValue: progressValue ?? this.progressValue,
      progressText: progressText ?? this.progressText,
      logs: logs ?? this.logs,
      launchingUsers: launchingUsers ?? this.launchingUsers,
      userProgress: userProgress ?? this.userProgress,
      userLaunchingProfiles: userLaunchingProfiles ?? this.userLaunchingProfiles,
      offlineUsers: offlineUsers ?? this.offlineUsers,
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
