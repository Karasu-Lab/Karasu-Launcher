import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/minecraft_state.dart';
import 'package:karasu_launcher/providers/authentication_provider.dart';
import 'package:karasu_launcher/providers/minecraft_state_provider.dart';
import 'package:karasu_launcher/utils/minecraft_utils.dart';

final minecraftServiceProvider = Provider<MinecraftService>((ref) {
  return MinecraftService(ref);
});

class MinecraftService {
  final Ref _ref;

  MinecraftService(this._ref);
  Future<void> launchMinecraftAsService(
    Profile profile, {
    String? offlinePlayerName,
  }) async {
    final notifier = _ref.read(minecraftStateProvider.notifier);
    final account = _ref.read(activeAccountProvider);

    notifier.setLaunching(true);
    notifier.updateProgress(0.0, '準備中...');
    notifier.addLog(
      'Minecraftの起動を開始します (バージョン: ${profile.lastVersionId})',
      level: LogLevel.info,
    );

    if (account != null) {
      notifier.addLog(
        'アカウント: ${account.profile?.name ?? "不明"} としてログインします',
        level: LogLevel.info,
      );
    } else {
      final playerName = offlinePlayerName ?? 'Player';
      notifier.addLog(
        '警告: アクティブなアカウントが見つかりません。オフラインモードで起動します (プレイヤー名: $playerName)',
        level: LogLevel.warning,
      );
    }

    try {
      await launchMinecraft(
        profile,
        onAssetsProgress: notifier.onAssetsProgress,
        onLibrariesProgress: notifier.onLibrariesProgress,
        onPrepareComplete: notifier.onPrepareComplete,
        onNativesProgress: notifier.onNativesProgress,
        onStdout: _handleStdout,
        onStderr: _handleStderr,
        onExit: notifier.onExit,
        onMinecraftLaunch: notifier.onMinecraftLaunch,
        account: account,
        offlinePlayerName: offlinePlayerName,
      );
    } catch (e) {
      notifier.addLog('Minecraftの起動中にエラーが発生しました: $e', level: LogLevel.error);
      notifier.resetProgress();
    }
  }

  void _handleStdout(String line, LogSource source) {
    try {
      final decodedLine = utf8.decode(line.codeUnits, allowMalformed: true);
      if (decodedLine.toLowerCase().contains("debug")) {
        _addLogWithSource(decodedLine, LogLevel.debug, LogSource.javaStdOut);
      } else {
        _addLogWithSource(decodedLine, LogLevel.info, LogSource.javaStdOut);
      }
    } catch (e) {
      _ref
          .read(minecraftStateProvider.notifier)
          .addLog('標準出力の処理中にエラーが発生しました: $e', level: LogLevel.error);
    }
  }

  void _handleStderr(String line, LogSource source) {
    try {
      final decodedLine = utf8.decode(line.codeUnits, allowMalformed: true);
      if (decodedLine.toLowerCase().contains("warn") ||
          decodedLine.toLowerCase().contains("warning")) {
        _addLogWithSource(decodedLine, LogLevel.warning, LogSource.javaStdErr);
      } else {
        _addLogWithSource(decodedLine, LogLevel.error, LogSource.javaStdErr);
      }
    } catch (e) {
      _ref
          .read(minecraftStateProvider.notifier)
          .addLog('標準エラー出力の処理中にエラーが発生しました: $e', level: LogLevel.error);
    }
  }

  void _addLogWithSource(String message, LogLevel level, LogSource source) {
    _ref
        .read(minecraftStateProvider.notifier)
        .addJavaLog(message, level: level, source: source);
  }
}
