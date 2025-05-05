import 'package:karasu_launcher/providers/log_provider.dart';

/// Minecraft関連の定数
const String MINECRAFT_VERSION_MANIFEST_URL =
    'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json';
const String MINECRAFT_RESOURCES_URL =
    'https://resources.download.minecraft.net';

/// 進捗コールバック
typedef ProgressCallback =
    void Function(double progress, int current, int total);

/// 準備完了コールバック
typedef PrepareCompleteCallback = void Function();

/// Minecraft終了コールバック
typedef MinecraftExitCallback =
    void Function(
      int? exitCode,
      bool normal,
      String? userId,
      String? profileId,
    );

/// Minecraft出力コールバック
typedef MinecraftOutputCallback =
    void Function(String output, LogSource source);

/// Minecraft起動コールバック
typedef LaunchMinecraftCallback = void Function();
