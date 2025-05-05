import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/minecraft_state.dart';
import 'package:karasu_launcher/providers/log_provider.dart';
import 'package:karasu_launcher/mixins/logging_mixin.dart';

final minecraftStateProvider =
    StateNotifierProvider<MinecraftStateNotifier, MinecraftState>((ref) {
      return MinecraftStateNotifier(ref);
    });

class MinecraftStateNotifier extends StateNotifier<MinecraftState>
    with LoggingMixin {
  final Ref _ref;

  MinecraftStateNotifier(this._ref) : super(MinecraftState());

  @override
  Ref get ref => _ref;

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
    switch (level) {
      case LogLevel.info:
        logInfo(message);
        break;
      case LogLevel.debug:
        logDebug(message);
        break;
      case LogLevel.warning:
        logWarning(message);
        break;
      case LogLevel.error:
        logError(message);
        break;
    }
  }

  void addJavaLog(
    String message, {
    LogLevel level = LogLevel.info,
    LogSource source = LogSource.app,
    String? userId,
  }) {
    final isStderr = source == LogSource.javaStdErr;
    logJava(message, level: level, isStderr: isStderr, userId: userId);
  }

  void onAssetsProgress(double progress, int current, int total) {
    updateProgress(
      progress,
      'Downloading assets: ${(progress * 100).toInt()}%',
    );

    if (current == 1 ||
        current == total ||
        (progress * 10).toInt() != ((progress - (1.0 / total)) * 10).toInt()) {
      logInfo(
        'Downloading assets: $current/$total (${(progress * 100).toInt()}%)',
      );
    }
  }

  void onUserAssetsProgress(
    String userId,
    double progress,
    int current,
    int total,
  ) {
    updateUserProgress(
      userId,
      progress,
      'Downloading assets: ${(progress * 100).toInt()}%',
    );

    if (current == 1 ||
        current == total ||
        (progress * 10).toInt() != ((progress - (1.0 / total)) * 10).toInt()) {
      logDebug(
        '[User: $userId] Downloading assets: $current/$total (${(progress * 100).toInt()}%)',
      );
    }
  }

  void onLibrariesProgress(double progress, int current, int total) {
    updateProgress(
      progress,
      'Downloading libraries: ${(progress * 100).toInt()}%',
    );
    logInfo(
      'Downloading libraries: $current/$total (${(progress * 100).toInt()}%)',
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
    logWarning(
      '[User: $userId] Downloading libraries: $current/$total (${(progress * 100).toInt()}%)',
    );
  }

  void onPrepareComplete() {
    updateProgress(1.0, 'Launching...');
    logInfo('Minecraft preparation complete');
  }

  void onUserPrepareComplete(String userId) {
    updateUserProgress(userId, 1.0, 'Launching...');
    logInfo('[User: $userId] Minecraft preparation complete');
  }

  void onNativesProgress(double progress, int current, int total) {
    updateProgress(
      progress,
      'Extracting native libraries: ${(progress * 100).toInt()}%',
    );
    logInfo(
      'Extracting native libraries: $current/$total (${(progress * 100).toInt()}%)',
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
    logInfo(
      '[User: $userId] Extracting native libraries: $current/$total (${(progress * 100).toInt()}%)',
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

    if (normal) {
      logInfo(exitMessage);
    } else {
      logError(exitMessage);
    }
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

    if (normal) {
      logInfo(exitMessage);
    } else {
      logError(exitMessage);
    }
  }

  void onMinecraftLaunch() {
    logInfo('Minecraft has been launched');
    resetProgress();
  }
}
