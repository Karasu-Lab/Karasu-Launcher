import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/minecraft_state.dart';

final minecraftStateProvider =
    StateNotifierProvider<MinecraftStateNotifier, MinecraftState>((ref) {
      return MinecraftStateNotifier();
    });

class MinecraftStateNotifier extends StateNotifier<MinecraftState> {
  MinecraftStateNotifier() : super(MinecraftState());

  void setLaunching(bool isLaunching) {
    state = state.copyWith(
      isLaunching: isLaunching,
      isGlobalLaunching: isLaunching,
    );
  }

  void setUserLaunching(String userId, bool isLaunching) {
    final Map<String, bool> updatedLaunchingUsers = Map.from(
      state.launchingUsers,
    );

    if (isLaunching) {
      updatedLaunchingUsers[userId] = true;
    } else {
      updatedLaunchingUsers.remove(userId);
    }

    state = state.copyWith(launchingUsers: updatedLaunchingUsers);
  }

  bool isUserLaunching(String userId) {
    return state.launchingUsers.containsKey(userId);
  }

  int get launchingUsersCount => state.launchingUsers.length;

  List<String> get launchingUserIds => state.launchingUsers.keys.toList();

  void setUserLaunchingProfile(
    String userId,
    String profileId, {
    bool isOfflineUser = false,
  }) {
    final Map<String, List<String>> updatedUserProfiles = Map.from(
      state.userLaunchingProfiles,
    );

    if (!updatedUserProfiles.containsKey(userId)) {
      updatedUserProfiles[userId] = [];
    }

    if (!updatedUserProfiles[userId]!.contains(profileId)) {
      updatedUserProfiles[userId] = [
        ...updatedUserProfiles[userId]!,
        profileId,
      ];
    }

    setUserLaunching(userId, true);

    if (isOfflineUser) {
      final Map<String, bool> updatedOfflineUsers = Map.from(
        state.offlineUsers,
      );
      updatedOfflineUsers[userId] = true;
      state = state.copyWith(
        offlineUsers: updatedOfflineUsers,
        userLaunchingProfiles: updatedUserProfiles,
      );
    } else {
      state = state.copyWith(userLaunchingProfiles: updatedUserProfiles);
    }
  }

  void removeUserLaunchingProfile(String userId, String profileId) {
    final Map<String, List<String>> updatedUserProfiles = Map.from(
      state.userLaunchingProfiles,
    );

    if (updatedUserProfiles.containsKey(userId)) {
      final updatedProfileIds =
          updatedUserProfiles[userId]!.where((id) => id != profileId).toList();

      if (updatedProfileIds.isEmpty) {
        updatedUserProfiles.remove(userId);
        state = state.copyWith(userLaunchingProfiles: updatedUserProfiles);
        resetUserProgress(userId);
      } else {
        updatedUserProfiles[userId] = updatedProfileIds;
        state = state.copyWith(userLaunchingProfiles: updatedUserProfiles);
      }
    }
  }

  List<String> getUserLaunchingProfiles(String userId) {
    return state.userLaunchingProfiles[userId] ?? [];
  }

  bool isUserLaunchingProfile(String userId, String profileId) {
    return state.userLaunchingProfiles[userId]?.contains(profileId) ?? false;
  }

  bool isOfflineUser(String userId) {
    return state.offlineUsers[userId] ?? false;
  }

  List<String> get offlineUserIds => state.offlineUsers.keys.toList();

  void clearUserLaunchingProfiles(String userId) {
    final Map<String, List<String>> updatedUserProfiles = Map.from(
      state.userLaunchingProfiles,
    );
    updatedUserProfiles.remove(userId);

    final Map<String, bool> updatedOfflineUsers = Map.from(state.offlineUsers);
    updatedOfflineUsers.remove(userId);

    state = state.copyWith(
      userLaunchingProfiles: updatedUserProfiles,
      offlineUsers: updatedOfflineUsers,
    );

    resetUserProgress(userId);
  }

  void updateProgress(double value, String text) {
    state = state.copyWith(progressValue: value, progressText: text);
  }

  void updateUserProgress(String userId, double value, String text) {
    final Map<String, UserProgress> updatedUserProgress = Map.from(
      state.userProgress,
    );
    updatedUserProgress[userId] = UserProgress(value: value, text: text);

    state = state.copyWith(userProgress: updatedUserProgress);
  }

  UserProgress? getUserProgress(String userId) {
    return state.userProgress[userId];
  }

  void resetProgress() {
    state = state.copyWith(
      isLaunching: false,
      progressValue: 0.0,
      progressText: 'Play',
    );
  }

  void resetUserProgress(String userId) {
    final Map<String, UserProgress> updatedUserProgress = Map.from(
      state.userProgress,
    );
    updatedUserProgress.remove(userId);

    final Map<String, bool> updatedLaunchingUsers = Map.from(
      state.launchingUsers,
    );
    updatedLaunchingUsers.remove(userId);

    state = state.copyWith(
      userProgress: updatedUserProgress,
      launchingUsers: updatedLaunchingUsers,
    );
  }

