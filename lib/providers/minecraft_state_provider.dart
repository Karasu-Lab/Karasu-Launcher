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
      progressText: 'プレイ',
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
    final userPrefix = userId != null ? '[ユーザー: $userId] ' : '';

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
    updateProgress(progress, 'アセット取得中: ${(progress * 100).toInt()}%');
    addLog(
      'アセット取得中: $current/$total (${(progress * 100).toInt()}%)',
      level: LogLevel.info,
    );
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
      'アセット取得中: ${(progress * 100).toInt()}%',
    );
    addLog(
      '[ユーザー: $userId] アセット取得中: $current/$total (${(progress * 100).toInt()}%)',
      level: LogLevel.debug,
    );
  }

  void onLibrariesProgress(double progress, int current, int total) {
    updateProgress(progress, 'ライブラリ取得中: ${(progress * 100).toInt()}%');
    addLog(
      'ライブラリ取得中: $current/$total (${(progress * 100).toInt()}%)',
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
      'ライブラリ取得中: ${(progress * 100).toInt()}%',
    );
    addLog(
      '[ユーザー: $userId] ライブラリ取得中: $current/$total (${(progress * 100).toInt()}%)',
      level: LogLevel.warning,
    );
  }

  void onPrepareComplete() {
    updateProgress(1.0, '起動中...');
    addLog('Minecraft起動準備完了', level: LogLevel.info);
  }

  void onUserPrepareComplete(String userId) {
    updateUserProgress(userId, 1.0, '起動中...');
    addLog('[ユーザー: $userId] Minecraft起動準備完了', level: LogLevel.info);
  }

  void onNativesProgress(double progress, int current, int total) {
    updateProgress(progress, 'ネイティブライブラリ取得中: ${(progress * 100).toInt()}%');
    addLog(
      'ネイティブライブラリ取得中: $current/$total (${(progress * 100).toInt()}%)',
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
      'ネイティブライブラリ取得中: ${(progress * 100).toInt()}%',
    );
    addLog(
      '[ユーザー: $userId] ネイティブライブラリ取得中: $current/$total (${(progress * 100).toInt()}%)',
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
            ? 'Minecraftが正常に終了しました (終了コード: $exitCode)'
            : 'Minecraftが異常終了しました (終了コード: $exitCode)';
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
            ? '[ユーザー: $userId] Minecraftが正常に終了しました (終了コード: $exitCode)'
            : '[ユーザー: $userId] Minecraftが異常終了しました (終了コード: $exitCode)';
    addLog(exitMessage, level: normal ? LogLevel.info : LogLevel.error);
  }

  void onMinecraftLaunch() {
    addLog('Minecraftが起動しました', level: LogLevel.info);
    resetProgress();
  }
}
