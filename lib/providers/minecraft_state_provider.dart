import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/minecraft_state.dart';

final minecraftStateProvider =
    StateNotifierProvider<MinecraftStateNotifier, MinecraftState>((ref) {
      return MinecraftStateNotifier();
    });

class MinecraftStateNotifier extends StateNotifier<MinecraftState> {
  MinecraftStateNotifier() : super(const MinecraftState());

  // 起動状態を設定
  void setLaunching(bool isLaunching) {
    state = state.copyWith(isLaunching: isLaunching);
  }

  // 進捗状態を更新
  void updateProgress(double value, String text) {
    state = state.copyWith(progressValue: value, progressText: text);
  }

  // 進捗状態をリセット
  void resetProgress() {
    state = state.copyWith(
      isLaunching: false,
      progressValue: 0.0,
      progressText: 'プレイ',
    );
  }

  // ログを追加
  void addLog(String message, {LogLevel level = LogLevel.info}) {
    final log = LogMessage(message: message, level: level);
    state = state.copyWith(logs: [...state.logs, log]);
  }

  // Java出力のログを追加（プレフィックスをつける）
  void addJavaLog(
    String message, {
    LogLevel level = LogLevel.info,
    LogSource source = LogSource.app,
  }) {
    final prefix =
        level == LogLevel.error || level == LogLevel.warning ? '[Java] ' : '';
    final log = LogMessage(
      message: prefix + message,
      level: level,
      source: source,
    );
    state = state.copyWith(logs: [...state.logs, log]);
  }

  // ログをクリア
  void clearLogs() {
    state = state.copyWith(logs: []);
  }

  // アセット取得進捗のコールバック関数
  void onAssetsProgress(double progress, int current, int total) {
    updateProgress(progress, 'アセット取得中: ${(progress * 100).toInt()}%');
    addLog(
      'アセット取得中: $current/$total (${(progress * 100).toInt()}%)',
      level: LogLevel.info,
    );
  }

  // ライブラリ取得進捗のコールバック関数
  void onLibrariesProgress(double progress, int current, int total) {
    updateProgress(progress, 'ライブラリ取得中: ${(progress * 100).toInt()}%');
    addLog(
      'ライブラリ取得中: $current/$total (${(progress * 100).toInt()}%)',
      level: LogLevel.info,
    );
  }

  // 準備完了時のコールバック関数
  void onPrepareComplete() {
    updateProgress(1.0, '起動中...');
    addLog('Minecraft起動準備完了', level: LogLevel.info);
  }

  // 終了時のコールバック関数
  void onExit(int? exitCode, bool normal) {
    resetProgress();
    final exitMessage =
        normal
            ? 'Minecraftが正常に終了しました (終了コード: $exitCode)'
            : 'Minecraftが異常終了しました (終了コード: $exitCode)';
    addLog(exitMessage, level: normal ? LogLevel.info : LogLevel.error);
  }
}
