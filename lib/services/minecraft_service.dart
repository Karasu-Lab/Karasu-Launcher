import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/minecraft_state.dart';
import 'package:karasu_launcher/providers/minecraft_state_provider.dart';
import 'package:karasu_launcher/utils/minecraft_utils.dart';

final minecraftServiceProvider = Provider<MinecraftService>((ref) {
  return MinecraftService(ref);
});

class MinecraftService {
  final Ref _ref;

  MinecraftService(this._ref);

  Future<void> launchMinecraftAsService(Profile profile) async {
    final notifier = _ref.read(minecraftStateProvider.notifier);

    notifier.setLaunching(true);
    notifier.updateProgress(0.0, '準備中...');
    notifier.addLog(
      'Minecraftの起動を開始します (バージョン: ${profile.lastVersionId})',
      level: LogLevel.info,
    );

    try {
      await launchMinecraft(
        profile,
        onAssetsProgress: notifier.onAssetsProgress,
        onLibrariesProgress: notifier.onLibrariesProgress,
        onPrepareComplete: notifier.onPrepareComplete,
        onStdout: _handleStdout,
        onStderr: _handleStderr,
        onExit: notifier.onExit,
      );
    } catch (e) {
      notifier.addLog('Minecraftの起動中にエラーが発生しました: $e', level: LogLevel.error);
      notifier.resetProgress();
    }
  }

  void _handleStdout(String line, LogSource source) {
    if (line.toLowerCase().contains("debug")) {
      _addLogWithSource(line, LogLevel.debug, LogSource.javaStdOut);
    } else {
      _addLogWithSource(line, LogLevel.info, LogSource.javaStdOut);
    }
  }

  void _handleStderr(String line, LogSource source) {
    if (line.toLowerCase().contains("warn") ||
        line.toLowerCase().contains("warning")) {
      _addLogWithSource(line, LogLevel.warning, LogSource.javaStdErr);
    } else {
      _addLogWithSource(line, LogLevel.error, LogSource.javaStdErr);
    }
  }

  void _addLogWithSource(String message, LogLevel level, LogSource source) {
    _ref
        .read(minecraftStateProvider.notifier)
        .addJavaLog(message, level: level, source: source);
  }
}
