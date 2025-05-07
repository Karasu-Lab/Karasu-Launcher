import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/mixins/logging_mixin.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/providers/authentication_provider.dart';
import 'package:karasu_launcher/providers/java_provider.dart';
import 'package:karasu_launcher/providers/log_provider.dart';
import 'package:karasu_launcher/providers/minecraft_state_provider.dart';
import 'package:karasu_launcher/utils/minecraft/launch/launcher_factory.dart';
import 'package:karasu_launcher/utils/minecraft_utils.dart';

final minecraftServiceProvider = Provider<MinecraftService>((ref) {
  return MinecraftService(ref);
});

class MinecraftService with LoggingMixin {
  final Ref _ref;

  MinecraftService(this._ref);

  @override
  Ref get ref => _ref;

  Future<void> launchMinecraftAsService(
    Profile profile, {
    String? offlinePlayerName,
  }) async {
    final notifier = _ref.read(minecraftStateProvider.notifier);
    final account = _ref.read(activeAccountProvider);

    notifier.setLaunching(true);
    notifier.updateProgress(0.0, '準備中...');
    logInfo(
      'App java path: ${_ref.read(javaProvider).customJavaBinaryPath}',
    );
    logInfo('Starting Minecraft (Version: ${profile.lastVersionId})');

    if (account != null) {
      logInfo('Logging in as account: ${account.profile?.name ?? "Unknown"}');
    } else {
      final playerName = offlinePlayerName ?? 'Player';
      logWarning(
        'Warning: No active account found. Launching in offline mode (Player name: $playerName)',
      );
    }

    try {
      // 標準ランチャーを使用
      final launcher = await LauncherFactory().getLauncherForProfile(profile);

      await launcher.launchMinecraft(
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
        javaProvider: ref.watch(javaProvider),
      );
    } catch (e) {
      logError('An error occurred while launching Minecraft: $e');
      notifier.resetProgress();
    }
  }

  void _handleStdout(String line, LogSource source) {
    try {
      final decodedLine = utf8.decode(line.codeUnits, allowMalformed: true);

      LogLevel level;

      final lowerLine = decodedLine.toLowerCase();
      if (lowerLine.contains("debug")) {
        level = LogLevel.debug;
      } else if (lowerLine.contains("asset") ||
          lowerLine.contains("resource")) {
        level = LogLevel.debug;
      } else if (lowerLine.contains("library") || lowerLine.contains("lib")) {
        level = LogLevel.warning;
      } else if (lowerLine.contains("error") ||
          lowerLine.contains("exception")) {
        level = LogLevel.error;
      } else {
        level = LogLevel.info;
      }

      _addLogWithSource(decodedLine, level, LogSource.javaStdOut);
    } catch (e) {
      logError('Error processing standard output: $e');
    }
  }

  void _handleStderr(String line, LogSource source) {
    try {
      final decodedLine = utf8.decode(line.codeUnits, allowMalformed: true);

      LogLevel level;

      final lowerLine = decodedLine.toLowerCase();
      if (lowerLine.contains("library") || lowerLine.contains("lib")) {
        level = LogLevel.warning;
      } else if (lowerLine.contains("warn") || lowerLine.contains("warning")) {
        level = LogLevel.warning;
      } else if (lowerLine.contains("asset") ||
          lowerLine.contains("resource")) {
        level = LogLevel.debug;
      } else {
        level = LogLevel.error;
      }

      _addLogWithSource(decodedLine, level, LogSource.javaStdErr);
    } catch (e) {
      logError('Error processing standard error output: $e');
    }
  }

  void _addLogWithSource(String message, LogLevel level, LogSource source) {
    logJava(message, level: level, isStderr: source == LogSource.javaStdErr);
  }
}
