import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/mixins/logging_mixin.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/providers/authentication_provider.dart';
import 'package:karasu_launcher/providers/log_provider.dart';
import 'package:karasu_launcher/providers/minecraft_state_provider.dart';
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
      logError('An error occurred while launching Minecraft: $e');
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
      logError('Error processing standard output: $e');
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
      logError('Error processing standard error output: $e');
    }
  }

  void _addLogWithSource(String message, LogLevel level, LogSource source) {
    final isStderr = source == LogSource.javaStdErr;
    logJava(message, level: level, isStderr: isStderr);
  }
}
