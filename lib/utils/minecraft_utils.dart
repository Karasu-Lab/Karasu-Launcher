import 'dart:io';
import 'package:karasu_launcher/models/auth/account.dart';
import 'package:karasu_launcher/models/launcher_profiles.dart';
import 'package:karasu_launcher/models/launcher_versions_v2.dart';
import 'package:karasu_launcher/models/version_info.dart';
import 'package:karasu_launcher/models/assets_indexes.dart';

// 各モジュールのインポート（ファイル内では小文字のエイリアスとして参照）
import 'minecraft/constants.dart';
export 'minecraft/constants.dart';

import 'minecraft/download_utils.dart' as download_utils;
import 'minecraft/version_utils.dart' as version_utils;
import 'minecraft/assets_utils.dart' as assets_utils;
import 'minecraft/library_utils.dart' as library_utils;
import 'minecraft/native_utils.dart' as native_utils;

// ランチャー関連の機能をインポート
import 'minecraft/launch/launcher_utils.dart' as launcher_utils;
export 'minecraft/launch/launch.dart';

/// ファイルをダウンロードする共通関数
Future<File> downloadFile(
  String url,
  String filePath, {
  int? expectedSize,
}) async {
  return download_utils.downloadFile(url, filePath, expectedSize: expectedSize);
}

Future<LauncherVersionsV2> fetchVersionManifest() async {
  return version_utils.fetchVersionManifest();
}

Future<String> getVersionJsonPath(String versionId) async {
  return version_utils.getVersionJsonPath(versionId);
}

Future<String> getClientJarPath(String versionId) async {
  return version_utils.getClientJarPath(versionId);
}

Future<VersionInfo> fetchVersionInfo(String versionId) async {
  return version_utils.fetchVersionInfo(versionId);
}

Future<VersionInfo> fetchModVersionInfo(String versionId) async {
  return version_utils.fetchModVersionInfo(versionId);
}

Future<File> downloadClientJar(VersionInfo versionInfo) async {
  return version_utils.downloadClientJar(versionInfo);
}

Future<void> downloadMinecraftClient(String versionId) async {
  return launcher_utils.downloadMinecraftClient(versionId);
}

Future<void> downloadMinecraftComplete(String versionId) async {
  return launcher_utils.downloadMinecraftComplete(versionId);
}

Future<AssetsIndexes> fetchAssetIndex(VersionInfo versionInfo) async {
  return assets_utils.fetchAssetIndex(versionInfo);
}

Future<File> downloadAsset(String hash, Directory assetsObjectsDir) async {
  return assets_utils.downloadAsset(hash, assetsObjectsDir);
}

Future<void> downloadMinecraftAssets(
  String versionId, {
  ProgressCallback? onProgress,
}) async {
  return assets_utils.downloadMinecraftAssets(
    versionId,
    onProgress: onProgress,
  );
}

Future<File?> downloadLibrary(Libraries library, Directory librariesDir) async {
  return library_utils.downloadLibrary(library, librariesDir);
}

Future<void> downloadMinecraftLibraries(
  String versionId, {
  ProgressCallback? onProgress,
}) async {
  return library_utils.downloadMinecraftLibraries(
    versionId,
    onProgress: onProgress,
  );
}

Future<void> extractNativeLibraries(
  VersionInfo versionInfo,
  String nativesDir, {
  ProgressCallback? onProgress,
}) async {
  return native_utils.extractNativeLibraries(
    versionInfo,
    nativesDir,
    onProgress: onProgress,
  );
}

Future<void> extractJar(String jarPath, String targetDir) async {
  return native_utils.extractJar(jarPath, targetDir);
}

Future<void> copyNativeFiles(String sourceDir, String targetDir) async {
  return native_utils.copyNativeFiles(sourceDir, targetDir);
}

Future<String> buildClasspath(VersionInfo versionInfo, String versionId) async {
  return library_utils.buildClasspath(versionInfo, versionId);
}

Future<List<String>> constructJvmArguments({
  required VersionInfo versionInfo,
  required String nativeDir,
  required String classpath,
  required String appDir,
  required String gameDir,
}) async {
  return launcher_utils.constructJvmArguments(
    versionInfo: versionInfo,
    nativeDir: nativeDir,
    classpath: classpath,
    appDir: appDir,
    gameDir: gameDir,
  );
}

Future<List<String>> constructGameArgumentsWithAuth({
  required VersionInfo versionInfo,
  required String appDir,
  required String gameDir,
  required String versionId,
  Account? account,
  String? offlinePlayerName,
}) async {
  return launcher_utils.constructGameArgumentsWithAuth(
    versionInfo: versionInfo,
    appDir: appDir,
    gameDir: gameDir,
    versionId: versionId,
    account: account,
    offlinePlayerName: offlinePlayerName,
  );
}

void removeAuthRelatedArgs(List<String> args) {
  launcher_utils.removeAuthRelatedArgs(args);
}

Future<List<String>> constructGameArguments({
  required VersionInfo versionInfo,
  required String appDir,
  required String gameDir,
  required String versionId,
  String? username = 'Player',
  String? uuid = '00000000-0000-0000-0000-000000000000',
  String? accessToken = '00000000000000000000000000000000',
  String? userType = 'mojang',
  String? xuid,
  String? clientId,
}) async {
  return launcher_utils.constructGameArguments(
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
  return launcher_utils.replaceArgumentPlaceholders(
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

Future<String> findJavaPath(Profile profile) async {
  return launcher_utils.findJavaPath(profile);
}

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
  return launcher_utils.launchMinecraft(
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

Future<void> downloadRequiredMinecraftFiles(
  String versionId, {
  ProgressCallback? onAssetsProgress,
  ProgressCallback? onLibrariesProgress,
  ProgressCallback? onNativesProgress,
}) async {
  return launcher_utils.downloadRequiredMinecraftFiles(
    versionId,
    onAssetsProgress: onAssetsProgress,
    onLibrariesProgress: onLibrariesProgress,
    onNativesProgress: onNativesProgress,
  );
}
