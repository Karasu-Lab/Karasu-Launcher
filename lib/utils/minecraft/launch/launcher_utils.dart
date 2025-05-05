import 'dart:io';
import 'package:karasu_launcher/models/auth/account.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:karasu_launcher/utils/minecraft/constants.dart';
import 'package:karasu_launcher/utils/minecraft/launch/launcher_factory.dart';

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
}) async {
  final launcher = LauncherFactory().getStandardLauncher();
  return await launcher.launchMinecraft(
    profile,
    onAssetsProgress: onAssetsProgress,
    onLibrariesProgress: onLibrariesProgress,
    onNativesProgress: onNativesProgress,
    onPrepareComplete: onPrepareComplete,
    onExit: onExit,
    onStdout: onStdout,
    onStderr: onStderr,
    onMinecraftLaunch: onMinecraftLaunch,
    account: account,
    offlinePlayerName: offlinePlayerName,
  );
}

/// JVM引数を構築する
Future<List<String>> constructJvmArguments({
  required VersionInfo versionInfo,
  required String nativeDir,
  required String classpath,
  required String appDir,
  required String gameDir,
}) async {
  final launcher = LauncherFactory().getStandardLauncher();
  return await launcher.constructJvmArguments(
    versionInfo: versionInfo,
    nativeDir: nativeDir,
    classpath: classpath,
    appDir: appDir,
    gameDir: gameDir,
  );
}

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
}) async {
  final launcher = LauncherFactory().getStandardLauncher();
  return await launcher.constructGameArguments(
    versionInfo: versionInfo,
    appDir: appDir,
    gameDir: gameDir,
    versionId: versionId,
    username: username,
    uuid: uuid,
    accessToken: accessToken,
    userType: userType,
    xuid: xuid,
    clientId: clientId,
  );
}

/// 認証情報を使用してゲーム引数を構築する
Future<List<String>> constructGameArgumentsWithAuth({
  required VersionInfo versionInfo,
  required String appDir,
  required String gameDir,
  required String versionId,
  Account? account,
  String? offlinePlayerName,
}) async {
  final launcher = LauncherFactory().getStandardLauncher();
  return await launcher.constructGameArgumentsWithAuth(
    versionInfo: versionInfo,
    appDir: appDir,
    gameDir: gameDir,
    versionId: versionId,
    account: account,
    offlinePlayerName: offlinePlayerName,
  );
}

/// 必要なMinecraftファイルをダウンロードする
Future<void> downloadRequiredMinecraftFiles(
  String versionId, {
  ProgressCallback? onAssetsProgress,
  ProgressCallback? onLibrariesProgress,
  ProgressCallback? onNativesProgress,
}) async {
  final launcher = LauncherFactory().getStandardLauncher();
  return await launcher.downloadRequiredMinecraftFiles(
    versionId,
    onAssetsProgress: onAssetsProgress,
    onLibrariesProgress: onLibrariesProgress,
    onNativesProgress: onNativesProgress,
  );
}

/// Minecraftクライアントをダウンロードする
Future<void> downloadMinecraftClient(String versionId) async {
  final launcher = LauncherFactory().getStandardLauncher();
  return await launcher.downloadMinecraftClient(versionId);
}

/// Minecraftアセットをダウンロードする
Future<void> downloadMinecraftAssets(
  String versionId, {
  ProgressCallback? onProgress,
}) async {
  final launcher = LauncherFactory().getStandardLauncher();
  return await launcher.downloadMinecraftAssets(
    versionId,
    onProgress: onProgress,
  );
}

/// Minecraftライブラリをダウンロードする
Future<void> downloadMinecraftLibraries(
  String versionId, {
  ProgressCallback? onProgress,
}) async {
  final launcher = LauncherFactory().getStandardLauncher();
  return await launcher.downloadMinecraftLibraries(
    versionId,
    onProgress: onProgress,
  );
}

/// Minecraftの全てのファイルをダウンロードする
Future<void> downloadMinecraftComplete(String versionId) async {
  final launcher = LauncherFactory().getStandardLauncher();
  return await launcher.downloadMinecraftComplete(versionId);
}

/// Javaパスを検索する
Future<String> findJavaPath(Profile profile) async {
  final launcher = LauncherFactory().getStandardLauncher();
  return await launcher.findJavaPath(profile);
}

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
]) {
  final launcher = LauncherFactory().getStandardLauncher();
  return launcher.replaceArgumentPlaceholders(
    arg,
    username,
    versionId,
    gameDir,
    appDir,
    assetsIndexName,
    uuid,
    accessToken,
    userType,
    versionType,
    xuid,
    clientId,
  );
}

/// 認証関連の引数を削除する
void removeAuthRelatedArgs(List<String> args) {
  final launcher = LauncherFactory().getStandardLauncher();
  return launcher.removeAuthRelatedArgs(args);
}
