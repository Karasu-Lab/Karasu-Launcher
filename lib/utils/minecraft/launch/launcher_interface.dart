import 'dart:io';
import 'package:karasu_launcher/models/auth/account.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:karasu_launcher/utils/minecraft/constants.dart';

/// Minecraftのランチャーインターフェース
/// ジェネリックで型を指定することで、任意の型を返す実装を可能にする
abstract class MinecraftLauncherInterface {
  /// Minecraftクライアントをダウンロードする
  Future<void> downloadMinecraftClient(String versionId);

  /// Minecraftの全てのファイルをダウンロードする
  Future<void> downloadMinecraftComplete(String versionId);

  /// 必要なMinecraftファイルをダウンロードする
  Future<void> downloadRequiredMinecraftFiles(
    String versionId, {
    ProgressCallback? onAssetsProgress,
    ProgressCallback? onLibrariesProgress,
    ProgressCallback? onNativesProgress,
  });

  /// Minecraftを起動する
  Future<Process> launchMinecraft(
    Profile profile, {
    ProgressCallback? onAssetsProgress,
    ProgressCallback? onLibrariesProgress,
    ProgressCallback? onNativesProgress,
    PrepareCompleteCallback? onPrepareComplete,
    MinecraftExitCallback? onExit,
    MinecraftOutputCallback? onStdout,
    MinecraftOutputCallback? onStderr,
    LaunchMinecraftCallback? onMinecraftLaunch,
    Account? account,
    String? offlinePlayerName,
  });

  /// JVM引数を構築する
  Future<List<String>> constructJvmArguments({
    required VersionInfo versionInfo,
    required String nativeDir,
    required String classpath,
    required String appDir,
    required String gameDir,
  });

  /// ゲーム引数を構築する
  Future<List<String>> constructGameArguments({
    required VersionInfo versionInfo,
    required String appDir,
    required String gameDir,
    required String versionId,
    String? username,
    String? uuid,
    String? accessToken,
    String? userType,
    String? xuid,
    String? clientId,
  });

  /// 認証関連の引数を削除する
  void removeAuthRelatedArgs(List<String> args);

  /// 認証情報を使用してゲーム引数を構築する
  Future<List<String>> constructGameArgumentsWithAuth({
    required VersionInfo versionInfo,
    required String appDir,
    required String gameDir,
    required String versionId,
    Account? account,
    String? offlinePlayerName,
  });

  /// Javaパスを検索する
  Future<String> findJavaPath(Profile profile);

  /// ゲーム引数のプレースホルダーを置き換える
  String replaceArgumentPlaceholders(
    String arg,
    String username,
    String versionId,
    String gameDir,
    String appDir,
    String assetsIndexName,
    String uuid,
    String accessToken,
    String userType,
    String versionType, [
    String? xuid,
    String? clientId,
  ]);
}