  void addLog(String message, {LogLevel level = LogLevel.info}) {
    final log = LogMessage(message: message, level: level);
    state = state.copyWith(logs: [...state.logs, log]);
  }

  void addJavaLog(
    String message, {
    LogLevel level = LogLevel.info,
    LogSource source = LogSource.app,
    String? userId,
  }) {
    final prefix =
        level == LogLevel.error || level == LogLevel.warning ? '[Java] ' : '';
    final userPrefix = userId != null ? '[User: $userId] ' : '';

    final log = LogMessage(
      message: userPrefix + prefix + message,
      level: level,
      source: source,
    );
    state = state.copyWith(logs: [...state.logs, log]);
  }

  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  void onAssetsProgress(double progress, int current, int total) {
    // 常にUIの進捗は更新する
    updateProgress(
      progress,
      'Downloading assets: ${(progress * 100).toInt()}%',
    );

    // 10%単位でのみログを出力する
    if (current == 1 ||
        current == total ||
        (progress * 10).toInt() != ((progress - (1.0 / total)) * 10).toInt()) {
      addLog(
        'Downloading assets: $current/$total (${(progress * 100).toInt()}%)',
        level: LogLevel.info,
      );
    }
  }

  void onUserAssetsProgress(
    String userId,
    double progress,
    int current,
    int total,
  ) {
    // 常にUIの進捗は更新する
    updateUserProgress(
      userId,
      progress,
      'Downloading assets: ${(progress * 100).toInt()}%',
    );

    // 10%単位でのみログを出力する
    if (current == 1 ||
        current == total ||
        (progress * 10).toInt() != ((progress - (1.0 / total)) * 10).toInt()) {
      addLog(
        '[User: $userId] Downloading assets: $current/$total (${(progress * 100).toInt()}%)',
        level: LogLevel.debug,
      );
    }
  }

  void onLibrariesProgress(double progress, int current, int total) {
    updateProgress(
      progress,
      'Downloading libraries: ${(progress * 100).toInt()}%',
    );
    addLog(
      'Downloading libraries: $current/$total (${(progress * 100).toInt()}%)',
      level: LogLevel.info,
    );
  }

  void onUserLibrariesProgress(
    String userId,
    double progress,
    int current,
    int total,
  ) {
    updateUserProgress(
      userId,
      progress,
      'Downloading libraries: ${(progress * 100).toInt()}%',
    );
    addLog(
      '[User: $userId] Downloading libraries: $current/$total (${(progress * 100).toInt()}%)',
      level: LogLevel.warning,
    );
  }

  void onPrepareComplete() {
    updateProgress(1.0, 'Launching...');
    addLog('Minecraft preparation complete', level: LogLevel.info);
  }

  void onUserPrepareComplete(String userId) {
    updateUserProgress(userId, 1.0, 'Launching...');
    addLog(
      '[User: $userId] Minecraft preparation complete',
      level: LogLevel.info,
    );
  }

  void onNativesProgress(double progress, int current, int total) {
    updateProgress(
      progress,
      'Extracting native libraries: ${(progress * 100).toInt()}%',
    );
    addLog(
      'Extracting native libraries: $current/$total (${(progress * 100).toInt()}%)',
      level: LogLevel.info,
    );
  }

  void onUserNativesProgress(
    String userId,
    double progress,
    int current,
    int total,
  ) {
    updateUserProgress(
      userId,
      progress,
      'Extracting native libraries: ${(progress * 100).toInt()}%',
    );
    addLog(
      '[User: $userId] Extracting native libraries: $current/$total (${(progress * 100).toInt()}%)',
      level: LogLevel.info,
    );
  }

  void onExit(int? exitCode, bool normal, String? userId, String? profileId) {
    if (userId != null && profileId != null) {
      removeUserLaunchingProfile(userId, profileId);
    }

    resetProgress();
    final exitMessage =
        normal
            ? 'Minecraft exited normally (exit code: $exitCode)'
            : 'Minecraft exited abnormally (exit code: $exitCode)';
    addLog(exitMessage, level: normal ? LogLevel.info : LogLevel.error);
  }

  void onUserExit(
    String userId,
    int? exitCode,
    bool normal, {
    String? profileId,
  }) {
    if (profileId != null) {
      removeUserLaunchingProfile(userId, profileId);
    } else {
      clearUserLaunchingProfiles(userId);
    }

    resetUserProgress(userId);
    final exitMessage =
        normal
            ? '[User: $userId] Minecraft exited normally (exit code: $exitCode)'
            : '[User: $userId] Minecraft exited abnormally (exit code: $exitCode)';
    addLog(exitMessage, level: normal ? LogLevel.info : LogLevel.error);
  }

  void onMinecraftLaunch() {
    addLog('Minecraft has been launched', level: LogLevel.info);
    resetProgress();
  }
}
